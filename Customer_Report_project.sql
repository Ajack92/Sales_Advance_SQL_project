/*
==========================================================
customer report
==========================================================
purpose 
		This report consolidate key customer metrics and behaviors

Hightlights:
		1:Gathering essential feilds such as names,ages,transction details.
		2. segments customers into categories (VIP,Regular,New) and age groups
		3. Aggregate customer_level metrics
				-total orders
				-total sales
				-total quantity purchased
				-total products
				-lifespan(in months)
		4. calculate valubale KPIs:
				-recency(months since last order)
				-avergae order value
				-avergae monthly spend
===========================================================
*/
--1. base query: retrieves core columns from tables

create view customer_report as 

with base_query as(
	select 
		s.order_number,
		s.order_date,
		s.product_key,
		s.sales_amount,
		s.quantity,
		c.customer_key,
		c.customer_number,
		concat(c.first_name,' ',c.last_name) as full_name,
		datediff(year,c.birthdate,GETDATE()) as age
from [gold.fact_sales] as s
	join [gold.dim_customers] as c 
	on c.customer_key = s.customer_key
	where s.order_date is not null
)

,customer_aggreagation as (
select 
	full_name,
	customer_number,
	customer_key,
	age,
	count(distinct order_number) as total_orders,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	count(distinct product_key) as total_products,
	max(order_date) as last_order_date,
	datediff(month,min(order_date),max(order_date)) as life_span
from base_query
group by 
	full_name,
	customer_number,
	customer_key,
	age
)

select
	full_name,
	customer_number,
	customer_key,
	age, 
	case when age < 20 then 'under 20'
		 when age between 20 and 29 then '20-29'
		 when age between 30 and 39 then '30-39'
		 when age between 40 and 49 then '40-49'
		 else 'above 50+'
    end as age_group,
	case when life_span >= 12 and total_sales > 5000 then 'VIP'
		 when life_span >= 12 and total_sales < 5000 then 'Regular'
		 else 'New'
	end as customer_segment,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	last_order_date,
	datediff(month,last_order_date,getdate()) as recency,
	life_span,
	--compute avg_order_value
	case when total_sales = 0 then 0
	else total_sales/total_orders
	end as avg_order_value,
	--compute avg_monthly_spend
	case when life_span = 0 then total_sales
	 else total_sales/life_span
	 end as avg_monthly_spend
from customer_aggreagation

