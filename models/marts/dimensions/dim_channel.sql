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
    *
from channels
