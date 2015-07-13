## =====================================================================
## Title       : Backup-SSAS
## Description : Backup all Analysis Server databases
## Author      : Idera
## Date        : 6/27/2008
## Input       : -serverInstance <server\inst>
##               -backupDestination <drive:\x\y | \\unc\path>
##               -retentionDays <n>
##               -logDir <drive:\x\y | \\unc\path>
##               -verbose 
##               -debug	
## Output      : write backup files (*.abf)
## 				  create log file of activity
## Usage			: PS> .\Backup-SSAS -ServerInstance MyServer -BackupDestination C:\SSASbackup 
##                                 -RetentionDays 2 -LogDir C:\SSASLog -verbose -debug
## Notes			: Original script attributed to Ron Klimaszewski
## Tag			: Microsoft Analysis Server, SSAS, backup
## Change Log  :
## =====================================================================
 
param 
( 
	[string]$ServerInstance = "(local)", 
	[string]$BackupDestination, 
	[int]$RententionDays = 2, 
	[string]$LogDir, 
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Backup-SSAS $serverInstance $backupDestination $retentionDays $logDir
}

function Backup-SSAS($serverInstance, $backupDestination, $retentionDays, $logDir)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}
	
	# Force a minimum of two days of retention 
	# TIP: using PS "less than" operator
	if ($RetentionDays -lt 2 ) 
	{
		$RetentionDays = 2 
	} 
	
	# Load Microsoft Analysis Services assembly, output error messages to null
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices") | Out-Null
	
	# Declare SSAS objects with strongly typed variables
	[Microsoft.AnalysisServices.Server]$SSASserver = New-Object ([Microsoft.AnalysisServices.Server]) 
	[Microsoft.AnalysisServices.BackupInfo]$serverBackup = New-Object ([Microsoft.AnalysisServices.BackupInfo]) 
	
	# Connect to Analysis Server with specified instance
	$SSASserver.Connect($ServerInstance) 
	
	# Set Backup destination to Analysis Server default if not supplied
	# TIP: using PowerShell "equal" operator
	if ($backupDestination -eq "") 
	{
		Write-Debug "Setting the Destination parameter to the BackupDir parameter" 
		$BackupDestination = $SSASserver.ServerProperties.Item("BackupDir").Value 
	} 
	
	# Test for existence of Backup Destination path
	# TIP: using PowerShell ! operator is equivalent to "-not" operator, see below
	if (!(test-path $backupDestination)) 
	{
		Write-Host Destination path `"$backupDestination`" does not exists.  Exiting script. 
		exit 1 
	} 
	else 
	{
		Write-Host Backup files will be written to `"$backupDestination`" 
	} 
	
	# Set Log directory to Analysis Server default if not applied
	if ($logDir -eq "") 
	{
		Write-Debug "Setting the Log directory parameter to the LogDir parameter" 
		$logDir = $SSASserver.ServerProperties.Item("LogDir").Value 
	} 
	
	# Test for existence of Log directory path
	if (!(test-path $logDir)) 
	{
		Write-Host Log directory `"$logDir`" does not exists.  Exiting script. 
		exit 1 
	} 
	else 
	{
		Write-host Logs will be written to $logDir 
	} 
	
	# Test if Log directory and Backup destination paths end on "\" and add if missing
	# TIP: using PowerShell "+=" operator to do a quick string append operation
	if (-not $logDir.EndsWith("\")) 
	{
		$logDir += "\"
	} 
	
	if (-not $backupDestination.EndsWith("\")) 
	{
		$backupDestination += "\"
	} 
	
	# Create Log file name using Server instance
	[string]$logFile = $logDir + "SSASBackup." + $serverInstance.Replace("\","_") + ".log" 
	Write-Debug "Log file name is $logFile"
	
	Write-Debug "Creating database object and set options..."
	$dbs = $SSASserver.Databases 
	$serverBackup.AllowOverwrite = 1 
	$serverBackup.ApplyCompression = 1 
	$serverBackup.BackupRemotePartitions = 1 
	
	# Create backup timestamp
	# TIP: using PowerShell Get-Date to format a datetime string
	[string]$backupTS = Get-Date -Format "yyyy-MM-ddTHHmm" 
	
	# Add message to backup Log file
	# TIP: using PowerShell to output strings to a file
	Write-Debug "Backing up files on $serverInstance at $backupTS"
	"Backing up files on $ServerInstance at $backupTS" | Out-File -filepath $LogFile -encoding oem -append 
	
	# Back up the SSAS databases
	# TIP: using PowerShell foreach loop to enumerate a parent-child object
	foreach ($db in $dbs) 
	{
		$serverBackup.file = $backupDestination + $db.name + "." + $backupTS + ".abf" 
	
		# TIP: using mixed string literals and variable in a Write-Host command
		Write-Host Backing up $db.Name to $serverBackup.File 
		$db.Backup($serverBackup) 
		
		if ($?) {"Successfully backed up " + $db.Name + " to " + $serverBackup.File | Out-File -filepath $logFile -encoding oem -append} 
		else {"Failed to back up " + $db.Name + " to " + $serverBackup.File | Out-File -filepath $logFile -encoding oem -append} 
	} 
	
	# Disconnect from Analysis Server
	$SSASserver.Disconnect() 
	
	# Clear out the old files and files backed up to the Log file
	Write-Host Clearing out old files from $BackupDestination 
	[int]$retentionHours = $retentionDays * 24 * - 1 
	"Deleting old backup files" | Out-File -filepath $logFile -encoding oem -append 
	
	# TIP: using PowerShell get-childitem (get child items for matching location) and pipe to
	#        where-object (selecting certain ones based on a condition) 
	get-childitem ($backupDestination + "*.abf") | where-object {$_.LastWriteTime -le [System.DateTime]::Now.AddHours($RetentionHours)} | Out-File -filepath $logFile -encoding oem -append 
	get-childitem ($backupDestination + "*.abf") | where-object {$_.LastWriteTime -le [System.DateTime]::Now.AddHours($RetentionHours)} | remove-item 
}

main



# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0a7wJqhtJteHzzcwXufpF9Cc
# UYegggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCRRN+lf0I7FYdkG
# AAzUerObEQ8lMA0GCSqGSIb3DQEBAQUABIIBALMmzf9U6dUNbS9UptEuL2oVjR24
# 2+UGjKkz7hLwC+96F+gwVjGZDITqyDf/tbguap3I8yczY5Y150lS0S6egw3ABQN2
# WqyCHEbsmhmv5DkPzHfJlFU7aipdX9E2hD0PYEkJP0HER7mUrkSVrfvPxtbTjP9/
# 1Tczrc0hPzS/l5dVP6Qis1a76SjXfPXxMXDrm7di2lUH1rHsxC/UOrETPFLdiqS3
# ae6TVljNl6teK1PZpUe5cHZfQONKKDKNgxoDD6FSk5KHhGV4vB1+y5lsXyIeOem3
# AEx3n1O49Wa7WM60H535qcSpARU+UsY4OK/ZTgBcJFs3EfO8tumwWgqvMy8=
# SIG # End signature block
