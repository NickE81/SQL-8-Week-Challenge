-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS total_ammount
FROM sales JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(*) AS total_days FROM
	(SELECT customer_id, order_date
	FROM sales
	GROUP BY customer_id, order_date)
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT ON (customer_id) customer_id, product_name
FROM
	(SELECT customer_id, MIN(order_date) AS first_order, product_name
	FROM sales JOIN menu
	ON sales.product_id = menu.product_id
	GROUP BY customer_id, product_name
	ORDER BY MIN(order_date));

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(*) AS sales_count FROM
sales JOIN menu
ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY sales_count DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_name FROM
	(SELECT DISTINCT ON (customer_id) customer_id, product_id FROM
		(SELECT customer_id, product_id, COUNT(*) AS purchases FROM
		SALES
		GROUP BY customer_id, product_id
		ORDER BY customer_id, purchases DESC)) AS popular_items
JOIN menu
ON popular_items.product_id = menu.product_id
ORDER BY customer_id;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT DISTINCT ON (customer_id) customer_id, product_name FROM
	(SELECT sales.customer_id AS customer_id, product_id FROM
	sales JOIN members
	ON sales.customer_id = members.customer_id
	WHERE order_date > join_date
	ORDER BY order_date) AS first_item
JOIN menu
ON first_item.product_id = menu.product_id
ORDER BY customer_id;

-- 7. Which item was purchased just before the customer became a member?
SELECT DISTINCT ON (customer_id) customer_id, product_name FROM
	(SELECT sales.customer_id AS customer_id, product_id, order_date FROM
	sales JOIN members
	ON sales.customer_id = members.customer_id
	WHERE order_date < join_date
	ORDER BY order_date DESC) AS first_item
JOIN menu
ON first_item.product_id = menu.product_id
ORDER BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT customer_id, COUNT(*) AS total_items, SUM(price) AS total_cost FROM
	(SELECT sales.customer_id AS customer_id, product_id
	FROM sales JOIN members
	ON sales.customer_id = members.customer_id
	WHERE order_date < join_date) AS orders
JOIN menu
ON orders.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(points) AS points FROM
	(SELECT customer_id,
		CASE product_name
			WHEN 'sushi'
				THEN price * 20
			ELSE price * 10
		END points
	FROM
	sales JOIN menu
	ON sales.product_id = menu.product_id)
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT customer_id, SUM(points) AS points FROM
	(SELECT customer_id,
		CASE
			WHEN product_name = 'sushi' or DATE(order_date) BETWEEN DATE(join_date) AND DATE(join_date) + INTERVAL '6 day'
				THEN price * 20
			ELSE price * 10
		END points
	FROM
		(SELECT sales.customer_id AS customer_id, product_id, order_date, join_date FROM
		sales JOIN members
		ON sales.customer_id = members.customer_id) AS orders
	JOIN menu
	ON orders.product_id = menu.product_id
	WHERE DATE(order_date) < DATE('2021-02-01'))
GROUP BY customer_id;