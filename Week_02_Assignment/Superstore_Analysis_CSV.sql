CREATE DATABASE Superstore;

USE superstore;

-- Objective: Analyze sales data using SQL with filtering, aggregation, and business queries. 
-- Steps:
-- 1.Load dataset into a SQL database.
-- Answer 1.--> We loaded the CSV dataset into the database using the Table Data Import Wizard. First, we right-clicked on the Superstore database, selected Table Data Import Wizard, and then imported the CSV dataset file into the database table.

-- 2.Explore table (schema, sample data). 
DESCRIBE superstore.`sample - superstore`;

SELECT * FROM superstore.`sample - superstore`
LIMIT 5;

-- I encountered an issue with some column names while applying filters. Specifically, the Order Date column was causing errors because 
-- ORDER and DATE are reserved keywords in SQL. As a result, the SQL query was not executing correctly. To resolve this issue and simplify query writing, 
-- I renamed the problematic columns using more suitable names such as order_date. This eliminated the conflicts with SQL keywords and allowed the queries to run successfully
ALTER TABLE `sample - superstore`
RENAME COLUMN `Row ID` TO row_id;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Order ID` TO order_id;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Order Date` TO order_date;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Ship Date` TO ship_date;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Ship Mode` TO ship_mode;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Customer ID` TO customer_id;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Customer Name` TO customer_name;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Postal Code` TO postal_code;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Product ID` TO product_id;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Sub-Category` TO sub_category;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Product Name` TO product_name;

-- 3.Apply WHERE filters (region, category, date, sales). 
SELECT * FROM superstore.`sample - superstore`
WHERE Region = 'South';

SELECT * FROM superstore.`sample - superstore`
WHERE Category = 'Office Supplies';

SELECT * FROM superstore.`sample - superstore`
WHERE Sales > 3500;

SELECT * FROM superstore.`sample - superstore`
WHERE order_date BETWEEN '11/8/2014' and '11/8/2017';


-- 4.Use GROUP BY for aggregations (sales, quantity, averages). 
SELECT Category,
       ROUND(SUM(Sales)) AS Total_Sales,
       ROUND(AVG(Sales)) AS Avg_Sales,
       ROUND(SUM(Quantity)) AS Total_Quantity,
       ROUND(SUM(Profit)) AS Total_Profit,
       ROUND(AVG(Profit)) AS Avg_Profit
FROM superstore.`sample - superstore`
GROUP BY Category;

-- 5.Sort and limit results (top products, top categories). 

-- Top 3 Product
SELECT product_name,
       SUM(Sales) AS Total_Sales,
       ROUND(SUM(Profit)) AS Total_Profit
FROM superstore.`sample - superstore`
GROUP BY product_name
ORDER BY Total_Sales DESC
LIMIT 3;

-- TOP categories
SELECT Category,
       SUM(Profit) AS Total_Profit,
       SUM(Sales) AS Total_Sales
FROM superstore.`sample - superstore`
GROUP BY Category
ORDER BY Total_Profit DESC;

-- 6.Solve use cases (monthly trends, top customers, duplicates).
-- monthly trends
-- in the csv data the order_date is a string so we convert that into proper data fromat so that we can find monthly trends we use STR_TO_DATE
SELECT
    YEAR(STR_TO_DATE(`Order_Date`, '%m/%d/%Y'))  AS order_year,
    MONTH(STR_TO_DATE(`Order_Date`, '%m/%d/%Y')) AS order_month,
    MONTHNAME(STR_TO_DATE(`Order_Date`, '%m/%d/%Y')) AS month_name,
    COUNT(DISTINCT `Order_ID`)                   AS total_orders,
    SUM(Sales)                                   AS total_sales,
    SUM(Profit)                                  AS total_profit
FROM superstore.`sample - superstore`
GROUP BY order_year, order_month, month_name
ORDER BY order_year, order_month;

-- top 5 customers 
SELECT Customer_Name,
       SUM(Sales) AS Total_Sales
FROM superstore.`sample - superstore`
GROUP BY Customer_Name
ORDER BY Total_Sales DESC
LIMIT 5;
-- TOP 5 PROFATIABLE CUSTOMERS
SELECT Customer_Name,
       SUM(Profit) AS Total_Profit
FROM superstore.`sample - superstore`
GROUP BY Customer_Name
ORDER BY Total_Profit DESC
LIMIT 5;

-- duplicate entries

SELECT product_id,order_id,
       COUNT(*) AS Duplicate_Count
FROM superstore.`sample - superstore`
GROUP BY product_id,order_id
HAVING COUNT(*) > 1;

-- 7.Validate results (row counts, data quality). 

SELECT Category,
    COUNT(*) AS Total_Rows,
    COUNT(Order_ID) AS OrderID_NotNull,
    COUNT(Customer_Name) AS Customer_NotNull,
    SUM(Quantity) AS qua_NotNull
FROM superstore.`sample - superstore`
GROUP BY Category;

SELECT *
FROM superstore.`sample - superstore`
WHERE Profit < 0;

SELECT * 
FROM superstore.`sample - superstore`
WHERE Discount > 0.5;

SELECT COUNT(DISTINCT Customer_ID) AS Unique_Customers
FROM superstore.`sample - superstore`;




