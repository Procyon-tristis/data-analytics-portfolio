-- Денормализованная витрина заказов
CREATE TABLE marts.fct_orders AS
SELECT 
    o.order_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    ROUND(EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_delivered_customer_date)) / 86400, 1) AS delivery_delta_days,  -- разница в днях между оценкой и фактом доставки (отрицательное число = опоздание)
    ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400, 1) AS actual_delivery_days,      -- фактическое время доставки клиенту в днях
    oi.items_count,
    oi.total_order_cost,
    oi.total_freight,
    r.review_score
FROM raw.orders o
JOIN raw.customers c ON o.customer_id = c.customer_id
LEFT JOIN (
    SELECT 
        order_id,
        COUNT(order_item_id) AS items_count,
        SUM(price) AS total_order_cost,
        SUM(freight_value) AS total_freight
    FROM raw.order_items
    GROUP BY order_id
) oi ON o.order_id = oi.order_id
LEFT JOIN (
    SELECT order_id, AVG(review_score) AS review_score
    FROM raw.order_reviews
    GROUP BY order_id
) r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';


-- Витрина для RFM-сегментации клиентов
CREATE TABLE marts.rfm_customers AS
WITH customer_aggregates AS (
    SELECT 
        customer_unique_id,
        MAX(order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency,
        COALESCE(SUM(total_order_cost), 0) AS monetary
    FROM marts.fct_orders
    GROUP BY customer_unique_id
),
dataset_end_date AS (
    SELECT MAX(order_purchase_timestamp) + INTERVAL '1 day' AS ref_date FROM marts.fct_orders
)
SELECT 
    c.customer_unique_id,
    ROUND(EXTRACT(EPOCH FROM (d.ref_date - c.last_order_date)) / 86400) AS recency_days,
    c.frequency,
    c.monetary
FROM customer_aggregates c
CROSS JOIN dataset_end_date d;
