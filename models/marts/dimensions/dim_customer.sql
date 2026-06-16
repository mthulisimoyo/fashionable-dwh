with customer as (

    select distinct on (customer_key)
        customer_key,
        ship_country,
        ship_state,
        ship_city,
        ship_postal_code
    from {{ ref('int__sales_enriched') }}
    order by customer_key

)

select  
    customer_key,
    coalesce(ship_country, 'Unknown') as ship_country,
    coalesce(ship_state, 'Unknown') as ship_state,
    coalesce(ship_city, 'Unknown') as ship_city,
    coalesce(ship_postal_code, 'Unknown') as ship_postal_code
from customer
