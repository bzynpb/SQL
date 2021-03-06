-- a.    Create table (Actions) and insert values

CREATE TABLE Actions (
    [Visitor_ID] INT  PRIMARY KEY,
    [Adv_Type] VARCHAR(1),
    [Action] VARCHAR(10)
);

drop table actions
CREATE TABLE Actions (
    [Visitor_ID] INT IDENTITY(1,1) PRIMARY KEY,
    [Adv_Type] VARCHAR(1),
    [Action] VARCHAR(10)
);


INSERT INTO [Actions] VALUES
('A', 'Left'),
('A', 'Order'),
('B', 'Left'),
('A', 'Order'),
('A', 'Review'),
('A', 'Left'),
('B', 'Left'),
('B', 'Order'),
('B', 'Review'),
('A', 'Review');

SELECT *
FROM [Actions]

/* 
b.    Retrieve count of total Actions and Orders for each Advertisement Type
c.    Calculate Orders (Conversion) rates for each Advertisement Type 
by dividing by total count of actions casting as float by multiplying by 1.0. 
*/



WITH [total] AS (
    SELECT [Adv_Type], COUNT([Action]) as [total_actions]
    FROM [Actions]
    GROUP BY  [Adv_Type]
),
[orders] AS (
    SELECT [Adv_Type], COUNT([Action]) as [num_orders]
    FROM [Actions]
    WHERE [Action]='Order'
    GROUP BY  [Adv_Type]
)
SELECT [total].[Adv_Type], 
--1.0* ([Orders].[num_orders]/[total].[total_actions])
CAST((1.0*[Orders].[num_orders]/[total].[total_actions]) AS DECIMAL (2,2)) AS Conversion_Rate
FROM [total] 
JOIN [orders] ON [total].[Adv_Type]= [orders].[Adv_Type]

--- alternative solution --- 

WITH table_name AS (
				select	distinct Adv_Type,Action1,
				COUNT (Action1) over (partition by Adv_Type ) total_actions_of_Adv_Type,
				COUNT (Action1) over (partition by Adv_Type,Action1 ) actions_portions_of_Adv_Type
				from	Actions
	)
SELECT	Adv_Type, Action1, actions_portions_of_Adv_Type , total_actions_of_Adv_Type, round((cast(actions_portions_of_Adv_Type as float) / total_actions_of_Adv_Type),2) conv_rate
FROM	table_name
where Action1 = 'Order'
;
-----
WITH table_name AS (
				select distinct Adv_Type,Action1,
				COUNT (Action1) over (partition by Adv_Type ) total_actions_of_Adv_Type,
				COUNT (Action1) over (partition by Adv_Type,Action1 ) actions_portions_of_Adv_Type,
				cast ((1.0 * COUNT (Action1) over (partition by Adv_Type,Action1 ) / COUNT (Action1) over (partition by Adv_Type )) as decimal (5,3)) conv_rate
				from	Actions
	)
SELECT	Adv_Type, Action1, actions_portions_of_Adv_Type , total_actions_of_Adv_Type, round((cast(actions_portions_of_Adv_Type as float) / total_actions_of_Adv_Type),2) conv_rate
FROM	table_name
where Action1 = 'Order'
;
select Adv_Type,  conv_rate
from (
		select distinct Adv_Type,Action1,
				COUNT (Action1) over (partition by Adv_Type ) total_actions_of_Adv_Type,
				COUNT (Action1) over (partition by Adv_Type,Action1 ) actions_portions_of_Adv_Type,
				cast ((1.0 * COUNT (Action1) over (partition by Adv_Type,Action1 ) / COUNT (Action1) over (partition by Adv_Type )) as decimal (5,3)) conv_rate
				from	Actions
	 ) as T1
where Action1 = 'Order'

-- Alternative solution 3---
CREATE TABLE Assignment_3(
	Visitor_ID int NOT NULL PRIMARY KEY,
	Adv_Type VARCHAR(50) NOT NULL,
	[Action] VARCHAR(50) NOT NULL,
);
INSERT [dbo].[Assignment_3] ([Visitor_ID],[Adv_Type],[Action]) VALUES (1,N'A',N'Left')
INSERT [dbo].[Assignment_3] ([Visitor_ID],[Adv_Type],[Action]) VALUES (2, N'A',N'Order')
INSERT [dbo].[Assignment_3] ([Visitor_ID],[Adv_Type],[Action]) VALUES (3, N'B',N'Left')
INSERT [dbo].[Assignment_3] ([Visitor_ID],[Adv_Type],[Action]) VALUES (4, N'A',N'Order')
INSERT [dbo].[Assignment_3] ([Visitor_ID],[Adv_Type],[Action]) VALUES (5, N'A',N'Review')
INSERT [dbo].[Assignment_3] ([Visitor_ID],[Adv_Type],[Action]) VALUES (6, N'A',N'Left')
INSERT [dbo].[Assignment_3] ([Visitor_ID],[Adv_Type],[Action]) VALUES (7, N'B',N'Left')
INSERT [dbo].[Assignment_3] ([Visitor_ID],[Adv_Type],[Action]) VALUES (8, N'B',N'Order')
INSERT [dbo].[Assignment_3] ([Visitor_ID],[Adv_Type],[Action]) VALUES (9, N'B',N'Review')
INSERT [dbo].[Assignment_3] ([Visitor_ID],[Adv_Type],[Action]) VALUES (10, N'A',N'Review')
SELECT Adv_Type, CAST(ROUND((SUM(CASE WHEN Action='ORDER' THEN 1.0 END)/(COUNT(Action)*1.0)),2) AS numeric(2,2))  AS 'Conversion_Rate'
FROM [dbo].[Assignment_3]
GROUP BY Adv_Type