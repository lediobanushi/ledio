-- Procedure 1: Get customer info
DELIMITER //
CREATE PROCEDURE GetCustomerInfo(IN customer_id_param VARCHAR(50))
BEGIN
    SELECT 
        c.customer_id,
        c.customer_city,
        c.customer_state,
        COUNT(DISTINCT o.order_id) as total_orders,
        SUM(oi.price) as total_spent
    FROM olist_customers c
    LEFT JOIN olist_orders o ON c.customer_id = o.customer_id
    LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE c.customer_id = customer_id_param
    GROUP BY c.customer_id, c.customer_city, c.customer_state;
END //
DELIMITER ;

-- Procedure 2: Get seller info
DELIMITER //
CREATE PROCEDURE GetSellerInfo(IN seller_id_param VARCHAR(50))
BEGIN
    SELECT 
        s.seller_id,
        s.seller_city,
        s.seller_state,
        COUNT(DISTINCT oi.order_id) as total_orders,
        SUM(oi.price) as total_revenue
    FROM olist_sellers s
    LEFT JOIN olist_order_items oi ON s.seller_id = oi.seller_id
    WHERE s.seller_id = seller_id_param
    GROUP BY s.seller_id, s.seller_city, s.seller_state;
END //
DELIMITER ;

-- Procedure 3: Get monthly sales
DELIMITER //
CREATE PROCEDURE GetMonthlySales(IN year_param INT, IN month_param INT)
BEGIN
    SELECT 
        c.customer_state,
        COUNT(DISTINCT o.order_id) as total_orders,
        SUM(oi.price) as total_revenue
    FROM olist_orders o
    JOIN olist_customers c ON o.customer_id = c.customer_id
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    WHERE YEAR(o.order_purchase_timestamp) = year_param 
    AND MONTH(o.order_purchase_timestamp) = month_param
    GROUP BY c.customer_state
    ORDER BY total_revenue DESC;
END //
DELIMITER ;
--
-- Call customer info
CALL GetCustomerInfo('customer_id_here');

-- Call seller info  
CALL GetSellerInfo('seller_id_here');

-- Call monthly sales
CALL GetMonthlySales(2018, 1);


