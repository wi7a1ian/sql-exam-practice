-- Check body of al lthe sprocs for certain text (comment/object)
DECLARE @SearchText NVARCHAR(1000)
SET @SearchText = 'usp_ReportCustomerAccessFeeBilling'
 
 
SELECT ROUTINE_NAME, ROUTINE_DEFINITION
    FROM INFORMATION_SCHEMA.ROUTINES 
    WHERE ROUTINE_DEFINITION LIKE '%'+@SearchText+'%' 
    AND ROUTINE_TYPE='PROCEDURE';
 
SELECT OBJECT_NAME(id) 
    FROM SYSCOMMENTS 
    WHERE [TEXT] LIKE '%'+@SearchText+'%'  
    AND OBJECTPROPERTY(id, 'IsProcedure') = 1 
    GROUP BY OBJECT_NAME(id);
 
SELECT OBJECT_NAME(OBJECT_ID)
    FROM sys.sql_modules
    WHERE OBJECTPROPERTY(OBJECT_ID, 'IsProcedure') = 1
    AND definition LIKE '%'+@SearchText+'%'
	
-- Connect to linked database:
EXEC SP_ADDLINKEDSERVER @server = 'MSPP1PDMDCF01A\DM1DBC01A', @srvproduct='SQL Server'
SELECT * FROM [MSPP1PDMDCF01A\DM1DBC01A].[DM_Central_Control].[dbo].Project WHERE Project_ID = 54972366
EXEC SP_DROPSERVER [MSPP1PDMDCF01A\DM1DBC01A]
 
EXEC SP_ADDLINKEDSERVER @server = 'E2P1FCC1DBJ027B.CCP.EDP.LOCAL\CC1J027B', @srvproduct='SQL Server'
EXEC('select * from CCJOB_ZZ3559811_CDG_CC_POC.dbo.Doc where Doc_ID = ?;', 97261) AT [E2P1FCC1DBJ027B.CCP.EDP.LOCAL\CC1J027B]
EXEC('select * from CCJOB_ZZ3559811_CDG_EE_POC.dbo.Doc where Doc_ID = ?;', 97261)
EXEC SP_DROPSERVER [E2P1FCC1DBJ027B.CCP.EDP.LOCAL\CC1J027B]

-- Update & check index/column stats date
UPDATE STATISTICS Doc WITH FULLSCAN
 
SELECT name AS index_name,
STATS_DATE(OBJECT_ID, index_id) AS StatsUpdated
FROM sys.indexes
WHERE OBJECT_ID = OBJECT_ID('Doc')

-- 