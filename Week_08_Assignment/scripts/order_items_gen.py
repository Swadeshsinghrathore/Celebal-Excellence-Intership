import pandas as pd
import random
from faker import Faker

fake = Faker()
order_items = []

item_id = 1

for order_id in range(1, 501):

    product_id = random.randint(1, 500)

    quantity = random.randint(1, 5)

    unit_price = random.randint(200, 6000)

    discount_percent = random.randint(0, 100)

    order_items.append([
        item_id,
        order_id,
        product_id,
        quantity,
        unit_price,
        discount_percent
    ])

    item_id += 1
for i in random.sample(range(500), 15):
    order_items[i][3] = -abs(order_items[i][3])

order_items_df = pd.DataFrame(
    order_items,
    columns=[
        "item_id",
        "order_id",
        "product_id",
        "quantity",
        "unit_price",
        "discount_percent"
    ]
)

order_items_df.to_csv(
    "order_items.csv",
    index=False
)

print("order_items.csv created")

