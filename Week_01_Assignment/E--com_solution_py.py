### Objective Of Week 1 Assignment :-
# Learn Python basics and perform basic data exploration and cleaning using Pandas. Steps:

# 1- Load a CSV dataset into a Pandas DataFrame.

# 2- Explore data (head/tail, shape, columns, data types).

# 3- Handle missing values (identify, fill/drop).

# 4- Perform basic operations (filter rows, select columns).

# 5- Remove duplicates.

# 6- Create a derived column (total_amount = price * quantity).

# 7- Save the cleaned dataset as a new CSV file.

# Output: Jupyter Notebook (.ipynb) + cleaned CSV + brief summary.

## 1.We are loading the CSV dataset into a Pandas DataFrame for data analysis and preprocessing.
import pandas as pd
import numpy as np

ecom_data = pd.read_csv("DataSet/e-commerce-dataset.csv")
ecom_data

## 2.Now, we are going to explore the dataset by examining its head and tail records, shape, column names, sample, and data types
ecom_data.head()

ecom_data.tail()

ecom_data.head(1)

ecom_data.tail(1)

ecom_data.sample()

ecom_data.sample(2)

ecom_data.shape

ecom_data.columns

ecom_data.dtypes


## 3.Now, we are going to handle missing values by identifying them and applying appropriate techniques such as filling or dropping the missing data.
ecom_data.head()

ecom_data.isnull().sum()

ecom_data[['discount','what_customers_said',]]

ecom_data['seller_name'].fillna('Unknown Seller Name',inplace=True)

ecom_data['what_customers_said'].fillna('No reviews from customer',inplace=True)

ecom_data['videos'].fillna('No Url',inplace=True)

ecom_data['variations'].fillna('[]',inplace=True)

ecom_data['seller_information'].fillna('[]',inplace=True)

ecom_data['discount'].fillna(0,inplace=True)

ecom_data.isnull().sum()

## 4.Now, we are going to perform basic data operations such as filtering rows and selecting specific columns from the dataset.
ecom_data[ecom_data['rating']>3.9]

ecom_data[(ecom_data['rating']>=4.3) & (ecom_data['ratings_count']>=200)]

ecom_data[(ecom_data['rating']>=4.3) & (ecom_data['ratings_count']>=200)].shape

ecom_data[ecom_data['discount']>=50]

ecom_data[['product_id', 'title', 'category', 'rating', 'ratings_count']]

ecom_data[['product_id', 'title', 'seller_name', 'seller_information']]

ecom_data[['product_id', 'title','best_offer', 'more_offers']]


## 5.Now, we are going to identify and remove duplicate records from the dataset.
ecom_data.duplicated().sum()
#### No duplicate data was found in the dataset.


## 6.Now, we are going to create a derived column, total_amount, by multiplying the price and quantity columns.
ecom_data.head()

ecom_data['final_price'] = ecom_data['final_price'].str.replace('[₹]','',regex=True)

ecom_data['final_price'] = ecom_data['final_price'].str.replace('[,]','',regex=True)

ecom_data['final_price'] = ecom_data['final_price'].str.replace('["]','',regex=True)

ecom_data['final_price'] = ecom_data['final_price'].astype(float)

ecom_data['final_price']

ecom_data.dtypes

ecom_data['total_amount'] = ecom_data['ratings_count'] * ecom_data['final_price']

ecom_data.sample()

ecom_data

## 7.Finally, we are going to save the cleaned dataset as a new CSV file for further analysis and future use.
ecom_data.to_csv('e-commerce-dataset-Final.csv', index=False)

print("CSV file saved successfully.")
