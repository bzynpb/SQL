/* Discount Effects

Generate a report including product IDs and discount effects on 
whether the increase in the discount rate positively impacts the number of orders for the products.

*/
CREATE VIEW discount_quantity AS (
    SELECT *
    FROM (
        SELECT p.product_id,  o.discount, 
        SUM(quantity) as num_item_sold
        FROM product.product p
        LEFT JOIN sale.order_item o ON p.product_id = o.product_id
        LEFT JOIN sale.orders t ON o.order_id=t.order_id
        GROUP BY  p.product_id, o.discount
    ) t
    PIVOT (
        SUM (num_item_sold)
        FOR discount
        IN ([0.05], [0.07],[0.10],[0.20] )
    ) as p 
)

CREATE VIEW discount_quantity1 AS 
(
    SELECT product_id,
    d.[0.05] discount_1,
    d.[0.07] discount_2,
    d.[0.10] discount_3,
    d.[0.20] discount_4,
    (d.[0.05] + d.[0.07] + d.[0.10] + d.[0.20] ) total_amount  
    FROM discount_quantity d
) 

WITH compare_table AS(
    SELECT  product_id,
    discount_1,
    CAST((1.0*discount_1/total_amount) AS DECIMAL (2,2)) AS [% p1],
    discount_2,
    CAST((1.0*discount_2/total_amount) AS DECIMAL (2,2)) AS [% p2],
    discount_3,
    CAST((1.0* discount_3/total_amount) AS DECIMAL (2,2)) AS [% p3],
    discount_4,
    CAST((1.0*discount_4/total_amount) AS DECIMAL (2,2)) AS [% p4]
    FROM discount_quantity1 
)
SELECT product_id,
CASE    WHEN (1.0* (([% p1]+[% p2]) - ([% p3]+[% p4])) > 0.02 ) THEN 'Negatif' 
        WHEN (1.0* (([% p1]+[% p2]) - ([% p3]+[% p4])) < 0.02 ) THEN 'Positive' 
        ELSE 'Neutral '
END AS Discount_Effect
FROM compare_table

