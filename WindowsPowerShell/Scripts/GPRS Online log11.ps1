<#
.SYNOPSIS
Get-GprsTime (V3.0 Update for Windows 7)  Check the total connect time of any
GPRS devices from a specified date. 
Use Get-Help .\Get-GprsTime -full to view Help for this file.
.DESCRIPTION
Display all the GPRS modem Event Log entries. While applications issued by the 
mobile phone manufacturers will invariably monitor only their own usage, this
will show any logged GPRS activity, be it via PCMCIA, USB, mobile phone, etc.
Use the -Verbose switch for some extra information if desired. A default value
can be set with the -Monthly switch but can be temporarily overridden with any 
-Start value and deleted by entering an invalid date.  Now uses .NET Parse to 
use any culture date input. Switches -M and -S cannot be used together.
   A Balloon prompt will be issued in the Notification area for the 5 days 
before the nominal month end. 
NOTE:  this can effectively be suppressed by using a value higher than the SIM
card term, ie something like -Account 90 for a 30 day card which will override 
the default setting. Use -Today to check only today's usage.
Define a function in  $profile to set any permanent switches, for example to
set the account value permanently to 30 days.
function GPRS {
   Invoke-Expression "Get-GprsTime -Account 30 $args" 
}

.EXAMPLE
.\Get-GprsTime.ps1 -Monthly 4/8/2011

This will set the default search date to start from 4/8/2011 and is used to
reset the start date each month for the average 30/31 day SIM card.
.EXAMPLE
.\Get-GprsTime.ps1 -Start 12/07/2009 -Account 100 -Verbose

Search from 12/07/2011 and also show (Verbose) details for each session. The
Account switch will override any balloon prompt near the SIM expiry date.
.EXAMPLE
.\Get-GprsTime.ps1 5/9/2011 -v

Search one day only and show session details.
.EXAMPLE
.\Get-GprsTime.ps1 -Today

Show all sessions for today. This always defaults to verbose output.
.EXAMPLE
.\Get-GprsTime.ps1 -Debug

Shows the first available Event Log record and confirms switch settings.
.NOTES
A shorter total time than that actually used will result if the Event Log
does not contain earlier dates; just increase the log size in such a case.
The author can be contacted at www.SeaStarDevelopment.Bravehost.com and a
(binary compiled) Module version of this procedure is included in the file
Gprs3038.zip download there; the execution time of the module being about 
10 times faster than this script.
For the Event Log to record connect & disconnect events, the modem software
should be set to RAS rather than NDIS.
#>


Param ([String] $start,
	[String] $monthly,
	[Int] $account = 0, #Start warning prompt 5 days before month end.
	[Switch] $today,
	[Switch] $verbose,
	[Switch] $debug)

Trap [System.Management.Automation.MethodInvocationException] {
	[Int]$line = $error[0].InvocationInfo.ScriptLineNumber
	[System.Media.SystemSounds]::Hand.Play()
	if ($line -eq 196) {
		Write-Warning "[$name] Current GPRS variable has been deleted."
		$monthly = ""
		[Environment]::SetEnvironmentVariable("GPRS",$monthly,"User")
	}
	else {
		Write-Warning "[$name] Date is missing or invalid $SCRIPT:form"
	}
	exit 1
}
#Establish the Operating System...We only need to confirm XP or later.

function Get-OSVersion($computer,[ref]$osv) {
	$os = Get-WmiObject -class Win32_OperatingSystem -computerName $computer
	Switch ($os.Version) {
		"5.1.2600" { $osv.value = "xp" }
		default { "Version not listed" }
	} 
} 

$osv = $null
$version = Get-OSVersion "localhost" ([ref]$osv)
if ($osv -eq 'xp') {
	$logname = 'System'
	$connEvent = 20158
	$discEvent = 20159
	$source = 'RemoteAccess'
}
else { #Treat As Vista or Windows 7.
	$logname = 'Application'
	$connEvent = 20225
	$discEvent = 20226
	$source = 'RasClient'
}
$entryType = 'Information'
$logEntry = $null
$oldest = Get-eventlog -LogName $logname | #Get the earliest Log record.
Where-Object {$_.Source -eq $source} |
Where-Object {$_.EntryType -eq $entryType } |
Sort-Object TimeGenerated |
Select-Object -first 1
if ($oldest.TimeGenerated) { 
	$logEntry = "System Event records available from - $($oldest.TimeGenerated.ToLongDateString())"
}
$name = $myInvocation.MyCommand
$newLine = "[$name] The switches -Start and -Monthly can only be used separately."
if ($debug) {
	$DebugPreference = 'Continue'
}
if ($start -and $monthly) {
	[System.Media.SystemSounds]::Hand.Play()
	Write-Warning "$newLine"
	exit 1
}
$SCRIPT:form = ""

#In certain cases Culture & UICulture can be different and have been known to
# return conflicting results regarding '-is [DateTime]' queries, etc.
if ($Host.CurrentCulture -eq $Host.CurrentUICulture) {
	$SCRIPT:form = '-Use format mm/dd/year' 
	[Int]$culture = "{0:%d}" -f [DateTime] "6/5/2009" #Returns local day.
	If ($culture -eq 6) {
		$SCRIPT:form = '-Use format dd/mm/year'
	}
}
$ErrorActionPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$WarningPreference = 'Continue'
$conn = $disc = $default = $print = $null 
$timeNow = [DateTime]::Now 
$total = $timeNow - $timeNow #Set initial value to 00:00:00.
$insert = "since"
if ($verbose) {
	$VerbosePreference = 'Continue'
}

function CreditMsg ($value, $value2) {
	$value = [Math]::Abs($value)
	$prefix = "CURRENT"
	[DateTime] $creditDT = $value2 
	$creditDT = $creditDT.AddDays($value) #Add the -Account days.
	$thisDay = "{0:M/d/yyyy}" -f [DateTime]::Now #Force US format.
	#If we use '$number = $creditDT - (Get-Date)' instead of the line below we
	#can sometimes get a value of 1 returned instead 2, hence the  above  lines.
	$number = $creditDT - [DateTime] $thisDay
	[String] $credit = $creditDT 
	$credit = $credit.Replace('00:00:00','') #Remove any trailing time.
	$credit = "{0:d}" -f [DateTime]$credit
	Switch($number.Days) {
		1 {$prefix = "($value days) will expire tomorrow"; break}
		0 {$prefix = "($value days) will expire today"; break}
		-1 {$prefix = "($value days) expired yesterday"; break}
		{			(				$_ -lt 0)} {$prefix = "($value days) expired on $credit"; break}
		{			(				$_ -le 5)} {$prefix = "($value days) will expire on $credit"}
		Default {$prefix = "CURRENT"} #Only come here if over 5 days.
	}
	return $prefix
}

function Interval ([String] $value) {
	Switch -regex ($value) {
		'^00:00:\d+(.*)$' {$suffix = "seconds"; break}
		'^00:\d+:\d+(.*)$' {$suffix = "minutes"; break}
		'^\d+:\d+:\d+(.*)$' {$suffix = "  hours"; break}
		'^(\d+)\D(\d+)(.*)$' {$suffix = "  hours"
			$pDays = $matches[1]
			$pHours = $matches[2]
			[string]$pMinSec = $matches[3]
			[string]$tHours = (([int]$pDays) * 24)+[int]$pHours
			$value = $tHours + $pminSec; break}
		default {$suffix = "  hours"} #Should never come here!
	}
	return "$value $suffix"
}

function CheckSetting ($value) {
	if ($value) { #Correct for local culture.
		$print = $default.ToShortDateString() 
	}
	else {
		$print = "(Value not set)"
	}
	return $print
}
#The Script effectively starts here.............................................
$getGprs = [Environment]::GetEnvironmentVariable("GPRS","User")
#First check for GPRS variable and change from US date format to current locale.
if ([DateTime]::TryParse($getGprs, [Ref]$timeNow)) { #No error as date is valid.
	$default = "{0:d}" -f [datetime]$getGprs 
	$default = [DateTime]::Parse($default) 
	$checkParts = "{0:yyyy},{0:%M}" -f $default
	$times = $checkParts.Split(',')
	$dayCount = [DateTime]::DaysInMonth($times[0],$times[1]) #Range 28-31.
	if($account -eq 0) {
		$account = $dayCount
		$summary = "$($dayCount.ToString()) days" 
	}
	else {
		$summary = "$($account.Tostring()) days"
	}
	$text = CreditMsg $account $getGprs #Check if within 5 days of expiry date.
	if ($text -ne "CURRENT") {
		[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
		$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 
		$objNotifyIcon.Icon = [System.Drawing.SystemIcons]::Exclamation 
		$objNotifyIcon.BalloonTipIcon = "Info" 
		$objNotifyIcon.BalloonTipTitle = "GPRS online account"
		$objNotifyIcon.BalloonTipText = "Credit $text"
		$objNotifyIcon.Visible = $True 
		$objNotifyIcon.ShowBalloonTip(10000)
	}
}
else {
	$summary = "(Days not set)"
	if ((!$today) -and (!$monthly) -and (!$start)) {
		[System.Media.SystemSounds]::Hand.Play()
		Write-Warning("Monthly date is either invalid or not set.")
		exit 1
	}
}
if ($start) {
	$start = [DateTime]::Parse($start) #Trigger TRAP if invalid!
	[DateTime]$limit = $start
	$convert = "{0:D}" -f $limit
	$print = CheckSetting $default
} 

if ($monthly) {
	$start = [DateTime]::Parse($monthly) #Trigger TRAP if invalid!
	Write-Output "Setting GPRS (monthly) environment variable to: $monthly"
	$gprs = [String]$start.Replace('00:00:00','')
	[Environment]::SetEnvironmentVariable("GPRS",$gprs,"User")
	[DateTime] $limit = $start #Change to required US date format.
	$convert = "{0:D}" -f $limit
	$print = $limit.ToShortDateString()
	$summary = "(Days undetermined)" #Will show next time around.
}

if ($today) { 
	$verBosePreference = 'Continue' #Show VERBOSE by default.
	[DateTime] $limit = (Get-Date)
	$convert = "{0:D}" -f $limit
	$limit = $limit.Date #Override any start date if using -Today input.
	$insert = "for today"
	$print = CheckSetting $default
}
if ((!$today) -and (!$monthly) -and (!$start)) { 
	if ($default) {
		$monthly = $default
		[DateTime] $limit = $monthly
		$convert = "{0:D}" -f $limit
		$print = CheckSetting $default
	}
}
Write-Verbose "All records $($insert.Replace('for ','')) - $convert"
Write-Verbose "Script activation - User [$($env:UserName)] Computer [$($env:ComputerName)]"
Write-Output ""
Write-Output "Calculating total connect time of all GPRS modem devices..."
#We cannot proceed beyond here without a valid $limit value.
Write-Debug "Using - [Search date] $($limit.ToShortDateString()) [Account] $summary [GPRS Monthly] $print"
if ($logEntry) { 
	Write-Debug "$logEntry"
}

$lines = Get-EventLog $logname | Where-Object {($_.TimeGenerated -ge $limit) -and `
	(		$_.EventID -eq $discEvent -or $_.EventID -eq $connEvent)} 
if ($lines) {
	Write-Verbose "A total of $([Math]::Truncate($lines.Count/2)) online sessions extracted from the System Event Log."
}
else {
	Write-Output "(There are no events indicated in the System Event Log)"
}
$lines | ForEach-Object {
	$source = $_.Source
	if ($_.EventID -eq $discEvent) { #Event 20159 is Disconnect.
		$disc = $_.TimeGenerated
	} 
	else { #Event 20158 is Connect.
		$conn = $_.TimeGenerated 
	} #We are only interested in matching pairs of DISC/CONN...
	if ($disc -ne $null -and $conn -ne $null -and $disc -gt $conn) {
		$diff = $disc - $conn
		$total += $diff
		$convDisc = "{0:G}" -f $disc
		$convConn = "{0:G}" -f $conn
		$period = Interval $diff
		Write-Verbose "Disconnect at $convDisc. Online - $period"
		Write-Verbose "   Connect at $convConn."
	}
} #End ForEach
if (!$source) {
	$source = '(Undetermined)'
}
Write-Verbose "Using local event source - System Event Log [$source]"
$period = Interval $total
Write-Output "Total online usage $insert $convert is $($period.Replace('   ',' '))."
Write-Output ""
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCWEBL5RKp2W3hKt6SKlBEqb7
# c1OgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEFKkNCtkrINWEws
# MISU+PiaCc0eMA0GCSqGSIb3DQEBAQUABIIBAHAeWgdppgIDt09gHYvmD/nS+hsK
# GA3RNk39sUh4RSSYYISI8mj6NF57ieOCEM14aleKLaF4K1VaVrcozVdU0SblmHQY
# PE4LKc9tzbIlRHQxgskqs3T/pbLElhBk0FIp8bvPSXXrrwW5/JK66q6T3ET8ZR8J
# 9DlccTP1Pgf/eKVUoy43i9f3xLnljZWq/s/GeaEOPCLPqL69DFh6D5IUO97SGbBV
# CBLJs64nP8MBD513Y8nKi4W+5gmGatBnLjebh4sGHJalsfkR+8Yj3kCONlJ43xeM
# EsVpntuYXshmXpMeIVsT4uzXyAlHeURL0uO74g2dsu95cavTvWCtLgBea6w=
# SIG # End signature block
