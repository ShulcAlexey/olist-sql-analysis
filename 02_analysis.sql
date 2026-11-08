-- =====================================================================
-- 02_analysis.sql
-- Аналитика продаж, клиентов и доставки
-- Во всех запросах учитываются только доставленные заказы (delivered)
-- =====================================================================


-- 1. Выручка, количество заказов и средний чек по месяцам,
--    рост выручки к прошлому месяцу (LAG)
--    Период: январь 2017 — август 2018. Данные за 2016 год неполные
--    (единичные заказы, пропущенные месяцы) и искажают рост к прошлому месяцу.
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
           COUNT(DISTINCT o.order_id) AS orders_cnt,
           SUM(oi.price)              AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY 1
)
SELECT month,
       orders_cnt,
       ROUND(revenue, 2)              AS revenue,
       ROUND(revenue / orders_cnt, 2) AS avg_check,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
ORDER BY month;


-- 2. Топ-10 категорий по выручке и их доля в общей выручке
--    (RANK + оконная сумма по всем категориям)
WITH cat AS (
    SELECT COALESCE(ct.product_category_name_english,
                    p.product_category_name,
                    'unknown')          AS category,
           SUM(oi.price)                AS revenue,
           COUNT(DISTINCT oi.order_id)  AS orders_cnt
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN category_translation ct
           ON ct.product_category_name = p.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT RANK() OVER (ORDER BY revenue DESC)            AS rnk,
       category,
       ROUND(revenue, 2)                              AS revenue,
       orders_cnt,
       ROUND(100 * revenue / SUM(revenue) OVER (), 1) AS share_pct
FROM cat
ORDER BY rnk
LIMIT 10;


-- 3. Доля повторных покупателей
--    Считается по customer_unique_id: customer_id уникален для каждого заказа
WITH per_customer AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS orders_cnt
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT COUNT(*)                                AS customers,
       COUNT(*) FILTER (WHERE orders_cnt > 1)  AS repeat_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE orders_cnt > 1) / COUNT(*), 2) AS repeat_pct
FROM per_customer;


-- 4. Как задержка доставки влияет на оценку клиента
--    delay_days = фактическая дата доставки − обещанная дата доставки
--    (<= 0 — доставлено вовремя или раньше)
WITH d AS (
    SELECT order_id,
           order_delivered_customer_date::date
             - order_estimated_delivery_date::date AS delay_days
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
),
r AS (
    SELECT order_id, AVG(review_score) AS score
    FROM reviews
    GROUP BY order_id
)
SELECT CASE WHEN delay_days <= 0  THEN '1. Вовремя или раньше'
            WHEN delay_days <= 3  THEN '2. Опоздание 1-3 дня'
            WHEN delay_days <= 7  THEN '3. Опоздание 4-7 дней'
            WHEN delay_days <= 14 THEN '4. Опоздание 8-14 дней'
            ELSE                       '5. Опоздание > 14 дней'
       END                     AS delay_group,
       COUNT(*)                AS orders_cnt,
       ROUND(AVG(r.score), 2)  AS avg_score,
       ROUND(100.0 * COUNT(*) FILTER (WHERE r.score <= 2) / COUNT(*), 1) AS bad_reviews_pct
FROM d
JOIN r USING (order_id)
GROUP BY 1
ORDER BY 1;
