-- *Section A* — SQL Basics (SELECT, Constraints, Primary Keys) 

-- Q1. Write a query to display all columns and rows from the customer's table. 
SELECT * FROM shopease.customers;

-- Q2. Retrieve only the first_name, last_name, and city of all customers. 
SELECT first_name,last_name,city
FROM shopease.customers;

-- Q3. List all unique categories available in the products table. 
SELECT DISTINCT(category) 
FROM shopease.products;

-- Q4. Identify the Primary Key of each table in the schema. Explain why a Primary Key must be unique and NOT NULL. 
-- customers --> customer_id
-- order_items --> item_id
-- orders --> order_id
-- product --> product_id
-- A Primary Key must be unique because it uniquely identifies each record in a table. It must be NOT NULL because 
-- every record must have a valid identifier. Together, these constraints ensure data integrity and prevent duplicate or unidentified records.


-- Q5. What constraints are applied to the email column in the customers table? What would happen if you tried to insert a duplicate email? 
-- each email must be  UNIQUE NOT NULL 
INSERT INTO  shopease.customers
VALUES(109, 'Swadesh',  'singh', 'aarav.s@email.com',  'Mumbai',    'Maharashtra', '2024-01-15', TRUE);
-- Error Code: 1062. Duplicate entry 'aarav.s@email.com' for key 'customers.email'


-- Q6. Try inserting a product with unit_price = -50. What happens and which constraint prevents it? Write both the INSERT statement and explain the error.
INSERT INTO shopease.products
VALUES (109,'Type-C Cable','Electronics','Generic',-50.00,100);
-- Error Code: 3819. Check constraint 'products_chk_1' is violated.

-- this happend due to the constrant CHECK (unit_price > 0) it only allow the users to insert the value when unit_price > 0 
INSERT INTO shopease.products
VALUES (109,'Type-C Cable','Electronics','Generic',50.00,100);



-- *Section B* — Filtering & Optimization (WHERE, Indexes) 

-- Q7. Retrieve all orders with status = 'Delivered'. 
SELECT * 
FROM shopease.orders
WHERE status = 'Delivered';

-- Q8. Find all products in the 'Electronics' category with a unit_price greater than ₹2000. 
SELECT * 
FROM shopease.products
WHERE category = 'Electronics' AND unit_price > 2000;

-- Q9. List all customers who joined in the year 2024 and belong to the state 'Maharashtra'. 
SELECT * 
FROM shopease.customers
WHERE YEAR(join_date) = 2024 AND state = 'Maharashtra';


-- Q10. Find all orders placed between '2024-08-10' and '2024-08-25' (inclusive) that are NOT cancelled.
SELECT * 
FROM shopease.orders
WHERE order_date BETWEEN '2024-08-10' AND '2024-08-25'
AND status <> 'cancelled';


-- Q11. Explain what the index idx_orders_date does. How would it improve the performance of a query that filters orders by order_date? Write a sample query that would benefit from this index. 
-- An index works like the index of a book. Instead of scanning every row in the orders table to find matching dates, MySQL can use the index to quickly locate the required records.
-- Without the index, MySQL performs a full table scan, checking every row in the table. As the table grows larger, this becomes slower.
-- With idx_orders_date, MySQL can directly access the rows that match the specified date or date range, significantly reducing the amount of data scanned and improving query performance.
SELECT *
FROM shopease.orders
WHERE order_date = '2024-08-28';

SELECT *
FROM shopease.orders
WHERE order_date BETWEEN '2024-08-01' AND '2024-08-20';

-- Q12. If you run: SELECT * FROM customers WHERE YEAR(join_date) = 2024; — would the index on join_date be used? Explain why or why not, and rewrite the query to be index-friendly (SARGable).
SELECT * 
FROM shopease.customers 
WHERE YEAR(join_date) = 2024;

-- No, generally the index would not be used efficiently.

-- This is because the YEAR() function is applied to the indexed column join_date. When a function is applied to an indexed column, MySQL must calculate YEAR(join_date) for every row before comparing it with 2024. As a result, it cannot directly use the index to locate matching rows.
-- This type of query is non-SARGable (Search Argument Not Able), meaning the database optimizer cannot efficiently use the index.

-- Index-Friendly (SARGable) Query
SELECT *
FROM shopease.customers
WHERE join_date BETWEEN '2024-01-01' AND '2024-12-31';


-- *Section C* — Aggregation (GROUP BY, SUM, COUNT, AVG, MIN, MAX) 

-- Q13. Count the total number of orders in the orders table. 
SELECT COUNT(order_id)
FROM shopease.orders;

-- Q14. Find the total revenue (SUM of total_amount) from all 'Delivered' orders. 
SELECT SUM(total_amount) AS Total_Amount
FROM shopease.orders
WHERE status = "delivered";

-- Q15. Calculate the average unit_price of products in each category. 
SELECT category,
		AVG(unit_price) AS Avg_Unit_Price 
FROM shopease.products
GROUP BY category;

-- Q16. For each order status, find the count of orders and the total revenue. Sort the result by total revenue in descending order.
SELECT status,
	COUNT(order_id) AS Total_Order, 
	SUM(total_amount) AS Total_Amount
FROM  shopease.orders
GROUP BY status 
ORDER BY Total_Amount DESC;

-- Q17. Find the most expensive (MAX) and cheapest (MIN) product in each category. 
SELECT category,
	MAX(unit_price) AS Most_Expensive ,
    MIN(unit_price) AS Cheapest
FROM shopease.products
GROUP BY category;

-- Q18. List all product categories where the average unit_price is greater than ₹2000. (Hint: Use HAVING clause) 
SELECT
    category,
    AVG(unit_price) AS Avg_Price
FROM shopease.products
GROUP BY category
HAVING AVG(unit_price) > 2000;


-- *Section D* — Joins & Relationships 

-- Q19. Write an INNER JOIN query to display each order along with the customer's first_name and last_name. Show: order_id, order_date, first_name, last_name, total_amount. 
SELECT o.order_id,
    o.order_date,
    c.first_name,
    c.last_name,
    o.total_amount
FROM shopease.orders o
INNER JOIN shopease.customers c ON o.customer_id = c.customer_id;

-- Q20. Using a LEFT JOIN, list ALL customers and their orders (if any). Customers with no orders should still appear with NULL values for order columns. 
SELECT c.customer_id,
    c.first_name,
    c.last_name,
    o.order_id,
    o.order_date,
    o.total_amount
FROM shopease.customers c
LEFT JOIN shopease.orders o ON c.customer_id = o.customer_id;

-- Q21. Write a query using JOINs across three tables (orders → order_items → products) to show: order_id, product_name, quantity, unit_price, and discount_pct for each order item. 
SELECT o.order_id,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct
FROM shopease.orders o
INNER JOIN shopease.order_items oi ON o.order_id = oi.order_id
INNER JOIN shopease.products p    ON oi.product_id = p.product_id;

-- Q22. Explain the difference between LEFT JOIN and RIGHT JOIN with an example from this schema. When would you use a FULL OUTER JOIN? 
-- JOIN LEFT JOIN All rows from left table + matching rows from right. Non-matching right side NULL
SELECT c.first_name, o.order_id
FROM shopease.customers c
LEFT JOIN shopease.orders o ON c.customer_id = o.customer_id;
-- A customer with no orders appears with order_id = NULL

-- RIGHT JOIN All rows from right table + matching rows from left. Non-matching left side NULL
SELECT c.first_name, o.order_id
FROM shopease.customers c
RIGHT JOIN shopease.orders o ON c.customer_id = o.customer_id;
-- An order with no matching customer → appears with first_name = NULL

-- IN SQL WORKBANCH THERE IS NO CONCEPT OF FULL OUTER JOIN WE USE UNION TO PERFORM FULL OUTER JOIN
-- FULL OUTER JOIN All rows from both tables. NULLs on whichever side has no match
-- Use FULL OUTER JOIN when you need to find: Records that match in both tables, Records that exist only in the first table,Records that exist only in the second table.
-- FULL OUTER JOIN IN SQL WORKBENCH
SELECT c.customer_id,c.first_name,c.last_name,
    o.order_id,
    o.total_amount
FROM shopease.customers c
LEFT JOIN shopease.orders o ON c.customer_id = o.customer_id
UNION
SELECT c.customer_id,c.first_name,c.last_name,
    o.order_id,
    o.total_amount
FROM shopease.customers c
RIGHT JOIN shopease.orders o ON c.customer_id = o.customer_id;

-- Q23. Identify all Foreign Key relationships in the schema. Explain what would happen if you tried to insert an order with customer_id = 999 (which doesn't exist in customers).
--   customers.customer_id  <--FK--  orders.customer_id 
--   orders.order_id        <--FK--  order_items.order_id 
--   products.product_id    <--FK--  order_items.product_id 
INSERT INTO shopease.orders VALUES (1011, 999, '2024-09-01', 'Pending', 500.00);
-- Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails (`shopease`.`orders`, CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`))
-- This query will never be executed, or we can say that this row will not be added to the Orders table.



-- *Section E* — Advanced Concepts (CASE, ACID, Transactions) 

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