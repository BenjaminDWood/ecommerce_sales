# ERD: https://drawsql.app/teams/brightwood/diagrams/e-commerce-data 

USE ecommerce;

/* Creation of sales_report table for import from csv*/

DROP TABLE IF EXISTS sales_report;

CREATE TABLE `sales_report` (
    `index` BIGINT DEFAULT NULL,
    `order_id` TEXT,
    `date` DATETIME DEFAULT NULL,
    `status` TEXT,
    `fulfilment` TEXT,
    `sales_channel` TEXT,
    `ship_service_level` TEXT,
    `style` TEXT,
    `sku` TEXT,
    `category` TEXT,
    `size` TEXT,
    `asin` TEXT,
    `courier_status` TEXT,
    `qty` BIGINT DEFAULT NULL,
    `currency` TEXT,
    `amount` DOUBLE DEFAULT NULL,
    `ship_city` TEXT,
    `ship_state` TEXT,
    `ship_postal_code` DOUBLE DEFAULT NULL,
    `ship_country` TEXT,
    `promotion_ids` TEXT,
    `b2b` TINYINT(1) DEFAULT NULL,
    `fulfilled_by` TEXT
);

/* Creation of item_stock table from csv */

DROP TABLE IF EXISTS item_stock;
    
CREATE TABLE `ecommerce`.`item_stock` (
    `index` INT NOT NULL,
    `sku_code` VARCHAR(45) NULL,
    `design_no` VARCHAR(45) NULL,
    `stock` INT NULL,
    `category` VARCHAR(45) NULL,
    `size` VARCHAR(45) NULL,
    `color` VARCHAR(45) NULL,
    PRIMARY KEY (`index`)
);

/* Creation of international sales table from csv */

CREATE TABLE `ecommerce`.`international_sales` (
  `index` INT NOT NULL,
  `date` DATE NULL,
  `customer` VARCHAR(45) NULL,
  `sku` VARCHAR(45) NULL,
  `quantity` BIGINT NULL,
  `converted_price` FLOAT NULL,
  `charge` FLOAT NULL,
  PRIMARY KEY (`index`));
  
  /* Once again, fixing the date column (removing the 00:00:00 timestamp), plus rejigging the column names and datatypes */
  
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
  
ALTER TABLE international_sales
MODIFY COLUMN date DATE;

ALTER TABLE sales_report
MODIFY COLUMN date DATE;

/* Stored procedure to look up information on a single order, included product information including stock for refund/replacement requirements */

DELIMITER $$
CREATE PROCEDURE find_order(in p_order_id TEXT)
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

CALL find_order('402-8210765-3935569');

/* Creation of a stored procedure to provide a brief customer summary using a LIKE name input match, showing the customer name, their total spend,
their spend this year - which is always 0 as the records don't go back that far -, and the date and sum of their most recent purchase */

DELIMITER $$
CREATE PROCEDURE customer_summary(in p_customer_name TEXT)
BEGIN
	WITH most_recent_purchase AS (
		SELECT customer_name, MAX(date) AS max_date
		FROM international_sales
		GROUP BY customer_name)	#CTE for the most recent purchase
	SELECT
    i.customer_name,
		ROUND(SUM(i.charge), 2) AS total_spend,
		SUM(CASE WHEN YEAR(i.date) = YEAR(CURDATE()) THEN ROUND(i.charge, 2) ELSE 0 END) AS spend_this_year,
		MAX(CASE WHEN date = NULL THEN 'No Purchase History' ELSE m.max_date END) AS most_recent_purchase_date,
		SUM(CASE WHEN i.date = m.max_date THEN ROUND(i.charge, 2) ELSE 0 END) AS most_recent_spend
	FROM international_sales i
	JOIN 
		most_recent_purchase m ON i.customer_name = m.customer_name
	WHERE i.customer_name LIKE CONCAT('%', p_customer_name, '%')
	GROUP BY i.customer_name;
    
    END $$
    
    DELIMITER ;
    
    CALL customer_summary('amani');

/*Ranking table of the top customers including their overall rank and spend, plus their rank and spend for each of the two years using CTEs
(NOTE: This is not the way I'd do this were there multiple years, but for two years only it seemed much cleaner and easier to simply have the two CTEs */

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
    ROUND(o.yearly_spend, 2) AS `2021_spend`,
	RANK() OVER (ORDER BY SUM(t.yearly_spend) DESC) `Rank (2022)`,
    ROUND(t.yearly_spend, 2) AS `2022_spend`
FROM
	international_sales i
JOIN
	2021_spend o ON o.customer_name = i.customer_name
JOIN
	2022_spend t ON t.customer_name = i.customer_name
GROUP BY customer_name
ORDER BY overall_rank;

/* Below queries show firstly the top ranking products over the time period, then segregated by month to check for seasonal variations. Category has been included
to help with readability. */


CREATE TEMPORARY TABLE t_all_sales # Temporary Table to combine sales from both the sales_report and international_sales
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
/* Cancelled items still appear with qty and amount sometimes, but shouldn't be included in revenue figures
(Most (>80%) orders fall within one of these categories, other orders may still fall through at this point due to cancellations, loss, returns etc., so have been excluded */
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
		date,										
		sku,
        category,
        SUM(qty) AS total_sold,
        ROUND(SUM(CASE WHEN qty > 0 THEN amount ELSE 0 END), 2) AS total_revenue
	FROM
		t_all_sales
	GROUP BY
		date, sku, category
	)
SELECT
	sku,
    category,
	RANK() OVER(ORDER BY total_revenue DESC) AS total_ranking,
    total_revenue,
	RANK() OVER(ORDER BY total_sold DESC) AS items_sold_ranking,
    total_sold
FROM
	combined_sales
GROUP BY
	sku, category, total_revenue, total_sold
ORDER BY
	total_revenue DESC;
    

#Query 2: Top products by month

WITH combined_sales AS (										#Aggregate by product (sku) and date
	SELECT
		date,										
		sku,
        category,
        SUM(qty) AS total_sold,
        ROUND(SUM(CASE WHEN qty > 0 THEN amount ELSE 0 END), 2) AS total_revenue
	FROM
		t_all_sales
	GROUP BY
		date, sku, category
	)
SELECT
	date_format(date, '%Y-%m') AS `date`,
	sku,
    category,
	RANK() OVER(PARTITION BY YEAR(date), MONTH(date) ORDER BY total_revenue DESC) AS total_ranking,
    total_revenue,
	RANK() OVER(PARTITION BY YEAR(date), MONTH(date) ORDER BY total_sold DESC) AS items_sold_ranking,
    total_sold
FROM
	combined_sales
GROUP BY
	`date`, sku, category, total_revenue, total_sold
ORDER BY
	`date` DESC, total_revenue DESC;
    
#Query 3: Top categories by month

WITH combined_sales AS (										
	SELECT
		date_format(date, '%Y-%m') AS `date`,
        category,
        SUM(qty) AS total_sold,
        SUM(CASE WHEN qty > 0 THEN amount ELSE 0 END) AS total_revenue
	FROM
		t_all_sales
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
    
#Query 4: Top categories over the whole time period

WITH combined_sales AS (									
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
    
    
/* Returning revenue by location, excluding 33 results where ship_city is null. Limited the results to 100 as there are over 1000 rows anyway and e.g. the top 10 could be picked
later for marketing purposes */

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

/* Revenue Report: Combined revenue from domestic and international sales by month. Having 0 revenue for so many months domestically presents as an error, but is actually
what the data contains. */

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

/* Customer Churn table: Checking for repeat customers in international sales and flagging those who haven't placed an order in more than 90 days
NOTE: The 90 day limit is from the final date in the dataset for testing purposes and would be replaced by DATE(NOW()) in a live dataset
May now add a tiered churn for the below at 60 and 120 days */

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
SELECT
	rc.customer_name,
    MAX(i.date) AS last_order,
    TIMESTAMPDIFF(day, MAX(i.date), '2022-05-11') AS days_since_last_order,
    CASE
		WHEN TIMESTAMPDIFF(day, MAX(i.date), '2022-05-11') >= 120 THEN 'flag_120'
		WHEN TIMESTAMPDIFF(day, MAX(i.date), '2022-05-11') >= 90 THEN 'flag_90'
		WHEN TIMESTAMPDIFF(day, MAX(i.date), '2022-05-11') >= 60 THEN 'flag_60'
		ELSE 'No'
        END AS flag #Note the date in these queries is the most recent date available in the dataset
FROM
	repeat_customers rc
INNER JOIN
	international_sales i ON i.customer_name = rc.customer_name
GROUP BY
	customer_name
ORDER BY
	days_since_last_order DESC;


 
