-- Connect to database
USE maven_advanced_sql;

-- ASSIGNMENT 1: Subqueries in the SELECT clause

-- View the products table
SELECT * FROM products;

-- View the average unit price
SELECT AVG(unit_price) FROM products;

-- Return the product id, product name, unit price, average unit price,
-- and the difference between each unit price and the average unit price
-- Order the results from most to least expensive
SELECT
	product_id,
    product_name,
    unit_price,
    (SELECT AVG(unit_price) FROM products) AS avg_unit_price,
    unit_price - (SELECT AVG(unit_price) FROM products) AS diff_from_avg
FROM products
ORDER BY unit_price DESC;


-- ASSIGNMENT 2: Subqueries in the FROM clause

-- Return the factories, product names from the factory
-- and number of products produced by each factory


-- All factories and products
SELECT * FROM products;

-- All factories and their total number of products
SELECT
	factory,
    COUNT(product_id) AS count
FROM products
GROUP BY factory;

-- Final query with subqueries
SELECT
	p.factory,
    p.product_name,
    pn.products_no
FROM products p
LEFT JOIN (
	SELECT
		factory,
		COUNT(product_id) AS products_no
	FROM products
	GROUP BY factory
) AS pn
ON p.factory = pn.factory
ORDER BY p.factory, p.product_name;


-- ASSIGNMENT 3: Subqueries in the WHERE clause

-- View all products from Wicked Choccy's
SELECT * FROM products
WHERE factory = 'Wicked Choccy''s';

-- Return products where the unit price is less than
-- the unit price of all products from Wicked Choccy's
SELECT *
FROM products
WHERE unit_price < ALL (
	SELECT unit_price
    FROM products
	WHERE factory = 'Wicked Choccy''s'
);


-- ASSIGNMENT 4: CTEs

-- View the orders and products tables
SELECT * FROM orders;
SELECT * FROM products;

-- Calculate the amount spent on each product, within each order
-- Return all orders over $200
-- Return the number of orders over $200
WITH orders_sums AS (
	SELECT
		o.order_id,
		SUM(o.units * p.unit_price) AS total_amount_spent
	FROM orders o
	LEFT JOIN products p
		ON o.product_id = p.product_id
	GROUP BY o.order_id
    HAVING total_amount_spent > 200
)

SELECT
	COUNT(*) AS total_orders_over_200
FROM orders_sums;


-- ASSIGNMENT 5: Multiple CTEs

-- Copy over Assignment 2 (Subqueries in the FROM clause) solution
SELECT
	p.factory,
    p.product_name,
    pn.products_no
FROM products p
LEFT JOIN (
	SELECT
		factory,
		COUNT(product_id) AS products_no
	FROM products
	GROUP BY factory
) AS pn
ON p.factory = pn.factory
ORDER BY p.factory, p.product_name;

-- Rewrite the Assignment 2 subquery solution using CTEs instead
WITH products_number AS (
	SELECT
		factory,
		COUNT(product_id) AS products_no
	FROM products
	GROUP BY factory
)

SELECT
	p.factory,
    p.product_name,
    pn.products_no
FROM products p
LEFT JOIN products_number pn
	ON p.factory = pn.factory
ORDER BY p.factory, p.product_name;


-- OTHER:
-- 1. Subqueries in the SELECT clause
SELECT * FROM happiness_scores;

-- Average happiness score
SELECT AVG(happiness_score) FROM happiness_scores;

-- Happiness score deviation from the average
-- Return: year, country, happiness_score, average happiness score and the difference.
SELECT
	year,
	country,
    happiness_score,
    (SELECT AVG(happiness_score) FROM happiness_scores) AS avg_happiness_score,
    happiness_score - (
			SELECT AVG(happiness_score)
            FROM happiness_scores
        ) AS diff_from_avg
FROM happiness_scores;


-- 2. Subqueries in the FROM clause
SELECT * FROM happiness_scores;

-- Average happiness score for each country
SELECT
	country,
    AVG(happiness_score) AS avg_hs_by_country
FROM happiness_scores
GROUP BY country;

/* Return a country's happiness score for the year as well as
the average happiness score for the country across years */
SELECT
	hs.year,
    hs.country,
    hs.happiness_score,
    country_hs.avg_hs_by_country
FROM happiness_scores hs
LEFT JOIN (
	SELECT
		country,
		AVG(happiness_score) AS avg_hs_by_country
	FROM happiness_scores
    GROUP BY country
) AS country_hs
ON hs.country = country_hs.country;

-- View one country
SELECT
	hs.year,
    hs.country,
    hs.happiness_score,
    country_hs.avg_hs_by_country
FROM happiness_scores hs
LEFT JOIN (
	SELECT
		country,
		AVG(happiness_score) AS avg_hs_by_country
	FROM happiness_scores
    GROUP BY country
) AS country_hs
ON hs.country = country_hs.country
WHERE hs.country = 'Poland';


-- 3. Multiple subqueries

-- Return happiness scores for 2015 - 2024
SELECT * FROM happiness_scores; -- 2015 - 2023
SELECT * FROM happiness_scores_current; -- 2024

SELECT
	year,
    country,
    happiness_score
FROM happiness_scores
UNION ALL
SELECT
	2024 AS year,
    country,
    ladder_score
FROM happiness_scores_current;
            
/* Return a country's happiness score for the year as well as
the average happiness score for the country across years */
SELECT
	hs.year,
    hs.country,
    hs.happiness_score,
    country_hs.avg_hs_by_country
FROM (
	SELECT year, country, happiness_score
	FROM happiness_scores
	UNION ALL
	SELECT 2024, country, ladder_score
	FROM happiness_scores_current
) AS hs
LEFT JOIN (
	SELECT country, AVG(happiness_score) AS avg_hs_by_country
	FROM happiness_scores
	GROUP BY country
) AS country_hs
ON hs.country = country_hs.country;

/* Return years where the happiness score is a whole point
greater than the country's average happiness score */
SELECT
	hs.year,
    hs.country,
    hs.happiness_score,
    country_hs.avg_hs_by_country
FROM (
	SELECT year, country, happiness_score
	FROM happiness_scores
	UNION ALL
	SELECT 2024, country, ladder_score
	FROM happiness_scores_current
) AS hs
LEFT JOIN (
	SELECT country, AVG(happiness_score) AS avg_hs_by_country
	FROM happiness_scores
	GROUP BY country
) AS country_hs
ON hs.country = country_hs.country
WHERE hs.happiness_score > country_hs.avg_hs_by_country + 1;


-- 4. Subqueries in the WHERE and HAVING clauses

-- Average happiness score
SELECT AVG(happiness_score) FROM happiness_scores;

-- Above average happiness scores (WHERE)
SELECT *
FROM happiness_scores
WHERE happiness_score > (
	SELECT AVG(happiness_score)
    FROM happiness_scores
);

-- Above average happiness scores for each region (HAVING)
SELECT
	region,
    AVG(happiness_score) AS avg_hs
FROM happiness_scores
GROUP BY region
HAVING avg_hs > (
	SELECT AVG(happiness_score)
    FROM happiness_scores
);
      

-- 5. ANY vs ALL
SELECT * FROM happiness_scores; -- 2015 - 2023
SELECT * FROM happiness_scores_current; -- 2024

-- Scores that are greater than ANY 2024 scores
SELECT *
FROM happiness_scores
WHERE happiness_score > ANY (
	SELECT ladder_score
    FROM happiness_scores_current
);

-- Scores that are greater than ALL 2024 scores
SELECT *
FROM happiness_scores
WHERE happiness_score > ALL (
	SELECT ladder_score
    FROM happiness_scores_current
);

-- 6. EXISTS
SELECT * FROM happiness_scores;
SELECT * FROM inflation_rates;

/* Return happiness scores of countries
that exist in the inflation rates table */
SELECT *
FROM happiness_scores hs
WHERE EXISTS (
	SELECT ir.country_name
    FROM inflation_rates ir
    WHERE ir.country_name = hs.country
);

-- Alternative to EXISTS: INNER JOIN
SELECT *
FROM happiness_scores hs
INNER JOIN inflation_rates ir
	ON hs.country = ir.country_name
    AND hs.year = ir.year;
    

-- 7. CTEs: Readability

/* SUBQUERY: Return the happiness scores along with
   the average happiness score for each country */
SELECT
	hs.year,
    hs.country,
    hs.happiness_score,
    country_hs.avg_hs_by_country
FROM happiness_scores hs
LEFT JOIN (
	SELECT
		country,
		AVG(happiness_score) AS avg_hs_by_country
	FROM happiness_scores
    GROUP BY country
) AS country_hs
ON hs.country = country_hs.country;

/* CTE: Return the happiness scores along with
   the average happiness score for each country */
WITH country_avg_hs AS (
	SELECT
		country,
		AVG(happiness_score) AS avg_hs_by_country
	FROM happiness_scores
    GROUP BY country
)

SELECT
	hs.year,
    hs.country,
    hs.happiness_score,
    cahs.avg_hs_by_country
FROM happiness_scores hs
LEFT JOIN country_avg_hs cahs
	ON hs.country = cahs.country;

-- 8. CTEs: Reusability
        
-- SUBQUERY: Compare the happiness scores within each region in 2023
SELECT
	hs1.region,
    hs1.country,
    hs1.happiness_score,
    hs2.country,
    hs2.happiness_score
FROM (
	SELECT *
	FROM happiness_scores
	WHERE year = 2023
) AS hs1
INNER JOIN (
	SELECT *
	FROM happiness_scores
	WHERE year = 2023
) AS hs2
	ON hs1.region = hs2.region
WHERE hs1.country < hs2.country;

-- CTE: Compare the happiness scores within each region in 2023
WITH hs_2023 AS (
	SELECT *
	FROM happiness_scores
	WHERE year = 2023
)

SELECT
	hs1.region,
    hs1.country,
    hs1.happiness_score,
    hs2.country,
    hs2.happiness_score
FROM hs_2023 hs1
INNER JOIN hs_2023 hs2
	ON hs1.region = hs2.region
WHERE hs1.country < hs2.country;


-- 9. Multiple CTEs

-- Step 1: Compare 2023 vs 2024 happiness scores side by side
SELECT * FROM happiness_scores;
SELECT * FROM happiness_scores_current;

WITH hs23 AS (
	SELECT
		country,
		happiness_score
	FROM happiness_scores
	WHERE year = 2023
),
hs24 AS (
	SELECT
		country,
		ladder_score
	FROM happiness_scores_current
)

SELECT
	hs23.country,
    hs23.happiness_score AS hs_2023,
    hs24.country,
    hs24.ladder_score AS hs_2024
FROM hs23
LEFT JOIN hs24
	ON hs23.country = hs24.country;

-- Step 2: Return the countries where the score increased
WITH hs23 AS (
	SELECT
		country,
		happiness_score
	FROM happiness_scores
	WHERE year = 2023
),
hs24 AS (
	SELECT
		country,
		ladder_score
	FROM happiness_scores_current
)

SELECT
	hs23.country,
    hs23.happiness_score AS hs_2023,
    hs24.country,
    hs24.ladder_score AS hs_2024
FROM hs23
LEFT JOIN hs24
	ON hs23.country = hs24.country
WHERE hs24.ladder_score > hs23.happiness_score;


-- 10. Recursive CTEs

-- Create a stock prices table
/* CREATE TABLE IF NOT EXISTS stock_prices (
    date DATE PRIMARY KEY,
    price DECIMAL(10, 2)
);
*/

/* INSERT INTO stock_prices (date, price) VALUES
	('2024-11-01', 678.27),
	('2024-11-03', 688.83),
	('2024-11-04', 645.40),
	('2024-11-06', 591.01);
*/

-- Example 1: Generating sequences
SELECT * FROM stock_prices;

-- Generate a column of dates
-- Join with the stock_prices table to fill missing dates
WITH RECURSIVE my_dates(dt) AS (
	SELECT '2024-11-01'
    UNION ALL
    SELECT dt + INTERVAL 1 DAY
    FROM my_dates
    WHERE dt < '2024-11-06'
)
     
SELECT
	md.dt,
    sp.price
FROM my_dates md
LEFT JOIN stock_prices sp
	ON md.dt = sp.date;
    
-- Example 2: Working with hierachical data
SELECT * FROM employees;

-- Return the reporting chain for each employee
WITH RECURSIVE emp_chain AS (
	SELECT
		employee_id,
		employee_name,
		manager_id,
		employee_name AS hierarchy
	FROM employees
	WHERE manager_id IS NULL
    
	UNION ALL
    
	SELECT
		emp.employee_id,
        emp.employee_name,
        emp.manager_id,
        CONCAT(emp_chain.hierarchy, ' > ', emp.employee_name) AS hierarchy
	FROM employees emp, emp_chain
    WHERE emp.manager_id = emp_chain.employee_id
)

SELECT *
FROM emp_chain;


-- 11. Subquery vs CTE vs Temp Table vs View

-- Subquery
SELECT *
FROM (
	SELECT
		year,
		country,
		happiness_score
	FROM happiness_scores
	UNION ALL
	SELECT
		2024 AS year,
		country,
		ladder_score
	FROM happiness_scores_current
) AS my_subq;

-- CTE
WITH my_cte AS (
	SELECT
		year,
		country,
		happiness_score
	FROM happiness_scores
	UNION ALL
	SELECT
		2024 AS year,
		country,
		ladder_score
	FROM happiness_scores_current
)

SELECT *
FROM my_cte;

-- Temporary table
CREATE TEMPORARY TABLE my_temp_table AS
SELECT
	year,
	country,
	happiness_score
FROM happiness_scores
UNION ALL
SELECT
	2024 AS year,
	country,
	ladder_score
FROM happiness_scores_current;

SELECT *
FROM my_temp_table;

-- View
CREATE VIEW my_view AS
SELECT
	year,
	country,
	happiness_score
FROM happiness_scores
UNION ALL
SELECT
	2024 AS year,
	country,
	ladder_score
FROM happiness_scores_current;

SELECT *
FROM my_view;
