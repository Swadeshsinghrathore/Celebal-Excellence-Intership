import pandas as pd
import random
from faker import Faker

fake = Faker()
products = []

categories = {
    "Electronics": ["Laptop", "Mobile", "Headphones", "Keyboard", "Mouse"],
    "Clothing": ["T-Shirt", "Jeans", "Jacket", "Shoes", "Shirt"],
    "Home": ["Chair", "Table", "Fan", "Sofa", "Lamp"],
    "Books": ["Python Book", "SQL Book", "AI Book", "ML Book", "Math Book"]
}
product_id = 1

for category, items in categories.items():

    for i in range(125):

        product_name = random.choice(items)

        subcategory = product_name

        cost_price = random.randint(100, 5000)

        products.append([
            product_id,
            product_name,
            category,
            subcategory,
            cost_price
        ])

        product_id += 1

for i in random.sample(range(500), 20):
    products[i][1] = "  " + products[i][1].upper() + "  "

product_df = pd.DataFrame(
    products,
    columns=[
        "product_id",
        "product_name",
        "category",
        "subcategory",
        "cost_price"
    ]
)

product_df.to_csv("products.csv", index=False)

print("products.csv created")