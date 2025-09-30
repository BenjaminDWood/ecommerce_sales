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
SELECT 
	date_format(date, '%Y-%m') AS Month,
    customer_name, 
    SUM(charge) AS `Total Spent`
FROM
    international_sales
GROUP BY
    year(date),
    month(date),
    date,
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






