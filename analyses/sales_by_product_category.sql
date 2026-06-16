-- which product styles and category are most popular and profitable?

-- overall sales by product category
select
    f.product_category,
    sum(f.amount) as total_sales,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as units_sold,
    count(distinct f.order_id) as total_orders,
    count(1) as order_lines
from {{ ref('fact_sales') }} f
inner join {{ ref('dim_product') }} p on f.product_key = p.product_key
group by f.product_category
order by units_sold desc;


-- Top Styles and Categories by Revenue
select
    f.product_category,
    p.style,
    c.city,
    sum(f.amount) as total_sales,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as units_sold,
    count(distinct f.order_id) as total_orders,
    count(1) as order_lines
from {{ ref('fact_sales') }} f
inner join {{ ref('dim_product') }} p on f.product_key = p.product_key
inner join {{ ref('dim_customer') }} c on f.customer_key = c.customer_key
group by f.product_category, p.style, c.city
order by total_revenue desc;