-- Витрина для первого экрана: Продажи, категории и география
CREATE TABLE marts.bi_sales_overview AS
SELECT 
    o.order_id,
    o.order_purchase_timestamp::date AS purchase_date,
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS purchase_month,
    c.customer_state,
    c.customer_city,
    COALESCE(t.product_category_name_english, p.product_category_name, 'other') AS category_name,
    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS total_order_item_cost,
    ROUND((oi.price * 0.12)::numeric, 2) AS estimated_olist_commission
FROM raw.orders o
JOIN raw.customers c ON o.customer_id = c.customer_id
JOIN raw.order_items oi ON o.order_id = oi.order_id
LEFT JOIN raw.products p ON oi.product_id = p.product_id
LEFT JOIN raw.product_category_name_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered';

-- Витрина для второго экрана: Логистика и отзывы
CREATE TABLE marts.bi_logistics_reviews AS
SELECT 
    o.order_id,
    o.order_purchase_timestamp::date AS purchase_date,
    c.customer_state,
    s.seller_state,
    CASE 
        WHEN c.customer_state = s.seller_state THEN 'Intra-state' 
        ELSE 'Inter-state' 
    END AS route_type,
    ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400, 1) AS actual_delivery_days,
    ROUND(EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_delivered_customer_date)) / 86400, 1) AS delivery_delta_days,
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status,
    r.review_score
FROM raw.orders o
JOIN raw.customers c ON o.customer_id = c.customer_id
JOIN raw.order_items oi ON o.order_id = oi.order_id
JOIN raw.sellers s ON oi.seller_id = s.seller_id
LEFT JOIN (SELECT order_id, AVG(review_score) AS review_score
    FROM raw.order_reviews
    GROUP BY order_id) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL;