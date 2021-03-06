--DAwSQL Session -8 
--E-Commerce Project Solution

--1. Join all the tables and create a new table called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
SELECT * FROM cust_dimen
SELECT * FROM market_fact
SELECT * FROM orders_dimen
SELECT *  FROM prod_dimen
SELECT * FROM shipping_dimen


CREATE VIEW [combined_view2] AS 
(
    SELECT
    a.Ord_id, a.prod_id, a.Ship_id, a.Cust_id, a.Sales, a.Discount, a.Order_Quantity, a.Product_Base_Margin,
	  b.Customer_Name, b.Province, b.Region, b.Customer_Segment,
	  CONVERT(date,(SUBSTRING(c.Order_Date,7,4) + SUBSTRING(c.Order_Date,4,2) + SUBSTRING(c.Order_Date,1,2)) ,101) as Order_Date,
    c.Order_Priority,
	  d.Product_Category, d.Product_Sub_Category,
	  e.Order_ID, 
    CONVERT(date,(SUBSTRING(e.Ship_Date,7,4) + SUBSTRING(e.Ship_Date,4,2) + SUBSTRING(e.Ship_Date,1,2)) ,101) as Ship_Date, 
    e.Ship_Mode
    FROM market_fact a 
    LEFT JOIN cust_dimen b ON a.Cust_id=b.Cust_id
    LEFT JOIN orders_dimen c ON a.Ord_id=c.Ord_id
    LEFT JOIN prod_dimen d ON a.Prod_id=d.Prod_id
    LEFT JOIN shipping_dimen e ON e.Ship_id=a.Ship_id
) 

SELECT * 
INTO combined_table
FROM [combined_view2]

--///////////////////////

--2. Find the top 3 customers who have the maximum count of orders.
SELECT cust_id,customer_name
FROM (
  SELECT TOP 3 cust_id, customer_name, count(Order_ID) order_num
  FROM combined_table
  GROUP BY cust_id, Customer_Name
  ORDER BY order_num DESC  
  ) t1


SELECT DISTINCT customer_name
FROM combined_table

--/////////////////////////////////

/* 3.Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
Use "ALTER TABLE", "UPDATE" etc. */

ALTER TABLE combined_table
ADD DaysTakenForDelivery INT

UPDATE combined_table
SET DaysTakenForDelivery = datediff(day, Order_Date, Ship_Date )


SET DATEFORMAT dmy;
UPDATE dbo.shipping_dimen
SET ship_date = CONVERT(varchar, CAST(ship_date AS date), 3);

SELECT CONVERT(varchar, CAST(Order_Date AS date), 3)
FROM dbo.orders_dimen2




--////////////////////////////////////

/* 4. Find the customer whose order took the maximum time to get delivered.
Use "MAX" or "TOP" */

SELECT TOP 1 cust_id, customer_name, DaysTakenForDelivery
FROM combined_table
ORDER BY DaysTakenForDelivery DESC

--////////////////////////////////

/*5. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
You can use date functions and subqueries*/

SELECT MONTH(Order_Date) month, 
      DATENAME(month,Order_Date) month_name, 
      COUNT(DISTINCT cust_id) cust_num
FROM combined_table A 
WHERE 
  EXISTS (
    SELECT  cust_id
    FROM combined_table b
    WHERE MONTH(Order_Date) = 1  
    AND YEAR(Order_Date)=2011
    AND A.Cust_id = B.Cust_id
  )
AND YEAR(Order_Date)=2011
GROUP BY MONTH(Order_Date) , datename(month,Order_Date) 
Order by month

--////////////////////////////////////////////

/*6. write a query to return for each user acording to the time elapsed between the first purchasing and the third purchasing, 
in ascending order by Customer ID
Use "MIN" with Window Functions*/

 SELECT DISTINCT cust_id, 
                first_order_date [1.order],  
                order_date [3.order], 
                list_order,
                DATEDIFF(day,FIRST_ORDER_DATE, order_date) date_diff
 FROM (
      SELECT cust_id, order_date,
      MIN (Order_Date) OVER (PARTITION BY Cust_id) first_order_date,
      DENSE_RANK () OVER (PARTITION BY Cust_id ORDER BY Order_date) list_order
      FROM combined_table
 ) t1
 WHERE list_order =3

--//////////////////////////////////////

/* 7. Write a query that returns customers who purchased both product 11 and product 14, 
as well as the ratio of these products to the total number of products purchased by all customers.
Use CASE Expression, CTE, CAST and/or Aggregate Functions */
select * from combined_table

WITH tablo_1 AS
(
    SELECT cust_id, 
          SUM(CASE WHEN prod_id = 'Prod_11' THEN Order_Quantity ELSE 0 END) count_prod11,
          SUM(CASE WHEN prod_id = 'Prod_14' THEN Order_Quantity ELSE 0 END) count_prod14,
          sum(Order_Quantity) total_product
    FROM combined_table
    GROUP BY cust_id
    HAVING SUM(CASE WHEN prod_id = 'Prod_11' THEN Order_Quantity ELSE 0 END) >0
          AND SUM(CASE WHEN prod_id = 'Prod_14' THEN Order_Quantity ELSE 0 END) >0
)
SELECT  cust_id,
        count_prod11,
        CAST ((1.0*count_prod11/total_product) AS DECIMAL (3,2)) AS [ratio_of_p11], 
        count_prod14,
        CAST ((1.0*count_prod14/total_product) AS DECIMAL (3,2)) AS [ratio_of_p14],
        total_product
FROM tablo_1
ORDER BY [ratio_of_p14] DESC, [ratio_of_p11] ASC

--/////////////////


--CUSTOMER SEGMENTATION

--1. Create a view that keeps visit logs of customers on a monthly basis. (For each log, three field is kept: Cust_id, Year, Month)
--Use such date functions. Don't forget to call up columns you might need later.

CREATE VIEW customer_log AS
(
SELECT cust_id, 
      YEAR(Order_Date) as order_year, 
      MONTH(Order_Date) as order_month
FROM combined_table
GROUP BY cust_id, YEAR(Order_Date), MONTH(Order_Date) 
)


--//////////////////////////////////

/* 2.Create a ???view??? that keeps the number of monthly visits by users. (Show separately all months from the beginning  business)
Don't forget to call up columns you might need later. */

CREATE VIEW montly_visits AS 
(
SELECT	Cust_id,
		Customer_Name,
		YEAR(Order_Date) Years, 
		DATENAME(MONTH,Order_Date) Months,
		COUNT(Order_Date) Monthly_visit
FROM combined_table
GROUP BY Cust_id, Customer_Name, YEAR(Order_Date) , DATENAME(MONTH,Order_Date)
)

SELECT *
FROM montly_visits

--//////////////////////////////////

/*3. For each visit of customers, create the next month of the visit as a separate column.
You can order the months using "DENSE_RANK" function.
then create a new column for each month showing the next month using the order you have made above. (use "LEAD" function.)
Don't forget to call up columns you might need later. */

CREATE VIEW Next_Visit AS
(
SELECT	*,
		LEAD(CURRENT_MONTH, 1) OVER (PARTITION BY Cust_id ORDER BY Current_Month) Next_Visit_Month
FROM
	(SELECT *,
	DENSE_RANK() OVER(ORDER BY [years] , [months]) Current_Month
	FROM montly_visits
	) t1
) 

SELECT * 
FROM Next_Visit

--/////////////////////////////////

/* 4. Calculate monthly time gap between two consecutive visits by each customer.
Don't forget to call up columns you might need later. */

CREATE VIEW time_gap As 
(
SELECT Cust_id, Order_Date, 
second_order , 
DATEDIFF(MONTH,Order_Date,second_order) time_gap
FROM
	(SELECT  Cust_id, 
          Order_Date,	
          MIN(Order_date) over(Partition by Cust_id) first_order_date,	 
          lead(Order_Date, 1) over(partition by cust_id order by order_date) second_order,
          DENSE_RANK() over(Partition by Cust_id order by order_date) order_datez
  FROM combined_table
	) T
WHERE DATEDIFF(MONTH,Order_Date,second_order) >0
) 

--///////////////////////////////////

/* 5.Categorise customers using average time gaps. Choose the most fitted labeling model for you.
For example: 
Labeled as ???churn??? if the customer hasn't made another purchase for the months since they made their first purchase.
Labeled as ???regular??? if the customer has made a purchase every month.
Etc.*/

SELECT *
FROM time_gap
--
SELECT Cust_id, 
        AVG(time_gap) avg_time_gap
FROM time_gap
GROUP BY Cust_id 
--
SELECT Cust_id, 
      avg_time_gap,
      CASE  WHEN avg_time_gap = 1 THEN 'Retained'
            WHEN avg_time_gap > 1 THEN 'Irregular'
            WHEN avg_time_gap IS NULL THEN 'Churn'
            ELSE 'UNKNOWN DATA' 
            END Customer_Lebels
FROM (
     SELECT Cust_id, 
        AVG(time_gap) avg_time_gap
      FROM time_gap
      GROUP BY Cust_id 
) t1


--/////////////////////////////////////


--MONTH-WISE RETENT??ON RATE


--Find month-by-month customer retention rate  since the start of the business.

/* 1. Find the number of customers retained month-wise. (You can use time gaps)

Use Time Gaps */

SELECT DISTINCT YEAR(order_date) [year], 
                MONTH(order_date) [month],
                DATENAME(month,order_date) [month_name],
                COUNT(cust_id) OVER (PARTITION BY year(order_date), month(order_date) order by year(order_date), month(order_date)  ) num_cust
FROM combined_table


--//////////////////////


/*2. Calculate the month-wise retention rate.
Basic formula: o	Month-Wise Retention Rate = 1.0 * Number of Customers Retained in The Current Month / Total Number of Customers in the Current Month
It is easier to divide the operations into parts rather than in a single ad-hoc query. It is recommended to use View. 
You can also use CTE or Subquery if you want.

You should pay attention to the join type and join columns between your views or tables. */

CREATE VIEW t1 AS
(
SELECT DISTINCT YEAR(order_date) [year], 
                MONTH(order_date) [month],
                DATENAME(month,order_date) [month_name],
                COUNT(cust_id) OVER (PARTITION BY year(order_date), month(order_date) order by year(order_date), month(order_date)  ) num_cust
FROM combined_table
) 
 
SELECT[year],
      [month_name],
      [num_cust],
      LEAD(num_cust,1) OVER (ORDER BY [year], [month] ) as next_num,
      FORMAT(num_cust*1.0*100/(lead(num_cust,1) over (order by year, month, num_cust)),'N2') ratio

FROM t1


---///////////////////////////////////

