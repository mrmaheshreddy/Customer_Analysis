-- Creating the database
CREATE DATABASE if not exists customer_analysis;

use customer_analysis;

-- Create table Sales
create table sales(
customer_id  varchar(1),
order_date date,
product_id integer);
 
INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);
    
-- Create table menu 
CREATE TABLE menu (
product_id integer,
product_name varchar(15),
price integer);

INSERT INTO menu (product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

-- create table members 
CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

-- Still works without specifying the column names explicitly
INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');
    
-- QUERYING THE TABLES 
select * from sales;
select * from menu;
select * from members;


-- 1. What is the total amount each customer spent in the restaurant?

select s.customer_id,sum(m.price) as Amount_spend from sales s
join menu m on s.product_id=m.product_id 
group by s.customer_id;

-- 2. How many days has each customer visited the restaurant?

select s.customer_id,count(distinct order_date) as Days_visited 
from sales s 
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH customer_first_purchase AS(
select customer_id,min(order_date) as first_purchase_date
from sales s 
group by customer_id)
select cfp.customer_id,cfp.first_purchase_date, product_name
from customer_first_purchase cfp
join sales s on s.customer_id=cfp.customer_id
and cfp.first_purchase_date=s.order_date 
join menu m on m.product_id=s.product_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name,count(*) as most_purchased 
from sales s
join menu m on s.product_id=m.product_id
group by m.product_name 
order by most_purchased desc limit 1;

-- 5. Which item was the most popular for each customer?

WITH customer_popularity AS (
SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS ranking
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
 GROUP BY s.customer_id,m.product_name
)
SELECT customer_id,product_name,purchase_count
FROM customer_popularity WHERE ranking = 1;

-- 6. Which item was purchased first by the customer after they became a member?

with first_item as(
select s.customer_id,min(s.order_date) as first_purchase_date
from sales s
join members mb on s.customer_id=mb.customer_id  
where s.order_date >= mb.join_date
group by s.customer_id
)
select fi.customer_id,m.product_name from 
first_item fi
join sales s on fi.customer_id=s.customer_id
AND fi.first_purchase_date = s.order_date
JOIN menu m ON s.product_id = m.product_id;

-- 7. Which item was purchased just before the customer became a member?

WITH last_purchase_before_membership AS (
    SELECT s.customer_id, MAX(s.order_date) AS last_purchase_date
    FROM sales s
    JOIN members mb ON s.customer_id = mb.customer_id
    WHERE s.order_date < mb.join_date
    GROUP BY s.customer_id
)
SELECT lpbm.customer_id, m.product_name
FROM last_purchase_before_membership lpbm
JOIN sales s ON lpbm.customer_id = s.customer_id 
AND lpbm.last_purchase_date = s.order_date
JOIN menu m ON s.product_id = m.product_id;

 -- 8. What is the total items and amount spent for each member before they became a member?
 
 select s.customer_id,count(*) as total_items,sum(m.price) as amount_spent
 from sales s 
 join menu m on s.product_id=m.product_id
 join members mb on s.customer_id=mb.customer_id
 where s.order_date < mb.join_date
 group by s.customer_id;
 
 -- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id,
SUM(
		CASE 
            WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
            ELSE m.price * 10
        END
    ) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH first_week_purchases AS (
   SELECT 
        s.customer_id,
        m.product_name,
        m.price,
        s.order_date,
        mb.join_date,
        CASE 
            WHEN s.order_date BETWEEN mb.join_date AND DATE_ADD(mb.join_date, INTERVAL 7 DAY)
            THEN m.price * 10 * 2
            ELSE m.price * 10
        END AS points
    FROM 
        sales s
    JOIN 
        menu m ON s.product_id = m.product_id
    JOIN 
        members mb ON s.customer_id = mb.customer_id
    WHERE
        s.order_date <= '2021-01-31'
)
SELECT customer_id,SUM(points) AS total_points
FROM first_week_purchases
GROUP BY customer_id;





















