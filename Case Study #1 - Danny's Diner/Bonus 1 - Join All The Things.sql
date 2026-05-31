SELECT customer_id, order_date, product_name, price, member FROM
	(SELECT sales.customer_id AS customer_id, order_date, product_id,
		CASE
			WHEN order_date < join_date OR join_date IS NULL
				THEN 'N'
			ELSE 'Y'
		END member
	FROM
	sales LEFT JOIN members
	ON sales.customer_id = members.customer_id) AS orders
JOIN menu
ON orders.product_id = menu.product_id
ORDER BY customer_id, order_date, price DESC