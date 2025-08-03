-- Report 1: Customer Lifetime Value Analysis
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.customer_state,
        c.customer_city,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(oi.price + oi.freight_value) as total_spent,
        AVG(oi.price + oi.freight_value) as avg_order_value,
        DATEDIFF(MAX(o.order_purchase_timestamp), MIN(o.order_purchase_timestamp)) as customer_lifespan_days,
        AVG(orr.review_score) as avg_rating,
        COUNT(DISTINCT oi.product_id) as unique_products
    FROM olist_customers c
    LEFT JOIN olist_orders o ON c.customer_id = o.customer_id
    LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
    LEFT JOIN olist_order_reviews orr ON o.order_id = orr.order_id
    GROUP BY c.customer_id, c.customer_state, c.customer_city
),
customer_segments AS (
    SELECT 
        *,
        CASE 
            WHEN total_spent >= 1000 AND order_count >= 5 THEN 'VIP'
            WHEN total_spent >= 500 AND order_count >= 3 THEN 'Regular'
            WHEN total_spent >= 100 THEN 'Occasional'
            ELSE 'New'
        END as customer_segment,
        total_spent / NULLIF(customer_lifespan_days, 0) * 365 as annual_value
    FROM customer_metrics
)
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_total_spent,
    AVG(annual_value) as avg_annual_value,
    AVG(order_count) as avg_orders,
    AVG(avg_rating) as avg_rating,
    customer_state,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY customer_segment) as segment_percentage
FROM customer_segments
GROUP BY customer_segment, customer_state
ORDER BY customer_segment, avg_total_spent DESC;


-- Report 2: Product Performance & Inventory Analysis (Common Table Expression syntax)
WITH product_performance AS (
    SELECT 
        p.product_id,
        p.product_category_name,
        pct.product_category_name_english,
        p.product_weight_g,
        p.product_length_cm * p.product_height_cm * p.product_width_cm as volume_cm3,
        COUNT(oi.order_id) as times_sold,
        SUM(oi.price) as total_revenue,
        AVG(oi.price) as avg_price,
        SUM(oi.freight_value) as total_freight,
        AVG(orr.review_score) as avg_rating,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        COUNT(DISTINCT oi.seller_id) as unique_sellers
    FROM olist_products p
    LEFT JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
    LEFT JOIN olist_order_items oi ON p.product_id = oi.product_id
    LEFT JOIN olist_orders o ON oi.order_id = o.order_id
    LEFT JOIN olist_order_reviews orr ON o.order_id = orr.order_id
    GROUP BY p.product_id, p.product_category_name, pct.product_category_name_english, 
             p.product_weight_g, p.product_length_cm, p.product_height_cm, p.product_width_cm
),
category_analysis AS (
    SELECT 
        product_category_name,
        product_category_name_english,
        COUNT(*) as total_products,
        SUM(times_sold) as total_sales,
        SUM(total_revenue) as category_revenue,
        AVG(avg_price) as avg_category_price,
        AVG(avg_rating) as avg_category_rating,
        SUM(total_revenue) / SUM(times_sold) as revenue_per_sale,
        AVG(product_weight_g) as avg_weight,
        AVG(volume_cm3) as avg_volume
    FROM product_performance
    GROUP BY product_category_name, product_category_name_english
)
SELECT 
    ca.*,
    RANK() OVER (ORDER BY ca.category_revenue DESC) as revenue_rank,
    RANK() OVER (ORDER BY ca.total_sales DESC) as sales_rank,
    RANK() OVER (ORDER BY ca.avg_category_rating DESC) as rating_rank,
    CASE 
        WHEN ca.avg_category_price > 200 THEN 'Premium'
        WHEN ca.avg_category_price > 100 THEN 'Mid-Range'
        ELSE 'Budget'
    END as price_category
FROM category_analysis ca
ORDER BY ca.category_revenue DESC;

-- Report 3: Geographic Sales & Delivery Performance
WITH geographic_sales AS (
    SELECT 
        c.customer_state,
        c.customer_city,
        s.seller_state,
        s.seller_city,
        COUNT(DISTINCT o.order_id) as total_orders,
        SUM(oi.price + oi.freight_value) as total_revenue,
        AVG(oi.price) as avg_item_price,
        AVG(oi.freight_value) as avg_freight,
        AVG(orr.review_score) as avg_rating,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        COUNT(DISTINCT oi.seller_id) as unique_sellers,
        AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)) as avg_delivery_days,
        AVG(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)) as delivery_vs_estimated
    FROM olist_orders o
    JOIN olist_customers c ON o.customer_id = c.customer_id
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    JOIN olist_sellers s ON oi.seller_id = s.seller_id
    LEFT JOIN olist_order_reviews orr ON o.order_id = orr.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state, c.customer_city, s.seller_state, s.seller_city
),
state_performance AS (
    SELECT 
        customer_state,
        SUM(total_orders) as state_orders,
        SUM(total_revenue) as state_revenue,
        AVG(avg_rating) as state_avg_rating,
        AVG(avg_delivery_days) as state_avg_delivery,
        AVG(delivery_vs_estimated) as state_delivery_accuracy,
        COUNT(DISTINCT customer_city) as cities_with_orders,
        SUM(unique_customers) as total_customers,
        SUM(unique_sellers) as total_sellers
    FROM geographic_sales
    GROUP BY customer_state
)
SELECT 
    sp.*,
    RANK() OVER (ORDER BY sp.state_revenue DESC) as revenue_rank,
    RANK() OVER (ORDER BY sp.state_avg_rating DESC) as rating_rank,
    RANK() OVER (ORDER BY sp.state_avg_delivery ASC) as delivery_rank,
    CASE 
        WHEN sp.state_avg_delivery <= 7 THEN 'Fast'
        WHEN sp.state_avg_delivery <= 14 THEN 'Normal'
        ELSE 'Slow'
    END as delivery_category,
    CASE 
        WHEN sp.state_avg_rating >= 4.5 THEN 'Excellent'
        WHEN sp.state_avg_rating >= 4.0 THEN 'Good'
        WHEN sp.state_avg_rating >= 3.5 THEN 'Average'
        ELSE 'Poor'
    END as rating_category
FROM state_performance sp
ORDER BY sp.state_revenue DESC;