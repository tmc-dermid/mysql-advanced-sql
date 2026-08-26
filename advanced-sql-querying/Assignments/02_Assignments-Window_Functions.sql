-- Connect to database
USE maven_advanced_sql;

-- ASSIGNMENT 1: Window function basics

-- View the orders table
SELECT * FROM orders;

-- View the columns of interest
SELECT
	customer_id,
    order_id,
    order_date,
    transaction_id
FROM orders;

-- For each customer, add a column for transaction number
SELECT
	customer_id,
    order_id,
    order_date,
    transaction_id,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY transaction_id) AS transaction_num
FROM orders;

-- ASSIGNMENT 2: Row Number vs Rank vs Dense Rank

-- View the columns of interest
SELECT
	order_id,
    product_id,
    units
FROM orders;

-- Try ROW_NUMBER to rank the units
SELECT
	order_id,
    product_id,
    units,
    ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY units DESC) AS row_num
FROM orders
ORDER BY order_id, row_num;

-- For each order, rank the products from most units to fewest units
-- If there's a tie, keep the tie and don't skip to the next number after
SELECT
	order_id,
    product_id,
    units,
    DENSE_RANK() OVER(PARTITION BY order_id ORDER BY units DESC) AS rank_no
FROM orders
ORDER BY order_id, rank_no;

-- Check the order id that ends with 44262 from the results preview
SELECT
	order_id,
    product_id,
    units,
    DENSE_RANK() OVER(PARTITION BY order_id ORDER BY units DESC) AS rank_no
FROM orders
WHERE order_id LIKE '%44262'
ORDER BY order_id, rank_no;

-- ASSIGNMENT 3: First Value vs Last Value vs Nth Value

-- View the rankings from the last assignment

-- Add a column that contains the 2nd most popular product
SELECT
	order_id,
	product_id,
	units,
	NTH_VALUE(product_id, 2) OVER(PARTITION BY order_id ORDER BY units DESC) AS second_product
FROM orders
ORDER BY order_id;
    
-- Return the 2nd most popular product for each order
WITH sec_pop_prod AS (
	SELECT
		order_id,
		product_id,
		units,
		NTH_VALUE(product_id, 2) OVER(PARTITION BY order_id ORDER BY units DESC) AS second_product
	FROM orders
	ORDER BY order_id
)

SELECT * FROM sec_pop_prod
WHERE product_id = second_product;

-- Alternative using DENSE RANK

-- Add a column that contains the rankings
SELECT
	order_id,
	product_id,
	units,
	DENSE_RANK() OVER(PARTITION BY order_id ORDER BY units DESC) AS rank_num
FROM orders
ORDER BY order_id;

-- Return the 2nd most popular product for each order
WITH sec_pop_prod AS (
	SELECT
		order_id,
		product_id,
		units,
		DENSE_RANK() OVER(PARTITION BY order_id ORDER BY units DESC) AS rank_num
	FROM orders
	ORDER BY order_id
)

SELECT * FROM sec_pop_prod
WHERE rank_num = 2;


-- ASSIGNMENT 4: Lead & Lag

-- View the columns of interest
SELECT
	customer_id,
    order_id,
    units
FROM orders
ORDER BY customer_id, order_id;

-- For each customer, return the total units within each order
SELECT
	customer_id,
    order_id,
    order_date,
    SUM(units) AS total_units
FROM orders
GROUP BY customer_id, order_id, order_date
ORDER BY customer_id, order_date;

-- Turn the query into a CTE and view the columns of interest
WITH grouped_orders AS (
	SELECT
		customer_id,
		order_id,
		order_date,
		SUM(units) AS total_units
	FROM orders
	GROUP BY customer_id, order_id, order_date
	ORDER BY customer_id, order_date
)

SELECT * FROM grouped_orders;

-- Create a prior units column
-- For each customer, find the change in units per order over time
WITH grouped_orders AS (
	SELECT
		customer_id,
		order_id,
		order_date,
		SUM(units) AS total_units
	FROM orders
	GROUP BY customer_id, order_id, order_date
	ORDER BY customer_id, order_date
),
orders_prior_units AS (
	SELECT
		customer_id,
		order_id,
		total_units,
		LAG(total_units) OVER(PARTITION BY customer_id) AS prior_units
	FROM grouped_orders
)

SELECT
	customer_id,
    order_id,
    total_units,
    prior_units,
    total_units - prior_units AS units_diff
FROM orders_prior_units;


-- ASSIGNMENT 5: NTILE

-- Calculate the total amount spent by each customer

-- View the data needed from the orders table
SELECT * FROM orders;

-- View the data needed from the products table
SELECT * FROM products;

-- Combine the two tables and view the columns of interest
SELECT
	o.customer_id,
    SUM(o.units * p.unit_price) AS total_spent
FROM orders o
INNER JOIN products p
	ON o.product_id = p.product_id
GROUP BY o.customer_id;
        
-- Calculate the total spending by each customer and sort the results from highest to lowest
SELECT
	o.customer_id,
    SUM(o.units * p.unit_price) AS total_spent
FROM orders o
INNER JOIN products p
	ON o.product_id = p.product_id
GROUP BY o.customer_id
ORDER BY total_spent DESC;

-- Turn the query into a CTE and apply the percentile calculation
-- Return the top 1% of customers in terms of spending
WITH total_amount_spent AS (
	SELECT
		o.customer_id,
		SUM(o.units * p.unit_price) AS total_spent
	FROM orders o
    INNER JOIN products p
		ON o.product_id = p.product_id
	GROUP BY o.customer_id
	ORDER BY total_spent DESC
),
ts_percentiles AS (
	SELECT
		customer_id,
		total_spent,
		NTILE(100) OVER(ORDER BY total_spent DESC) AS ts_percentile
	FROM total_amount_spent
)

SELECT * FROM ts_percentiles
WHERE ts_percentile = 1;


