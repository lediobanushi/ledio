-- View 1: Customer Analytics
CREATE VIEW customer_analytics AS
SELECT 
    c.customer_id,
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) as total_orders,
    AVG(oi.price) as avg_order_value,
    SUM(oi.price + oi.freight_value) as total_spent,
    AVG(orr.review_score) as avg_review_score
FROM olist_customers c
LEFT JOIN olist_orders o ON c.customer_id = o.customer_id
LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
LEFT JOIN olist_order_reviews orr ON o.order_id = orr.order_id
GROUP BY c.customer_id, c.customer_city, c.customer_state;

-- View 2: Seller Performance
CREATE VIEW seller_performance AS
SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) as total_orders,
    SUM(oi.price) as total_revenue,
    AVG(oi.price) as avg_item_price,
    AVG(orr.review_score) as avg_customer_rating
FROM olist_sellers s
LEFT JOIN olist_order_items oi ON s.seller_id = oi.seller_id
LEFT JOIN olist_orders o ON oi.order_id = o.order_id
LEFT JOIN olist_order_reviews orr ON o.order_id = orr.order_id
GROUP BY s.seller_id, s.seller_city, s.seller_state;