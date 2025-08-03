-- olist_products: product_category_name → product_category_name_translation
ALTER TABLE olist_products
  ADD CONSTRAINT fk_products_category
  FOREIGN KEY (product_category_name)
  REFERENCES product_category_name_translation(product_category_name);

-- olist_orders: customer_id → olist_customers
ALTER TABLE olist_orders
  ADD CONSTRAINT fk_orders_customer
  FOREIGN KEY (customer_id)
  REFERENCES olist_customers(customer_id);

-- olist_order_items: order_id → olist_orders
ALTER TABLE olist_order_items
  ADD CONSTRAINT fk_order_items_order
  FOREIGN KEY (order_id)
  REFERENCES olist_orders(order_id);

-- olist_order_items: product_id → olist_products
ALTER TABLE olist_order_items
  ADD CONSTRAINT fk_order_items_product
  FOREIGN KEY (product_id)
  REFERENCES olist_products(product_id);

-- olist_order_items: seller_id → olist_sellers
ALTER TABLE olist_order_items
  ADD CONSTRAINT fk_order_items_seller
  FOREIGN KEY (seller_id)
  REFERENCES olist_sellers(seller_id);

-- olist_order_payments: order_id → olist_orders
ALTER TABLE olist_order_payments
  ADD CONSTRAINT fk_order_payments_order
  FOREIGN KEY (order_id)
  REFERENCES olist_orders(order_id);

-- olist_order_reviews: order_id → olist_orders
ALTER TABLE olist_order_reviews
  ADD CONSTRAINT fk_order_reviews_order
  FOREIGN KEY (order_id)
  REFERENCES olist_orders(order_id);
  
  
  ---
  
  SET SQL_SAFE_UPDATES = 0;
  -- Option A: Update orphaned product categories to 'unknown'
UPDATE olist_products 
SET product_category_name = 'unknown' 
WHERE product_category_name NOT IN (SELECT product_category_name FROM product_category_name_translation);

-- Option B: Add missing categories to translation table
INSERT INTO product_category_name_translation (product_category_name, product_category_name_english)
SELECT DISTINCT product_category_name, product_category_name 
FROM olist_products 
WHERE product_category_name NOT IN (SELECT product_category_name FROM product_category_name_translation);

-- Option C: Remove orphaned order items (if they're not needed)
DELETE FROM olist_order_items 
WHERE product_id NOT IN (SELECT product_id FROM olist_products);


-- 
-- After fixing data, try adding the constraints again
ALTER TABLE olist_products
  ADD CONSTRAINT fk_products_category
  FOREIGN KEY (product_category_name)
  REFERENCES product_category_name_translation(product_category_name);

ALTER TABLE olist_order_items
  ADD CONSTRAINT fk_order_items_product
  FOREIGN KEY (product_id)
  REFERENCES olist_products(product_id);
  ----
  