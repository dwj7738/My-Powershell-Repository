######################################## DISCLAIMER ###################################
# The free software programs provided by Shaiju J.S may be freely distributed,     #### 
# provided that no charge above the cost of distribution is levied, and that the ######
# disclaimer below is always attached to it.                                     ######
# The programs are provided as is without any guarantees or warranty.            ###### 
# Although the author has attempted to find and correct any bugs in the free software #
# programs, the author is not responsible for any damage or losses of any kind caused #
# by the use or misuse of the programs. The author is under no obligation to provide ##
# support, service, corrections, or upgrades to the free software programs. ########### 
#######################################################################################


write-host "###########################################################################" -ForegroundColor DarkCyan
write-host "################# EVENT LOG GRABBER USING POWERSHELL ######################" -ForegroundColor Yellow
write-host "##################### USE ADMIN ACCOUNT TO START ##########################" -ForegroundColor Green
write-host "###########################################################################" -ForegroundColor Yellow
write-host "## EL Grabber Version 1 #### By Shaiju J.S ########## 18 Jan 2012 #########" -ForegroundColor Green
write-host "###########################################################################" -ForegroundColor DarkCyan

Write-Host "WELCOME TO EVENT LOG GRABBER !!!" -ForegroundColor Yellow
$opt3 = Read-Host "Would you like to export the details to csv file (Y/N)?"
$server14 = Read-Host "Enter the server name"
[int]$n = Read-Host "Last how many hours events need to be grabbed?"
$event = Read-host "Application / Security / System / Others (Specify the name)?"
$start1 = (Get-Date).addHours(-[int]$n) 
$start2 = (Get-Date)
$strdat = (get-date).ToString()
if ($opt3 -eq 'Y') {
	If ($event -eq 'Security') {
		$entry2 = Read-Host "FailureAudit / SuccessAudit ?"
		$location1 = Read-Host "Enter a drive location for the report"
		get-eventlog -logname $event -EntryType $entry2 -after $start1 -before $start2 -ComputerName $server14 | Export-csv -Force -Path "$location1\$(Get-Date -Format 'dd_MM_yyyy')-$Event Log-$entry2-$server14.csv"
		Invoke-Item "$location1\$(Get-Date -Format 'dd_MM_yyyy')-$Event Log-$entry2-$server14.csv"
	}
	else {
		$entry0 = Read-Host "Information / Warning / Error ?"
		$location2 = Read-Host "Enter a drive location for the report"
		get-eventlog -logname $event -EntryType $entry0 -after $start1 -before $start2 -ComputerName $server14 | Export-csv -Force -Path "$location2\$(Get-Date -Format 'dd_MM_yyyy')-$Event Log-$entry0-$server14.csv"
		Invoke-Item "$location2\$(Get-Date -Format 'dd_MM_yyyy')-$Event Log-$entry0-$server14.csv"
	}
}
else {
	If ($event -eq 'Security') {
		$entry3 = Read-Host "FailureAudit / SuccessAudit ?"
		get-eventlog -logname $event -EntryType $entry3 -after $start1 -before $start2 -ComputerName $server14 | Out-GridView
	}
	else {
		$entry1 = Read-Host "Information / Warning / Error ?"
		get-eventlog -logname $event -EntryType $entry1 -after $start1 -before $start2 -ComputerName $server14 | Out-GridView
	}
}
Exit