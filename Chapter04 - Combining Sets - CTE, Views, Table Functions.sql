USE AdventureWorks2014;

--// Chapter 4 Lesson 2 - Table expressions
-- Derived tables ----------------------------------------------------
	SELECT City2, StateProvinceID2, PostalCode2
	FROM
		(SELECT
			ROW_NUMBER() OVER(PARTITION BY City
				ORDER BY StateProvinceID, PostalCode) AS rownum,
			City, StateProvinceID, PostalCode
		FROM Person.Address) AS D(rownum, City2, StateProvinceID2, PostalCode2) -- additional aliasing
	WHERE rownum < 2

-- Common table expression (CTE) -------------------------------------
	;WITH SomeInnerQuery AS -- First CTE
		(SELECT
			ROW_NUMBER() OVER(PARTITION BY City
				ORDER BY StateProvinceID, PostalCode) AS rownum,
			City, StateProvinceID, PostalCode
		FROM Person.Address)
	, SomeOtherInnerQuery(Msg2) AS -- Another CTE that can refer to above
		(SELECT 'OK' AS Msg)
	SELECT City, StateProvinceID, PostalCode, soiq1.Msg2, soiq2.Msg2 -- Outer query that can refer all of the above
	FROM SomeInnerQuery
	CROSS APPLY SomeOtherInnerQuery soiq1
	CROSS JOIN SomeOtherInnerQuery soiq2
	WHERE rownum < 2

-- Recurrent CTE -----------------------------------------------------
	;WITH [EmployeeManagersCTE] ([BusinessEntityID], [OrganizationNode], [FirstName], [LastName], [RecursionLevel])   
	AS (  
		SELECT e.[BusinessEntityID], e.[OrganizationNode], p.[FirstName], p.[LastName], 0   
		FROM [HumanResources].[Employee] e   
		INNER JOIN [Person].[Person] p   
			ON p.[BusinessEntityID] = e.[BusinessEntityID]  
		UNION ALL  
		SELECT e.[BusinessEntityID], e.[OrganizationNode], p.[FirstName], p.[LastName], 
			[RecursionLevel] + 1 -- Join recursive member to anchor  
		FROM [HumanResources].[Employee] e   
		INNER JOIN [EmployeeManagersCTE]  
			ON e.[OrganizationNode].GetAncestor(1) = [EmployeeManagersCTE].[OrganizationNode]  -- ! type: hierarchyid
		INNER JOIN [Person].[Person] p   
			ON p.[BusinessEntityID] = e.[BusinessEntityID]  
	)  
	SELECT   
		m.[BusinessEntityID]  
		, m.[FirstName]  
		, m.[LastName] -- Outer select from the CTE  
		, m.[RecursionLevel]  
		, m.[OrganizationNode].ToString() as [OrganizationNode]  
		, p.[FirstName] AS 'ManagerFirstName'  
		, p.[LastName] AS 'ManagerLastName'   
	FROM [EmployeeManagersCTE] m   
	INNER JOIN [HumanResources].[Employee] e   
		ON m.[OrganizationNode].GetAncestor(1) = e.[OrganizationNode]   -- !
	INNER JOIN [Person].[Person] p   
		ON p.[BusinessEntityID] = e.[BusinessEntityID]  
	ORDER BY [RecursionLevel], m.[OrganizationNode].ToString()  
	OPTION (MAXRECURSION 25)   -- !

-- View ----------------------------------------------------------------
	IF OBJECT_ID('CitiesView', 'V') IS NOT NULL DROP VIEW CitiesView;
	GO
	CREATE VIEW CitiesView AS
		SELECT City2, StateProvinceID2, PostalCode2
		FROM
			(SELECT
				ROW_NUMBER() OVER(PARTITION BY City
					ORDER BY StateProvinceID, PostalCode) AS rownum,
				City, StateProvinceID, PostalCode
			FROM Person.Address) AS D(rownum, City2, StateProvinceID2, PostalCode2) -- additional aliasing
		WHERE rownum < 2
	GO
	SELECT * FROM CitiesView WHERE City2 IS NOT NULL

--  Inline Table-Valued Functions --------------------------------------
	IF OBJECT_ID('udf_Cities', 'IF') IS NOT NULL DROP FUNCTION udf_Cities;
	GO
	CREATE FUNCTION udf_Cities(@CityName AS NVARCHAR(100)) RETURNS TABLE
	AS
	RETURN
		SELECT City, StateProvinceID, PostalCode, ModifiedDate
		FROM Person.Address
		WHERE City = @CityName
	GO
	select c.* FROM udf_Cities('Bothell') AS c where c.ModifiedDate < '2012-05-30 00:00:00.000'

-- Cross Join - Cartesian product so if you have 10 rows in each table the query will return 100 rows
-- Cross/Outer Apply - Invoke a table-valued function for each row returned by an outer table expression of a query.
--	The right input is evaluated for each row from the left input and the rows produced are combined for the final output.
--  If right value is null then left row is not returned.
--  The OUTER APPLY operator does what the CROSS APPLY operator does, but also includes in the result rows from the left side that get an empty set back from the right side.
SELECT pa.*, pa2.AddressLine1 AS ThreeClosestAddresses
FROM Person.Address pa
-- OUTER APPLY -- will return a row for Kingsport
CROSS APPLY -- will not return a row for Kingsport
	(SELECT AddressLine1 
	FROM Person.Address 
	WHERE City = pa.City 
		AND pa.AddressLine1 <> AddressLine1
	ORDER BY City
	OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY) AS pa2
WHERE pa.City = 'Kingsport' -- Only 1 record = no other addresses = output 0 records
--WHERE pa.City = 'Cheyenne'

-- What is the difference between the APPLY and JOIN operators?
-- With a JOIN operator, both inputs represent static relations. With APPLY, the
-- left side is a static relation, but the right side can be a table expression with
-- correlations to elements from the left table.

--// Chapter 4 Lesson 3 - Set Operators
SELECT City from Person.Address UNION SELECT City FROM Person.Address -- unique set
SELECT City from Person.Address UNION ALL SELECT City FROM Person.Address -- multi set
SELECT City from Person.Address INTERSECT SELECT City from Person.Address -- distinct rows that are common to both sets
SELECT City from Person.Address EXCEPT SELECT City from Person.Address -- distinct rows that appear in the first query but not the second
-- Precedence: INTERSECT > UNION & EXCEPT

