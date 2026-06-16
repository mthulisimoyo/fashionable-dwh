import duckdb
import numpy


con = duckdb.connect()
con.execute(
    f"""
    CREATE OR REPLACE TABLE salers_report_raw AS
    SELECT * FROM read_csv(
        '/Users/lindamoyo/Documents/fashionable-warehouse/fashionable_dwh/seeds/fashionable_sale_report.csv',
        header = true,
        all_varchar = true,
        delim = ',',
        quote = '"',
        escape = '"',
        null_padding = true,
        strict_mode = false,
        ignore_errors = true,
        sample_size = -1
    );
    """
)


cols = ['index', 'Order ID', 'Date', 'Status', 'Fulfilment', 'Sales Channel', 'ship-service-level', 'Style', 'SKU', 'Category', 'Size', 'ASIN', 'Courier Status', 'Qty', 'currency', 'Amount', 'ship-city', 'ship-state', 'ship-postal-code', 'ship-country', 'promotion-ids', 'B2B', 'fulfilled-by', 'Unnamed: 22']

#print(cols)
n = con.execute("SELECT count(*) FROM salers_report_raw").fetchone()[0]

def header_format(title):
    print("\n================================================================================")
    print(title)
    print("================================================================================")


header_format("TABLE PROFILE")
print(f"{'column':<22}{'nulls':>9}{'blanks':>9}{'distinct':>10}")
for c in cols:
    q = f'''
        SELECT
            count(*) FILTER (WHERE "{c}" IS NULL)                              AS nulls,
            count(*) FILTER (WHERE "{c}" IS NOT NULL AND trim("{c}") = '')     AS blanks,
            count(DISTINCT "{c}")                                              AS distinct_vals
        FROM salers_report_raw
    '''
    nulls, blanks, distinct = con.execute(q).fetchone()
    print(f"{c:<22}{nulls:>9,}{blanks:>9,}{distinct:>10,}")

def top_values(col):
    header_format(f"VALUE COUNTS: {col!r} (top 10)")
    rows = con.execute(
        f'''
        SELECT coalesce("{col}", '<NULL>') AS val, count(*) AS cnt
        FROM salers_report_raw
        GROUP BY 1
        ORDER BY cnt DESC LIMIT 10
        '''
    ).fetchall()
    for val, cnt in rows:
        print(f"  {cnt:>8,}  {val}")

for c in ["Status", "Fulfilment", "Sales Channel ", "ship-service-level", "Category", "Size", "Courier Status",
        "currency", "B2B", "fulfilled-by", "ship-country", "ship-state"]:
    if c in cols:
        top_values(c)

# Numeric profiling for Qty and Amount
header_format("NUMERIC PROFILE: Qty and Amount")
print(
    con.execute(
        """
        SELECT
            'Qty'    AS metric,
            min(try_cast(Qty AS DOUBLE))    AS min,
            max(try_cast(Qty AS DOUBLE))    AS max,
            round(avg(try_cast(Qty AS DOUBLE)), 2) AS avg,
            count(*) FILTER (WHERE try_cast(Qty AS DOUBLE) IS NULL AND Qty IS NOT NULL) AS uncastable
        FROM salers_report_raw
        UNION ALL
        SELECT
            'Amount',
            min(try_cast(Amount AS DOUBLE)),
            max(try_cast(Amount AS DOUBLE)),
            round(avg(try_cast(Amount AS DOUBLE)), 2),
            count(*) FILTER (WHERE try_cast(Amount AS DOUBLE) IS NULL AND Amount IS NOT NULL)
        FROM salers_report_raw
        """
    ).fetchdf().to_string(index=False)
)

header_format("DATE PROFILE: 'Date' column (format: MM-DD-YY)")
print(
    con.execute(
        """
        SELECT
            min(try_strptime(Date, '%m-%d-%y')) AS min_date,
            max(try_strptime(Date, '%m-%d-%y')) AS max_date,
            count(*) FILTER (WHERE try_strptime(Date, '%m-%d-%y') IS NULL AND Date IS NOT NULL) AS unparseable
        FROM salers_report_raw
        """
    ).fetchdf().to_string(index=False)
)

header_format("GRAIN and KEY ANALYSIS")
print(
    con.execute(
        """
        SELECT
            count(*)                          AS rows,
            count(DISTINCT index)             AS distinct_index,
            count(DISTINCT "Order ID")        AS distinct_order_id,
            count(DISTINCT "Order ID" || '|' || SKU) AS distinct_order_sku
        FROM salers_report_raw
        """
    ).fetchdf().to_string(index=False)
)
print("\nTop Order IDs by line count (multi-line orders):")
print(
    con.execute(
        '''
        SELECT "Order ID", count(*) AS lines
        FROM salers_report_raw
        GROUP BY 1
        ORDER BY lines DESC
        LIMIT 5
        '''
    ).fetchdf().to_string(index=False)
)

header_format("'Unnamed: 22' inspection")
print(
    con.execute(
        '''
        SELECT
            count(*) FILTER (WHERE "Unnamed: 22" IS NOT NULL) AS non_null,
            count(DISTINCT "Unnamed: 22") AS distinct_vals
        FROM salers_report_raw
        '''
    ).fetchdf().to_string(index=False)
)


print(
    con.execute(
        '''
        SELECT
            "Order ID", "SKU",
            count(1) AS distinct_vals
        FROM salers_report_raw
        GROUP BY 1, 2
        HAVING count(1) > 1
        '''
    ).fetchdf().to_string(index=False)
)

print(
    con.execute(
        '''
        SELECT
            *
        FROM salers_report_raw
        WHERE "Order ID" = '407-4853873-4978725'
        AND "SKU" = 'J0230-SKD-M'
        '''
    ).fetchdf().to_string(index=False)
)
con.close()