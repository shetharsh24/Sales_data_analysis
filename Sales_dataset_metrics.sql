-- Generating metrics for sales dataset, although I would prefer a BI tool but since it was highligted that we are suppose
-- to use only sql hence using sql to write the queries

-- Metric : Total Sales Revenue
-- In dataviz once we create this metric we can apply different criteria to see it's effect

SELECT
	CONVERT(VARCHAR , CAST(SUM(TransactionAmount) AS money), 1) AS [Total_Sales]
FROM dbo.sales

-- Metric : Average Transaction Value (ATV)
-- Can be used for segragation of customers, pricing of products & to see if we put products in promotion can it drives higher sales?

SELECT
	CONVERT(VARCHAR , CAST(AVG(TransactionAmount) AS money), 1) AS [Avg_Total_Sales]
FROM dbo.sales

-- Metric : Sales Growth Rate (%)
-- Helps to know about the seasonality of product, whether we need to do any promotional activity for month or no if sales is decreasing

with sales_cte
AS
(SELECT
	MONTH(TransactionDate) AS [Month]
	,CAST(SUM(TransactionAmount) AS money) AS [Total_month_sales]
	,ISNULL(LAG(CAST(SUM(TransactionAmount) AS money)) OVER (ORDER BY MONTH(TransactionDate)),0) AS [Prev_month_sales]
FROM dbo.sales
WHERE MONTH(TransactionDate) IS NOT NULL
GROUP BY MONTH(TransactionDate))
SELECT *,
	CASE WHEN [Prev_month_sales] = 0 THEN 1
	ELSE ([Total_month_sales] - [Prev_month_sales])/[Prev_month_sales] * 100
	END AS [Sales_percent_MoM_growth]
FROM sales_cte

-- Top-Selling Products
-- Usually a breakdown of products by viz tool can help us to drill down into each products individually

SELECT
	ProductName
	,CONVERT(VARCHAR , CAST(SUM(TransactionAmount) AS money), 1) AS [Product_Sales]
FROM dbo.sales
WHERE ProductName IS NOT NULL
GROUP BY ProductName
ORDER BY Product_Sales DESC

-- Return Rate (%)
-- Helps us to analyze which products are returned more & what can we do to improve

SELECT 
     ProductName
	,CAST((SUM(CASE WHEN Returned = 1 THEN 1 END) * 100.0/ COUNT(*)) AS DECIMAL(4,2)) AS Return_Rate
FROM dbo.sales
WHERE ProductName IS NOT NULL
GROUP BY ProductName
ORDER BY Return_Rate DESC

-- Average Delivery Time (Days)
-- This combined with return rate can give us a good picture of what needs to be improved

SELECT ProductName
	  ,AVG(DeliveryTimeDays) AS Avg_Delivery_Days
FROM dbo.sales
WHERE ProductName IS NOT NULL
GROUP BY ProductName
ORDER BY Avg_Delivery_Days DESC

-- Promotional Sales Lift (%)
-- Tells us the effectiveness of promotions that we do

with promotion_cte
AS
(SELECT 
    ProductName,
    CAST(SUM(CASE WHEN IsPromotional = 0 THEN TransactionAmount ELSE 0 END) AS MONEY) AS Non_Promotional_Sales,
    CAST(SUM(CASE WHEN IsPromotional = 1 THEN TransactionAmount ELSE 0 END) AS MONEY) AS Promotional_Sales
FROM dbo.sales
WHERE ProductName IS NOT NULL
GROUP BY ProductName)
SELECT *,
		(Promotional_Sales - Non_Promotional_Sales) * 100/Non_Promotional_Sales AS [Promotional_sales_%]
FROM promotion_cte
ORDER BY [Promotional_sales_%] DESC

-- Payment Method Preference (%)
-- Certain payment methods offer discounts while shopping so we can encourage users to buy products by giving discounts

SELECT
	PaymentMethod
	,CAST(COUNT(*) * 100.0/ (SELECT COUNT(*) FROM dbo.sales WHERE PaymentMethod IS NOT NULL) AS DECIMAL(4,2)) AS [Payment_preference_%]
FROM dbo.sales
WHERE PaymentMethod IS NOT NULL
GROUP BY PaymentMethod

-- Average Feedback Score
-- Helps us to know how they rate the product

SELECT
	ProductName	
	,AVG(FeedbackScore) AS [Avg_Feedback_Store]
FROM dbo.sales
WHERE ProductName IS NOT NULL
GROUP BY ProductName
ORDER BY [Avg_Feedback_Store] DESC














