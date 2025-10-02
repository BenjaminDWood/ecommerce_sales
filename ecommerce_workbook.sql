create database if not exists ecommerce;

use ecommerce;

drop table if exists sales_report;

CREATE TABLE `sales_report` (
  `index` bigint DEFAULT NULL,
  `order_id` text,
  `date` datetime DEFAULT NULL,
  `status` text,
  `fulfilment` text,
  `sales_channel` text,
  `ship_service_level` text,
  `style` text,
  `sku` text,
  `category` text,
  `size` text,
  `asin` text,
  `courier_status` text,
  `qty` bigint DEFAULT NULL,
  `currency` text,
  `amount` double DEFAULT NULL,
  `ship_city` text,
  `ship_state` text,
  `ship_postal_code` double DEFAULT NULL,
  `ship_country` text,
  `promotion_ids` text,
  `b2b` tinyint(1) DEFAULT NULL,
  `fulfilled_by` text
);

SELECT 
    *
FROM
    sales_report;
    
drop table if exists item_stock;
    
CREATE TABLE `ecommerce`.`item_stock` (
  `index` INT NOT NULL,
  `sku_code` VARCHAR(45) NULL,
  `design_no` VARCHAR(45) NULL,
  `stock` INT NULL,
  `category` VARCHAR(45) NULL,
  `size` VARCHAR(45) NULL,
  `color` VARCHAR(45) NULL,
  PRIMARY KEY (`index`));
  
  select * from item_stock;
  select * from sales_report;
    
SELECT 
    *
FROM
    sales_report
WHERE
    order_id = '405-8078784-5731545';

DELIMITER $$
CREATE PROCEDURE find_order(in p_order_id INTEGER)
BEGIN
		SELECT
			s.*,
            i.design_no,
            i.stock,
            i.color
		FROM
			sales_report s
		JOIN
			item_stock i ON s.sku = i.sku_code
                WHERE
					s.order_id = p_order_id;
END$$
DELIMITER ;

select * from international_sales;

UPDATE international_sales SET DATE = DATE(DATE);

describe international_sales;

UPDATE international_sales i SET i.date = DATE(i.DATE);

ALTER TABLE international_sales
MODIFY COLUMN date DATE;

ALTER TABLE international_sales
CHANGE COLUMN CUSTOMER customer_name varchar(45);

ALTER TABLE international_sales
CHANGE COLUMN SKU sku varchar(45);

ALTER TABLE international_sales
CHANGE COLUMN PCS quantity bigint;

ALTER TABLE international_sales
CHANGE COLUMN RATE converted_price FLOAT;

ALTER TABLE international_sales
CHANGE COLUMN `GROSS AMT` charge float;

# Best customer and total spent (This now shows, specifically, the total spent in descending order by each customer, by month
	# May well be a very useful export for visualisation!
		#OK, now it's 100% correct as well!
SELECT 
	date_format(date, '%Y-%m') AS Month,
    customer_name AS Customer,
    SUM(charge) AS `Total Spent`
FROM
    international_sales
GROUP BY
    Month,
	customer_name
order by
	Month,
	sum(charge) DESC;
    
#Just checking date range - As expected, about 1 year's worth of data from June '21, to May '22.

SELECT
	min(date),
    max(date)
FROM
	international_sales;

#100% this does exactly: Total spend per customer by Year. It's perfect.
SELECT 
	YEAR(date) AS Year,
    customer_name, 
    SUM(charge) AS `Total Spent`
FROM
    international_sales
GROUP BY
    Year,
	customer_name
order by
	Year,
	sum(charge) DESC;
    
# Searching for customer name LIKE with an input - show total spend, spend by year, and most recent order

SELECT
	customer_name,
    SUM(charge) AS total_spend,
    (SELECT
		SUM(charge)
	FROM
		international_sales
	WHERE
		YEAR(date) = YEAR(current_date())) AS spend_this_year,
	(SELECT
		SUM(charge)
	FROM
		international_sales
	WHERE
		date = max(date)) AS most_recent_spend
FROM
	international_sales
WHERE
		customer_name LIKE '%AMANI%'
GROUP BY
	customer_name;


#Practice with getting spend this year

SELECT
	customer_name,
	SUM(charge)
FROM
	international_sales
WHERE
	YEAR(date) = '2021'
GROUP BY
	customer_name;

#Practice for most recent order

SELECT
	customer_name,
    sum(charge)
FROM
	international_sales
WHERE
	date = (SELECT max(date) FROM international_sales)
GROUP BY
	customer_name;
    
SELECT
    customer_name,
    SUM(charge) AS total_spend,
    SUM(CASE WHEN YEAR(date) = YEAR(CURDATE()) THEN charge ELSE 0 END) AS spend_this_year,
    max(CASE WHEN date = NULL THEN 'No Purchase History' ELSE date END) AS most_recent_purchase_date,
    SUM(CASE WHEN date = (
        SELECT MAX(date) 
        FROM international_sales 
        WHERE customer_name = s.customer_name
    ) THEN charge ELSE 0 END) AS most_recent_spend
FROM international_sales s
WHERE customer_name LIKE '%AMANI%'
GROUP BY customer_name;

# Nicely working version
SELECT
    i.customer_name,
    SUM(i.charge) AS total_spend,
    SUM(CASE WHEN YEAR(i.date) = YEAR(CURDATE()) THEN round(i.charge, 2) ELSE 0 END) AS spend_this_year,
	MAX(CASE WHEN date = NULL THEN 'No Purchase History' ELSE i.date END) AS most_recent_purchase_date,
    SUM(CASE WHEN i.date = r.max_date THEN ROUND(i.charge, 2) ELSE 0 END) AS most_recent_spend
FROM international_sales i
JOIN (
    SELECT customer_name, MAX(date) AS max_date
    FROM international_sales
    GROUP BY customer_name
) r ON i.customer_name = r.customer_name
WHERE i.customer_name LIKE '%AMANI%'
GROUP BY i.customer_name;


#Final draft
drop procedure customer_summary;

DELIMITER $$
CREATE PROCEDURE customer_summary(in p_customer_name TEXT)
BEGIN
	SELECT
    i.customer_name,
		ROUND(SUM(i.charge), 2) AS total_spend,
		SUM(CASE WHEN YEAR(i.date) = YEAR(CURDATE()) THEN ROUND(i.charge, 2) ELSE 0 END) AS spend_this_year,
		MAX(CASE WHEN date = NULL THEN 'No Purchase History' ELSE i.date END) AS most_recent_purchase_date,
		SUM(CASE WHEN i.date = r.max_date THEN ROUND(i.charge, 2) ELSE 0 END) AS most_recent_spend
	FROM international_sales i
	JOIN (
		SELECT customer_name, MAX(date) AS max_date
		FROM international_sales
		GROUP BY customer_name
	) r ON i.customer_name = r.customer_name
	WHERE i.customer_name LIKE CONCAT('%', p_customer_name, '%')
	GROUP BY i.customer_name;
    
    END $$
    
    DELIMITER ;
    
    CALL customer_summary('on');

WITH most_recent_purchase AS (
		SELECT customer_name, MAX(date) AS max_date
		FROM international_sales
		GROUP BY customer_name)	
SELECT
    i.customer_name,
	ROUND(SUM(i.charge), 2) AS total_spend,
	SUM(CASE WHEN YEAR(i.date) = YEAR(CURDATE()) THEN ROUND(i.charge, 2) ELSE 0 END) AS spend_this_year,
	MAX(CASE WHEN date IS NULL THEN 'No Purchase History' ELSE m.max_date END) AS most_recent_purchase_date,
	SUM(CASE WHEN i.date = m.max_date THEN ROUND(i.charge, 2) ELSE 0 END) AS most_recent_spend
	FROM international_sales i
	JOIN 
		most_recent_purchase m ON i.customer_name = m.customer_name
	WHERE i.customer_name LIKE '%AMANI%'
	GROUP BY i.customer_name;
    

    SELECT
		RANK() OVER (ORDER BY SUM(charge) DESC) AS `rank`,
		customer_name,
        sum(charge) AS total_spend
	FROM
		international_sales
	GROUP BY customer_name
	ORDER BY `rank`;
 
 #Adding CTE for the yearly sum
 
 WITH 2021_spend AS (
	SELECT
		customer_name,
        sum(charge) AS yearly_spend
	FROM
		international_sales
	WHERE
		year(date) = '2021'
	GROUP BY
		customer_name
	), 
 2022_spend AS (
	SELECT
		customer_name,
        sum(charge) AS yearly_spend
	FROM
		international_sales
	WHERE
		year(date) = '2022'
	GROUP BY
		customer_name
	) 
SELECT
	RANK() OVER (ORDER BY SUM(i.charge) DESC) AS overall_rank,
	i.customer_name,
	ROUND(sum(i.charge), 2) AS total_spend,
    RANK() OVER (ORDER BY SUM(o.yearly_spend) DESC) AS `Rank (2021)`,
    o.yearly_spend AS `2021_spend`,
	RANK() OVER (ORDER BY SUM(t.yearly_spend) DESC) `Rank (2022)`,
    t.yearly_spend AS `2022_spend`
FROM
	international_sales i
JOIN
	2021_spend o ON o.customer_name = i.customer_name
JOIN
	2022_spend t ON t.customer_name = i.customer_name
GROUP BY customer_name
ORDER BY overall_rank;

select customer_name, sum(charge)
FROM international_sales
WHERE customer_name LIKE '%Mulberries%'
GROUP BY customer_name; #Just a check to make sure my totals are working

#Top selling items - The sku code - any kind of name for the item, number sold, total spent on it and rank, avg spent on it
#                                                       Category?
# May need to use a union here because of the date field
SELECT
	MONTH(sr.date),
	sr.sku,
    sr.category,
    SUM(sr.qty),
    SUM(CASE WHEN sr.qty = 0 THEN 0 ELSE sr.amount END) + SUM(ints.charge) AS total_revenue,
	RANK() OVER (PARTITION BY total_revenue ORDER BY total_revenue DESC),
    SUM(sr.qty) + COUNT(ints.sku) AS total_sold
FROM
	sales_report sr
JOIN
	international_sales ints ON sr.sku = ints.sku
    GROUP BY sr.sku;
    
    
SELECT
*
from
sales_report
WHERE
status = 'Cancelled';

SELECT * FROM international_sales WHERE quantity = 0;

SELECT DISTINCT status FROM sales_report;

SELECT status, COUNT(status) FROM sales_report GROUP BY status;

SELECT status, COUNT(status) FROM sales_report WHERE status = 'Shipped' OR status = 'Shipped - Delivered to Buyer' GROUP BY status;

SELECT DISTINCT
	qty
FROM
	sales_report;
    
SELECT
*
FROM
sales_report
WHERE
qty > 1;

SELECT
*
FROM
international_sales
WHERE
quantity > 1;

SELECT
*
FROM
international_sales
WHERE
sku = 'J0023-TP-M'; #Amount is the total paid, no need to multiply it. Charge is also a total paid field.
    
SELECT
	sr.sku,
	SUM(CASE WHEN sr.qty = 0 THEN 0 ELSE sr.amount END) + SUM(ints.charge) AS total_revenue,
    SUM(CASE WHEN sr.qty = 0 THEN 0 ELSE sr.amount END) AS national_sales,
    SUM(ints.charge) AS international_sales,
	SUM(sr.qty) + COUNT(ints.sku) AS total_sold
FROM
	sales_report sr
JOIN
	international_sales ints ON sr.sku = ints.sku
GROUP BY sku
ORDER BY sku DESC;

ALTER TABLE sales_report
MODIFY COLUMN date DATE;

WITH all_sales AS (
	SELECT
		date,											#Date from sales report
        NULL AS customer_name,							#Customer name NULL for international sales
        category,										#Adding category from sales report
        qty,											#qty (quantity) from sales report
        amount											#Amount (spent) from sales report
	FROM
		sales_report
	WHERE
		status IN ('Shipped', 'Shipped - Delivered to Buyer')
/* Cancelled items still appear with qty and amount sometimes, but shouldn't be included in revenue figures (Most (>80%) orders fall within one of these categories,
other orders may still fall through at this point due to cancellations, loss, returns etc., so have been excluded */
	UNION ALL
	SELECT
		i.date,											#Date from international sales
        i.customer_name,								#Customer name from international sales
        st.category,
        i.quantity AS qty,								#quantity as qty from international sales
        i.charge AS amount								#charge (amount spent) from international sales
	FROM
		international_sales i
	JOIN
		item_stock st ON st.sku_code = i.sku
	),
combined_sales AS (										#Aggregate by product (sku) and date
	SELECT
		date,										
        category,
        SUM(qty) AS total_sold,
        SUM(CASE WHEN qty > 0 THEN amount ELSE 0 END) AS total_revenue
	FROM
		all_sales
	GROUP BY
		date, category
	)
SELECT
	date_format(date, '%m-%Y') AS `date`,
    category,
	RANK() OVER(PARTITION BY YEAR(date), MONTH(date) ORDER BY total_revenue DESC) AS total_ranking,
    total_revenue,
	RANK() OVER(PARTITION BY YEAR(date), MONTH(date) ORDER BY total_sold DESC) AS items_sold_ranking,
    total_sold
FROM
	combined_sales
GROUP BY
	category
ORDER BY
	`date` DESC, total_ranking ASC;
    
/* Currently, I want the above to show the top categories, by month i.e. grouped by category */

        
SELECT * FROM international_sales;

SELECT * FROM international_sales WHERE quantity IS NOT NULL;
	 
SELECT * FROM sales_report 	WHERE status IN ('Shipped', 'Shipped - Delivered to Buyer') AND qty = 0;

SELECT * FROM sales_report WHERE sku = 'JNE3797-KR-XL' AND status IN ('Shipped', 'Shipped - Delivered to Buyer');


#Testing CTEs - they work fine

SELECT
	order_id,
	date,
	NULL AS customer_name,
	sku,
	qty,
	amount
FROM
	sales_report
WHERE
	status IN ('Shipped', 'Shipped - Delivered to Buyer')
UNION ALL
SELECT
	NULL AS order_id,
	date,
	customer_name,
	sku,
	quantity AS qty,
	charge AS amount
FROM
	international_sales
GROUP BY date, customer_name, sku, quantity, charge;

# Working on top cities ranked by revenue over the whole time period
#Fields: Cities grouped, sum of revenue

SELECT
	RANK() OVER (ORDER BY SUM(amount) DESC) AS city_rank,
	ship_city,
    ship_state,
    SUM(amount) AS total_revenue
FROM
	sales_report
WHERE
	status IN ('Shipped', 'Shipped - Delivered to Buyer') AND qty > 0 AND ship_city IS NOT NULL
GROUP BY
	ship_city, ship_state
ORDER BY total_revenue DESC
LIMIT 100;

SELECT * FROM sales_report WHERE ship_city IS NULL;


# Standard revenue report - FIELDS: Month, domestic revenue, international revenue, total revenue

WITH combined_revenue AS (
	SELECT
		date,
        amount,
        NULL AS charge
	FROM
		sales_report
	WHERE
		status IN ('Shipped', 'Shipped - Delivered to Buyer') AND qty > 0 
	UNION ALL
	SELECT
		date,
        NULL AS amount,
        charge
	FROM
		international_sales
	)
SELECT
	YEAR(date) AS year,
    MONTH(date) AS month,
    SUM(COALESCE(amount,0)) AS domestic_revenue,
    SUM(COALESCE(charge,0)) AS international_revenue,
    SUM(COALESCE(amount,0)) + SUM(COALESCE(charge,0)) AS total_revenue
FROM
	combined_revenue
ORDER BY `date`, total_revenue DESC;
        
#CTE Test

	SELECT
		date,
        amount,
        NULL AS charge
	FROM
		sales_report
	WHERE
		status IN ('Shipped', 'Shipped - Delivered to Buyer') AND qty > 0 
	UNION ALL
	SELECT
		date,
        NULL AS amount,
        charge
	FROM
		international_sales;
        
#New Version

WITH combined_revenue AS (
    SELECT
        date,
        amount,
        NULL AS charge
    FROM sales_report
    WHERE status IN ('Shipped', 'Shipped - Delivered to Buyer') AND qty > 0 

    UNION ALL

    SELECT
        date,
        NULL AS amount,
        charge
    FROM international_sales
),
monthly_revenue AS (
    SELECT
        YEAR(date) AS year,
        MONTH(date) AS month,
        SUM(COALESCE(amount,0)) AS domestic_revenue,
        SUM(COALESCE(charge,0)) AS international_revenue,
        SUM(COALESCE(amount,0)) + SUM(COALESCE(charge,0)) AS total_revenue
    FROM combined_revenue
    GROUP BY YEAR(date), MONTH(date)
)
SELECT
    year,
    month,
    ROUND(domestic_revenue,2) AS `Domestic Revenue`,
    ROUND(international_revenue,2) AS `International Revenue`,
    ROUND(total_revenue,2) AS `Total Revenue`
FROM monthly_revenue
ORDER BY year, month;

SELECT DISTINCT MONTH(date) FROM sales_report;


# Checking for churn
# So... create a table of repeat customers, where orders, grouped by date, are greater than one

with separate_orders as (
	SELECT
		date,
		customer_name
	FROM
		international_sales
	GROUP BY
		date, customer_name
    ),
repeat_customers AS (
	SELECT
		customer_name,
		COUNT(customer_name) AS separate_order_count
	FROM
		separate_orders
	GROUP BY
		customer_name
	HAVING	
		separate_order_count > 1
    )
#Final table Customer | last order date | time since last order | flag?
SELECT
	rc.customer_name,
    MAX(i.date) AS last_order,
    TIMESTAMPDIFF(day, MAX(i.date), '2022-05-11') AS days_since_last_order,
    CASE WHEN TIMESTAMPDIFF(day, MAX(i.date), '2022-05-11') > 90 THEN 'Yes' ELSE 'No' END AS Flag
FROM
	repeat_customers rc
INNER JOIN
	international_sales i ON i.customer_name = rc.customer_name
GROUP BY
	customer_name
ORDER BY
	days_since_last_order DESC;



#CTE Test

WITH separate_orders as ( #This CTE works and does what it's supposed to
	SELECT
		date,
		customer_name
	FROM
		international_sales
	GROUP BY
		date, customer_name
    )
SELECT
	customer_name,
	COUNT(customer_name) AS separate_order_count
FROM
	separate_orders
GROUP BY
	customer_name
HAVING	
	separate_order_count > 1
ORDER BY
	separate_order_count DESC; # This does what it's supposed to but can delete the ORDER BY
    
SELECT
	max(date)
FROM
	international_sales;
    
SELECT date(now());

# Creating best-selling categories

WITH all_sales AS (
	SELECT
		order_id,										#Order ID from sales report
		date,											#Date from sales report
        NULL AS customer_name,							#Customer name NULL for international sales
        category,										#Adding category from sales report
        qty,											#qty (quantity) from sales report
        amount											#Amount (spent) from sales report
	FROM
		sales_report
	WHERE
		status IN ('Shipped', 'Shipped - Delivered to Buyer')
/* Cancelled items still appear with qty and amount sometimes, but shouldn't be included in revenue figures (Most (>80%) orders fall within one of these categories,
other orders may still fall through at this point due to cancellations, loss, returns etc., so have been excluded */
	UNION ALL
	SELECT
		NULL AS order_id,								#order id NULL for sales report
		i.date,											#Date from international sales
        i.customer_name,									#Customer name from international sales
        st.category,
        i.quantity AS qty,								#quantity as qty from international sales
        i.charge AS amount								#charge (amount spent) from international sales
	FROM
		international_sales i
	JOIN
		item_stock st ON st.sku_code = i.sku
	),
combined_sales AS (										#Aggregate by product (sku) and date
	SELECT
		date_format(date, '%Y-%m') AS `date`,
        category,
        SUM(qty) AS total_sold,
        SUM(CASE WHEN qty > 0 THEN amount ELSE 0 END) AS total_revenue
	FROM
		all_sales
	GROUP BY
		date_format(date, '%Y-%m'), category
	)
SELECT
	date,
    category,
	RANK() OVER(PARTITION BY date ORDER BY total_revenue DESC) AS total_ranking,
    total_revenue,
	RANK() OVER(PARTITION BY date ORDER BY total_sold DESC) AS items_sold_ranking,
    total_sold
FROM
	combined_sales
ORDER BY
	`date` DESC, total_revenue DESC;
    
    #Top categories overall
    
    WITH all_sales AS (
	SELECT
		order_id,										#Order ID from sales report
        NULL AS customer_name,							#Customer name NULL for international sales
        category,										#Adding category from sales report
        qty,											#qty (quantity) from sales report
        amount											#Amount (spent) from sales report
	FROM
		sales_report
	WHERE
		status IN ('Shipped', 'Shipped - Delivered to Buyer')
/* Cancelled items still appear with qty and amount sometimes, but shouldn't be included in revenue figures (Most (>80%) orders fall within one of these categories,
other orders may still fall through at this point due to cancellations, loss, returns etc., so have been excluded */
	UNION ALL
	SELECT
		NULL AS order_id,								#order id NULL for sales report
        i.customer_name,									#Customer name from international sales
        st.category,
        i.quantity AS qty,								#quantity as qty from international sales
        i.charge AS amount								#charge (amount spent) from international sales
	FROM
		international_sales i
	JOIN
		item_stock st ON st.sku_code = i.sku
	),
combined_sales AS (										#Aggregate by product (sku) and date
	SELECT
        category,
        SUM(qty) AS total_sold,
        SUM(CASE WHEN qty > 0 THEN amount ELSE 0 END) AS total_revenue
	FROM
		all_sales
	GROUP BY
		category
	)
SELECT
    category,
	RANK() OVER(ORDER BY total_revenue DESC) AS total_ranking,
    total_revenue,
	RANK() OVER(ORDER BY total_sold DESC) AS items_sold_ranking,
    total_sold
FROM
	combined_sales
ORDER BY
	total_revenue DESC;
    
#Yes, it was only now that I remembered the existence of temporary tables *SHAME*   
DROP TABLE t_all_sales;
CREATE TEMPORARY TABLE t_all_sales
	SELECT
		order_id,										#Order ID from sales report
		date,											#Date from sales report
        NULL AS customer_name,							#Customer name NULL for international sales
        sku,											#sku from sales report
        category,
        qty,											#qty (quantity) from sales report
        amount											#Amount (spent) from sales report
	FROM
		sales_report
	WHERE
		status IN ('Shipped', 'Shipped - Delivered to Buyer')
	UNION ALL
	SELECT
		NULL AS order_id,								#order id NULL for sales report
		i.date,											#Date from international sales
        i.customer_name,									#Customer name from international sales
        i.sku,											#sku from international sales
        st.category,
        i.quantity AS qty,								#quantity as qty from international sales
        i.charge AS amount								#charge (amount spent) from international sales
	FROM
		international_sales i
	JOIN
		item_stock st ON st.sku_code = i.sku
	GROUP BY date, i.customer_name, i.sku, st.category, i.quantity, i.charge;
    
WITH combined_sales AS (										#Aggregate by product (sku) and date
	SELECT
        category,
        SUM(qty) AS total_sold,
        SUM(CASE WHEN qty > 0 THEN amount ELSE 0 END) AS total_revenue
	FROM
		t_all_sales
	GROUP BY
		category
	)
SELECT
    category,
	RANK() OVER(ORDER BY total_revenue DESC) AS total_ranking,
    total_revenue,
	RANK() OVER(ORDER BY total_sold DESC) AS items_sold_ranking,
    total_sold
FROM
	combined_sales
ORDER BY
	total_revenue DESC;
        

    