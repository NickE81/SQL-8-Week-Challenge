-- D. Pricing and Ratings
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
WITH pizzas_sold AS (
    SELECT pizza_id, COUNT(*) AS amount,
        CASE
            WHEN pizza_id = 1 THEN 12
            ELSE 10
        END price
    FROM customer_orders JOIN runner_orders
    ON customer_orders.order_id = runner_orders.order_id
    WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL
    GROUP BY pizza_id)
SELECT SUM(amount * price) AS total_cost
FROM pizzas_sold;

-- 2. What if there was an additional $1 charge for any pizza extras?
WITH pizzas_sold AS (
    SELECT 
        CASE
            WHEN pizza_id = 1 THEN 12
            ELSE 10
        END pizza_price,
        CARDINALITY(COALESCE(REGEXP_SPLIT_TO_ARRAY(NULLIF(NULLIF(extras, ''), 'null'), ', '), '{}'::text[])::int[]) AS extras
    FROM customer_orders JOIN runner_orders
    ON customer_orders.order_id = runner_orders.order_id
    WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL)
SELECT SUM(pizza_price + extras)
FROM pizzas_sold;
    -- Add cheese is $1 extra
WITH pizzas_sold AS (
    SELECT 
        CASE
            WHEN pizza_id = 1 THEN 12
            ELSE 10
        END pizza_price,
        COALESCE(REGEXP_SPLIT_TO_ARRAY(NULLIF(NULLIF(extras, ''), 'null'), ', '), '{}'::text[])::int[] AS extras
    FROM customer_orders JOIN runner_orders
    ON customer_orders.order_id = runner_orders.order_id
    WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL)
SELECT SUM(pizza_price + CARDINALITY(extras) + CARDINALITY(ARRAY_POSITIONS(extras, 4)))
FROM pizzas_sold;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
CREATE SCHEMA IF NOT EXISTS case_study2d
    CREATE TABLE IF NOT EXISTS case_study2d.runner_ratings (order_id int, rating int);

INSERT INTO case_study2d.runner_ratings (order_id, rating)
    VALUES (1, 4),
            (2, 5),
            (3, 4),
            (4, 3),
            (5, 1),
            (7, 4),
            (8, 3),
            (10, 2)

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
    -- customer_id
    -- order_id
    -- runner_id
    -- rating
    -- order_time
    -- pickup_time
    -- Time between order and pickup
    -- Delivery duration
    -- Average speed
    -- Total number of pizzas

WITH joined_table AS (
    SELECT
        customer_id,
        customer_orders.order_id AS order_id,
        runner_id,
        order_time,
        pickup_time::TIMESTAMP AS pickup_time,
        pickup_time::TIMESTAMP - order_time AS time_to_pickup,
        REGEXP_REPLACE(duration, '[^0-9.]', '', 'g')::INT AS delivery_duration,
        ROUND((REGEXP_REPLACE(distance, '[^0-9.]', '', 'g')::FLOAT / (REGEXP_REPLACE(duration, '[^0-9.]', '', 'g')::FLOAT / 60))::NUMERIC, 2) AS average_speed,
        COUNT(*) AS num_of_pizzas
    FROM customer_orders JOIN runner_orders
    ON customer_orders.order_id = runner_orders.order_id
    WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL
    GROUP BY customer_id, customer_orders.order_id, runner_id, order_time, pickup_time, time_to_pickup, delivery_duration, average_speed)

SELECT customer_id, joined_table.order_id AS order_id, runner_id, rating, order_time, pickup_time, time_to_pickup, delivery_duration, average_speed, num_of_pizzas
FROM joined_table JOIN case_study2d.runner_ratings
ON joined_table.order_id = case_study2d.runner_ratings.order_id;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
WITH prices_and_distances AS (
    SELECT customer_orders.order_id AS order_id, REGEXP_REPLACE(distance, '[^0-9.]', '', 'g')::FLOAT AS distance,
        CASE
            WHEN pizza_id = 1 THEN 12
            ELSE 10
        END pizza_price
    FROM customer_orders JOIN runner_orders
    ON customer_orders.order_id = runner_orders.order_id
    WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL),
total_prices AS (
    SELECT order_id, distance, SUM(pizza_price) AS total_price
    FROM prices_and_distances
    GROUP BY order_id, distance)
SELECT ROUND(SUM(total_price - (0.3 * distance))::NUMERIC, 2)
FROM total_prices;