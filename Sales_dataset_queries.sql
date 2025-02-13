-- Updating Region for each city
-- This step helps us to remove null values and also helps in data cleaning

--SELECT DISTINCT(Region)
--FROM dbo.sales
--WHERE City IN ('Ahemdabad','Mumbai','Pune')
	
--BEGIN Transaction

--UPDATE dbo.sales
--SET Region = 'East'
--WHERE City IN ('Ahemdabad','Mumbai','Pune')

--ROLLBACK Transaction

--COMMIT Transaction

--  Which city has the highest total sales, and how do sales vary across cities & region?

SELECT 
	 CONVERT(VARCHAR , CAST(SUM(TransactionAmount) AS money), 1) AS [Total_Sales]
	,CITY
	,Region
FROM dbo.sales
GROUP BY CITY
		,Region
ORDER BY [Total_Sales] DESC

-- What are the top-selling products by city, region & store type?

SELECT
	 ProductName
	,CONVERT(VARCHAR , CAST(SUM(TransactionAmount) AS money), 1) AS [Total_Sales]
	,CITY
	,Region
	,StoreType
FROM dbo.sales
WHERE ProductName IS NOT NULL AND StoreType IS NOT NULL 
GROUP BY ProductName
		 ,CITY
		 ,Region
		 ,StoreType
ORDER BY [Total_Sales] DESC

-- What products have the longest average delivery time & does delivery time impact return rates?

SELECT 
     ProductName
    ,AVG(DeliveryTimeDays) AS Avg_Delivery_Days
    ,SUM(CASE WHEN Returned = 0 THEN 1 END) AS Not_Returned
    ,SUM(CASE WHEN Returned = 1 THEN 1 END) AS Returned_Count
	,CAST((SUM(CASE WHEN Returned = 1 THEN 1 END) * 100.0/ COUNT(*)) AS DECIMAL(4,2)) AS Return_Rate
FROM dbo.sales
WHERE ProductName IS NOT NULL
GROUP BY ProductName
ORDER BY Avg_Delivery_Days DESC

-- Are returns more frequent for certain products, cities or store types?

SELECT 
     ProductName
	,CITY
	,StoreType
    ,CAST((SUM(CASE WHEN Returned = 1 THEN 1 END) * 100.0/ COUNT(*)) AS DECIMAL(4,2)) AS Return_Rate
FROM dbo.sales
WHERE ProductName IS NOT NULL AND StoreType IS NOT NULL
GROUP BY ProductName
		,CITY
	    ,StoreType
ORDER BY Return_Rate DESC

-- How does feedback vary by region & store type?

SELECT
	City
	,Region
	,StoreType
	,AVG(FeedbackScore) AS [Avg_Feedback_Store]
FROM dbo.sales
WHERE StoreType IS NOT NULL
GROUP BY City
	 ,Region
	,StoreType
ORDER BY [Avg_Feedback_Store] DESC

-- How does sales volume change when a product is under promotion?

SELECT 
    ProductName,
    CONVERT(VARCHAR, CAST(SUM(CASE WHEN IsPromotional = 0 THEN TransactionAmount ELSE 0 END) AS MONEY), 1) AS Non_Promotional_Sales,
    CONVERT(VARCHAR, CAST(SUM(CASE WHEN IsPromotional = 1 THEN TransactionAmount ELSE 0 END) AS MONEY), 1) AS Promotional_Sales
FROM dbo.sales
WHERE ProductName IS NOT NULL
GROUP BY ProductName
ORDER BY ProductName

-- Do promotions lead to more returns?

SELECT 
    IsPromotional
    ,COUNT(*) AS Total_Transactions
    ,SUM(CASE WHEN Returned = 1 THEN 1 ELSE 0 END) AS Returned_Transactions
    ,CAST((SUM(CASE WHEN Returned = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS DECIMAL(4,2)) AS Return_Rate_Percentage
FROM dbo.sales
GROUP BY IsPromotional

-- Which payment method is used the most & which contributes the highest revenue?

SELECT 
    PaymentMethod
    ,COUNT(*) AS Transaction_Count
    ,CONVERT(VARCHAR , CAST(SUM(TransactionAmount) AS money), 1) AS [Total_Transaction]
FROM dbo.sales
WHERE PaymentMethod IS NOT NULL
GROUP BY PaymentMethod
ORDER BY [Total_Transaction] DESC

-- Do customers with high loyalty points spend more per transaction?

SELECT 
    CASE 
        WHEN LoyaltyPoints < 100 THEN 'Low Loyalty'
        WHEN LoyaltyPoints BETWEEN 100 AND 500 THEN 'Medium Loyalty'
        ELSE 'High Loyalty'
    END AS Loyalty_Level,
    COUNT(DISTINCT CustomerID) AS Customer_Count,
    CONVERT(VARCHAR , CAST(AVG(TransactionAmount) AS money), 1) AS Avg_Spend_Per_Transaction
FROM dbo.sales
GROUP BY 
    CASE 
        WHEN LoyaltyPoints < 100 THEN 'Low Loyalty'
        WHEN LoyaltyPoints BETWEEN 100 AND 500 THEN 'Medium Loyalty'
        ELSE 'High Loyalty'
    END
ORDER BY Avg_Spend_Per_Transaction DESC


-- What percentage of transactions come from repeat customers?

WITH CustomerTransactionCounts AS (
    SELECT 
        CustomerID 
        ,COUNT(*) AS Transaction_Count
    FROM dbo.sales
    GROUP BY CustomerID
)
SELECT 
    CASE 
        WHEN ctc.Transaction_Count = 1 THEN 'New Customer'
        ELSE 'Repeat Customer'
    END AS Customer_Type
    ,COUNT(s.TransactionID) AS Transaction_Count
    ,CAST((COUNT(s.TransactionID) * 100.0 / (SELECT COUNT(*) FROM dbo.sales)) AS DECIMAL(4,2))AS Percentage_Of_Total
FROM dbo.sales s
JOIN CustomerTransactionCounts ctc ON s.CustomerID = ctc.CustomerID
GROUP BY 
    CASE 
        WHEN ctc.Transaction_Count = 1 THEN 'New Customer'
        ELSE 'Repeat Customer'
    END