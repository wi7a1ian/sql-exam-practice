USE AdventureWorks2014;

SELECT SWITCHOFFSET(SYSDATETIMEOFFSET(), '-08:00'), SYSDATETIMEOFFSET(), SYSDATETIME(), SWITCHOFFSET(SYSDATETIME(), '-08:00')

-- CAST vs CONVERT vs TRY_PARSE
DECLARE @SomeDay DATETIME
SET @SomeDay = '2011-04-23 00:00:00.000'
SELECT @SomeDay, GETDATE()
SELECT * FROM Purchasing.PurchaseOrderDetail WHERE ModifiedDate >= CONVERT(DATE, @SomeDay) AND ModifiedDate < DATEADD(DAY, 1, CONVERT(DATE, @SomeDay))
SELECT * FROM Purchasing.PurchaseOrderDetail WHERE CONVERT(VARCHAR, ModifiedDate, 112) = CONVERT(VARCHAR, @SomeDay, 112)

SELECT 
	TRY_PARSE('1' AS DECIMAL(36,9)),
	TRY_PARSE('aaaaaaaaaaaa' AS DECIMAL(36,9)),
	CONVERT(DECIMAL(36,9), '1'),
	CAST('1' AS DECIMAL(36,9)),
	IIF(TRY_PARSE('aaaaaaaa' AS DECIMAL(36,9)) IS NOT NULL, 'TRUE', 'FALSE') AS GoodCast

-- Useful functions
SELECT STUFF(',x,y,z', 1, 1, '')-- = 'x,y,z'
SELECT FORMAT(1759, '000000000')-- = '0000001759'
SELECT LEN('a      ') --LEN removes trailing spaces
SELECT DATALENGTH(N'1 ') -- = 4
SELECT CONCAT('a',NULL,'b') --CONCAT is better than + because it skipps nulls

--// COALESCE instead of ISNULL
	DECLARE
	  @x AS VARCHAR(3) = NULL,
	  @y AS VARCHAR(10) = '1234567890';
	SELECT COALESCE(@x, @y) AS [COALESCE], ISNULL(@x, @y) AS [ISNULL];
	-- ISNULL will force datatype/length from @x
	--COALESCE(T1.col1, -1) = COALESCE(T2.col1, -1), or ISNULL(T1.col1, -1) = ISNULL(T2.col1, -1).
	-- more efficient: T1.col1 = T2.col1 OR (T1.col1 IS NULL AND T2.col1 IS NULL)

--// Escape character
	SELECT CASE WHEN '_dupa' LIKE '!_%' ESCAPE '!' THEN 'Tak' ELSE 'Nie' END
	-- SQL Server can't rely on index ordering when the pattern starts with a wildcard—for example:
	-- col LIKE '%ABC'


--// Order / Offset / Getch
	SELECT * FROM Person.Address order by 1,2,3

	SELECT TOP(3) * FROM Person.Address ORDER BY City DESC --normal
	SELECT TOP(3) WITH TIES * FROM Person.Address ORDER BY City DESC -- with ties
	SELECT TOP(50) PERCENT * FROM Person.Address ORDER BY City DESC -- 50%
	SELECT * FROM Person.Address ORDER BY City DESC OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY --  paging
	SELECT * FROM Person.Address ORDER BY City DESC OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY --  paging v2
	SELECT * FROM Person.Address ORDER BY City DESC OFFSET 3 ROWS --  inversed Top

	-- Get three arbitrary rows
	SELECT TOP(3) * FROM Person.Address ORDER BY (SELECT NULL); -- let people know that your choice is intentional and not an oversight
