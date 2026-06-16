-- what is sales trend by season and over time?

-- by season
select 
    d.season,
    sum(f.amount) as total_sales,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as units_sold,
    count(distinct f.order_id) as total_orders,
    count(distinct f.product_key) as total_products_sold,
    count(distinct f.customer_key) as total_customers,
    sum(f.amount)/count(distinct f.order_id) as avg_order_value,
    sum(f.amount)/count(distinct f.product_key) as avg_product_value,
    sum(f.amount)/count(distinct f.customer_key) as avg_customer_value
from {{ ref('fact_sales') }} f
join {{ ref('dim_date') }} d on f.date_key = d.date_key
group by d.season
order by d.season;

-- Monthly sales trend
select 
    d.year,
    d.month_number,
    d.month_name,
    d.season,
    sum(f.amount) as total_sales,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as units_sold,
    count(distinct f.order_id) as total_orders,
    count(distinct f.product_key) as total_products_sold
from {{ ref('fact_sales') }} f
join {{ ref('dim_date') }} d on f.date_key = d.date_key
group by d.year, d.month_number, d.month_name, d.season
order by d.year, d.month_number, d.season;