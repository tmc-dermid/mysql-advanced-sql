USE `mavenfuzzyfactory`;

-- Assignment 9.1: Analyzing Seasonality & Business Patterns

-- Context:
-- We should take a look at 2012’s monthly and weekly volume patterns, to see if we can find any seasonal trends we should plan for in 2013.
-- Pull session volume and order volume.

-- Monthly:
SELECT
	YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT ws.website_session_id) AS total_sessions,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) = 2012
GROUP BY yr, mo;

-- Weekly:
SELECT
	YEAR(ws.created_at) AS yr,
	WEEK(ws.created_at) AS wk,
	MIN(DATE(ws.created_at)) AS start_of_week,
    COUNT(DISTINCT ws.website_session_id) AS total_sessions,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE YEAR(ws.created_at) = 2012
GROUP BY yr, wk;


-- Assignment 9.2: Analyzing Seasonality & Business Patterns

-- Context:
-- Analyze the average website session volume, by hour of day and by day week.
-- Let’s avoid the holiday time period and use a date range of Sep 15 Nov 15, 2013.

WITH daily_hourly_sessions AS (
	SELECT
		DATE(created_at) AS created_date,
		WEEKDAY(created_at) AS created_weekday,
		HOUR(created_at) AS created_hour,
		COUNT(DISTINCT website_session_id) AS total_sessions
	FROM website_sessions
	WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15' -- prescribed in the assignment
	GROUP BY 1, 2, 3
)

SELECT
	created_hour AS hr,
    ROUND(AVG(total_sessions), 1) AS avg_sessions,
    ROUND(AVG(CASE WHEN created_weekday = 0 THEN total_sessions ELSE NULL END), 1) AS mon,
    ROUND(AVG(CASE WHEN created_weekday = 1 THEN total_sessions ELSE NULL END), 1) AS tue,
    ROUND(AVG(CASE WHEN created_weekday = 2 THEN total_sessions ELSE NULL END), 1) AS wed,
    ROUND(AVG(CASE WHEN created_weekday = 3 THEN total_sessions ELSE NULL END), 1) AS thu,
    ROUND(AVG(CASE WHEN created_weekday = 4 THEN total_sessions ELSE NULL END), 1) AS fri,
    ROUND(AVG(CASE WHEN created_weekday = 5 THEN total_sessions ELSE NULL END), 1) AS sat,
    ROUND(AVG(CASE WHEN created_weekday = 6 THEN total_sessions ELSE NULL END), 1) AS sun
FROM daily_hourly_sessions
GROUP BY hr;
