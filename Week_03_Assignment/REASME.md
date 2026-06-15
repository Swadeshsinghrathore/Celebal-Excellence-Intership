# Week 03 Assignment

# Superstore Advanced SQL Analysis

## Subqueries, CTEs, and Window Functions

A structured SQL analysis assignment using the **Sample Superstore** dataset, covering advanced querying techniques including Subqueries, Common Table Expressions (CTEs), and Window Functions. The dataset is normalized into a relational schema and analyzed for customer sales insights.

---

## Files

- `AD.sql` — Complete SQL file covering all steps: schema setup, required queries, final combined query, and mini project

---

## Dataset & Schema Overview

The raw dataset (`superstore_raw`) was imported from the Sample Superstore CSV into the `superstore2` database. Column names were renamed from the raw CSV to snake_case to avoid SQL reserved keyword conflicts (`ORDER`, `DATE`, spaces in names).

Three normalized tables were created from the raw data:

| Table | Primary Key | Description |
|---|---|---|
| `customers` | `customer_id` | Customer details: name, segment |
| `products` | `product_id` | Product catalog: name, category, sub-category |
| `orders` | `row_id` | Transaction records with sales, quantity, discount, profit |

### Foreign Key Relationships

```
customers.customer_id  ←──  orders.customer_id
products.product_id    ←──  orders.product_id
```

---

## Step 1 — Setup Data

### Column Renaming

After importing `superstore_raw`, all problematic column names were renamed using `ALTER TABLE ... RENAME COLUMN` to snake_case equivalents. This is a required preprocessing step — SQL reserved keywords like `ORDER` and `DATE` in column names break query execution without proper escaping.

```sql
ALTER TABLE superstore2.superstore_raw
RENAME COLUMN `Order ID`   TO order_id,
RENAME COLUMN `Order Date` TO order_date,
RENAME COLUMN `Ship Date`  TO ship_date,
-- ... and remaining columns
```

### Table Creation & Data Insertion

- **`customers`** — Created with `customer_id` as `PRIMARY KEY`. Data inserted using `SELECT DISTINCT` on `customer_id, customer_name, segment` from the raw table.

- **`products`** — Created with `product_id` as `PRIMARY KEY`. Used `MAX()` on `product_name`, `category`, and `sub_category` grouped by `product_id` to extract one unique row per product and avoid duplicate primary key errors.

- **`orders`** — Created with `row_id` as `PRIMARY KEY` and `FOREIGN KEY` constraints referencing both `customers` and `products`. Data inserted using `SELECT DISTINCT` to populate all transaction fields.

---

## Step 2 — Required Queries

---

### Q1 — Orders Where Sales > Average Sales (Subquery)

```sql
SELECT * FROM superstore2.orders
WHERE sales > (SELECT AVG(sales) FROM superstore2.orders);
```

The inner subquery calculates the overall average sales value. The outer query then returns all order rows where `sales` exceeds that average. This is a **scalar subquery** — it returns a single value used as a filter threshold.

---

### Q2 — Highest Sales Order per Customer (Correlated Subquery)

```sql
SELECT customer_id, order_id, product_id, sales
FROM superstore2.orders o
WHERE sales = (
    SELECT MAX(sales)
    FROM superstore2.orders p
    WHERE p.customer_id = o.customer_id
);
```

This uses a **correlated subquery** — for each row in the outer query, the subquery runs once for that specific `customer_id` and returns their maximum sales value. Rows where `sales` matches that maximum are returned, giving the top sales order per customer.

---

### Q3 — Total Sales per Customer (CTE)

```sql
WITH customer_sales AS (
    SELECT customer_id,
        SUM(sales) AS total_sales
    FROM superstore2.orders
    GROUP BY customer_id
)
SELECT * FROM customer_sales;
```

A **Common Table Expression (CTE)** named `customer_sales` pre-computes the total sales for each customer. The main query then simply reads from this CTE. CTEs improve readability by separating the aggregation logic from the final result.

---

### Q4 — Customers Whose Total Sales Are Above Average (CTE + Subquery)

```sql
WITH customer_sales AS (
    SELECT customer_id,
        SUM(sales) AS total_sales
    FROM superstore2.orders
    GROUP BY customer_id
)
SELECT customer_id, total_sales
FROM customer_sales
WHERE total_sales > (
    SELECT AVG(total_sales)
    FROM customer_sales
);
```

The CTE is reused twice: once to build the per-customer totals, and again inside a subquery to compute the average of those totals. The main query filters to customers above that average. This demonstrates that **a CTE can reference itself within the same query** (in the subquery).

---

### Q5 — Rank All Customers by Total Sales (Window Function)

```sql
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
```

`RANK()` is a **window function** that assigns a rank to each customer based on `total_sales` in descending order. Unlike `GROUP BY`, window functions do not collapse rows — every customer retains their own row with a rank assigned. Tied values receive the same rank, with a gap before the next rank.

---

### Q6 — Row Numbers per Customer (Window Function + PARTITION BY)

```sql
SELECT customer_id,
    order_id,
    order_date,
    sales,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS row_number
FROM superstore2.orders;
```

`PARTITION BY customer_id` divides the dataset into separate windows — one per customer. `ROW_NUMBER()` then assigns sequential numbers (1, 2, 3...) to each order within that customer's window, ordered by `order_date`. The row number resets to 1 for each new customer.

---

### Q7 — Top 3 Customers by Total Sales (Window Function)

```sql
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
```

`RANK()` is applied inside a subquery (derived table) to rank customers by total sales. The outer query then filters to only `sales_rank <= 3`. Note: if multiple customers are tied at rank 3, all of them are returned.

---

## Step 3 — Final Combined Query (JOIN + CTE + Window Function)

```sql
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
```

This query combines all three advanced techniques:
- **CTE** — pre-computes total sales per customer
- **JOIN** — links the CTE result to the `customers` table to fetch `customer_name`
- **Window Function** — assigns a sales rank using `RANK() OVER (...)`

Result: a clean leaderboard showing customer name, their total sales, and their rank.

---

## Mini Project — Customer Sales Insights

---

### 1. Top 5 Customers by Sales

Uses `RANK() OVER (ORDER BY SUM(sales) DESC)` inside a derived table and filters to `sales_rank <= 5`. Identifies the highest-revenue customers in the dataset.

---

### 2. Bottom 5 Customers by Sales

Same approach as top 5, but `RANK() OVER (ORDER BY SUM(sales) ASC)` sorts in ascending order, surfacing the lowest-revenue customers.

---

### 3. Customers Who Made Only One Order

```sql
SELECT c.customer_name, o.customer_id, COUNT(o.order_id) AS total_orders
FROM superstore2.orders o
JOIN superstore2.customers c ON o.customer_id = c.customer_id
GROUP BY o.customer_id
HAVING COUNT(o.order_id) = 1;
```

Groups orders by `customer_id` and uses `HAVING COUNT = 1` to filter to single-order customers. `HAVING` is used (not `WHERE`) because the filter is applied after aggregation.

---

### 4. Customers with Above-Average Sales

```sql
SELECT DISTINCT c.customer_name
FROM superstore2.orders o
JOIN superstore2.customers c ON o.customer_id = c.customer_id
WHERE o.sales > (SELECT AVG(sales) FROM superstore2.orders);
```

Joins orders with customers and filters rows where individual `sales` exceeds the dataset average. `DISTINCT` ensures each customer name appears only once even if they have multiple qualifying orders.

---

### 5. Highest Order Value per Customer

```sql
SELECT c.customer_name, o.customer_id, MAX(o.sales) AS highest_order_value
FROM superstore2.orders o
JOIN superstore2.customers c ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
ORDER BY highest_order_value DESC;
```

Groups by customer and uses `MAX(sales)` to find their single highest-value transaction. Results are sorted descending so the highest-value customers appear first.

---

## Key Concepts Learned

| Concept | What It Does |
|---|---|
| **Scalar Subquery** | Returns a single value used as a filter condition (e.g., `AVG(sales)`) |
| **Correlated Subquery** | Runs once per outer row, referencing the outer query's current row |
| **CTE (`WITH`)** | Named temporary result set — improves readability and can be referenced multiple times |
| **`RANK()`** | Assigns rank with gaps for ties (1, 2, 2, 4...) |
| **`ROW_NUMBER()`** | Assigns unique sequential numbers regardless of ties |
| **`PARTITION BY`** | Divides data into groups; window function resets per group |
| **`HAVING`** | Filters after aggregation (vs `WHERE` which filters before) |
| **Normalized Schema** | Separating raw data into `customers`, `products`, `orders` tables linked by foreign keys |