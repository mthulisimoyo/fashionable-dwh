with sales as (

    select * ,
        row_number() over (partition by order_id, sku order by source_id desc) as row_num
    from {{ ref('stg__sales_report') }}

)

select
    source_id,
    order_id,
    order_date,
    {{ dbt_utils.generate_surrogate_key(['source_id']) }} as sales_key,
    {{ dbt_utils.generate_surrogate_key(['sku']) }}   as product_key,
    {{ dbt_utils.generate_surrogate_key(['ship_country', 
        'ship_state', 'ship_city', 'ship_postal_code']) }} as customer_key,
    {{ dbt_utils.generate_surrogate_key(['sales_channel', 'fulfilment', 'ship_service_level',
        'courier_status', 'fulfilled_by']) }} as channel_key,    
    cast(strftime(try_cast(order_date as date), '%Y%m%d') as integer) as date_key,

    sku,
    style,
    asin,
    product_category,
    product_size,
    order_status,
    courier_status,
    fulfilment,
    sales_channel,
    ship_service_level,
    fulfilled_by,
    ship_city,
    ship_state,
    ship_postal_code,
    ship_country,
    promotion_ids,

    quantity,
    amount,
    case when order_status='Shipped' then amount else 0 end as revenue,
    (order_status = 'Shipped' and amount is not null) as is_valid_sale,
    is_b2b,
    row_num

from sales
where row_num = 1
