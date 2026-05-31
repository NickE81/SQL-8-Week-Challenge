-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
WITH joined_table AS
    (SELECT customer_id, plan_name, start_date
    FROM subscriptions JOIN plans
    ON subscriptions.plan_id = plans.plan_id
    WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19)),
ranked_table AS
    (SELECT customer_id, plan_name, start_date,
        RANK() OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS ranking
    FROM joined_table
    GROUP BY customer_id, plan_name, start_date),
history_table AS
    (SELECT customer_id,
        CASE
            WHEN ranking = 1 THEN CONCAT('started a ', plan_name, ' subscription on ', start_date)
            ELSE CONCAT(', switched to ', plan_name, ' on ', start_date)
        END order_history
    FROM ranked_table)
    
SELECT CONCAT('Customer ', customer_id, ' ', STRING_AGG(order_history, ''))
FROM history_table
GROUP BY customer_id;