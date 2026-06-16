-- which city has the highest sales? 
-- what is the total revenue, units sold, total orders and average order value for each city?

select 
    c.state,
    c.city,
    sum(f.amount) as total_sales,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as units_sold,
    count(distinct f.order_id) as total_orders,
    sum(f.amount)/count(distinct f.order_id) as avg_order_value
from {{ ref('fact_sales') }} f
join {{ ref('dim_customer') }} c on f.customer_key = c.customer_key
group by 1, 2
order by total_sales desc;