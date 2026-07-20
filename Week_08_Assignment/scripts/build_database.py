"""
Loads the 4 cleaned CSVs into a single SQLite database file: ecommerce.db
Run this AFTER clean_data.py
"""

import sqlite3
import pandas as pd

CLEAN = "data/cleaned"
DB_PATH = "ecommerce.db"

tables = {
    "customers": r"C:\Users\user\Desktop\CELEBAL_INTERN\Week_08_Assignment\data\cleaned\clean_customers.csv",
    "orders": r"C:\Users\user\Desktop\CELEBAL_INTERN\Week_08_Assignment\data\cleaned\clean_orders.csv",
    "order_items": r"C:\Users\user\Desktop\CELEBAL_INTERN\Week_08_Assignment\data\cleaned\clean_order_items.csv",
    "products": r"C:\Users\user\Desktop\CELEBAL_INTERN\Week_08_Assignment\data\cleaned\clean_products.csv",
}

conn = sqlite3.connect(DB_PATH)

for table_name, csv_path in tables.items():
    df = pd.read_csv(csv_path)
    df.to_sql(table_name, conn, if_exists="replace", index=False)
    print(f"Loaded {len(df)} rows into '{table_name}'")

conn.close()
print(f"\nDatabase ready at {DB_PATH}")