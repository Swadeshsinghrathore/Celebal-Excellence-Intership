-- Section A — SQL Basics (SELECT, Constraints, Primary Keys) 

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
