-- Connect to database
USE maven_advanced_sql;

-- ASSIGNMENT 1: Basic Joins
-- Which products exist in one table, but not the other?

-- View the orders and products tables
SELECT * FROM orders;
SELECT * FROM products;

SELECT
	COUNT(DISTINCT product_id) AS count
FROM orders;

SELECT
	COUNT(DISTINCT product_id) AS count
FROM products;

-- Join the tables using various join types & note the number of rows in the output
SELECT COUNT(*)
FROM orders o
LEFT JOIN products p
	ON o.product_id = p.product_id; -- 8549 rows
    
SELECT COUNT(*)
FROM orders o
RIGHT JOIN products p
	ON o.product_id = p.product_id; -- 8552 rows
        
-- View the products that exist in one table, but not the other
SELECT *
FROM orders o
LEFT JOIN products p
	ON o.product_id = p.product_id
WHERE p.product_id IS NULL; -- 0

SELECT *
FROM products p
LEFT JOIN orders o
	ON p.product_id = o.product_id
WHERE o.product_id IS NULL; -- 3

-- Pick a final JOIN type to join products and orders
SELECT
	p.product_id,
    p.product_name,
    o.product_id AS product_id_in_orders
FROM products p
LEFT JOIN orders o
	ON p.product_id = o.product_id
WHERE o.product_id IS NULL;


-- ASSIGNMENT 2: Self Joins
-- Which products are within 25 cents of each other in terms of unit price?

-- View the products table
SELECT * FROM products;

-- Join the products table with itself so each candy is paired with a different candy
SELECT
	p1.product_name,
    p1.unit_price,
    p2.product_name,
    p2.unit_price
FROM products p1
INNER JOIN products p2
	ON p1.product_id <> p2.product_id;
        
-- Calculate the price difference, do a self join, and then return only price differences under 25 cents
SELECT
	p1.product_name,
    p1.unit_price,
    p2.product_name,
    p2.unit_price,
    p1.unit_price - p2.unit_price AS price_diff
FROM products p1
INNER JOIN products p2
	ON p1.product_id <> p2.product_id
WHERE ABS(p1.unit_price - p2.unit_price) < 0.25
	AND p1.product_name < p2.product_name
ORDER BY price_diff DESC;


-- =-= JOIN on multiple columns =-=
SELECT * FROM happiness_scores;

SELECT * FROM inflation_rates;

SELECT
	hs.year,
    hs.country,
    hs.happiness_score,
    ir.inflation_rate
FROM happiness_scores hs
INNER JOIN inflation_rates ir
	ON hs.year = ir.year
    AND hs.country = ir.country_name;
    
-- =-= JOIN on multiple tables =-=
SELECT * FROM happiness_scores;
SELECT * FROM country_stats;
SELECT * FROM inflation_rates;

SELECT
	hs.year,
    hs.country,
    hs.happiness_score,
    cs.continent,
    ir.inflation_rate
FROM happiness_scores hs
LEFT JOIN country_stats cs
	ON hs.country = cs.country
LEFT JOIN inflation_rates ir
	ON hs.country = ir.country_name
    AND hs.year = ir.year;
    
-- =-= SELF JOIN =-=
CREATE TABLE IF NOT EXISTS employees (
	employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100),
    salary INT,
    manager_id INT
);

INSERT INTO employees (employee_id, employee_name, salary, manager_id)
VALUES
	(1, 'Ava', 85000, NULL),
    (2, 'Bob', 72000, 1),
    (3, 'Cat', 59000, 1),
    (4, 'Dan', 85000, 2);
    
SELECT * FROM employees;

-- Employees with the same salary
SELECT
	e1.employee_name,
    e1.salary,
	e2.employee_name,
    e2.salary
FROM employees e1
INNER JOIN employees e2
  ON e1.salary = e2.salary
WHERE e1.employee_id > e2.employee_id; -- so we have no duplicates

-- Employees that have a greater salary
SELECT
	e1.employee_name,
    e1.salary,
	e2.employee_name,
    e2.salary
FROM employees e1
INNER JOIN employees e2
  ON e1.salary > e2.salary
ORDER BY e1.employee_name;

-- Employees and their managers
SELECT
	e1.employee_id,
	e1.employee_name,
    e1.manager_id,
	e2.employee_name AS manager_name
FROM employees e1
LEFT JOIN employees e2
  ON e1.manager_id = e2.employee_id;
  
-- =-= CROSS JOIN + UNION / UNION ALL =-=
CREATE TABLE tops (
    id INT,
    item VARCHAR(50)
);

CREATE TABLE sizes (
    id INT,
    size VARCHAR(50)
);

CREATE TABLE outerwear (
    id INT,
    item VARCHAR(50)
);

INSERT INTO tops (id, item)
VALUES
	(1, 'T-Shirt'),
	(2, 'Hoodie');

INSERT INTO sizes (id, size)
VALUES
	(101, 'Small'),
	(102, 'Medium'),
	(103, 'Large');

INSERT INTO outerwear (id, item)
VALUES
	(2, 'Hoodie'),
	(3, 'Jacket'),
	(4, 'Coat');

SELECT * FROM tops;
SELECT * FROM sizes;
SELECT * FROM outerwear;

SELECT *
FROM tops
CROSS JOIN sizes;

SELECT * FROM happiness_scores; -- data for years 2015 - 2023
SELECT * FROM happiness_scores_current; -- data for year 2024

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


