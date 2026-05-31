-- C. Challenge Payment Question
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

    -- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
    -- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
    -- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
    -- once a customer churns they will no longer make payments

WITH current_table AS (
    SELECT customer_id, plan_id, start_date, RANK() OVER (PARTITION BY customer_id ORDER BY start_date) AS ranking
    FROM subscriptions
    WHERE start_date <= '2020-12-31'
    GROUP BY customer_id, plan_id, start_date),
next_table AS (
    SELECT *
    FROM current_table),
paired_table AS (
    SELECT current_table.customer_id AS customer_id, current_table.plan_id AS plan_id, current_table.start_date AS start_date, next_table.start_date AS next_sub_date
    FROM current_table LEFT JOIN next_table
    ON current_table.customer_id = next_table.customer_id
    WHERE next_table.ranking = current_table.ranking + 1 OR (current_table.ranking = (SELECT MAX(ranking) FROM next_table WHERE current_table.customer_id = next_table.customer_id) AND current_table.ranking = next_table.ranking)),
next_dates_adjusted AS (
    SELECT
        customer_id,
        plan_id,
        CASE
            WHEN plan_id IN (0, 1, 2, 4) THEN '1 month'::INTERVAL
            ELSE '1 year'::INTERVAL
        END payment_period,
        start_date,
        CASE
            WHEN next_sub_date = start_date THEN '2020-12-31'
            ELSE next_sub_date
        END next_sub_date
    FROM paired_table),
series_generated AS (
    SELECT customer_id, plan_id, payment_period, GENERATE_SERIES(start_date, next_sub_date - INTERVAL '1 day', payment_period)::DATE AS payment_date
    FROM next_dates_adjusted),
ranked_orders AS (    
    SELECT customer_id, plan_id, payment_date, RANK() OVER (PARTITION BY customer_id ORDER BY payment_date) AS payment_order
    FROM series_generated
    WHERE plan_id NOT IN (0, 4)
    GROUP BY customer_id, plan_id, payment_date),
ranked_orders_duplicate AS (
    SELECT *
    FROM ranked_orders)
SELECT customer_id, ranked_orders.plan_id AS plan_id, plan_name,
    CASE
        WHEN ranked_orders.plan_id = 3
            AND (SELECT plan_id FROM ranked_orders_duplicate WHERE ranked_orders.customer_id = ranked_orders_duplicate.customer_id AND ranked_orders.payment_order = ranked_orders_duplicate.payment_order + 1) = 2
            AND payment_date BETWEEN
                                (SELECT payment_date FROM ranked_orders_duplicate WHERE ranked_orders.customer_id = ranked_orders_duplicate.customer_id AND ranked_orders.payment_order = ranked_orders_duplicate.payment_order + 1) AND
                                (SELECT payment_date FROM ranked_orders_duplicate WHERE ranked_orders.customer_id = ranked_orders_duplicate.customer_id AND ranked_orders.payment_order = ranked_orders_duplicate.payment_order + 1) + INTERVAL '1 month'
            THEN ((SELECT payment_date FROM ranked_orders_duplicate WHERE ranked_orders.customer_id = ranked_orders_duplicate.customer_id AND ranked_orders.payment_order = ranked_orders_duplicate.payment_order + 1) + INTERVAL '1 month')::DATE
        ELSE payment_date::DATE
    END payment_date,
    CASE
        WHEN ranked_orders.plan_id = 3 AND (SELECT plan_id FROM ranked_orders_duplicate WHERE ranked_orders.customer_id = ranked_orders_duplicate.customer_id AND ranked_orders.payment_order = ranked_orders_duplicate.payment_order + 1) = 1 THEN 189.10
        WHEN ranked_orders.plan_id = 2 AND (SELECT plan_id FROM ranked_orders_duplicate WHERE ranked_orders.customer_id = ranked_orders_duplicate.customer_id AND ranked_orders.payment_order = ranked_orders_duplicate.payment_order + 1) = 1 THEN 10.00
        WHEN ranked_orders.plan_id = 3 THEN 199.00
        WHEN ranked_orders.plan_id = 2 THEN 19.90
        WHEN ranked_orders.plan_id = 1 THEN 9.90
        ELSE 0
    END amount,
    payment_order
FROM ranked_orders JOIN plans
ON ranked_orders.plan_id = plans.plan_id
ORDER BY customer_id, payment_order;