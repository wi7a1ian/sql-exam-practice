USE AdventureWorks2014;

-- EXECUTE AS:
--  CALLER - person calling the module
--  SELF - person creating or altering the module
--  OWNER - current owner of the module or schema (cannot be specified for DDL or logon triggers)

IF OBJECT_ID('dbo.SomeTable', 'U') IS NOT NULL
	DROP TABLE dbo.SomeTable;
GO
CREATE TABLE dbo.SomeTable
(
	SomeId INT IDENTITY(1,1) NOT NULL,
	SomeUniqueId INT NULL, -- UNIQUE,
	SomeText NVARCHAR(MAX) DEFAULT(''),
	SomeGUID UNIQUEIDENTIFIER,
)

-- USP - User-defined Stored Procedures
IF OBJECT_ID('dbo.SomeSproc', 'P') IS NOT NULL
DROP PROC dbo.SomeSproc;
GO
CREATE PROC dbo.SomeSproc
	@custid AS INT,
	@orderdatefrom AS DATETIME = '19000101',
	@orderdateto AS DATETIME = '99991231',
	@numrows AS INT = 0 OUTPUT
WITH ENCRYPTION, RECOMPILE, EXECUTE AS CALLER
AS
BEGIN
SET NOCOUNT ON; -- remove messages like (3 row(s) affected) being returned every time the procedure executes
	
	SELECT SalesOrderID, CustomerID, ShipToAddressID, OrderDate, DueDate, ShipDate
	FROM Sales.SalesOrderHeader
	WHERE CustomerID = @custid
		AND orderdate >= @orderdatefrom
		AND orderdate < @orderdateto;
	SET @numrows = @@ROWCOUNT;
	WAITFOR DELAY '00:00:01'; -- 1s
	-- WAITFOR TIME '23:46:00'; -- waits until 11:45

RETURN 0; -- Use the SQL Server error numbers from @@ERROR or from ERROR_NUMBER() in a CATCH block instead.
END
GO

DECLARE @rowsreturned AS INT,
	@retcode AS INT;

EXEC @retcode = dbo.SomeSproc
	@custid = 29825,
	@orderdatefrom = '2011-05-31',
	@orderdateto = '20110612',
	@numrows = @rowsreturned OUTPUT;
SELECT @retcode AS 'Return Code', @rowsreturned AS "Rows Returned";
GO
EXEC dbo.SomeSproc
	@custid = 29825;
GO


-- TRIGGERS -  liek sprocs but fired by events
-- SQL Server supports the association of triggers with two kinds of events:
--  Data manipulation events (DML triggers)
--  Data definition events (DDL triggers) such as CREATE TABLE
-- Supported DML events: INSERT, UPDATE, or DELETE
-- Supported DML triggers: AFTER (only table), INSTEAD OF (table and view)
-- Issuing a ROLLBACK TRAN command within the trigger’s code causes a rollback of everything.
-- You can access tables that are named 'inserted' and 'deleted'.
-- The maximum depth of nested trigger executions is 32 (A->B, B->A, ...)

IF OBJECT_ID('dbo.tr_SomeTrigger', 'TR') IS NOT NULL
	DROP TRIGGER dbo.tr_SomeTrigger;
GO

CREATE TRIGGER dbo.tr_SomeTrigger
ON dbo.SomeTable
WITH ENCRYPTION
	,EXECUTE AS CALLER --SELF, 'user'
--FOR DELETE, INSERT, UPDATE
AFTER DELETE, INSERT, UPDATE
--INSTEAD OF INSERT
AS
BEGIN
	IF @@ROWCOUNT = 0 RETURN;-- AFTER only - performance improvement
	SET NOCOUNT ON
	
	SELECT 'InsertedCount' AS Operation, COUNT(*) AS [Count] FROM Inserted
	UNION SELECT 'DeletedCount', COUNT(*) FROM Deleted
	UNION SELECT 'SomeText Updated', CASE WHEN UPDATE(SomeText) THEN 1 ELSE 0 END;

	RETURN;
END
GO

INSERT INTO dbo.SomeTable (SomeText, SomeGUID) VALUES('Something', NEWID());
UPDATE dbo.SomeTable SET SomeText = 'LOL';
--TRUNCATE TABLE dbo.SomeTable; --  no trigger!
DELETE dbo.SomeTable;


-- UDF - User-Defined Functions
-- FN - A scalar function returns a single value back to the caller.
--      Use of scalar UDFs prevent queries from being parallelized.
-- IF - A table-valued UDF with a single line of code is called an inline table-valued UDF. 
--      Parameterized view - the optimizer treats an inline table-valued function just like a view. 
-- TF - A table-valued UDF with multiple lines of code is called a multistatement table-valued UDF.

-- Examples:
-- FN
IF OBJECT_ID('dbo.fn_SomeScalarFunction', 'FN') IS NOT NULL
	DROP FUNCTION dbo.fn_SomeScalarFunction
GO
CREATE FUNCTION dbo.fn_SomeScalarFunction
(
	@unitprice AS MONEY,
	@qty AS INT
)
RETURNS MONEY
WITH SCHEMABINDING, 
	ENCRYPTION, 
	RETURNS NULL ON NULL INPUT -- if any param is null then break execution, opposite to CALLED ON NULL INPUT
	,EXECUTE AS CALLER -- SELF, OWNER, 'user'
AS
BEGIN
	RETURN @unitprice * @qty
END;
GO

SELECT dbo.fn_SomeScalarFunction(12.50, 10);

-- IF
IF OBJECT_ID('dbo.fn_SomeInlineFunction', 'IF') IS NOT NULL
	DROP FUNCTION dbo.fn_SomeInlineFunction;
GO
CREATE FUNCTION dbo.fn_SomeInlineFunction
(
	@startFrom AS SMALLINT
)
RETURNS TABLE 
AS 
	RETURN
	(
		SELECT @startFrom+1 AS One, @startFrom+2 AS Two, @startFrom+3 as Three
		UNION SELECT @startFrom+4, @startFrom+5, @startFrom+6
		UNION SELECT @startFrom+7, @startFrom+8, @startFrom+9
	);
GO

SELECT * 
FROM dbo.fn_SomeInlineFunction ( 0 ) f1
CROSS JOIN dbo.fn_SomeInlineFunction ( 100 ) f2;

-- TF
IF OBJECT_ID('dbo.fn_SomeMultiFunction', 'TF') IS NOT NULL
	DROP FUNCTION dbo.fn_SomeMultiFunction;
GO
CREATE FUNCTION dbo.fn_SomeMultiFunction
(
	@param1 int,
	@param2 char(5)
)
RETURNS @returntable TABLE
(
	c1 int,
	c2 char(5)
)
AS
BEGIN
	INSERT @returntable
	SELECT @param1, @param2
	RETURN
END;
GO

SELECT * FROM dbo.fn_SomeMultiFunction(1, '2')