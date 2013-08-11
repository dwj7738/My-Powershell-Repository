<# 
.SYNOPSIS 
Manage-BackupExec  
 
.DESCRIPTION 
This script is a collection of PowerShell commands that shows examples of performing some basic Backup Exec 2012 tasks with PowerShell to give you an idea of how easy it is to manage without a GUI.  
 
.Notes 
LastModified: 5/27/2012 
Author:       Mike F Robbins 
#> 

# Import the Backup Exec 2012 PowerShell Module 
Import-Module BEMCLI 

# Inventory the backup tapes in the tape drives: 
Get-BETapeDriveDevice | 
Submit-BEInventoryJob | 
select Name, JobType, Schedule, Storage | 
ft –auto 

# Once the inventory completes, retrieve the name of the backup tape in each tape drive: 
Get-BETapeDriveDevice | 
select Name, Media | 
ft –auto 

# Perform a quick erase on the backup tape in each of the tape drives: 
Get-BETapeDriveDevice | 
Submit-BEEraseMediaJob | 
select Name, JobType, Status, Schedule | 
ft -auto 

# Run both of the overwrite jobs. This is dependent on having two jobs named "Overwrite Drive #" and no other jobs that start with O. 
Get-BEJob -Name "o*" | 
Start-BEJob | 
Out-Null 

# List the backup jobs that failed with a status of error in the past 12 hours: 
Get-BEJobHistory -JobStatus Error -FromStartTime (Get-Date).AddHours(-12) | 
ft -auto 

# Example of a parameters valid values 
help Get-BEJobHistory –Parameter JobStatus 

# Re-run the backup jobs that failed due to a status of error in the past 12 hours: 
Get-BEJob -Name (Get-BEJobHistory -JobStatus Error -FromStartTime (Get-Date).AddHours(-12) | 
	select -expand name) | 
Start-BEJob | 
Out-Null 

# Jobs that are currently active and ready: 
Get-BEJob -Status “Active”, “Ready” | 
select Storage, Name, JobType, Status | 
ft -auto 

# Cancel all of the active backup jobs: 
Get-BEJob -Status "Active" | 
Stop-BEJob | 
ft –auto 

# Eject the backup tape from each of the tape drives: 
Get-BETapeDriveDevice | 
Submit-BEEjectMediaJob | 
Out-Null 