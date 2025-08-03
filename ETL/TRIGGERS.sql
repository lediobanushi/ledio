-- Trigger 1: Update customer order count when new order is inserted
DELIMITER //
CREATE TRIGGER after_order_insert
AFTER INSERT ON olist_orders
FOR EACH ROW
BEGIN
    UPDATE olist_customers 
    SET total_orders = (
        SELECT COUNT(*) 
        FROM olist_orders 
        WHERE customer_id = NEW.customer_id
    )
    WHERE customer_id = NEW.customer_id;
END//
DELIMITER ;

-- Trigger 2: Log payment changes
CREATE TABLE payment_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(50),
    old_payment_value FLOAT,
    new_payment_value FLOAT,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER after_payment_update
AFTER UPDATE ON olist_order_payments
FOR EACH ROW
BEGIN
    IF OLD.payment_value != NEW.payment_value THEN
        INSERT INTO payment_log (order_id, old_payment_value, new_payment_value)
        VALUES (NEW.order_id, OLD.payment_value, NEW.payment_value);
    END IF;
END//
DELIMITER ;

-- Trigger 3: Validate review score
DELIMITER //
CREATE TRIGGER before_review_insert
BEFORE INSERT ON olist_order_reviews
FOR EACH ROW
BEGIN
    IF NEW.review_score < 1 OR NEW.review_score > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Review score must be between 1 and 5';
    END IF;
END//
DELIMITER ;