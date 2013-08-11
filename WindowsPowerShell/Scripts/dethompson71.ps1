#------------------------------------------------------------------------------
#
# get the 'connect' entries from the logs of all the Exchange CAS servers
# only keep the last 30 days
#
# runs at 2AM
#------------------------------------------------------------------------------


Function Get-ClientVersionConnectLogs () {
	Param(
		$LogDate = $Null
	)

	If ($LogDate) {
		# this is the default location for these logs during install
		$Script:CAS | %{gc ( '\\' + $_.Name + '\c$\Program Files\Microsoft\Exchange Server\V14\Logging\RPC Client Access\RCA_'+$T + '-*.LOG') |?{$_-match"OUTLOOK.EXE"-and$_-match",Connect,"}}
	}
}


# Starting with today, work back checking to see that a file for
# that days exists, if it does not then create it
#
# the directory where you keep these "connect logs" - change to fit your needs
$Script:CasLogUNCDir ='\\<server>\<drv>\Data\CASConnectLogs'

# get all the CAS servers -- only get 2010 servers ( I have 2007 servers too)
$Script:CAS = Get-ExchangeServer | ?{ $_.IsClientAccessServer -eq $true -and $_.AdminDisplayVersion -match "^Version 14" }


# loop thru the last 14 days and collect the logs
1..14 | % {

	$T = Get-Date ((Get-Date).adddays(($_) * -1)) -Format 'yyyyMMdd'
	$Script:CASLogFile = $('OLConnect-' + $T + '.txt')

	$FileName = Join-Path -Path $Script:CasLogUNCDir -ChildPath $Script:CASLogFile

	if(-not (Test-Path $FileName)) {

		Write-output "Working: " $T

		Get-ClientVersionConnectLogs $T | Out-File $FileName

	}
}



# Now check to see if any files are old than 30 days and kill them

gci $Script:CasLogUNCDir | ? {$_.LastWritetime -lt ((get-date).adddays(-30))} | Remove-Item | Out-Null