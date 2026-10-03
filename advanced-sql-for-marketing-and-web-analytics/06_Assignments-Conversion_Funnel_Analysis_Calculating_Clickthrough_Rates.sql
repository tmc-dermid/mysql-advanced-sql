USE `mavenfuzzyfactory`;

-- Assignment 6.1: Conversion Funnel Analysis and Calculating Click-through Rates

-- Context:
-- We want to understand where we lose our gsearch visitors between the new /lander 1 page and placing an order.
-- We want to build a full Conversion Funnel, analyzing how many customers make it to each step.
-- Use data from August 5th to September 5th.

-- STEP 1: Flagging each pageview as a specific funnel step (e.g. /products, /cart, etc.)
-- STEP 2: Identifying the funnel steps reached by each session
-- STEP 3: Aggregating the data and summarizing funnel performance
-- STEP 4: Calculating click-through rates between funnel steps

-- 1: Flagging each pageview as a specific funnel step and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE pageviews_flags
SELECT
	ws.website_session_id,
    wp.pageview_url,
    wp.created_at AS pageview_created_at,
    CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
	CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions ws
LEFT JOIN website_pageviews wp
	ON ws.website_session_id = wp.website_session_id
WHERE ws.created_at > '2012-08-05' -- prescribed in the assignment
	AND ws.created_at < '2012-09-05' -- date of assignment
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
ORDER BY
	ws.website_session_id,
    wp.created_at;

-- 2: Identifying the funnel steps reached by each session and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE session_level_reached_flags
SELECT
	website_session_id,
    MAX(products_page) AS products_reached,
    MAX(mrfuzzy_page) AS mrfuzzy_reached,
    MAX(cart_page) AS cart_reached,
    MAX(shipping_page) AS shipping_reached,
    MAX(billing_page) AS billing_reached,
    MAX(thankyou_page) AS thankyou_reached
FROM pageviews_flags
GROUP BY website_session_id;

-- 3: Aggregating the data and summarizing funnel performance and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE funnel_performance
SELECT
	COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN products_reached = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_reached = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_reached = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_reached = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_reached = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_reached = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_reached_flags;

-- 4: Calculating click-through rates between funnel steps
SELECT
	total_sessions,
    ROUND(to_products / total_sessions * 100, 2) AS clicked_to_products, -- or: lander_clickthrough_rate
    ROUND(to_mrfuzzy / to_products * 100, 2) AS clicked_to_mrfuzzy, -- or: products_clickthrough_rate
    ROUND(to_cart / to_mrfuzzy * 100, 2) AS clicked_to_cart, -- or: mrfuzzy_clickthrough_rate
    ROUND(to_shipping / to_cart * 100, 2) AS clicked_to_shipping, -- or: cart_clickthrough_rate
    ROUND(to_billing / to_shipping * 100, 2) AS clicked_to_billing, -- or: shipping_clickthrough_rate
    ROUND(to_thankyou / to_billing * 100, 2) AS clicked_to_thankyou -- or: billing_clickthrough_rate
FROM funnel_performance;

-- Results:
-- clicked_to_products: 47.07%
-- clicked_to_mrfuzzy: 74.09%
-- clicked_to_cart: 43.59%
-- clicked_to_shipping: 66.62%
-- clicked_to_billing: 79.34%
-- clicked_to_thankyou: 43.77%

-- Conclusion:
-- We have to focus on the Lander page, MrFuzzy page and the Billing page.


-- Assignment 6.2: Conversion Funnel Analysis and Calculating Click-through Rates

-- Context:
-- We want to test an updated billing page
-- We want to compare the new /billing-2 page with the old /billing page
-- We are wondering what % of sessions on those pages end up placing an order

-- Step 0: Finding the first instance of /billing-2 to set analysis timeframe
SELECT
	MIN(created_at) AS first_created_at,
    MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/billing-2';

-- Results:

-- first_created_at: '2012-09-10 00:13:05'
-- first_pageview_id: 53550

-- Step 1.1 - in CTE: Selecting sessions for both billing page versions and their orders
-- Step 1.2 - in the main query: Aggregating the data and calculating the Conversion Rate
WITH billing_page_sessions_orders AS (
	SELECT
		wp.website_session_id,
		wp.pageview_url AS billing_page_version,
		o.order_id
	FROM website_pageviews wp
	LEFT JOIN orders o
		ON wp.website_session_id = o.website_session_id
	WHERE wp.website_pageview_id >= 53550
		AND wp.created_at < '2012-11-10' -- date of assignment
		AND wp.pageview_url IN ('/billing', '/billing-2')
)

SELECT
	billing_page_version,
	COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) * 100, 2) AS billing_to_order_rate
FROM billing_page_sessions_orders
GROUP BY billing_page_version;

-- Results:
-- billing_to_order_rate for /billing: 45.66%
-- billing_to_order_rate for /billing-2: 62.69%

-- Conclusion:
-- The new billing page version was a great success.
