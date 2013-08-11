#region File Cluster Migration Script Description
## =====================================================================
## Title       : File Cluster Migration Script (FCMigrationPub.ps1)
## Description : Create cluster shares and assign owner to home dir.
## Author      : Anthony Duplessis
## Date        : 1/24/2010
## Input       : Make sure the below variable are set correctly.
## Variables   :
##
## $body - Body of email message
## $Count - Used to count number of users to process from text file
## $DirExists - Directory Exists Counter
## $DirNoExists - Directory does not exist counter
## $emailFrom - Email from email address
## $emailTo - Email to email address
## $HomeDirModified - Directory owner set counter
## $HomePath - Variable that must be set for each server - path to home folder root
## $IcaclsPath - Static path to Icacls.exe
## $InputFile - Variable that must be set for each server - path and name of file with user account names.
## $NetPath - Static path to Net.exe
## $RunCompact - Variable to invoke to run Compact.exe to un-compress files
## $RunIcaclsCommand - Variable to invoke to set owner of directory and files of home folders
## $Sharename - Name of share to create a combination of $UserName and "$" dollar sign
## $ShareReportPath - path and file name for share creation report
## $SharesCreated - Number of shares created counter
## $smtp - object definition
## $smtp.Send - send routine
## $smtpServer - SMTP Server name
## $subject - email subject
## $Total - total count of users in file
## $UserDir - variable of the users hole directory path
##                                   
## Output      : to log file as defined in $ShareReportPath variable
## Usage       :
##               1. Edit the variables below for the correct locations, file names, email addresses and email text 
##               of the variables in the VARIABLES THAT REQUIRE MODIFICATIONS section.
## 
##               The script will scan the users to be modified from the file
##               - count the number of users
##				 - verify that there home directory exists
##				 - create their home share
##               - make the user the owner of their home directory and directories and files within
##               - Un-compress the files and directories
##               - Send an email notification of the completion of the script
##            
## Notes       :
## Change log  :
## =====================================================================
#endregion

#region Initialize Variables
## =====================================================================
## Initialize Variables
## =====================================================================
Clear-Host
## =====================================================================
##                                  VARIABLES THAT REQUIRE MODIFICATIONS
## =====================================================================
$HomePath = "N:\HomeDirs\"
$InputFile = "D:\HomeDirs.txt"
$ShareReportPath = "D:\Shares.log"
$emailFrom = "FileClusterMigration@company.com"
$emailTo = "superadmin@company.com,admin@company.com"
$smtpServer = "smtp.company.com"

## =====================================================================
## No changes below this line
## =====================================================================
$NetPath = "C:\Windows\System32\NET.exe SHARE "
$IcaclsPath = "C:\Windows\System32\ICACLS.exe "
$subject = ""
$body = ""
$RunCompact = ""
$Sharename = $UserName + "$"
$SharesCreated = 0
$HomeDirModified = 0
$DirExists = 0
$DirNoExists = 0
#endregion

#region Display Script Title
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "             F I L E  C L U S T E R  M I G R A T I O N  T O O L" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
#endregion

#region Loop to Count items in text file and verify the home directory exists
## ========================================================================
## "Loop to Count items in text file and verify the home directory exists"
## ========================================================================

$body = @"
The File Cluster Migration script count and verify directory has started.
"@
$subject = "FCMigration Script Count and Directory Verification Routine Started."
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom, $emailTo, $subject, $body)

Foreach ($UserName in (Get-Content $InputFile))
{
	$Count = $Count + 1
	$Total = $Count
	$UserDir = $HomePath + $Username

	if (Test-Path $UserDir)
	{
		$DirExists = $DirExists + 1
	}
	else
	{
		$DirNoExists = $DirNoExists + 1
		Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
		Write-Host "The Following Directories do not match the supplied User ID" -ForegroundColor Yellow
		Write-Host " "
		Write-Host "$UserDir, Does Not Exist for User ID: $UserName" -ForegroundColor Red
		Write-Host " "


	}
}
Write-Host "????????????????????????????????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
Write-Host " Total Directories Excpected - " $Total -ForegroundColor Green
Write-host "     Total Directories Found - " $DirExists -ForegroundColor Green
Write-host "   Total Directories Missing - " $DirNoExists -ForegroundColor Red
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta

If ($DirNoExists -gt 0)
{
	Write-Host "????????????????????????????????????????????????????????????????????????????????" -ForegroundColor Red
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
	Write-Host "                 FIX THE ABOVE ERRORS AND RE-RUN THIS SCRIPT!" -ForegroundColor Yellow
	Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta

	Exit
}
Else
{

}
#endregion

#region Loop to Create Share
$body = @"
The File Cluster Migration script Share Creation Routine has Started. 
"@
$subject = "FCMigration Script Share Creation Routine has Started."
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom, $emailTo, $subject, $body)
## =====================================================================
## Loop to Create Share
## =====================================================================
Foreach ($UserName in (Get-Content $InputFile))
{
	$SharesCreated = $SharesCreated + 1
	$Sharename = $UserName + "$"
	$RunNetCommand = "cmd /c $NetPath$Sharename=$HomePath$UserName '/GRANT:EVERYONE,FULL'"
	Invoke-Expression $RunNetCommand
}
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "????????????????????????????????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "The Share Creation Routine Created" $SharesCreated "of" $Total "shares" -ForegroundColor Green
Write-Host "See the file at" $ShareReportPath "for details" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
$body = @"
The File Cluster Migration script Share Creation Routine Completed. 
It processed $SharesCreated shares out of a possible $Total of users.
The log file of the shares created is located at $ShareReportPath."

The Directory / File ownerhsip is being set. 

"@
$subject = "FCMigration Script Share Creation Routine Completed."
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom, $emailTo, $subject, $body)
#endregion

#region Loop to Grant Onwer of Home Directory
## =====================================================================
## Loop to Grant Onwer of Home Directory
## =====================================================================
$RunIcaclsCommand = "cmd /c $IcaclsPath$HomePath /setowner Administrators /T" 
Invoke-Expression $RunIcaclsCommand
Foreach ($UserName in (Get-Content $InputFile))
{
	$HomeDirModified = $HomeDirModified + 1
	$RunIcaclsCommand = "cmd /c $IcaclsPath$HomePath$UserName /setowner $UserName /T"
	Invoke-Expression $RunIcaclsCommand
}
Write-Host "????????????????????????????????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "The Grant Owner Routine Modified "$HomeDirModified" of " $Total "home folders" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
$body = @"
The File Cluster Migration script Grant Owner Routine Completed. 
The Grant Owner Routine Modified " $HomeDirModified " home folders out of " $Total "home folders to modify

The routine to un-compress the files and directories is being run. 
"@
$subject = "FCMigration Script Grant Ownership Completed."
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom, $emailTo, $subject, $body)
#endregion

#region Invoke compress command to uncompress files
## =====================================================================
## Invoke compress command to uncompress files
## =====================================================================
Write-Host "????????????????????????????????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "The UnCompress Routine Has been started, This will take a while..." -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
$UserName = " "
Foreach ($UserName in (Get-Content $InputFile))
{
	$UserDir = $HomePath + $Username
	$RunCompact = "cmd /c compact /u /s:$UserDir /f /i /q"
	Invoke-Expression $RunCompact
}
#endregion

#region Send Completion Email
## =====================================================================
## Send Completion Email
## =====================================================================
$body = @"
The File Cluster Migration script has completed. 
It processed $SharesCreated shares out of a possible $Total of users.
The log file of the shares created is located at $ShareReportPath."

and the Grant Owner Routine Modified $HomeDirModified home folders out of $Total home folders to modify.

This email signifies the end of the un-compress routine, the script has completed and stopped. 

"@
$subject = "FCMigration Script Has Completed."
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom, $emailTo, $subject, $body)
Write-Host "????????????????????????????????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "      F I L E  C L U S T E R  M I G R A T I O N  T O O L  C O M P L E T E" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "????????????????????????????????????????????????????????????????????????????????" -ForegroundColor Green
#endregion
Exit