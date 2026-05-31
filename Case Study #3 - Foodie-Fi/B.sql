-- B. Data Analysis Questions
-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(*)
FROM (SELECT DISTINCT customer_id FROM subscriptions);

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
WITH month_of_sub AS (
    SELECT EXTRACT(MONTH FROM start_date) AS month_of_trial
    FROM subscriptions
    WHERE plan_id = 0)
SELECT month_of_trial, COUNT(*) AS amount
FROM month_of_sub
GROUP BY month_of_trial
ORDER BY month_of_trial ASC;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
WITH subscription_type AS (
    SELECT plan_name
    FROM subscriptions JOIN plans
    ON subscriptions.plan_id = plans.plan_id
    WHERE EXTRACT(YEAR FROM start_date) > 2020
    ORDER BY customer_id)
SELECT plan_name, COUNT(*) AS amount
FROM subscription_type
GROUP BY plan_name
ORDER BY plan_name;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(DISTINCT customer_id) - COUNT(*) FILTER (WHERE plan_id = 4) AS num_of_customers, (COUNT(*) FILTER (WHERE plan_id = 4)::FLOAT / COUNT(DISTINCT customer_id)::FLOAT) * 100::FLOAT AS pct_of_churns
FROM subscriptions

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH ranked_table AS (
    SELECT customer_id, plan_id, RANK() OVER (PARTITION BY customer_id ORDER BY start_date) AS ranking
    FROM subscriptions),
filtered_table AS (
    SELECT customer_id, STRING_AGG(plan_id::TEXT, ', ') AS first_switch
    FROM ranked_table
    WHERE ranking = 1 OR ranking = 2
    GROUP BY customer_id)
SELECT ROUND((COUNT(*) FILTER (WHERE first_switch = '0, 4'))::FLOAT / COUNT(*)::FLOAT * 100) AS pct_churn
FROM filtered_table;

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH ranked_table AS (
    SELECT customer_id, plan_id, RANK() OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS ranking
    FROM subscriptions
    GROUP BY customer_id, plan_id, start_date),
filtered_table AS (
    SELECT customer_id, STRING_AGG(plan_id::TEXT, ', ') AS first_switch
    FROM ranked_table
    WHERE ranking = 1 or ranking = 2
    GROUP BY customer_id)
SELECT
    ROUND((COUNT(*) FILTER (WHERE first_switch = '0, 1')::FLOAT / COUNT(*)::FLOAT * 100)::NUMERIC, 1) AS pct_basic_monthly,
    ROUND((COUNT(*) FILTER (WHERE first_switch = '0, 2')::FLOAT / COUNT(*)::FLOAT * 100)::NUMERIC, 1) AS pct_pro_monthly,
    ROUND((COUNT(*) FILTER (WHERE first_switch = '0, 3')::FLOAT / COUNT(*)::FLOAT * 100)::NUMERIC, 1) AS pct_pro_annual,
    ROUND((COUNT(*) FILTER (WHERE first_switch = '0, 4')::FLOAT / COUNT(*)::FLOAT * 100)::NUMERIC, 1) AS pct_churn
FROM filtered_table;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH filtered_table AS (
    SELECT customer_id, plan_id, RANK() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS ranking
    FROM subscriptions
    WHERE start_date <= '2020-12-31'
    GROUP BY customer_id, plan_id, start_date)
SELECT
    ROUND((COUNT(*) FILTER (WHERE plan_id = 0)::FLOAT / COUNT(*)::FLOAT * 100)::NUMERIC, 1) AS pct_trial,
    ROUND((COUNT(*) FILTER (WHERE plan_id = 1)::FLOAT / COUNT(*)::FLOAT * 100)::NUMERIC, 1) AS pct_basic_monthly,
    ROUND((COUNT(*) FILTER (WHERE plan_id = 2)::FLOAT / COUNT(*)::FLOAT * 100)::NUMERIC, 1) AS pct_pro_monthly,
    ROUND((COUNT(*) FILTER (WHERE plan_id = 3)::FLOAT / COUNT(*)::FLOAT * 100)::NUMERIC, 1) AS pct_pro_annual,
    ROUND((COUNT(*) FILTER (WHERE plan_id = 4)::FLOAT / COUNT(*)::FLOAT * 100)::NUMERIC, 1) AS pct_churn
FROM filtered_table
WHERE ranking = 1;

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(*) AS num_of_annual
FROM subscriptions
WHERE start_date BETWEEN '2020-01-01' AND '2020-12-31' AND plan_id = 3;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH annual_users AS (
    SELECT subscriptions.customer_id AS customer_id, start_date
    FROM subscriptions RIGHT JOIN (SELECT customer_id FROM subscriptions WHERE plan_id = 3) AS annual_users
    ON subscriptions.customer_id = annual_users.customer_id
    WHERE plan_id = 0 OR plan_id = 3),
dates_difference AS (
    SELECT MAX(start_date)::DATE - MIN(start_date)::DATE AS days_to_annual
    FROM annual_users
    GROUP BY customer_id)
SELECT ROUND(AVG(days_to_annual))
FROM dates_difference;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)


-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH filtered_table AS (
    SELECT customer_id, plan_id, RANK() OVER (PARTITION BY customer_id ORDER BY start_date ASC) AS ranking
    FROM subscriptions
    WHERE start_date <= '2020-12-31'
    GROUP BY customer_id, plan_id, start_date),
pro_subs AS (
    SELECT customer_id, ranking
    FROM filtered_table
    WHERE plan_id = 2),
basic_subs AS (
    SELECT customer_id, ranking
    FROM filtered_table
    WHERE plan_id = 1),
matching_subs AS (
    SELECT pro_subs.customer_id AS customer_id, pro_subs.ranking AS pro_sub_date, basic_subs.ranking AS basic_subs_date
    FROM pro_subs INNER JOIN basic_subs
    ON pro_subs.customer_id = basic_subs.customer_id)
SELECT COUNT(*) AS downgrades
FROM matching_subs
WHERE basic_subs_date = pro_sub_date + 1;