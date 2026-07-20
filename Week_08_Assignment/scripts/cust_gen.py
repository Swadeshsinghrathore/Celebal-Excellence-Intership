import pandas as pd
import random
from faker import Faker

fake = Faker()

customers = []

for i in range(1, 501):
    customer_id = i
    customer_name = fake.name()
    email = fake.email()
    registration_date = fake.date_between(
        start_date="-3y",
        end_date="today"
    )
    customer_type = random.choice(
        ["REGULAR", "PREMIUM", "VIP"]
    )
    customers.append([
        customer_id,
        customer_name,
        email,
        registration_date,
        customer_type
    ])

for i in random.sample(range(500), 10):
    customers[i][2] = "invalidemail.com"
    
    customer_df = pd.DataFrame(
    customers,
    columns=[
        "customer_id",
        "customer_name",
        "email",
        "registration_date",
        "customer_type"
    ]
)

customer_df.to_csv(
    "customers.csv",
    index=False
)

print("customers.csv created")