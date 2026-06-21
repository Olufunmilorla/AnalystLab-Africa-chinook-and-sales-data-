/*==============================================================================
  ANALYSTTLAB AFRICA – WEEK 3: SQL & DATA QUERYING
  Database : Chinook (Music Store)
  Author   : Olufunmilola
  Date     : June 2026
  Purpose  : Business-driven SQL analysis covering core querying, joins,
             subqueries, window functions, and query optimisation.
==============================================================================*/


/*==============================================================================
  SECTION 1 – DATABASE OVERVIEW
  Understand the tables, row counts, and key relationships before querying.
==============================================================================*/

-- 1.1  List all tables (SQL Server / Azure SQL syntax)

SELECT TABLE_NAME
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_TYPE = 'BASE TABLE'
ORDER  BY TABLE_NAME;

-- 1.2  Row counts for every table

SELECT 'Album'       AS TableName, COUNT(*) AS TotalRows FROM Album       UNION ALL
SELECT 'Artist',                   COUNT(*)              FROM Artist      UNION ALL
SELECT 'Customer',                 COUNT(*)              FROM Customer    UNION ALL
SELECT 'Employee',                 COUNT(*)              FROM Employee    UNION ALL
SELECT 'Genre',                    COUNT(*)              FROM Genre       UNION ALL
SELECT 'Invoice',                  COUNT(*)              FROM Invoice     UNION ALL
SELECT 'InvoiceLine',              COUNT(*)              FROM InvoiceLine UNION ALL
SELECT 'MediaType',                COUNT(*)              FROM MediaType   UNION ALL
SELECT 'Playlist',                 COUNT(*)              FROM Playlist    UNION ALL
SELECT 'PlaylistTrack',            COUNT(*)              FROM PlaylistTrack UNION ALL
SELECT 'Track',                    COUNT(*)              FROM Track
ORDER  BY TableName;





/*==============================================================================
  SECTION 2 – CORE SQL QUERIES
  SELECT · WHERE · ORDER BY · GROUP BY · HAVING · Aggregate Functions
==============================================================================*/

-- 2.1  All customers sorted alphabetically by last name

SELECT CustomerId,
       FirstName,
       LastName,
       Country,
       Email
FROM   Customer
ORDER  BY LastName, FirstName;


-- 2.2  Tracks priced above the standard $0.99

SELECT TrackId,
       Name        AS TrackName,
       UnitPrice
FROM   Track
WHERE  UnitPrice > 0.99
ORDER  BY UnitPrice DESC;


-- 2.3  Total revenue per country (only countries with > $50 in sales)

SELECT   BillingCountry          AS Country,
         COUNT(InvoiceId)        AS NumberOfInvoices,
         ROUND(SUM(Total), 2)    AS TotalRevenue
FROM     Invoice
GROUP BY BillingCountry
HAVING   SUM(Total) > 50
ORDER BY TotalRevenue DESC;


-- 2.4  Average invoice value by year

SELECT   YEAR(InvoiceDate)        AS InvoiceYear,
         COUNT(InvoiceId)         AS InvoiceCount,
         ROUND(AVG(Total), 2)     AS AvgInvoiceValue,
         ROUND(SUM(Total), 2)     AS TotalRevenue
FROM     Invoice
GROUP BY YEAR(InvoiceDate)
ORDER BY InvoiceYear;



-- 2.5  Number of tracks per genre, descending

SELECT   g.Name      AS Genre,
         COUNT(t.TrackId) AS TrackCount
FROM     Track t
JOIN     Genre g ON t.GenreId = g.GenreId
GROUP BY g.Name
ORDER BY TrackCount DESC;






/*==============================================================================
  SECTION 3 – JOINS
  INNER JOIN · LEFT JOIN · multi-table joins
==============================================================================*/

-- 3.1  INNER JOIN – Track details with album and artist

SELECT t.Name            AS Track,
       al.Title          AS Album,
       ar.Name           AS Artist,
       g.Name            AS Genre,
       mt.Name           AS MediaType,
       t.UnitPrice,
       ROUND(t.Milliseconds / 60000.0, 2) AS DurationMinutes
FROM   Track        t
JOIN   Album        al ON t.AlbumId      = al.AlbumId
JOIN   Artist       ar ON al.ArtistId    = ar.ArtistId
JOIN   Genre        g  ON t.GenreId      = g.GenreId
JOIN   MediaType    mt ON t.MediaTypeId  = mt.MediaTypeId
ORDER  BY ar.Name, al.Title, t.Name;



-- 3.2  LEFT JOIN – All customers including those with no invoice
--      (identifies inactive / never-purchased customers)

SELECT   c.CustomerId,
         c.FirstName + ' ' + c.LastName  AS CustomerName,
         c.Country,
         COUNT(i.InvoiceId)              AS TotalPurchases,
         ISNULL(ROUND(SUM(i.Total),2), 0) AS TotalSpent
FROM     Customer c
LEFT JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
ORDER BY TotalSpent DESC;



-- 3.3  Sales rep performance – employee linked to their customers' revenue

SELECT   e.EmployeeId,
         e.FirstName + ' ' + e.LastName   AS SalesRep,
         e.Title,
         COUNT(DISTINCT c.CustomerId)      AS CustomersManaged,
         COUNT(i.InvoiceId)               AS TotalInvoices,
         ROUND(SUM(i.Total), 2)           AS TotalRevenue
FROM     Employee e
JOIN     Customer c ON e.EmployeeId = c.SupportRepId
JOIN     Invoice  i ON c.CustomerId = i.CustomerId
GROUP BY e.EmployeeId, e.FirstName, e.LastName, e.Title
ORDER BY TotalRevenue DESC;


-- 3.4  Invoice line detail – full purchase breakdown

SELECT   i.InvoiceId,
         i.InvoiceDate,
         c.FirstName + ' ' + c.LastName AS Customer,
         c.Country,
         t.Name   AS Track,
         ar.Name  AS Artist,
         il.UnitPrice,
         il.Quantity,
         ROUND(il.UnitPrice * il.Quantity, 2) AS LineTotal
FROM     InvoiceLine il
JOIN     Invoice     i  ON il.InvoiceId = i.InvoiceId
JOIN     Customer    c  ON i.CustomerId = c.CustomerId
JOIN     Track       t  ON il.TrackId   = t.TrackId
JOIN     Album       al ON t.AlbumId    = al.AlbumId
JOIN     Artist      ar ON al.ArtistId  = ar.ArtistId
ORDER BY i.InvoiceDate DESC, i.InvoiceId;





/*==============================================================================
  SECTION 4 – SUBQUERIES
==============================================================================*/

-- 4.1  Customers who have spent more than the overall average spend

SELECT   c.FirstName + ' ' + c.LastName AS CustomerName,
         c.Country,
         ROUND(SUM(i.Total), 2)          AS TotalSpent
FROM     Customer c
JOIN     Invoice  i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
HAVING   SUM(i.Total) > (
             SELECT AVG(CustomerTotal)
             FROM (
                 SELECT CustomerId, SUM(Total) AS CustomerTotal
                 FROM   Invoice
                 GROUP  BY CustomerId
             ) sub
         )
ORDER BY TotalSpent DESC;



-- 4.2  Top-selling track (by units sold)

SELECT   TOP 1
         t.Name          AS Track,
         ar.Name         AS Artist,
         SUM(il.Quantity) AS UnitsSold
FROM     InvoiceLine il
JOIN     Track  t  ON il.TrackId  = t.TrackId
JOIN     Album  al ON t.AlbumId   = al.AlbumId
JOIN     Artist ar ON al.ArtistId = ar.ArtistId
GROUP BY t.TrackId, t.Name, ar.Name
ORDER BY UnitsSold DESC;



-- 4.3  Albums that contain at least one track with price above $0.99

SELECT DISTINCT al.Title  AS Album,
                ar.Name   AS Artist
FROM   Album  al
JOIN   Artist ar ON al.ArtistId = ar.ArtistId
WHERE  al.AlbumId IN (
           SELECT DISTINCT AlbumId
           FROM   Track
           WHERE  UnitPrice > 0.99
       )
ORDER BY ar.Name, al.Title;


-- 4.4  Employees who manage more customers than the average employee does

SELECT   e.FirstName + ' ' + e.LastName AS SalesRep,
         COUNT(c.CustomerId)             AS CustomerCount
FROM     Employee e
JOIN     Customer c ON e.EmployeeId = c.SupportRepId
GROUP BY e.EmployeeId, e.FirstName, e.LastName
HAVING   COUNT(c.CustomerId) > (
             SELECT AVG(CustomerCount)
             FROM (
                 SELECT SupportRepId, COUNT(*) AS CustomerCount
                 FROM   Customer
                 WHERE  SupportRepId IS NOT NULL
                 GROUP  BY SupportRepId
             ) sub
         )
ORDER BY CustomerCount DESC;




/*==============================================================================
  SECTION 5 – WINDOW FUNCTIONS
  ROW_NUMBER · RANK · DENSE_RANK · PARTITION BY · Running Totals
==============================================================================*/

-- 5.1  Top 5 customers per country by total spend (PARTITION BY country)

WITH CustomerSpend AS (
    SELECT   c.CustomerId,
             c.FirstName + ' ' + c.LastName AS CustomerName,
             c.Country,
             ROUND(SUM(i.Total), 2)          AS TotalSpent
    FROM     Customer c
    JOIN     Invoice  i ON c.CustomerId = i.CustomerId
    GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
)
SELECT *
FROM (
    SELECT CustomerName,
           Country,
           TotalSpent,
           RANK() OVER (PARTITION BY Country ORDER BY TotalSpent DESC) AS RankInCountry
    FROM   CustomerSpend
) ranked
WHERE  RankInCountry <= 5
ORDER BY Country, RankInCountry;


-- 5.2  Top 10 best-selling tracks overall with dense rank

SELECT TOP 10
       TrackName,
       Artist,
       UnitsSold,
       Revenue,
       DENSE_RANK() OVER (ORDER BY UnitsSold DESC) AS SalesRank
FROM (
    SELECT   t.Name           AS TrackName,
             ar.Name          AS Artist,
             SUM(il.Quantity) AS UnitsSold,
             ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS Revenue
    FROM     InvoiceLine il
    JOIN     Track  t  ON il.TrackId  = t.TrackId
    JOIN     Album  al ON t.AlbumId   = al.AlbumId
    JOIN     Artist ar ON al.ArtistId = ar.ArtistId
    GROUP BY t.TrackId, t.Name, ar.Name
) sales
ORDER BY SalesRank;



-- 5.3  Monthly revenue with running total
SELECT   InvoiceYear,
         InvoiceMonth,
         MonthlyRevenue,
         ROUND(SUM(MonthlyRevenue) OVER (
             PARTITION BY InvoiceYear
             ORDER BY InvoiceMonth
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
         ), 2) AS YTD_Revenue
FROM (
    SELECT   YEAR(InvoiceDate)            AS InvoiceYear,
             MONTH(InvoiceDate)           AS InvoiceMonth,
             ROUND(SUM(Total), 2)         AS MonthlyRevenue
    FROM     Invoice
    GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
) monthly
ORDER BY InvoiceYear, InvoiceMonth;



-- 5.4  Revenue contribution % per genre (window function approach)
SELECT   Genre,
         TotalRevenue,
         ROUND(
             TotalRevenue * 100.0 / SUM(TotalRevenue) OVER (),
         2) AS RevenueSharePct
FROM (
    SELECT   g.Name                                     AS Genre,
             ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS TotalRevenue
    FROM     InvoiceLine il
    JOIN     Track t ON il.TrackId  = t.TrackId
    JOIN     Genre g ON t.GenreId   = g.GenreId
    GROUP BY g.GenreId, g.Name
) genre_revenue
ORDER BY TotalRevenue DESC;



-- 5.5  Customer purchase sequence – ROW_NUMBER per customer
SELECT   c.FirstName + ' ' + c.LastName AS CustomerName,
         i.InvoiceDate,
         i.Total,
         ROW_NUMBER() OVER (
             PARTITION BY c.CustomerId
             ORDER BY i.InvoiceDate
         ) AS PurchaseNumber
FROM     Customer c
JOIN     Invoice  i ON c.CustomerId = i.CustomerId
ORDER BY CustomerName, PurchaseNumber;





/*==============================================================================
  SECTION 6 – BUSINESS INTELLIGENCE QUERIES
  Answering key analytical questions for the music store
==============================================================================*/

-- 6.1  QUESTION: Who are the top 10 customers by lifetime value?

SELECT   TOP 10
         c.CustomerId,
         c.FirstName + ' ' + c.LastName    AS CustomerName,
         c.Country,
         c.Email,
         COUNT(i.InvoiceId)                AS TotalOrders,
         ROUND(SUM(i.Total), 2)            AS LifetimeValue,
         ROUND(AVG(i.Total), 2)            AS AvgOrderValue
FROM     Customer c
JOIN     Invoice  i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country, c.Email
ORDER BY LifetimeValue DESC;


-- 6.2  QUESTION: What are the top 5 revenue-generating countries?

SELECT   TOP 5
         BillingCountry                    AS Country,
         COUNT(DISTINCT CustomerId)        AS UniqueCustomers,
         COUNT(InvoiceId)                  AS Invoices,
         ROUND(SUM(Total), 2)              AS TotalRevenue,
         ROUND(AVG(Total), 2)              AS AvgOrderValue
FROM     Invoice
GROUP BY BillingCountry
ORDER BY TotalRevenue DESC;



-- 6.3  QUESTION: Which genres drive the most revenue?

SELECT   g.Name                                      AS Genre,
         COUNT(DISTINCT t.TrackId)                   AS TrackCount,
         SUM(il.Quantity)                            AS UnitsSold,
         ROUND(SUM(il.UnitPrice * il.Quantity), 2)  AS Revenue
FROM     InvoiceLine il
JOIN     Track  t ON il.TrackId = t.TrackId
JOIN     Genre  g ON t.GenreId  = g.GenreId
GROUP BY g.GenreId, g.Name
ORDER BY Revenue DESC;



-- 6.4  QUESTION: What does monthly revenue look like over time? (trend analysis)

SELECT   YEAR(InvoiceDate)   AS Year,
         MONTH(InvoiceDate)  AS Month,
         DATENAME(MONTH, InvoiceDate) AS MonthName,
         COUNT(InvoiceId)    AS InvoiceCount,
         ROUND(SUM(Total), 2) AS Revenue
FROM     Invoice
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate), DATENAME(MONTH, InvoiceDate)
ORDER BY Year, Month;


-- 6.5  QUESTION: Which artists generate the most revenue?

SELECT   TOP 10
         ar.Name                                      AS Artist,
         COUNT(DISTINCT al.AlbumId)                   AS Albums,
         COUNT(DISTINCT t.TrackId)                    AS Tracks,
         SUM(il.Quantity)                             AS UnitsSold,
         ROUND(SUM(il.UnitPrice * il.Quantity), 2)   AS Revenue
FROM     InvoiceLine il
JOIN     Track  t  ON il.TrackId  = t.TrackId
JOIN     Album  al ON t.AlbumId   = al.AlbumId
JOIN     Artist ar ON al.ArtistId = ar.ArtistId
GROUP BY ar.ArtistId, ar.Name
ORDER BY Revenue DESC;


-- 6.6  QUESTION: What is the customer churn / purchase frequency distribution?

SELECT   PurchaseCount,
         COUNT(*) AS Customers
FROM (
    SELECT   CustomerId,
             COUNT(InvoiceId) AS PurchaseCount
    FROM     Invoice
    GROUP BY CustomerId
) freq
GROUP BY PurchaseCount
ORDER BY PurchaseCount;


-- 6.7  QUESTION: Which media type is most popular by track count and sales?

SELECT   mt.Name                                     AS MediaType,
         COUNT(DISTINCT t.TrackId)                   AS TrackCount,
         SUM(il.Quantity)                            AS UnitsSold,
         ROUND(SUM(il.UnitPrice * il.Quantity), 2)  AS Revenue
FROM     Track       t
JOIN     MediaType   mt ON t.MediaTypeId = mt.MediaTypeId
LEFT JOIN InvoiceLine il ON t.TrackId   = il.TrackId
GROUP BY mt.MediaTypeId, mt.Name
ORDER BY Revenue DESC;



/*==============================================================================
  SECTION 7 – QUERY OPTIMISATION
  Indexing recommendations and efficient query patterns

  Existing Index Review
Verified existing indexes on key tables.
Confirmed indexes on CustomerId, InvoiceId, TrackId, AlbumId, GenreId, and SupportRepId.
==============================================================================*/


SELECT
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.indexes i
JOIN sys.tables t
    ON i.object_id = t.object_id
WHERE i.name IS NOT NULL
ORDER BY t.name, i.name;





/*==============================================================================
  END OF SCRIPT
==============================================================================*/
