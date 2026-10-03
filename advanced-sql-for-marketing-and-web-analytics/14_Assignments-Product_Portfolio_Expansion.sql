USE `mavenfuzzyfactory`;

-- Assignment 14: Product Portfolio Expansion Analysis

-- Context:
-- On December 12th 2013, we launched a third product targeting the birthday gift market (Birthday Bear).
-- Run a pre post analysis comparing the month before vs. the month after, in terms of
-- session to order conversion rate, AOV, products per order, and revenue per session

SELECT
    CASE
		WHEN ws.created_at < '2013-12-12' THEN 'Pre_Birthday_Bear'
        WHEN ws.created_at >= '2013-12-12' THEN 'Post_Birthday_Bear'
        ELSE 'error'
    END AS time_period,
    -- COUNT(DISTINCT ws.website_session_id) AS total_sessions,
    -- COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) * 100, 2) AS session_to_order_conv_rate,
    -- SUM(o.price_usd) AS total_revenue,
    -- SUM(o.items_purchased) AS total_products_sold,
    SUM(o.price_usd) / COUNT(DISTINCT o.order_id) AS average_order_value,
    SUM(o.items_purchased) / COUNT(DISTINCT o.order_id) AS products_per_order,
    SUM(o.price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY time_period;
