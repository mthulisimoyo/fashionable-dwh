{{ 
    config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='sales_key',
    on_schema_change='append_new_columns',
    ) 
}}

with sales as (

    select 
        s.sales_key,
        s.order_id,
        s.order_status,
        s.is_b2b,
        s.is_valid_sale,
        s.date_key,
        p.product_key,
        s.customer_key,
        s.channel_key,
        s.quantity,
        s.amount,
        s.revenue
    
    from {{ ref('int__sales_enriched') }} s
    left join {{ ref('dim_product') }} p 
        on s.product_natural_key = p.product_natural_key
        and s.order_date >= p.valid_from 
        and s.order_date < p.valid_to

)

select *
from sales
