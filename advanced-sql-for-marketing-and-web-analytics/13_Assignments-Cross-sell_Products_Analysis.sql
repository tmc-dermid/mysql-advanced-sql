USE `mavenfuzzyfactory`;

-- Assignment 13: Product Conversion Funnels

-- Context:
-- On September 25th we started giving customers the option to add a second product while on the /cart page.
-- Compare the month before vs the month after the change.
-- Show CTR from the /cart page, Avg Products per Order, AOV, and overall revenue per /cart page view.

-- Step 1: Identify the relevant /cart pageviews and their sessions
-- Step 2: See which of those /cart sessions clicked through to the shipping page
-- Step 3: Find the orders associated with the /cart sessions
-- Step 4: Aggregate and summarize.

-- 1:
CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT
    CASE
		WHEN created_at < '2013-09-25' THEN 'Pre_Cross_Sell'
        WHEN created_at >= '2013-01-06' THEN 'Post_Cross_Sell'
        ELSE 'error'
    END AS time_period,
    website_session_id AS cart_session_id,
    website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
	AND pageview_url = '/cart';
    
-- 2:
CREATE TEMPORARY TABLE cart_session_seeing_another_page
SELECT
	ssc.time_period,
    ssc.cart_session_id,
    MIN(wp.website_pageview_id) AS pageview_id_after_cart
FROM sessions_seeing_cart ssc
LEFT JOIN website_pageviews wp
	ON ssc.cart_session_id = wp.website_session_id
    AND wp.website_pageview_id > ssc.cart_pageview_id
GROUP BY
	ssc.time_period,
    ssc.cart_session_id
HAVING pageview_id_after_cart IS NOT NULL;

-- 3:
CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
	ssc.time_period,
    ssc.cart_session_id,
    o.order_id,
    o.items_purchased,
    o.price_usd
FROM sessions_seeing_cart ssc
INNER JOIN orders o
	ON ssc.cart_session_id = o.website_session_id;
    
CREATE TEMPORARY TABLE sessions_another_page_orders
SELECT
	ssc.time_period,
    ssc.cart_session_id,
    CASE WHEN csap.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN ppso.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    ppso.items_purchased,
    ppso.price_usd
FROM sessions_seeing_cart ssc
LEFT JOIN cart_session_seeing_another_page csap
	ON ssc.cart_session_id = csap.cart_session_id
LEFT JOIN pre_post_sessions_orders ppso
	ON ssc.cart_session_id = ppso.cart_session_id
ORDER BY cart_session_id;

SELECT
	time_period,
    COUNT(DISTINCT cart_session_id) AS cart_sessions,
    SUM(clicked_to_another_page) AS clickthroughs,
    ROUND(SUM(clicked_to_another_page) / COUNT(DISTINCT cart_session_id) * 100, 2) AS cart_ctr, -- clickthrough rate
    SUM(placed_order) AS orders_placed,
    SUM(items_purchased) AS products_purchased,
    SUM(items_purchased) / SUM(placed_order) AS products_per_order,
    SUM(price_usd) AS revenue,
    SUM(price_usd) / SUM(placed_order) AS aov, -- average order value
    SUM(price_usd) / COUNT(DISTINCT cart_session_id) AS revenue_per_cart_session
FROM sessions_another_page_orders
GROUP BY time_period;
    