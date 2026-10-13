{% set selected_stores = filter_values('store_name') %}
{% set selected_brands = filter_values('brand_name') %}
{% set selected_categories = filter_values('category_name') %}
SELECT 
    s.store_id,
    s.store_name,
    s.city AS store_city,
    s.state AS store_state,
    p.product_id,
    p.product_name,
    p.model_year,
    p.list_price,
    b.brand_id,
    b.brand_name,
    c.category_id,
    c.category_name,
    COALESCE(stk.quantity, 0) AS current_stock,
    COALESCE(stk.quantity, 0) * p.list_price AS stock_value,
    CASE 
        WHEN stk.quantity IS NULL OR stk.quantity = 0 THEN 'Отсутствует'
        WHEN stk.quantity <= 2 THEN 'Критически низкий'
        WHEN stk.quantity <= 5 THEN 'Низкий'
        WHEN stk.quantity <= 15 THEN 'Средний'
        ELSE 'Достаточный'
    END AS stock_status
FROM sales.stocks stk
JOIN sales.stores s ON stk.store_id = s.store_id
JOIN sales.products p ON stk.product_id = p.product_id
JOIN sales.brands b ON p.brand_id = b.brand_id
JOIN sales.categories c ON p.category_id = c.category_id
WHERE 1 = 1
  {% if selected_stores %}
  AND s.store_name IN ('{{ selected_stores | join("', '") }}')
  {% endif %}
  {% if selected_brands %}
  AND b.brand_name IN ('{{ selected_brands | join("', '") }}')
  {% endif %}
  {% if selected_categories %}
  AND c.category_name IN ('{{ selected_categories | join("', '") }}')
  {% endif %}