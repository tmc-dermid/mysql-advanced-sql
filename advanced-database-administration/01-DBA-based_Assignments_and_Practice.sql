CREATE SCHEMA IF NOT EXISTS mavenbearbuilders;

USE mavenbearbuilders;

-- Create tables to populate them using the Table Data Import Wizard
CREATE TABLE order_items (
	order_item_id BIGINT,
    created_at DATETIME,
    order_id BIGINT,
    price_usd DECIMAL(10,2),
    cogs_usd DECIMAL(10,2),
    website_session_id BIGINT,
    
    PRIMARY KEY (order_item_id)
);

SELECT * FROM order_items;

SELECT
	MIN(created_at),
	MAX(created_at)
FROM order_items;


CREATE TABLE order_item_refunds (
	order_item_refund_id BIGINT,
    created_at DATETIME,
    order_item_id BIGINT,
    order_id BIGINT,
    refund_amount_usd DECIMAL(10,2),
    
    PRIMARY KEY (order_item_refund_id),
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id)
);

SELECT * FROM order_item_refunds;


-- Delete order_item_ids with the id of: 131, 132, 145, 151 and 153
-- Remember to use a PK column in WHERE clause when doing DELETE FROM
SELECT order_item_refund_id
FROM order_item_refunds
WHERE order_item_id IN (131, 132, 145, 151, 153);

DELETE FROM order_item_refunds
WHERE order_item_refund_id BETWEEN 6 AND 10;

-- Create a new products table and add some new products
CREATE TABLE products (
	product_id BIGINT,
    launched_at DATETIME,
    product_name VARCHAR(100),
    
    PRIMARY KEY (product_id)
);

INSERT INTO products
VALUES
	(1, '2012-03-19 09:00:00', 'The Original Mr. Fuzzy'),
    (2, '2013-01-06 13:00:00', 'The Forever Love Bear');
    
SELECT * FROM products;


-- Add a column to order_items table that references the products table by product_id
ALTER TABLE order_items
ADD COLUMN product_id BIGINT;

ALTER TABLE order_items
ADD FOREIGN KEY (product_id) REFERENCES products(product_id);

SELECT * FROM order_items;


-- Replace all NULL values with product_id = 1
UPDATE order_items
SET product_id = 1
WHERE order_item_id > 0;


-- Add a binary column to the order_items table called is_primary_item
ALTER TABLE order_items
ADD COLUMN is_primary_item BOOLEAN;

SELECT * FROM order_items;

UPDATE order_items
SET is_primary_item = 1
WHERE order_item_id > 0;

SELECT * FROM order_items;


-- Add two new products to the products table
INSERT INTO products
VALUES
	(3, '2013-12-12 09:00:00', 'The Birthday Sugar Panda'),
    (4, '2014-02-05 10:00:00', 'The Hudson River Mini bear');
    
SELECT * FROM products;


-- Create an order summary table and back-populate the table using the records from order_items
CREATE TABLE orders (
	order_id BIGINT,
    created_at DATETIME,
    website_session_id BIGINT,
    primary_product_id BIGINT,
    items_purchased BIGINT,
    price DECIMAL(10,2),
    cogs DECIMAL(10,2),
    
    PRIMARY KEY (order_id)
);

INSERT INTO orders
SELECT
	order_id,
    MIN(created_at) AS created_at,
    MIN(website_session_id) AS website_session_id,
    SUM(CASE
		WHEN is_primary_item = 1 THEN product_id
        ELSE NULL
        END) AS primary_product_id,
    COUNT(order_item_id) AS items_purchased,
    SUM(price_usd) AS price_usd,
    SUM(cogs_usd) AS cogs_usd
FROM order_items
GROUP BY order_id
ORDER BY order_id;
    
SELECT * FROM orders;

SELECT * FROM order_items;


-- Create a trigger so that anytime order_items records are inserted into the database, the orders table is updated as well
CREATE TRIGGER insertNewOrders
AFTER INSERT ON order_items
FOR EACH ROW
	REPLACE INTO orders
    SELECT
		order_id,
		MIN(created_at) AS created_at,
		MIN(website_session_id) AS website_session_id,
		SUM(CASE
			WHEN is_primary_item = 1 THEN product_id
			ELSE NULL
			END) AS primary_product_id,
		COUNT(order_item_id) AS items_purchased,
		SUM(price_usd) AS price_usd,
		SUM(cogs_usd) AS cogs_usd
    FROM order_items
    WHERE order_id = NEW.order_id
    GROUP BY order_id
    ORDER BY order_id;

SHOW TRIGGERS;

SELECT * FROM orders;


-- Create a website_sessions table and import data to this table
CREATE TABLE website_sessions (
	website_session_id BIGINT,
	created_at DATETIME,
	user_id BIGINT,
	is_repeat_session BOOLEAN,
	utm_source VARCHAR(50),
	utm_campaign VARCHAR(50),
	utm_content VARCHAR(50),
	device_type VARCHAR(25),
	http_referer VARCHAR(100),
    
    PRIMARY KEY (website_session_id)
);

SELECT * FROM website_sessions;

-- Create a view summarizing performance for January and February
-- Show year, month, utm_source, utm_campaign and number of sessions
CREATE VIEW monthly_sessions AS
SELECT
	YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    utm_source,
    utm_campaign,
    COUNT(website_session_id) AS number_of_sessions
FROM website_sessions
GROUP BY year, month, utm_source, utm_campaign;

SELECT * FROM monthly_sessions;


-- Create a Stored Procedure to see total orders and revenue for a given time period (startDate and endDate)

USE mavenbearbuilders;

SELECT * FROM orders;

DELIMITER //

CREATE PROCEDURE sp_showOrderPerformance(IN startDate DATE, IN endDate DATE)
BEGIN
	SELECT
		COUNT(order_id) AS total_orders,
        SUM(price_usd) AS total_revenue
    FROM orders
    WHERE CAST(created_at AS DATE) BETWEEN startDate AND endDate;
END //

DELIMITER ;


CALL sp_showOrderPerformance('2013-11-01', '2013-12-31');


-- Create a new table website_pageviews and populate the table via importing data
CREATE TABLE website_pageviews (
	website_pageview_id BIGINT,
    created_at DATETIME,
    website_session_id BIGINT,
    pageview_url VARCHAR(100),
    
    PRIMARY KEY (website_pageview_id)
);


SELECT * FROM website_pageviews;


-- =-= Final Project =-=
-- The company is adding chat support to the website.
-- Design a database plan to track which customers and sessions utilize chat, and which chat representatives serve each customer.

-- users (user_id, created_at, first_name, last_name)
-- chat_representatives(chat_representative_id, created_at, first_name, last_name)
-- chat_sessions(chat_session_id, created_at, chat_representative_id, user_id, website_session_id)
-- chat_messages(chat_message_id, created_at, chat_session_id, user_id, chat_representative_id, message_content)


-- Create the tables from the chat support tracking plan and include relationships to existing tables
CREATE TABLE users (
	user_id BIGINT,
    created_at DATETIME,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    
    PRIMARY KEY (user_id)
);

CREATE TABLE chat_representatives (
	chat_representative_id BIGINT,
    created_at DATETIME,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    
    PRIMARY KEY (chat_representative_id)
);

CREATE TABLE chat_sessions (
	chat_session_id BIGINT,
    created_at DATETIME,
    chat_representative_id BIGINT,
    user_id BIGINT,
    website_session_id BIGINT,
    
    PRIMARY KEY (chat_session_id),
    FOREIGN KEY (chat_representative_id) REFERENCES chat_representatives(chat_representative_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (website_session_id) REFERENCES website_sessions(website_session_id)
);

CREATE TABLE chat_messages (
	chat_message_id BIGINT,
    created_at DATETIME,
    chat_session_id BIGINT,
    user_id BIGINT,
    chat_representative_id BIGINT,
	message_content VARCHAR(200),
    
	PRIMARY KEY (chat_message_id),
    FOREIGN KEY (chat_session_id) REFERENCES chat_sessions(chat_session_id),
	FOREIGN KEY (user_id) REFERENCES users(user_id),
	FOREIGN KEY (chat_representative_id) REFERENCES chat_representatives(chat_representative_id)
);

-- Create a Stored Procedure to pull a count of chats handled by a given chat representative for a given time period.
DELIMITER //

CREATE PROCEDURE sp_showChatsCountForRepresentative(IN rep_id BIGINT, IN startDate DATE, IN endDate DATE)
BEGIN
	SELECT
		COUNT(chat_session_id) AS chats_handled
    FROM chat_sessions
    WHERE chat_representative_id = rep_id
		AND DATE(created_at) BETWEEN startDate AND endDate;
END //

DELIMITER ;

-- Call a procedure
CALL sp_showChatsCountForRepresentative(1, '2014-01-01', '2014-01-31');


-- Create two Views, one detailing monthly order volume and revenue, the other showing monthly website traffic.
CREATE VIEW monthly_orders_revenue AS
SELECT
	YEAR(created_at) AS year,
 	MONTH(created_at) AS month,
    COUNT(order_id) AS orders_count,
    SUM(price_usd) AS revenue
FROM orders
GROUP BY year, month
ORDER BY year, month;

SELECT * FROM monthly_orders_revenue;


CREATE VIEW monthly_website_sessions AS
SELECT 
	YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    COUNT(website_session_id) AS sessions_count
FROM website_sessions
GROUP BY year, month
ORDER BY year, month;

SELECT * FROM monthly_website_sessions;

-- Create the final EER Diagram (Enhanced Entity-Relationship Diagram) using the Reverse Engineering process


-- =-= PRACTICE =-=

-- Triggers
USE thriftshop;

SELECT * FROM customer_purchases;

SELECT * FROM purchase_summary;

CREATE TRIGGER updatePurchaseSummary_before
BEFORE INSERT ON customer_purchases
FOR EACH ROW
	UPDATE purchase_summary
    SET purchase_excluding_last = (
		SELECT COUNT(customer_purchase_id)
        FROM customer_purchases
        WHERE customer_purchases.customer_id = purchase_summary.customer_id
    )
	WHERE customer_id = NEW.customer_id -- WHERE purchase_summary.customer_id MATCHES the new records' customer_id IN customer_purchases table
		AND purchase_summary_id > 0; -- to handle safe update mode

CREATE TRIGGER updatePurchaseSummary_after
AFTER INSERT ON customer_purchases
FOR EACH ROW
	UPDATE purchase_summary
    SET total_purchases = (
		SELECT COUNT(customer_purchase_id)
        FROM customer_purchases
        WHERE customer_purchases.customer_id = purchase_summary.customer_id
    )
	WHERE customer_id = NEW.customer_id
		AND purchase_summary_id > 0; -- to handle safe update mode

SHOW TRIGGERS;

INSERT INTO customer_purchases
VALUES (13, 6, 4);

SELECT * FROM purchase_summary;


-- Views
USE survey;

SELECT * FROM salary_survey;

CREATE VIEW country_averages AS
SELECT
	country,
    COUNT(*) AS respondents,
    AVG(years_experience) AS avg_yrs_experience,
    ROUND(AVG(CASE WHEN is_manager = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS pct_manager,
    ROUND(AVG(CASE WHEN education_level = 'Masters' THEN 1 ELSE 0 END) * 100, 2) AS pct_masters
FROM salary_survey
GROUP BY country
ORDER BY respondents DESC;

SELECT * FROM country_averages;


-- Stored Procedures
USE mavenmovies;

SELECT *
FROM rental
WHERE customer_id = 135;

DELIMITER //

CREATE PROCEDURE sp_showCustomerRentals(IN custid BIGINT)
BEGIN
	SELECT * FROM rental WHERE customer_id = custid;
END //

DELIMITER ;


CALL sp_showCustomerRentals(135);


DELIMITER //

CREATE PROCEDURE sp_showCustomerRentalsAndTotal(IN custid BIGINT, OUT total_rentals BIGINT)
BEGIN
	SELECT * FROM rental WHERE customer_id = custid;
    
    SELECT COUNT(rental_id) INTO total_rentals FROM rental WHERE customer_id = custid;
END //

DELIMITER ;


CALL sp_showCustomerRentalsAndTotal(135, @total_rentals);

SELECT @total_rentals;


-- Scheduled Events
CREATE SCHEMA schema_for_events;

USE schema_for_events;

CREATE TABLE the_table (
	timestamps_via_event DATETIME
);

SELECT * FROM the_table;

-- Example with ... ON SCHEDULE AT ...
CREATE EVENT first_event_at
ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 15 SECOND
DO
	INSERT INTO the_table
    VALUES (NOW());

-- Example with ... ON SCHEDULE EVERY ...
CREATE EVENT first_event_every
ON SCHEDULE
	EVERY 15 SECOND
    STARTS CURRENT_TIMESTAMP
    ENDS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
DO
	INSERT INTO the_table
    VALUES (NOW());

SHOW EVENTS;

SELECT * FROM the_table;


