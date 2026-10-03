USE `mavenfuzzyfactory`;

-- Assignment 2.1: Traffic Source Bid Optimization - Conversion Rates (session-to-order) by Device Type

-- Context:
-- Pull conversion rates from session to order, by device type.

SELECT
	ws.device_type,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) * 100, 2) AS session_to_order_conversion_rate
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-05-11' -- date of assignment
	AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand'
GROUP BY ws.device_type;


-- Assignment 2.2: Traffic Source Bid Optimization - Weekly Trends for both Desktop and Mobile

-- Context:
-- Pull weekly trends for both desktop and mobile.

SELECT
	-- YEAR(created_at) AS yr,
    -- WEEK(created_at) AS mo,
	MIN(DATE(created_at)) AS week_start_date, -- Get the first date of each week
	COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
FROM website_sessions
WHERE created_at > '2012-04-15' -- prescribed in the assignment
	AND created_at < '2012-06-09' -- date of assignment
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY
	YEAR(created_at),
	WEEK(created_at); -- Group data by year and week. We could also use: YEARWEEK(created_at)