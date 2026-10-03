USE `mavenfuzzyfactory`;

-- Assignment 5.1: Analyzing Landing Page Tests and Calculating Bounce Rates

-- Context:
-- Pull bounce rates for traffic landing on the homepage.
-- Show: Sessions, Bounced Sessions, and % of Sessions which Bounced (aka "Bounce Rate").

-- Step 1: Finding the first website_pageview_id associated with each session and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE first_pageviews
SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14' -- date of assignment
GROUP BY website_session_id;

-- Step 2: Identifying the landing page for each session and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE session_landing_page
SELECT
    fp.website_session_id,
	wp.pageview_url AS landing_page
FROM first_pageviews fp
LEFT JOIN website_pageviews wp
	ON fp.min_pageview_id = wp.website_pageview_id;
    
-- Step 3: Including a count of pageviews per session and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE bounced_sessions_only
SELECT
	slp.website_session_id,
	slp.landing_page,
    COUNT(wp.website_pageview_id) AS count_of_pageviews
FROM session_landing_page slp
LEFT JOIN website_pageviews wp
	ON slp.website_session_id = wp.website_session_id
GROUP BY
	slp.website_session_id,
	slp.landing_page
HAVING count_of_pageviews = 1; -- filtering for bounced sessions only

-- Step 4: Summarizing by counting total_sessions and bounced_sessions + creating a bounce_rate metric column
SELECT
	slp.landing_page,
    COUNT(DISTINCT slp.website_session_id) AS total_sessions,
    COUNT(DISTINCT bso.website_session_id) AS bounced_sessions,
    ROUND(COUNT(DISTINCT bso.website_session_id) / COUNT(DISTINCT slp.website_session_id) * 100, 2) AS bounce_rate
FROM session_landing_page slp
LEFT JOIN bounced_sessions_only bso
	ON slp.website_session_id = bso.website_session_id
GROUP BY slp.landing_page;


-- Assignment 5.2: Analyzing Landing Page Tests and Calculating Bounce Rates
	   
-- Context:
-- Compare a new landing page (/lander-1) with the homepage in a 50/50 test for gsearch nonbrand traffic.
-- Pull bounce rates for the two groups.

-- Step 0: Finding the first instance of /lander-1 to set analysis timeframe
SELECT
    MIN(created_at) first_created_at,
    MIN(website_pageview_id) first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/lander-1';

-- Results:
-- first_created_at: '2012-06-19 00:35:54'
-- first_pageview_id: 23504

-- Step 1: Finding the first website_pageview_id associated with each session and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews wp
INNER JOIN website_sessions ws
	ON wp.website_session_id = ws.website_session_id
	AND ws.created_at < '2012-07-28' -- prescribed in the assignment
    AND wp.website_pageview_id >= 23504
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY wp.website_session_id;

-- Step 2: Identifying the landing page for each session and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE nonbrand_test_sessions_landing_page
SELECT
	ftp.website_session_id,
    wp.pageview_url AS landing_page
FROM first_test_pageviews ftp
LEFT JOIN website_pageviews wp
	ON ftp.min_pageview_id = wp.website_pageview_id
WHERE wp.pageview_url IN ('/home', '/lander-1'); -- we are doing a 50/50 test between these two landing pages

-- Step 3: Including a count of pageviews per session and creating a TEMPORARY TABLE to use in later steps
CREATE TABLE nonbrand_test_bounced_sessions
SELECT
	nts.website_session_id,
    nts.landing_page,
    COUNT(wp.website_pageview_id) AS count_of_pageviews
FROM nonbrand_test_sessions_landing_page nts
LEFT JOIN website_pageviews wp
	ON nts.website_session_id = wp.website_session_id
GROUP BY
	nts.website_session_id,
    nts.landing_page
HAVING count_of_pageviews = 1; -- filtering for bounced sessions only

-- Step 4: Summarizing by counting total_sessions and bounced_sessions + creating a bounce_rate metric column
SELECT
	nts.landing_page,
    COUNT(DISTINCT nts.website_session_id) AS total_sessions,
    COUNT(DISTINCT ntb.website_session_id) AS bounced_sessions,
    ROUND(COUNT(DISTINCT ntb.website_session_id) / COUNT(DISTINCT nts.website_session_id) * 100, 2) AS bounce_rate
FROM nonbrand_test_sessions_landing_page nts
LEFT JOIN nonbrand_test_bounced_sessions ntb
    ON nts.website_session_id = ntb.website_session_id
GROUP BY nts.landing_page;

-- Results:
-- bounce_rate for /home: 58.34%
-- bounce_rate for /lander-1: 53.24% <-- new landing page '/lander-1' has lower bounce_rate = success


-- Assignment 5.3: Landing Page Trend Analysis (by Week)

-- Context:
-- Pull the volume of paid search nonbrand traffic landing on /home and /lander 1, trended weekly since June 1st.
-- Also pull our overall paid search bounce rate trended weekly.

-- Step 1: Finding the first website_pageview_id associated with each session and a count of pageviews per session
--         then creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE sessions_first_pv_id_view_count
SELECT
	ws.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview_id,
    COUNT(wp.website_pageview_id) AS count_of_pageviews
FROM website_pageviews wp
INNER JOIN website_sessions ws
	ON wp.website_session_id = ws.website_session_id
WHERE ws.created_at > '2012-06-01' -- prescribed in the assignment
	AND ws.created_at < '2012-08-31' -- date of assignment
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY ws.website_session_id;

-- Step 2: Identifying the landing page for each session and creating a TEMPORARY TABLE to use in later steps
CREATE TEMPORARY TABLE sessions_counts_landing_page
SELECT
	sf.website_session_id,
    sf.min_pageview_id,
    sf.count_of_pageviews,
    wp.pageview_url AS landing_page,
    wp.created_at AS session_created_at
FROM sessions_first_pv_id_view_count sf
LEFT JOIN website_pageviews wp
	ON sf.min_pageview_id = wp.website_pageview_id;
    
-- Step 3: Aggregating weekly data and comparing landing page performance
SELECT
	-- YEARWEEK(session_created_at) AS year_week,
    MIN(DATE(session_created_at)) AS week_start_date,
    COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN count_of_pageviews = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
    ROUND(COUNT(DISTINCT CASE WHEN count_of_pageviews = 1 THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT website_session_id) * 100, 2) AS bounce_rate,
	COUNT(CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
	COUNT(CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM sessions_counts_landing_page
GROUP BY YEARWEEK(session_created_at);