USE AdventureWorks2014;

-- Atomicity - all database changes in the transaction succeed or none of them succeed.
-- Consistency - Every transaction, whether successful or not, leaves the database in a consistent state as defined by all object and database constraints.
-- Isolation - Every transaction looks as though it occurs in isolation from other transactions in regard to database changes. 
-- Durability - Every transaction endures through an interruption of service. When service is restored, all committed transactions are rolled forward all uncommitted transactions are rolled back.


-- Nested transactions:
-- The final outermost COMMIT statement won' actually commit anything. Only the one at @TRANCOUNT = 1 will.
-- Transaction can contain only one ROLLBACK command, and it will roll back the entire transaction and reset the @@TRANCOUNT counter to 0.

BEGIN TRAN Tran1 WITH MARK;

SAVE TRANSACTION save1
DROP TABLE Person.EmailAddress;
ROLLBACK TRANSACTION save1;

DROP TABLE Person.EmailAddress;

IF @@TRANCOUNT > 0 ROLLBACK;
GO


-- Restore to specific MARK
/*
RESTORE DATABASE TSQ2012 FROM DISK = 'C:SQLBackups\TSQL2012.bak'
WITH NORECOVERY;
GO
RESTORE LOG TSQL2012 FROM DISK = 'C:\SQLBackups\TSQL2012.trn'
WITH STOPATMARK = 'Tran1';
GO
*/

-- Shared locks Used for sessions that read data—that is, for readers
-- Exclusive locks Used for changes to data—that is, writers

-- Transaction Isolation Levels
--  READ COMMITTED
--  READ UNCOMMMITED
--  READ COMMITTED SNAPSHOT
--  REPEATABLE READ - the transaction may see new rows added after its first read; this is called a phantom read
--  SNAPSHOT - 
--  SERIALIZABLE - strongest one
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

RAISERROR('Errorrrr', 16, 1);
RAISERROR('Super print', 1, 1) WITH NOWAIT; -- PRINT
RAISERROR('Super %d print %s', 1, 1, 1337, 'bitches!') WITH NOWAIT; -- PRINT

DECLARE @message AS NVARCHAR(1000) = 'Error in % stored procedure';
SELECT @message = FORMATMESSAGE (@message, N'usp_InsertCategories');
RAISERROR (@message, 16, 0);

-- THROW always terminates the batch except when it is used in a TRY block.
THROW 50666, 'Error', 1;
THROW;

-- Try convert/parse
SELECT TRY_CONVERT(DATETIME, '1752-12-31'); -- convert
SELECT TRY_CONVERT(DATETIME, '1753-01-01');
SELECT TRY_PARSE('1' AS INTEGER); -- parse / cast
SELECT TRY_PARSE('B' AS INTEGER);

-- Unstructured Error Handling Using @@ERROR
--@@ERROR always reports the error status of the command last executed
DECLARE @errorNr INT
PRINT 'Some operation'
SET @errorNr = @@error
IF @errorNr <> 0
	PRINT('We have an error!')
ELSE
	PRINT('No error.')


-- XACT_ABORT - for sprocs
--roll back based on any error with severity > 10
BEGIN TRAN;
SET XACT_ABORT ON;
	---...
	CREATE TABLE #dupa(Id uniqueidentifier default(newid()));
	-- DROP TABLE #dupa
	--RAISERROR('rollback all', 16, 1); -- does nto work!?!?
	THROW 50666, 'Error', 1;
	IF @@TRANCOUNT > 0 COMMIT TRAN;
SET XACT_ABORT OFF;
COMMIT TRAN;
GO
SET XACT_ABORT OFF; -- for safety of future examples
GO

-- Structured Error Handling Using TRY/CATCH
--Errors with severity greater than 10 and less than 20 within the TRY block result in transferring control to the CATCH block.
--If we combine XACT_ABORT with TRY/CATCH then we will always get in CATCH the uncommitable state ( XACT_STATE() = -1 ).
--  1 An open transaction exists that can be either committed or rolled back.
--  0 There is no open transaction; it is equivalent to @@TRANCOUNT = 0.
-- -1 An open transaction exists, but it is not in a committable state. The transaction can only be rolled back.
BEGIN TRAN;
BEGIN TRY
	CREATE TABLE #dupa(Id uniqueidentifier default(newid()));
	RAISERROR('Error 1', 16, 1);
	THROW 50666, 'Error 2', 1;
	IF @@TRANCOUNT > 0 COMMIT TRAN;
END TRY
BEGIN CATCH
	SELECT ERROR_NUMBER() AS errornumber
	, ERROR_MESSAGE() AS errormessage
	, ERROR_LINE() AS errorline
	, ERROR_SEVERITY() AS errorseverity
	, ERROR_STATE() AS errorstate;

	--IF XACT_STATE() = 1 -- open transaction that can be commited
	--	COMMIT TRAN
	--ELSE
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
	THROW; -- rethrow
END CATCH


-- Dynamic SQL
DECLARE @tablename AS NVARCHAR(261) = N'SELECT COUNT(*) FROM Production.Product';
SELECT @tablename;
EXECUTE(@tablename); -- one batch only

EXEC sp_executesql @tablename -- can accept input/output params
-- The ability to parameterize means that sp_excutesql avoids simple concatenations like those used in the EXEC statement. As a result, it can be used to help prevent SQL injection.
-- Better performance. Its parameterization aids in reusing cached execution plans.






