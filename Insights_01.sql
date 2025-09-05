-- O_list delivery performance
SELECT 
  Round(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400.0),2) AS avg_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL 
  AND order_purchase_timestamp IS NOT NULL;

--Performance per seller
  With sub as (
				SELECT 
				  oi.seller_id,
				  ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0), 2) AS delivery_days
				FROM orders o
				JOIN order_items oi ON o.order_id = oi.order_id
				WHERE o.order_delivered_customer_date IS NOT NULL 
				  AND o.order_purchase_timestamp IS NOT NULL
				GROUP BY oi.seller_id

  )
  SELECT 
  seller_id,
  ROUND(AVG(delivery_days), 2) AS avg_delivery_days
FROM sub
GROUP BY seller_id;

--Which states experience the longest average delivery times?
SELECT customer_state , Round(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp) / 86400.0)),2) AS avg_days
	from customers c
	join orders o 
	on c.customer_id= o.customer_id
	WHERE o.order_delivered_customer_date IS NOT NULL 
				  AND o.order_purchase_timestamp IS NOT NULL
	GROUP BY customer_state
	ORDER BY avg_days  DESC
	LIMIT 10;

--Which sellers have the highest average delivery times?

	SELECT s.seller_id , Round(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp) / 86400.0)),2) AS avg_days
	FROM sellers s 
	join order_items oi
	on s.seller_id = oi.seller_id
	join orders o 
	on o.order_id = oi.order_id
	WHERE o.order_delivered_customer_date IS NOT NULL 
				  AND o.order_purchase_timestamp IS NOT NULL
	group by s.seller_id
	ORDER by avg_days DESC;

--Outlier detected and explored
select * 
from orders o
join order_items oi
on o.order_id = oi.order_id
join sellers s 
on oi.seller_id = s.seller_id
Where s.seller_id = 'df683dfda87bf71ac3fc63063fba369d'

--optimized query to avoid sellers with orders < 5

	SELECT s.seller_id , Round(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp) / 86400.0)),2) AS avg_days
	FROM sellers s 
	join order_items oi
	on s.seller_id = oi.seller_id
	join orders o 
	on o.order_id = oi.order_id
	WHERE o.order_delivered_customer_date IS NOT NULL 
				  AND o.order_purchase_timestamp IS NOT NULL
	group by s.seller_id
	HAVING COUNT(*) >= 5
	ORDER by avg_days DESC;

-- Get the number of orders per unique customer
-- Only keep customers who placed more than 1 order

	SELECT 
  customer_unique_id, 
  COUNT(order_id) AS num_orders
FROM customers c
JOIN orders o 
  ON c.customer_id = o.customer_id
GROUP BY customer_unique_id
HAVING COUNT(order_id) > 1;


-- CTE 1: Get customers who placed more than 1 order (repeaters)

WITH repeaters AS (
  SELECT 
    customer_unique_id
  FROM customers c
  JOIN orders o 
    ON c.customer_id = o.customer_id
  GROUP BY customer_unique_id
  HAVING COUNT(order_id) > 1
),

-- CTE 2: Get all customers who placed at least one order

total_customers AS (
  SELECT DISTINCT customer_unique_id
  FROM customers c
  JOIN orders o 
    ON c.customer_id = o.customer_id
)

-- Final output: count repeaters, total customers, and percentage

SELECT
  COUNT(repeaters.customer_unique_id) AS repeat_customers,
  COUNT(total_customers.customer_unique_id) AS total_customers,
  ROUND(
    100.0 * COUNT(repeaters.customer_unique_id) / COUNT(total_customers.customer_unique_id), 
    2
  ) AS repeat_customer_percentage
FROM total_customers
LEFT JOIN repeaters 
  ON total_customers.customer_unique_id = repeaters.customer_unique_id;

--What is the total revenue per month during the dataset period?
select Round(sum(price + freight_value):: numeric,2) AS total_revenue,to_char(o.order_purchase_timestamp,'YYYY-MM') AS month
from order_items oi
join orders o on oi.order_id=o.order_id
WHERE order_status = 'delivered'
group by to_char(o.order_purchase_timestamp,'YYYY-MM') 
ORDER by month;	

--What is avg order value per MONTH
with tot as (
select count(o.order_id)AS total_orders,Round(sum(price + freight_value):: numeric,2) AS total_revenue,to_char(o.order_purchase_timestamp,'YYYY-MM') AS month
from order_items oi
join orders o on oi.order_id=o.order_id
WHERE order_status = 'delivered'
group by to_char(o.order_purchase_timestamp,'YYYY-MM') 
)
select month,Round((total_revenue / total_orders),2) AS avg_order_value
from tot;

--Monthly Revenue Growth Rate


With monthly_revenue AS (
Select date_trunc('month',o.order_purchase_timestamp) AS month,
sum(oi.price + oi.freight_value)AS total_revenue
from orders o 
join order_items oi 
on o.order_id = oi.order_id
where o.order_status = 'delivered'
Group by date_trunc('month',o.order_purchase_timestamp)
)

, monthly_with_lag AS (
	select month,
	total_revenue,
	LAG(total_revenue) OVER(order by month) AS prev_month_rev
	from monthly_revenue
)
Select 
To_char(month,'YYYY-MM') AS month_N,
Round(total_revenue::numeric,2) AS total_rev,
Round(prev_month_rev::numeric,2) AS prev_mon_rev,
Case When prev_month_rev IS NULl THEN NULL 
					ELSE
							Round((total_revenue-prev_month_rev)::numeric/NULLIF(prev_month_rev::numeric,0) * 100,2)
							END	AS GROWTH_RATE
From monthly_with_lag
ORDER BY month

--we need total revenue and Ranking them 
WITH SELLER_RANK AS (Select seller_id,
		To_Char(order_purchase_timestamp,'YYYY-MM') AS month,
		Round(sum(price:: numeric + freight_value:: numeric),2) AS total_rev,
		DENSE_Rank() OVER(partition by To_Char(order_purchase_timestamp,'YYYY-MM') order by sum(price + freight_value) DESC) AS seller_rank
		FROM order_items oi
		join orders o
		on oi.order_id = o.order_id	
		Where order_status = 'delivered'
		GROUP BY seller_id, to_char(order_purchase_timestamp,'YYYY-MM')
		)
		
		SELECT seller_id,
				month,
				total_rev,
				seller_rank
		From SELLER_RANK
		WHERE seller_rank =1
		ORDER BY month, seller_rank;
		
