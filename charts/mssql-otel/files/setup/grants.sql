USE [master];
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '$(monitor_user)')
BEGIN
  CREATE LOGIN [$(monitor_user)] WITH PASSWORD = '$(monitor_password)';
END
GO

GRANT VIEW SERVER STATE TO [$(monitor_user)];
GRANT VIEW ANY DEFINITION TO [$(monitor_user)];
GRANT VIEW ANY DATABASE TO [$(monitor_user)];
GO

DECLARE @name SYSNAME;
DECLARE db_cursor CURSOR READ_ONLY FORWARD_ONLY FOR
SELECT [name]
FROM [master].[sys].[databases]
WHERE [name] NOT IN ('master', 'msdb', 'model', 'rdsadmin', 'distribution')
AND [state] = 0;
OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @name;
WHILE @@FETCH_STATUS = 0
BEGIN
  BEGIN TRY
    EXEC('USE [' + @name + '];
      IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''$(monitor_user)'')
      BEGIN
        CREATE USER [$(monitor_user)] FOR LOGIN [$(monitor_user)];
      END;
      GRANT VIEW DATABASE STATE TO [$(monitor_user)];');
  END TRY
  BEGIN CATCH
    PRINT 'Error on ' + @name + ': ' + ERROR_MESSAGE();
  END CATCH
  FETCH NEXT FROM db_cursor INTO @name;
END
CLOSE db_cursor;
DEALLOCATE db_cursor;
GO
