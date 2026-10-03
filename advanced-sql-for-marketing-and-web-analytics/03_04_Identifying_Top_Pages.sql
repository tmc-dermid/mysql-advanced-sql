USE `mavenfuzzyfactory`;

-- Assignment 3: Identifying Top Website Pages

-- Context:
-- Pull the most viewed website pages, ranked by session volume.

SELECT
	pageview_url,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09' -- date of assignment
GROUP BY pageview_url
ORDER BY sessions DESC;


-- Assignment 4: Identifying Top Entry Pages

-- Context:
-- Pull a list of the top entry pages.
-- Pull all entry pages and rank them on entry volume.

-- Entry page - the first website pageview in each session.

CREATE TEMPORARY TABLE entry_pages
SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-12' -- date of assignment
GROUP BY website_session_id;

SELECT
	wp.pageview_url AS landing_page, -- aka: entry_page
    COUNT(DISTINCT ep.website_session_id) AS sessions
FROM entry_pages ep
LEFT JOIN website_pageviews wp
	ON ep.min_pageview_id = wp.website_pageview_id
GROUP BY landing_page
ORDER BY sessions DESC;
