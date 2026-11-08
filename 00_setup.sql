CREATE TABLE customers (
    customer_id TEXT, customer_unique_id TEXT,
    customer_zip_code_prefix TEXT, customer_city TEXT, customer_state TEXT);

CREATE TABLE orders (
    order_id TEXT, customer_id TEXT, order_status TEXT,
    order_purchase_timestamp TIMESTAMP, order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP, order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP);

CREATE TABLE order_items (
    order_id TEXT, order_item_id INT, product_id TEXT, seller_id TEXT,
    shipping_limit_date TIMESTAMP, price NUMERIC, freight_value NUMERIC);

CREATE TABLE payments (
    order_id TEXT, payment_sequential INT, payment_type TEXT,
    payment_installments INT, payment_value NUMERIC);

CREATE TABLE reviews (
    review_id TEXT, order_id TEXT, review_score INT,
    review_comment_title TEXT, review_comment_message TEXT,
    review_creation_date TIMESTAMP, review_answer_timestamp TIMESTAMP);

CREATE TABLE products (
    product_id TEXT, product_category_name TEXT,
    product_name_lenght INT, product_description_lenght INT, product_photos_qty INT,
    product_weight_g INT, product_length_cm INT, product_height_cm INT, product_width_cm INT);

CREATE TABLE sellers (
    seller_id TEXT, seller_zip_code_prefix TEXT, seller_city TEXT, seller_state TEXT);

CREATE TABLE category_translation (
    product_category_name TEXT, product_category_name_english TEXT);

COPY customers   FROM 'C:/Users/Public/olist/olist_customers_dataset.csv'      WITH (FORMAT csv, HEADER true);
COPY orders      FROM 'C:/Users/Public/olist/olist_orders_dataset.csv'         WITH (FORMAT csv, HEADER true);
COPY order_items FROM 'C:/Users/Public/olist/olist_order_items_dataset.csv'    WITH (FORMAT csv, HEADER true);
COPY payments    FROM 'C:/Users/Public/olist/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true);
COPY reviews     FROM 'C:/Users/Public/olist/olist_order_reviews_dataset.csv'  WITH (FORMAT csv, HEADER true);
COPY products    FROM 'C:/Users/Public/olist/olist_products_dataset.csv'       WITH (FORMAT csv, HEADER true);
COPY sellers     FROM 'C:/Users/Public/olist/olist_sellers_dataset.csv'        WITH (FORMAT csv, HEADER true);
COPY category_translation FROM 'C:/Users/Public/olist/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true);

ALTER TABLE customers            ADD PRIMARY KEY (customer_id);
ALTER TABLE orders               ADD PRIMARY KEY (order_id);
ALTER TABLE products             ADD PRIMARY KEY (product_id);
ALTER TABLE sellers              ADD PRIMARY KEY (seller_id);
ALTER TABLE category_translation ADD PRIMARY KEY (product_category_name);
ALTER TABLE order_items          ADD PRIMARY KEY (order_id, order_item_id);
ALTER TABLE payments             ADD PRIMARY KEY (order_id, payment_sequential);
-- 4. Внешние ключи
ALTER TABLE orders      ADD FOREIGN KEY (customer_id) REFERENCES customers (customer_id);
ALTER TABLE order_items ADD FOREIGN KEY (order_id)    REFERENCES orders (order_id);
ALTER TABLE order_items ADD FOREIGN KEY (product_id)  REFERENCES products (product_id);
ALTER TABLE order_items ADD FOREIGN KEY (seller_id)   REFERENCES sellers (seller_id);
ALTER TABLE payments    ADD FOREIGN KEY (order_id)    REFERENCES orders (order_id);
ALTER TABLE reviews     ADD FOREIGN KEY (order_id)    REFERENCES orders (order_id);
 
-- Не создаётся: в products есть категории, которых нет в справочнике
-- category_translation (нарушение ссылочной целостности).
-- Подробности — 01_data_quality.sql, проверка 2.
-- ALTER TABLE products ADD FOREIGN KEY (product_category_name)
--     REFERENCES category_translation (product_category_name);