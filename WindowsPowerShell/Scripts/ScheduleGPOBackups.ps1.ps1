Import-Module grouppolicy
#region ConfigBlock
# What domain are we going to backup GPOs for?
$domain = "mydomain.com"
# Where are we going to store the backups?
$gpoBackupRootDir = "c:\gpoBackups"
# As I plan to do a new backup set each month I'll setup the directory names to reflect
# the year and month in a nice sortable way.
# Set this up and format to your liking, I prefer $gpoBackupRootDir\yyyy-MM
$backupDir = "$gpoBackupRootDir\{0:yyyy-MM}" -f (Get-Date)

# Perform a full backup how often? Day/Week/Month/Year?
#$fullBackupFrequency = "Day"
#$fullBackupFrequency = "Week"
$fullBackupFrequency = "Month"
#$fullBackupFrequency = "Year"

# Perform Incremental backups how often?  Hour/Day/Week/Month?
$IncBackupFreqency = "Hour"
# $IncBackupFreqency = "Day"
# $IncBackupFreqency = "Week"
# $IncBackupFreqency = "Month"

# How many full sets to keep?
# Alternatively, how far back do we keep our backup sets?
$numKeepBackupSets = 12

# On what day do we want to consider the start of Week?
#$startOfWeek = "Sunday"
$startOfWeek = "Monday"
#$startOfWeek = "Tuesday"
#$startOfWeek = "Wednesday"
#$startOfWeek = "Thursday"
#$startOfWeek = "Friday"
#$startOfWeek = "Saturday"

# On what day do we want to consider the start of Month?
$startOfMonth = 1

# On what day do we want to consider the start of Year?
$startOfYear = 1

#endregion

$currentDateTime = Get-Date
$doFull = $false
$doInc = $false

# Does our backup directory exist?
# If not attempt to create it and fail the script with an approprate error
if (-not (Test-Path $backupDir))
{
	try 
	{
		New-Item -ItemType Directory -Path $backupDir
	}
	catch
	{
		Throw $("Could not create directory $backupDir")
	}
}

# If we're here then our backup directory is in good shape
# Check if we need to run a full backup or not
#  if we do, then run it
if ( Test-Path $backupDir\LastFullTimestamp.xml )
{
	# Import the timestamp from the last recorded complete full
	$lastFullTimestamp = Import-Clixml $backupDir\LastFullTimestamp.xml
	# check to see if the timestamp is valid, if not then delete it and run a full
	if ( $lastFullTimestamp -isnot [datetime] )
	{
		$doFull = $true
		Remove-Item $backupDir\LastFullTimestamp.xml
	}
	else # $lastfulltimestamp is or can be boxed/cast into [datetime]
	{
		# determine how long it has been since the last recorded full
		$fullDelta = $currentDateTime - $lastFullTimestamp
		switch ($fullBackupFrequency)
		{
			Day
			{
				if ( $fullDelta.days -gt 0 )
				{
					$doFull = $true
				}
			}
			Week
			{
				if ( ($currentDateTime.dayOfWeek -eq [DayOfWeek]$startOfWeek) `
					-or ($fullDelta.days -gt 7) )
				{
					$doFull = $true
				}
			}
			Month
			{
				if ( ($currentDateTime.day -eq $startOfMonth) `
					-or ($fullDelta.days -gt 30) )
				{
					$doFull = $true
				}
			}
			Year
			{
				if ( ($currentDateTime.dayofyear -eq $startOfYear) `
					-or ($fullDelta.days -gt 365) )
				{
					$doFull = $true
				}
			}
		}
	}
}
else # There is no recorded last completed full so we want to run one
{
	$doFull = $true
}

if ($doFull)
{
	# Run Backup of All GPOs in domain
	$GPOs = Get-GPO -domain $domain -All
	foreach ($GPO in $GPOs)
	{
		$GPOBackup = Backup-GPO $GPO.DisplayName -Path $backupDir
		# First build the Report path, then generate a report of the backed up settings.
		$ReportPath = $backupDir + "\" + $GPO.ModificationTime.Year + "-" + $GPO.ModificationTime.Month + "-" + $GPO.ModificationTime.Day + "_" + $GPO.Displayname + "_" + $GPOBackup.Id + ".html"
		Get-GPOReport -Name $GPO.DisplayName -path $ReportPath -ReportType HTML 
	}
	Export-Clixml -Path $backupDir\LastFullTimestamp.xml -InputObject ($currentDateTime)
}
else # If we're not running a full check if we need to run an incremental backup
{
	if ( Test-Path $backupDir\LastIncTimestamp.xml )
	{
		# Import the timestamp from the last recorded complete Incremental
		$lastIncTimestamp = Import-Clixml $backupDir\LastIncTimestamp.xml
		# check to see if the timestamp is valid, if not then delete it and run an inc
		if ( $lastIncTimestamp -isnot [datetime] )
		{
			# Import the timestamp from the last recorded complete full
			# If we're here then the timestamp is valid. It is checked earlier and if it fails
			# or doesn't exist then we run a full and will never get here.
			# determine how long it has been since the last recorded full
			$lastFullTimestamp = Import-Clixml $backupDir\LastFullTimestamp.xml
			$IncDelta = $currentDateTime - $lastFullTimestamp
			$doInc = $true
			Remove-Item $backupDir\LastIncTimestamp.xml
		}
		else # $lastIncTimestamp is or can be boxed/cast into [datetime]
		{
			# determine how long it has been since the last recorded full
			$IncDelta = $currentDateTime - $lastIncTimestamp
		}
	}
	else # There is no recorded last Incremental
	{
		# Import the timestamp from the last recorded complete full
		# If we're here then the timestamp is valid. It is checked earlier and if it fails
		# or doesn't exist then we run a full and will never get here.
		# determine how long it has been since the last recorded full
		$lastFullTimestamp = Import-Clixml $backupDir\LastFullTimestamp.xml
		$IncDelta = $currentDateTime - $lastFullTimestamp
	}
	# If we have already determined to run an Inc we want to skip this part
	if ($doInc -eq $false)
	{
		switch ($IncBackupFreqency)
		{
			Hour
			{
				if ($IncDelta.hours -gt 0)
				{
					$doInc = $true
				}
			}
			Day
			{
				if ($IncDelta.days -gt 0)
				{
					$doInc = $true
				}
			}
			Week
			{
				if ( ($currentDateTime.dayOfWeek -eq [DayOfWeek]$startOfWeek) `
					-or ($IncDelta.days -gt 7) )
				{
					$doInc = $true
				}
			}
			Month
			{
				if ( ($currentDateTime.day -eq $startOfMonth) `
					-or ($IncDelta.days -gt 30) )
				{
					$doInc = $true
				}
			}
		}
	}
	# Time to check our Incremental flag and run the backup if we need to
	if ($doInc)
	{
		# Run Incremental Backup
		$GPOs = Get-GPO -domain $domain -All | Where-Object { $_.modificationTime -gt ($currentDateTime - $incDelta) }
		foreach ($GPO in $GPOs)
		{
			$GPOBackup = Backup-GPO $GPO.DisplayName -Path $backupDir
			# First build the Report path, then generate a report of the backed up settings.
			$ReportPath = $backupDir + "\" + $GPO.ModificationTime.Year + "-" + $GPO.ModificationTime.Month + "-" + $GPO.ModificationTime.Day + "_" + $GPO.Displayname + ".html"
			Get-GPOReport -Name $GPO.DisplayName -path $ReportPath -ReportType HTML 
		}
		Export-Clixml -Path $backupDir\LastIncTimestamp.xml -InputObject ($currentDateTime)
	}
}
#TODO: Cleanup old backup sets
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKs5WK0ro2oUWZPupDlL6hvux
# peigggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFClGL8CWUdw7BV3p
# KMJxYwKHzT86MA0GCSqGSIb3DQEBAQUABIIBAFsieqMEwUqGVr9O3JuKUfhSnc0S
# IyI7+1UWffOVGSmFin3AEngQtQrtoO7OCxAQF2JKyt+8qCIX4Z5ZlitSHCYPzTnR
# A8fMWSljrGSjHHK66rtU0iD5X8aUDpc2CTuchtjk7o1n32Pg7TiYAX1rnOnPgOX7
# TH1CWAG2PRLpG/acbHTTTJGg/diqJFtKsYFhLH7W9CkHk4m5A9hrZkYcFuEfCMzX
# lDrFmMBWdkDBXDIki7z58m3gOvVLwoSzO9JPElLTWjskwQOZn/SxxUeFy+GJANdk
# xZ8jugJZ7hQatvp5u9+fqoSag5zIV7oJwF5cVry45mEEL45wymlN1AecIOM=
# SIG # End signature block
