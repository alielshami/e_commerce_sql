-- Channel Portfolio Analysis
Use mavenfuzzyfactory;

SELECT
	utm_content, 
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS cvr
FROM website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at BETWEEN '2014-01-01' AND '2014-02-01' -- arbitrary date to just view data
GROUP BY 1
ORDER BY sessions DESC;

/*
With gsearch doing well and the site performing better, we 
launched a second paid search channel, bsearch, around 
August 22.
 Can you pull weekly trended session volume since then and 
compare to gsearch nonbrandso I can get a sense for how 
important this will be for the business?
*/

SELECT
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN utm_source='gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source='bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE utm_campaign = 'nonbrand'
	AND created_at < '2012-11-29'
    AND created_at > '2012-08-22'
GROUP BY 
	YEAR(created_at),
	WEEK(created_at);
    
-- Comparing channel characteristics 

/*
 Hi there,
 I’d like to learn more about the bsearchnonbrand campaign. 
Could you please pullthe percentage of traffic coming on 
Mobile, and compare that to gsearch?
 Feel free to dig around and share anything else you find 
interesting. Aggregate data since August 22nd is great, no 
need to show trending at this point. 
*/
SELECT DISTINCT device_type FROM website_sessions;
SELECT
	utm_source,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN device_type='mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type='mobile' THEN website_session_id ELSE NULL END) / 
		 COUNT(DISTINCT website_session_id) AS pct_mobile
FROM website_sessions
WHERE utm_campaign = 'nonbrand'
	AND created_at < '2012-11-30'
    AND created_at > '2012-08-22'
GROUP BY utm_source;

-- Cross channel bid optimization

/*
I’m wondering if bsearch nonbrand should have the same 
bids as gsearch. Could you pull nonbrand conversion rates 
from session to order for gsearch and bsearch, and slice the 
data by device type?
 Please analyze data from August 22 toSeptember 18; we 
ran a special pre-holiday campaign for gsearch starting on 
September 19th, so the data after that isn’t fair game.
*/

SELECT 
	ws.device_type,
    ws.utm_source,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS cvr
FROM website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE utm_campaign = 'nonbrand'
	AND ws.created_at < '2012-09-19'
    AND ws.created_at > '2012-08-22'
GROUP BY 1,2;

-- Analyzing Channel Portfolio Trends

/*
 Based on your last analysis, we bid down bsearch nonbrand on 
December 2nd.
 Can you pull weekly session volume for gsearch and bsearch 
nonbrand, broken down by device, since November 4th?
 If you can include a comparison metric to show bsearchas a 
percent of gsearchfor each device, that would be great too. 
*/

SELECT
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN utm_source='gsearch' AND device_type = 'desktop' 
		THEN website_session_id ELSE NULL END) AS g_dtop_sessions,
	COUNT(DISTINCT CASE WHEN utm_source='bsearch' AND device_type = 'desktop' 
		THEN website_session_id ELSE NULL END) AS b_dtop_sessions,
	COUNT(DISTINCT CASE WHEN utm_source='bsearch' AND device_type = 'desktop' 
		THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN utm_source='gsearch'
		AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS b_pct_of_g_dtop,
	COUNT(DISTINCT CASE WHEN utm_source='gsearch' AND device_type = 'mobile' 
		THEN website_session_id ELSE NULL END) AS g_mob_sessions,
	COUNT(DISTINCT CASE WHEN utm_source='bsearch' AND device_type = 'mobile' 
		THEN website_session_id ELSE NULL END) AS b_mob_sessions,
	COUNT(DISTINCT CASE WHEN utm_source='bsearch' AND device_type = 'mobile' 
		THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN utm_source='gsearch'
		AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS b_pct_of_g_mob
FROM website_sessions
WHERE utm_campaign = 'nonbrand'
	AND created_at < '2012-12-22'
    AND created_at > '2012-11-04'
GROUP BY 
	YEAR(created_at),
	WEEK(created_at);
    
-- Analyzing Direct, Brand-driven Traffic
SELECT http_referer FROM website_sessions WHERE utm_source IS NOT NULL AND http_referer IS NULL;
SELECT 
    CASE 
		WHEN http_referer IS NULL THEN 'direct_type_in'
		WHEN http_referer = 'https://www.gsearch.com' AND utm_source IS NULL THEN 'gsearch_organic'
        WHEN http_referer = 'https://www.bsearch.com' AND utm_source IS NULL THEN 'bsearch_organic'
        ELSE 'Other'
	END AS type,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000 -- arbitrary
	-- AND utm_source is NULL
 GROUP BY 1
 ORDER BY 2 DESC;
-- dive into http_referer --> when it is NULL that means this was direct type in search ELSE its organic search


/* 
A potential investor is asking if we’re building any 
momentum with our brand or if we’ll need to keep relying 
on paid traffic.
 Could you pull organic search, direct type in, and paid 
brand search sessions by month, and show those sessions 
as a % of paid search nonbrand?
*/
SELECT
	YEAR(created_at)AS yr,
    MONTH(created_at) AS mo,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END) AS brand,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS brand_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END) AS direct,
    COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand,
	COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END) AS organic,
    COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM(
	SELECT
		website_session_id,
		created_at,
		CASE 
			WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com')
				THEN 'organic_search'
			WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
			WHEN utm_campaign = 'brand'  THEN 'paid_brand'
			WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
		END AS channel_group
	FROM website_sessions
	WHERE created_at < '2012-12-23'
) AS session_w_channel_group
GROUP BY 1,2 ;

-- Analyzing Seasonality and Business Trends

SELECT 
website_session_id,
created_at
FROM 
website_sessions
WHERE 
website_session_id BETWEEN 150000 AND 155000; -- arbitrary 

/*
2012 was a great year for us. As we continue to grow, we 
should take a look at 2012’s monthly and weekly volume 
patterns, to see if we can find any seasonal trends we 
should plan for in 2013.
 If you can pull session volume and order volume, that 
would be excellent.
*/

SELECT
	YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2013-01-02'
GROUP BY 1,2;

SELECT
	MIN(DATE(ws.created_at)) as week_start,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2013-01-02'
GROUP BY 
	YEAR(ws.created_at),
    WEEK(ws.created_at);
    
-- pretty steady increase through the year with a significant increase in the last weeks of November

/*
We’re considering adding live chat support to the website 
to improve our customer experience. Could you analyze 
the average website session volume, by hour of day and 
by day week,so that we can staff appropriately? 
Let’s avoid the holiday time period and use a date range of 
Sep 15 -Nov 15, 2013.
*/

SELECT
	hr,
    ROUND(AVG(CASE WHEN wkday = 0 THEN sessions ELSE NULL END),1) AS mon,
    ROUND(AVG(CASE WHEN wkday = 1 THEN sessions ELSE NULL END),1) AS tue,
    ROUND(AVG(CASE WHEN wkday = 2 THEN sessions ELSE NULL END),1) AS wed,
    ROUND(AVG(CASE WHEN wkday = 3 THEN sessions ELSE NULL END),1) AS thu,
    ROUND(AVG(CASE WHEN wkday = 4 THEN sessions ELSE NULL END),1) AS fri,
    ROUND(AVG(CASE WHEN wkday = 5 THEN sessions ELSE NULL END),1) AS sat,
    ROUND(AVG(CASE WHEN wkday = 6 THEN sessions ELSE NULL END),1) AS sun
FROM (
	SELECT
		DATE(created_at) AS created_date,
		WEEKDAY(created_at) AS wkday,
		HOUR(created_at) AS hr,
		COUNT(DISTINCT website_session_id) AS sessions
	FROM website_sessions
	WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
	GROUP BY 1,2,3
) AS daily_hourly_sessions
GROUP BY hr;

SELECT
	DATE(created_at) AS created_date,
    WEEKDAY(created_at) AS wkday,
    HOUR(created_at) AS hr,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY 1,2,3;

-- Product Sales Analysis

/*
 We’re about to launch a new product, and I’d like to do a 
deep dive on our current flagship product.
 Can you please pull monthly trends to date for number of 
sales, total revenue, and total margin generatedfor the 
business?
*/

SELECT 
	DISTINCT(primary_product_id)
FROM orders
WHERE created_at < '2013-01-04';

SELECT
	DATE_FORMAT(created_at, '%Y-%m') AS month,
    COUNT(DISTINCT order_id) AS number_of_sales,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY 1;

/*
We launched our second product back on January 6th. Can 
you pull together some trended analysis? 
I’d like to see monthly order volume, overall conversion 
rates, revenue per session, and a breakdown of sales by 
product, all for the time period since April 1, 2012.
*/

SELECT
	DATE_FORMAT(ws.created_at, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS conv_rate,
    SUM(o.price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session,
    COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN o.order_id ELSE NULL END) AS product_one_orders,
    COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN o.order_id ELSE NULL END) AS product_two_orders
FROM website_sessions ws
	LEFT JOIN orders o
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at > '2012-04-01'
	AND ws.created_at < '2013-04-05'
GROUP BY 1;

-- Product Level website analysis

SELECT
	wp.pageview_url,
    COUNT(DISTINCT wp.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT wp.website_session_id) AS viewed_product_to_order_rate
FROM website_pageviews wp
	LEFT JOIN orders o
		ON wp.website_session_id = o.website_session_id
WHERE wp.created_at BETWEEN '2013-02-01' AND '2013-03-01'
	AND wp.pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear')
GROUP BY 1;

WITH product_pageviews AS (
	SELECT 
		website_session_id,
        website_pageview_id,
        created_at,
        CASE
			WHEN created_at < '2013-01-06' THEN 'A. Pre_Product_2'
            WHEN created_at >= '2013-01-06' THEN 'B. Post_Product_2'
			ELSE NULL
		END AS time_period
	FROM website_pageviews
    WHERE created_at < '2013-04-06'
		AND created_at > '2012-10-06'
        AND pageview_url = '/products'
),
sessions_w_next_pageview_id AS (
	SELECT
		product_pageviews.time_period AS time_period,
        product_pageviews.website_session_id AS website_session_id,
        MIN(website_pageviews.website_pageview_id) AS next_pageview_id
	FROM product_pageviews
		LEFT JOIN website_pageviews
			ON product_pageviews.website_session_id = website_pageviews.website_session_id
            AND website_pageviews.website_pageview_id > product_pageviews.website_pageview_id
	GROUP BY 1,2
),
sessions_w_next_pageview_url AS (
	SELECT
		sessions_w_next_pageview_id.time_period AS time_period,
        sessions_w_next_pageview_id.website_session_id AS website_session_id,
        website_pageviews.pageview_url AS next_pageview_url
	FROM sessions_w_next_pageview_id
		LEFT JOIN website_pageviews
			ON sessions_w_next_pageview_id.next_pageview_id = website_pageviews.website_pageview_id		
)
SELECT
	time_period,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_page,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id) AS pct_w_next_page,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)
		AS to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)
		AS to_lovebear,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id) AS pct_to_lovebear
FROM sessions_w_next_pageview_url
GROUP BY 1;

/*
I’d like to look at our two products since January 6th and 
analyze the conversion funnels from each product page to 
conversion.
 It would be great if you could produce a comparison between 
the two conversion funnels, for all website traffic.
*/

-- Step 1: Select All Pageviews for relevant sessions
USE mavenfuzzyfactory;
WITH sessions_seeing_product_pages AS (
	SELECT 
		website_session_id,
        website_pageview_id,
        pageview_url AS product_page_seen
	FROM website_pageviews
    WHERE created_at < '2013-04-10'
		AND created_at > '2013-01-06'
        AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear')
)
-- Step 2: figure out which pageview urls to look for
SELECT DISTINCT 
	website_pageviews.pageview_url
FROM sessions_seeing_product_pages
	LEFT JOIN website_pageviews 
		ON sessions_seeing_product_pages.website_session_id = website_pageviews.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id;
        
-- URLS: cart, shipping, billing-2, thank-you-for-your-order

-- Step 3: pull all pageviews and identify the funnel steps
CREATE TEMPORARY TABLE funnel_steps
SELECT
	website_session_id,
    CASE
		WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'check logic'
	END AS product_seen,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
WITH sessions_seeing_product_pages AS (
	SELECT 
		website_session_id,
        website_pageview_id,
        pageview_url AS product_page_seen
	FROM website_pageviews
    WHERE created_at < '2013-04-10'
		AND created_at > '2013-01-06'
        AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear')
)
SELECT 
	sessions_seeing_product_pages.website_session_id,
    sessions_seeing_product_pages.product_page_seen,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages
	LEFT JOIN website_pageviews 
		ON sessions_seeing_product_pages.website_session_id = website_pageviews.website_session_id
        AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
ORDER BY
	sessions_seeing_product_pages.website_session_id,
    website_pageviews.created_at
) AS pageview_level
GROUP BY 
	website_session_id,
    product_seen;
    
SELECT
	product_seen,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id) AS product_page_click_rt,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM funnel_steps
GROUP BY product_seen;	

	
SELECT
	product_seen,
	COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM funnel_steps
GROUP BY product_seen;

-- CROSS SELLING PRODUCTS

SELECT
    orders.primary_product_id,
    COUNT(DISTINCT orders.order_id) AS orders,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END) AS x_sell_prod1,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END) AS x_sell_prod2,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END) AS x_sell_prod3
FROM orders
	LEFT JOIN order_items
		ON order_items.order_id = orders.order_id
        AND order_items.is_primary_item = 0 -- cross sell only
WHERE orders.order_id BETWEEN 10000 AND 11000
GROUP BY 1; -- arbitrary


/*
On September 25thwe started giving customers the option 
to add a 2ndproduct while on the /cart page. Morgan says 
this has been positive, but I’d like your take on it.
 Could you please compare the month before vs the month 
after the change? I’d like to seeCTR from the /cart page, 
Avg Products per Order, AOV, and overall revenue per 
/cart page view.
*/
CREATE TEMPORARY TABLE session_seeing_cart
SELECT
	CASE
		WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
        WHEN created_at >= '2013-09-25' THEN 'B. Post_Cross_Sell'
		ELSE 'check logic'
	END AS time_period,
    website_session_id AS cart_session_id,
    website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25';

CREATE TEMPORARY TABLE cart_sessions_w_next_page
SELECT
	session_seeing_cart.time_period,
    session_seeing_cart.cart_session_id,
    MIN(website_pageviews.website_pageview_id) AS pv_id_after_cart
FROM session_seeing_cart
	LEFT JOIN website_pageviews
		ON session_seeing_cart.cart_session_id = website_pageviews.website_session_id
        AND website_pageviews.website_pageview_id > session_seeing_cart.cart_pageview_id
GROUP BY
	session_seeing_cart.time_period,
    session_seeing_cart.cart_session_id
HAVING MIN(website_pageviews.website_pageview_id) IS NOT NULL;


CREATE TEMPORARY TABLE pre_post_session_orders
SELECT
	time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
FROM session_seeing_cart
	JOIN orders
		ON orders.website_session_id = session_seeing_cart.cart_session_id;
       

SELECT
	session_seeing_cart.time_period,
    session_seeing_cart.cart_session_id,
    CASE WHEN cart_sessions_w_next_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
	CASE WHEN pre_post_session_orders.cart_session_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_session_orders.items_purchased,
    pre_post_session_orders.price_usd
FROM session_seeing_cart
	LEFT JOIN cart_sessions_w_next_page
		ON session_seeing_cart.cart_session_id = cart_sessions_w_next_page.cart_session_id
	LEFT JOIN pre_post_session_orders
		ON session_seeing_cart.cart_session_id = pre_post_session_orders.cart_session_id
ORDER BY session_seeing_cart.cart_session_id;

SELECT
	time_period,
    COUNT(DISTINCT cart_session_id) AS cart_sessions,
    SUM(clicked_to_another_page) AS clickthroughs,
    SUM(clicked_to_another_page) / COUNT(DISTINCT cart_session_id) AS clickthrough_rate,
    SUM(placed_order) AS orders_placed,
    SUM(items_purchased) AS items,
    SUM(items_purchased) / SUM(placed_order) AS products_per_order,
    SUM(price_usd) / SUM(placed_order) AS aov,
    SUM(price_usd) / COUNT(DISTINCT cart_session_id) AS rev_per_cart_session
FROM(
	SELECT
		session_seeing_cart.time_period,
		session_seeing_cart.cart_session_id,
		CASE WHEN cart_sessions_w_next_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
		CASE WHEN pre_post_session_orders.cart_session_id IS NULL THEN 0 ELSE 1 END AS placed_order,
		pre_post_session_orders.items_purchased,
		pre_post_session_orders.price_usd
	FROM session_seeing_cart
		LEFT JOIN cart_sessions_w_next_page
			ON session_seeing_cart.cart_session_id = cart_sessions_w_next_page.cart_session_id
		LEFT JOIN pre_post_session_orders
			ON session_seeing_cart.cart_session_id = pre_post_session_orders.cart_session_id
	ORDER BY cart_session_id
) AS fulldata
GROUP BY time_period;


/*
 On December 12th2013, we launched a third product 
targeting the birthday gift market (Birthday Bear).
 Could you please run a pre-post analysis comparing the 
month before vs. the month after, in terms of session-to
order conversion rate, AOV, products per order, and 
revenue per session
*/

SELECT
	CASE
		WHEN website_sessions.created_at < '2013-12-12' THEN 'A. Pre_Birthday_Bear'
        WHEN website_sessions.created_at > '2013-12-12' THEN 'B. Post_Birthday_Bear'
	END AS time_period,
    -- COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    -- COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    -- SUM(orders.price_usd) AS total_revenue,
    -- SUM(orders.items_purchased) AS total_products_sold,
    SUM(orders.price_usd) / COUNT(DISTINCT orders.order_id) AS average_order_value,
    SUM(orders.items_purchased) /  COUNT(DISTINCT orders.order_id) AS products_per_order,
	SUM(orders.price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY time_period;

-- PRODUCT REFUND ANALYSIS

/*
Our Mr. Fuzzy supplier had some quality issues which 
weren’t corrected until September 2013. Then they had a 
major problem where the bears’ arms were falling off in 
Aug/Sep 2014. As a result, we replaced them with a new 
supplier on September 16, 2014.
 Can you please pull monthly product refund rates, by 
product, and confirm our quality issues are now fixed?
*/

SELECT 
	DISTINCT(product_id)
FROM order_items; -- 1,2,3,4

SELECT
	YEAR(order_items.created_at),
    MONTH(order_items.created_at),
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS p1_orders,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refunds.order_item_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS p1_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS p2_orders,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refunds.order_item_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS p2_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS p3_orders,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refunds.order_item_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS p3_refund_rt,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS p4_orders,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refunds.order_item_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS p4_refund_rt
FROM order_items
	LEFT JOIN order_item_refunds
		ON order_items.order_item_id = order_item_refunds.order_item_id
WHERE order_items.created_at < '2014-10-15'
GROUP BY 1,2;

-- The supplier obviously had problems which was significant in the refund rate on August and September
-- but the refund rate dropped down on October which means the supplier fixed the issues