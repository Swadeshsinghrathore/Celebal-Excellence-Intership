SELECT * FROM superstore2.superstore_raw;
 -- I changed the column names because some of the original names contained SQL reserved keywords such as ORDER and DATE. 
-- To avoid conflicts and query execution errors, we renamed the columns with appropriate and meaningful names.ALTER TABLE superstore2.superstore_raw
ALTER TABLE superstore2.superstore_raw
RENAME COLUMN `Row ID` TO row_id,
RENAME COLUMN `Order ID` TO order_id,
RENAME COLUMN `Order Date` TO order_date,
RENAME COLUMN `Ship Date` TO ship_date,
RENAME COLUMN `Ship Mode` TO ship_mode,
RENAME COLUMN `Customer ID` TO customer_id,
RENAME COLUMN `Customer Name` TO customer_name,
RENAME COLUMN `Segment` TO segment,
RENAME COLUMN `Country` TO country,
RENAME COLUMN `City` TO city,
RENAME COLUMN `State` TO state,
RENAME COLUMN `Postal Code` TO postal_code,
RENAME COLUMN `Region` TO region,
RENAME COLUMN `Product ID` TO product_id,
RENAME COLUMN `Category` TO category,
RENAME COLUMN `Sub-Category` TO sub_category,
RENAME COLUMN `Product Name` TO product_name,
RENAME COLUMN `Sales` TO sales,
RENAME COLUMN `Quantity` TO quantity,
RENAME COLUMN `Discount` TO discount,
RENAME COLUMN `Profit` TO profit;

-- Create the customer table 
CREATE TABLE superstore2.customers (
    customer_id   VARCHAR(20) primary key,
    customer_name VARCHAR(100) NOT NULL,
    segment       VARCHAR(50)
);

-- Inserting the data into customer table using SELECT DISTINCT 
INSERT INTO superstore2.customers (customer_id,
				customer_name,
                segment)
SELECT DISTINCT
    customer_id,
    customer_name,
    segment
FROM superstore2.superstore_raw;


-- Creadting the product table 
CREATE TABLE superstore2.products (
    product_id   VARCHAR(20) primary key,
	product_name VARCHAR(255),
    category     VARCHAR(50),
    sub_category VARCHAR(50)
   
);

-- Inserting the data into product table using SELECT 
INSERT INTO superstore2.products (
    product_id,
    product_name,
    category,
    sub_category
)
SELECT
    product_id,
    MAX(product_name),
    MAX(category),
    MAX(sub_category)
FROM superstore2.superstore_raw
GROUP BY product_id;

-- Creating the Orders table with foreign key constraints to establish relationships between the tables and maintain referential integrity.
CREATE TABLE superstore2.orders (
    order_id    VARCHAR(20) NOT NULL,
    row_id      INT primary key,
    order_date  VARCHAR(255),
    ship_date   VARCHAR(255),
    ship_mode   VARCHAR(255),
    customer_id VARCHAR(255),
    product_id  VARCHAR(255),
    sales       double,
    quantity    INT,
    discount    double,
    profit      double,
    
    
    FOREIGN KEY (customer_id) 
    REFERENCES customers(customer_id),
    
    FOREIGN KEY (product_id) 
    REFERENCES products(product_id)
    
);

-- Inserting the data into order table using SELECT DISTINCT 
INSERT INTO superstore2.orders (order_id, row_id, order_date, ship_date, ship_mode, customer_id, product_id, sales, quantity, discount, profit)
SELECT DISTINCT
    order_id,
    row_id,
    order_date,
    ship_date,
    ship_mode,
    customer_id,
    product_id,
    sales,
    quantity,
    discount,
    profit
FROM superstore2.superstore_raw;


-- 1. Find all orders where sales are greater than the average sales. (Subquery)  
-- first i find the avrage selas of all products in order table than use this as a subquery and find all 

SELECT * FROM superstore2.orders
where sales > (SELECT AVG(sales) FROM superstore2.orders);

-- 2. Find the highest sales order for each customer. (Subquery) 
-- This query groups all records by product_id and selects one value for product_name, category, and sub_category using MAX().
-- It then inserts one unique row per product into the products table, avoiding duplicate primary key errors.
SELECT
    customer_id,
    order_id,
    product_id,
    sales
FROM superstore2.orders o
WHERE sales = (
    SELECT MAX(sales)
    FROM superstore2.orders p
    where p.customer_id = o.customer_id
); 

-- 3. Calculate total sales for each customer. (CTE)
-- The CTE customer_sales calculates the total sales made by each customer using SUM(sales) and GROUP BY customer_id.
-- The main query then retrieves the customer-wise total sales from the CTE. 
WITH customer_sales AS (
    SELECT customer_id,
        SUM(sales) AS total_sales
    FROM superstore2.orders
    GROUP BY customer_id
)
SELECT *
FROM customer_sales;

-- 4. Find customers whose total sales are above average. (CTE + Subquery)  
-- The CTE calculates the total sales for each customer.
-- The subquery finds the average of those total sales, and the main query returns customers whose total sales are above that average.
WITH customer_sales AS (
    SELECT customer_id,
        SUM(sales) AS total_sales
    FROM superstore2.orders
    GROUP BY customer_id
)
SELECT customer_id,
    total_sales
FROM customer_sales
WHERE total_sales > (
    SELECT AVG(total_sales)
    FROM customer_sales
);

-- 5. Rank all customers based on total sales. (Window Function)
-- The CTE calculates the total sales for each customer using SUM(sales).
-- The RANK() window function assigns ranks to customers based on their total sales in descending order.
WITH customer_sales AS (
    SELECT customer_id,
        SUM(sales) AS total_sales
    FROM superstore2.orders
    GROUP BY customer_id
)
SELECT customer_id,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS customer_rank
FROM customer_sales;


-- 6. Assign row numbers to each order within a customer. (Window Function + PARTITION BY)
-- PARTITION BY customer_id creates a separate group for each customer.
-- ROW_NUMBER() then assigns a sequential number to each order within that customer's orders based on order_date.
SELECT customer_id,
    order_id,
    order_date,
    sales,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS raw_number
FROM superstore2.orders; 


-- 7. Display top 3 customers based on total sales. (Window Function)
-- The query first calculates the total sales for each customer using SUM(sales) and groups the data by customer_id.
-- Then RANK() assigns rankings based on total sales in descending order, and only the top 3 ranked customers are displayed.
SELECT customer_id, total_sales, sales_rank
FROM (
    SELECT 
        customer_id,
        SUM(sales) AS total_sales,
        RANK() OVER (ORDER BY SUM(sales) DESC) AS sales_rank
    FROM superstore2.orders
    GROUP BY customer_id
) AS ranked
WHERE sales_rank <= 3;  


-- 8. Write one final query that shows: Customer Name ,Total Sales ,Rank (Use JOIN + CTE + Window Function together) 
-- The CTE calculates total sales for each customer using SUM(sales).
-- The query joins with the customers table to get customer names and uses RANK() to rank customers based on total sales.

WITH customer_sales AS (
    SELECT 
        customer_id,
        SUM(sales) AS total_sales
    FROM superstore2.orders
    GROUP BY customer_id
)
SELECT 
    c.customer_name,
    cs.total_sales,
    RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
FROM customer_sales cs
JOIN superstore2.customers c 
    ON cs.customer_id = c.customer_id;
    


-- MINI PROJECT: Customer Sales Insights 

-- 1. Who are the top 5 customers?  

SELECT customer_id, total_sales, sales_rank
FROM (
    SELECT 
        customer_id,
        SUM(sales) AS total_sales,
        RANK() OVER (ORDER BY SUM(sales) DESC) AS sales_rank
    FROM superstore2.orders
    GROUP BY customer_id
) AS ranked
WHERE sales_rank <= 5; 


-- 2. Who are the bottom 5 customers?  

SELECT customer_id, total_sales, bottom_sales_rank
FROM (
    SELECT 
        customer_id,
        SUM(sales) AS total_sales,
        RANK() OVER (ORDER BY SUM(sales) ASC) AS bottom_sales_rank
    FROM superstore2.orders
    GROUP BY customer_id
) AS ranked
WHERE bottom_sales_rank <= 5;

-- 3. Which customers made only one order?  

SELECT c.customer_name,
    o.customer_id,
    COUNT(o.order_id) AS total_orders
FROM superstore2.orders o
JOIN superstore2.customers c 
ON o.customer_id = c.customer_id
GROUP BY o.customer_id
HAVING COUNT(o.order_id) = 1;


-- 4. Which customers have above-average sales? 
SELECT DISTINCT c.customer_name
FROM superstore2.orders o
JOIN superstore2.customers c 
ON o.customer_id = c.customer_id
WHERE o.sales > (SELECT AVG(sales) FROM superstore2.orders);

-- 5. What is the highest order value per customer? 
SELECT 
    c.customer_name,
    o.customer_id,
    MAX(o.sales) AS highest_order_value
FROM superstore2.orders o
JOIN superstore2.customers c 
ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
ORDER BY highest_order_value DESC;
