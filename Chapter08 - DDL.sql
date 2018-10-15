-- Data Definition Language
USE AdventureWorks2014;

-- Tables
CREATE TABLE dbo.SomeTable
(
	SomeId INT IDENTITY(1,1) NOT NULL,
	SomeUniqueId INT NULL, -- UNIQUE,
	SomeText NVARCHAR(MAX) DEFAULT(''),
	SomeGUID UNIQUEIDENTIFIER,
	[Some fancy column #1] DECIMAL,		-- delimited identifier
	SomeDate AS GETDATE(),				-- computed, evaluated at runtime
	SomeDateTime DATETIME2 DEFAULT CURRENT_TIMESTAMP,
	SomeComputedCol AS (SomeId % 5) PERSISTED				-- computed, persited column = on drive,
	CONSTRAINT PK_SomeTable PRIMARY KEY(SomeId, SomeGUID),
	CONSTRAINT UQ_SomeTable UNIQUE(SomeUniqueId),
	CONSTRAINT CHK_SomeTable_SomeDateTime CHECK (SomeDateTime < GETDATE())
)
WITH (DATA_COMPRESSION = ROW);
CREATE INDEX IX_SomeTable_SomeId_SomeGUID ON dbo.SomeTable (SomeId, SomeGUID);

SELECT *
FROM sys.key_constraints
WHERE type = 'PK' AND name IN ('PK_SomeTable', 'IX_SomeTable_SomeId_SomeGUID');

SELECT *
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.SomeTable')

DROP INDEX IX_SomeTable_SomeId_SomeGUID ON dbo.SomeTable;
ALTER TABLE dbo.SomeTable DROP CONSTRAINT PK_SomeTable;
ALTER TABLE dbo.SomeTable DROP CONSTRAINT UQ_SomeTable;
DROP TABLE dbo.SomeTable;

select * from sys.key_constraints
select * from sys.default_constraints
select * from sys.check_constraints
select * from sys.foreign_keys
GO

-- Views
-- Creating a unique clustered index on a view results in an indexed view that materializes data
CREATE VIEW dbo.SomeView
WITH SCHEMABINDING, VIEW_METADATA /* it makes the view look like it is the base table */, ENCRYPTION /* shallow protection */
AS
	SELECT 
		DAY(ModifiedDate) AS ModDay,
		CONCAT(FirstName, ' ', MiddleName + ' ', LastName) AS FullName,
		COUNT(*) OVER(PARTITION BY FirstName) AS NrOfPeopleWithTheSameName
	FROM Person.Person
	WHERE LastName LIKE 'P_ter%'
WITH CHECK OPTION -- cannot change a value so that the affected row no longer matches the WHERE clause filter.
GO
SELECT * FROM SomeView;
DROP VIEW dbo.SomeView;

-- Inline Functions
IF OBJECT_ID (N'dbo.fn_SomeTableValuedFunction', N'IF') IS NOT NULL
	DROP FUNCTION dbo.fn_SomeTableValuedFunction;
IF OBJECT_ID (N'dbo.fn_SomeTableValuedFunction2', N'IF') IS NOT NULL
	DROP FUNCTION dbo.fn_SomeTableValuedFunction2;
GO


-- #1
CREATE FUNCTION dbo.fn_SomeTableValuedFunction ( @LastNameFilter NVARCHAR(50) = 'P_ter%' )
RETURNS TABLE
WITH SCHEMABINDING, ENCRYPTION
AS -- body of the function can only be a SELECT statement
RETURN
(
	SELECT 
		DAY(ModifiedDate) AS ModDay,
		CONCAT(FirstName, ' ', MiddleName + ' ', LastName) AS FullName,
		COUNT(*) OVER(PARTITION BY FirstName) AS NrOfPeopleWithTheSameName
	FROM Person.Person
	WHERE LastName LIKE @LastNameFilter
)
GO
SELECT * FROM dbo.fn_SomeTableValuedFunction('P_ter%');
GO

-- #2
CREATE FUNCTION dbo.fn_SomeTableValuedFunction2 ( @LastNameFilter NVARCHAR(50) = 'P_ter%' )
RETURNS @return TABLE ( ModDay INT, FullName NVARCHAR(MAX), NrOfPeopleWithTheSameName INT)
AS -- body of the function can only be a SELECT statement
BEGIN
	WITH calcResult AS
	(
		SELECT 
			DAY(ModifiedDate) AS ModDay,
			CONCAT(FirstName, ' ', MiddleName + ' ', LastName) AS FullName,
			COUNT(*) OVER(PARTITION BY FirstName) AS NrOfPeopleWithTheSameName
		FROM Person.Person
		WHERE LastName LIKE @LastNameFilter
	)
	INSERT INTO @return
	SELECT * FROM calcResult;
	RETURN;
END
GO
SELECT * FROM dbo.fn_SomeTableValuedFunction2('P_ter%');

-- Synonyms
-- late-binding = object_name does not need to actually exist, and SQL Server doesn’t test it
CREATE SYNONYM SomeSynonym FOR Person.Person;
GO
DROP SYNONYM SomeSynonym;
GO

-- Temp Tables
--  #t - Local temporary tables are visible throughout the level that created them, across batches, and in all inner levels of the call stack.
--  ##t - Global temp tables are visible to all sessions. They are destroyed when the session that created them terminates and there are no active references to them.
-- Do not name the constraints, like PK.
CREATE TABLE #T1 (	col1 INT NOT NULL );
INSERT INTO #T1(col1) VALUES(10);
EXEC('SELECT col1 FROM #T1;');
SELECT col1 FROM #T1;

IF (OBJECT_ID('tempdb..#T1') IS NOT NULL)
	DROP TABLE #T1;
GO

-- Table Variables
--  @t - visible only to the batch that declared them and are destroyed automatically at the end of the batch.
-- Do not name the constraints, like PK.
-- Performance - SQL Server maintains distribution statistics (histograms) for temporary tables but not for table variables.
-- Changes against a table variable are not undone if the user transaction is rolled back.
DECLARE @T1 AS TABLE (	col1 INT NOT NULL );
INSERT INTO @T1(col1) VALUES(10);
--EXEC('SELECT col1 FROM @T1;'); -- not visible
SELECT col1 FROM @T1;
GO

