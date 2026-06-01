# E-Commerce Dataset — Data Exploration & Cleaning

A Python-based data exploration and preprocessing assignment using Pandas on an e-commerce dataset. The assignment includes data cleaning, missing value handling, filtering, duplicate detection, and feature engineering. Completed as a Week 1 assignment to strengthen foundational skills in Python, data analysis, and preprocessing workflows.


---

## Objective

Load, explore, clean, and preprocess an e-commerce CSV dataset using Pandas, then export the cleaned version for further analysis.

---

## Project Structure

```
Week_01_Assignment
   ├── E-com_solution.ipynb                      # Main Jupyter Notebook
   ├── E-com_solution_py.py                      # Python File
   ├── DataSet/
   │   └── e-commerce-dataset.csv         # Raw input dataset
   └── e-commerce-dataset-Final.csv       # Cleaned output dataset
```

---

## Steps Covered

### 1. Load Dataset
- Imported `pandas` and `numpy`
- Loaded the e-commerce CSV into a Pandas DataFrame

### 2. Data Exploration
- Inspected records using `head()`, `tail()`, and `sample()`
- Checked dataset dimensions with `shape`
- Listed column names and their data types using `columns` and `dtypes`

### 3. Handle Missing Values
- Identified null values using `isnull().sum()`
- Applied column-specific fill strategies:
  | Column | Fill Value |
  |---|---|
  | `seller_name` | `'Unknown Seller Name'` |
  | `what_customers_said` | `'No reviews from customer'` |
  | `videos` | `'No Url'` |
  | `variations` | `'[]'` |
  | `seller_information` | `'[]'` |
  | `discount` | `0` |

### 4. Data Filtering & Column Selection
- Filtered products with `rating > 3.9`
- Applied compound filter: `rating >= 4.3` AND `ratings_count >= 200`
- Filtered products with `discount >= 50%`
- Selected relevant column subsets for analysis

### 5. Duplicate Removal
- Checked for duplicate rows using `duplicated().sum()`
- Result: **No duplicates found** in the dataset

### 6. Derived Column — `total_amount`
- Cleaned the `final_price` column by stripping `₹`, commas, and quotes
- Converted `final_price` to `float`
- Created a new derived column: `total_amount = ratings_count × final_price`

### 7. Save Cleaned Dataset
- Exported the cleaned DataFrame to `e-commerce-dataset-Final.csv`

---

## Output

- **`e-commerce-dataset-Final.csv`** — cleaned dataset with missing values handled, `final_price` as numeric, and the new `total_amount` column added.

---

### Learning Outcomes

By completing this project, the following concepts were learned:

- Data loading using Pandas
- Data exploration techniques
- Handling missing values
- Data filtering and selection
- Duplicate detection
- Feature engineering
- Exporting processed datasets
