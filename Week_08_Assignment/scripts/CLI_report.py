import sqlite3
from datetime import datetime, timedelta

DB_PATH = "ecommerce.db"


def get_period_stats(conn, start_date, end_date):
    """Returns (total_orders, total_revenue, unique_customers) for a date range."""
    query = """
        SELECT
            COUNT(DISTINCT o.order_id)   AS total_orders,
            COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)), 0) AS total_revenue,
            COUNT(DISTINCT o.customer_id) AS unique_customers
        FROM orders o
        JOIN order_items oi ON oi.order_id = o.order_id
        WHERE date(o.order_date) >= date(?) AND date(o.order_date) <= date(?)
    """
    row = conn.execute(query, (start_date, end_date)).fetchone()
    return row  # (total_orders, total_revenue, unique_customers)


def get_top_products(conn, start_date, end_date, limit=3):
    """Returns top N products by revenue for a date range."""
    query = """
        SELECT
            p.product_name,
            SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS revenue
        FROM orders o
        JOIN order_items oi ON oi.order_id = o.order_id
        JOIN products p ON p.product_id = oi.product_id
        WHERE date(o.order_date) >= date(?) AND date(o.order_date) <= date(?)
        GROUP BY p.product_name
        ORDER BY revenue DESC
        LIMIT ?
    """
    return conn.execute(query, (start_date, end_date, limit)).fetchall()


def previous_period(start_date, end_date):
    """Given a start/end date, returns the immediately preceding period of the same length."""
    start = datetime.strptime(start_date, "%Y-%m-%d")
    end = datetime.strptime(end_date, "%Y-%m-%d")
    length = (end - start).days + 1  # inclusive length in days

    prev_end = start - timedelta(days=1)
    prev_start = prev_end - timedelta(days=length - 1)
    return prev_start.strftime("%Y-%m-%d"), prev_end.strftime("%Y-%m-%d")


def pct_change(current, previous):
    if previous == 0:
        return None  # avoid divide-by-zero; nothing to compare against
    return round((current - previous) * 100.0 / previous, 2)


def generate_report(report_type, start_date, end_date):
    conn = sqlite3.connect(DB_PATH)

    orders, revenue, customers = get_period_stats(conn, start_date, end_date)
    top_products = get_top_products(conn, start_date, end_date)

    prev_start, prev_end = previous_period(start_date, end_date)
    prev_orders, prev_revenue, prev_customers = get_period_stats(conn, prev_start, prev_end)

    print("\n" + "=" * 50)
    print(f"{report_type.upper()} REPORT: {start_date} to {end_date}")
    print("=" * 50)
    print(f"Total Orders      : {orders}")
    print(f"Total Revenue     : {round(revenue, 2)}")
    print(f"Unique Customers  : {customers}")

    print("\nTop 3 Products:")
    if top_products:
        for i, (name, rev) in enumerate(top_products, start=1):
            print(f"  {i}. {name} - {round(rev, 2)}")
    else:
        print("  No sales in this period.")

    print(f"\nComparison with previous period ({prev_start} to {prev_end}):")
    order_change = pct_change(orders, prev_orders)
    revenue_change = pct_change(revenue, prev_revenue)
    print(f"  Orders change : {order_change}%" if order_change is not None else "  Orders change : N/A (no previous data)")
    print(f"  Revenue change: {revenue_change}%" if revenue_change is not None else "  Revenue change: N/A (no previous data)")

    conn.close()


def main():
    print("=== E-Commerce Report Generator ===")
    report_type = input("Report type (daily/weekly/monthly): ").strip().lower()
    while report_type not in ("daily", "weekly", "monthly"):
        report_type = input("Please enter daily, weekly, or monthly: ").strip().lower()

    start_date = input("Start date (YYYY-MM-DD): ").strip()
    end_date = input("End date (YYYY-MM-DD): ").strip()

    generate_report(report_type, start_date, end_date)


if __name__ == "__main__":
    main()