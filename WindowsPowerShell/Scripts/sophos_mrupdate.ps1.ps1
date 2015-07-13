<#
.SYNOPSIS
   Updates the Sophos Message Relay configuration.
.DESCRIPTION
   Points the local Message Router service to a new parent relay server.
.PARAMETER mrinit
   The mrinit.conf file to use.
.PARAMETER loglevel
   The current loglevel (used by the Log function).  
   Defaults to 'information' (debug messages will not be printed).
   Valid values are 'debug', 'information', 'warning', and 'error'.
.EXAMPLE
   # Update settings using the configuration in the file AMW_mrinit.conf
   sophos_mrupdate.ps1 -mrinit AMW_mrinit.conf
#>
param([Parameter(Mandatory=$true)][string]$mrinit,
	[Parameter(Mandatory=$false)][string]$loglevel = 1)

# LOGGING #####################################################################

# Set severity constants
$MSG_DEBUG = 0
$MSG_INFORMATION = 1
$MSG_WARNING = 2
$MSG_ERROR = 3
$MSG_SEVERITY = @('debug', 'information', 'warning', 'error')

if ($MSG_SEVERITY -notcontains $loglevel.ToLower()) {
	Write-Error ('Invalid loglevel!  ' +
		'Must be debug, information, warning, or error.')
	exit 1
} else {
	foreach ($index in (0..($MSG_SEVERITY.Count - 1))) {
		if ($MSG_SEVERITY[$index] -eq $loglevel) {
			$loglevel = $index
		}
	}
}

# Set configurable settings for logging
$LOG_FILE = 'c:\windows\temp\sophos_mrupdate.log'
$SMTP_TO = 'sophos-virusalerts@company.com'
$SMTP_SERVER = 'smtp.company.com'
$SMTP_SUBJECT = 'Sophos MRUpdate Error'
$SMTP_FROM = 'sophos-mrupdate@company.com'


function Log {
	<#
.SYNOPSIS
   Writes a message to the Log.
.DESCRIPTION
  Logs a message to the logfile if the severity is higher than $loglevel.
.PARAMETER severity
   The severity of the message.  Can be Information, Warning, or Error.
   Use the $MSG_XXXX constants.
   Note that Error will halt the script and send an email.
.PARAMETER message
   A string to be printed to the log.
.EXAMPLE
   Log $MSG_ERROR "Something has gone terribly wrong!"
#>
	param([Parameter(Mandatory=$true)][int]$severity,
		[Parameter(Mandatory=$true)][string]$message,
		[Parameter()][switch]$sendmail)

	if ($severity -ge $loglevel) {
		$timestamp = Get-Date -Format 'yyyy-MM-dd hh:mm:ss'
		$output = ("$timestamp`t$($env:computername)`t" +
			"$($MSG_SEVERITY[$severity])`t$message")
		Write-Output $output >> $LOG_FILE


		if (($severity -ge $MSG_ERROR) -or $sendmail) {
			Send-MailMessage -To $SMTP_TO `
			-SmtpServer $SMTP_SERVER `
			-Subject "$SMTP_SUBJECT on $($env:computername)" `
			-Body $output `
			-From $SMTP_FROM
			exit 1
		}
	}
}


# MAIN ########################################################################

# The path to the Remote Management System files
$CURRENT_PATH = $pwd
$RMS_PATH = 'C:\Program Files (x86)\Sophos\Remote Management System\'

if (-not (Test-Path $RMS_PATH)) {
	$RMS_PATH = 'C:\Program Files\Sophos\Remote Management System\'

	if (-not (Test-Path $RMS_PATH)) {
		Log $MSG_ERROR "The path '$RMS_PATH' could not be found!"
	}
}

#Copy over the new mrinit.conf file
Log $MSG_DEBUG "Copying file '$mrinit'..."

if (Test-Path ".\$mrinit") {
	try {
		Copy-Item -Path ".\$mrinit" -Destination ($RMS_PATH + 'mrinit.conf') -Force
	} catch {
		LOG $MSG_ERROR "Unable to copy $mrinit to the RMS directory!" 
	}
} else {
	LOG $MSG_ERROR "File '$mrinit' missing!  Check the SCCM package."
	exit 1
}

Log $MSG_DEBUG "Changing directory to $RMS_PATH..."
cd $RMS_PATH

# Get the backup copies of mrinit.conf out of the way.  For some reason
# RMS will inexplicably use the backup copy instead of the new one if you don't
Log $MSG_DEBUG 'Renaming mrinit.conf.orig to mrinit.conf.orig.old'

try {
	Rename-Item '.\mrinit.conf.orig' '.\mrinit.conf.orig.old' `
	-Force `
	-ea SilentlyContinue
} catch {
	Log $MSG_ERROR "Unable to rename the file 'mrinit.orig'!"
}

# This is the command that actually grabs the new mrinit.conf file and makes
# the important updates to the system.
.\ClientMRInit.exe

# Let's restart the Message Router
net stop "Sophos Message Router"
net start "Sophos Message Router"

cd $CURRENT_PATH
# Voila!  We're done.
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZIIuIe85Pe4UdUfNX3jR5Kli
# s9ygggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFqUUsj75bDHNE6U
# 9UKeEGowS29TMA0GCSqGSIb3DQEBAQUABIIBAElw5HSWExr5FKM/R5x+5ZSVB6yD
# rHOoBueE5XFrZoTjdlL2+pUS+5UixXrzgr/cqQxfwET6taITVHhtQ4t313ZUoapj
# qvRkFza9sVsVcjeC4Zf+BsKeLenTBeKjhSuPO4WhToBrQ0Sf2GQ6IWOq9OSh1rMm
# V0Hez6H5QE0tl7BGPrVASWjvkaz3KNaXnuVi8jqqGALA1qFSmbd2yAoStTKGHCqY
# IPhi4mSnLDrOdoJ1rwV6je8aNrDh6jDsF7e/y644IqT6bLmpuefglaBLDLddaAiV
# Ckbm7c/w5pJZQbQ3hTGayIV+0kcg/52O4b5hoyWI3yMP0DVxgu8TMfdfxT8=
# SIG # End signature block
