-- Section E — Advanced Concepts (CASE, ACID, Transactions) 

-- Q24. Write a query using CASE to classify products into price tiers: 
--   • 'Budget'    → unit_price < 1000 
--   • 'Mid-Range' → unit_price BETWEEN 1000 AND 3000 
--   • 'Premium'   → unit_price > 3000 
-- Display: product_name, unit_price, price_tier. 

SELECT product_name,unit_price,
    CASE 
        WHEN unit_price < 1000 THEN 'Budget'
        WHEN unit_price BETWEEN 1000 AND 3000 THEN 'Mid-Range'
        WHEN unit_price > 3000 THEN 'Premium'
    END AS price_tier
FROM shopease.products
ORDER BY unit_price;


-- Q25. Using a CASE statement inside an aggregate function, count how many orders are 'Delivered' vs 'Not Delivered' (all other statuses). Display the result in a single row. 
SELECT 
    COUNT(
		CASE
			WHEN status = 'Delivered'  THEN 1 
			END
        ) AS delivered,
    COUNT(
		CASE
			WHEN status <> 'Delivered' THEN 1 
            END
            ) AS not_delivered
FROM shopease.orders;


-- Q26. Explain each letter of ACID: 
--   • A – Atomicity 
--   • C – Consistency 
--   • I – Isolation 
--   • D – Durability 
-- Give a real-world example (e.g., bank transfer) showing why each property is important. 

	-- A – Atomicity (All or Nothing)
	-- A transaction must be completed entirely or not at all. There should be no partial execution.
	-- Example:
	-- Account A balance = ₹10,000
	-- Transfer ₹5,000 to Account B
	-- Steps:
	-- Deduct ₹5,000 from Account A
	-- Add ₹5,000 to Account B
	-- If the system crashes after Step 1 but before Step 2:
	-- A = ₹5,000
	-- B = unchanged
	-- With Atomicity, the entire transaction is rolled back:
    
    -- C – Consistency (Maintain Valid Data)
    -- A transaction must move the database from one valid state to another valid state while following all rules and constraints.
	-- 	Example:
	-- 	Before transfer:
	-- 	A = ₹10,000
	-- 	B = ₹15,000
	-- 	Total = ₹25,000
	-- 	After transferring ₹5,000:
	-- 	A = ₹5,000
	-- 	B = ₹20,000
	-- 	Total = ₹25,000
	-- 	The total money remains the same.
	-- 	Inconsistent state:
	-- 	A = ₹5,000
	-- 	B = ₹15,000
	-- 	Total = ₹20,000
	-- 	Money has disappeared.
    
    -- I – Isolation (Transactions Don't Interfere)
	-- Multiple transactions running simultaneously should not affect each other's execution.
	-- Example:
	-- Account Balance = ₹10,000
	-- Two transactions occur at the same time:
	-- T1: Withdraw ₹2,000
	-- T2: Deposit ₹3,000
	-- Without Isolation:
	-- T1 reads ₹10,000
	-- T2 reads ₹10,000
	-- T1 writes ₹8,000
	-- T2 writes ₹13,000
	-- Final Balance = ₹13,000 
	-- Correct Balance should be:
    -- ₹10,000 − ₹2,000 + ₹3,000 = ₹11,000
    
    -- D – Durability (Data Stays Saved)
    -- Once a transaction is committed, its changes are permanently stored, even if the system crashes.
	-- Example:
	-- Transfer ₹5,000 completed successfully.
	-- Before crash:
	-- A = ₹5,000
	-- B = ₹20,000
	-- System crashes immediately after transaction commits.
	-- After restart:
	-- A = ₹5,000
	-- B = ₹20,000
	-- The transaction remains saved.


-- Q27. Write a SQL transaction that does the following atomically: 
--   1. Insert a new order (order_id=1011, customer_id=102, today's date, 'Pending', 1598.00) 
--   2. Insert two order items for that order 
--   3. Update the stock_qty of the purchased products 
--   4. If any step fails, ROLLBACK the entire transaction. Otherwise, COMMIT. 
-- Write the complete BEGIN...COMMIT/ROLLBACK block. 

DELIMITER $$
CREATE PROCEDURE place_order_1011()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SELECT 'Transaction FAILED Rolled back all changes' AS result;
    END;
START TRANSACTION;
-- Step 1: Insert a new order (order_id=1011, customer_id=102, today's date, 'Pending', 1598.00) 
INSERT INTO shopease.orders VALUES 
(1011, 102, CURDATE(), 'Pending', 1598.00);

-- Step 2a: Insert order item 1 Bedsheet Set (product_id=206, qty=1)
INSERT INTO shopease.order_items VALUES 
(5016, 1011, 206, 1, 1299.00, 0);

-- Step 2b: Insert order item 2 Cushion Covers (product_id=208, qty=1)
INSERT INTO shopease.order_items VALUES 
(5017, 1011, 208, 1, 599.00, 0);

-- Step 3a: Deduct stock for Bedsheet Set(qty-1)
UPDATE shopease.products 
SET stock_qty = stock_qty - 1 
WHERE product_id = 206;

-- Step 3b: Deduct stock for Cushion Covers(qty-1)
UPDATE shopease.products 
SET stock_qty = stock_qty - 1 
WHERE product_id = 208;

COMMIT;
    SELECT 'Transaction SUCCESS All changes committed' AS result;

END$$
DELIMITER ;
CALL place_order_1011();