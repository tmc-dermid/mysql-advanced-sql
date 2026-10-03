USE `mavenfuzzyfactory`;

-- Assignment 16.1: Repeat Behavior Analysis - Identifying Repeat Visitors

-- Context:
-- Pull data on how many of our website visitors come back for another session.

-- Step 1: Identify the relevant new sessions
-- Step 2: Use the user_id values from Step 1 to find any repeat sessions those users had
-- Step 3: Analyze the data at the user-level (how many sessions did each user have?)
-- Step 4: Aggregate the user-level data.

CREATE TEMPORARY TABLE new_sessions_only
SELECT
	user_id,
    website_session_id
FROM website_sessions
WHERE created_at < '2014-11-01' -- date of assignment
	AND created_at >= '2014-01-01' -- prescribed in assignment
    AND is_repeat_session = 0; -- new sessions only
    
CREATE TEMPORARY TABLE sessions_repeats
SELECT
	nso.user_id,
    nso.website_session_id AS new_session_id,
    ws.website_session_id AS repeat_session_id
FROM new_sessions_only nso
LEFT JOIN website_sessions ws
	ON nso.user_id = ws.user_id
	AND ws.is_repeat_session = 1 -- was a repeat session
    AND ws.website_session_id > nso.website_session_id -- session was later than the new session
    AND ws.created_at < '2014-11-01' -- date of assignment
	AND ws.created_at >= '2014-01-01'; -- prescribed in assignment
    
SELECT
	repeat_sessions,
    COUNT(DISTINCT user_id) AS users
FROM (
	SELECT
		user_id,
        COUNT(DISTINCT new_session_id) AS new_sessions,
        COUNT(DISTINCT repeat_session_id) AS repeat_sessions
    FROM sessions_repeats
    GROUP BY user_id
) user_level
GROUP BY repeat_sessions;


-- Assignment 16.2: Repeat Behavior Analysis - Analyzing Time-to-Repeat

-- Context:
-- Show the minimum, maximum, and average time between the first and second session for customers who do come back

-- Step 1: Identify the relevant new sessions
-- Step 2: Use the user_id values from Step 1 to find any repeat sessions those users had
-- Step 3: Find the created_at times for first and second sessions
-- Step 4: Find the differences between first and second sessions at a user-level
-- Step 5: Aggregate the user-level data.

CREATE TEMPORARY TABLE new_sessions_only
SELECT
	user_id,
    website_session_id,
    created_at
FROM website_sessions
WHERE created_at < '2014-11-03' -- date of assignment
	AND created_at >= '2014-01-01' -- prescribed in assignment
    AND is_repeat_session = 0; -- new sessions only
    
CREATE TEMPORARY TABLE sessions_repeats_for_time_diff
SELECT
	nso.user_id,
    nso.website_session_id AS new_session_id,
    nso.created_at AS new_session_created_at,
    ws.website_session_id AS repeat_session_id,
    ws.created_at AS repeat_session_created_at
FROM new_sessions_only nso
LEFT JOIN website_sessions ws
	ON nso.user_id = ws.user_id
	AND ws.is_repeat_session = 1 -- was a repeat session
    AND ws.website_session_id > nso.website_session_id -- session was later than the new session
    AND ws.created_at < '2014-11-03' -- date of assignment
	AND ws.created_at >= '2014-01-01'; -- prescribed in the assignment
    
SELECT
	user_id,
    new_session_id,
    new_session_created_at,
    MIN(repeat_session_id) AS second_session_id,
    MIN(repeat_session_created_at) AS second_session_created_at
FROM sessions_repeats_for_time_diff
WHERE repeat_session_id IS NOT NULL
GROUP BY
	user_id,
    new_session_id,
    new_session_created_at;
    
CREATE TEMPORARY TABLE users_first_to_seconds
SELECT
	user_id,
    DATEDIFF(second_session_created_at, new_session_created_at) AS days_first_to_second_session
FROM (
	SELECT
		user_id,
		new_session_id,
		new_session_created_at,
		MIN(repeat_session_id) AS second_session_id,
		MIN(repeat_session_created_at) AS second_session_created_at
	FROM sessions_repeats_for_time_diff
	WHERE repeat_session_id IS NOT NULL
	GROUP BY
		user_id,
		new_session_id,
		new_session_created_at
) AS first_second;

-- Aggregating and summarizing
SELECT
	AVG(days_first_to_second_session) AS avg_days_first_to_second,
    MIN(days_first_to_second_session) AS min_days_first_to_second,
    MAX(days_first_to_second_session) AS max_days_first_to_second
FROM users_first_to_seconds;


-- Assignment 16.3: Repeat Behavior Analysis - New vs Repeat Conversion Rates

-- Context:
-- Do a comparison of conversion rates and revenue per session for repeat sessions vs new sessions.

SELECT
	ws.is_repeat_session,
    COUNT(DISTINCT ws.website_session_id) AS total_sessions,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) * 100, 2) AS session_to_order_conv_rate,
    SUM(o.price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions ws
LEFT JOIN orders o
	ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2014-11-08' -- date of assignment
	AND ws.created_at >= '2014-01-01' -- prescribed in the assignment
GROUP BY ws.is_repeat_session;
