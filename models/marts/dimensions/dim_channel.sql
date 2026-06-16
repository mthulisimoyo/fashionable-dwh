with channels as (
    select distinct on (channel_key)
        channel_key,
        sales_channel,
        fulfilment,
        ship_service_level,
        courier_status,
        fulfilled_by
    from {{ ref('int__sales_enriched') }}
    order by channel_key
)
select 
    channel_key,
    coalesce(sales_channel, 'Fashionable') as sales_channel,
    coalesce(fulfilment, 'Fashionable') as fulfilment,
    coalesce(ship_service_level, 'Unknown') as ship_service_level,
    coalesce(courier_status, 'Unknown') as courier_status,
    coalesce(fulfilled_by, 'Not Applicable') as  fulfilled_by
from channels