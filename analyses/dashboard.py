"""Fashionable - Sales Dashboard (Streamlit).

A simple BI front-end over the dbt star schema in DuckDB. It reads the marts
(fact_sales + conformed dimensions) and answers the marketer questions:
popular categories/styles (incl. Mumbai), seasonal trend, and top cities.

"""

from __future__ import annotations

import os

import altair as alt
import duckdb
import pandas as pd
import streamlit as st

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "fashionable.duckdb")

st.set_page_config(page_title="Fashionable Sales", page_icon="🛍️", layout="wide")

PINK = "#E8467C"
NAVY = "#1F2A44"
TEAL = "#169A8E"


@st.cache_data(show_spinner="Loading star schema from DuckDB…")
def load_data() -> pd.DataFrame:
    con = duckdb.connect(DB_PATH, read_only=True)
    df = con.execute(
        """
        select
            f.order_id,
            f.quantity,
            f.amount,
            f.revenue,
            f.is_b2b,
            f.is_valid_sale,
            f.order_status,
            d.full_date,
            d.season,
            d.month_name,
            d.day_name,
            d.is_weekend,
            p.product_category,
            p.style,
            p.sku,
            p.product_size,
            c.ship_state,
            c.ship_city,
            ch.sales_channel,
            ch.fulfilment
        from marts.fact_sales  f
        join marts.dim_date     d on f.date_key     = d.date_key
        join marts.dim_product  p on f.product_key  = p.product_key
        join marts.dim_customer c on f.customer_key = c.customer_key
        join marts.dim_channel ch on f.channel_key  = ch.channel_key
        """
    ).fetchdf()
    con.close()
    return df


try:
    data = load_data()
except Exception as exc:  # noqa: BLE001
    st.error(
        f"Could not read the warehouse at `{os.path.abspath(DB_PATH)}`.\n\n"
        f"Run `dbt build` first to create the marts.\n\nDetails: {exc}"
    )
    st.stop()

# ----------------------------------------------------------------- sidebar
st.sidebar.header("Filters")
valid_only = st.sidebar.toggle(
    "Valid sales only", value=True,
    help="Shipped & priced lines (excludes cancelled / pending / unpriced).",
)

seasons = sorted(data["season"].dropna().unique())
categories = sorted(data["product_category"].dropna().unique())
channels = sorted(data["sales_channel"].dropna().unique())

sel_seasons = st.sidebar.multiselect("Season", seasons, default=seasons)
sel_categories = st.sidebar.multiselect("Product category", categories, default=categories)
sel_channels = st.sidebar.multiselect("Sales channel", channels, default=channels)
b2b_choice = st.sidebar.radio("Customer type", ["All", "B2C only", "B2B only"], horizontal=False)

df = data.copy()
if valid_only:
    df = df[df["is_valid_sale"]]
df = df[df["season"].isin(sel_seasons)]
df = df[df["product_category"].isin(sel_categories)]
df = df[df["sales_channel"].isin(sel_channels)]
if b2b_choice == "B2C only":
    df = df[~df["is_b2b"]]
elif b2b_choice == "B2B only":
    df = df[df["is_b2b"]]

# ----------------------------------------------------------------- header + KPIs
st.title("🛍️ Fashionable - Sales Dashboard")
st.caption("Analytics Engineer - Technical Interview by Mthulisi Moyo")

if df.empty:
    st.warning("No rows match the current filters.")
    st.stop()

revenue = float(df["revenue"].sum())
units = int(df["quantity"].sum())
orders = df["order_id"].nunique()
lines = len(df)
aov = revenue / orders if orders else 0

k1, k2, k3, k4 = st.columns(4)
k1.metric("Net revenue", f"{revenue:,.0f}")
k2.metric("Units sold", f"{units:,}")
k3.metric("Orders", f"{orders:,}")
k4.metric("Avg order value", f"{aov:,.0f}")

st.divider()


def bar(frame: pd.DataFrame, x: str, y: str, title: str, color: str, horizontal=False):
    enc_x, enc_y = (alt.X(f"{y}:Q", title=None), alt.Y(f"{y}:N", sort="-x", title=None)) \
        if horizontal else (alt.X(f"{x}:N", sort="-y", title=None), alt.Y(f"{y}:Q", title=None))
    chart = (
        alt.Chart(frame, title=title)
        .mark_bar(color=color, cornerRadius=3)
        .encode(x=enc_x, y=enc_y, tooltip=list(frame.columns))
        .properties(height=320)
    )
    st.altair_chart(chart, use_container_width=True)


# ----------------------------------------------------------------- row 1
c1, c2 = st.columns(2)
with c1:
    by_cat = (df.groupby("product_category", as_index=False)["revenue"].sum()
                .rename(columns={"revenue": "revenue"}).sort_values("revenue", ascending=False))
    bar(by_cat, "product_category", "revenue", "Revenue by product category", PINK)
with c2:
    by_city = (df.groupby("ship_city", as_index=False)["revenue"].sum()
                 .rename(columns={"revenue": "revenue"}).sort_values("revenue", ascending=False).head(10))
    bar(by_city, "ship_city", "revenue", "Top 10 cities by revenue", NAVY, horizontal=True)

# ----------------------------------------------------------------- row 2
c3, c4 = st.columns(2)
with c3:
    trend = (df.groupby("full_date", as_index=False)["revenue"].sum()
               .rename(columns={"revenue": "revenue"}))
    line = (
        alt.Chart(trend, title="Daily net revenue trend")
        .mark_line(color=TEAL, point=alt.OverlayMarkDef(color=TEAL))
        .encode(x=alt.X("full_date:T", title=None),
                y=alt.Y("revenue:Q", title=None),
                tooltip=["full_date:T", "revenue:Q"])
        .properties(height=320)
    )
    st.altair_chart(line, use_container_width=True)
with c4:
    by_season = (df.groupby("season", as_index=False)
                   .agg(revenue=("revenue", "sum"), units=("quantity", "sum")))
    bar(by_season, "season", "revenue", "Revenue by season", PINK)

# ----------------------------------------------------------------- styles table
st.divider()
st.subheader("Most popular styles")
focus_cities = ["(All cities)"] + sorted(df["ship_city"].dropna().unique().tolist())
default_idx = focus_cities.index("MUMBAI") if "MUMBAI" in focus_cities else 0
city_focus = st.selectbox("Focus city", focus_cities, index=default_idx)

styles_df = df if city_focus == "(All cities)" else df[df["ship_city"] == city_focus]
top_styles = (
    styles_df.groupby(["product_category", "style"], as_index=False)
    .agg(units=("quantity", "sum"), revenue=("revenue", "sum"), order_lines=("order_id", "count"))
    .sort_values("units", ascending=False)
    .head(15)
    .reset_index(drop=True)
)
st.caption(f"Top styles in **{city_focus}** - answers \"which styles/categories are most popular in Mumbai?\"")
st.dataframe(
    top_styles,
    use_container_width=True,
    hide_index=True,
    column_config={
        "revenue": st.column_config.NumberColumn("revenue", format="%.0f"),
        "units": st.column_config.NumberColumn("units", format="%d"),
    },
)