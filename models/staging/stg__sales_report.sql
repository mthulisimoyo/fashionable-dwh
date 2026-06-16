with source as (

    select * from {{ ref('fashionable_sale_report') }}

),
renamed as (

    select
        cast("index" as integer)                              as source_id,
        trim("Order ID")                                      as order_id,
        trim("SKU")                                           as sku,
        trim("Style")                                         as style,
        trim("ASIN")                                          as asin,
        try_strptime("Date", '%m-%d-%y')::date                as order_date,
        trim("Status")                                        as order_status,
        trim("Fulfilment")                                    as fulfilment,
        trim("Sales Channel ")                                as sales_channel,
        trim("ship-service-level")                            as ship_service_level,
        nullif(trim("Courier Status"), '')                    as courier_status,
        nullif(trim("fulfilled-by"), '')                      as fulfilled_by,
        nullif(trim("promotion-ids"), '')                     as promotion_ids,
        trim("Category")                                      as product_category,
        trim("Size")                                          as product_size,
        cast("Qty" as integer)                                as quantity,
        try_cast("Amount" as decimal(10, 2))                  as amount,
        nullif(trim("currency"), '')                          as currency,
        nullif(upper(trim("ship-city")), '')                  as ship_city,
        nullif(upper(trim("ship-state")), '')                 as ship_state,
        -- strip the trailing .0 from postal codes and convert empty strings to null
        nullif(regexp_replace(trim("ship-postal-code"), '\.0$', ''), '') as ship_postal_code,
        nullif(upper(trim("ship-country")), '')               as ship_country,
        cast(trim("B2B") as boolean)                          as is_b2b
    from source

)
select * from renamed