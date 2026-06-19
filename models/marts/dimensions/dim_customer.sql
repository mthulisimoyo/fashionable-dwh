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
    *
from customer
