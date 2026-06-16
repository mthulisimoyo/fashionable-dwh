# fashionable_dwh
`
`
A dimensional warehouse for **Fashionable** an eCommerce fashion
retailer. Raw order-line data is modelled into a **star schema** with conformed
dimensions and surrogate keys using **dbt**, materialised in a local **DuckDB**
database, and explored through a **Streamlit** dashboard.
`
`
## Business process & grain
`
`
- **Process:** online fashion sales.
`- **Fact grain:** one row per **order line** (`order_id + sku) — the lowest``
`  transaction level in the source. This answers _what_ sells, _where_, _when_,`
`  and _through which channel_. Rolling up to `order_id would lose line detail.``
`- Duplicate `(order_id, sku) lines are de-duplicated in the intermediate layer``
``  (latest source_id wins).``
`
`
## Architecture
`
`
`
Follows a Medallion Style Architecture with the Gold layer dimensionally modeled
seed (raw CSV)  ->  staging  ->  intermediate  ->  marts (star schema)
`
`
`
| Layer | Model | Materialisation | Purpose |
|-------|-------|-----------------|---------|
`| seed | `fashionable_sale_report | table (raw) | Raw CSV loaded as all-VARCHAR (no silent coercion) |``
`| staging | `stg__sales_report | table (staging) | Trim, type-cast, parse MM-DD-YY dates, normalise nulls |``
`| intermediate | `int__sales_enriched | table (intermediate) | De-dup, conformed surrogate keys, derived measures (revenue, is_valid_sale, date_key) |``
`| marts | `dim_date | table (marts) | Date spine with season / weekend attributes |``
`| marts | `dim_product | table (marts) | SKU -> style / category / size |``
`| marts | `dim_customer | table (marts) | Ship-to geography (country / state / city / postal) |``
`| marts | `dim_channel | table (marts) | Sales channel, fulfilment, courier, service level |``
`| marts | `fact_sales | table (marts) | Order-line fact: FKs to all dims, order_id degenerate dimension, measures quantity / amount / net_revenue |``
`
`
`**Surrogate keys** (`dbt_utils.generate_surrogate_key) are generated identically``
`in `int__sales_enriched and re-derived in each dimension, guaranteeing``
`referential integrity. `net_revenue / is_valid_sale are recognised only on``
`shipped + priced lines (`order_status like 'Shipped%' and amount is not null).``
`
`
## Data quality tests
`
`
`Tests are defined in the `_*.yml files next to each model and run with``
dbt build`:``
`
`
``- **Keys:** `not_null` + `unique` on surrogate keys.``
``- **Referential:** `relationships` from every `fact_sales` FK to its dimension.``
``- **Domain / range:** `dbt_utils.accepted_range` on `quantity` and `net_revenue`.``
``- **Conformity:** `dbt_expectations.expect_table_row_count_to_equal_other_table
`  (fact vs intermediate — guards against row loss / fan-out).`
`
`
## Requirements
`
`
`- Python 3.x `