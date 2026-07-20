
-- 1. Total revenue per category
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)), 2) AS total_revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;



-- 2. Top 10 customers by total order value
SELECT
    c.customer_id,
    c.customer_name,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)), 2) AS total_value
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_value DESC
LIMIT 10;


-- 3. Month-wise order count for the last 12 months
SELECT
    strftime('%Y-%m', order_date) AS month,
    COUNT(*) AS order_count
FROM orders
WHERE order_date >= date((SELECT MAX(order_date) FROM orders), '-12 months')
GROUP BY month
ORDER BY month;



-- 4. Customers who placed orders but never had any item delivered
SELECT DISTINCT c.customer_id, c.customer_name
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE c.customer_id NOT IN (
    SELECT customer_id FROM orders WHERE status = 'DELIVERED'
);


-- 5. Products that were ordered but had more returns than purchases
--    (a "return" = a row with negative quantity; a "purchase" = positive quantity)
SELECT
    p.product_id,
    p.product_name,
    SUM(CASE WHEN oi.quantity > 0 THEN oi.quantity ELSE 0 END) AS total_purchased,
    SUM(CASE WHEN oi.quantity < 0 THEN -oi.quantity ELSE 0 END) AS total_returned
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING total_returned > total_purchased;


-- 6. Return rate (returned items / total items) per category
SELECT
    p.category,
    SUM(CASE WHEN oi.quantity < 0 THEN -oi.quantity ELSE 0 END) AS returned_items,
    SUM(ABS(oi.quantity)) AS total_items,
    ROUND(
        1.0 * SUM(CASE WHEN oi.quantity < 0 THEN -oi.quantity ELSE 0 END)
        / SUM(ABS(oi.quantity)), 4
    ) AS return_rate
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY return_rate DESC;



-- 7. Running total of revenue per region, ordered by date
WITH daily_revenue AS (
    SELECT
        o.region_code,
        date(o.order_date) AS order_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS daily_revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.region_code, date(o.order_date)
)
SELECT
    region_code,
    order_date,
    ROUND(daily_revenue, 2) AS daily_revenue,
    ROUND(SUM(daily_revenue) OVER (
        PARTITION BY region_code ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS running_total
FROM daily_revenue
ORDER BY region_code, order_date;


-- 8. Rank products by total revenue within each category (DENSE_RANK, ties share rank)
WITH product_revenue AS (
    SELECT
        p.category,
        p.product_name,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS total_revenue
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_name
)
SELECT
    category,
    product_name,
    ROUND(total_revenue, 2) AS total_revenue,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) AS rank_in_category
FROM product_revenue
ORDER BY category, rank_in_category;


-- 9. Days between consecutive orders per customer (LAG), flag "At Risk" if avg gap > 30 days
WITH ordered AS (
    SELECT
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date
    FROM orders
    WHERE customer_id != -1   
),
gaps AS (
    SELECT
        customer_id,
        order_date,
        previous_order_date,
        CASE WHEN previous_order_date IS NOT NULL
             THEN julianday(order_date) - julianday(previous_order_date)
        END AS days_gap
    FROM ordered
)
SELECT
    g.customer_id,
    g.order_date,
    g.previous_order_date,
    ROUND(g.days_gap, 1) AS days_gap,
    CASE WHEN avg_gap.avg_days_gap > 30 THEN 'At Risk' ELSE 'Active' END AS risk_flag
FROM gaps g
JOIN (
    SELECT customer_id, AVG(julianday(order_date) - julianday(previous_order_date)) AS avg_days_gap
    FROM ordered
    WHERE previous_order_date IS NOT NULL
    GROUP BY customer_id
) avg_gap ON avg_gap.customer_id = g.customer_id
ORDER BY g.customer_id, g.order_date;


-- 10. Multi-level CTE: monthly revenue per customer -> category (High/Medium/Low) -> count per month
WITH monthly_revenue AS (
    SELECT
        o.customer_id,
        strftime('%Y-%m', o.order_date) AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.customer_id != -1
    GROUP BY o.customer_id, month
),
categorized AS (
    SELECT
        customer_id,
        month,
        revenue,
        CASE
            WHEN revenue > 10000 THEN 'High'
            WHEN revenue >= 5000 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_category
    FROM monthly_revenue
)
SELECT
    month,
    revenue_category,
    COUNT(*) AS customer_count
FROM categorized
GROUP BY month, revenue_category
ORDER BY month, revenue_category;


-- 11. NTILE quartiles based on customer lifetime value
WITH customer_value AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS total_value
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.customer_id != -1
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    ROUND(total_value, 2) AS total_value,
    NTILE(4) OVER (ORDER BY total_value DESC) AS quartile,
    CASE NTILE(4) OVER (ORDER BY total_value DESC)
        WHEN 1 THEN 'Platinum'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Bronze'
    END AS quartile_label
FROM customer_value
ORDER BY quartile, total_value DESC;


-- 12. Year-over-year revenue comparison per month
WITH monthly_revenue AS (
    SELECT
        CAST(strftime('%Y', o.order_date) AS INTEGER) AS year,
        CAST(strftime('%m', o.order_date) AS INTEGER) AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY year, month
)
SELECT
    cur.year,
    cur.month,
    ROUND(cur.revenue, 2) AS revenue,
    ROUND(prev.revenue, 2) AS prev_year_revenue,
    CASE
        WHEN prev.revenue IS NULL THEN NULL   -- no data to compare against
        WHEN prev.revenue = 0 THEN NULL
        ELSE ROUND((cur.revenue - prev.revenue) * 100.0 / prev.revenue, 2)
    END AS yoy_growth_percent
FROM monthly_revenue cur
LEFT JOIN monthly_revenue prev
    ON prev.year = cur.year - 1 AND prev.month = cur.month
ORDER BY cur.year, cur.month;


-- 13. First purchased category vs most recent purchased category, per customer
WITH customer_category_orders AS (
    SELECT
        o.customer_id,
        p.category,
        o.order_date,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date ASC)  AS rn_first,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date DESC) AS rn_last
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.customer_id != -1
)
SELECT
    f.customer_id,
    f.category AS first_category,
    l.category AS most_recent_category,
    CASE WHEN f.category != l.category THEN 'Yes' ELSE 'No' END AS category_shift
FROM (SELECT * FROM customer_category_orders WHERE rn_first = 1) f
JOIN (SELECT * FROM customer_category_orders WHERE rn_last = 1) l
    ON l.customer_id = f.customer_id
ORDER BY f.customer_id;


-- 14. Cumulative revenue distribution: % of total revenue from top N% of customers
WITH customer_value AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.customer_id != -1
    GROUP BY o.customer_id
),
ranked AS (
    SELECT
        customer_id,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue,
        SUM(revenue) OVER () AS grand_total
    FROM customer_value
)
SELECT
    customer_id,
    ROUND(revenue, 2) AS revenue,
    ROUND(cumulative_revenue, 2) AS cumulative_revenue,
    ROUND(cumulative_revenue * 100.0 / grand_total, 2) AS cumulative_percent
FROM ranked
ORDER BY revenue DESC;


-- 15. Cohort analysis: group customers by registration month, track ordering in month 0/1/2/3
WITH cohorts AS (
    SELECT
        customer_id,
        registration_date,
        strftime('%Y-%m', registration_date) AS cohort_month
    FROM customers
),
customer_orders AS (
    SELECT
        o.customer_id,
        c.cohort_month,
        -- how many months after registration did this order happen?
        (CAST(strftime('%Y', o.order_date) AS INTEGER) - CAST(strftime('%Y', c.registration_date) AS INTEGER)) * 12
        + (CAST(strftime('%m', o.order_date) AS INTEGER) - CAST(strftime('%m', c.registration_date) AS INTEGER)) AS month_number
    FROM orders o
    JOIN cohorts c ON c.customer_id = o.customer_id
    WHERE o.customer_id != -1
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS cohort_customers
    FROM cohorts
    GROUP BY cohort_month
)
SELECT
    co.cohort_month,
    cs.cohort_customers,
    COUNT(DISTINCT CASE WHEN co.month_number = 0 THEN co.customer_id END) AS ordered_month_0,
    COUNT(DISTINCT CASE WHEN co.month_number = 1 THEN co.customer_id END) AS ordered_month_1,
    COUNT(DISTINCT CASE WHEN co.month_number = 2 THEN co.customer_id END) AS ordered_month_2,
    COUNT(DISTINCT CASE WHEN co.month_number = 3 THEN co.customer_id END) AS ordered_month_3,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN co.month_number = 1 THEN co.customer_id END) / cs.cohort_customers, 1) AS retention_month_1_pct
FROM customer_orders co
JOIN cohort_size cs ON cs.cohort_month = co.cohort_month
GROUP BY co.cohort_month, cs.cohort_customers
ORDER BY co.cohort_month;


-- 16. Products frequently bought together (self-join on order_id, A-B pair appears once)
SELECT
    pa.product_name AS product_a,
    pb.product_name AS product_b,
    COUNT(*) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2
    ON oi1.order_id = oi2.order_id
    AND oi1.product_id < oi2.product_id      -- ensures each pair counted once (A<B, no A-A)
JOIN products pa ON pa.product_id = oi1.product_id
JOIN products pb ON pb.product_id = oi2.product_id
GROUP BY pa.product_name, pb.product_name
ORDER BY times_bought_together DESC;
