CREATE CREDENTIAL [ADGroupManagementCred] WITH IDENTITY = N'CORP\SVC-ADGroupManage',
SECRET = N'P@ssword'
GO 

USE [master]
CREATE LOGIN [CORP\SVC-ADGroupManage] FROM WINDOWS WITH DEFAULT_DATABASE=[ADGroupManagementDB]
GO
ALTER LOGIN [CORP\SVC-ADGroupManage] ADD CREDENTIAL [ADGroupManagementCred]
GO

EXEC msdb.dbo.sp_add_proxy
@proxy_name=N'ADGroupManagementProxy',
@credential_name=N'ADGroupManagementCred',
@enabled=1
GO

--Run CmdExec sub-system (sub-system = 3)
EXEC msdb.dbo.sp_grant_proxy_to_subsystem
@proxy_name=N'ADGroupManagementProxy',
@subsystem_id=3
GO

EXEC msdb.dbo.sp_grant_login_to_proxy
@proxy_name=N'ADGroupManagementProxy',
@login_name=N'CORP\SVC-ADGroupManage'
GO

USE [ADGroupManagementDB]
GO
CREATE USER [CORP\SVC-ADGroupManage] FOR LOGIN [CORP\SVC-ADGroupManage]
ALTER ROLE [db_datareader] ADD MEMBER [CORP\SVC-ADGroupManage]
GO

-- Create SQL Job

USE [msdb]
GO

/****** Object:  Job [ADGroupManagementJob]    Script Date: 2/26/2013 11:24:55 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 2/26/2013 11:24:55 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ADGroupManagementJob', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'CORP\Administrator', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Process Group Membership Changes]    Script Date: 2/26/2013 11:24:55 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Process Group Membership Changes', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, 
		@subsystem=N'CmdExec', 
		@command=N'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -file "C:\ADGroupManagement\SQLJob.ps1"', 
		@flags=32, 
		@proxy_name=N'ADGroupManagementProxy'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'HourlyJobSchedule', 
		@enabled=1, 
		@freq_type=4,
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120604, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'9c7b2ac1-b1a7-411b-b8ef-5f1be639852a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
