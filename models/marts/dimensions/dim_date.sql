with bounds as (

    select
        min(order_date) as min_date,
        max(order_date) as max_date
    from {{ ref('int__sales_enriched') }}

),

date_spine as (

    select cast(bounds.d as date) as date_day
    from bounds,
        unnest(generate_series(bounds.min_date, bounds.max_date, interval '1 day')) as t (d)

)

select
    cast(strftime(date_day, '%Y%m%d') as integer) as date_key,
    date_day as full_date,
    year(date_day) as year,
    quarter(date_day) as quarter,
    month(date_day) as month_number,
    monthname(date_day) as month_name,
    week(date_day) as week_of_year,
    day(date_day) as day_of_month,
    dayofweek(date_day) as day_of_week,
    dayname(date_day) as day_name,
    dayofweek(date_day) in (0, 6) as is_weekend,
    case
        when month(date_day) in (2, 3) then 'Spring'
        when month(date_day) in (4, 5, 6) then 'Summer'
        when month(date_day) in (7, 8, 9) then 'Monsoon'
        when month(date_day) in (10, 11) then 'Autumn'
        else 'Winter'
    end as season
from date_spine
