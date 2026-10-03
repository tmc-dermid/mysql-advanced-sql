USE `mavenfuzzyfactory`;

-- Assignment 7.1: Analyzing Channel Portfolios

-- Context:
-- We launched a second paid search channel called 'bsearch' around August 22nd.
-- Pull weekly trended session volume and compare to gsearch nonbrand.

SELECT
	-- YEARWEEK(created_at) AS yw,
    MIN(DATE(created_at)) AS start_of_week,
    COUNT(website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE created_at > '2012-08-22' -- prescribed in the assignment
	AND created_at < '2012-11-29' -- date of assignment
	AND utm_campaign = 'nonbrand'
GROUP BY YEARWEEK(created_at);


-- Assignment 7.2: Comparing Channel Characteristics

-- Context:
-- For bsearch nonbrand, pull the percentage of percentage of traffic coming on Mobile and compare that to gsearch.
-- Use data since August 22nd.

SELECT
	utm_source,
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,
    ROUND(COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS percentage_mobile_sessions
FROM website_sessions
WHERE created_at > '2012-08-22' -- prescribed in the assignment
	AND created_at < '2012-11-30' -- date of assignment
	AND utm_campaign = 'nonbrand'
GROUP BY utm_source;


-- Assignment 7.3: Cross Channel Bid Optimization

-- Context:
-- Pull nonbrand conversion rates from session to order for gsearch and bsearch, and slice the data by device type.
-- Use data from August 22nd to September 18th.

SELECT
    ws.device_type,
	ws.utm_source,
    COUNT(DISTINCT ws.website_session_id) AS total_sessions,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) * 100, 2) AS session_to_order_conversion_rate
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.utm_source IN ('gsearch', 'bsearch')
	AND ws.created_at > '2012-08-22' -- prescribed in the assignment
    AND ws.created_at < '2012-09-19' -- prescribed in the assignment
    AND ws.utm_campaign = 'nonbrand'
GROUP BY
	ws.utm_source,
    ws.device_type
ORDER BY
	ws.device_type,
    ws.utm_source;
    
    
-- Assignment 7.4: Analyzing Channel Portfolio Trends

-- Context:
-- We bid down bsearch nonbrand on December 2nd
-- Pull weekly session volume for gsearch and bsearch nonbrand, broken down by device, since November 4th
-- Include a comparison metric to show bsearch as a percent of gsearch for each device

SELECT
	-- YEARWEEK(created_at),
	MIN(DATE(created_at)) AS start_of_week,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS gs_dtop_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS bs_dtop_sessions,
    ROUND(COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) * 100, 2) AS bs_pct_of_gs_dtop,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS gs_mob_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS bs_mob_sessions,
    ROUND(COUNT(DISTINCT CASE WHEN utm_source = 'Bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_source = 'Gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) * 100, 2) AS bs_pct_of_gs_mob
FROM website_sessions
WHERE utm_campaign = 'nonbrand'
	AND created_at > '2012-11-04' -- prescribed in the assignment
    AND created_at < '2012-12-22' -- date of assignment
GROUP BY
	YEARWEEK(created_at);
    