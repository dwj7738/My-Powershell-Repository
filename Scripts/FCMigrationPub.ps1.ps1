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
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdw0TOeD7AbwhGtbwBUtwLmul
# R+2gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCDOGm/ExbkFRcnd
# NmYbnLNM+ajJMA0GCSqGSIb3DQEBAQUABIIBAMjRCbIoUmg5LADKiW7rdOn8/VVJ
# 7F3rPSlO767gYQ8PemuNCB+TWHpSj0r3USXhsX7Bv4SLi1Zvu24XZxharDnj9Dx1
# pdceWLpaaezlRLIrIdW1W90fc8T9eZ7hUzrF0NDvmQnmDtBFcs0rtxN5wkKNkrHm
# W4zHye8FVk9pf2cjXRYC3g8PUhMoK53ZsOvCvdx3I7WQAk4ls095kevy+LbTREYZ
# jG1gVsYJfOejhRQARg6OVqxpQGGFwEqFr4Y+pVZYLcC3sj6f1Rrhv1dY6uUkSyck
# Tj20IFzzMh1ztfssGOEoV9aVdzq/8VYZS3olqw/3QwkT1rEAu5jNaABoDiw=
# SIG # End signature block
