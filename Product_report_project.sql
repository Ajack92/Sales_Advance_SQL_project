/*
==========================================================
product report
==========================================================

*/
--1. base query: retrieves core columns from tables

create view report_products as 

with product_base as (
select
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost,
	s.order_date,
	s.order_number,
	s.sales_amount,
	s.quantity,
	s.customer_key
from [gold.dim_products] as p
join [gold.fact_sales] as s on 
p.product_key = s.product_key
where order_date is not null 
)

, product_aggregate as (
select 
	product_name,
	category,
	subcategory,
	product_key,
	cost,
	max(order_date) as last_sale_date,
	count(distinct order_number) as total_orders,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	count(distinct customer_key) as total_customers,
	datediff(month,min(order_date),max(order_date)) as life_span,
	round(avg(cast(sales_amount as float) / nullif(quantity, 0)),1) as avg_selling_price
from product_base
group by 
	product_name,
	category,
	subcategory,
	product_key,
	cost
)

select 
	product_name,
	category,
	subcategory,
	product_key,
	cost,
	last_sale_date,
	datediff(month,last_sale_date, getdate()) as recency_in_months,
	case 
		when total_sales > 50000 then 'High-performer'
		when total_sales < 50000 then 'Mid-range'
		else 'Low-performer'
	end as product_segment,
	life_span,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	----avg order revenue
	case when total_orders = 0 then 0
		 else total_sales/total_orders
	end as avg_order_revenue,
	---avg_monthy_revenue
	case when life_span = 0 then total_sales
		 else total_sales/life_span
	end as avg_monthly_revenue
from product_aggregate


select * 
from report_products