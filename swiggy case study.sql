
--Swiggy Case Study

use swiggy

select *from users$
select *from orders$
select *from dbo.food
select *from menu
select *from delivery_partner
select *from restaurants$
select *from order_details$


-- Q1 Find customers who have never ordered

	Select u.name as Customer_Name from users$ u where u.user_id 
	NOT IN (Select o.user_id from orders$ o WHERE o.user_id is not NULL)

--Q2 What is the Average Price Per Dish

	select food.f_name as food_name,round(AVG(menu.price),0) As AvgPricePerDish 
	from food INNER JOIN menu On food.f_id=menu.f_id
	Group by food.f_name
	order by AvgPricePerDish DESC


--Q3 Find the top restaurant in terms of the number of orders for a given month

	with cte as(
	select o.r_id,DATENAME(M,o.date) as Month from orders$ o
	),
	cte1 as(
	select TOP 1 *,COUNT(c.r_id) as Orders from cte c
	where MONTH='June'
	Group by c.r_id,c.Month
	Order by COUNT(c.r_id) DESC
	)
	select c1.*,c2.r_name Restraunt_Name from cte1 c1 INNER JOIN restaurants$  c2
	On c1.r_id=c2.r_id


-- Q4 Restaurants with monthly sales greater than x for a particular Month 	

	with cte as(
	select o.r_id id,o.amount amt,DATENAME(M,o.date) as Month from orders$ o
	)
	select r.r_name Restraunt_name,SUM(c.amt) as Monthly_Sales 
	from cte c INNER JOIN restaurants$ r ON c.id=r.r_id
	where MONTH='July'
	Group by r.r_name
	HAVING SUM(c.amt)>1000


--Q5 Show all orders with order details for a particular customer in a particular date range

	with cte as( 
	select * from orders$
	where user_id=4 AND date between '2022-06-10' AND '2022-07-10' 
	),
	restraunt as(
	select r.r_name,cte.* from cte INNER JOIN restaurants$ r
	ON cte.r_id=r.r_id
	),
	food_ordered as(
	select r.*,o.f_id from restraunt r INNER JOIN order_details$ o
	on r.order_id=o.order_id
	)
	select fo.order_id,fo.r_name as Restraunt_name,f.f_name as Food_name 
	from food_ordered fo INNER JOIN food f On fo.f_id=f.f_id
	Group by fo.order_id,fo.r_name,f.f_name


--Q6 Find restaurants with max repeated customers 
	DELETE FROM orders$ 
	WHERE r_id IS NULL AND user_id IS NULL;


	with cte as(
	select o.r_id,o.user_id,COUNT(o.user_id) cnt,
	ROW_NUMBER() over (partition by o.r_id order by o.r_id ) as rn
	from orders$ o
	group by o.r_id,o.user_id
	HAVING COUNT(o.user_id) >1
	)
	select TOP 1 cte.r_id Restraunt_Id,r.r_name as Restraunt_Name,
	COUNT(cte.user_id) as Repeated_Customers
	from cte INNER join restaurants$ r on cte.r_id=r.r_id
	Group by cte.r_id,r.r_name
	order by COUNT(cte.user_id) desc



--Q7 Month over month revenue growth of swiggy


	with sales as(
	select SUM(o.amount) as revenue, DATENAME(M,o.date) AS 'MONTH' from orders$ o
	Group by DATENAME(M,o.date)
	),
	growthRate as(
	select MONTH,revenue,LAG(revenue,1) over (order by revenue) as GrowthRate from sales 
	)
	select gr.MONTH,gr.revenue,
	CONCAT(ROUND((gr.revenue-gr.GrowthRate)/GrowthRate *100,1),'%') as Growth_Rate_Percent 
	from growthRate gr
	order by gr.MONTH desc


--Q8 Find the Customer's - favorite food

	with cte as(
	select o.user_id,od.f_id,COUNT(*) as freq,
	DENSE_RANK()over(partition by o.user_id order by COUNT(*) desc) as rn
	from orders$ o INNER JOIN order_details$ od ON o.order_id=od.order_id
	Group by o.user_id,od.f_id
	)
	select cte.user_id,cte.f_id as food_id,food.f_name as food_name 
	from cte INNER JOIN food On cte.f_id=food.f_id
	where cte.rn=1
