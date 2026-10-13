{% set selected_brands = filter_values('brand_name') %}
{% set selected_categories = filter_values('category_name') %}
{% set selected_stores = filter_values('store_name') %}
{% set selected_staffs = filter_values('staff_name') %}
{% set selected_products = filter_values('product_name') %}
{% set start_date = (from_dttm | string)[:10] if from_dttm else '2015-12-30' %}
{% set end_date = (to_dttm | string)[:10] if to_dttm else '2026-12-30' %}
SELECT 
    -- заказ
    o.order_id,
    o.order_date,
    o.customer_id,
    -- сотрудник
    o.staff_id,
    CONCAT(st.first_name, ' ', st.last_name) AS staff_name,
    st.email AS staff_email,
    -- магазин и география
    o.store_id,
    s.store_name,
    s.city AS store_city,
    s.state AS store_state,
    s.latitude,
    s.longitude,
    CASE 
        WHEN s.store_name = 'Santa Cruz Bikes' THEN 'US-CA'
        WHEN s.store_name = 'Baldwin Bikes'    THEN 'US-NY'
        WHEN s.store_name = 'Rowlett Bikes'    THEN 'US-TX'
    END AS state_code,
    -- товар
    p.product_id,
    p.product_name,
    p.model_year,
    b.brand_id,
    b.brand_name,
    c.category_id,
    c.category_name,
    -- показатели чека
    oi.quantity AS sold_units,
    oi.list_price,
    oi.discount,
    (oi.quantity * oi.list_price * (1 - oi.discount)) AS revenue,
    (oi.quantity * oi.list_price * oi.discount) AS total_discount_amount
FROM sales.orders o
JOIN sales.order_items oi ON o.order_id = oi.order_id
JOIN sales.products p ON oi.product_id = p.product_id
JOIN sales.brands b ON p.brand_id = b.brand_id
JOIN sales.categories c ON p.category_id = c.category_id
JOIN sales.stores s ON o.store_id = s.store_id
JOIN sales.staffs st ON o.staff_id = st.staff_id
WHERE o.order_status = 4
  AND o.order_date BETWEEN '{{ start_date }}' AND '{{ end_date }}'
  {% if selected_brands %}
  AND b.brand_name IN ('{{ selected_brands | join("', '") }}')
  {% endif %}
  {% if selected_categories %}
  AND c.category_name IN ('{{ selected_categories | join("', '") }}')
  {% endif %}
  {% if selected_stores %}
  AND s.store_name IN ('{{ selected_stores | join("', '") }}')
  {% endif %}
  {% if selected_staffs %}
  AND CONCAT(st.first_name, ' ', st.last_name) IN ('{{ selected_staffs | join("', '") }}')
  {% endif %}
  {% if selected_products %}
  AND p.product_name IN ('{{ selected_products | join("', '") }}')
  {% endif %}