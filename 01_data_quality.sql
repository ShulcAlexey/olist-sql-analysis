-- =====================================================================
-- 01_data_quality.sql
-- Проверка качества данных перед анализом
-- =====================================================================


-- 1. Количество строк в каждой таблице (контроль полноты загрузки)
SELECT 'customers' AS table_name, COUNT(*) AS rows_cnt FROM customers
UNION ALL SELECT 'orders',               COUNT(*) FROM orders
UNION ALL SELECT 'order_items',          COUNT(*) FROM order_items
UNION ALL SELECT 'payments',             COUNT(*) FROM payments
UNION ALL SELECT 'reviews',              COUNT(*) FROM reviews
UNION ALL SELECT 'products',             COUNT(*) FROM products
UNION ALL SELECT 'sellers',              COUNT(*) FROM sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;


-- 2. Категории товаров, которых нет в справочнике переводов
--    (причина, по которой не создаётся внешний ключ products -> category_translation)
SELECT p.product_category_name,
       COUNT(*) AS products_cnt
FROM products p
LEFT JOIN category_translation ct
       ON p.product_category_name = ct.product_category_name
WHERE ct.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name;


-- 3. Товары без категории
SELECT COUNT(*) AS products_without_category
FROM products
WHERE product_category_name IS NULL;


-- 4. Пропуски в датах по статусам заказа
SELECT order_status,
       COUNT(*) AS total,
       COUNT(*) FILTER (WHERE order_approved_at IS NULL)             AS no_approved_date,
       COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS no_delivery_date
FROM orders
GROUP BY order_status
ORDER BY total DESC;


-- 5. Аномалия: заказ в статусе «доставлен», но даты доставки нет
SELECT COUNT(*) AS delivered_without_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;


-- 6. Заказы без платежей
SELECT COUNT(*) AS orders_without_payment
FROM orders o
WHERE NOT EXISTS (
    SELECT 1 FROM payments p WHERE p.order_id = o.order_id
);


-- 7. Заказы, оплаченные несколькими платежами
SELECT COUNT(*) AS multi_payment_orders
FROM (
    SELECT order_id
    FROM payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t;


-- 8. Ловушка JOIN: при соединении order_items и payments
--    строки размножаются, и выручка завышается
SELECT (SELECT SUM(price) FROM order_items) AS correct_revenue,
       SUM(oi.price)                        AS naive_join_revenue
FROM order_items oi
JOIN payments p ON p.order_id = oi.order_id;


-- 9. Сверка: стоимость товаров + доставка против суммы платежей по заказу
WITH items AS (
    SELECT order_id, SUM(price + freight_value) AS items_total
    FROM order_items
    GROUP BY order_id
),
pay AS (
    SELECT order_id, SUM(payment_value) AS paid
    FROM payments
    GROUP BY order_id
)
SELECT COUNT(*) AS orders_compared,
       COUNT(*) FILTER (WHERE ABS(i.items_total - p.paid) > 1) AS mismatched_orders
FROM items i
JOIN pay p USING (order_id);


-- 10. Заказы с несколькими отзывами
SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (
    SELECT order_id
    FROM reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t;


-- 11. customer_id создаётся на каждый заказ, реальный клиент — customer_unique_id
SELECT COUNT(DISTINCT customer_id)        AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS real_customers
FROM customers;