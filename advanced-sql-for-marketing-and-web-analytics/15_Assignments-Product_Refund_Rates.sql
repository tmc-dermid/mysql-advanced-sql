USE `mavenfuzzyfactory`;

-- Assignment 15: Product Refund Rates

-- Context:
-- Our Mr. Fuzzy supplier had some quality issues which weren’t corrected until September 2013.
-- As a result, we replaced them with a new supplier on September 16, 2014.
-- Pull monthly product refund rates, by product, and confirm our quality issues are now fixed.

SELECT
	YEAR(oi.created_at) AS yr,
    MONTH(oi.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN oi.product_id = 1 THEN oi.order_item_id ELSE NULL END) AS prod1_orders,
    COUNT(DISTINCT CASE WHEN oi.product_id = 1 THEN oir.order_item_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN oi.product_id = 1 THEN oi.order_item_id ELSE NULL END) AS prod1_refund_rate,
    COUNT(DISTINCT CASE WHEN oi.product_id = 2 THEN oi.order_item_id ELSE NULL END) AS prod2_orders,
    COUNT(DISTINCT CASE WHEN oi.product_id = 2 THEN oir.order_item_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN oi.product_id = 2 THEN oi.order_item_id ELSE NULL END) AS prod2_refund_rate,
	COUNT(DISTINCT CASE WHEN oi.product_id = 3 THEN oi.order_item_id ELSE NULL END) AS prod3_orders,
    COUNT(DISTINCT CASE WHEN oi.product_id = 3 THEN oir.order_item_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN oi.product_id = 3 THEN oi.order_item_id ELSE NULL END) AS prod3_refund_rate,
	COUNT(DISTINCT CASE WHEN oi.product_id = 4 THEN oi.order_item_id ELSE NULL END) AS prod4_orders,
    COUNT(DISTINCT CASE WHEN oi.product_id = 4 THEN oir.order_item_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN oi.product_id = 4 THEN oi.order_item_id ELSE NULL END) AS prod4_refund_rate
FROM order_items oi
LEFT JOIN order_item_refunds oir
	ON oi.order_item_id = oir.order_item_id
WHERE oi.created_at < '2014-10-15'
GROUP BY yr, mo;