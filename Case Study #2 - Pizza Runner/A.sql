-- A. Pizza Metrics
-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS pizzas_sold
FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(*) AS unique_orders
FROM
	(SELECT DISTINCT pizza_id, NULLIF(NULLIF(exclusions, ''), 'null'), NULLIF(NULLIF(extras, ''), 'null') FROM customer_orders);

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(*) AS orders_delivered
FROM runner_orders
WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT pizza_id, COUNT(*) AS pizzas_delivered
FROM customer_orders JOIN runner_orders
ON customer_orders.order_id = runner_orders.order_id
WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL
GROUP BY pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_name, COUNT(*) AS pizzas_ordered
FROM customer_orders JOIN pizza_names
ON customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_id, pizza_name
ORDER BY customer_id, pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT COUNT(*) AS max_pizzas_delivered
FROM customer_orders JOIN runner_orders
ON customer_orders.order_id = runner_orders.order_id
WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL
GROUP BY customer_orders.order_id
ORDER BY COUNT(*) DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id, SUM(change) AS changed, SUM(no_change) AS no_change
FROM
	(SELECT customer_id,
		CASE
			WHEN NULLIF(NULLIF(exclusions, ''), 'null') IS NOT NULL OR NULLIF(NULLIF(extras, ''), 'null') IS NOT NULL
				THEN 1
			ELSE 0
		END change,
		CASE
			WHEN NULLIF(NULLIF(exclusions, ''), 'null') IS NULL AND NULLIF(NULLIF(extras, ''), 'null') IS NULL
				THEN 1
			ELSE 0
		END no_change
	FROM customer_orders JOIN runner_orders
	ON customer_orders.order_id = runner_orders.order_id
	WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL)
GROUP BY customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) AS pizzas_w_both
FROM customer_orders JOIN runner_orders
ON customer_orders.order_id = runner_orders.order_id
WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL AND NULLIF(NULLIF(exclusions, ''), 'null') IS NOT NULL AND NULLIF(NULLIF(extras, ''), 'null') IS NOT NULL;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time) AS hour_of_day, COUNT(*) AS total_pizzas
FROM customer_orders
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY hour_of_day;

-- 10. What was the volume of orders for each day of the week?
SELECT EXTRACT(DOW FROM order_time) AS day_of_week, COUNT(*) AS total_pizzas
FROM customer_orders
GROUP BY EXTRACT(DOW FROM order_time)
ORDER BY EXTRACT(DOW FROM order_time);