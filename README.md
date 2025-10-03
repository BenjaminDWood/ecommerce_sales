## Read Me

Original dataset can be viewed [here](https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data)

### Project

A very messy collection of .csv files, three of which I selected as the most relevant for processing and analysis. Preprocessed in Python Pandas before exporting to SQL. Creation of multiple queries designed to answer common business questions, before a final visualisation of selected query results on Tableau.

### Files

e_commerce.ipynb: Jupyter notebook used for preprocessing the data, which mostly involved fixing data formats, dealing with null and blank records etc.

ecommerce_workbook.sql: The working version for query testing and figuring things out. I've left this in to "show my work", so to speak.

ecommerce.sql: A tidied format of the queries I wanted to achieve. Table of contents below.

### SQL file (ecommerce.sql)

1. Table creation and alteration
2. Stored Procedure: Find Order lookup
3. Stored Procedure: Customer Summary
4. Query: Top customers (by year + overall)
5. Query: Top Ranking Products & Categories
   i. Top Products Overall
   ii. Top Products Monthly
   iii. Top Categories Monthly
   iv. Top Categories Overall
6. Query: Top Citiies By Revenue
7. Query: Revenue Report (Domestic + International, Monthly)
8. Query: Customer Churn Report

Visualisation of selected data can be viewed on my [Tableau profile](https://public.tableau.com/app/profile/benjamin.wood8808/viz/EcommerceVisualisation/CustomersDashboard?publish=yes).
