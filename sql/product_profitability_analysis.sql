-- =====================================================
-- Retail Product & Profitability Analysis
-- Dataset: ~32K+ Orders | 3 Relational Tables
-- Author: Enos Mohod
-- =====================================================


-- =====================================================
-- 1️⃣ Revenue & Order Volume Analysis
-- =====================================================

-- Total Revenue per Product
WITH total_revenue AS (
    SELECT 
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.price_usd), 2) AS total_revenue
    FROM products p
    INNER JOIN order_items oi 
        ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name
)
SELECT *
FROM total_revenue
ORDER BY total_revenue DESC;


-- Total Orders per Product
SELECT 
    p.product_id,
    p.product_name,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM products p
INNER JOIN order_items oi 
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_orders DESC;



-- =====================================================
-- 2️⃣ Profitability & Margin Analysis
-- =====================================================

-- Total Profit per Product
SELECT 
    p.product_id,
    p.product_name,
    ROUND(SUM(oi.price_usd) - SUM(oi.cogs_usd), 2) AS total_profit
FROM products p
INNER JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_profit DESC;


-- Profit Margin (%) per Product
SELECT 
    p.product_id,
    p.product_name,
    ROUND(
        (SUM(oi.price_usd) - SUM(oi.cogs_usd)) 
        / SUM(oi.price_usd) * 100,
        2
    ) AS profit_margin_percentage
FROM products p
INNER JOIN order_items oi 
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY profit_margin_percentage DESC;


-- Cost % and Markup % per Product
SELECT 
    p.product_id,
    p.product_name,
    ROUND(SUM(oi.cogs_usd) / SUM(oi.price_usd) * 100, 2) AS cost_percentage,
    ROUND(
        (SUM(oi.price_usd) - SUM(oi.cogs_usd)) 
        / SUM(oi.cogs_usd) * 100,
        2
    ) AS markup_percentage
FROM products p 
INNER JOIN order_items oi 
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY markup_percentage DESC;



-- =====================================================
-- 3️⃣ Hero Product Ranking (Revenue + Profit + Markup)
-- =====================================================

WITH base_metrics AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.price_usd) AS total_revenue,
        SUM(oi.price_usd) - SUM(oi.cogs_usd) AS total_profit,
        ROUND(
            (SUM(oi.price_usd) - SUM(oi.cogs_usd)) 
            / SUM(oi.cogs_usd) * 100,
            2
        ) AS markup_percentage
    FROM products p
    INNER JOIN order_items oi 
        ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name
),
ranked_metrics AS (
    SELECT *,
        DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        DENSE_RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (ORDER BY markup_percentage DESC) AS markup_rank
    FROM base_metrics
)
SELECT *,
    (revenue_rank + profit_rank + markup_rank) AS hero_rank
FROM ranked_metrics
ORDER BY hero_rank ASC;



-- =====================================================
-- 4️⃣ Weekday Order Pattern Analysis
-- =====================================================

SELECT 
    EXTRACT(DOW FROM created_at) AS day_of_week,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY EXTRACT(DOW FROM created_at)
ORDER BY day_of_week;



-- =====================================================
-- 5️⃣ Product Pair Analysis (Frequently Bought Together)
-- =====================================================

SELECT
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    COUNT(*) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2
    ON oi1.order_id = oi2.order_id
   AND oi1.product_id < oi2.product_id
JOIN products p1 
    ON oi1.product_id = p1.product_id
JOIN products p2 
    ON oi2.product_id = p2.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC
LIMIT 20;
