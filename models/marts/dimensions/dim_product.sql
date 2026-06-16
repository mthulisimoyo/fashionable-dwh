with products as (

    select distinct on (product_key)
        sku,
        product_key,
        style,
        asin,
        product_category,
        product_size
    from {{ ref('int__sales_enriched') }}
    order by product_key

)

select  *
from products
