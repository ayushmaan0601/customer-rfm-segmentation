-- Create a fresh database
CREATE DATABASE IF NOT EXISTS rfm_analysis;
USE rfm_analysis;

-- Create the transactions table
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id    VARCHAR(10) NOT NULL,
    purchase_date  DATE NOT NULL,
    amount         DECIMAL(10,2) NOT NULL
);
-- Should return 8000 rows
SELECT COUNT(*) FROM transactions;

-- Preview first 10 rows
SELECT * FROM transactions LIMIT 10;

USE rfm_analysis;

CREATE OR REPLACE VIEW rfm_raw AS
SELECT
    customer_id,
    
    -- Recency: days since last purchase (lower = better)
    DATEDIFF('2024-12-31', MAX(purchase_date)) AS recency_days,
    
    -- Frequency: total number of purchases
    COUNT(transaction_id) AS frequency,
    
    -- Monetary: total amount spent
    ROUND(SUM(amount), 2) AS monetary

FROM transactions
GROUP BY customer_id;

-- Preview it
SELECT * FROM rfm_raw LIMIT 10;

SELECT
    ROUND(AVG(recency_days), 1)  AS avg_recency,
    ROUND(AVG(frequency), 1)     AS avg_frequency,
    ROUND(AVG(monetary), 2)      AS avg_monetary,
    MIN(recency_days)            AS min_recency,
    MAX(recency_days)            AS max_recency,
    MIN(frequency)               AS min_frequency,
    MAX(frequency)               AS max_frequency,
    ROUND(MIN(monetary), 2)      AS min_monetary,
    ROUND(MAX(monetary), 2)      AS max_monetary
FROM rfm_raw;

CREATE OR REPLACE VIEW rfm_scores AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,

    -- Recency score: lower days = better = score 3
    CASE
        WHEN recency_days <= 30  THEN 3
        WHEN recency_days <= 90  THEN 2
        ELSE 1
    END AS r_score,

    -- Frequency score: higher purchases = better = score 3
    CASE
        WHEN frequency >= 12 THEN 3
        WHEN frequency >= 6  THEN 2
        ELSE 1
    END AS f_score,

    -- Monetary score: higher spend = better = score 3
    CASE
        WHEN monetary >= 3000 THEN 3
        WHEN monetary >= 1500 THEN 2
        ELSE 1
    END AS m_score

FROM rfm_raw;

SELECT * FROM rfm_scores LIMIT 10;

CREATE OR REPLACE VIEW rfm_segments AS
SELECT
    customer_id,
    r_score,
    f_score,
    m_score,
    recency_days,
    frequency,
    monetary,

    -- Combined RFM score as a string e.g. "3-3-3"
    CONCAT(r_score, '-', f_score, '-', m_score) AS rfm_combo,

    -- Segment labels
    CASE
        WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Champion'
        WHEN r_score = 3 AND f_score >= 2               THEN 'Loyal Customer'
        WHEN r_score = 3 AND f_score = 1               THEN 'New Customer'
        WHEN r_score = 2 AND f_score >= 2               THEN 'Potential Loyalist'
        WHEN r_score = 2 AND f_score = 1               THEN 'Needs Attention'
        WHEN r_score = 1 AND f_score >= 2               THEN 'At Risk'
        WHEN r_score = 1 AND f_score = 1 AND m_score >= 2 THEN 'Cant Lose Them'
        ELSE 'Lost'
    END AS segment

FROM rfm_scores;

SELECT * FROM rfm_segments LIMIT 10;

SELECT
    segment,
    COUNT(customer_id)        AS customer_count,
    ROUND(AVG(recency_days))  AS avg_recency_days,
    ROUND(AVG(frequency))     AS avg_purchases,
    ROUND(AVG(monetary), 2)   AS avg_spend
FROM rfm_segments
GROUP BY segment
ORDER BY customer_count DESC;

SELECT
    segment,
    COUNT(customer_id)                                    AS customers,
    ROUND(SUM(monetary), 2)                               AS total_revenue,
    ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary)) 
          OVER(), 1)                                      AS revenue_pct
FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;

SELECT
    segment,
    COUNT(customer_id)           AS customers,
    ROUND(AVG(monetary), 2)      AS avg_spend,
    ROUND(AVG(recency_days))     AS avg_days_since_purchase,
    ROUND(AVG(frequency))        AS avg_purchases,
    -- Revenue at risk if these customers are lost
    ROUND(SUM(monetary), 2)      AS total_revenue_at_risk
FROM rfm_segments
WHERE segment IN ('At Risk', 'Cant Lose Them', 'Needs Attention')
GROUP BY segment
ORDER BY total_revenue_at_risk DESC;


SELECT
    segment,
    COUNT(customer_id)       AS customers,
    ROUND(AVG(frequency))    AS avg_purchases,
    ROUND(AVG(monetary), 2)  AS avg_spend,
    ROUND(AVG(recency_days)) AS avg_recency_days
FROM rfm_segments
WHERE segment IN ('New Customer', 'Potential Loyalist')
GROUP BY segment;

SELECT
    DATE_FORMAT(purchase_date, '%Y-%m') AS month,
    COUNT(DISTINCT customer_id)          AS unique_customers,
    COUNT(transaction_id)                AS total_orders,
    ROUND(SUM(amount), 2)                AS monthly_revenue,
    ROUND(AVG(amount), 2)                AS avg_order_value
FROM transactions
GROUP BY month
ORDER BY month;

SELECT
    segment,
    COUNT(customer_id)                                        AS total_customers,
    ROUND(SUM(monetary), 2)                                   AS total_revenue,
    ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary))
          OVER(), 1)                                          AS revenue_share_pct,
    ROUND(AVG(monetary), 2)                                   AS avg_customer_value,
    ROUND(AVG(recency_days))                                  AS avg_recency_days,
    ROUND(AVG(frequency))                                     AS avg_purchases,

    -- Business action recommendation per segment
    CASE
        WHEN segment = 'Champion'          THEN 'Reward & retain — offer loyalty perks'
        WHEN segment = 'Loyal Customer'    THEN 'Upsell premium products'
        WHEN segment = 'Potential Loyalist' THEN 'Nurture with personalised offers'
        WHEN segment = 'New Customer'      THEN 'Onboard well — drive second purchase'
        WHEN segment = 'Needs Attention'   THEN 'Re-engage with targeted discounts'
        WHEN segment = 'At Risk'           THEN 'URGENT — win-back campaign needed'
        WHEN segment = 'Cant Lose Them'    THEN 'URGENT — personal outreach immediately'
        ELSE 'Low priority — minimal spend'
    END AS recommended_action

FROM rfm_segments
GROUP BY segment
ORDER BY total_revenue DESC;