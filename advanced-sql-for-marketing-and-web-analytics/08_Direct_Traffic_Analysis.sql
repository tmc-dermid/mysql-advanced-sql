USE `mavenfuzzyfactory`;

-- Assignment 8: Direct Traffic Analysis

-- Context:
-- Pull organic search, direct type in, and paid brand search sessions by month.
-- Show those sessions as a % of paid search nonbrand.

WITH channel_groups_cte AS (
	SELECT
		website_session_id,
		created_at,
		CASE
			WHEN http_referer IS NULL AND utm_source IS NULL THEN 'direct_type_in'
			WHEN http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') AND utm_source IS NULL THEN 'organic_search'
			WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
			WHEN utm_campaign = 'brand' THEN 'paid_brand'
		END AS channel_group
	FROM website_sessions
	WHERE created_at < '2012-12-23' -- date of assignment
)

SELECT
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END) AS nonbrand_sess,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id END) AS brand_sess,
    ROUND(COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id END) /
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END) * 100, 2) AS brand_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id END) AS direct_sess,
	ROUND(COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id END) /
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END) * 100, 2) AS direct_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id END) AS organic_sess,
    ROUND(COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id END) /
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id END) * 100, 2) AS organic_pct_of_nonbrand
FROM channel_groups_cte
GROUP BY yr, mo;