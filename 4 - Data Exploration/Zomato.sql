create database if not exists zomato;
use zomato;

CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,STR_TO_DATE("09-22-2017", "%m-%d-%Y")),
(3,STR_TO_DATE("04-21-2017", "%m-%d-%Y"));

CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,STR_TO_DATE("09-02-2014", "%m-%d-%Y")),
(2,STR_TO_DATE("01-15-2015", "%m-%d-%Y")),
(3,STR_TO_DATE("04-11-2014", "%m-%d-%Y"));

CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,STR_TO_DATE("04-19-2017", "%m-%d-%Y"),2),
(3,STR_TO_DATE("12-18-2019", "%m-%d-%Y"),1),
(2,STR_TO_DATE("07-20-2020", "%m-%d-%Y"),3),
(1,STR_TO_DATE("10-23-2019", "%m-%d-%Y"),2),
(1,STR_TO_DATE("03-19-2018", "%m-%d-%Y"),3),
(3,STR_TO_DATE("12-20-2016", "%m-%d-%Y"),2),
(1,STR_TO_DATE("11-09-2016", "%m-%d-%Y"),1),
(1,STR_TO_DATE("05-20-2016", "%m-%d-%Y"),3),
(2,STR_TO_DATE("09-24-2017", "%m-%d-%Y"),1),
(1,STR_TO_DATE("03-11-2017", "%m-%d-%Y"),2),
(1,STR_TO_DATE("03-11-2016", "%m-%d-%Y"),1),
(3,STR_TO_DATE("11-10-2016", "%m-%d-%Y"),1),
(3,STR_TO_DATE("12-07-2017", "%m-%d-%Y"),2),
(3,STR_TO_DATE("12-15-2016", "%m-%d-%Y"),2),
(2,STR_TO_DATE("11-08-2017", "%m-%d-%Y"),2),
(2,STR_TO_DATE("09-10-2018", "%m-%d-%Y"),3);

CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

/*1- Total amount spent by each customer */
select a.userid,sum(b.price) total_amt_spent from sales a inner join product b on a.product_id=b.product_id
group by a.userid order by a.userid;

/*2- How many days has each customer visited zomato? */
select userid,count(distinct created_date) distinct_days from sales group by userid;

/*3- What was the first product purchased by each customer? */
select * from
(select *, rank() over(partition by userid order by created_date) rnk from sales) a where rnk=1;
/* We can see that the product with id "1" is the one every customer bought first*/

/*4- What is the most purchased item on the menu and how many times was it purchased by all customers? */
/*step 1*/ select product_id,count(product_id) purchase_count from sales group by product_id 
order by count(product_id) desc limit 1; 
/*step 2*/ select product_id from sales group by product_id order by count(product_id) desc limit 1; 
/*step 3*/ select * from sales where product_id =
(select product_id from sales group by product_id order by count(product_id) desc limit 1);
/*step 4*/ select userid,count(product_id) cnt from sales where product_id =
(select product_id from sales group by product_id order by count(product_id) desc limit 1)
group by userid order by userid;

/*5- Which item is the most popular for each customer? */
/*step 1*/ select userid,product_id,count(product_id) cnt from sales group by userid,product_id;
/*step 2*/ select *,rank() over(partition by userid order by cnt desc) rnk from
(select userid,product_id,count(product_id) cnt from sales group by userid,product_id) as a; /*"as a" = alias*/
/*step 3*/ select * from
(select *,rank() over(partition by userid order by cnt desc) rnk from
(select userid,product_id,count(product_id) cnt from sales group by userid,product_id) as a) as b
where rnk = 1;

/*6- Which item was purchased first by the customer after they became a golduser member? */
/*step 1*/ select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid=b.userid;
/*step 2*/ select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid=b.userid and created_date>gold_signup_date;
/*step 3*/ select a.*,rank() over(partition by userid order by created_date) rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid=b.userid and created_date>gold_signup_date) as a;
/*step 4*/ select * from
(select a.*,rank() over(partition by userid order by created_date) rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid=b.userid and created_date>gold_signup_date) as a) as b where rnk=1;

/*7- Which item was purchased just before the customer became a member? */
select * from
(select a.*,rank() over(partition by userid order by created_date desc) rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid=b.userid and created_date<gold_signup_date) as a) as b where rnk=1;
/*same code as the previous insight, but changing the ">" by "<" (we want to see purchases before the customers
become members), and changing the rank order to descending ("desc") to give the first position to the highest
date*/

/*8- What are the total orders and amount spent for each member before they became a member? */
/*step 1: we can first re-write the subquery from the previous question, as we want to see the information
before the customers became members*/
select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid=b.userid and created_date<gold_signup_date;
/*step 2: now we join the subquery to the product table to obtain the price info*/
select c.*,d.price from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid=b.userid and created_date<gold_signup_date) as c inner join product d on c.product_id=
d.product_id;
/*step 3: from that information we just need to count the number of orders and sum the amount spent by customer*/
select e.userid,count(distinct e.created_date) order_count,sum(e.price) amount_spent from
(select c.*,d.price from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
on a.userid=b.userid and created_date<gold_signup_date) as c inner join product d on c.product_id=
d.product_id) as e group by userid;

/*9- If buying each product generates points for eg. 5$ = 2 zomato points and each product has different
purchasing points as follows: for p1 5$ = 1 zomato point, for p2 10$ = 5 zomato points, and p3 5$ = 1 zomato point,
we want to calculate the points collected by each customer, and for which product most points have been given 
until now */
/*step 1: join sales and product tables to get the price data*/
select a.*, b.price from sales a inner join product b on a.product_id=b.product_id;
/*step 2: we now want to calculate the sum of sales per product purchased by every customer*/
select c.userid,c.product_id,sum(c.price) sum_of_sales from
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) as c
group by c.userid,c.product_id order by c.userid;
/*step 3: we want to add a new column with the number of points the customer earns for every product_id purchased*/
select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points
from
(select c.userid,c.product_id,sum(c.price) sum_of_sales from
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) as c
group by c.userid,c.product_id order by c.userid) as d;
/*step 4: now we add a new column to divide the sum of sales by points to get the total amount of points earned 
per product_id*/
select e.*,sum_of_sales/points total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points
from
(select c.userid,c.product_id,sum(c.price) sum_of_sales from
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) as c
group by c.userid,c.product_id order by c.userid) as d) as e;
/*step 5: to calculate the total number of points collected by each customer let's sum the points and group by
userid*/
select f.userid,sum(f.total_points) total_points_amt from
(select e.*,sum_of_sales/points total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points
from
(select c.userid,c.product_id,sum(c.price) sum_of_sales from
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) as c
group by c.userid,c.product_id order by c.userid) as d) as e) as f group by f.userid;
/*step 6: at the very beginning of this question, it says that for every 2 zomato points the customer will earn
a cashback of 5$. That means we can simply multiply the total amount of points earned by 2.5 to get the total cashback
figures per customer*/
select f.userid,sum(f.total_points)*2.5 total_cashback_earned from
(select e.*,sum_of_sales/points total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points
from
(select c.userid,c.product_id,sum(c.price) sum_of_sales from
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) as c
group by c.userid,c.product_id order by c.userid) as d) as e) as f group by f.userid;
/*step 7: let's work on the second part of the question. We want to know for which product most points have been given 
until now. To do that we can use the code of the previous step, changing a couple of things like removing the
multiplication, or grouping by product_id instead of userid*/
select f.product_id,sum(f.total_points) total_points from
(select e.*,sum_of_sales/points total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points
from
(select c.userid,c.product_id,sum(c.price) sum_of_sales from
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) as c
group by c.userid,c.product_id order by c.userid) as d) as e) as f group by f.product_id;
/*Step 8: now we proceed to rank the data*/
select *,rank() over(order by total_points desc) rnk from
(select f.product_id,sum(f.total_points) total_points from
(select e.*,sum_of_sales/points total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points
from
(select c.userid,c.product_id,sum(c.price) sum_of_sales from
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) as c
group by c.userid,c.product_id order by c.userid) as d) as e) as f group by f.product_id) as g;
/*step 9: let's just filter out the data to keep ranking #1 only*/
select * from
(select *,rank() over(order by total_points desc) rnk from
(select f.product_id,sum(f.total_points) total_points from
(select e.*,sum_of_sales/points total_points from
(select d.*, case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points
from
(select c.userid,c.product_id,sum(c.price) sum_of_sales from
(select a.*, b.price from sales a inner join product b on a.product_id=b.product_id) as c
group by c.userid,c.product_id order by c.userid) as d) as e) as f group by f.product_id) as g) as h where rnk=1;

/*10- In the first year after a customer joins the gold programme (including their join date) regardless of what
the customer has purchased they earn 5 zomato points for every 10$ spent (equals 0.5zp=1$). Who earned more points 
customer 1 or 3? And what was their points earnings in their first year?*/
/*step 1: let's first get the sales data after the gold members signed up*/
select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b on
a.userid=b.userid and a.created_date>=b.gold_signup_date;
/*step 2: now we delimit sales to those made maximum 1 year after the gold signup date*/
select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b on
a.userid=b.userid and a.created_date>=b.gold_signup_date and a.created_date<=
date_add(b.gold_signup_date, interval 365 day);
/*step 3: now we join the above to the product table to get the price information*/
select c.*,d.price from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b on
a.userid=b.userid and a.created_date>=b.gold_signup_date and a.created_date<=
date_add(b.gold_signup_date, interval 365 day)) as c inner join product d on c.product_id=d.product_id;
/*step 4: now we can multiply the price for 0.5, to get the points earned*/
select c.*,d.price*0.5 total_points_earned from
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join goldusers_signup b on
a.userid=b.userid and a.created_date>=b.gold_signup_date and a.created_date<=
date_add(b.gold_signup_date, interval 365 day)) as c inner join product d on c.product_id=d.product_id;

















 






















