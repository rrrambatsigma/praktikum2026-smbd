
/*
=========================================================
PRAKTIKUM SMBD
BACKUP DAN VERIFIKASI SELURUH USER DATABASE
=========================================================
*/

-- =======================================================
-- 1. INFORMASI SERVER DAN DATABASE
-- =======================================================

SELECT
    @@SERVERNAME AS ServerName,
    SERVERPROPERTY('InstanceName') AS InstanceName,
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('Edition') AS Edition;
GO

SELECT
    name AS DatabaseName,
    state_desc AS DatabaseStatus,
    recovery_model_desc AS RecoveryModel
FROM sys.databases
ORDER BY name;
GO

-- =======================================================
-- 2. BACKUP DAN VERIFIKASI SELURUH USER DATABASE
-- =======================================================

USE master;
GO

SET NOCOUNT ON;
GO

-- -------------------------------------------------------
-- A. KONFIGURASI
-- -------------------------------------------------------

DECLARE @BackupDir NVARCHAR(4000) = N'E:\SQLBackup';

-- Timestamp untuk seluruh file backup
DECLARE @Timestamp VARCHAR(20) =
    CONVERT(CHAR(8), GETDATE(), 112) + '_' +
    REPLACE(CONVERT(CHAR(8), GETDATE(), 108), ':', '');

-- -------------------------------------------------------
-- B. VARIABEL PROSES
-- -------------------------------------------------------

DECLARE @DatabaseName SYSNAME;
DECLARE @SafeDatabaseName NVARCHAR(260);
DECLARE @BackupFile NVARCHAR(4000);
DECLARE @SQL NVARCHAR(MAX);

-- -------------------------------------------------------
-- C. TABEL HASIL
-- -------------------------------------------------------

CREATE TABLE #BackupResults (
    ID INT IDENTITY(1,1),
    DatabaseName SYSNAME,
    BackupFile NVARCHAR(4000),
    BackupStatus VARCHAR(20),
    VerifyStatus VARCHAR(20),
    ErrorMessage NVARCHAR(MAX)
);

-- -------------------------------------------------------
-- D. AMBIL SELURUH USER DATABASE YANG ONLINE
-- -------------------------------------------------------

DECLARE db_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT name
FROM sys.databases
WHERE database_id > 4
  AND state_desc = 'ONLINE'
ORDER BY name;

OPEN db_cursor;

FETCH NEXT FROM db_cursor INTO @DatabaseName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Buat nama file yang aman untuk sistem file
    SET @SafeDatabaseName = @DatabaseName;

    SET @SafeDatabaseName = REPLACE(@SafeDatabaseName, N'\', N'_');
    SET @SafeDatabaseName = REPLACE(@SafeDatabaseName, N'/', N'_');
    SET @SafeDatabaseName = REPLACE(@SafeDatabaseName, N':', N'_');
    SET @SafeDatabaseName = REPLACE(@SafeDatabaseName, N'*', N'_');
    SET @SafeDatabaseName = REPLACE(@SafeDatabaseName, N'?', N'_');
    SET @SafeDatabaseName = REPLACE(@SafeDatabaseName, N'"', N'_');
    SET @SafeDatabaseName = REPLACE(@SafeDatabaseName, N'<', N'_');
    SET @SafeDatabaseName = REPLACE(@SafeDatabaseName, N'>', N'_');
    SET @SafeDatabaseName = REPLACE(@SafeDatabaseName, N'|', N'_');

    -- Tentukan path file backup
    SET @BackupFile =
        @BackupDir + N'\' +
        @SafeDatabaseName + N'_' +
        @Timestamp + N'.bak';

    PRINT N'========================================';
    PRINT N'Database: ' + @DatabaseName;
    PRINT N'File: ' + @BackupFile;

    -- ---------------------------------------------------
    -- E. PROSES BACKUP
    -- ---------------------------------------------------

    BEGIN TRY

        SET @SQL =
            N'BACKUP DATABASE ' + QUOTENAME(@DatabaseName) +
            N' TO DISK = N''' +
            REPLACE(@BackupFile, '''', '''''') +
            N''' WITH COPY_ONLY, CHECKSUM, COMPRESSION, STATS = 10;';

        EXEC sys.sp_executesql @SQL;

        -- ------------------------------------------------
        -- F. VERIFIKASI FILE BACKUP
        -- ------------------------------------------------

        BEGIN TRY

            SET @SQL =
                N'RESTORE VERIFYONLY FROM DISK = N''' +
                REPLACE(@BackupFile, '''', '''''') +
                N''' WITH CHECKSUM;';

            EXEC sys.sp_executesql @SQL;

            INSERT INTO #BackupResults (
                DatabaseName,
                BackupFile,
                BackupStatus,
                VerifyStatus,
                ErrorMessage
            )
            VALUES (
                @DatabaseName,
                @BackupFile,
                'BERHASIL',
                'BERHASIL',
                NULL
            );

            PRINT N'BACKUP DAN VERIFIKASI BERHASIL';

        END TRY
        BEGIN CATCH

            INSERT INTO #BackupResults (
                DatabaseName,
                BackupFile,
                BackupStatus,
                VerifyStatus,
                ErrorMessage
            )
            VALUES (
                @DatabaseName,
                @BackupFile,
                'BERHASIL',
                'GAGAL',
                ERROR_MESSAGE()
            );

            PRINT N'BACKUP BERHASIL, VERIFIKASI GAGAL';
            PRINT ERROR_MESSAGE();

        END CATCH;

    END TRY
    BEGIN CATCH

        INSERT INTO #BackupResults (
            DatabaseName,
            BackupFile,
            BackupStatus,
            VerifyStatus,
            ErrorMessage
        )
        VALUES (
            @DatabaseName,
            @BackupFile,
            'GAGAL',
            'TIDAK DIPROSES',
            ERROR_MESSAGE()
        );

        PRINT N'BACKUP GAGAL';
        PRINT ERROR_MESSAGE();

    END CATCH;

    FETCH NEXT FROM db_cursor INTO @DatabaseName;
END;

-- -------------------------------------------------------
-- G. SELESAIKAN PROSES
-- -------------------------------------------------------

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- -------------------------------------------------------
-- H. TAMPILKAN HASIL
-- -------------------------------------------------------

SELECT
    ID,
    DatabaseName,
    BackupFile,
    BackupStatus,
    VerifyStatus,
    ErrorMessage
FROM #BackupResults
ORDER BY DatabaseName;

-- Ringkasan jumlah hasil
SELECT
    COUNT(*) AS TotalDatabase,
    SUM(CASE WHEN BackupStatus = 'BERHASIL'
             THEN 1 ELSE 0 END) AS BackupBerhasil,
    SUM(CASE WHEN BackupStatus = 'GAGAL'
             THEN 1 ELSE 0 END) AS BackupGagal,
    SUM(CASE WHEN VerifyStatus = 'BERHASIL'
             THEN 1 ELSE 0 END) AS VerifikasiBerhasil,
    SUM(CASE WHEN VerifyStatus = 'GAGAL'
             THEN 1 ELSE 0 END) AS VerifikasiGagal
FROM #BackupResults;

DROP TABLE #BackupResults;
GO