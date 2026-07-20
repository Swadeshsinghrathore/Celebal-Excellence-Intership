# Week 05 — Apache Spark: DataFrames, Data Cleaning & Aggregations

## Overview

This assignment covers the fundamentals of Apache Spark why it exists, how it processes data in memory, and how to use Spark DataFrames for real world data cleaning and aggregation tasks. All code is written in PySpark and tested on a self created e commerce transaction dataset.

---

## Dataset Description

**Note:** No dataset was provided for this assignment. I created a custom dataset specifically designed to practise the Spark operations covered in the questions including null handling, duplicates, type casting, filtering, and aggregation.

### File: `Spark_assignment_dataset.csv`

| Property | Value |
|---|---|
| Total Rows | 1,220 |
| Total Columns | 14 |
| Domain | E-commerce Transactions |
| Time Period | January 2025 – May 2025 |

### Column Reference

| Column | Type | Description |
|---|---|---|
| `user_id` | Integer | Unique identifier for each user (range: 1–300) |
| `transaction_date` | String | Date of the transaction in `YYYY-MM-DD` format |
| `region` | String | Geographic region — `North`, `South`, `East`, `West` |
| `product_category` | String | Category of the purchased product — `Books`, `Clothing`, `Electronics`, `Furniture`, `Grocery` |
| `sale_amount` | Float | Final sale amount for the transaction (₹10.27 – ₹997.51) |
| `city` | String | City of purchase — Delhi, Mumbai, Kolkata, Pune, Chennai, Bengaluru, Hyderabad, Jaipur |
| `age` | Integer | Age of the user (16–60) |
| `subscription` | String | User subscription tier — `Free`, `Basic`, `Premium` |
| `raw_timestamp` | String | Full datetime of the transaction in `YYYY-MM-DD HH:mm:ss` format |
| `email` | String | User email address (intentionally contains ~93 nulls) |
| `username` | String | Username string (intentionally contains ~79 nulls) |
| `price` | Float | Unit price of the product (₹5.50 – ₹499.96; ~106 nulls) |
| `status` | String | Transaction status — `Pending`, `Completed`, `Cancelled` (~142 nulls) |
| `store_id` | Integer | Store identifier (101–105) |

### Intentional Data Quality Issues

The dataset was deliberately designed with the following imperfections to practise data cleaning in Spark:

| Issue | Column(s) Affected | Count |
|---|---|---|
| Null values | `email` | 93 |
| Null values | `username` | 79 |
| Null values | `price` | 106 |
| Null values | `status` | 142 |
| Duplicate `user_id` + `transaction_date` combinations | `user_id`, `transaction_date` | Present |

---
## Questions & Answers

---

### Q1 — Key Limitations of MapReduce vs Spark

**Q:** What are the key limitations of traditional MapReduce that make Spark a preferred choice for modern big data processing?

Traditional MapReduce writes intermediate results to disk after every map and reduce step. Since disk I/O is slow, this becomes a bottleneck especially for multi step jobs. The programming model is also rigid: all logic has to be expressed as map then reduce, which makes complex pipelines awkward to write. For iterative algorithms (like machine learning), MapReduce is particularly bad because the same data is reloaded from disk in every iteration.

Spark solves this by:
- Keeping data **in memory** across stages
- Providing a higher-level API (DataFrames, Spark SQL)
- Handling iterative processing efficiently with `.cache()` and `.persist()`

---

### Q2 — In-Memory Computing for Iterative ML

**Q:** Explain how Spark uses In-Memory Computing to speed up iterative machine learning algorithms compared to disk-based systems.

In MapReduce, every ML iteration reads data from disk and writes results back this repeated I/O cost dominates runtime. Spark loads the dataset into RAM once using `.cache()` or `.persist()` and reuses it across iterations. Since memory access is orders of magnitude faster than disk access, Spark can be up to 100× faster than MapReduce for iterative algorithms like gradient descent or k-means.

---

### Q3 — Removing Duplicates

**Q:** Write a code snippet to remove all duplicate rows based on `user_id` and `transaction_date`.

```python
df_Q3 = df.dropDuplicates(["user_id", "transaction_date"])

print("Rows before:", df.count())
print("Rows after dropDuplicates:", df_Q3.count())
print("Duplicates removed:", df.count() - df_Q3.count())
```

---

### Q4 — Filter + GroupBy Aggregation

**Q:** Filter for `region == 'West'`, then group by `product_category` and find the average `sale_amount`.

```python
df_Q4 = df.filter(col("region") == "West") \
          .groupBy("product_category") \
          .agg(avg("sale_amount").alias("avg_sale_amount"))

df_Q4.show()
```

Filter is applied first to reduce data volume before the groupBy, which avoids shuffling unnecessary rows.

---

### Q5 — `.na.drop()` vs `.na.fill()`

**Q:** What is the difference between `.na.drop()` and `.na.fill()`? Fill null values in `status` with `'Unknown'`.

| Method | Behaviour |
|---|---|
| `.na.drop()` | Removes entire rows that contain null values |
| `.na.fill()` | Keeps rows but replaces nulls with a specified default value |

Use `.drop()` when a row is unusable without that data. Use `.fill()` when you want to preserve the row with a sensible substitute.

```python
df_Q5 = df.na.fill("Unknown", subset=["status"])
df_Q5.select("status").show(10)
```

---

### Q6 — City Record Count (Filtered)

**Q:** Find the total count of records per city, but only for cities where count > 100.

```python
df_Q6 = df.groupBy("city") \
          .agg(count("*").alias("record_count")) \
          .filter(col("record_count") > 100)

df_Q6.show()
```

---

### Q7 — Immutability of Spark DataFrames

**Q:** How does immutability affect data cleaning operations like dropping or renaming columns?

Spark DataFrames are **immutable** — every transformation returns a new DataFrame; the original is never modified. This means you must **reassign** the result to a variable:

```python
df = df.drop("col")                          # must reassign
df = df.withColumnRenamed("old", "new")      # must reassign
```

If you forget to reassign, the change is lost. Immutability also makes Spark fault-tolerant: since the original data is never overwritten, Spark can recompute lost partitions from the lineage (DAG) at any point.

---

### Q8 — Multi-Condition Filter

**Q:** Filter for rows where `age` is between 18 and 30 (inclusive) and `subscription` is `'Premium'`.

```python
df_Q8 = df.filter((col("age") >= 18) & (col("age") <= 30) &
                  (col("subscription") == "Premium"))

df_Q8.select("user_id", "age", "subscription").show(10)
```

---

### Q9 — Why Handle Nulls Before Aggregation

**Q:** Why is it better to handle null values before performing mathematical aggregations?

Spark's aggregation functions (like `avg()`) silently **ignore nulls** by default. If a large portion of values are missing, the computed average can be significantly skewed without any warning. Counts can also be misleading depending on whether nulls are included. Cleaning nulls first (by dropping or filling) ensures that aggregations are based on consistent, intentional data — and that results are reproducible and trustworthy.

---

### Q10 — Timestamp Type Casting

**Q:** Cast `raw_timestamp` to `TimestampType` and rename it to `event_time`.

```python
df_Q10 = df.withColumn("raw_timestamp", col("raw_timestamp").cast(TimestampType())) \
           .withColumnRenamed("raw_timestamp", "event_time")

df_Q10.printSchema()
df_Q10.select("event_time").show(5)
```

**Note:** In this dataset, `raw_timestamp` was already stored in a clean `YYYY-MM-DD HH:mm:ss` format, so `inferSchema=True` had already auto-detected it as a timestamp. The cast worked for all 1,220 rows with zero nulls produced. In messier real-world data, inconsistent formats would cause some rows to silently become null after casting.

---

### Q11 — Shuffle and Wide Transformations

**Q:** Explain the Shuffle process during a `groupBy`. Why is it a wide transformation?

When Spark executes a `groupBy`, all records sharing the same key must be processed together — but they may be scattered across many nodes. The **Shuffle** is the process where Spark redistributes data across the network so all rows with the same key land on the same partition.

This makes `groupBy` a **wide transformation** because it creates a dependency across multiple partitions (a "wide" dependency). In contrast, narrow transformations like `filter` work on each partition independently with no network transfer.

The shuffle is typically the most expensive step in a Spark job due to network I/O and disk writes.

---

### Q12 — Null + Empty String Filter

**Q:** Remove rows where `email` is null OR `username` is an empty string.

```python
df_Q12 = df.filter(col("email").isNotNull() & (col("username") != ""))

print("Before:", df.count())
print("After:", df_Q12.count())
```

Keeping rows where email is not null **AND** username is not empty is logically equivalent to removing rows where email is null **OR** username is empty (De Morgan's Law).

---

### Q13 — Multiple Aggregations with `.agg()`

**Q:** Use `.agg()` to calculate min, max, and mean of the `price` column in a single call.

```python
df_Q13 = df.agg(
    min("price").alias("min_price"),
    max("price").alias("max_price"),
    mean("price").alias("mean_price")
)

df_Q13.show()
```

`.agg()` computes all statistics in one pass over the data, which is more efficient than running separate aggregation queries.

---

### Q14 — Risk of `inferSchema=True` with Messy Dates

**Q:** What is the risk of using `inferSchema=True` when source data contains inconsistent date formats?

Spark samples the data to infer types. If a date column has mixed formats (e.g., `2023-01-05`, `05/01/2023`, `01-05-2023`), Spark cannot resolve a single consistent pattern and typically falls back to reading the column as a plain `String`. This means:
- Date-specific operations (sort, range filter) either fail or produce wrong results
- Some values may parse to null silently

The safer approach is to either define the schema manually or read the column as a string and parse it explicitly using `to_timestamp()` with a known format string.

---

### Q15 — End-to-End Processing Pipeline

**Q:** Build a pipeline that: removes duplicates → fills null prices with 0 → groups by `store_id` to calculate total revenue.

```python
df_Q15 = df.dropDuplicates() \
           .na.fill(0, subset=["price"]) \
           .groupBy("store_id") \
           .agg(sum("price").alias("total_revenue"))

df_Q15.show()
```

**Pipeline breakdown:**
1. `dropDuplicates()` — removes fully duplicate rows
2. `.na.fill(0, subset=["price"])` — replaces null prices with 0 so they contribute ₹0 to revenue instead of being silently excluded
3. `.groupBy("store_id").agg(sum(...))` — aggregates total revenue per store across stores 101–105

---
