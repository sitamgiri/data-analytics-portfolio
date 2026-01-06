DROP TABLE IF EXISTS ORDER_DETAIL;
--IMPORT THE CSV FILE ORDER DETAIL 
CREATE TABLE ORDER_DETAILS(
		ORDER_DETAIL INT PRIMARY KEY,
		ORDER_ID INT,
		PIZZA_ID VARCHAR(50),
		QUANTITY INT
		
);
SELECT * FROM ORDER_DETAILS


DROP TABLE IF EXISTS ORDER_INFO;

--IMPORT CSV FILE ORDER INFO
CREATE TABLE ORDER_INFO(
		ORDER_ID INT,
		"DATE" DATE,
		"TIME" TIME
);
SELECT * FROM ORDER_INFO;

--IMPORT TYPES OF PIZZAS AVAILABLE 

DROP TABLE IF EXISTS PIZZA_TYPES;

CREATE TABLE PIZZA_TYPES(
 PIZZA_TYPE VARCHAR (100),
 "NAME" VARCHAR (100),
 CATEGORY VARCHAR (50),
 INGREDIENTS VARCHAR (250)
 );

SELECT * FROM PIZZA_TYPES;

---IMPORT PIZZA FROM THE CSV FOLDER
DROP TABLE IF EXISTS PIZZA;

CREATE TABLE PIZZA(
	PIZZA_ID VARCHAR(50),
	PIZZA_TYPE VARCHAR(100),
	SIZE VARCHAR (10),
	PRICE NUMERIC
);

SELECT * FROM PIZZA;

---CREATE A NEW TABLE CALLED PIZZA_MENU TO ACCESS BASIC DATA FROM THE ABOVE GIVEN TABLES
DROP TABLE IF EXISTS PIZZA_MENU;

CREATE TABLE PIZZA_MENU AS
SELECT 
    PZ.PIZZA_ID,PT."NAME" as pizza_name,PT.PIZZA_TYPE,PT.CATEGORY,PT.INGREDIENTS,PZ.SIZE,PZ.PRICE
	FROM PIZZA_TYPES PT
	JOIN PIZZA PZ
	ON PT.PIZZA_TYPE=PZ.PIZZA_TYPE;


SELECT * FROM PIZZA_MENU;

--CREATE A TABLE CALLED SALES RECORD TO ACCESS THE SALES DETAIL

DROP TABLE IF EXISTS SALES_RECORD;

CREATE TABLE SALES_RECORD AS 
		SELECT OD.ORDER_DETAIL,
		OD.ORDER_ID,OD.PIZZA_ID,PM.PRICE,OD.QUANTITY,OI."DATE",OI."TIME"
		FROM ORDER_DETAILS OD
		JOIN ORDER_INFO OI
		ON 
		OD.ORDER_ID=OI.ORDER_ID
		
		JOIN
		PIZZA_MENU PM
		ON
		OD.PIZZA_ID=PM.PIZZA_ID;

SELECT * FROM SALES_RECORD;

SELECT PIZZA_ID,QUANTITY FROM SALES_RECORD
GROUP BY PIZZA_ID,QUANTITY;


-- group the orders according to pizza types


WITH REVENUE_COLLECTION AS
	(SELECT
	SD.PIZZA_ID ,
	M.CATEGORY,
	SUM(SD.QUANTITY) AS TOTAL_QUANTITY,
	SUM(SD.QUANTITY * M.PRICE) AS TOTAL_REVENUE,
	SD."DATE" AS DATES
	FROM
	SALES_RECORD SD
	JOIN PIZZA_MENU M ON SD.PIZZA_ID = M.PIZZA_ID
	GROUP BY
	SD.PIZZA_ID,
	M.PRICE,
	SD."DATE",
	M.CATEGORY)

SELECT
	*
FROM
	REVENUE_COLLECTION;
--now let us see the total business per month
SELECT
	EXTRACT(
		MONTH
		FROM
			"DATE"
	) AS MONTHS,
	EXTRACT(
		YEAR
		FROM
			"DATE"
	) AS YEARS,
	SUM(PRICE*QUANTITY) AS REVENUE,
	SUM(QUANTITY) AS NUMBERS_SOLD
FROM
	SALES_RECORD
GROUP BY
	MONTHS,
	YEARS
ORDER BY
	REVENUE DESC;

--check for the most popular pizza overall
SELECT
	M.PIZZA_NAME,
	SD.PIZZA_ID,
	M.PIZZA_TYPE,
	SUM(SD.QUANTITY) AS TOTAL_QUANTITY,
	M.CATEGORY,
	M.INGREDIENTS
FROM
	SALES_RECORD SD
	JOIN PIZZA_MENU M ON SD.PIZZA_ID = M.PIZZA_ID
GROUP BY
	SD.PIZZA_ID,
	M.PIZZA_NAME,
	M.CATEGORY,
	M.INGREDIENTS,
	M.PIZZA_TYPE
ORDER BY
	TOTAL_QUANTITY DESC;
--identifying the most ordered sized pizza

SELECT
	COUNT(OD.ORDER_ID) AS ORDER_SIZE,
	M.SIZE
FROM
	ORDER_DETAILS OD
	JOIN PIZZA_MENU M ON OD.PIZZA_ID = M.PIZZA_ID
GROUP BY
	M.SIZE
ORDER BY
	ORDER_SIZE DESC;

--identify the highest priced pizza
SELECT
	PIZZA_ID,
	PIZZA_NAME,
	CATEGORY,
	SIZE,
	PRICE
FROM
	PIZZA_MENU
ORDER BY
	PRICE DESC;


--list the top 5 most ordered pizza

SELECT
	M.PIZZA_NAME,
	M.SIZE,
	SUM(OD.QUANTITY) AS SUM_DETAIL
FROM
	ORDER_DETAILS OD
	JOIN PIZZA_MENU M ON OD.PIZZA_ID = M.PIZZA_ID
GROUP BY
	M.SIZE,
	M.PIZZA_NAME
ORDER BY
	SUM_DETAIL DESC
LIMIT
	5;

--determine the distribution by hour of the day

SELECT
	COUNT(ORDER_ID) AS TOTAL_PER_HOUR,
	EXTRACT(
		HOUR
		FROM
			"TIME"
	) AS TIME_OF_ORDER
FROM
	SALES_RECORD
GROUP BY
	TIME_OF_ORDER
ORDER BY
	TOTAL_PER_HOUR DESC;


--get the total pizza ORDERED on the basis of their category
SELECT
	PM.CATEGORY,
	SUM(OD.QUANTITY) AS ORDER_DETAILS
FROM
	PIZZA_MENU PM
	JOIN ORDER_DETAILS OD ON PM.PIZZA_ID = OD.PIZZA_ID
GROUP BY
	PM.CATEGORY
ORDER BY
	ORDER_DETAILS DESC;

--make the category wise arrangement of the pizzas
SELECT
	CATEGORY,
	COUNT(PIZZA_NAME) AS PIZZA_TYPES
FROM
	PIZZA_MENU
GROUP BY
	CATEGORY;


--group the order by day and calculate the avg order per day

WITH QUANTITY_DETAIL AS (
	SELECT
		"DATE",
		SUM(QUANTITY) AS PIZZA_PER_DAY
	FROM
		SALES_RECORD
	GROUP BY
		"DATE"
	ORDER BY
		"DATE" ASC
)

SELECT
	ROUND(AVG(PIZZA_PER_DAY), 2) AS AVG_PIZZA
FROM
	QUANTITY_DETAIL;

-- calculate 3 most ordered pizza types on the basis of revenue
SELECT
	PM.PIZZA_NAME,
	SUM(PM.PRICE * SR.QUANTITY) AS REVENUE
FROM
	SALES_RECORD SR
	JOIN PIZZA_MENU PM ON SR.PIZZA_ID = PM.PIZZA_ID
GROUP BY
	PM.PIZZA_NAME
ORDER BY
	REVENUE DESC
LIMIT
	3;
--calculate percentage contribution of each pizzas in total revenue

WITH
	REVENUE_DISTRIBUTION AS (
		SELECT
			PIZZA_ID,
			SUM(QUANTITY * PRICE) AS REVENUE_COLLECTED
		FROM
			SALES_RECORD
		GROUP BY
			PIZZA_ID
	),
	TOTAL AS (
		SELECT
			SUM(REVENUE_COLLECTED) AS TOTAL_SUM
		FROM
			REVENUE_DISTRIBUTION
	)
SELECT
	RD.PIZZA_ID,
	RD.REVENUE_COLLECTED,
	ROUND(RD.REVENUE_COLLECTED / T.TOTAL_SUM * 100, 2) AS PERCENT_DISTRIBUTION
FROM
	REVENUE_DISTRIBUTION RD
	CROSS JOIN TOTAL T
ORDER BY
	PERCENT_DISTRIBUTION DESC;


--Analyze cumilative revenue generated over time
WITH
	SALES_REPORT AS (
		SELECT
			PIZZA_ID,
			"DATE",
			SUM(QUANTITY * PRICE) AS REVENUE_COLLECTED
		FROM
			SALES_RECORD
		GROUP BY
			PIZZA_ID,
			"DATE"
		ORDER BY
			"DATE" ASC
	),
	TOTAL_REVENUE AS (
		SELECT
			"DATE",
			SUM(REVENUE_COLLECTED) AS TOTAL_REVENUE_PER_DAY
		FROM
			SALES_REPORT
		GROUP BY
			"DATE"
		ORDER BY
			"DATE"
	),
	CUMILATIVE_CALC AS (
		SELECT
			TOTAL_REVENUE_PER_DAY,
			"DATE",
			SUM(TOTAL_REVENUE_PER_DAY) OVER (
				ORDER BY
					"DATE" ROWS BETWEEN UNBOUNDED PRECEDING
					AND CURRENT ROW
			) AS CUMILATIVE_REVENUE
		FROM
			TOTAL_REVENUE
	)
SELECT
	"DATE",
	TOTAL_REVENUE_PER_DAY,
	CUMILATIVE_REVENUE
FROM
	CUMILATIVE_CALC;

--TOP  3 TYPES OF PIZZAS PER CATEGORY ON THE BASIS OF REVENUE
WITH 
RANKED_PIZZA AS 
(
	SELECT
	PM.CATEGORY AS CATEGORY,PM.PIZZA_NAME AS PIZZA_NAME,
	SUM(SR.QUANTITY * PM.PRICE) AS REVENUE,
	RANK() OVER (PARTITION BY PM.CATEGORY ORDER BY (SUM(SR.QUANTITY * PM.PRICE)) DESC) AS RANKING
FROM
	SALES_RECORD SR
	JOIN PIZZA_MENU PM ON SR.PIZZA_ID = PM.PIZZA_ID
GROUP BY
	PM.CATEGORY,PM.PIZZA_NAME)

SELECT CATEGORY,PIZZA_NAME,REVENUE,RANKING
FROM
RANKED_PIZZA
WHERE
RANKING<=3;


--REPORT
--this is the piza sales analysis for the year 2015

-- Findings
--a. The maximum revenue was generated in the month of July with a total revenue of $72557.90,followed by May 
--with the total revenue of $71402.74.
--b. The least Revenue was generated in the month of october with a total revenue of $64027.60
--c. Amongst all types of pizza The Greek Pizza was the least ordered pizza followed by the green_garden_l aand ckn_alfredo_s
--d. where as The big meat Pizza tops the table as the most ordered pizza followed by thai_ckn_l and five_cheese_l, 
--e. Amongst all the sizes large size is the most ordered pizza followed by medium and XXl is the least size ordered.
--f. The highest price pizza is The Greek Pizza with a price of 35.95$
--g. The lowest priced pizza is The pepperoni Pizza with a price tag of 9.75$
--h. On the basis of category Classic pizzas are the most ordered pizza and chicken pizzas are the least ordered pizza
--i. It can be found that at around 12 in the afternoon the higest number of orders has been placed followed by 1 pm which 
--  is considered a lunch break time in most regions and the least order has been placed during early morning at 9 am.
--j. avg of approx 138 pizzas are being ordered per day
--k. The Thai Chicken Pizza has generated the most revenue of 43434.25$ followed by The Barbecue Chicken pizza with a 
--   revenue of 42768$ and The California Chicken Pizz with a total revenue of 41409.50$
--l. the thai chicken pizza contributes a maximum of 3.58% in our total revenue 
