<#   
.SYNOPSIS   
	Script that return informations about scheduled tasks on a computer
    
.DESCRIPTION 
	This script uses the Schedule.Service COM-object to query the local or a remote computer in order to gather	a
	formatted list including the Author, UserId and description of the task. This information is parsed from the
	XML attributed to provide a more human readable format
 
.PARAMETER Computername
    The computer that will be queried by this script

.NOTES   
    Name: Get-ScheduledTasks.ps1
    Author: Jaap Brasser
    DateCreated: 2012-01-10
    Site: http://www.jaapbrasser.com
    Version: 1.1

.LINK
	http://www.jaapbrasser.com
	
.EXAMPLE   
	.\Get-ScheduledTasks.ps1 -Computername mycomputer1

Description 
-----------     
This command query mycomputer1 and display a formatted list of all scheduled tasks on that computer

.EXAMPLE   
	.\Get-ScheduledTasks.ps1

Description 
-----------     
This command query localhost and display a formatted list of all scheduled tasks on the local computer	
#>
param(
	$computername = "localhost"
)
try {
	$schedule = new-object -com("Schedule.Service") 
} catch {
	Write-Warning "Schedule.Service COM Object not found, this script requires this object"
	return
}
$schedule.connect($ComputerName) 
$tasks = $schedule.getfolder("\").gettasks(0)
$results = @()
$tasks | Foreach-Object {
	$PSObject = New-Object PSObject
	$PSObject | Add-Member -MemberType NoteProperty -Name 'Name' -Value $_.name
	$PSObject | Add-Member -MemberType NoteProperty -Name 'Path' -Value $_.path
	$PSObject | Add-Member -MemberType NoteProperty -Name 'State' -Value $_.state
	$PSObject | Add-Member -MemberType NoteProperty -Name 'Enabled' -Value $_.enabled
	$PSObject | Add-Member -MemberType NoteProperty -Name 'LastRunTime' -Value $_.lastruntime
	$PSObject | Add-Member -MemberType NoteProperty -Name 'LastTaskResult' -Value $_.lasttaskresult
	$PSObject | Add-Member -MemberType NoteProperty -Name 'NumberOfMissedRuns' -Value $_.numberofmissedruns
	$PSObject | Add-Member -MemberType NoteProperty -Name 'NextRunTime' -Value $_.nextruntime
	$PSObject | Add-Member -MemberType NoteProperty -Name 'Author' -Value ([regex]::split($_.xml,'<Author>|</Author>'))[1]
	$PSObject | Add-Member -MemberType NoteProperty -Name 'UserId' -Value ([regex]::split($_.xml,'<UserId>|</UserId>'))[1]
	$PSObject | Add-Member -MemberType NoteProperty -Name 'Description' -Value ([regex]::split($_.xml,'<Description>|</Description>'))[1]
	$PSObject
}