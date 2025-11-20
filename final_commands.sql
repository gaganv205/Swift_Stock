-- new_fixed.sql
-- Fully corrected SQL dump for database `ss` (DDL, DML, Triggers, Functions, Procedures, Views, Users & Grants)
-- NOTE: passwords are placeholders 'your_password_here' — replace with secure passwords before production.

DROP DATABASE IF EXISTS `ss`;
CREATE DATABASE `ss` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `ss`;

-- =====================
-- TABLES (DDL)
-- =====================

DROP TABLE IF EXISTS `RE_ASSIGNMENT`;
DROP TABLE IF EXISTS `PICKER_ASSIGNMENT`;
DROP TABLE IF EXISTS `ORDER_ITEM`;
DROP TABLE IF EXISTS `order_table`;
DROP TABLE IF EXISTS `Product_Storage`;
DROP TABLE IF EXISTS `PRODUCT`;
DROP TABLE IF EXISTS `RACK`;
DROP TABLE IF EXISTS `PICKER`;
DROP TABLE IF EXISTS `CUSTOMER`;

CREATE TABLE `CUSTOMER` (
  `Customer_ID` INT NOT NULL AUTO_INCREMENT,
  `Name` varchar(50) DEFAULT NULL,
  `Email_ID` varchar(100) DEFAULT NULL,
  `Phone_Number` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`Customer_ID`)
) ENGINE=InnoDB;

CREATE TABLE `PRODUCT` (
  `Product_ID` int NOT NULL,
  `Name` varchar(100) DEFAULT NULL,
  `Weight` decimal(8,3) DEFAULT NULL,
  `Height` decimal(8,3) DEFAULT NULL,
  `Width` decimal(8,3) DEFAULT NULL,
  `Breadth` decimal(8,3) DEFAULT NULL,
  `Popularity` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`Product_ID`)
) ENGINE=InnoDB;

CREATE TABLE `RACK` (
  `Rack_ID` int NOT NULL,
  `Aisle_Number` int DEFAULT NULL,
  `Level` int DEFAULT NULL,
  `Distance` decimal(6,2) DEFAULT NULL,
  PRIMARY KEY (`Rack_ID`)
) ENGINE=InnoDB;

CREATE TABLE `Product_Storage` (
  `Product_ID` int NOT NULL,
  `Rack_ID` int DEFAULT NULL,
  PRIMARY KEY (`Product_ID`),
  CONSTRAINT fk_ps_product FOREIGN KEY (Product_ID) REFERENCES PRODUCT(Product_ID) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ps_rack FOREIGN KEY (Rack_ID) REFERENCES RACK(Rack_ID) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `order_table` (
  `Order_ID` int NOT NULL AUTO_INCREMENT,
  `Customer_ID` int DEFAULT NULL,
  `Order_Date` date DEFAULT NULL,
  `Status` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`Order_ID`),
  CONSTRAINT fk_order_customer FOREIGN KEY (`Customer_ID`) REFERENCES `CUSTOMER`(`Customer_ID`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `ORDER_ITEM` (
  `Order_ID` int NOT NULL,
  `Product_ID` int NOT NULL,
  `Quantity` int DEFAULT NULL,
  PRIMARY KEY (`Order_ID`,`Product_ID`),
  CONSTRAINT fk_orderitem_order FOREIGN KEY (Order_ID) REFERENCES order_table(Order_ID) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_orderitem_product FOREIGN KEY (Product_ID) REFERENCES PRODUCT(Product_ID) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `PICKER` (
  `Picker_ID` int NOT NULL,
  `Name` varchar(50) DEFAULT NULL,
  `Shift` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`Picker_ID`)
) ENGINE=InnoDB;

CREATE TABLE `PICKER_ASSIGNMENT` (
  `Picker_ID` int NOT NULL,
  `Rack_ID` int NOT NULL,
  `Order_ID` int NOT NULL,
  PRIMARY KEY (`Picker_ID`,`Rack_ID`,`Order_ID`),
  CONSTRAINT fk_pa_order FOREIGN KEY (Order_ID) REFERENCES order_table(Order_ID) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pa_rack FOREIGN KEY (Rack_ID) REFERENCES RACK(Rack_ID) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pa_picker FOREIGN KEY (Picker_ID) REFERENCES PICKER(Picker_ID) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `RE_ASSIGNMENT` (
  `Reassign_ID` int NOT NULL AUTO_INCREMENT,
  `Product_ID` int DEFAULT NULL,
  `From_Rack_ID` int DEFAULT NULL,
  `To_Rack_ID` int DEFAULT NULL,
  `Reason` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`Reassign_ID`),
  CONSTRAINT fk_re_product FOREIGN KEY (Product_ID) REFERENCES PRODUCT(Product_ID) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_re_from_rack FOREIGN KEY (From_Rack_ID) REFERENCES RACK(Rack_ID) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_re_to_rack FOREIGN KEY (To_Rack_ID) REFERENCES RACK(Rack_ID) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================
-- INSERTS (DML) - in FK-safe order: parents first
-- =====================

-- Customers
INSERT INTO `CUSTOMER` (Customer_ID, Name, Email_ID, Phone_Number) VALUES
(101,'Alice','alice@example.com','9876543210'),
(102,'Bob','bob@example.com','8765432109'),
(103,'Charlie','charlie@example.com','7654321098'),
(104,'Diana','diana@example.com','6543210987'),
(105,'Ethan','ethan@example.com','5432109876');

-- Products
INSERT INTO `PRODUCT` (Product_ID, Name, Weight, Height, Width, Breadth, Popularity) VALUES
(1,'Wireless Mouse',0.20,4.50,6.00,3.00,16),
(2,'Mechanical Keyboard',0.85,5.00,45.00,15.00,14),
(3,'USB-C Cable',0.05,1.00,10.00,2.00,6),
(4,'Laptop Stand',1.20,15.00,25.00,5.00,27),
(5,'Noise Cancelling Headphones',0.30,18.00,20.00,10.00,4),
(6,'Webcam',0.10,5.00,8.00,5.00,0),
(7,'Portable SSD',0.12,7.00,10.00,3.00,2),
(8,'Smartphone Holder',0.09,10.00,8.00,5.00,2),
(9,'Bluetooth Speaker',0.50,12.00,10.00,10.00,6),
(10,'Desk Lamp',1.00,25.00,15.00,10.00,1),
(11,'Phone Cases',NULL,NULL,NULL,NULL,0);

-- Racks
INSERT INTO `RACK` (Rack_ID, Aisle_Number, Level, Distance) VALUES
(201,1,1,5.00),(202,1,2,7.50),(203,2,1,9.00),(204,2,2,12.00),(205,3,1,14.50),(206,3,2,18.00),(207,4,1,21.00),(208,4,2,25.00),(209,0,1,3.00);

-- Product_Storage (after products & racks exist)
INSERT INTO `Product_Storage` (Product_ID, Rack_ID) VALUES
(7,201),(5,202),(8,202),(6,204),(9,204),(1,205),(2,206),(10,206),(3,207),(4,209),(11,209);

-- Orders (order_table)
INSERT INTO `order_table` (Order_ID, Customer_ID, Order_Date, Status) VALUES
(401,101,'2025-10-15',NULL),(402,102,'2025-10-18',NULL),(403,103,'2025-10-21',NULL),(404,104,'2025-10-25',NULL),(405,105,'2025-10-30',NULL),(406,101,'2025-11-01',NULL),(5001,101,'2025-11-07',NULL),(6001,101,'2025-11-08',NULL),(6002,101,'2025-11-08',NULL);

-- Order items (after order_table & product exist)
INSERT INTO `ORDER_ITEM` (Order_ID, Product_ID, Quantity) VALUES
(401,1,2),(401,3,1),(401,5,3),(402,2,1),(402,4,1),(402,5,1),(403,1,4),(403,9,2),(404,2,3),(404,3,5),(404,10,1),(405,7,2),(405,8,1),(406,1,5),(406,2,2),(406,4,1),(406,9,4),(5001,1,5),(5001,2,8),(6001,1,3),(6001,2,5),(6001,3,2),(6001,4,25),(6002,8,1);

-- Note: product_id 1001 in ORDER_ITEM (6001,1001,2) does NOT exist in PRODUCT. Keep as-is if intentional; if not, remove or create PRODUCT 1001.

-- Pickers
INSERT INTO `PICKER` (Picker_ID, Name, Shift) VALUES
(301,'Rahul','Morning'),(302,'Sneha','Evening'),(303,'Vikram','Night');

-- Picker assignments (after orders & racks & pickers exist)
INSERT INTO `PICKER_ASSIGNMENT` (Picker_ID, Rack_ID, Order_ID) VALUES
(301,201,401),(301,202,402),(303,202,6002),(302,203,403),(302,204,404),(302,205,6001),(303,205,405),(301,206,6001),(303,206,406),(301,207,5001),(302,207,6001),(303,209,6001);

-- Reassignments
INSERT INTO `RE_ASSIGNMENT` (Reassign_ID, Product_ID, From_Rack_ID, To_Rack_ID, Reason) VALUES
(501,5,203,202,'Optimization - closer rack'),(502,4,208,209,'Auto Reassignment - High Popularity');

-- =====================
-- ROUTINES (Functions, Procedures) & TRIGGERS
-- Use proper DELIMITER to avoid client parsing issues
-- =====================

DELIMITER $$

-- Function: get_product_popularity
DROP FUNCTION IF EXISTS get_product_popularity $$
CREATE FUNCTION get_product_popularity(p_product_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE v_pop INT DEFAULT 0;
  SELECT IFNULL(Popularity, 0) INTO v_pop FROM PRODUCT WHERE Product_ID = p_product_id;
  RETURN v_pop;
END $$

-- Procedure: reassign_product_safely
DROP PROCEDURE IF EXISTS reassign_product_safely $$
CREATE PROCEDURE reassign_product_safely(IN p_product_id INT)
BEGIN
    DECLARE nearest_rack INT DEFAULT NULL;
    DECLARE current_rack INT DEFAULT NULL;

    SELECT Rack_ID INTO current_rack FROM Product_Storage WHERE Product_ID = p_product_id LIMIT 1;

    SELECT Rack_ID INTO nearest_rack
    FROM RACK
    WHERE Distance < (SELECT IFNULL(Distance, 999999) FROM RACK WHERE Rack_ID = current_rack)
    ORDER BY Distance ASC
    LIMIT 1;

    IF nearest_rack IS NOT NULL AND current_rack IS NOT NULL AND nearest_rack <> current_rack THEN
        INSERT INTO RE_ASSIGNMENT(Product_ID, From_Rack_ID, To_Rack_ID, Reason)
        VALUES (p_product_id, current_rack, nearest_rack, 'Auto Reassignment - High Popularity');
    END IF;
END $$

-- Procedure: create_order_with_items (handles JSON items array)
DROP PROCEDURE IF EXISTS create_order_with_items $$
CREATE PROCEDURE create_order_with_items(
  IN p_customer_id INT,
  IN p_customer_name VARCHAR(50),
  IN p_customer_email VARCHAR(100),
  IN p_customer_phone VARCHAR(15),
  IN p_order_id INT,
  IN p_order_date DATE,
  IN p_items JSON
)
BEGIN
  DECLARE v_exists INT DEFAULT 0;
  DECLARE v_i INT DEFAULT 0;
  DECLARE v_n INT;
  DECLARE v_pid INT;
  DECLARE v_qty INT;

  SELECT COUNT(*) INTO v_exists FROM CUSTOMER WHERE Customer_ID = p_customer_id OR Email_ID = p_customer_email;

  IF v_exists = 0 THEN
    INSERT INTO CUSTOMER (Customer_ID, Name, Email_ID, Phone_Number)
    VALUES (p_customer_id, p_customer_name, p_customer_email, p_customer_phone);
  END IF;

  INSERT INTO order_table (Order_ID, Customer_ID, Order_Date) VALUES (p_order_id, p_customer_id, p_order_date);

  SET v_n = JSON_LENGTH(p_items);
  WHILE v_i < v_n DO
    SET v_pid = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].product_id'))) AS UNSIGNED);
    SET v_qty = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].quantity'))) AS UNSIGNED);
    INSERT INTO ORDER_ITEM (Order_ID, Product_ID, Quantity) VALUES (p_order_id, v_pid, v_qty);
    SET v_i = v_i + 1;
  END WHILE;
END $$

-- Procedure: view_most_popular_products
DROP PROCEDURE IF EXISTS view_most_popular_products $$
CREATE PROCEDURE view_most_popular_products(IN p_top_n INT)
BEGIN
  SELECT p.Product_ID, p.Name, p.Popularity, ps.Rack_ID, r.Distance
  FROM PRODUCT p
  LEFT JOIN Product_Storage ps ON p.Product_ID = ps.Product_ID
  LEFT JOIN RACK r ON ps.Rack_ID = r.Rack_ID
  ORDER BY p.Popularity DESC
  LIMIT p_top_n;
END $$

-- Trigger: after insert on ORDER_ITEM
DROP TRIGGER IF EXISTS trg_after_order_item_insert $$
CREATE TRIGGER trg_after_order_item_insert
AFTER INSERT ON ORDER_ITEM
FOR EACH ROW
BEGIN
    DECLARE v_rack_id INT;
    DECLARE v_picker_id INT;
    DECLARE v_popularity INT;

    UPDATE PRODUCT SET Popularity = IFNULL(Popularity,0) + IFNULL(NEW.Quantity,0) WHERE Product_ID = NEW.Product_ID;

    SELECT Popularity INTO v_popularity FROM PRODUCT WHERE Product_ID = NEW.Product_ID;

    IF v_popularity > 20 THEN
        CALL reassign_product_safely(NEW.Product_ID);
    END IF;

    SELECT Rack_ID INTO v_rack_id FROM Product_Storage WHERE Product_ID = NEW.Product_ID LIMIT 1;

    SELECT p.Picker_ID INTO v_picker_id
    FROM PICKER p
    LEFT JOIN PICKER_ASSIGNMENT pa ON p.Picker_ID = pa.Picker_ID
    GROUP BY p.Picker_ID
    ORDER BY COUNT(pa.Order_ID) ASC
    LIMIT 1;

    IF v_picker_id IS NOT NULL AND v_rack_id IS NOT NULL THEN
      INSERT INTO PICKER_ASSIGNMENT (Picker_ID, Rack_ID, Order_ID) VALUES (v_picker_id, v_rack_id, NEW.Order_ID);
    END IF;
END $$

-- Trigger: after insert on PRODUCT (auto-assign nearest rack)
DROP TRIGGER IF EXISTS trg_after_product_insert $$
CREATE TRIGGER trg_after_product_insert
AFTER INSERT ON PRODUCT
FOR EACH ROW
BEGIN
  DECLARE v_rack_id INT;
  SELECT Rack_ID INTO v_rack_id FROM RACK ORDER BY Distance ASC LIMIT 1;
  IF v_rack_id IS NOT NULL THEN
    INSERT INTO Product_Storage (Product_ID, Rack_ID) VALUES (NEW.Product_ID, v_rack_id);
  END IF;
END $$

-- Trigger: after insert on RE_ASSIGNMENT
DROP TRIGGER IF EXISTS trg_after_reassignment_insert $$
CREATE TRIGGER trg_after_reassignment_insert
AFTER INSERT ON RE_ASSIGNMENT
FOR EACH ROW
BEGIN
  UPDATE Product_Storage SET Rack_ID = NEW.To_Rack_ID WHERE Product_ID = NEW.Product_ID;
  IF ROW_COUNT() = 0 THEN
    INSERT INTO Product_Storage (Product_ID, Rack_ID) VALUES (NEW.Product_ID, NEW.To_Rack_ID);
  END IF;
END $$

-- Trigger: after insert on PRODUCT (auto-assign nearest rack)
CREATE TRIGGER `trg_after_product_insert`
AFTER INSERT ON `PRODUCT`
FOR EACH ROW
BEGIN
  DECLARE v_rack_id INT;
  SELECT Rack_ID INTO v_rack_id FROM RACK ORDER BY Distance ASC LIMIT 1;
  IF v_rack_id IS NOT NULL THEN
    INSERT INTO Product_Storage (Product_ID, Rack_ID) VALUES (NEW.Product_ID, v_rack_id);
  END IF;
END$$

-- Trigger: after insert on RE_ASSIGNMENT
CREATE TRIGGER `trg_after_reassignment_insert`
AFTER INSERT ON `RE_ASSIGNMENT`
FOR EACH ROW
BEGIN
  UPDATE Product_Storage SET Rack_ID = NEW.To_Rack_ID WHERE Product_ID = NEW.Product_ID;
  IF ROW_COUNT() = 0 THEN
    INSERT INTO Product_Storage (Product_ID, Rack_ID) VALUES (NEW.Product_ID, NEW.To_Rack_ID);
  END IF;
END $$

DELIMITER ;

-- =====================
-- VIEWS
-- =====================

CREATE OR REPLACE VIEW vw_picker_rack_products AS
SELECT pa.Picker_ID, p.Name AS Picker_Name, pa.Rack_ID,
       pr.Product_ID, prd.Name AS Product_Name, prd.Weight
FROM PICKER_ASSIGNMENT pa
LEFT JOIN PICKER p ON pa.Picker_ID = p.Picker_ID
LEFT JOIN Product_Storage pr ON pa.Rack_ID = pr.Rack_ID
LEFT JOIN PRODUCT prd ON pr.Product_ID = prd.Product_ID;

CREATE OR REPLACE VIEW vw_admin_warehouse_snapshot AS
SELECT o.Order_ID, o.Order_Date, c.Customer_ID, c.Name AS Customer_Name,
       oi.Product_ID, prod.Name AS Product_Name, oi.Quantity,
       prod.Popularity, ps.Rack_ID, r.Aisle_Number, r.Distance
FROM order_table o
LEFT JOIN CUSTOMER c ON o.Customer_ID = c.Customer_ID
LEFT JOIN ORDER_ITEM oi ON o.Order_ID = oi.Order_ID
LEFT JOIN PRODUCT prod ON oi.Product_ID = prod.Product_ID
LEFT JOIN Product_Storage ps ON prod.Product_ID = ps.Product_ID
LEFT JOIN RACK r ON ps.Rack_ID = r.Rack_ID;

CREATE OR REPLACE VIEW vw_rack_product_status AS
SELECT r.Rack_ID, r.Aisle_Number, r.Distance,
       COUNT(ps.Product_ID) AS Total_Products
FROM RACK r
RIGHT JOIN Product_Storage ps ON r.Rack_ID = ps.Rack_ID
GROUP BY r.Rack_ID, r.Aisle_Number, r.Distance
HAVING COUNT(ps.Product_ID) >= 1;

CREATE OR REPLACE VIEW vw_product_storage_comparison AS
SELECT r.Rack_ID, r.Distance, ps.Product_ID
FROM RACK r
LEFT JOIN Product_Storage ps ON r.Rack_ID = ps.Rack_ID
UNION
SELECT r.Rack_ID, r.Distance, ps.Product_ID
FROM RACK r
RIGHT JOIN Product_Storage ps ON r.Rack_ID = ps.Rack_ID;

CREATE OR REPLACE VIEW vw_top_selling_products AS
SELECT oi.Product_ID, p.Name AS Product_Name, SUM(oi.Quantity) AS Total_Sold
FROM ORDER_ITEM oi
JOIN PRODUCT p ON oi.Product_ID = p.Product_ID
GROUP BY oi.Product_ID, p.Name
HAVING SUM(oi.Quantity) > (SELECT IFNULL(AVG(Quantity),0) FROM ORDER_ITEM)
ORDER BY Total_Sold DESC
LIMIT 5;


-- =====================
-- USERS & GRANTS (DROP IF EXISTS to avoid 1396)
-- =====================

-- Warehouse admin (broad privileges)
DROP USER IF EXISTS 'warehouse_admin'@'%';
CREATE USER 'warehouse_admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON ss.* TO 'warehouse_admin'@'%' WITH GRANT OPTION;
GRANT SELECT, INSERT, UPDATE, DELETE ON ss.customer TO 'warehouse_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON ss.picker TO 'warehouse_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON ss.product TO 'warehouse_admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON ss.rack TO 'warehouse_admin'@'%';
GRANT SELECT ON ss.order_table TO 'warehouse_admin'@'%';
GRANT SELECT ON ss.picker_assignment TO 'warehouse_admin'@'%';
GRANT SELECT ON ss.product_storage TO 'warehouse_admin'@'%';
GRANT SELECT ON ss.re_assignment TO 'warehouse_admin'@'%';
GRANT SELECT ON ss.vw_admin_warehouse_snapshot TO 'warehouse_admin'@'%';
GRANT EXECUTE ON FUNCTION ss.get_product_popularity TO 'warehouse_admin'@'%';
GRANT EXECUTE ON PROCEDURE ss.reassign_product_safely TO 'warehouse_admin'@'%';
GRANT EXECUTE ON PROCEDURE ss.view_most_popular_products TO 'warehouse_admin'@'%';
GRANT EXECUTE ON PROCEDURE ss.create_order_with_items TO 'warehouse_admin'@'%';

GRANT SELECT ON ss.vw_picker_rack_products TO 'warehouse_admin'@'%';
GRANT SELECT ON ss.vw_rack_product_status TO 'warehouse_admin'@'%';
GRANT SELECT ON ss.vw_product_storage_comparison TO 'warehouse_admin'@'%';
GRANT SELECT ON ss.vw_top_selling_products TO 'warehouse_admin'@'%';

-- Picker user (limited read + exec where helpful)
DROP USER IF EXISTS 'picker_user'@'%';
CREATE USER 'picker_user'@'%' IDENTIFIED BY 'picker123';
GRANT SELECT ON ss.order_table TO 'picker_user'@'%';
GRANT SELECT ON ss.picker TO 'picker_user'@'%';
GRANT SELECT ON ss.picker_assignment TO 'picker_user'@'%';
GRANT SELECT ON ss.product TO 'picker_user'@'%';
GRANT SELECT ON ss.product_storage TO 'picker_user'@'%';
GRANT SELECT ON ss.rack TO 'picker_user'@'%';
GRANT SELECT ON ss.vw_picker_rack_products TO 'picker_user'@'%';
GRANT EXECUTE ON PROCEDURE ss.view_most_popular_products TO 'picker_user'@'%';
GRANT EXECUTE ON PROCEDURE ss.create_order_with_items TO 'picker_user'@'%';
GRANT EXECUTE ON FUNCTION ss.get_product_popularity TO 'picker_user'@'%';
GRANT SELECT ON ss.vw_top_selling_products TO 'picker_user'@'%';

-- Customer user (limited to inserting orders and reading products/customers)
DROP USER IF EXISTS 'customer_user'@'%';
CREATE USER 'customer_user'@'%' IDENTIFIED BY 'customer123';
GRANT SELECT ON ss.customer TO 'customer_user'@'%';
GRANT SELECT ON ss.product TO 'customer_user'@'%';
GRANT INSERT ON ss.order_table TO 'customer_user'@'%';
GRANT INSERT ON ss.order_item TO 'customer_user'@'%';
GRANT INSERT ON ss.customer TO 'customer_user'@'%';
GRANT EXECUTE ON PROCEDURE ss.create_order_with_items TO 'customer_user'@'%';
GRANT EXECUTE ON FUNCTION ss.get_product_popularity TO 'customer_user'@'%';

-- Flush privileges so changes apply immediately
FLUSH PRIVILEGES;

-- =====================
-- FINAL NOTES: sanity checks
-- =====================
-- If you want to verify triggers/procs/views created successfully:
-- SHOW TRIGGERS FROM ss;
-- SHOW PROCEDURE STATUS WHERE Db = 'ss';
-- SHOW FUNCTION STATUS WHERE Db = 'ss';
-- SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- Done. This file creates objects in FK-safe order and uses proper DELIMITER blocks for routines/triggers.
-- Replace 'your_password_here' with secure passwords before using in production.
