USE AdventureWorks2014;
GO

/*
Regarding querying tasks, generally it is recommended to use set-based solutions as
your default choice, and reserve the use of iterative solutions for exceptional cases.
*/

SET NOCOUNT ON;

DECLARE @curcustid AS INT;
DECLARE cust_cursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT CustomerID
	FROM Sales.Customer;

OPEN cust_cursor;
FETCH NEXT FROM cust_cursor INTO @curcustid;

WHILE @@FETCH_STATUS = 0
BEGIN
	RAISERROR('Customer ID %d', 1, 1, @curcustid) WITH NOWAIT; 
	FETCH NEXT FROM cust_cursor INTO @curcustid;
END;

CLOSE cust_cursor;
DEALLOCATE cust_cursor;
GO

-- Similar, but without cursor
DECLARE @curcustid AS INT;
SET @curcustid = (
	SELECT TOP (1) CustomerID 
	FROM Sales.Customer 
	ORDER BY CustomerID
);

WHILE @curcustid IS NOT NULL
BEGIN
	RAISERROR('Customer ID %d', 1, 1, @curcustid) WITH NOWAIT; 
	SET @curcustid = (
		SELECT TOP (1) CustomerID 
		FROM Sales.Customer
		WHERE CustomerID > @curcustid
		ORDER BY CustomerID);
END;
GO