import pandas as pd
import random
from faker import Faker

fake = Faker()
orders = []

status_list = [
    "PLACED",
    "SHIPPED",
    "DELIVERED",
    "CANCELLED",
    "RETURNED"
]

regions = [
    "NORTH",
    "SOUTH",
    "EAST",
    "WEST"
]
from datetime import datetime

for order_id in range(1, 501):

    customer_id = random.randint(1, 500)

    order_date = fake.date_time_between(
        start_date="-2y",
        end_date="now"
    )

    status = random.choice(status_list)

    region = random.choice(regions)

    orders.append([
        order_id,
        customer_id,
        order_date,
        status,
        region
    ])

for i in random.sample(range(500), 25):
    orders[i][1] = None

for i in random.sample(range(500), 15):

    date = orders[i][2]

    orders[i][2] = date.strftime("%d-%m-%Y %H:%M:%S")

orders_df = pd.DataFrame(
    orders,
    columns=[
        "order_id",
        "customer_id",
        "order_date",
        "status",
        "region_code"
    ]
)

orders_df.to_csv(
    "orders.csv",
    index=False
)

print("orders.csv created")