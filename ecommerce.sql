USE ecommerce;

/* Ceation of sales_report table for import from csv*/

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

/* Creation of international sales table from 


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



