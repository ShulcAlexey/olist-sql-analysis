-- =====================================================================
-- 03_mart.sql
-- Витрина данных для дашборда
-- Гранулярность: одна строка = одна позиция доставленного заказа
-- =====================================================================

CREATE OR REPLACE VIEW mart_order_items AS
SELECT o.order_id,
       oi.order_item_id,
       DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
       c.customer_state,
       COALESCE(ct.product_category_name_english,
                p.product_category_name,
                'unknown')                                    AS category,
       oi.price,
       oi.freight_value,
       o.order_delivered_customer_date::date
         - o.order_estimated_delivery_date::date              AS delay_days,
       r.review_score
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN customers c    ON c.customer_id = o.customer_id
JOIN products p     ON p.product_id = oi.product_id
LEFT JOIN category_translation ct
       ON ct.product_category_name = p.product_category_name
-- Отзывы предварительно агрегированы до уровня заказа,
-- чтобы несколько отзывов не размножали строки витрины
LEFT JOIN (
    SELECT order_id, ROUND(AVG(review_score), 1) AS review_score
    FROM reviews
    GROUP BY order_id
) r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered';


-- Проверка витрины: число строк должно совпадать с числом позиций
-- доставленных заказов (строки не размножились при JOIN)
SELECT (SELECT COUNT(*) FROM mart_order_items) AS mart_rows,
       (SELECT COUNT(*)
        FROM order_items oi
        JOIN orders o ON o.order_id = oi.order_id
        WHERE o.order_status = 'delivered')    AS expected_rows;


-- Пример данных
SELECT * FROM mart_order_items LIMIT 20;