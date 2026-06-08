-- Section D — Joins & Relationships 


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
-- JOIN LEFT JOIN All rows from left table + matching rows from right. Non-matching right side → NULL
SELECT c.first_name, o.order_id
FROM shopease.customers c
LEFT JOIN shopease.orders o ON c.customer_id = o.customer_id;
-- A customer with no orders appears with order_id = NULL

-- RIGHT JOIN All rows from right table + matching rows from left. Non-matching left side → NULL
SELECT c.first_name, o.order_id
FROM shopease.customers c
RIGHT JOIN shopease.orders o ON c.customer_id = o.customer_id;
-- An order with no matching customer → appears with first_name = NULL

-- IN SQL WORKBANCH THERE IS NO CONCEPT OF FULL OUTER JOIN WE USE UNION 
-- FULL OUTER JOIN All rows from both tables. NULLs on whichever side has no match
-- Use FULL OUTER JOIN when you need to find: Records that match in both tables, Records that exist only in the first table,Records that exist only in the second table.
-- FULL OUTER JOIN simulation in MySQL
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
