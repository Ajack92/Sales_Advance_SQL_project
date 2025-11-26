# Sales_Advance_SQL_project


### Advance Data Analysis Project.

### Over time trends
### How a mseasure evolves ove time.Helps in tracking trends and identify seasonality in data
### Done by Aggreating [Measure] by [date dimension]

### 1. Sales performance over time

```sql
select year(order_date) as order_year,
sum(sales_amount) as total_sales
from [gold.fact_sales]
where order_date is not null
group by year(order_date)
order by 1;
```

### 2. Sales and customer performance over time

```sql
select year(order_date) as order_year,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers
from [gold.fact_sales]
where order_date is not null
group by year(order_date)
order by 1
```
### 3. Sales , Quantity, and customer performance over time

```sql
select year(order_date) as order_year,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from [gold.fact_sales]
where order_date is not null
group by year(order_date)
order by 1
```

### 4. By month

```sql
select month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from [gold.fact_sales]
where order_date is not null
group by month(order_date)
order by 1
```
### 5. By month and year 

```sql
select year(order_date) as order_year,
month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from [gold.fact_sales]
where order_date is not null
group by month(order_date),year(order_date)
order by 1,2
```

### 7. using datetrunc 

```sql

select datetrunc(month,order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from [gold.fact_sales]
where order_date is not null
group by datetrunc(month,order_date)
order by 1
```
### 8. Using datetrunc

```sql
select datetrunc(year,order_date) as order_year,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quantity) as total_quantity
from [gold.fact_sales]
where order_date is not null
group by datetrunc(year,order_date)
order by 1
```

###  Cumilative Analysis- Aggregate the data progressively over time
###  Helps to understand whether our business is growing or declining 

### Aggregate cumlative measure by date diamension


### 9. Calculate the total sales per month and Running total of sale over time using window function
        (default window frame b/w unbounded preceding and current row)
		
```sql
select 
order_date,
total_sales,
sum(total_sales) over(order by order_date) as running_total_sales 
from
(
select
datetrunc(month,order_date) as order_date,
sum(sales_amount) as total_sales
from [gold.fact_sales]
where order_date is not null
group by datetrunc(month,order_date)
) t

```
### 10. partition by month

```sql
select 
order_date,
total_sales,
sum(total_sales) over(partition by order_date order by order_date) as running_total_sales 
from
(
select
datetrunc(month,order_date) as order_date,
sum(sales_amount) as total_sales
from [gold.fact_sales]
where order_date is not null
group by datetrunc(month,order_date)
) t
```
### 11. partition by year

```sql
select 
order_date,
total_sales,
sum(total_sales) over(order by order_date) as running_total_sales 
from
(
select
datetrunc(year,order_date) as order_date,
sum(sales_amount) as total_sales
from [gold.fact_sales]
where order_date is not null
group by datetrunc(year,order_date)
) t
```

### 12. Moving Average of the price

```sql
select 
order_date,
total_sales,
sum(total_sales) over( order by order_date) as running_total_sales,
avg(avg_price) over(order by order_date) as moving_avg_price
from
(
select
datetrunc(year,order_date) as order_date,
sum(sales_amount) as total_sales,
avg(price) as avg_price
from [gold.fact_sales]
where order_date is not null
group by datetrunc(year,order_date)
)t
```

### Performance Analysis
### its a process of comparing current value with target value
### Helps to measure success and compare performance
### Formula- current[Meaure] - Target[measure] eg : current sales - Average sales

### 13. Analyze the yearly performace of products by comparing their sales to both average sales performance of the product and the prevous year's sales

```sql
with yearly_product_sales as(
	select 
	year(s.order_date) as order_year,
	p.product_name,
	sum(s.sales_amount) as current_sales
	from [gold.fact_sales]  as s
	join [gold.dim_products]  as p on s.product_key = p.product_key
	where order_date is not null
	group by year(s.order_date),p.product_name
)

select 
	order_year,
	product_name,
	current_sales,
	AVG(current_sales) over( partition  by product_name) as avg_sales,
	current_sales - AVG(current_sales) over( partition  by product_name) as diff_avg,
case when current_sales - AVG(current_sales) over( partition  by product_name) > 0 then 'Above Avg'
when current_sales - AVG(current_sales) over( partition  by product_name) < 0 then 'Below Avg'
else 'AVG'
end as avg_change,
	lag(current_sales) over(partition by product_name order by order_year) as previous_year,
 case when current_sales - lag(current_sales) over(partition by product_name order by order_year)> 0 then 'Increase'
 when current_sales - lag(current_sales) over(partition by product_name order by order_year) < 0 then 'Decrease'
 else 'No change'
 end as py_change
	from yearly_product_sales
	order by product_name, order_year
```



### Proportonal analysis --part to whole 
### Analyze how an individual part is performing compared to overall, allowing us to 
### understand which category has greatest impact on business
     [Measure]/total[measure])*100 by dimension 
     eg: (sales/total sales)*100 by country

### 14. which category contribute the most to overall sales?

```sql
with category_sales as(
select
p.category,
sum(s.sales_amount) total_sales
from [gold.fact_sales] as s
join [gold.dim_products] as p on s.product_key = p.product_key
group by p.category
)

select
category,
total_sales,
sum(total_sales) over() overall_sales,
concat(round((cast(total_sales as float) / sum(total_sales) over()) *100,2),'%') as percentage_of_total
from category_sales
order by total_sales DESC
```


### Data segmentation
### Group the data based on specific range
### heps to understand corelation b/w two meaures 
[measure] by [measure]--
eg: total products by sales range
    --total customers by age---

### segment products into cost ranges and 
### 15. count how many products fall into each segment

```sql
with product_segment as(
select 
product_key,
product_name,
cost,
case when cost < 100 then 'Below 100'
	 when cost between 100 and 500 then '100-500'
	 when cost between 500 and 1000 then '500-1000'
	 else 'above 1000'
end cost_range
from [gold.dim_products])

select 
cost_range,
count(product_key) as total_products
from product_segment
group by cost_range
order by 2 desc 
```

### 16. Group customers into three segament based on their spending behaviour:
    VIP:customers with at least 12 months of history and spending more than 5000
    Regular customers with atleast 12 months of history but spending 5000 or less
    new customers with a lifespan less than 12 months
    find total no of customers by each group 

```sql
with customer_spending as (

select c.customer_id,
min( s.order_date) as first_order, 
max( s.order_date) as last_order, 
sum(s.sales_amount) as sales,
datediff(month,min( s.order_date),max( s.order_date)) as life_span
from 
[gold.dim_customers] as c
join [gold.fact_sales] as s on c.customer_key = s.customer_key
group by c.customer_id
)

select
customer_segment,
count(customer_id) as total
from (
    select customer_id,
	 case when life_span >= 12 and sales > 5000 then 'VIP'
		 when life_span >= 12 and sales < 5000 then 'Regular'
		 else 'New'
	end as customer_segment
	from customer_spending)t
group by customer_segment 
order by total DESC
```

==========================================================
### customer report
==========================================================
### purpose 
		This report consolidate key customer metrics and behaviors

### Hightlights:
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

```sql 
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

```
==========================================================
### Product Report
==========================================================

```sql

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

```
