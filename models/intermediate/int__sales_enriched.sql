with sales as (

    select
        *,
        row_number() over (partition by order_id, sku order by source_id desc) as row_num
    from {{ ref('stg__sales_report') }}

)

select
    source_id,
    order_id,
    order_date,
    {{ dbt_utils.generate_surrogate_key(['order_id', 'sku']) }} as sales_key,
    {{ dbt_utils.generate_surrogate_key(['sku']) }} as product_natural_key,
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

    coalesce(sales_channel, 'Fashionable') as sales_channel,
    coalesce(fulfilment, 'Fashionable') as fulfilment,
    coalesce(ship_service_level, 'Unknown') as ship_service_level,
    coalesce(courier_status, 'Unknown') as courier_status,
    coalesce(fulfilled_by, 'Not Applicable') as fulfilled_by,

    coalesce(ship_country, 'Unknown') as ship_country,
    coalesce(ship_state, 'Unknown') as ship_state,
    coalesce(ship_city, 'Unknown') as ship_city,
    coalesce(ship_postal_code, 'Unknown') as ship_postal_code,

    promotion_ids,

    quantity,
    amount,
    case when {{ is_valid_sale('order_status', 'amount') }} then amount end as revenue,
    {{ is_valid_sale('order_status', 'amount') }} as is_valid_sale,
    is_b2b,
    row_num

from sales
where row_num = 1
