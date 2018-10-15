-- Data Manipulation Language
USE AdventureWorks2014;
IF OBJECT_ID('dbo.MyOrders') IS NOT NULL DROP TABLE dbo.MyOrders;
IF OBJECT_ID('dbo.SomeSequenceIDs') IS NOT NULL DROP SEQUENCE dbo.SomeSequenceIDs;

-- “The Data Loading Performance Guide” at http://msdn.microsoft.com/en-us/library/dd425070.aspx.
-- If your source data is a table inside SQL Server, using SELECT INTO or INSERT … SELECT
-- provides a quick and easy way to achieve this. If your source data is located outside of SQL Server, 
-- you can use BCP, BULKINSERT, INSERT…SELECT or Integration Services as appropriate.

CREATE TABLE dbo.MyOrders
(
	orderid INT NOT NULL IDENTITY(1, 1)
		CONSTRAINT PK_MyOrders_orderid PRIMARY KEY,
	custid INT NOT NULL,
	empid INT NOT NULL,
	orderdate DATE NOT NULL
		CONSTRAINT DFT_MyOrders_orderdate DEFAULT (CAST(SYSDATETIME() AS DATE)),
	shipcountry NVARCHAR(15) NULL,
	freight MONEY NULL
);


-- INSERT VALUES
INSERT INTO dbo.MyOrders(custid, empid, orderdate, shipcountry, freight)
VALUES(2, 19, '20120620', N'USA', 30.00);

SET IDENTITY_INSERT dbo.MyOrders ON;
INSERT INTO dbo.MyOrders(orderid, custid, empid, orderdate, shipcountry, freight)
VALUES(2, 2, 19, '20120620', N'USA', 30.00);
SET IDENTITY_INSERT dbo.MyOrders OFF;

INSERT INTO dbo.MyOrders(custid, empid, orderdate, shipcountry, freight) VALUES
(2, 11, '20120620', N'USA', 50.00),
(5, 13, '20120620', N'USA', 40.00),
(7, 17, '20120620', N'USA', 45.00),
(7, 18, '20120620', N'Norway', 455.00);

-- INSERT SELECT
INSERT INTO dbo.MyOrders( custid, empid, orderdate, shipcountry, freight) --WITH (TABLOCK)
SELECT custid, empid, orderdate, shipcountry, freight
FROM dbo.MyOrders
WHERE shipcountry = N'Norway';
-- An INSERT statement that takes its rows from a SELECT operation and inserts them into a heap is minimally logged 
-- when a WITH (TABLOCK) hint is used on the destination table

-- INSERT EXEC

-- SELECT INTO

-- UPDATE
-- with Joins
-- nondeterministic - more than one match but SQL wont throw error
-- with Table Expressions 
--   CTEs = WITH C AS ... UPDATE C ... SET ...
--   derived tables = UPDATE C SET ... FROM (...) AS C
-- if you write an UPDATE statement with a table A in the UPDATE clause and a table B (but not A) in the FROM clause, you get an implied cross join between A and B
-- based on a Variable
-- All-at-Once = all assignments use the original values of the row as the source values (... SET col1+1, col2=col1 ... will be 101, 100 )
-- additional WRITE() method for nvarchar:
	DECLARE @SomeTable TABLE( SomeText NVARCHAR(MAX) );
	INSERT INTO @SomeTable VALUES ('start1'),('start2');
	UPDATE @SomeTable SET SomeText.WRITE(' end', null, 0); -- append
	SELECT * FROM @SomeTable;

-- DELETE 
-- because DELETE statement is fully logged and as a result, large deletes can take a long time to complete:
--   split your large delete into smaller chunks (WHILE 1=1 BEGIN DELETE TOP (1000) ...; IF @@rowcount < 1000 BREAK; END)
--   TRUNCATE 
--      no filter option
--      reset identity prop
--      not allowed if a foreign key is pointing to the table 
--      disallowed against a table involved in an indexed view
--      requires ALTER permissions on the target table, not DELETE
-- with Joins, but subquery is considered a standard
-- with Table Expressions ( for example to delete top 100 rows )

-- IDENTITY
SELECT SCOPE_IDENTITY()					-- last identity value generated in your session in the current scope
	, @@IDENTITY						-- last identity value generated in your session regardless of scope
	, IDENT_CURRENT('dbo.MyOrders')	-- last identity value generated in the input table regardless of session
-- reseed
DBCC CHECKIDENT('dbo.MyOrders', RESEED, 554);
SELECT IDENT_CURRENT('dbo.MyOrders')
-- doesn’t guarantee uniqueness
-- doesn’t guarantee that there will be no gaps between the values
-- if an INSERT statement fails, the current identity value is not changed back to the original one, so the unused value is lost. 
-- no cycling support, this means that after you reach the maximum value in the type, the next insertion will fail due to an overflow error

-- SEQUENCE object
-- use this function in INSERT and UPDATE statements, DEFAULT constraints, and assignments to variables
CREATE SEQUENCE dbo.SomeSequenceIDs AS INT
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 1000
	NO CYCLE
	START WITH 10
	CACHE 50; -- flush to drive every 50th request

SELECT NEXT VALUE FOR dbo.SomeSequenceIDs;
ALTER SEQUENCE dbo.SomeSequenceIDs RESTART WITH 1;

ALTER TABLE dbo.MyOrders -- apply to a table
	ADD CONSTRAINT DFT_MyOrders_custid
	DEFAULT(NEXT VALUE FOR dbo.SomeSequenceIDs) FOR custid;

SELECT
	TYPE_NAME(system_type_id) AS type,
	start_value, minimum_value, current_value, increment, is_cycling
FROM sys.sequences
WHERE object_id = OBJECT_ID('dbo.SomeSequenceIDs');


-- MERGE
MERGE INTO dbo.MyOrders WITH (HOLDLOCK) AS TGT
USING 
	--dbo.MyOrders AS SRC
	--(SELECT * FROM dbo.MyOrders) AS SRC
	--(SELECT 1,1,2,'20120620', 'PL', 0) AS SRC( orderid, custid, empid, orderdate, shipcountry, freight)
	--VALUES(1,1,2,'20120620', 'PL', 0) AS SRC( orderid, custid, empid, orderdate, shipcountry, freight)
	--(SELECT 1 AS orderid, 1 AS custid, 2 AS empid, '20120620' AS orderdate, 'PL' AS shipcountry, 0 AS freight) AS SRC
	--	
	ON SRC.orderid = TGT.orderid
WHEN MATCHED AND SRC.shipcountry = 'PL' THEN 
	DELETE
WHEN MATCHED THEN UPDATE
	SET TGT.custid = SRC.custid,
	TGT.empid = SRC.empid,
	TGT.orderdate = SRC.orderdate,
	TGT.shipcountry = SRC.shipcountry,
	TGT.freight = SRC.freight
WHEN NOT MATCHED /*AND predicate*/ THEN INSERT
	VALUES(/*SRC.orderid,*/ SRC.custid, SRC.empid, SRC.orderdate, SRC.shipcountry, SRC.freight)
WHEN NOT MATCHED BY SOURCE THEN 
	DELETE
OUTPUT $action, COALESCE(inserted.orderid, deleted.orderid) AS orderid;

-- OUTPUT INSERT
INSERT INTO dbo.MyOrders(custid, empid, orderdate, shipcountry, freight)
	OUTPUT inserted.custid, inserted.empid, inserted.orderdate, inserted.shipcountry, inserted.freight INTO dbo.MyOrders -- loopback lol
	OUTPUT inserted.custid, inserted.empid, inserted.orderdate, inserted.shipcountry, inserted.freight
	--INTO #tmp(custid, empid, orderdate, shipcountry, freight)
VALUES(2, 19, '20120620', N'USA', 30.00);

-- OUTPUT UPDATE
UPDATE dbo.MyOrders
SET freight = 0
--OUTPUT inserted.custid, inserted.empid, inserted.orderdate, inserted.shipcountry, inserted.freight
--OUTPUT deleted.custid, deleted.empid, deleted.orderdate, deleted.shipcountry, deleted.freight
OUTPUT inserted.shipcountry, deleted.freight, inserted.freight
WHERE shipcountry = 'USA'

-- OUTPUT DELETE
DELETE FROM dbo.MyOrders
OUTPUT deleted.*
WHERE shipcountry = 'Norway'

-- OUTPUT MERGE
--... used above

-- Composable DML





