################################################################################
# Get-GprsTime.ps1
#       Check the total connect time of any GPRS devices from a specified date. 
# Use the -Detail switch for some extra information if desired.  A default value
# can be set with the -Monthly switch but can be temporarily overridden with any
# -Start value. All dates to be entered in European (dd/mm/yyyy) format.
#       A balloon prompt will be issued in the Notification area for the 5 days
# before the nominal month end, and a suitable Icon (exclamation.ico) file needs 
# to be available in the $PWD directory for this to work.
# NOTE:  this can effectively be suppressed by using a value higher than the SIM
# card term, ie something like -Expire 100 for a 30 day card which will override 
# the default setting. Use -Today to check only today's usage.
# Examples:
#    .\Get-GprsTime.ps1 -Monthly 1/10/2009
#    .\Get-GprsTime.ps1 -Start 03/10/2009 -Expire 100 -Detail
#    .\Get-GprsTime.ps1 -m 2/9/2009
#    .\Get-GprsTime.ps1 -s 3/10/2009 -d
#    .\Get-GprsTime.ps1 -d
#    .\Get-GprsTime.ps1 -Today
#    .\Get-GprsTime.ps1
#
# The author can be contacted at www.SeaStarDevelopment.Bravehost.com 
################################################################################
param ([String] $start,
	[String] $monthly,
	[Int] $expires = 30, #Start warning prompt 5 days before month end.
	[Switch] $today,
	[Switch] $detail)
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'
$conn = $disc = $null #Initialise to satisfy Set-PsDebug (-Strict).
$timeNow = [DateTime]::Now 
$total = $timeNow - $timeNow #Set initial value to 00:00:00
$insert = "since"
If ($detail) {
	$VerbosePreference = 'Continue'
}

Function CreditMsg ($value) {
	$prefix = "CURRENT"
	$creditDate = [Environment]::GetEnvironmentVariable("DTAC","User")
	If ($creditDate) { #Do nothing if no monthly date set.
		#Now swap the date to US format so system can add to it correctly.
		[DateTime] $creditDT = SwapDayMonth $creditDate "SILENTLY"
		$creditDT = $creditDT.AddDays($value) #Add the -Expires days.
		$number = $creditDT - (Get-Date) #Calculate difference from today.
		Switch($number.Days) {
			{				(					$_ -le 5)} {$prefix = "will expire on $creditDate "}
			0 {$prefix = "will expire today"}
			{				(					$_ -lt 0)} {$prefix = "expired on $creditDate"}
			Default {$prefix = "CURRENT"} #Only come here if over 5 days.
		}
	}
	Return $prefix
}
#Check valid dates; but 31/2/2009 or 31/11/2009 will still slip through.
Function Validate ([String] $value) {
	If ($value -match '^([0]?[1-9]|1[0-9]|2[0-9]|3[01])/([0]?[1-9]|1[0-2])/(2009|2010)$') {
		Return "OK"
	}
}
#Match the input: (day)/(month)/(year); then convert to: (month)/(day)/(year).
Function SwapDayMonth ([String] $value,[String] $value2) {
	If ($value -match '^(\d+)/(\d+)/(.*)$') {
		If ($value2 -ne "SILENTLY") {
			Write-Verbose "Using parameters  - Day [$($matches[1])] Month [$($matches[2])] Year [$($matches[3])]"
		}
		Return $value -replace '^(\d+)/(\d+)/(.*)','$2/$1/$3' 
	} 
}
Function Interval ([String] $value) {
	Switch($value) {
		{			$_ -match '^00:00:\d+(.*)' } {$suffix = "seconds"; break}
		{			$_ -match '^00:\d+:\d+(.*)'} {$suffix = "minutes"; break}
		Default {$suffix = "  hours"}
	}
	Return $suffix
}

#Script entry point starts here...

If ($monthly) {
	If ((validate $monthly) -eq "OK") {
		Write-Output "Setting GPRS (monthly) environment variable: $monthly"
		[Environment]::SetEnvironmentVariable("DTAC",$monthly,"User")
		$start = $monthly
	}
	Else {
		Write-Error "Invalid monthly date input: - resubmit"
		Return
	}
} 
Else { #If no -Monthly entered and no -Start, use the DTAC environment variable.
	If (!$start) {
		$start = [Environment]::GetEnvironmentVariable("DTAC","User")
	}
}
#We must have a valid $start value before reaching here.
If ((Validate $start) -eq "OK") { #Catch dates like 29/2/xxxx or 31/9/xxxx. 
	[DateTime] $limit = SwapDayMonth $start #Change to required US date format.
	$convert = "{0:D}" -f $limit
} 
Else { 
	Write-Error "Invalid or missing date input: - resubmit"
	Exit 4
}
If ($today) {
	$verbosePreference = 'Continue' #Show VERBOSE by default.
	[DateTime] $limit = (Get-Date)
	$convert = "{0:D}" -f $limit
	$limit = $limit.Date #Override any start date if using -Today input.
	$insert = "for today"
}

Write-Verbose "All records $($insert.Replace('for ','')) - $convert"
Write-Verbose "Script activation - User [$($env:UserName)] Computer [$($env:ComputerName)]"

$text = CreditMsg $expires #Check if we are within 5 days of expiry date.
If (($text -ne "CURRENT") -and (Test-Path "$pwd\exclamation.ico")) {
	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 
	$objNotifyIcon.Icon = "$pwd\exclamation.ico" 
	$objNotifyIcon.BalloonTipIcon = "Info" 
	$objNotifyIcon.BalloonTipTitle = "GPRS online account"
	$objNotifyIcon.BalloonTipText = "Credit $text"
	$objNotifyIcon.Visible = $True 
	$objNotifyIcon.ShowBalloonTip(10000)
}
Write-Output ""
Write-Output "Calculating total connect time of all GPRS modem devices..."

$lines = Get-EventLog system | Where-Object {($_.TimeGenerated -ge $limit) -and `
	(		$_.EventID -eq 20159 -or $_.EventID -eq 20158)} 
If ($lines) {
	Write-Verbose "A total of $([Math]::Truncate($lines.Count/2)) online sessions extracted from the System Event Log."
}
Else {
	Write-Output "(There are no events indicated in the System Event Log)"
}
$lines | ForEach-Object {
	$source = $_.Source
	If ($_.EventID -eq 20159) { #Event 20159 is Disconnect.
		$disc = $_.TimeGenerated
	} 
	Else { #Event 20158 is Connect.
		$conn = $_.TimeGenerated 
	} #We are only interested in matching pairs of DISC/CONN...
	If ($disc -ne $null -and $conn -ne $null -and $disc -gt $conn) {
		$diff = $disc - $conn
		$total += $diff
		$convDisc = SwapDayMonth $disc "SILENTLY" #Set European date format.
		$convConn = SwapDayMonth $conn "SILENTLY"
		$period = Interval $diff
		Write-Verbose "Disconnect at $convDisc. Online - $diff $period"
		Write-Verbose "   Connect at $convConn"
	}
} #End ForEach
If (!$source) {
	$source = '(Undetermined)'
}
Write-Verbose "Using local event source - System Event Log [$source]"
$period = Interval $total
Write-Output "Total online usage $insert $convert is $total $($period.Trim())."
Write-Output ""
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUY1ANEpHVytdUj0vaE5Dxrm0L
# 6gKgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCJ6w4QS0HQ6xWWi
# KQoL3hKsor7hMA0GCSqGSIb3DQEBAQUABIIBACutKJHzqAZiwkMcfwyyOq4bIy7L
# x6MyIY2aDTd/OI0ZR/CDXwjbI/sDim4V1JrswYpIJPX98FERjHspyhEqQ4XY0Haf
# jDHOx08gcKyweOJdoXTFqg1fNFExSz0JhoarwZe+IlR7225Va2zJQLP4bJRm1+KM
# wZieZ9U782eySPWwbpxZr/+Rezbji14VqrvBdIdazoE4Kbly5v+1spNYJGCON7+Y
# r4vlPS7VSQPjTUkiLqgBhyd8MRin+6Iy1qiJeDNlgXSfDdGR9JdGudSzgKRxXq2/
# jj1dmjTVJ0TGAEksZCnMpPlsWSMs1FlutxDoZJ2Sim6NPvbjVVKz0fK5Ytc=
# SIG # End signature block
