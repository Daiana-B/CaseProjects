USE Restaurant_Project

--view menu_items
SELECT * FROM menu_items

--find the number of items on the menu
SELECT COUNT(DISTINCT menu_item_id)
FROM menu_items;

--what are the least and the most expensive items on menu?
SELECT *
FROM menu_items
WHERE CAST(price AS decimal)= (SELECT MIN(CAST(price AS decimal)) FROM menu_items);
SELECT *
FROM menu_items
WHERE CAST(price AS decimal)= (SELECT MAX(CAST(price AS decimal)) FROM menu_items);


--how many Italian dishes are on the menu?
SELECT COUNT(DISTINCT menu_item_id) AS count_italian_dishes
FROM menu_items
WHERE category = 'Italian';

--what are the least and the most expensive Italian items on menu?
SELECT *
FROM menu_items
WHERE CAST(price AS decimal)= (SELECT MIN(CAST(price AS decimal)) FROM menu_items WHERE category = 'Italian')
AND category = 'Italian';
SELECT *
FROM menu_items
WHERE CAST(price AS decimal)= (SELECT MAX(CAST(price AS decimal)) FROM menu_items WHERE category = 'Italian')
AND category = 'Italian';

--how many dishes are in each category?
SELECT category, COUNT(menu_item_id) AS count_dishes
FROM menu_items
GROUP BY category
ORDER BY 2 DESC

--what is the average dish price within each category?
SELECT category, AVG(CAST(price AS decimal)) AS average_price
FROM menu_items
GROUP BY category
ORDER BY 2 DESC;

--view oorder_details

SELECT * FROM order_details

--what is the date range of the table?
SELECT MIN(CAST(order_date AS date)) AS min_date, MAX(CAST(order_date AS date)) AS max_date
FROM order_details;

--how many orders were made within this data date range?
SELECT COUNT(DISTINCT order_id)
FROM order_details;

--how many items were ordered within this data date range?
SELECT COUNT(*)
FROM order_details;

--which orders had the most numbers of items?
SELECT order_id, cnt_items FROM(
SELECT order_id, COUNT(item_id) AS cnt_items, DENSE_RANK() OVER(ORDER BY COUNT(item_id) DESC) AS nm
FROM order_details
GROUP BY (order_id)) order_items
WHERE nm = 1;

--how many orders had more than 12 items?
SELECT COUNT(*) AS orders_more_12_items
FROM (
SELECT order_id, COUNT(item_id) AS cnt_items
FROM order_details
GROUP BY order_id
HAVING COUNT(item_id) > 12) order_items


--analyze customer behavior

SELECT *
FROM order_details ord 
LEFT JOIN menu_items men ON ord.item_id=men.menu_item_id

--what were the least and most ordered items?
WITH item_orders AS (
SELECT item_id, COUNT(order_id) AS cnt_orders
FROM order_details
GROUP BY item_id)
SELECT item_id, item_name AS least_ordered, category
FROM item_orders i_o
JOIN menu_items men ON i_o.item_id=men.menu_item_id
WHERE cnt_orders = (SELECT MIN(cnt_orders) FROM item_orders);
WITH item_orders AS (
SELECT item_id, COUNT(order_id) AS cnt_orders
FROM order_details
GROUP BY item_id)
SELECT item_id, item_name AS most_ordered, category
FROM item_orders i_o
JOIN menu_items men ON i_o.item_id=men.menu_item_id
WHERE cnt_orders = (SELECT MAX(cnt_orders) FROM item_orders);

--view top 10 items by total revenue
SELECT item_name, CAST(price AS decimal(18,2))*COUNT(*) AS item_revenue
FROM order_details ord 
LEFT JOIN menu_items men ON ord.item_id=men.menu_item_id
GROUP BY item_name, price
ORDER BY 2 DESC
OFFSET 0 ROWS FETCH NEXT 10 ROW ONLY


--average order amount
WITH ord_spend AS (
SELECT order_id, SUM(CAST(price AS decimal(18,2))) AS total_spend
FROM order_details ord 
LEFT JOIN menu_items men ON ord.item_id=men.menu_item_id
GROUP BY order_id
)
SELECT AVG(total_spend)
FROM ord_spend



--what were the top 5 orders that spent the most money?
SELECT order_id, SUM(CAST(price AS decimal(18,2))) AS total_spend
FROM order_details ord 
LEFT JOIN menu_items men ON ord.item_id=men.menu_item_id
GROUP BY order_id
ORDER BY 2 DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY


--view the details of the highest spend order.
SELECT category, COUNT(item_id)
FROM order_details ord 
LEFT JOIN menu_items men ON ord.item_id=men.menu_item_id
WHERE order_id='440'
GROUP BY category
ORDER BY 2 DESC

--seems like it's worth to keep italian food

--view the details of the top 5 highest spend order.
SELECT order_id, category, COUNT(item_id)
FROM order_details ord 
LEFT JOIN menu_items men ON ord.item_id=men.menu_item_id
WHERE order_id IN ('440', '2075', '1957', '330', '2675')
GROUP BY order_id, category
ORDER BY 1, 3 DESC

--view categories by total revenue
WITH item_ord AS (
SELECT item_id, CAST(price AS decimal(18,2))*COUNT(*) AS item_revenue
FROM order_details ord 
LEFT JOIN menu_items men ON ord.item_id=men.menu_item_id
GROUP BY item_id, price
)
SELECT category, SUM(item_revenue) AS category_revenue
FROM item_ord i_o
JOIN menu_items men ON i_o.item_id = men.menu_item_id
GROUP BY category
ORDER BY 2 DESC



--seems like it's worth to keep italian food too

