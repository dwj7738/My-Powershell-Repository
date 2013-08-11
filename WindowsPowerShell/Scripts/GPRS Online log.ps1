################################################################################
# Get-GprsTime.ps1 (V.1005) - Reject any invalid date & allow years after 2009.
#
#       Check the total connect time of any GPRS devices from a specified date. 
# Use the -Detail switch for some extra information if desired.  A default value
# can be set with the -Monthly switch but can be temporarily overridden with any
# -Start value and deleted by entering an invalid date.  All dates to be entered
# in European (dd/mm/yyyy) format.
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
# The author can be contacted at www.SeaStarDevelopment.Bravehost.com and the
# 'exclamation.ico' file is included there in the Gprs100x.zip download.
################################################################################
param ([String] $start,
	[String] $monthly,
	[Int] $expires = 30, #Start warning prompt 5 days before month end.
	[Switch] $today,
	[Switch] $detail)
$name = $myInvocation.MyCommand
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'SilentlyContinue'
$WarningPreference = 'Continue'
$conn = $disc = $null #Initialise to satisfy Set-PsDebug (-Strict).
$timeNow = [DateTime]::Now 
$total = $timeNow - $timeNow #Set initial value to 00:00:00
$insert = "since"
If ($detail) {
	$VerbosePreference = 'Continue'
}

Function CreditMsg ($value) {
	$value = [Math]::Abs($value)
	$prefix = "CURRENT"
	$creditDate = [Environment]::GetEnvironmentVariable("DTAC","User")
	If ($creditDate) { #Do nothing if no monthly date set.
		#Now swap the date to US format so system can add to it correctly.
		[DateTime] $creditDT = SwapDayMonth $creditDate "SILENTLY"
		$creditDT = $creditDT.AddDays($value) #Add the -Expires days.
		$thisDay = "{0:M/d/yyyy}" -f [DateTime]::Now #Force US format.
		#If we use '$number = $creditDT - (Get-Date)' instead of the line below 
		#we can sometimes get a value of 1 returned instead 2, hence the  above.
		$number = $creditDT - [DateTime] $thisDay
		[String] $credit = $creditDT #Convert to string and revert to EU form.
		$credit = SwapDayMonth $credit "SILENTLY"
		$credit = $credit.Replace('00:00:00','') #Remove any trailing time.
		Switch($number.Days) {
			1 {$prefix = "($value days) will expire tomorrow"; break}
			0 {$prefix = "($value days) will expire today"; break}
			-1 {$prefix = "($value days) expired yesterday"; break}
			{				(					$_ -lt 0)} {$prefix = "($value days) expired on $credit"; break}
			{				(					$_ -le 5)} {$prefix = "($value days) will expire on $credit"}
			Default {$prefix = "CURRENT"} #Only come here if over 5 days.
		}
	}
	Return $prefix
}

Function Validate ([String] $value) {
	If ($value -match '^([0]?[1-9]|1[0-9]|2[0-9]|3[01])/([0]?[1-9]|1[0-2])/(20[01]\d)$') {
		$illegals = '30/02','30/2','31/2','31/02','31/9','31/09','31/4','31/04','31/6','31/06','31/11'
		$shortDate = $matches[1] + '/' + $matches[2]
		$year = $matches[3]
		If (![DateTime]::IsLeapYear($year)) { 
			$illegals += '29/02','29/2' #These 2 are illegal if not leap year.
		}
		If ($illegals -contains $shortDate) {
			Return 
		}
		Else {
			Return "OK" #All tests passed, so we have a valid date.
		}
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

#Script effectively starts here...

If ($monthly) {
	If ((validate $monthly) -eq "OK") {
		Write-Output "Setting GPRS (monthly) environment variable: $monthly"
		[Environment]::SetEnvironmentVariable("DTAC",$monthly,"User")
		$start = $monthly
	}
	Else {
		[System.Media.SystemSounds]::Hand.Play()
		Write-Warning "[$name] Date $monthly is invalid -resubmit."
		$monthly = ""
		[Environment]::SetEnvironmentVariable("DTAC",$monthly,"User")
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
	[System.Media.SystemSounds]::Hand.Play() 
	Write-Warning "[$name] Date $start is invalid -resubmit."
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