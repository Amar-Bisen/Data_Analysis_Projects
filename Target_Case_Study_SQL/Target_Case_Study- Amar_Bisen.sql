/* Exploration of olist_ecommerce Dataset */

use `olist_ecommerce`;
show tables;

-- 1. INITIAL EXPLORATION
desc customers;
desc geolocation;
desc order_items;
desc orders;
desc payments;

-- checking the properties of the customer table
select column_name, data_type, is_nullable 
from information_schema.columns
where table_name = 'customers' and table_schema = 'olist_ecommerce';

show columns from geolocation;

-- Data Types of all columns in 'Customers' Table.
select column_name, data_type 
from information_schema.columns
where table_name = 'customers' and table_schema = 'olist_ecommerce';

-- Time Range Between which the order were placed
select 
	min(order_purchase_timestamp) as 'first_order', 
    max(order_purchase_timestamp) as 'last_order' 
from orders;

-- Number of Cities and States of customers who ordered between active Period
select count(distinct customer_city) as 'Cites',
	count(distinct customer_state) as 'States'
from customers as c join orders as o
on c.customer_id = o.customer_id
where o.order_purchase_timestamp  
between '2016-09-04 21:15:19' and '2018-10-17 17:30:18';


/* Insight: First Order Date : 04-09-2016
			Last Order Date : 17-10-2018
            Number of Cities : 4119
            Number of States : 27
*/

-- 2. IN-DEPTH EXPLORATION
select count(*) from orders where order_approved_at is null;   				-- 160 null values
select count(*) from orders where order_delivered_carrier_date is null;  	-- 1783 null values
select count(*) from orders where order_delivered_customer_date is null;  	-- 2965 null values

-- Identify trends in the number of orders placed over the years
select  year, count(order_id) as "Number_Of_Order_Placed"
from 
(select order_id, year(order_purchase_timestamp) as "year" from orders) as a
group by  year
order by year;

-- Detect any monthly seasonality in the number of orders
select 
	extract(Year from order_purchase_timestamp) as "year", 
	month(order_purchase_timestamp) as "month",
	count(order_id) as "Total_Orders"
from orders
group by  Year, month
order by  Year, month;

-- Determine the time of day when Brazilian customers mostly place orders (Dawn, Morning, Afternoon, or Night).
select 
	extract(hour from order_purchase_timestamp) as 'Purchase_time',
	count(order_id) as "Number_of_Order_Placed"
from orders
group by Purchase_time
order by Purchase_time;


/* Insights: 
		1. Number of orders increases by Year.
        2. Not seen the monthely seasonality in the number of orders.
        3. Most of the Brazilian Customer places order in Afternoon and Night,  10 to 22 Hours are the peak purchase time.
*/


-- EVOLUTION OF E COMMERCE ORDERS IN BRAZILIAN MARKET
-- Month-on-month number of orders placed in each state
with monthly_order as (
	select c.customer_state, o.order_id,
    extract(year from order_purchase_timestamp) as "Year",
    extract(month from order_purchase_timestamp) as "month"
    from customers as c join orders as o 
    on c.customer_id = o.customer_id)
    
select year, month, customer_state,
	count(order_id) as Total_Orders
from monthly_order
group by year, month, customer_state
order by year, month, customer_state;

-- Distribution of customers across all states.
select customer_state, count(distinct customer_id) as "Total_Customers" 
from customers
group by customer_state
order by Total_Customers desc;


/*	Insights: 
	1. Some states like MG, SP, PR showing continuos growth in the number of orders month-by-month.
    2. SP is a state which have most e commerce customers near about 42 K.
*/


-- IMPACT ON ECONOMY
-- Analyze money movement by looking at order prices, freight, and other factors.

-- Checking Revenue Trends Yearly 
select 
	extract(Year from o.order_purchase_timestamp) as Year,
    extract(Month from o.order_purchase_timestamp) as Month,
    round(sum(p.payment_value),2) as Total_Revenue
from orders o join payments p
on o.order_id = p.order_id
where o.order_status = 'delivered'
group by Year, Month
order by Year, Month;

-- checking money flow by transactions type
select distinct payment_type from payments;


select payment_type as "Payment_method",
	count(order_id) as "Total_Orders",
    round(sum(payment_value),2) as "Revenue",
    round(avg(payment_installments),2) as "Average_Installments"
from payments
group by Payment_method
order by Revenue desc;

-- Most money spending states of customers.
select c.customer_state as "State",
	count(distinct o.order_id) as "Total_Orders",
	Round(sum(p.payment_value),2) as "Total_Revenue",
	round(sum(p.payment_value) / count(distinct o.order_id),2) as "Avg_order_value"
from customers c join orders o
on c.customer_id = o.customer_id
join payments p on o.order_id = p.order_id
where o.order_status = 'delivered'
group by c.customer_state
order by Total_Revenue desc;

-- percentage increase in the cost of orders from 2017 to 2018 (Jan-Aug).
with yearly_revenue as (
select 
	extract(Year from o.order_purchase_timestamp) as "Year",
    sum(p.payment_value) as Revenue
from orders o join payments p 
on o.order_id = p.order_id
where order_status = 'delivered' and 
		extract(month from o.order_purchase_timestamp) between 1 and 8 and
        extract(Year from o.order_purchase_timestamp) in (2017, 2018)
group by Year
),

pivoted_y_revenue as (
select 
	max(case when year = 2017 then Revenue end) as "Total_2017",
	max(case when year = 2018 then Revenue end) as "Total_2018"
from yearly_revenue ) 

select 
	round(Total_2017) as "2017_Revenue",
	round(Total_2018) as "2018_Revenue",
    round(((Total_2018 - Total_2017) / Total_2017)*100,2) as Percentage_increament
from pivoted_y_revenue;

-- Calculate the total & average value of order prices and freight for each state
select 
	c.customer_state,
	sum(oi.price) as Total_Order_Price,
    avg(oi.price) as Average_Order_Price, 
    sum(oi.freight_value) as Total_freight_price,
    avg(oi.freight_value) as Average_freight_price
from orders o join order_items oi
on o.order_id = oi.order_id 
join customers c on
o.customer_id = c.customer_id
group by c.customer_state
order by Total_Order_Price desc ;

/* Insights:
	1. month on month revenue inceases.
    2. Credit Cards and UPI are the most Used payment methods by Brazilian Customers.
    3. Creadit Card payments have avg 3.51 installments and other payment methods have avg 1 installments.
    4. Customers from SP, RJ, MG states spends more on online purchase in brazilian market.
    5. percentage increase in the cost of orders from 2017 to 2018 (Jan-Aug) is 143.33 %
    6. State SP has the Maximum order price and freight price among all states.
    7. State PB has the maximun average order price having 191.47.
    */
    
    
-- ANALYSIS ON SALES, FREIGHT, AND DELIVERY TIME 
-- Calculate the delivery time and the difference between estimated and actual delivery dates
select * from orders limit 10;

select (order_delivered_customer_date - order_purchase_timestamp) as "Delivery_time"
from orders 
order by Delivery_time desc;


select 
		date(order_purchase_timestamp) as Order_Date,
        date(order_delivered_customer_date) as Delivery_Date,
        date(order_estimated_delivery_date) as Estimated_Date,
        datediff(order_delivered_customer_date, order_purchase_timestamp) as Delivery_time,
        datediff(order_estimated_delivery_date, order_delivered_customer_date) as Difference_Actual_Vs_Estimate
from orders;


-- Identify the top 5 states with the highest & lowest average freight values
select c.customer_state, avg(oi.freight_value) as Average_Freight_Value
from customers c join orders o 
on c.customer_id = o.customer_id join order_items oi
on o.order_id = oi.order_id
where o.order_status = 'delivered' 
group by c.customer_state
order by Average_Freight_Value desc
limit 5;

select c.customer_state, avg(oi.freight_value) as Average_Freight_Value
from customers c join orders o 
on c.customer_id = o.customer_id join order_items oi
on o.order_id = oi.order_id
where o.order_status = 'delivered' 
group by c.customer_state
order by Average_Freight_Value asc
limit 5;

-- Identify the top 5 states with the highest & lowest average delivery times
select 
	c.customer_state,
	avg(datediff(o.order_delivered_customer_date, o.order_purchase_timestamp)) as Average_Delivery_Days
from customers c join orders o 
on c.customer_id = o.customer_id 
where o.order_status = 'delivered' 
	and o.order_delivered_customer_date is not null
group by c.customer_state
order by Average_Delivery_time desc
limit 5;

select 
	c.customer_state,
	avg(datediff(o.order_delivered_customer_date, o.order_purchase_timestamp)) as Average_Delivery_Days
from customers c join orders o 
on c.customer_id = o.customer_id 
where o.order_status = 'delivered' 
	and o.order_delivered_customer_date is not null
group by c.customer_state
order by Average_Delivery_time asc
limit 5;

-- Identify the top 5 states where delivery is faster than the estimated date.
select distinct c.customer_state,
	round(avg(datediff(order_delivered_customer_date, order_purchase_timestamp)),1) as "Avg_Actual_Delivery_Days",
    round(avg(datediff(order_estimated_delivery_date, order_purchase_timestamp)),1) as Avg_Estimated_Delivery_Days
from customers c join orders o 
on c.customer_id = o.customer_id
where o.order_status = 'delivered' and o.order_delivered_customer_date is not Null
group by c.customer_state
having avg(datediff(order_estimated_delivery_date, order_purchase_timestamp)) > 0
order by Avg_Estimated_Delivery_Days desc
limit 5;

/*
Insights:
1. SP, PR, MG, RJ, DF are the lowest average freight value states.
2. RR, PB, RO, AC, PI are the hieghest average freight value states.
3. SP, PR, MG, DF, SC states have the lowest average delivery time.
4. RR, AP, AM, AL, PA states have the heighest average delivery time.
5. AP, RR, AM, AC, RO are top 5 states where delivery is faster than the estimated date
*/


-- ANALYSIS BASED ON PAYMENTS 
-- Month-on-month number of orders placed using different payment types
select 
	extract(Year from order_purchase_timestamp) as Year,
    extract(Month From order_purchase_timestamp) as Month,
	payment_type AS Payment_Methods,
    count(distinct p.order_id) as "Total_Order_Placed"
from payments p 
join orders o 
on p.order_id = o.order_id
group by payment_type, Year, Month
order by Year, Month, Total_Order_Placed  desc;

-- Number of orders based on payment installments.
select 
	payment_installments,
    count(distinct order_id) as "Number_of_Orders"
from payments
group by payment_installments
order by payment_installments;


/*Insights: 
1. Most popular payment methods are Credit Cards and UPI.
2. Most customers pay their payments in 1 installment near about 50K transactions are done in 1 installment.
3. There are so less customers which are less likely to do payment more than 6 installments.
4. There is drastic drop in the number of orders after 10 installments.
*/
