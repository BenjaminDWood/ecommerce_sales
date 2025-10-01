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

/* Stored procedure to look up information on a single order, included product information including stock for refund/replacement requirements */

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


/* IDEAS: Top customer (by year?) DONE / top selling item(by year? Monthly trends?) / Total Revenue by month/year etc. / 
Best-selling CATEGORIES / Explore customer orders in general: can we predict churn, look at repeat orders etc. / Use ship city to determine the locations with the most orders! */


 
