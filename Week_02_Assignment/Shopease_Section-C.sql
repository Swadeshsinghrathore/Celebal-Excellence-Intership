-- Section C — Aggregation (GROUP BY, SUM, COUNT, AVG, MIN, MAX) 

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
