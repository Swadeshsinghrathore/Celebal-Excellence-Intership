-- Section B — Filtering & Optimization (WHERE, Indexes) 

-- Q7. Retrieve all orders with status = 'Delivered'. 
SELECT * 
FROM shopease.orders
WHERE status = 'Delivered';

-- Q8. Find all products in the 'Electronics' category with a unit_price greater than ₹2000. 
SELECT * 
FROM shopease.products
WHERE category = 'Electronics' AND unit_price > '2000';

-- Q9. List all customers who joined in the year 2024 and belong to the state 'Maharashtra'. 
SELECT * 
FROM shopease.customers
WHERE YEAR(join_date) = '2024' AND state = 'Maharashtra';


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