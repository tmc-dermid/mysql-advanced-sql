USE `mavenfuzzyfactory`;

-- Assignment 11: Product-level Website Pathing

-- Context:
-- Let’s look at sessions which hit the /products page and see where they went next.
-- Pull clickthrough rates from /products since the new product launch on January 6th 2013, by product,
-- and compare to the 3 months leading up to launch as a baseline.

-- Step 1: Find the relevant /products pageviews with website_sessions_id
-- Step 2: Find the next pageview_id that occurs after the product pageview
-- Step 3: Find the pageview_url associated with any applicable next pageview_id
-- Step 4: Summarize the data and analyze the pre vs post periods

-- 1: Finding the relevant /products pageviews with website_sessions_id and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE products_pageviews
SELECT
	website_session_id,
    website_pageview_id,
    created_at,
    CASE
		WHEN created_at < '2013-01-06' THEN 'Pre_Product_2'
        WHEN created_at >= '2013-01-06' THEN 'Post_Product_2'
        ELSE 'error'
    END AS time_period
FROM website_pageviews
WHERE created_at < '2013-04-06' -- date of assignment
	AND created_at > '2012-10-06' -- 3 months prior to product 2's launch
	AND pageview_url = '/products';
    
-- 2: Finding the next pageview_id that occurs after the product pageview and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE sessions_next_pageview_id
SELECT
	pp.time_period,
    pp.website_session_id,
    MIN(wp.website_pageview_id) AS min_next_pageview_id
FROM products_pageviews pp
LEFT JOIN website_pageviews wp
	ON pp.website_session_id = wp.website_session_id
    AND wp.website_pageview_id > pp.website_pageview_id
GROUP BY
	pp.time_period,
    pp.website_session_id;
    
-- 3: Finding the pageview_url associated with any applicable next pageview_id and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE sessions_next_pageview_url
SELECT
	snp.time_period,
    snp.website_session_id,
    wp.pageview_url AS next_pageview_url
FROM sessions_next_pageview_id snp
LEFT JOIN website_pageviews wp
	ON snp.min_next_pageview_id = wp.website_pageview_id;
    
-- 4: Summarizing the data and analyzing the pre vs post periods
SELECT
	time_period,
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS sessions_next_pg,
    ROUND(COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS pct_sessions_next_pg,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    ROUND(COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS pct_to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
    ROUND(COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS pct_to_lovebear
FROM sessions_next_pageview_url
GROUP BY time_period;

