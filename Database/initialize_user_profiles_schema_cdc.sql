/***********************************************
  DATABASE SCHEMA CONFIGURATION
  Objective: Create user profile storage with CDC
************************************************/

-- SECTION 1: SCHEMA DESIGN WITH DATA GOVERNANCE
CREATE TABLE Profiles.UserData (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    DateOfBirth DATE,
    CreatedAt DATETIME DEFAULT GETDATE() NOT NULL,
    LastUpdated DATETIME DEFAULT GETDATE() NOT NULL,
    IsActive BIT DEFAULT 1 NOT NULL,
    
    -- Column-level documentation
    CONSTRAINT CK_ValidEmail CHECK (Email LIKE '%_@__%.__%'),
    CONSTRAINT UQ_UserEmail UNIQUE (Email)
);

-- Optimize common query patterns
CREATE NONCLUSTERED INDEX IX_User_Email ON Profiles.UserData (Email);
CREATE NONCLUSTERED INDEX IX_User_LastName ON Profiles.UserData (LastName);

COMMENT ON TABLE Profiles.UserData IS 'Central repository for user profile information with CDC tracking';
COMMENT ON COLUMN Profiles.UserData.IsActive IS 'Soft delete flag for GDPR compliance';

/***********************************************
  CDC CONFIGURATION WITH SECURITY CONTROLS
************************************************/
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Enable CDC at database level with retention policy
    EXEC msdb.dbo.rds_cdc_enable_db 'CustomerDataWarehouse';
    
    -- Create dedicated CDC service account
    CREATE ROLE CDC_Service_Account;
    GRANT SELECT ON SCHEMA::Profiles TO CDC_Service_Account;
    
    -- Configure CDC with cleanup policy
    EXEC sys.sp_cdc_enable_table  
        @source_schema = 'Profiles',
        @source_name = 'UserData',
        @role_name = 'CDC_Service_Account',
        @capture_instance = 'UserData_CDC',
        @supports_net_changes = 1,
        @filegroup_name = 'CDC_Filegroup',
        @captured_column_list = 'UserID,FirstName,LastName,Email,DateOfBirth,CreatedAt,LastUpdated',
        @pollinginterval = 10;  -- 10 seconds polling interval

    -- Verify CDC configuration
    SELECT 
        capture_instance AS [Capture Instance],
        object_name AS [Table Name],
        start_lsn AS [Start LSN],
        index_name AS [Index Used]
    FROM sys.sp_cdc_help_change_data_capture
    WHERE source_schema = 'Profiles';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
END CATCH;

/***********************************************
  SAMPLE DATA LOADING WITH AUDIT TRAIL
************************************************/
BEGIN TRANSACTION;

INSERT INTO Profiles.UserData (
    FirstName, 
    LastName, 
    Email, 
    DateOfBirth
) 
VALUES 
('John', 'Doe', 'john.doe@example.com', '1990-01-01'),
('Jane', 'Smith', 'jane.smith@example.com', '1992-02-14'),
('Alice', 'Johnson', 'alice.johnson@example.com', '1988-03-10'),
('Bob', 'Williams', 'bob.williams@example.com', '1995-04-25'),
('Charlie', 'Brown', 'charlie.brown@example.com', '1985-05-05'),
('David', 'Clark', 'david.clark@example.com', '1993-06-12'),
('Emma', 'Davis', 'emma.davis@example.com', '1991-07-18'),
('Frank', 'Garcia', 'frank.garcia@example.com', '1989-08-22'),
('Grace', 'Martinez', 'grace.martinez@example.com', '1994-09-30'),
('Hannah', 'Lopez', 'hannah.lopez@example.com', '1996-10-15');

-- Verify CDC capture after insertion
SELECT 
    COUNT(*) AS [CDC Records Captured]
FROM cdc.Profiles_UserData_CT;

COMMIT TRANSACTION;

/***********************************************
  MAINTENANCE AND MONITORING
************************************************/
-- Create CDC cleanup job
EXEC sys.sp_cdc_add_job  
    @job_type = N'cleanup',  
    @retention = 4320;  -- 3 days retention (in minutes)

-- Create monitoring query
SELECT
    capture_instance AS [Table],
    start_lsn AS [Start Sequence],
    last_commit_lsn AS [Last Commit],
    DATEDIFF(MINUTE, last_commit_time, GETDATE()) AS [Minutes Since Last Commit]
FROM sys.dm_cdc_log_scan_sessions
ORDER BY session_id DESC;
