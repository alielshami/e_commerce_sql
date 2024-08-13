use mavenfuzzyfactory;

Select
	*
From
	products
Limit 10;

Select
	*
From
	orders
Limit 10;

Select
	*
From
	order_items
Limit 10;

Select
	*
From
	order_item_refunds
Limit 10;

Select
	*
From
	website_pageviews
Limit 10;

Select
	*
From
	website_sessions
Limit 10;

-- UNDERSTANDING TRAFFIC ANALYSIS
Select distinct
	utm_source,
    utm_campaign
From
	website_sessions;

SELECT
	ws.utm_content, 
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) /COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rt
FROM website_sessions ws
	LEFT JOIN orders o
		 ON	o.website_session_id = ws.website_session_id
WHERE
	ws.website_session_id BETWEEN 1000 AND 2000
GROUP BY 
	1
ORDER BY 2 DESC; 


SELECT
	ws.utm_source,
    ws.utm_campaign,
    ws.http_referer,
    COUNT(DISTINCT ws.website_session_id) AS sessions
--     COUNT(DISTINCT o.order_id) AS orders,
--     COUNT(DISTINCT o.order_id) /COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rt
FROM website_sessions ws
	-- LEFT JOIN orders o
-- 		 ON	o.website_session_id = ws.website_session_id	
WHERE
	ws.created_at < '2012-04-12'
GROUP BY 
	1,2,3
ORDER BY 4 DESC; 


SELECT
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) /COUNT(DISTINCT ws.website_session_id)  AS CVR
FROM website_sessions ws
	LEFT JOIN orders o
		ON o.website_session_id = ws.website_session_id	
WHERE
	ws.created_at < '2012-04-14' 
    AND ws.utm_source = 'gsearch' 
    AND ws.utm_campaign = 'nonbrand';


SELECT 
    YEAR(created_at),
    WEEK(created_at),
    MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT(website_session_id)) AS sessions
FROM website_sessions 
WHERE website_session_id BETWEEN 100000 AND 115000
GROUP BY 1,2; 

SELECT
	primary_product_id,
    COUNT(DISTINCT CASE WHEN items_purchased = 1 THEN order_id ELSE NULL END) as orders_w_1_item,
    COUNT(DISTINCT CASE WHEN items_purchased = 2 THEN order_id ELSE NULL END) as orders_w_2_item,
    COUNT(DISTINCT order_id) as total_orders
FROM orders
WHERE order_id BETWEEN 31000 AND 32000
GROUP BY 1;

SELECT 
    MIN(DATE(created_at)) AS week_started_at,
    COUNT(DISTINCT(website_session_id)) AS sessions
FROM website_sessions 
WHERE created_at < '2012-05-10' 
	AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
GROUP BY 
	YEAR(created_at),
    WEEK(created_at);	 
    
    
SELECT
	device_type,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) /COUNT(DISTINCT ws.website_session_id)  AS CVR
FROM website_sessions ws
	LEFT JOIN orders o
		ON o.website_session_id = ws.website_session_id	
WHERE
	ws.created_at < '2012-05-11' 
    AND ws.utm_source = 'gsearch' 
    AND ws.utm_campaign = 'nonbrand'
GROUP BY 1;


SELECT 
    MIN(DATE(created_at)) AS week_started_at,
    COUNT(DISTINCT(CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END)) AS dtop_sessions,
    COUNT(DISTINCT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END)) AS mob_sessions
FROM website_sessions 
WHERE created_at < '2012-06-09'
	AND created_at > '2012-04-15'
	AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
GROUP BY 
	YEAR(created_at),
    WEEK(created_at);
    
    
    
-- ANALYZE TOP WEBSITE CONTENT
-- Most visited pages
SELECT 
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS pvs
FROM website_pageviews
WHERE website_pageview_id < 1000
GROUP BY pageview_url
ORDER BY 2 DESC;

-- Top entry pages
CREATE TEMPORARY TABLE first_pageview_all
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
GROUP BY 1;

SELECT 
    wp.pageview_url AS entry_page,
    COUNT(DISTINCT( fp.website_session_id)) AS total_sessions
FROM first_pageview_all fp
	LEFT JOIN website_pageviews wp
		ON fp.min_pv_id = wp.website_pageview_id
GROUP BY 1;

-- Get the most visited pageviews

SELECT 
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS pvs
FROM
	website_pageviews
WHERE
	created_at < '2012-06-09'
GROUP BY 1
ORDER BY pvs DESC;
	

-- Get the most visited landing pages
-- STEP 1: find the first pageview for each session
-- STEP 2: find the url the customer saw on that first pageview
CREATE TEMPORARY TABLE first_pv_per_session
SELECT 
	website_session_id,
    MIN(website_pageview_id) AS first_pv
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;

SELECT 
	wp.pageview_url AS landing_page_url,
    COUNT(DISTINCT fp.website_session_id) AS num_of_sessions
FROM first_pv_per_session fp
	LEFT JOIN website_pageviews wp
		ON fp.first_pv = wp.website_pageview_id
GROUP BY 1;


-- LANDING PAGE PERFORMANCE for a certain time period
-- STEP 1: find the first pageview id for relevant sessions 
-- STEP 2: find the landing page of each session
-- STEP 3: count pageviews for each session, to identify "bounces"
-- STEP 4: summarize total sessions and bounced sessions, by LP

CREATE TEMPORARY TABLE first_pageviews_demo
SELECT
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews wp
	INNER JOIN website_sessions ws
		ON ws.website_session_id = wp.website_session_id
        AND ws.created_at BETWEEN '2014-01-01' AND '2014-02-01'
GROUP BY
	wp.website_session_id;
    
-- bring the landing page to each session
CREATE TEMPORARY TABLE session_w_landing_page_demo
SELECT
	fpd.website_session_id,
    wp.pageview_url AS landing_page
FROM first_pageviews_demo fpd
	LEFT JOIN website_pageviews wp
		ON fpd.min_pageview_id = wp.website_pageview_id;-- website pageview is the landing page
        
-- we make a table to include a count of pageviews per session
-- get only bounced sessions ( COUNT(DISTINCT wp.website_pageview_id) = 1 )
CREATE TEMPORARY TABLE bounced_sessions_only
SELECT 
	slpd.website_session_id,
    slpd.landing_page,
    COUNT(DISTINCT wp.website_pageview_id) AS count_of_pages_viewed
FROM session_w_landing_page_demo slpd
	LEFT JOIN website_pageviews wp
		ON slpd.website_session_id = wp.website_session_id
GROUP BY 1,2
HAVING
	COUNT(DISTINCT wp.website_pageview_id) = 1;
    
SELECT *
FROM bounced_sessions_only;

SELECT
	slpd.landing_page,
    slpd.website_session_id,
    bso.website_session_id AS bounced_website_session_id
FROM session_w_landing_page_demo slpd
	LEFT JOIN bounced_sessions_only bso
		ON slpd.website_session_id = bso.website_session_id
ORDER BY slpd.website_session_id;

-- final output 
	-- same query we just ran, and get a count of records
	-- group by landing page, add bounce rate column
    
SELECT
	slpd.landing_page,
    COUNT(DISTINCT slpd.website_session_id) AS sessions,
    COUNT(DISTINCT bso.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bso.website_session_id) / COUNT(DISTINCT slpd.website_session_id) AS bounce_rate
FROM session_w_landing_page_demo slpd
	LEFT JOIN bounced_sessions_only bso
		ON slpd.website_session_id = bso.website_session_id
GROUP BY 
	slpd.landing_page
ORDER BY slpd.website_session_id;

-- Check that out for the home page (since it has the most pageviews as a landing page)

CREATE TEMPORARY TABLE first_pageviews
SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY
	website_session_id;
    
-- bring the landing page to each session
CREATE TEMPORARY TABLE session_w_home_landing_page
SELECT
	fp.website_session_id,
    wp.pageview_url AS landing_page
FROM first_pageviews fp
	LEFT JOIN website_pageviews wp
		ON fp.min_pageview_id = wp.website_pageview_id
WHERE wp.pageview_url = '/home';-- website pageview is the landing page

SELECT * FROM session_w_home_landing_page;
        
-- we make a table to include a count of pageviews per session
-- get only bounced sessions ( COUNT(DISTINCT wp.website_pageview_id) = 1 )
CREATE TEMPORARY TABLE bounced_sessions
SELECT 
	slpd.website_session_id,
    slpd.landing_page,
    COUNT(DISTINCT wp.website_pageview_id) AS count_of_pages_viewed
FROM session_w_home_landing_page slpd
	LEFT JOIN website_pageviews wp
		ON slpd.website_session_id = wp.website_session_id
GROUP BY 1,2
HAVING
	COUNT(DISTINCT wp.website_pageview_id) = 1;
    

SELECT
    slpd.website_session_id,
    bso.website_session_id AS bounced_website_session_id
FROM session_w_home_landing_page slpd
	LEFT JOIN bounced_sessions bso
		ON slpd.website_session_id = bso.website_session_id
ORDER BY slpd.website_session_id;

-- final output 
	-- same query we just ran, and get a count of records
	-- group by landing page, add bounce rate column
    
SELECT
    COUNT(DISTINCT slpd.website_session_id) AS sessions,
    COUNT(DISTINCT bso.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bso.website_session_id) / COUNT(DISTINCT slpd.website_session_id) AS bounce_rate
FROM session_w_home_landing_page slpd
	LEFT JOIN bounced_sessions bso
		ON slpd.website_session_id = bso.website_session_id
GROUP BY 
	slpd.landing_page;

-- Comparing home page to lander-1

SELECT MIN((created_at)), MIN(website_pageview_id)
INTO @lander_1_date, @pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';

SELECT @lander_1_date, @pv;

WITH first_test_pageviews AS (
	SELECT
		ws.website_session_id,
		MIN(wp.website_pageview_id) AS min_pageview_id
	FROM website_pageviews wp
		INNER JOIN website_sessions ws
			ON wp.website_session_id = ws.website_session_id
	WHERE 
		wp.created_at > @lander_1_date 
        AND wp.created_at < '2012-07-28'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
	GROUP BY
		website_session_id
), 
sessions_w_landing_page AS(
	SELECT
		fpd.website_session_id,
		wp.pageview_url AS landing_page
	FROM first_test_pageviews fpd
		LEFT JOIN website_pageviews wp
			ON fpd.min_pageview_id = wp.website_pageview_id
), bounced_sessionss AS (
	SELECT 
		slpd.website_session_id,
		slpd.landing_page,
		COUNT(DISTINCT wp.website_pageview_id) AS count_of_pages_viewed
	FROM sessions_w_landing_page slpd
		LEFT JOIN website_pageviews wp
			ON slpd.website_session_id = wp.website_session_id
	GROUP BY 1,2
	HAVING
		COUNT(DISTINCT wp.website_pageview_id) = 1
)
SELECT
	slpd.landing_page,
    COUNT(DISTINCT slpd.website_session_id) AS sessions,
    COUNT(DISTINCT bso.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bso.website_session_id) / COUNT(DISTINCT slpd.website_session_id) AS bounce_rate
FROM sessions_w_landing_page slpd
	LEFT JOIN bounced_sessionss bso
		ON slpd.website_session_id = bso.website_session_id
GROUP BY 
	slpd.landing_page;

-- -------
-- -------
-- -------
-- -------

WITH first_test_pageviews AS (
	SELECT
		wp.website_session_id,
		MIN(wp.website_pageview_id) AS min_pageview_id
	FROM website_pageviews wp
		INNER JOIN website_sessions ws
			ON wp.website_session_id = ws.website_session_id
	WHERE 
		wp.created_at > '2012-06-01' 
        AND wp.created_at < '2012-08-31'
        AND utm_source Like '%search'
        AND utm_campaign = 'nonbrand'
	GROUP BY
		website_session_id
) , 
 sessions_w_landing_page AS(
	SELECT
		wp.created_at,
		fpd.website_session_id,
		wp.pageview_url AS landing_page
	FROM first_test_pageviews fpd
		LEFT JOIN website_pageviews wp
			ON fpd.min_pageview_id = wp.website_pageview_id
), bounced_sessionss AS (
	SELECT 
		slpd.website_session_id,
		slpd.landing_page,
		COUNT(DISTINCT wp.website_pageview_id) AS count_of_pages_viewed
	FROM sessions_w_landing_page slpd
		LEFT JOIN website_pageviews wp
			ON slpd.website_session_id = wp.website_session_id
	GROUP BY 1, 2
	HAVING
		COUNT(DISTINCT wp.website_pageview_id) = 1
)
SELECT
	MIN(DATE(slpd.created_at)) AS week_start,
    COUNT(DISTINCT bso.website_session_id) / COUNT(DISTINCT slpd.website_session_id) AS bounce_rate,
    COUNT(DISTINCT(CASE WHEN slpd.landing_page = '/home' THEN  slpd.website_session_id ELSE NULL END)) AS home_sessions,
    COUNT(DISTINCT(CASE WHEN slpd.landing_page = '/lander-1' THEN  slpd.website_session_id ELSE NULL END)) AS lander_sessions
FROM sessions_w_landing_page slpd
	LEFT JOIN bounced_sessionss bso
		ON slpd.website_session_id = bso.website_session_id
GROUP BY 
	YEARWEEK(slpd.created_at); --  = GROUP BY WEEK(slpd.created_at), YEAR(slpd.created_at);
    
-- ANALYZING & TESTING CONVERSION FUNNELS

-- Hi there! 
-- I’d like to understand where we lose our gsearch visitors 
-- between the new /lander-1 page and placing an order. Can 
-- you build us a full conversion funnel, analyzing how many 
-- customers make it to each step?
--  Start with /lander-1 and build the funnel all the way to our 
-- thank you page. Please use data since August 5th.
--  Thanks!-Morgan


WITH sessions_w_pageview_level AS (
	SELECT
		website_session_id,
		MAX(products_page) AS products_made_it,
		MAX(mrfuzzy_page) AS mrfuzzy_made_it,
		MAX(cart_page) AS cart_made_it,
        MAX(shipping_page) AS shipping_made_it,
        MAX(billing_page) AS billing_made_it,
        MAX(thankyou_page) AS thankyou_made_it
	FROM (

		SELECT
			ws.website_session_id,
			pv.pageview_url,
			pv.created_at AS pageview_created_at,
			CASE WHEN pv.pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
			CASE WHEN pv.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
			CASE WHEN pv.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
            CASE WHEN pv.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
            CASE WHEN pv.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
            CASE WHEN pv.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
		FROM website_sessions ws
			LEFT JOIN website_pageviews pv
				ON ws.website_session_id = pv.website_session_id
		WHERE ws.created_at BETWEEN '2012-08-05' AND '2012-09-05'
			AND ws.utm_source = 'gsearch'
            AND ws.utm_campaign = 'nonbrand'
			AND pv.pageview_url IN
				('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
		ORDER BY
			ws.website_session_id,
			pv.created_at
	) AS pageview_level
	GROUP BY website_session_id
)
SELECT 
	COUNT(website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(website_session_id) AS lander_clickthrough_rate,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS products_clickthrough_rate,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_clickthrough_rate,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_clickthrough_rate,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_clickthrough_rate,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_clickthrough_rate
FROM sessions_w_pageview_level;

-- Hello! 
-- We tested an updated billing page based on your funnel 
-- analysis. Can you take a look and see whether /billing-2 is 
-- doing any better than the original /billing page? 
-- We’re wondering what % of sessions on those pages end up 
-- placing an order. FYI –we ran this test for all traffic, not just 
-- for our search visitors.

SELECT 
	MIN(created_at),
    MIN(website_pageview_id)
INTO 
	@billing_2_date,
    @billing_2_pageview_id
FROM website_pageviews
WHERE pageview_url = '/billing-2';

SELECT @billing_2_date, @billing_2_pageview_id;

SELECT 
	wp.website_session_id,
    wp.pageview_url AS billing_version_seen,
    o.order_id
FROM website_pageviews wp
	LEFT JOIN orders o
		ON wp.website_session_id = o.website_session_id
WHERE wp.website_pageview_id > @billing_2_pageview_id
	AND wp.created_at < '2012-11-10'
    AND wp.pageview_url IN ('/billing', '/billing-2');



SELECT 
	billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(DISTINCT website_session_id) AS billint_to_order_rt
FROM (
	SELECT 
		wp.website_session_id,
		wp.pageview_url AS billing_version_seen,
		o.order_id
	FROM website_pageviews wp
		LEFT JOIN orders o
			ON wp.website_session_id = o.website_session_id
	WHERE wp.website_pageview_id > @billing_2_pageview_id
		AND wp.created_at < '2012-11-10'
		AND wp.pageview_url IN ('/billing', '/billing-2')
) AS billing_sessions_w_orders
GROUP BY billing_version_seen;
