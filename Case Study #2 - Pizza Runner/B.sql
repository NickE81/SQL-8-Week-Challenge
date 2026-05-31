-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT FLOOR((EXTRACT(DOY FROM registration_date) - EXTRACT(DOY FROM TIMESTAMP '2021-01-01')) / 7) + 1::INTEGER AS week, COUNT(*) AS registered
FROM runners
GROUP BY week
ORDER BY week;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT runner_id, AVG(pickup_length) AS avg_pickup_length
FROM
	(SELECT DISTINCT customer_orders.order_id, runner_id, (EXTRACT(EPOCH FROM pickup_time::TIMESTAMP) - EXTRACT(EPOCH FROM order_time)) / 60 AS pickup_length
	FROM customer_orders JOIN runner_orders
	ON customer_orders.order_id = runner_orders.order_id
	WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL)
GROUP BY runner_id
ORDER BY runner_id;
	
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT pizzas, AVG(duration)
FROM
	(SELECT customer_orders.order_id AS order_id, COUNT(*) as pizzas, REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::INTEGER AS duration
	FROM customer_orders JOIN runner_orders
	ON customer_orders.order_id = runner_orders.order_id
	WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL
	GROUP BY customer_orders.order_id, duration)
GROUP BY pizzas;
-- There doesn't appear to be based on the average deliveruy duration by number of pizzas

-- 4. What was the average distance travelled for each customer?
SELECT customer_id, AVG(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g')::FLOAT) AS avg_distance
FROM customer_orders JOIN runner_orders
ON customer_orders.order_id = runner_orders.order_id
WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL
GROUP BY customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::INTEGER) - MIN(REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::INTEGER) AS difference
FROM runner_orders
WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, AVG((REGEXP_REPLACE(distance, '[^0-9.]', '', 'g')::FLOAT) / ((REGEXP_REPLACE(duration, '[^0-9]', '', 'g')::FLOAT) / 60)) AS avg_speed
FROM runner_orders
WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL
GROUP BY runner_id;
-- Runner 2 has a significatly faster average speed than the other two

-- 7. What is the successful delivery percentage for each runner?
SELECT runner_id, AVG(completed) * 100::INTEGER AS completed_pct
FROM
	(SELECT runner_id,
		CASE
			WHEN NULLIF(NULLIF(cancellation, ''), 'null') IS NULL
				THEN 1
			ELSE 0
		END completed
	FROM runner_orders)
GROUP BY runner_id;