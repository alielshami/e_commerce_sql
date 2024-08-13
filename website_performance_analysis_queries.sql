-- Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions 
-- and orders so that we can showcase the growth there? 

SELECT 
	 DATE_FORMAT(ws.created_at, '%Y-%m') AS month,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE ws.utm_source = 'gsearch'
	AND ws.created_at < '2012-11-27'
GROUP BY  
    DATE_FORMAT(ws.created_at, '%Y-%m');
    
-- Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and 
-- brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell.

SELECT
	DATE_FORMAT(ws.created_at, '%Y-%m') AS month,
    COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions,
    COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN o.order_id ELSE NULL END) AS brand_orders,
    COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) AS nonbrand_orders
FROM website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE ws.utm_source = 'gsearch'
	AND ws.created_at < '2012-11-27'
GROUP BY DATE_FORMAT(ws.created_at, '%Y-%m');    


-- While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device 
-- type? I want to flex our analytical muscles a little and show the board we really know our traffic sources.


SELECT DISTINCT(device_type)
FROM website_sessions
WHERE utm_source = 'gsearch' AND utm_campaign = 'nonbrand';

SELECT
	DATE_FORMAT(ws.created_at, '%Y-%m') AS month,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN o.order_id ELSE NULL END) AS mobile_orders,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN o.order_id ELSE NULL END) AS desktop_orders
FROM website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE ws.utm_source = 'gsearch' 
	AND ws.utm_campaign = 'nonbrand'
		AND ws.created_at < '2012-11-27'
GROUP BY DATE_FORMAT(ws.created_at, '%Y-%m');

/*
4.	I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch. 
Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
*/ 

SELECT DISTINCT utm_source
FROM website_sessions;

SELECT
	DATE_FORMAT(ws.created_at, '%Y-%m') AS month,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN ws.website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN ws.website_session_id ELSE NULL END) AS bsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN ws.website_session_id ELSE NULL END)
		AS organic_search_sessions,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN ws.website_session_id ELSE NULL END)
		AS direct_type_in_sessions
FROM website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
GROUP BY DATE_FORMAT(ws.created_at, '%Y-%m');


/*
5.	I’d like to tell the story of our website performance improvements over the course of the first 8 months. 
Could you pull session to order conversion rates, by month? 

*/ 

SELECT
	DATE_FORMAT(ws.created_at, '%Y-%m') AS month,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS session_to_order_rt
FROM website_sessions ws
	LEFT JOIN orders o 
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
GROUP BY 1;

/*
6.	For the gsearch lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), and use 
nonbrand sessions and revenue since then to calculate incremental value)
*/ 

SELECT 
	MIN(website_pageview_id) AS first_test_pv
INTO @first_test_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';

SELECT @first_test_pv;

-- first test pageview = 23504

WITH first_test_pageviews AS (
	SELECT
		wp.website_session_id,
        MIN(wp.website_pageview_id) AS min_pageview_id
	FROM website_sessions ws
		JOIN website_pageviews wp
			ON ws.website_session_id = wp.website_session_id
			AND ws.created_at < '2012-07-28'
			AND wp.website_pageview_id >= @first_test_pv
			AND ws.utm_source = 'gsearch'
			AND ws.utm_campaign = 'nonbrand'
	GROUP BY 1
),
nonbrand_sessions_w_landing_pages AS (
	SELECT
		ftp.website_session_id,
        wp.pageview_url AS landing_page
	FROM first_test_pageviews ftp
		LEFT JOIN website_pageviews wp
			ON ftp.min_pageview_id = wp.website_pageview_id
	WHERE
		wp.pageview_url IN ('/home','/lander-1')
		
),
nonbrand_sessions_w_orders AS (
	SELECT 
		nonbrand_sessions_w_landing_pages.website_session_id,
        nonbrand_sessions_w_landing_pages.landing_page,
        orders.order_id
	FROM nonbrand_sessions_w_landing_pages
		LEFT JOIN orders 
			ON nonbrand_sessions_w_landing_pages.website_session_id = orders.website_session_id
)
SELECT 
	nonbrand_sessions_w_orders.landing_page,
	COUNT(DISTINCT nonbrand_sessions_w_orders.website_session_id) AS sessions,
    COUNT(DISTINCT nonbrand_sessions_w_orders.order_id) AS orders,
    COUNT(DISTINCT nonbrand_sessions_w_orders.order_id) / 
		COUNT(DISTINCT nonbrand_sessions_w_orders.website_session_id) AS sessions_to_orders_rt
FROM nonbrand_sessions_w_orders
GROUP BY nonbrand_sessions_w_orders.landing_page;

-- For the landing page test you analyzed previously, it would be great to show a full conversion funnel from each 
-- of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28)
SELECT DISTINCT pageview_url FROM website_pageviews;
SELECT
	ws.website_session_id,
    wp.pageview_url,
    CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
    CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END as billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END as thankyou_page
FROM website_sessions ws
	LEFT JOIN website_pageviews wp
		ON ws.website_session_id = wp.website_session_id
WHERE ws.created_at < '2012-07-28'
	AND ws.created_at > '2012-06-19'
    AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand'
ORDER BY 
	ws.website_session_id,
    wp.created_at;
    
CREATE TEMPORARY TABLE session_level_made_it_flagged   
SELECT 
	website_session_id,
    MAX(homepage) AS saw_home_page,
    MAX(custom_lander) AS saw_lander_page,
    MAX(products_page) AS products_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
	SELECT
		ws.website_session_id,
		wp.pageview_url,
		CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
		CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
		CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
		CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
		CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
		CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
		CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END as billing_page,
		CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END as thankyou_page
	FROM website_sessions ws
		LEFT JOIN website_pageviews wp
			ON ws.website_session_id = wp.website_session_id
	WHERE ws.created_at < '2012-07-28'
		AND ws.created_at > '2012-06-19'
		AND ws.utm_source = 'gsearch'
		AND ws.utm_campaign = 'nonbrand'
	ORDER BY 
		ws.website_session_id,
		wp.created_at
) AS pageview_level
GROUP BY website_session_id;

SELECT 
	CASE WHEN saw_home_page = 1 THEN 'saw_home_page'
		WHEN saw_lander_page = 1 THEN 'saw_custom_lander'
        ELSE 'Check logic' END AS segment,
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it_flagged 
GROUP BY 1
;

SELECT
	segment,
	sessions,
    to_products / sessions AS lander_click_rt,
    to_mrfuzzy / to_products AS products_click_rt,
    to_cart / to_mrfuzzy AS mrfuzzy_click_rt,
    to_shipping / to_cart AS cart_click_rt,
    to_billing / to_shipping AS shipping_click_rt,
    to_thankyou / to_billing AS billing_click_rt
FROM (

	SELECT 
		CASE WHEN saw_home_page = 1 THEN 'saw_home_page'
			WHEN saw_lander_page = 1 THEN 'saw_custom_lander'
			ELSE 'Check logic' END AS segment,
		COUNT(DISTINCT website_session_id) AS sessions,
		COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
		COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
		COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
		COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
		COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
		COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
	FROM session_level_made_it_flagged 
	GROUP BY 1

) AS funnel_by_lander;
    
/*
8.	I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated 
from the test (Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number 
of billing page sessions for the past month to understand monthly impact.
*/ 
use mavenfuzzyfactory;
SELECT
	billing_version_seen,
    COUNT(DISTINCT website_session_id),
    COUNT(DISTINCT order_id),
    SUM(price_usd) / COUNT(DISTINCT website_session_id) AS revenue_per_billing_page_seen
FROM(
	SELECT 
		wp.website_session_id,
		wp.pageview_url AS billing_version_seen,
		o.order_id,
		o.price_usd
	FROM website_pageviews wp
		LEFT JOIN orders o
			ON o.website_session_id = wp.website_session_id
	WHERE wp.created_at > '2012-09-10' -- prescribed in assignment
		AND wp.created_at < '2012-11-10' -- prescribed in assignment
			AND wp.pageview_url IN ('/billing', '/billing-2')
) AS sessions_w_billing
GROUP BY billing_version_seen;

SELECT 
	COUNT(website_session_id) AS billing_sessions_past_month
FROM website_pageviews 
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2') 
	AND created_at BETWEEN '2012-10-27' AND '2012-11-27'; -- past month

-- 1,194 billing sessions past month
-- LIFT: $8.51 per billing session
-- VALUE OF BILLING TEST: $10,160 over the past month
    