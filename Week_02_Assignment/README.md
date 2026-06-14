# Week 02 Assignment(A)
# Superstore Sales Analysis(CSV)

A structured SQL analysis assignment on the classic **Sample Superstore** dataset, covering data loading, schema exploration, cleaning, filtering, aggregation, business insights, and data validation using MySQL.

---

## File

- `Superstore_Analysis_CSV.sql` — Complete SQL file covering all 7 analysis steps

---

## Dataset Overview

The dataset is the widely-used **Sample Superstore** CSV containing retail transaction data. It was imported into a MySQL database named `superstore` using the **Table Data Import Wizard**.

Key columns in the table (`sample - superstore`):

| Column | Description |
|---|---|
| `order_id` | Unique identifier for each order |
| `order_date` | Date the order was placed (stored as string in CSV) |
| `ship_date` | Date the order was shipped |
| `ship_mode` | Shipping method used |
| `customer_id` / `customer_name` | Customer details |
| `Region` | Geographic region (East, West, South, Central) |
| `Category` / `sub_category` | Product classification |
| `product_id` / `product_name` | Product details |
| `Sales` | Revenue generated per row |
| `Quantity` | Units sold |
| `Discount` | Discount applied (0 to 1 scale) |
| `Profit` | Profit earned per row |

---

## Steps Covered

---

### Step 1 — Load Dataset

The CSV dataset was loaded into the `superstore` database using MySQL Workbench's **Table Data Import Wizard** (right-click on database → Table Data Import Wizard → select CSV file). This auto-created the table with columns mapped from the CSV headers.

---

### Step 2 — Explore Table (Schema & Sample Data)

Used `DESCRIBE` to inspect the table structure  column names, data types, and nullability. Used `SELECT * ... LIMIT 5` to preview the first 5 rows and get a feel for the data before querying.

**Column Renaming:**
Several column names in the raw CSV caused issues because they contained reserved SQL keywords (`ORDER`, `DATE`) or spaces, which broke query execution. All problematic columns were renamed using `ALTER TABLE ... RENAME COLUMN` to snake_case equivalents:

```sql
ALTER TABLE `sample - superstore`
RENAME COLUMN `Order Date` TO order_date;

ALTER TABLE `sample - superstore`
RENAME COLUMN `Order ID`   TO order_id;

-- ... and so on for Ship Date, Ship Mode, Customer ID, etc.
```

This is a critical preprocessing step — skipping it would cause every subsequent query using these columns to fail.

---

### Step 3 — WHERE Filters (Region, Category, Date, Sales)

Applied targeted filters to explore specific slices of the data:

- **By Region** — filtered all rows where `Region = 'South'` to isolate Southern transactions
- **By Category** — retrieved all `'Office Supplies'` orders
- **By Sales threshold** — found high-value transactions where `Sales > 3500`
- **By Date range** — used `BETWEEN` to fetch orders placed between two dates

Note: Since `order_date` is stored as a **string** in the CSV (format: `MM/DD/YYYY`), the `BETWEEN` filter on dates works lexicographically here. For accurate date filtering, `STR_TO_DATE()` conversion is applied in later steps.

---

### Step 4 — GROUP BY Aggregations (Sales, Quantity, Profit)

Grouped data by `Category` to compute a full performance summary per category in a single query:

```sql
SELECT Category,
       ROUND(SUM(Sales))     AS Total_Sales,
       ROUND(AVG(Sales))     AS Avg_Sales,
       ROUND(SUM(Quantity))  AS Total_Quantity,
       ROUND(SUM(Profit))    AS Total_Profit,
       ROUND(AVG(Profit))    AS Avg_Profit
FROM superstore.`sample - superstore`
GROUP BY Category;
```

`ROUND()` is applied to all aggregates to keep the output clean and readable. This gives an at-a-glance comparison of how Furniture, Office Supplies, and Technology perform across all key metrics.

---

### Step 5 — Sorting & Limiting Results (Top Products & Categories)

**Top 3 Products by Sales:**
Groups by `product_name`, sums sales and profit, sorts descending by `Total_Sales`, and limits to 3 — identifying the highest-revenue products in the store.

**Top Categories by Profit:**
Groups by `Category` and sorts by `Total_Profit` descending — no LIMIT applied here so all 3 categories are ranked, making it easy to see which category is most and least profitable.

---

### Step 6 — Business Use Cases

**Monthly Trends:**
Since `order_date` is a plain string in the CSV (`MM/DD/YYYY` format), it cannot be directly used with `YEAR()` or `MONTH()`. The solution is wrapping it with `STR_TO_DATE()` to parse it into a proper date first:

```sql
YEAR(STR_TO_DATE(`Order_Date`, '%m/%d/%Y'))  AS order_year,

MONTH(STR_TO_DATE(`Order_Date`, '%m/%d/%Y')) AS order_month,

MONTHNAME(STR_TO_DATE(`Order_Date`, '%m/%d/%Y')) AS month_name
```

The result shows total orders, sales, and profit per month across all years — useful for spotting seasonal patterns and peak sales periods.

**Top 5 Customers by Sales:**
Groups by `customer_name`, sums their total sales, and limits to top 5. Identifies the highest-spending customers — valuable for loyalty programs or account management.

**Top 5 Most Profitable Customers:**
A separate query ranks customers by `SUM(Profit)` instead of sales. High sales ≠ high profit (due to discounts), so this gives a more accurate picture of which customers are actually valuable to the business.

**Duplicate Detection:**
Checks for rows where the same `(product_id, order_id)` combination appears more than once:


In a superstore dataset, the same product can appear multiple times in one order (e.g., different quantities or ship modes), so this helps distinguish genuine duplicates from legitimate multi-line orders.

---

### Step 7 — Data Validation & Quality Checks

**Row & NULL counts per Category:**
Validates that critical columns like `Order_ID`, `Customer_Name`, and `Quantity` have no unexpected NULLs, and confirms row distribution across categories is as expected.

**Negative Profit rows:**
```sql
SELECT * FROM superstore.`sample - superstore` WHERE Profit < 0;
```
Identifies loss-making transactions — often caused by heavy discounts. These rows are valid business data but important to flag for profitability analysis.

**High Discount rows:**
```sql
SELECT * FROM superstore.`sample - superstore` WHERE Discount > 0.5;
```
Isolates orders where more than 50% discount was applied. These are likely responsible for the negative profit rows and may warrant business policy review.

**Unique Customer Count:**
```sql
SELECT COUNT(DISTINCT Customer_ID) AS Unique_Customers FROM ...;
```
Confirms the true number of individual customers in the dataset — important baseline metric for any customer-level analysis.

---
---
---

# Week 02 Assignment(B)
## ShopEase 

A structured SQL assignment covering core to advanced MySQL concepts using a fictional e-commerce schema **ShopEase**.

---

## File

- `Shopease_Combine.sql` — Combined SQL Sections with all queries and explanations across 5 sections

---

## Schema Overview

The **shopease** database contains the following tables:

| Table | Primary Key | Description |
|---|---|---|
| `customers` | `customer_id` | Stores customer info (name, city, state, join date) |
| `orders` | `order_id` | Records orders placed by customers |
| `order_items` | `item_id` | Line items within each order |
| `products` | `product_id` | Product catalog with pricing and stock |

### Foreign Key Relationships
```
customers.customer_id  ←──  orders.customer_id
orders.order_id        ←──  order_items.order_id
products.product_id    ←──  order_items.product_id
```

---

## Sections Covered

---

### Section A — SQL Basics (SELECT, Constraints, Primary Keys)

This section covers the foundational building blocks of SQL retrieving data and understanding how constraints maintain database integrity.

**Q1–Q3: Basic SELECT queries**
Covers `SELECT *` to fetch all columns, selecting specific columns like `first_name`, `last_name`, `city`, and using `SELECT DISTINCT` to retrieve unique values demonstrated by listing all unique product categories.

**Q4: Primary Keys**
Identifies the primary key of each table in the schema (`customer_id`, `item_id`, `order_id`, `product_id`). Explains why a primary key must be both **UNIQUE** and **NOT NULL** uniqueness ensures each row can be individually identified, and NOT NULL ensures no record is left without an identifier, which would break data integrity.

**Q5: UNIQUE constraint on email**
The `email` column in `customers` is constrained as `UNIQUE NOT NULL`. Attempting to insert a duplicate email throws:
```
Error Code: 1062. Duplicate entry 'aarav.s@email.com' for key 'customers.email'
```

**Q6: CHECK constraint on unit_price**
The `products` table has a `CHECK (unit_price > 0)` constraint. Inserting a product with `unit_price = -50` throws:
```
Error Code: 3819. Check constraint 'products_chk_1' is violated.
```
This prevents logically invalid data (negative prices) from entering the database.

---

### Section B — Filtering & Optimization (WHERE, Indexes)

This section focuses on filtering data precisely using `WHERE` clauses and understanding how indexes affect query performance.

**Q7–Q10: WHERE clause filtering**
- Filtering orders by `status = 'Delivered'`
- Combining conditions with `AND` — e.g., Electronics products with `unit_price > 2000`
- Using `YEAR()` function to filter customers who joined in 2024 from Maharashtra
- Using `BETWEEN` with `<>` to find orders in a date range that are not cancelled

**Q11: Index on order_date (`idx_orders_date`)**
An index works like a book's index instead of scanning every row, MySQL can jump directly to matching records. Without `idx_orders_date`, a query filtering by `order_date` performs a full table scan. With the index, MySQL uses a B-Tree lookup to locate matching rows instantly, which becomes significantly faster as the table grows.

```sql
-- Both these queries benefit from idx_orders_date
SELECT * FROM shopease.orders
WHERE order_date = '2024-08-28';

SELECT * FROM shopease.orders
WHERE order_date BETWEEN '2024-08-01' AND '2024-08-20';
```

**Q12: SARGable vs Non-SARGable queries**
Applying a function like `YEAR()` directly on an indexed column makes the query **non-SARGable** — MySQL cannot use the index because it must compute `YEAR(join_date)` for every row before comparing. The fix is to rewrite the filter as a range on the raw column:

```sql
--  Non-SARGable — index not used
SELECT * FROM customers
WHERE YEAR(join_date) = 2024;

--  SARGable — index used efficiently
SELECT * FROM customers
WHERE join_date BETWEEN '2024-01-01' AND '2024-12-31';
```

---

### Section C — Aggregation (GROUP BY, SUM, COUNT, AVG, MIN, MAX)

This section explores summarizing and analyzing data using aggregate functions combined with grouping.

**Q13: COUNT**
Counts the total number of orders in the `orders` table using `COUNT(order_id)`.

**Q14: SUM with WHERE**
Calculates total revenue only from `'Delivered'` orders using `SUM(total_amount)` filtered by status.

**Q15: AVG with GROUP BY**
Computes the average `unit_price` per product category, producing one row per category.

**Q16: Multi-aggregate with ORDER BY**
For each order status, computes both the count of orders and total revenue, then sorts by revenue descending — useful for understanding which statuses generate the most money.

**Q17: MAX and MIN per group**
Finds the most expensive and cheapest product within each category in a single query using `MAX(unit_price)` and `MIN(unit_price)` grouped by `category`.

**Q18: HAVING clause**
Filters grouped results to show only categories where the average price exceeds ₹2000. Unlike `WHERE` (which filters rows before grouping), `HAVING` filters after aggregation — it can reference aggregate expressions like `AVG(unit_price)`.

---

### Section D — Joins & Relationships

This section covers how to combine data across multiple related tables and understand the behavior of different join types.

**Q19: INNER JOIN (orders + customers)**
Fetches `order_id`, `order_date`, `first_name`, `last_name`, and `total_amount` by joining `orders` and `customers` on `customer_id`. Only returns rows where a match exists in both tables.

**Q20: LEFT JOIN (all customers + their orders)**
Returns every customer regardless of whether they have placed any orders. Customers with no orders appear with `NULL` in all order-related columns. This is useful for finding inactive customers.

**Q21: 3-Table JOIN (orders → order_items → products)**
Chains two INNER JOINs to pull `order_id`, `product_name`, `quantity`, `unit_price`, and `discount_pct` together in one result — traversing the full order detail hierarchy.

**Q22: LEFT vs RIGHT JOIN + FULL OUTER JOIN**
- **LEFT JOIN** — all rows from the left table, NULLs on the right where there's no match (e.g., customers with no orders)
- **RIGHT JOIN** — all rows from the right table, NULLs on the left where there's no match (e.g., orders with no matching customer)
- **FULL OUTER JOIN** — MySQL Workbanch doesn't natively support this, so it's simulated using `UNION` of a LEFT JOIN and a RIGHT JOIN.

**Q23: Foreign Key violation**
Attempting to insert an order with a non-existent `customer_id = 999` throws:
```
Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails
```
This enforces **referential integrity** — you cannot have an order that references a customer who doesn't exist.

---

### Section E — Advanced Concepts (CASE, ACID, Transactions)

This section covers conditional logic, database theory, and writing safe multi-step operations.

**Q24: CASE for price tier classification**
Classifies every product into `'Budget'`, `'Mid-Range'`, or `'Premium'` based on `unit_price` using a `CASE` expression in the `SELECT` clause. Results are ordered by price for easy reading.

```sql
CASE
    WHEN unit_price < 1000 THEN 'Budget'
    WHEN unit_price BETWEEN 1000 AND 3000 THEN 'Mid-Range'
    WHEN unit_price > 3000 THEN 'Premium'
END AS price_tier
```

**Q25: CASE inside COUNT**
Counts `'Delivered'` vs all other orders in a single row by nesting `CASE` inside `COUNT()`. When the condition is true, `CASE` returns `1` and COUNT includes it; when false, it returns `NULL` which COUNT ignores — an elegant way to pivot status counts without multiple queries.

**Q26: ACID Properties**
Explains all four ACID properties using a real-world bank transfer example:

| Property | Meaning | Example |
|---|---|---|
| **Atomicity** | All or nothing — no partial execution | Debit + credit both happen, or neither does |
| **Consistency** | DB moves between valid states only | Total money before and after transfer stays the same |
| **Isolation** | Concurrent transactions don't interfere | Two simultaneous withdrawals don't both read the same balance |
| **Durability** | Committed data survives crashes | After commit, the transfer is permanently saved even if the server crashes |

**Q27: Full Transaction with Stored Procedure**
Implements a complete atomic transaction that:
1. Inserts a new order (`order_id=1011`)
2. Inserts two order line items
3. Decrements stock for both purchased products
4. Uses a `DECLARE EXIT HANDLER FOR SQLEXCEPTION` to automatically `ROLLBACK` if any step fails
5. `COMMIT`s only if all steps succeed

```sql
DELIMITER $$
CREATE PROCEDURE place_order_1011()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Transaction FAILED — Rolled back all changes' AS result;
    END;

    START TRANSACTION;
        -- insert order, items, update stock...
    COMMIT;
    SELECT 'Transaction SUCCESS — All changes committed' AS result;
END$$
DELIMITER ;
```
