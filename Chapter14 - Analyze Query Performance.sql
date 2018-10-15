USE AdventureWorks2014;

/*
You should use SQL Server Extended Events instead of SQL Trace and SQL Server Profiler
because Extended Events is more lightweight and SQL Trace and SQL Server Profiler are
deprecated in future versions of SQL Server.
*/

-- Server -> Management -> Extended Events -> Sessions -> New...
CREATE EVENT SESSION [TK461Ch14] ON SERVER 
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[database_name]=N'AdventureWorks2014' AND [sqlserver].[like_i_sql_unicode_string]([sqlserver].[sql_text],N'SELECT%'))) 
ADD TARGET package0.ring_buffer
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

-- Now we can scan this
SELECT * from Person.Address
GO

-- SET STATISTICS IO ON - Information about the number of pages per table accessed by queries
-- SET STATISTICS TIME ON - Information about the number of pages per table accessed by queries
-- SET SHOWPLAN_TEXT ON and SET SHOWPLAN_ALL ON for estimated plans
-- SET STATISTICS PROFILE ON for actual plans
-- SET SHOWPLAN_XML ON for estimated plans
-- SET STATISTICS XML ON for actual plans
DBCC DROPCLEANBUFFERS;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SET STATISTICS XML ON;

	SELECT * from Sales.Customer;
	--(19820 row(s) affected)
	--Table 'Customer'. Scan count 1, logical reads 123, physical reads 1, read-ahead reads 121, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
	--SQL Server Execution Times: CPU time = 46 ms,  elapsed time = 188 ms.
	
	SELECT * from Sales.SalesOrderDetail;
	--(121317 row(s) affected)
	--Table 'SalesOrderDetail'. Scan count 1, logical reads 1246, physical reads 2, read-ahead reads 1284, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
	--SQL Server Execution Times: CPU time = 172 ms,  elapsed time = 1217 ms.

	SELECT C.CustomerID, C.AccountNumber, C.TerritoryID
	FROM Sales.Customer AS C
	INNER JOIN Sales.SalesOrderHeader AS O
	ON C.CustomerID = O.CustomerID;
	--(31465 row(s) affected)
	--Table 'SalesOrderHeader'. Scan count 1, logical reads 57, physical reads 1, read-ahead reads 55, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
	--Table 'Customer'. Scan count 1, logical reads 123, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
	--SQL Server Execution Times: CPU time = 109 ms,  elapsed time = 210 ms.

	SELECT C.CustomerID, C.AccountNumber, C.TerritoryID
	FROM Sales.Customer AS C
	INNER JOIN Sales.SalesOrderHeader AS O
		ON C.CustomerID = O.CustomerID
	WHERE O.CustomerID < 11005;
	--(15 row(s) affected)
	--Table 'Customer'. Scan count 0, logical reads 30, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
	--Table 'SalesOrderHeader'. Scan count 1, logical reads 2, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
	--SQL Server Execution Times: CPU time = 0 ms,  elapsed time = 0 ms.

	EXEC uspGetEmployeeManagers @BusinessEntityID = 1
	--Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
	--Table 'Employee'. Scan count 1, logical reads 11, physical reads 2, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
	--Table 'Worktable'. Scan count 2, logical reads 7, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
	--Table 'Person'. Scan count 0, logical reads 3, physical reads 3, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
	--SQL Server Execution Times: CPU time = 0 ms,  elapsed time = 46 ms.
	--SQL Server Execution Times: CPU time = 0 ms,  elapsed time = 46 ms.
	--SQL Server Execution Times: CPU time = 0 ms,  elapsed time = 0 ms.

SET STATISTICS XML OFF;
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;

-- Dynamic Management Objects
-- "Cumulative information is useless if the instance was restarted recently."
-- For analyzing query performance, the most useful groups include:
--  SQL Server Operating System (SQLOS)–related DMOs
--  Execution-related DMOs
--  Index-related DMOs

SELECT 
	cpu_count AS logical_cpu_count,
	cpu_count / hyperthread_ratio AS physical_cpu_count,
	CAST(physical_memory_kb / 1024. AS int) AS physical_memory__mb,
	sqlserver_start_time
FROM sys.dm_os_sys_info;


SELECT 
	S.login_name, S.host_name, S.program_name,
	WT.session_id, WT.wait_duration_ms, WT.wait_type,
	WT.blocking_session_id, WT.resource_description
FROM sys.dm_os_waiting_tasks AS WT
INNER JOIN sys.dm_exec_sessions AS S
	ON WT.session_id = S.session_id
WHERE s.is_user_process = 1;

SELECT 
	S.login_name, S.host_name, S.program_name,
	R.command, T.text,
	R.wait_type, R.wait_time, R.blocking_session_id--, R.plan_handle
FROM sys.dm_exec_requests AS R
INNER JOIN sys.dm_exec_sessions AS S
	ON R.session_id = S.session_id
OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS T
WHERE S.is_user_process = 1;

--following query lists five queries that used the most logical disk IO
SELECT TOP (5)
	(total_logical_reads + total_logical_writes) AS total_logical_IO,
	execution_count,
	(total_logical_reads/execution_count) AS avg_logical_reads,
	(total_logical_writes/execution_count) AS avg_logical_writes,
	(SELECT SUBSTRING(text, statement_start_offset/2 + 1,
	(CASE WHEN statement_end_offset = -1
	THEN LEN(CONVERT(nvarchar(MAX),text)) * 2
	ELSE statement_end_offset
	END - statement_start_offset)/2)
FROM sys.dm_exec_sql_text(sql_handle)) AS query_text
FROM sys.dm_exec_query_stats
ORDER BY (total_logical_reads + total_logical_writes) DESC;


SELECT * FROM sys.dm_db_missing_index_details
SELECT * FROM sys.dm_db_missing_index_columns
SELECT * FROM sys.dm_db_missing_index_groups
SELECT * FROM sys.dm_db_missing_index_group_stats

-- 10 most used indexes
SELECT i.name, i.type_desc, usage.TotalUserUsage, ius.*
FROM sys.indexes i
JOIN sys.dm_db_index_usage_stats ius
	ON i.object_id = ius.object_id
CROSS APPLY 
	(SELECT ius.user_seeks + ius.user_scans + ius.user_lookups as TotalUserUsage) AS usage
ORDER BY usage.TotalUserUsage DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;


--find nonclustered indexes that were not used from the last start of the instance by using the following query.
SELECT OBJECT_NAME(I.object_id) AS objectname,
	I.name AS indexname,
	I.index_id AS indexid
FROM sys.indexes AS I
INNER JOIN sys.objects AS O
	ON O.object_id = I.object_id
WHERE I.object_id > 100
	AND I.type_desc = 'NONCLUSTERED'
	AND I.index_id NOT IN
		(SELECT S.index_id
		FROM sys.dm_db_index_usage_stats AS S
		WHERE S.object_id=I.object_id
			AND I.index_id=S.index_id
			AND database_id = DB_ID('AdventureWorks2014'))
ORDER BY objectname, indexname;

--find missing indexes by using index-related DMOs. Use the following query.
SELECT MID.statement AS [Database.Schema.Table],
	MIC.column_id AS ColumnId,
	MIC.column_name AS ColumnName,
	MIC.column_usage AS ColumnUsage,
	MIGS.user_seeks AS UserSeeks,
	MIGS.user_scans AS UserScans,
	MIGS.last_user_seek AS LastUserSeek,
	MIGS.avg_total_user_cost AS AvgQueryCostReduction,
	MIGS.avg_user_impact AS AvgPctBenefit
FROM sys.dm_db_missing_index_details AS MID
CROSS APPLY sys.dm_db_missing_index_columns (MID.index_handle) AS MIC
INNER JOIN sys.dm_db_missing_index_groups AS MIG
	ON MIG.index_handle = MID.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats AS MIGS
	ON MIG.index_group_handle=MIGS.group_handle
ORDER BY MIGS.avg_user_impact DESC;

-- Obtaining query plan
SELECT qs.execution_count AS cnt, qt.text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.text LIKE N'%Sales.Customer%'
	AND qt.text NOT LIKE N'%qs.execution_count%'
ORDER BY qs.execution_count;

-- Heap / Page / Disk usage
DECLARE @SomeTable AS NVARCHAR(100) = N'Sales.Customer';
EXEC dbo.sp_spaceused @objname = @SomeTable, @updateusage = true;
SELECT 
	index_type_desc, page_count,
	record_count, avg_page_space_used_in_percent
FROM sys.dm_db_index_physical_stats
	(DB_ID(N'tempdb'), OBJECT_ID(@SomeTable), NULL, NULL , 'DETAILED');
	

-- Note: If a table is organized as a heap, then the only access method available to SQL Server is a table scan.

-- DYNAMIC SQL vs SPROC
-- Using dynamic SQL is not a good practice. In order to enforce plan reuse, you should use
-- programmatic objects such as stored procedures. The following code creates a procedure
-- that wraps the query that retrieves a single order in a stored procedure.

-- WITH RECOMPILE
--You can force SQL Server to recompile a stored procedure if you create it with the
--WITH RECOMPILE option. In addition, you can force recompilation on a query level. Instead
--of recompiling the complete procedure, you can recompile only the critical statements.


--// Optimizer Hints and Plan Guides
-- You can influence query execution by using hints:
-- table hints
-- query hints
-- join hints

--// The following query hints are supported by SQL Server 2012:
-- { HASH | ORDER } GROUP
-- { CONCAT | HASH | MERGE } UNION
-- { LOOP | MERGE | HASH } JOIN
-- EXPAND VIEWS
-- FAST number_rows
--! FORCE ORDER - Specifies that the join order indicated by the query syntax is preserved during query optimization. 
-- IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX
-- KEEP PLAN - relax the estimated recompile threshold for a query
-- KEEPFIXED PLAN - not to recompile a query due to changes in statistics
--! MAXDOP number_of_processors
-- MAXRECURSION number
--! OPTIMIZE FOR ( @variable_name { UNKNOWN | = literal_constant } [ ,...n ] ) - Instructs the query optimizer to use a particular value for a local variable when the query is compiled and optimized. The value is used only during query optimization, and not during query execution.
-- OPTIMIZE FOR UNKNOWN
-- PARAMETERIZATION { SIMPLE | FORCED }
--! RECOMPILE - discard the plan generated for the query after it executes, forcing the query optimizer to recompile a query plan the next time the same query is executed
--! ROBUST PLAN - try a plan that works for the maximum potential row size, possibly at the expense of performance
-- USE PLAN N'xml_plan'
-- TABLE HINT ( exposed_object_name [ , <table_hint> [ [, ]...n ] ]

--// The following table hints are supported by SQL Server 2012:
-- NOEXPAND
--! INDEX ( index_value [ ,...n ] ) | INDEX = ( index_value ) - can be used to force the join direction, if not then wrong direction can cause excessive memo buffer usage  
-- FORCESEEK [ ( index_value ( index_column_name [ ,... ] ) ) ]
-- FORCESCAN
-- FORCESEEK
-- KEEPIDENTITY - Is applicable only in an INSERT statement when the BULK option is used with OPENROWSET. pecifies that identity value or values in the imported data file are to be used for the identity column.
-- KEEPDEFAULTS - Is applicable only in an INSERT statement when the BULK option is used with OPENROWSET. Specifies to insert a table column's default value, if any, instead of NULL when the data record lacks a value for the column.
-- IGNORE_CONSTRAINTS - Is applicable only in an INSERT statement when the BULK option is used with OPENROWSET.
-- IGNORE_TRIGGERS - Is applicable only in an INSERT statement when the BULK option is used with OPENROWSET.
-- HOLDLOCK - applies only to the table or view for which it is specified and only for the duration of the transaction defined by the statement that it is used in
--! NOLOCK - Specifies that dirty reads are allowed. 
-- NOWAIT - Instructs the SQL Server 2005 Database Engine to return a message as soon as a lock is encountered on the table. NOWAIT is equivalent to specifying SET LOCK_TIMEOUT 0 for a specific table.
-- PAGLOCK - Takes page locks either where individual locks are ordinarily taken on rows or keys, or where a single table lock is ordinarily taken.
-- READCOMMITTED - Specifies that read operations comply with the rules for the READ COMMITTED isolation level by using either locking or row versioning.
-- READCOMMITTEDLOCK - Specifies that read operations comply with the rules for the READ COMMITTED isolation level by using locking.
-- READPAST - Specifies that the Database Engine not read rows that are locked by other transactions. Under most circumstances, the same is true for pages. 
-- READUNCOMMITTED = NOLOCK - Specifies that dirty reads are allowed. 
-- REPEATABLEREAD
-- ROWLOCK - Specifies that row locks are taken when page or table locks are ordinarily taken. 
-- SERIALIZABLE - Is equivalent to HOLDLOCK. Makes shared locks more restrictive by holding them until a transaction is completed, instead of releasing the shared lock as soon as the required table or data page is no longer needed, whether the transaction has been completed or not. 
-- SPATIAL_WINDOW_MAX_CELLS = integer
-- TABLOCK - Specifies that a lock is taken on the table and held until the end-of-statement. If data is being read, a shared lock is taken. If data is being modified, an exclusive lock is taken. If HOLDLOCK is also specified, a shared table lock is held until the end of the transaction.
-- TABLOCKX - Specifies that an exclusive lock is taken on the table until the transaction completes.
--! UPDLOCK - Specifies that update locks are to be taken and held until the transaction completes.
-- XLOCK - Specifies that exclusive locks are to be taken and held until the transaction completes. If specified with ROWLOCK, PAGLOCK, or TABLOCK, the exclusive locks apply to the appropriate level of granularity.

--// SQL Server 2012 also supports the following join hints in the FROM clause:
-- LOOP
-- HASH
-- MERGE
-- REMOTE