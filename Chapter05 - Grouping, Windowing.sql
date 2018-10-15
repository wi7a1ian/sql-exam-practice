USE AdventureWorks2014;

--// Chapter 5 Lesson 1 - Multiple Grouping Sets
--You could achieve the same result by writing four separate grouped queries—each defining
--only a single grouping set—and unifying their results with a UNION ALL operator. However,
--such a solution would involve much more code and won’t get optimized as efficiently as
--the query with the GROUPING SETS clause.
SELECT FirstName, PersonType,  COUNT(FirstName)
FROM Person.Person
GROUP BY GROUPING SETS
(
	(FirstName, PersonType),
	(FirstName),
	(PersonType),
	()
)
--...GROUP BY CUBE(FirstName, PersonType)
-- produce same as above (all combinations)
--...GROUP BY ROLLUP(FirstName, PersonType)
-- produce ((FirstName, PersonType), (FirstName), ())
SELECT TerritoryID, Status, GROUPING(Status), SUM(SubTotal) 
-- GROUPING() tells if this column is a part of groupipng resulting in nulls
FROM Sales.SalesOrderHeader
GROUP BY ROLLUP(TerritoryID, Status)

--// Chapter 5 Lesson 2 - Pivoting
SELECT DaysToManufacture, AVG(StandardCost) AS AverageCost 
FROM Production.Product
GROUP BY DaysToManufacture;
-- Pivot table with one row and five columns
WITH PivotData
AS (
	SELECT DaysToManufacture, StandardCost 
    FROM Production.Product
)
SELECT 'AverageCost' AS Cost_Sorted_By_Production_Days, [0], [1], [2], [3], [4], [15]
FROM PivotData
PIVOT
(
	AVG(StandardCost)
	FOR DaysToManufacture IN ([0], [1], [2], [3], [4], [15])
) AS PivotTable;

--// Chapter 5 Lesson 3 - Window Functions
-- Window aggregate function
	SELECT AVG(StandardCost) FROM Production.Product
	SELECT AVG(StandardCost) OVER() FROM Production.Product
--
	SELECT ProductID, Weight,
		AVG(Weight) OVER (PARTITION BY ProductModelID) AS AvgWeightInProductClass, 
		AVG(Weight) OVER () AS AvgWeightGlobal
	FROM Production.Product;
--
	SELECT ProductID, Weight,
		AVG(Weight) OVER ( -- = window aggregate function
			PARTITION BY ProductModelID
			ORDER BY ProductModelID -- = window order
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW -- = window frame
			--ROWS BETWEEN FOLLOWING AND 5 ROWS FOLLOWING
			--ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
		) AS AvgWeightInProductClass
	FROM Production.Product
	WHERE Weight IS NOT NULL;
-- Window ranking function
	SELECT SalesOrderDetailID, LineTotal,
	ROW_NUMBER() OVER(ORDER BY LineTotal) AS rownum,
	RANK() OVER(ORDER BY LineTotal) AS rnk,
	DENSE_RANK() OVER(ORDER BY LineTotal) AS densernk,
	NTILE(100) OVER(ORDER BY LineTotal) AS ntile100
	FROM Sales.SalesOrderDetail;
	--ORDER BY SalesOrderDetailID;
-- Window Offset Functions
	SELECT SalesOrderID, SalesOrderDetailID, LineTotal,
		LAG(LineTotal) OVER(PARTITION BY SalesOrderID
			ORDER BY ModifiedDate, SalesOrderDetailID) AS prev_val,
		LEAD(LineTotal) OVER(PARTITION BY SalesOrderID
			ORDER BY ModifiedDate, SalesOrderDetailID) AS next_val,
		FIRST_VALUE(LineTotal) OVER(PARTITION BY SalesOrderID
			ORDER BY ModifiedDate, SalesOrderDetailID
			ROWS BETWEEN UNBOUNDED PRECEDING
				AND CURRENT ROW) AS first_val,
		LAST_VALUE(LineTotal) OVER(PARTITION BY SalesOrderID
			ORDER BY ModifiedDate, SalesOrderDetailID
			ROWS BETWEEN CURRENT ROW
				AND UNBOUNDED FOLLOWING) AS last_val
	FROM Sales.SalesOrderDetail
	ORDER BY SalesOrderID, SalesOrderDetailID;
--


