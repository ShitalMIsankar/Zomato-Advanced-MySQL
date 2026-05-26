-- Business Insights
-- ─────────────────────────────────────────────────────────────
-- Q1. Most Frequently Ordered Dishes by a Specific Customer
--     in the Last Year
-- ─────────────────────────────────────────────────────────────
SELECT
    customer_id,
    order_item,
    COUNT(*) AS order_count
FROM orders
WHERE order_date > DATE_SUB(CURDATE(), INTERVAL 360 DAY)
GROUP BY customer_id, order_item
ORDER BY customer_id, order_count DESC;


-- ─────────────────────────────────────────────────────────────
-- Q2. Popular Time Slots for Orders (2-Hour Intervals)
-- ─────────────────────────────────────────────────────────────
-- FLOOR arithmetic 
SELECT
    FLOOR(HOUR(order_time) / 2) * 2       AS start_hour,
    FLOOR(HOUR(order_time) / 2) * 2 + 2   AS end_hour,
    COUNT(*)                               AS order_count
FROM orders
GROUP BY start_hour, end_hour
ORDER BY order_count DESC;


-- ─────────────────────────────────────────────────────────────
-- Q3. Average Order Value for High-Volume Customers
--     (customers with more than 750 orders)
-- ─────────────────────────────────────────────────────────────
SELECT
    customer_id,
    AVG(total_amount) AS avg_order_value
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 750;


-- ─────────────────────────────────────────────────────────────
-- Q4. High-Value Customers (Total Spending > 100 000)
-- ─────────────────────────────────────────────────────────────
SELECT
    customer_id,
    SUM(total_amount) AS total_spending,
    AVG(total_amount) AS avg_order_value
FROM orders
GROUP BY customer_id
HAVING SUM(total_amount) > 100000
ORDER BY total_spending DESC;


-- ─────────────────────────────────────────────────────────────
-- Q5. Orders Without Delivery
--     Return: restaurant name, city, undelivered order count
-- ─────────────────────────────────────────────────────────────
SELECT
    r.restaurant_name,
    r.city,
    COUNT(o.order_id) AS undelivered_orders
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.order_id NOT IN (SELECT order_id FROM deliveries)
GROUP BY r.restaurant_name, r.city
ORDER BY undelivered_orders DESC;


-- ─────────────────────────────────────────────────────────────
-- Q6. Restaurant Revenue Ranking
--     Rank by total revenue from last year, within each city
-- ─────────────────────────────────────────────────────────────
SELECT
    r.city,
    r.restaurant_name,
    SUM(o.total_amount) AS total_revenue,
    RANK() OVER (
        PARTITION BY r.city
        ORDER BY SUM(o.total_amount) DESC
    ) AS revenue_rank
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.order_date > DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY r.city, r.restaurant_name
ORDER BY r.city, revenue_rank;


-- ─────────────────────────────────────────────────────────────
-- Q7. Identify the Most Popular Dish in Each City
-- ─────────────────────────────────────────────────────────────
WITH city_dish_counts AS (
    SELECT
        r.city,
        o.order_item,
        COUNT(*) AS order_count,
        RANK() OVER (
            PARTITION BY r.city
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.city, o.order_item
)
SELECT city, order_item, order_count
FROM city_dish_counts
WHERE rnk = 1
ORDER BY city;


-- ─────────────────────────────────────────────────────────────
-- Q8. Customer Churn – Find customers who haven't placed an
--     order in the last 6 months
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_id,
    c.customer_name,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING MAX(o.order_date) < DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    OR MAX(o.order_date) IS NULL
ORDER BY last_order_date;


-- ─────────────────────────────────────────────────────────────
-- Q9. Cancellation Rate Comparison – Current vs Previous Year
-- ─────────────────────────────────────────────────────────────
SELECT
    r.restaurant_name,
    YEAR(o.order_date) AS year,
    SUM(CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*) AS cancellation_rate
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE YEAR(o.order_date) IN (YEAR(CURDATE()), YEAR(CURDATE()) - 1)
GROUP BY r.restaurant_name, year
ORDER BY r.restaurant_name, year;


-- ─────────────────────────────────────────────────────────────
-- Q10. Rider Average Delivery Time
-- ─────────────────────────────────────────────────────────────
SELECT
    r.rider_name,
    AVG(
        TIME_TO_SEC(TIMEDIFF(d.delivery_time, o.order_time)) / 60
    ) AS avg_delivery_time_minutes
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
JOIN riders r ON d.rider_id = r.rider_id
WHERE d.delivery_status = 'Delivered'
GROUP BY r.rider_name
ORDER BY avg_delivery_time_minutes;


-- ─────────────────────────────────────────────────────────────
-- Q11. Monthly Restaurant Growth Ratio (v1 – simpler view)
-- ─────────────────────────────────────────────────────────────
SELECT
    r.restaurant_name,
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(d.delivery_id) AS delivered_orders,
    LAG(COUNT(d.delivery_id)) OVER (
        PARTITION BY r.restaurant_name
        ORDER BY DATE_FORMAT(o.order_date, '%Y-%m')
    ) AS prev_month_orders,
    ROUND(
        COUNT(d.delivery_id) * 1.0
        / NULLIF(LAG(COUNT(d.delivery_id)) OVER (
            PARTITION BY r.restaurant_name
            ORDER BY DATE_FORMAT(o.order_date, '%Y-%m')
        ), 0),
    2) AS growth_ratio
FROM orders o
JOIN deliveries d   ON o.order_id      = d.order_id
JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name, month
ORDER BY r.restaurant_name, month;


-- ─────────────────────────────────────────────────────────────
-- Q12. Customer Segmentation – Gold vs Silver
--      Gold  : total spending > AOV (average order value)
--      Silver: total spending <= AOV
-- ─────────────────────────────────────────────────────────────
WITH aov AS (
    SELECT AVG(total_amount) AS avg_order_value
    FROM orders
),
customer_spending AS (
    SELECT
        o.customer_id,
        SUM(o.total_amount) AS total_spending,
        COUNT(o.order_id)   AS total_orders
    FROM orders o
    GROUP BY o.customer_id
)
SELECT
    cs.customer_id,
    c.customer_name,
    CASE
        WHEN cs.total_spending > (SELECT avg_order_value FROM aov)
        THEN 'Gold'
        ELSE 'Silver'
    END AS customer_segment,
    cs.total_orders,
    cs.total_spending
FROM customer_spending cs
JOIN customers c ON cs.customer_id = c.customer_id
ORDER BY cs.total_spending DESC;


-- ─────────────────────────────────────────────────────────────
-- Q13. Rider Monthly Earnings
--      Riders earn 8% of the total order amount per delivery
-- ─────────────────────────────────────────────────────────────
SELECT
    r.rider_name,
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    SUM(o.total_amount) * 0.08         AS total_earnings
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
JOIN riders r ON d.rider_id = r.rider_id
GROUP BY r.rider_name, month
ORDER BY r.rider_name, month;


-- ─────────────────────────────────────────────────────────────
-- Q14. Rider Ratings Analysis
--      5 stars : delivery < 15 min
--      4 stars : delivery 15–20 min
--      3 stars : delivery > 20 min
-- ─────────────────────────────────────────────────────────────
SELECT
    r.rider_name,
    SUM(CASE
        WHEN TIME_TO_SEC(TIMEDIFF(d.delivery_time, o.order_time)) / 60 < 15
        THEN 1 ELSE 0 END) AS five_star,
    SUM(CASE
        WHEN TIME_TO_SEC(TIMEDIFF(d.delivery_time, o.order_time)) / 60
             BETWEEN 15 AND 20
        THEN 1 ELSE 0 END) AS four_star,
    SUM(CASE
        WHEN TIME_TO_SEC(TIMEDIFF(d.delivery_time, o.order_time)) / 60 > 20
        THEN 1 ELSE 0 END) AS three_star
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
JOIN riders r ON d.rider_id = r.rider_id
WHERE d.delivery_status = 'Delivered'
GROUP BY r.rider_name
ORDER BY r.rider_name;


-- ─────────────────────────────────────────────────────────────
-- Q15. Order Frequency by Day of Week
--      Identify peak day per restaurant
-- ─────────────────────────────────────────────────────────────
WITH daily_counts AS (
    SELECT
        r.restaurant_name,
        DAYNAME(o.order_date) AS day_of_week,
        DAYOFWEEK(o.order_date) AS dow_num,
        COUNT(o.order_id) AS order_count,
        RANK() OVER (
            PARTITION BY r.restaurant_name
            ORDER BY COUNT(o.order_id) DESC
        ) AS rnk
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_name, day_of_week, dow_num
)
SELECT restaurant_name, day_of_week AS peak_day, order_count
FROM daily_counts
WHERE rnk = 1
ORDER BY order_count DESC;


-- ─────────────────────────────────────────────────────────────
-- Q16. Customer Lifetime Value (CLV)
--      Total revenue generated by each customer
-- ─────────────────────────────────────────────────────────────
SELECT
    c.customer_name,
    COUNT(o.order_id)   AS total_orders,
    SUM(o.total_amount) AS lifetime_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY lifetime_value DESC;


-- ─────────────────────────────────────────────────────────────
-- Q17. Monthly Sales Trend with MoM Change
-- ─────────────────────────────────────────────────────────────
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(total_amount) AS total_sales,
    LAG(SUM(total_amount)) OVER (
        ORDER BY DATE_FORMAT(order_date, '%Y-%m')
    ) AS previous_month_sales,
    SUM(total_amount) - LAG(SUM(total_amount)) OVER (
        ORDER BY DATE_FORMAT(order_date, '%Y-%m')
    ) AS mom_change
FROM orders
GROUP BY month
ORDER BY month;


-- ─────────────────────────────────────────────────────────────
-- Q18. Rider Efficiency
--      Average delivery time – identify slowest & fastest riders
-- ─────────────────────────────────────────────────────────────
SELECT
    r.rider_name,
    AVG(
        TIME_TO_SEC(TIMEDIFF(d.delivery_time, o.order_time)) / 60
    ) AS avg_delivery_time_minutes
FROM deliveries d
JOIN orders o ON d.order_id = o.order_id
JOIN riders r ON d.rider_id = r.rider_id
WHERE d.delivery_status = 'Delivered'
GROUP BY r.rider_name
ORDER BY avg_delivery_time_minutes;


-- ─────────────────────────────────────────────────────────────
-- Q19. Order Item Popularity Over Time (Seasonal Spikes)
-- ─────────────────────────────────────────────────────────────
SELECT
    o.order_item,
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(o.order_id)                  AS order_count
FROM orders o
GROUP BY o.order_item, month
ORDER BY o.order_item, month;


-- ─────────────────────────────────────────────────────────────
-- Q20. Monthly Restaurant Growth Ratio (full version)
--      Growth ratio = current_month_deliveries / prev_month_deliveries
-- ─────────────────────────────────────────────────────────────
WITH monthly_deliveries AS (
    SELECT
        r.restaurant_name,
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        COUNT(d.delivery_id) AS delivered_orders
    FROM orders o
    JOIN deliveries d   ON o.order_id      = d.order_id
    JOIN restaurants r  ON o.restaurant_id = r.restaurant_id
    WHERE d.delivery_status = 'Delivered'
    GROUP BY r.restaurant_name, month
)
SELECT
    restaurant_name,
    month,
    delivered_orders,
    LAG(delivered_orders) OVER (
        PARTITION BY restaurant_name ORDER BY month
    ) AS prev_month,
    ROUND(
        delivered_orders * 1.0
        / NULLIF(LAG(delivered_orders) OVER (
            PARTITION BY restaurant_name ORDER BY month
        ), 0),
    2) AS growth_ratio
FROM monthly_deliveries
ORDER BY restaurant_name, month;

