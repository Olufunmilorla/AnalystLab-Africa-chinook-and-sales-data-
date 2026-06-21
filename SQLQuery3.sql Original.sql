/* ==========================================================
ANALYSTLAB AFRICA – WEEK 3
SQL & DATA QUERYING PROJECT

Database: SalesAnalysis
Table: sales_data_

Objective:
Analyze sales performance, customer behavior,
product performance, and revenue trends using SQL.
========================================================== */

/* ==========================================================
SECTION 1: DATA QUALITY CHECKS
========================================================== */

-- Total Records

SELECT
COUNT(*) AS TotalRows
FROM sales_data_;

-- Check for Null Values

SELECT
SUM(CASE WHEN ORDERNUMBER IS NULL THEN 1 ELSE 0 END) AS NullOrderNumber,
SUM(CASE WHEN CUSTOMERNAME IS NULL THEN 1 ELSE 0 END) AS NullCustomer,
SUM(CASE WHEN PRODUCTCODE IS NULL THEN 1 ELSE 0 END) AS NullProduct,
SUM(CASE WHEN SALES IS NULL THEN 1 ELSE 0 END) AS NullSales
FROM sales_data_;

-- Check for Duplicate Orders

SELECT
ORDERNUMBER,
COUNT(*) AS DuplicateCount
FROM sales_data_
GROUP BY ORDERNUMBER
HAVING COUNT(*) > 1;

/* ==========================================================
SECTION 2: CORE SQL QUERIES
SELECT, WHERE, ORDER BY
========================================================== */

-- Retrieve all shipped orders

SELECT
ORDERNUMBER,
CUSTOMERNAME,
COUNTRY,
SALES,
STATUS
FROM sales_data_
WHERE STATUS = 'Shipped'
ORDER BY SALES DESC;

-- Highest value sales transactions

SELECT TOP 20
ORDERNUMBER,
CUSTOMERNAME,
PRODUCTLINE,
SALES
FROM sales_data_
ORDER BY SALES DESC;

/* ==========================================================
GROUP BY & HAVING
========================================================== */

-- Revenue by Product Line

SELECT
PRODUCTLINE,
SUM(SALES) AS TotalRevenue
FROM sales_data_
GROUP BY PRODUCTLINE
ORDER BY TotalRevenue DESC;

-- Product Lines generating over $1M

SELECT
PRODUCTLINE,
SUM(SALES) AS TotalRevenue
FROM sales_data_
GROUP BY PRODUCTLINE
HAVING SUM(SALES) > 1000000
ORDER BY TotalRevenue DESC;

/* ==========================================================
AGGREGATE FUNCTIONS
========================================================== */

SELECT
COUNT(DISTINCT ORDERNUMBER) AS TotalOrders,
COUNT(DISTINCT CUSTOMERNAME) AS TotalCustomers,
SUM(SALES) AS TotalRevenue,
AVG(SALES) AS AverageSalesValue,
MAX(SALES) AS HighestSale,
MIN(SALES) AS LowestSale
FROM sales_data_;

/* ==========================================================
SECTION 3: BUSINESS PROBLEM SOLVING
========================================================== */

-- Top 10 Customers by Revenue

SELECT TOP 10
CUSTOMERNAME,
SUM(SALES) AS RevenueGenerated
FROM sales_data_
GROUP BY CUSTOMERNAME
ORDER BY RevenueGenerated DESC;

-- Top 10 Products by Revenue

SELECT TOP 10
PRODUCTCODE,
PRODUCTLINE,
SUM(SALES) AS RevenueGenerated
FROM sales_data_
GROUP BY PRODUCTCODE, PRODUCTLINE
ORDER BY RevenueGenerated DESC;

-- Top 10 Products by Quantity Sold

SELECT TOP 10
PRODUCTCODE,
SUM(QUANTITYORDERED) AS UnitsSold
FROM sales_data_
GROUP BY PRODUCTCODE
ORDER BY UnitsSold DESC;

-- Revenue by Country

SELECT
COUNTRY,
SUM(SALES) AS Revenue
FROM sales_data_
GROUP BY COUNTRY
ORDER BY Revenue DESC;

-- Revenue by Territory

SELECT
TERRITORY,
SUM(SALES) AS Revenue
FROM sales_data_
GROUP BY TERRITORY
ORDER BY Revenue DESC;

-- Monthly Revenue Trend

SELECT
YEAR_ID,
MONTH_ID,
SUM(SALES) AS MonthlyRevenue
FROM sales_data_
GROUP BY YEAR_ID, MONTH_ID
ORDER BY YEAR_ID, MONTH_ID;

-- Quarterly Revenue Trend

SELECT
YEAR_ID,
QTR_ID,
SUM(SALES) AS QuarterlyRevenue
FROM sales_data_
GROUP BY YEAR_ID, QTR_ID
ORDER BY YEAR_ID, QTR_ID;

/* ==========================================================
SECTION 4: ADVANCED SQL
========================================================== */

-- Create Customer Lookup Table

SELECT DISTINCT
CUSTOMERNAME,
COUNTRY,
CITY,
TERRITORY
INTO Customers
FROM sales_data_;

/* ==========================================================
INNER JOIN
========================================================== */

SELECT
s.ORDERNUMBER,
s.CUSTOMERNAME,
s.SALES,
c.COUNTRY
FROM sales_data_ s
INNER JOIN Customers c
ON s.CUSTOMERNAME = c.CUSTOMERNAME;

/* ==========================================================
LEFT JOIN
========================================================== */

SELECT
c.CUSTOMERNAME,
c.COUNTRY,
ISNULL(SUM(s.SALES),0) AS Revenue
FROM Customers c
LEFT JOIN sales_data_ s
ON c.CUSTOMERNAME = s.CUSTOMERNAME
GROUP BY c.CUSTOMERNAME, c.COUNTRY;

/* ==========================================================
RIGHT JOIN
========================================================== */

SELECT
s.ORDERNUMBER,
s.SALES,
c.CUSTOMERNAME
FROM sales_data_ s
RIGHT JOIN Customers c
ON s.CUSTOMERNAME = c.CUSTOMERNAME;

/* ==========================================================
SUBQUERY
========================================================== */

-- Customers spending above average

SELECT
CUSTOMERNAME,
SUM(SALES) AS CustomerRevenue
FROM sales_data_
GROUP BY CUSTOMERNAME
HAVING SUM(SALES) >
(
SELECT AVG(CustomerRevenue)
FROM
(
SELECT
SUM(SALES) AS CustomerRevenue
FROM sales_data_
GROUP BY CUSTOMERNAME
) x
)
ORDER BY CustomerRevenue DESC;

/* ==========================================================
WINDOW FUNCTIONS
========================================================== */

-- Rank customers by revenue

SELECT
CUSTOMERNAME,
SUM(SALES) AS TotalRevenue,
RANK() OVER
(
ORDER BY SUM(SALES) DESC
) AS RevenueRank
FROM sales_data_
GROUP BY CUSTOMERNAME;

-- Row Number within Product Line

SELECT
PRODUCTLINE,
PRODUCTCODE,
SALES,
ROW_NUMBER() OVER
(
PARTITION BY PRODUCTLINE
ORDER BY SALES DESC
) AS RowNum
FROM sales_data_;

-- Top Product in each Product Line

WITH RankedProducts AS
(
SELECT
PRODUCTLINE,
PRODUCTCODE,
SUM(SALES) AS Revenue,
ROW_NUMBER() OVER
(
PARTITION BY PRODUCTLINE
ORDER BY SUM(SALES) DESC
) AS ProductRank
FROM sales_data_
GROUP BY PRODUCTLINE, PRODUCTCODE
)
SELECT *
FROM RankedProducts
WHERE ProductRank = 1;

/* ==========================================================
CUSTOMER PURCHASING BEHAVIOR
========================================================== */

SELECT
CUSTOMERNAME,
COUNT(DISTINCT ORDERNUMBER) AS NumberOfOrders,
SUM(SALES) AS TotalSpent,
AVG(SALES) AS AveragePurchaseValue,
SUM(CASE
WHEN DEALSIZE = 'Large'
THEN 1
ELSE 0
END) AS LargeDeals
FROM sales_data_
GROUP BY CUSTOMERNAME
ORDER BY TotalSpent DESC;

/* ==========================================================
QUERY OPTIMIZATION
========================================================== */

-- Create Indexes

CREATE INDEX IX_CustomerName
ON sales_data_(CUSTOMERNAME);

CREATE INDEX IX_ProductCode
ON sales_data_(PRODUCTCODE);

CREATE INDEX IX_OrderDate
ON sales_data_(ORDERDATE);

CREATE INDEX IX_Country
ON sales_data_(COUNTRY);

-- Verify Query Performance

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
CUSTOMERNAME,
SUM(SALES) AS Revenue
FROM sales_data_
GROUP BY CUSTOMERNAME;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
