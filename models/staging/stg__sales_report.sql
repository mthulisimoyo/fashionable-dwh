with renamed as (

    select
        cast(index as integer) as source_id,
        cast(qty as integer) as quantity,
        cast(trim(b2b) as boolean) as is_b2b,
        cast(try_strptime(date, '%m-%d-%y') as date) as order_date,
        trim("Order ID") as order_id,
        trim(sku) as sku,
        trim(style) as style,
        trim(asin) as asin,
        trim(status) as order_status,
        trim(fulfilment) as fulfilment,
        trim("Sales Channel ") as sales_channel,
        trim("ship-service-level") as ship_service_level,
        nullif(trim("Courier Status"), '') as courier_status,
        nullif(trim("fulfilled-by"), '') as fulfilled_by,
        nullif(trim("promotion-ids"), '') as promotion_ids,
        trim(category) as product_category,
        trim(size) as product_size,
        try_cast(amount as decimal(10, 2)) as amount,
        nullif(trim(currency), '') as currency,
        nullif(upper(trim("ship-city")), '') as ship_city,
        -- strip the trailing .0 from postal codes and convert empty strings to null
        nullif(upper(trim("ship-state")), '') as ship_state,
        nullif(regexp_replace(trim("ship-postal-code"), '\.0$', ''), '') as ship_postal_code,
        nullif(upper(trim("ship-country")), '') as ship_country
    from {{ ref('fashionable_sale_report') }}

)

select * from renamed
