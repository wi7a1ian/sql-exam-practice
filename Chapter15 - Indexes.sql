USE AdventureWorks2014;

/*
SQL Server organizes tables as heaps or as balanced trees. 

A table organized as a balanced tree is also known as a clustered table or a clustered index.

Indexes are always organized as balanced trees. Other indexes, such as indexes that do not
contain all of the data and serve as pointers to table rows for quick seeks, are called nonclustered
indexes.

The list of the clauses you should consider supporting with an index includes, but
is not limited to, the WHERE, JOIN, GROUP BY, and ORDER BY clauses.

*/

IF OBJECT_ID('dbo.SomeTable', 'U') IS NOT NULL
	DROP TABLE dbo.SomeTable;
GO
CREATE TABLE dbo.SomeTable
(
	SomeId INT IDENTITY(1,1) NOT NULL,
	SomeUniqueId INT NULL, -- UNIQUE,
	SomeText NVARCHAR(MAX) DEFAULT(''),
	SomeGUID UNIQUEIDENTIFIER,
);

IF OBJECT_ID('dbo.SomeView', 'V') IS NOT NULL
	DROP VIEW dbo.SomeView;
GO
CREATE VIEW dbo.SomeView (BusinessEntityID, FirstName, LastName)
WITH SCHEMABINDING
AS 
SELECT BusinessEntityID, FirstName, LastName FROM Person.Person
GO

-- You can rebuild or reorganize an index to get rid of the external fragmentation by using the
-- ALTER INDEX…REORGANIZE or ALTER INDEX…REBUILD statements.
-- Reorganize an index when the external fragmentation is less than 30 percent and
-- rebuild it if it is greater than 30 percent.

CREATE INDEX IX_SomeTable_SomeUniqueId ON  dbo.SomeTable(SomeUniqueId);
CREATE UNIQUE INDEX UX_SomeTable_SomeGUID ON  dbo.SomeTable(SomeGUID) WHERE SomeId > 100;
GO

-- INCLUDE
-- Value of the column will be stored at the 'leaf-level' but won't be used for seeks.
CREATE NONCLUSTERED INDEX IX_SomeViewInclude ON SomeTable(SomeUniqueId, SomeGUID) INCLUDE(SomeText);
GO

-- A columnstore index is just another nonclustered index on a table. The SQL Server Query
-- Optimizer considers using the columnstore index during the query optimization phase just
-- as it does any other index. All you have to do to take advantage of this feature is create a
-- columnstore index on a table.
-- When a query references a single column that is a part of a columnstore index,
-- then SQL Server fetches only that column from disk; it doesn’t fetch entire rows as with row storage.
-- If you want to update a table by using a columnstore index, you must first drop the columnstore index.
--
-- Columnstore indexes give high performance gains for queries that use full table scans, 
-- and are not well-suited for queries that seek into the data, searching for a particular value.
CREATE NONCLUSTERED COLUMNSTORE INDEX IX_CS_SomeView ON SomeTable(SomeUniqueId, SomeGUID);
GO

-- You can create a view with a query that joins and aggregates data. 
-- Then you can index the view to get an indexed view.
-- With indexing, you are materializing a view.
--CREATE UNIQUE CLUSTERED INDEX IX_CL_SomeView ON SomeView(BusinessEntityID, LastName);
CREATE UNIQUE CLUSTERED INDEX IX_CL_SomeView ON SomeView(BusinessEntityID, LastName);
GO

-- Statistics
-- SQL Server creates statistics for each index, and for single columns used as searchable arguments in queries.
-- DB options:
--  AUTO_CREATE_STATISTICS - default
--  AUTO_UPDATE_STATISTICS - update statistics when there are enough changes in the underlying tables and indexes
--  AUTO_UPDATE_STATISTICS_ASYNC - 
-- CREATE, DROP, UPDATE is supported
SELECT * from sys.stats where object_id = OBJECT_ID('dbo.SomeTable', 'U');
SELECT * from sys.stats_columns where object_id = OBJECT_ID('dbo.SomeTable', 'U');
UPDATE STATISTICS dbo.SomeTable;
EXEC sys.sp_updatestats;
DBCC SHOW_STATISTICS(N'dbo.SomeTable', N'IX_SomeTable_SomeUniqueId') WITH HISTOGRAM; -- density
DBCC SHOW_STATISTICS(N'dbo.SomeTable', N'IX_SomeTable_SomeUniqueId') WITH STAT_HEADER; -- when the statistics were last updated
--SELECT STATS_DATE(objID, statsID);
--DROP STATISTICS dbo.SomeTable.IX_SomeTable_SomeUniqueId;
--ALTER DATABASE AdventureWorks2014 SET AUTO_CREATE_STATISTICS OFF WITH NO_WAIT;


--ALTER TABLE SomeTable ADD CONSTRAINT FK_SomeTable_ClientID FOREIGN KEY (ClientID) REFERENCES Client (ID) -- enabled and trusted
--ALTER TABLE SomeTable NOCHECK CONSTRAINT FK_SomeTable_ClientID -- disable the constraint
--ALTER TABLE SomeTable CHECK CONSTRAINT FK_SomeTable_ClientID -- re-enable constraint, data isnt checked, so not trusted

-- drop the foreign key constraint & re-add it making sure its checked constraint is then enabled and trusted:
--ALTER TABLE SomeTable DROP CONSTRAINT FK_SomeTable_ClientID
--ALTER TABLE SomeTable WITH CHECK ADD CONSTRAINT FK_SomeTable_ClientID FOREIGN KEY (ClientID) REFERENCES Client (ID)

--drop the foreign key constraint & add but dont check constraint is then enabled, but not trusted
--ALTER TABLE SomeTable DROP CONSTRAINT FK_SomeTable_ClientID
--ALTER TABLE SomeTable WITH NOCHECK ADD CONSTRAINT FK_SomeTable_ClientID FOREIGN KEY (ClientID) REFERENCES Client (ID)