# Zomato-Advanced-MySQL
Designed and analyzed a Zomato-style food delivery database using SQL on 10K+ orders across multiple cities. Solved 20 real-world business problems covering customer behavior, revenue trends, churn, and delivery performance. Utilized advanced SQL techniques including JOINs, CTEs, window functions, and aggregations to generate actionable insights.

The goal is to demonstrate strong SQL skills including:

Data cleaning
Joins & subqueries
Window functions
Aggregations
Business-driven insights
🗂️ Dataset Description

The dataset consists of 5 relational tables:

Table Name	Description
customers	Customer details with registration date
restaurants	Restaurant information across major Indian cities
riders	Delivery partner details
orders	Order-level transaction data
deliveries	Delivery status and rider mapping
📊 Data Summary
👥 Customers: 32 records
🛵 Riders: 34 records
🍴 Restaurants: 105 records (Mumbai, Delhi, Bangalore, Hyderabad, Chennai, Pune)
📦 Orders: 10,000 records (Jan 2023 – Aug 2024)
~85% Completed
~10% Cancelled
~5% Pending
🚚 Deliveries: 9,700 records
300 orders intentionally left undelivered (for analysis)
🛠️ Database Setup
CREATE DATABASE zomato_db;
USE zomato_db;

Tables Created:
restaurants
customers
riders
orders
deliveries
🧹 Data Cleaning Performed
Replaced NULL values in total_amount with 0
Standardized missing order_status → 'Pending'
Standardized missing delivery_status → 'Pending'
📈 Business Problems Solved

This project answers 20 real-world business questions, including:

🔹 Customer Analytics
Most frequently ordered dishes per customer
Customer churn (inactive users)
Customer segmentation (Gold vs Silver)
Customer Lifetime Value (CLV)
🔹 Order & Sales Insights
Popular order time slots (2-hour intervals)
Monthly sales trends & MoM growth
Seasonal item demand patterns
🔹 Restaurant Performance
Revenue ranking by city
Most popular dish per city
Peak order day per restaurant
Monthly growth ratio
🔹 Delivery & Rider Analysis
Orders without delivery
Rider average delivery time
Rider efficiency (fastest vs slowest)
Rider earnings (8% commission model)
Rider rating simulation based on delivery time
🔹 Operational Metrics
Cancellation rate comparison (YoY)
High-value customers
High-frequency customers
⚡ Key SQL Concepts Used
JOIN (INNER, LEFT)
GROUP BY & Aggregations
CASE WHEN
CTE (WITH clause)
WINDOW FUNCTIONS
RANK()
LAG()
Date Functions (DATE_FORMAT, DATE_SUB)
NULL Handling (COALESCE, NULLIF)
📊 Sample Insights
📌 Repeat customers contribute significantly to revenue
📌 Peak ordering hours fall in evening slots (18:00–22:00)
📌 Certain restaurants dominate revenue within their city
📌 Delivery efficiency directly impacts rider ratings
📌 A small % of customers drive high lifetime value
