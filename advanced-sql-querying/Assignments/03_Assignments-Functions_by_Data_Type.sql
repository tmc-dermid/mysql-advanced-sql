-- Connect to database
USE maven_advanced_sql;

-- ASSIGNMENT 1: Numeric functions
-- Q: How many customers have spent $0-$10 on our products, $10-$20, and so on for every $10 range?

-- Calculate the total spend for each customer
SELECT
	o.customer_id,
    SUM(o.units * p.unit_price) AS total_spent
FROM orders o
INNER JOIN products p
	ON o.product_id = p.product_id
GROUP BY o.customer_id;

-- Put the spend into bins of $0-$10, $10-20, etc.
-- Number of customers in each spend bin
WITH total_amount_spend AS (
	SELECT
		o.customer_id,
		SUM(o.units * p.unit_price) AS total_spend
	FROM orders o
	INNER JOIN products p
		ON o.product_id = p.product_id
	GROUP BY o.customer_id
),
total_spend_rounded AS (
	SELECT
		customer_id,
		total_spend,
		FLOOR(total_spend / 10) * 10 AS total_spend_bin
	FROM total_amount_spend
)

SELECT
	total_spend_bin,
    COUNT(total_spend_bin) AS customers_num
FROM total_spend_rounded
GROUP BY total_spend_bin
ORDER BY total_spend_bin;


-- ASSIGNMENT 2: Datetime functions
-- Q: Select orders data from the second quarter of 2024.

-- Extract just the orders from Q2 2024
SELECT
	order_id,
    order_date
FROM orders
WHERE EXTRACT(year FROM order_date) = 2024
	AND QUARTER(order_date) = 2
ORDER BY order_date;

-- Add a column called ship_date that adds 2 days to each order date
SELECT
	order_id,
    order_date,
    DATE_ADD(order_date, INTERVAL 2 DAY) AS ship_date
FROM orders
WHERE EXTRACT(year FROM order_date) = 2024
	AND QUARTER(order_date) = 2
ORDER BY order_date;

-- Version more optimized:
SELECT
	order_id,
    order_date,
    DATE_ADD(order_date, INTERVAL 2 DAY) AS ship_date
FROM orders
WHERE order_date >= '2024-04-01'
	AND order_date < '2024-07-01'
ORDER BY order_date;

-- ASSIGNMENT 3: String functions
-- Q: Update product_ids to include the factory name and product name.

-- View the current factory names and product IDs
SELECT
	factory,
    product_id
FROM products;

-- Remove apostrophes and replace spaces with hyphens
SELECT
	factory,
    REPLACE(REPLACE(factory, "'", ""), ' ', '-') AS factory_clean,
    product_id
FROM products
ORDER BY factory;

-- Create new ID column called factory_product_id
WITH factory_cleaned AS (
	SELECT
		factory,
		REPLACE(REPLACE(factory, "'", ""), ' ', '-') AS factory_clean,
		product_id
	FROM products
    ORDER BY factory
)

SELECT
	factory,
    product_id,
    CONCAT(factory_clean, '-', product_id) AS factory_product_id
FROM factory_cleaned;


-- ASSIGNMENT 4: Pattern matching

-- View the product names
SELECT
	product_name
FROM products;

-- Only extract text after the hyphen for Wonka Bars
-- Using REPLACE
SELECT
	product_name,
    REPLACE(product_name, 'Wonka Bar - ', '') AS new_product_name
FROM products
WHERE product_name LIKE 'Wonka Bar%';

-- Using SUBSTR / INSTR
SELECT
	product_name,
    SUBSTR(product_name, INSTR(product_name, '-') + 2) AS new_product_name
FROM products
WHERE product_name LIKE 'Wonka Bar%';

-- Using REGEXP_SUBSTR()
SELECT
	product_name,
    REGEXP_SUBSTR(product_name, '[^-]+$') AS new_product_name
FROM products
WHERE product_name LIKE 'Wonka Bar%';

-- Using REGEXP_REPLACE()
SELECT
	product_name,
    REGEXP_REPLACE(product_name, '^.* - ', '') AS new_product_name
FROM products
WHERE product_name LIKE 'Wonka Bar%';

-- Returning the entire list of products
SELECT
	product_name,
    CASE
		WHEN INSTR(product_name, '-') = 0 THEN product_name
		ELSE SUBSTR(product_name, INSTR(product_name, '-') + 2)
	END AS new_product_name
FROM products;



-- ASSIGNMENT 5: Null functions
-- Q1: Update NULL division values to have a value of "Other".
-- Q2: Update NULL division values to be the same division as most common division within their respective factories.

-- View the columns of interest
SELECT
	product_name,
    factory,
    division
FROM products
ORDER BY factory, division;

-- Replace NULL values with Other
SELECT
	product_name,
    factory,
    division,
    COALESCE(division, 'Other') AS division_other
FROM products
ORDER BY factory, division;

-- Find the most common division for each factory
SELECT
	factory,
	division,
	COUNT(product_name) AS products_no
FROM products
WHERE division IS NOT NULL
GROUP BY factory, division
ORDER BY factory, division;

-- Replace NULL values with top division for each factory
WITH num_products AS (
	SELECT
		factory,
		division,
		COUNT(product_name) AS products_no
	FROM products
	WHERE division IS NOT NULL
	GROUP BY factory, division
	ORDER BY factory, division
),
num_products_ranked AS (
	SELECT
		factory,
		division,
		products_no,
		RANK() OVER(PARTITION BY factory ORDER BY products_no DESC) AS rank_no
	FROM num_products
),
top_division_factory AS (
	SELECT
		factory,
		division
	FROM num_products_ranked
	WHERE rank_no = 1
)

SELECT
	p.product_name,
    p.factory,
    p.division,
    COALESCE(p.division, tdf.division, 'Other') AS top_division
FROM products p
LEFT JOIN top_division_factory tdf
	ON p.factory = tdf.factory
ORDER BY p.factory, p.division;
