-- כתבו שאילתא אשר מציגה מידע על מוצרים אשר לא נרכשו בטבלת ההזמנות.
--Productid,name(Productname),Color : ה
--1.

SELECT 
    p.ProductID AS ProductId,
    p.Name AS ProductName,
    p.Color
FROM 
    Production.Product p
LEFT JOIN 
    Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
WHERE 
    sod.ProductID IS NULL
--2.
WITH CustomerSales AS (
    SELECT
        c.CustomerID,
        c.PersonID,
        c.AccountNumber,
        CONCAT(p.FirstName, ' ', p.LastName) AS FullName,
        SUM(sod.LineTotal) AS TotalSales
    FROM
        Sales.SalesOrderHeader soh
        JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
        JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
        JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    WHERE
        YEAR(soh.OrderDate) = 2014
    GROUP BY
        c.CustomerID,
        c.PersonID,
        c.AccountNumber,
        CONCAT(p.FirstName, ' ', p.LastName)
)
SELECT TOP 10
    CustomerID,
    PersonID,
    AccountNumber,
    FullName,
    TotalSales
FROM
    CustomerSales
ORDER BY
    TotalSales DESC

--3
DECLARE @CategoryName NVARCHAR(15) = 'Bikes';

WITH ProductSales AS (
    SELECT
        p.ProductID,
        p.Name AS ProductName,
        p.ProductNumber,
        p.Color,
        p.Size,
        p.StandardCost,
        p.ListPrice,
        ps.ProductSubcategoryID,
        p.SellStartDate,
        SUM(sod.OrderQty) AS TotalQuantitySold
    FROM
        Production.Product p
        JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
        JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
        JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE
        pc.Name = @CategoryName
    GROUP BY
        p.ProductID,
        p.Name,
        p.ProductNumber,
        p.Color,
        p.Size,
        p.StandardCost,
        p.ListPrice,
        ps.ProductSubcategoryID,
        p.SellStartDate
)
SELECT TOP 5
    ps.ProductID,
    ps.ProductName,
    ps.ProductNumber,
    ps.Color,
    ps.Size,
    ps.StandardCost,
    ps.ListPrice,
    ps.ProductSubcategoryID AS CategoryID,
    ps.SellStartDate,
    ps.TotalQuantitySold
FROM
    ProductSales ps
ORDER BY
    TotalQuantitySold DESC


--4
WITH ProductSales AS (
    SELECT
        p.ProductID,
        p.Name AS ProductName,
        pc.Name AS CategoryName,
        SUM(sod.OrderQty) AS TotalSales
    FROM
        Production.Product p
        JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
        JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
        JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
    GROUP BY
        p.ProductID,
        p.Name,
        pc.Name
),
RankedProductSales AS (
    SELECT
        ProductID,
        ProductName,
        CategoryName,
        TotalSales,
        ROW_NUMBER() OVER(PARTITION BY CategoryName ORDER BY TotalSales DESC) AS Rank
    FROM
        ProductSales
)
SELECT
    ProductID,
    ProductName,
    CategoryName,
    TotalSales
FROM
    RankedProductSales
WHERE
    Rank <= 10

--5
WITH RankedCustomers AS (
    SELECT
        c.CustomerID,
        sp.Name AS Country,
        COUNT(soh.SalesOrderID) AS TotalOrders,
        ROW_NUMBER() OVER (ORDER BY COUNT(soh.SalesOrderID) DESC) AS RowNum
    FROM
        Sales.Customer c
        JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
        JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
        JOIN Person.Address a ON c.CustomerID = a.AddressID
        JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
        JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
    WHERE
        cr.CountryRegionCode IN ('BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR', 'HU', 'IS', 'IE', 'IT', 'LV', 'LI', 'LT', 'LU', 'MT', 'NL', 'NO', 'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', 'CH', 'GB')
    GROUP BY
        c.CustomerID,
        sp.Name
)
SELECT
    CustomerID,
    Country,
    TotalOrders
FROM
    RankedCustomers
WHERE
    RowNum <= 10
ORDER BY
    TotalOrders DESC;














--6 
WITH ProductDeliveryTimes AS (
    SELECT
        sod.ProductID,
        p.Name AS ProductName,
        AVG(DATEDIFF(day, soh.OrderDate, soh.ShipDate)) AS AvgDeliveryTime
    FROM
        Sales.SalesOrderHeader soh
        JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
        JOIN Production.Product p ON sod.ProductID = p.ProductID
    GROUP BY
        sod.ProductID,
        p.Name
)
SELECT
    ProductID,
    ProductName,
    AvgDeliveryTime
FROM
    ProductDeliveryTimes
WHERE
    AvgDeliveryTime > 7

--7
WITH EmployeeAgeGroups AS (
    SELECT
        CASE
            WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) <= 25 THEN 'Up to 25'
            WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 26 AND 35 THEN '26-35'
            WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 36 AND 45 THEN '36-45'
            ELSE 'Above 45'
        END AS AgeGroup,
        COUNT(*) AS EmployeeCount
    FROM
        HumanResources.Employee
    GROUP BY
        CASE
            WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) <= 25 THEN 'Up to 25'
            WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 26 AND 35 THEN '26-35'
            WHEN DATEDIFF(YEAR, BirthDate, GETDATE()) BETWEEN 36 AND 45 THEN '36-45'
            ELSE 'Above 45'
        END
)
SELECT
    AgeGroup,
    EmployeeCount
FROM
    EmployeeAgeGroups


--8
SELECT DISTINCT
    c.CustomerID
   
FROM
    Sales.Customer c
    JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
WHERE
    DATEPART(QUARTER, soh.OrderDate) = 1
    AND YEAR(soh.OrderDate) = 2014;





--9
SELECT 
    CONCAT(e.JobTitle, ' ', p.FirstName, ' ', p.LastName) AS FullName,
    e.HireDate,
    e.JobTitle,
    COUNT(*) AS EmployeesInSameJobTitle
FROM 
    HumanResources.Employee e
JOIN 
    Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN 
    HumanResources.Employee e2 ON e.JobTitle = e2.JobTitle
GROUP BY 
    e.JobTitle,
    p.FirstName,
    p.LastName,
    e.HireDate
ORDER BY 
    e.JobTitle,
    FullName



--10
SELECT
    YEAR(OrderDate) AS [Year],
    SUM(CASE WHEN MONTH(OrderDate) = 1 THEN 1 ELSE 0 END) AS January,
    SUM(CASE WHEN MONTH(OrderDate) = 2 THEN 1 ELSE 0 END) AS February,
    SUM(CASE WHEN MONTH(OrderDate) = 3 THEN 1 ELSE 0 END) AS March,
    SUM(CASE WHEN MONTH(OrderDate) = 4 THEN 1 ELSE 0 END) AS April,
    SUM(CASE WHEN MONTH(OrderDate) = 5 THEN 1 ELSE 0 END) AS May,
    SUM(CASE WHEN MONTH(OrderDate) = 6 THEN 1 ELSE 0 END) AS June,
    SUM(CASE WHEN MONTH(OrderDate) = 7 THEN 1 ELSE 0 END) AS July,
    SUM(CASE WHEN MONTH(OrderDate) = 8 THEN 1 ELSE 0 END) AS August,
    SUM(CASE WHEN MONTH(OrderDate) = 9 THEN 1 ELSE 0 END) AS September,
    SUM(CASE WHEN MONTH(OrderDate) = 10 THEN 1 ELSE 0 END) AS October,
    SUM(CASE WHEN MONTH(OrderDate) = 11 THEN 1 ELSE 0 END) AS November,
    SUM(CASE WHEN MONTH(OrderDate) = 12 THEN 1 ELSE 0 END) AS December
FROM
    Sales.SalesOrderHeader
GROUP BY
    YEAR(OrderDate)
ORDER BY
    [Year]





