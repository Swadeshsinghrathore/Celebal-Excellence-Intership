# Week 03 - SQL Advanced Concepts

## What I Learned

### 1. Subqueries
- Used a **scalar subquery** to compare each row against an aggregate (e.g., find orders above average sales)
- Used a **correlated subquery** to find the highest sales order per customer — it runs once per outer row, referencing the current customer

### 2. CTEs (Common Table Expressions)
- Wrote `WITH customer_sales AS (...)` to pre-compute total sales per customer
- Reused the same CTE inside a subquery to find customers above the average of their group
- CTEs make complex queries more readable and avoid repeating logic

### 3. Window Functions
- `RANK() OVER (ORDER BY total_sales DESC)` — ranks customers by sales, with gaps for ties
- `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date)` — assigns sequential order numbers per customer; resets for each new customer
- Window functions don't collapse rows like `GROUP BY` — every row keeps its data plus gets a computed value

### 4. Schema Normalization
- Split the flat `superstore_raw` CSV into 3 related tables: `customers`, `products`, `orders`
- Used `FOREIGN KEY` constraints to maintain referential integrity between tables
- Used `SELECT DISTINCT` and `MAX() GROUP BY` for clean data insertion without duplicates

### 5. Combining Techniques
- Final query combined **JOIN + CTE + Window Function** in one — fetching customer names, total sales, and rank together
- Mini project applied all concepts to answer real business questions (top/bottom customers, single-order customers, above-average buyers)

# Week 2 - Basic SQL Assignment

This week I worked on two SQL  **ShopEase** (a structured schema-based assignment) and **Superstore** (a real-world CSV dataset analysis). Together, they covered everything from basic querying to transactions and business insights.

---

## Files

- `Shopease_Combine.sql` — Schema-based SQL assignment (5 sections, 27 questions)
- `Shopease_Section-A.sql` — Section A Solution
- `Shopease_Section-B.sql` — Section A Solution
- `Shopease_Section-C.sql` — Section A Solution
- `Shopease_Section-D.sql` — Section A Solution
- `Shopease_Section-E.sql` — Section A Solution
- `Superstore_Analysis_CSV.sql` — Sales data analysis on the Sample Superstore CSV dataset

---

## What I Learned

---

### 1. SQL Basics & Constraints

Learned how to use `SELECT`, `DISTINCT`, and how constraints like `PRIMARY KEY`, `UNIQUE`, `NOT NULL`, and `CHECK` enforce data integrity. Tested constraint violations hands-on — inserting a duplicate email throws a `1062` error, and inserting a negative price violates the `CHECK (unit_price > 0)` constraint with a `3819` error. This made the theory click in a practical way.

---

### 2. Filtering with WHERE

Practiced filtering rows using `WHERE` with conditions like `AND`, `BETWEEN`, `<>`, and column comparisons. Also worked with date-based filters and learned the difference between filtering on a raw column vs wrapping it in a function — which leads directly into indexes.

---

### 3. Indexes & SARGable Queries

This was a new concept for me. An index is like a book's index — MySQL doesn't scan every row, it jumps to matching records directly. But if you apply a function to an indexed column (like `YEAR(join_date)`), the index becomes useless because MySQL has to evaluate the function row by row first. This is called a **non-SARGable** query.

The fix is to rewrite the filter as a range on the raw column:

```sql
-- Index not used
WHERE YEAR(join_date) = 2024

-- Index used
WHERE join_date BETWEEN '2024-01-01' AND '2024-12-31'
```

---

### 4. Aggregations & GROUP BY

Used `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` with `GROUP BY` to summarize data at a category or status level. Learned the difference between `WHERE` (filters rows before grouping) and `HAVING` (filters after aggregation — can use aggregate expressions like `AVG(unit_price) > 2000`).

Also used `CASE` inside `COUNT()` to pivot order statuses into a single row — a clean trick to avoid multiple queries.

---

### 5. Joins

Practiced `INNER JOIN`, `LEFT JOIN`, and `RIGHT JOIN` across multiple tables. Key takeaway:
- **INNER JOIN** — only matching rows from both sides
- **LEFT JOIN** — all rows from left table, NULLs where right has no match (great for finding customers with no orders)
- **FULL OUTER JOIN** — MySQL Workbanch doesn't support this natively, simulated it using `UNION` of LEFT + RIGHT join

Also saw what happens when a Foreign Key is violated — inserting an order with a non-existent `customer_id` throws error `1452`, which enforces referential integrity between tables.

---

### 6. Working with Real CSV Data (Superstore)

The Superstore dataset had messier real-world problems:

**Column name conflicts** — columns like `Order Date` and `Order ID` clashed with SQL reserved keywords. Fixed by renaming them using `ALTER TABLE ... RENAME COLUMN` to snake_case equivalents.

**String dates** — `order_date` was stored as plain text in `MM/DD/YYYY` format. MySQL can't do time-based functions on strings, so I used `STR_TO_DATE()` to convert on the fly:

```sql
YEAR(STR_TO_DATE(`Order_Date`, '%m/%d/%Y'))
```

This enabled monthly trend analysis — finding total orders, sales, and profit per month across years.

---

### 7. ACID Properties & Transactions

Learned the four ACID properties using a bank transfer analogy:

| Property | Meaning |
|---|---|
| **Atomicity** | All steps complete or none do — no half-done transactions |
| **Consistency** | DB always moves between valid states |
| **Isolation** | Concurrent transactions don't interfere with each other |
| **Durability** | Once committed, data survives even a crash |

Implemented a real transaction in ShopEase using a **stored procedure** with `START TRANSACTION`, `COMMIT`, and an `EXIT HANDLER` that automatically `ROLLBACK`s if any step fails — inserting an order, adding line items, and updating stock atomically.

---

### 8. Data Validation & Quality

In the Superstore project, learned to validate dataset quality by checking:
- NULL counts per column using `COUNT(column)` vs `COUNT(*)`
- Negative profit rows — caused by heavy discounts, valid but worth flagging
- High discount rows (`Discount > 0.5`) — often the root cause of losses
- Unique customer count using `COUNT(DISTINCT customer_id)`
- Duplicate detection using `GROUP BY` + `HAVING COUNT(*) > 1`

---

# Week 1 — Python Basics & Data Exploration with Pandas

## What We Learned

### Python Fundamentals
- **Variables, Data Types & Operators** — integers, floats, strings, booleans, arithmetic and comparison operators
- **Control Flow** — `if-else` conditions for decision making
- **Loops** — `for` and `while` loops for iteration
- **Lists** — indexing, slicing, and iterating over lists
- **Dictionaries** — key-value operations, updating and iterating over dictionaries

### Pandas & Data Handling
- **Loading Data** — `read_csv()` to load datasets into a DataFrame
- **Exploring Data** — `head()`, `info()`, `describe()` to understand dataset structure
- **Filtering & Grouping** — filtering rows by conditions, grouping and aggregation
- **Column Operations** — creating new columns, applying transformations
- **Redundancy & Normalization Basics** — identifying duplicate data, understanding normalization concepts

------------------------
