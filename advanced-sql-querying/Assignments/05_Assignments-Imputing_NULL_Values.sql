-- Connect to database
USE maven_advanced_sql;

-- Imputing NULL Values

/* -- Create a stock prices table
CREATE TABLE IF NOT EXISTS stock_prices (
    date DATE PRIMARY KEY,
    price DECIMAL(10, 2)
);

INSERT INTO stock_prices (date, price) VALUES
	('2024-11-01', 678.27),
	('2024-11-03', 688.83),
	('2024-11-04', 645.40),
	('2024-11-06', 591.01); */
    
SELECT * FROM stock_prices;

-- Fill gaps between dates in the stock_prices table
WITH RECURSIVE missing_dates(dt) AS (
	SELECT MIN(date)
	FROM stock_prices

	UNION ALL
    
    SELECT dt + INTERVAL 1 DAY
    FROM missing_dates
    WHERE dt < (
		SELECT MAX(date) FROM stock_prices
	)
)

SELECT
	md.dt AS date,
	sp.price
FROM missing_dates md
LEFT JOIN stock_prices sp
	ON md.dt = sp.date;


-- Replace the NULL values in the price column in 4 different ways (aka imputation)
-- 1. With a hard coded value
-- 2. With a subquery (average of a column)
-- 3. With one window function (prior's row value)
-- 4. With two window functions (smoothed value)

WITH RECURSIVE missing_dates(dt) AS (
	SELECT MIN(date)
	FROM stock_prices

	UNION ALL
    
    SELECT dt + INTERVAL 1 DAY
    FROM missing_dates
    WHERE dt < (
		SELECT MAX(date) FROM stock_prices
	)
),
full_sp AS (
	SELECT
		md.dt AS date,
		sp.price
	FROM missing_dates md
	LEFT JOIN stock_prices sp
		ON md.dt = sp.date
)

SELECT
	date,
    price,
    COALESCE(price, 600) AS hard_coded_val_imp,
    COALESCE(price, ROUND((SELECT AVG(price) FROM full_sp), 2)) AS avg_column_imp,
    COALESCE(price, LAG(price) OVER()) AS prior_row_val_imp,
    COALESCE(price, ROUND((LAG(price) OVER() + LEAD(price) OVER()) / 2), 2) AS smoothed_val_imp
FROM full_sp;

