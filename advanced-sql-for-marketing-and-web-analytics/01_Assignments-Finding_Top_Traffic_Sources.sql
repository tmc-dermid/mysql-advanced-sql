USE `mavenfuzzyfactory`;

-- Assignment 1.1: Finding Top Traffic Sources

-- Context:
-- Where the bulk of our website sessions are coming from, through yesterday?
-- Show a breakdown by UTM source , campaign and referring domain.

SELECT
	ws.utm_source,
    ws.utm_campaign,
    ws.http_referer,
    COUNT(DISTINCT ws.website_session_id) AS sessions
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-04-12' -- date of assignment
GROUP BY 1, 2, 3
ORDER BY sessions DESC;

-- Conclusion: gsearch nonbrand is the major traffic source


-- Assignment 1.2: Traffic Conversion Rates (for the Top Traffic Source)

-- Context:
-- Calculate the conversion rate (CVR) from session to order for gsearch nonbrand.

SELECT
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) * 100, 2) AS session_to_order_conversion_rate
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-04-14' -- date of assignment
	AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand';


-- Assignment 1.3: Traffic Source Trending (by Week)

-- Context:
-- We bid down gsearch nonbrand on 2012-04-15. Pull gsearch nonbrand trended session volume, by week.

SELECT
	-- YEAR(created_at) AS yr,
    -- WEEK(created_at) AS mo,
    MIN(DATE(created_at)) AS week_start_date, -- Get the first date of each week
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-05-10' -- date of assignment
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY
	YEAR(created_at),
	WEEK(created_at); -- Group data by year and week. We could also use: YEARWEEK(created_at)