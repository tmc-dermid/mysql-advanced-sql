USE `mavenfuzzyfactory`;

-- Assignment 12: Product Conversion Funnels

-- Context:
-- Look at our two products since January 6th and analyze the conversion funnels from each product page to conversion.
-- Produce a comparison between the two conversion funnels, for all website traffic.

-- Step 1: Select all pageviews for relevant sessions
-- Step 2: Find the right pageview_urls to build the funnels
-- Step 3: Pull all pageviews and identify the funnel steps
-- Step 4: Create the session-level conversion funnel view
-- Step 5: Aggregate the data to assess funnel performance

-- 1: Selecting all pageviews for relevant sessions and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE sessions_seeing_product_pages
SELECT
	website_session_id,
    website_pageview_id,
    pageview_url AS product_page_seen
FROM website_pageviews
WHERE created_at < '2013-04-10' -- date of assignment
	AND created_at > '2013-01-06' -- date of the launch of product 2
    AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear');
    
-- 2, 3, 4:
SELECT DISTINCT
	wp.pageview_url
FROM sessions_seeing_product_pages sspp
LEFT JOIN website_pageviews wp
	ON sspp.website_session_id = wp.website_session_id
    AND wp.website_pageview_id > sspp.website_pageview_id;

CREATE TEMPORARY TABLE sessions_pageviews_flags
SELECT
	sspp.website_session_id,
    sspp.product_page_seen,
    CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN wp.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages sspp
LEFT JOIN website_pageviews wp
	ON sspp.website_session_id = wp.website_session_id
    AND wp.website_pageview_id > sspp.website_pageview_id
ORDER BY
	sspp.website_session_id,
    wp.created_at;
    
CREATE TEMPORARY TABLE session_product_level_reached_flags
SELECT
	website_session_id,
    CASE
		WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
		WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
		ELSE 'error'
	END AS product_seen,
    MAX(cart_page) AS cart_reached,
    MAX(shipping_page) AS shipping_reached,
    MAX(billing_page) AS billing_reached,
    MAX(thankyou_page) AS thankyou_reached
FROM sessions_pageviews_flags
GROUP BY
	website_session_id,
    product_seen;
    
-- 5: Summarizing and aggregating data
SELECT
	product_seen,
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN cart_reached = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_reached = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_reached = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_reached = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_reached_flags
GROUP BY product_seen;

-- Calculating click rates
SELECT
	product_seen,
    ROUND(COUNT(DISTINCT CASE WHEN cart_reached = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS product_page_click_rate,
    ROUND(COUNT(DISTINCT CASE WHEN shipping_reached = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN cart_reached = 1 THEN website_session_id ELSE NULL END) * 100, 2) AS cart_click_rate,
    ROUND(COUNT(DISTINCT CASE WHEN billing_reached = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN shipping_reached = 1 THEN website_session_id ELSE NULL END) * 100, 2) AS shipping_click_rate,
    ROUND(COUNT(DISTINCT CASE WHEN thankyou_reached = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN billing_reached = 1 THEN website_session_id ELSE NULL END) * 100, 2) AS billing_click_rate
FROM session_product_level_reached_flags
GROUP BY product_seen;