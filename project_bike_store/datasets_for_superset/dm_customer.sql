{% set selected_stores = filter_values('store_name') %}
{% set selected_states = filter_values('customer_state') %}
{% set start_date = (from_dttm | string)[:10] if from_dttm else '2015-12-30' %}
{% set end_date = (to_dttm | string)[:10] if to_dttm else '2026-12-30' %}
WITH order_totals AS (
    SELECT 
        order_id,
        SUM(quantity * list_price * (1 - discount)) AS order_amount
    FROM sales.order_items
    GROUP BY order_id
),
customer_history AS (
    SELECT 
        customer_id,
        MIN(order_date) AS global_first_order_date
    FROM sales.orders
    WHERE order_status = 4
    GROUP BY customer_id
),
customer_orders AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.city AS customer_city,
        c.state AS customer_state,
        s.store_name,
        o.order_id,
        o.order_date,
        ot.order_amount
    FROM sales.orders o
    JOIN order_totals ot ON o.order_id = ot.order_id
    JOIN sales.stores s ON o.store_id = s.store_id
    JOIN sales.customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 4
      AND o.order_date BETWEEN '{{ start_date }}' AND '{{ end_date }}'
      {% if selected_stores %}
      AND s.store_name IN ('{{ selected_stores | join("', '") }}')
      {% endif %}
      {% if selected_states %}
      AND c.state IN ('{{ selected_states | join("', '") }}')
      {% endif %}
)
SELECT 
    co.customer_id,
    co.first_name,
    co.last_name,
    co.customer_city,
    co.customer_state,
    co.store_name,
    COUNT(DISTINCT co.order_id) AS total_orders,
    SUM(co.order_amount) AS total_revenue,
    AVG(co.order_amount) AS avg_order_value,
    MIN(co.order_date) AS first_order_date,
    MAX(co.order_date) AS last_order_date,
    COUNT(DISTINCT co.order_id) AS orders_in_period,
    CASE 
        WHEN ch.global_first_order_date BETWEEN '{{ start_date }}' AND '{{ end_date }}' 
        THEN 'New' 
        ELSE 'Returning' 
    END AS customer_type,
    CASE 
        WHEN COUNT(DISTINCT co.order_id) >= 2 THEN 'Repeat' 
        ELSE 'Single' 
    END AS repeat_status
FROM customer_orders co
JOIN customer_history ch ON co.customer_id = ch.customer_id
GROUP BY 
    co.customer_id,
    co.first_name,
    co.last_name,
    co.customer_city,
    co.customer_state,
    co.store_name,
    ch.global_first_order_date
ORDER BY total_revenue DESC