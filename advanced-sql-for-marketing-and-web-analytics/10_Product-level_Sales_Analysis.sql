USE `mavenfuzzyfactory`;

-- Assignment 10.1: Product-level Sales Analysis

-- Context:
-- Pull monthly trends to date for number of sales, total revenue, and total margin generated for the business.

SELECT
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(order_id) AS number_of_sales,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-04' -- date of assignment
GROUP BY yr, mo;


-- Assignment 10.2: Product-level Sales Analysis

-- Context
-- We launched our second product back on January 6th.
-- Pull monthly order volume, overall conversion rates, revenue per session, and a breakdown of sales by product.
-- Use the time period since April 1st, 2013.

SELECT
	YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) * 100, 2) AS conversion_rate,
    SUM(o.price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session,
    COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN order_id ELSE NULL END) AS product_one_orders,
    COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN order_id ELSE NULL END) AS product_two_orders
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at > '2012-04-01' -- prescribed in the assignment
	AND ws.created_at < '2013-04-05' -- date of assignment
GROUP BY yr, mo;
