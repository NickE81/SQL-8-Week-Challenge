-- C. Ingredient Optimisation
-- 1. What are the standard ingredients for each pizza?
SELECT pizza_id, STRING_AGG(topping_name, ', ') AS toppings
FROM
    (SELECT pizza_id, UNNEST(REGEXP_SPLIT_TO_ARRAY(toppings, ', '))::INTEGER AS topping_id
    FROM pizza_recipes
    ORDER BY pizza_id) AS pizza_recipes
JOIN pizza_toppings
ON pizza_recipes.topping_id = pizza_toppings.topping_id
GROUP BY pizza_id
ORDER BY pizza_id;

-- 2. What was the most commonly added extra?
SELECT extra, COUNT(*) AS occurances
FROM
    (SELECT UNNEST(REGEXP_SPLIT_TO_ARRAY(NULLIF(NULLIF(extras, ''), 'null'), ', ')) AS extra
    FROM customer_orders)
WHERE extra IS NOT NULL
GROUP BY extra
ORDER BY extra;

-- 3. What was the most common exclusion?
SELECT exclusion, COUNT(*) AS occurances
FROM
    (SELECT UNNEST(REGEXP_SPLIT_TO_ARRAY(NULLIF(NULLIF(exclusions, ''), 'null'), ', ')) AS exclusion
    FROM customer_orders)
WHERE exclusion IS NOT NULL
GROUP BY exclusion
ORDER BY exclusion;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
	-- Meat Lovers
	-- Meat Lovers - Exclude Beef
	-- Meat Lovers - Extra Bacon
	-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT
    CASE
        WHEN exclusions IS NULL AND extras IS NULL
            THEN CONCAT('-- ', pizza_name)
        WHEN exclusions IS NULL AND extras IS NOT NULL
            THEN CONCAT('-- ', pizza_name, ' - Extra ', extras)
        WHEN exclusions IS NOT NULL AND extras IS NULL
            THEN CONCAT('-- ', pizza_name, ' - Exclude ', exclusions)
        ELSE CONCAT('-- ', pizza_name, ' - Exclude ', extras, ' - Extra ', exclusions)
    END pizza_order
FROM
    (SELECT pizza_name, STRING_AGG(topping_name, ', ') AS exclusions, extras
    FROM
        (SELECT pizza_num, pizza_name, UNNEST(exclusions) AS exclusions, STRING_AGG(topping_name, ', ') AS extras
        FROM
            (SELECT ROW_NUMBER() OVER (ORDER BY order_id, customer_orders.pizza_id) AS pizza_num, pizza_name,
                REGEXP_SPLIT_TO_ARRAY(COALESCE(REPLACE(exclusions, 'null', ''), ''), ', ') AS exclusions,
                UNNEST(REGEXP_SPLIT_TO_ARRAY(COALESCE(REPLACE(extras, 'null', ''), ''), ', ')) AS extras
            FROM customer_orders JOIN pizza_names
            ON customer_orders.pizza_id = pizza_names.pizza_id
            ORDER BY pizza_num)
        LEFT JOIN pizza_toppings
        ON extras = topping_id::TEXT
        GROUP BY pizza_num, pizza_name, exclusions
        ORDER BY pizza_num)
    LEFT JOIN pizza_toppings
    ON exclusions = topping_id::TEXT
    GROUP BY pizza_num, pizza_name, extras
    ORDER BY pizza_num);

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
	-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
SELECT CONCAT(pizza_name, ': ', toppings) AS pizza_details
FROM
    (SELECT pizza_num, pizza_name, STRING_AGG(topping, ', ') AS toppings 
    FROM
        (SELECT pizza_num, pizza_name,
            CASE WHEN occurances = 2
                THEN CONCAT('2x', topping_name)
            ELSE topping_name
        END topping
        FROM
            (SELECT pizza_num, pizza_name, topping_name, COUNT(*) AS occurances
            FROM
                (SELECT pizza_num, pizza_name, UNNEST(toppings) AS topping
                FROM
                    (SELECT ROW_NUMBER() OVER (ORDER BY order_id) AS pizza_num, order_id, pizza_name, toppings
                    FROM
                        (SELECT order_id, customer_orders.pizza_id,
                            SORT((REGEXP_SPLIT_TO_ARRAY(toppings, ', ')::int[]
                            - COALESCE(REGEXP_SPLIT_TO_ARRAY(NULLIF(NULLIF(exclusions, ''), 'null'), ', '), '{}'::text[])::int[])
                            || REGEXP_SPLIT_TO_ARRAY(NULLIF(NULLIF(extras, ''), 'null'), ', ')::int[]) AS toppings
                        FROM customer_orders JOIN pizza_recipes
                        ON customer_orders.pizza_id = pizza_recipes.pizza_id
                        ORDER BY order_id, customer_orders.pizza_id) AS pizza_orders
                    JOIN pizza_names
                    ON pizza_orders.pizza_id = pizza_names.pizza_id
                    ORDER BY pizza_num)) AS pizzas_ordered
            LEFT JOIN pizza_toppings
            ON topping = pizza_toppings.topping_id
            GROUP BY pizza_num, pizza_name, topping_name
            ORDER BY pizza_num, topping_name))
    GROUP BY pizza_num, pizza_name);

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
SELECT topping_name, COUNT(*) AS occurances
FROM
    (SELECT pizza_num, pizza_name, UNNEST(toppings) AS topping
    FROM
        (SELECT ROW_NUMBER() OVER (ORDER BY order_id) AS pizza_num, order_id, pizza_name, toppings
            FROM
                (SELECT order_id, customer_orders.pizza_id,
                    SORT((REGEXP_SPLIT_TO_ARRAY(toppings, ', ')::int[]
                    - COALESCE(REGEXP_SPLIT_TO_ARRAY(NULLIF(NULLIF(exclusions, ''), 'null'), ', '), '{}'::text[])::int[])
                    || REGEXP_SPLIT_TO_ARRAY(NULLIF(NULLIF(extras, ''), 'null'), ', ')::int[]) AS toppings
                FROM
                    (SELECT customer_orders.order_id AS order_id, pizza_id, exclusions, extras
                    FROM customer_orders JOIN runner_orders
                    ON customer_orders.order_id = runner_orders.order_id
                    WHERE NULLIF(NULLIF(cancellation, ''), 'null') IS NULL) AS customer_orders
                JOIN pizza_recipes
                ON customer_orders.pizza_id = pizza_recipes.pizza_id
                ORDER BY order_id, customer_orders.pizza_id) AS pizza_orders
            JOIN pizza_names
            ON pizza_orders.pizza_id = pizza_names.pizza_id
            ORDER BY pizza_num)) AS pizzas_ordered
JOIN pizza_toppings
ON pizzas_ordered.topping = pizza_toppings.topping_id
GROUP BY topping_name
ORDER BY occurances DESC;