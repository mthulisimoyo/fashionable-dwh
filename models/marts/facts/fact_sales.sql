with sales as (

    select 
        sales_key,
        order_id,
        order_status,
        is_b2b,
        is_valid_sale,
        date_key,
        product_key,
        customer_key,
        channel_key,
        quantity,
        amount,
        revenue
    
    from {{ ref('int__sales_enriched') }}

)

select *
from sales
