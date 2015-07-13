#==========================================
#
#Script ID / Name:  Update-CauSchedule.ps1
#
#Author:   				Justin Lipple (JL)
#
#Owner:	   				Justin Lipple (JL)
#
#Copyright: 			
#
#Created:   			03/04/2014
#
#Language: 				PowerShell v4
#
#Interpreter: 			PowerShell v4
#
#Requirements:
# 	
#
#-------------------------------------------------------------------------
#Purpose:  The Purpose of this script is to automate the updating of Cluster Aware Updating Self Updating mode schedules
#
#Additional Detail:
#    -Unfortunately the CAU schedule only allows WeeksOfMonth and DaysOfWeek. However our work's Patch Thursday is sometimes week 2, somethimes week 3
#     depending on what week the 2nd Tuesday of the month falls on.
#     This script will determine that, update designated CAU clusters, and email results.
#
#==========================================================================
#==============================
#Changelog
#==============================
#
# V1.0.0 JL 03/04/2014:
# - Created script
# V2.0.0 JL 11/04/2014:
# - Updates and tested working version
#
#
#==============================
# End Changelog
#==============================

#Input Parameters
Param(
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$True)]
    $ClusterName,
    [Parameter(Mandatory=$true,
    ValueFromPipeline=$True)]
    $EmailRecipient
)

#declare constants

$emailSubject = "Cluster Aware Updating patch day validation - $(Get-Date)"
$emailSender = 'CAUscript-NoReply@contoso.com'
$SMTP_SERVER = 'mailrelay.contoso.local'



#Script setup for logging & output purposes
$date = $((Get-Date).ToString("yyyyMMddHHmm"))
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = split-path -leaf $MyInvocation.MyCommand.Definition
$CSVFile =  "$($date)-$scriptName.csv"



function Send-Email{
Param(                     
    $currentWeekOfMonth,
    $actualWeekOfMonth, 
    $ClusterName, 
    $actualPatchThursday,
    $changeRequired,
    $newActualWeeksOfMonth)
 $head = @'
<style type="text/css">
.myOtherTable { background-color:#FFFFE0;border-collapse:collapse;color:#000;font-size:18px; }
.myOtherTable th { background-color:#BDB76B;color:white;width:50%; }
.myOtherTable td, .myOtherTable th { padding:5px;border:0; }
.myOtherTable td { border-bottom:1px dotted #BDB76B; }
</style>
<!-- End Styles -->
'@

$body = $head
$body += "<table class='myOtherTable'>"
$body += "<tr><th>$($ClusterName.ToUpper()): Cluster Aware Updating patch day validation</th><th></th></tr>"
$body += "<tr><td>The clusters current 'WeekOfMonth' schedule is</td><td>$currentWeekOfMonth</td></tr>"
$body += "<tr><td>The clusters current 'StartDate' schedule is</td><td>$currentStartDate</td></tr>"
$body += "<tr><td>This month's Patch Thursday date is</td><td>$actualPatchThursday</td></tr>"
$body += "<tr><td>This month's actual 'WeekOfMonth' is</td><td>$actualWeekOfMonth</td></tr>"
$body += "<tr><td>Is there a change required?</td><td>$changeRequired</td></tr>"
$body += "<tr><td>The clusters refreshed current 'WeekOfMonth' is</td><td>$newActualWeeksOfMonth</td></tr>"
$body += "</table>"


Send-MailMessage -To $emailRecipient -Subject $emailSubject -From $emailSender -SmtpServer $SMTP_SERVER -Body ($Body | Out-String) -BodyAsHtml


}

function Get-CauSchedule{ #function to retrieve the current schedule on a given cluster
Param(                     
    $clusterName)
$objCauSchedule = $null
$objCauSchedule = Get-CauClusterRole -ClusterName $clusterName

$global:CauSchedule = $null
$global:CauSchedule = New-object PSObject
$global:CauSchedule | Add-Member NoteProperty DaysOfWeek $objCauSchedule.GetValue(8).Value
$global:CauSchedule | Add-Member NoteProperty WeeksOfMonth $objCauSchedule.GetValue(9).Value
$global:CauSchedule | Add-Member NoteProperty StartDate $objCauSchedule.GetValue(2).Value

Return $global:CauSchedule

}


function Set-CauSchedule{ #function to update the existing schedule on a given cluster to provided values
Param(                     
    $clusterName,
    $newWeeksOfMonth)

Set-CauClusterRole -ClusterName $clustername -WeeksOfMonth $newWeeksOfMonth -StartDate $(Get-Date -Date "2013-01-01 18:30:00") -Force #sets start time to 6:30 PM

Return $global:newActualWeeksOfMonth = ((Get-CauClusterRole -ClusterName $clusterName).GetValue(9).Value)

}


function Get-PatchThursday{ #function to find Contoso Patch Thursday, for a given month & year
Param(                     
    $month = (Get-Date).Month, 
    $year = (Get-Date).Year)

$FindNthDay=2
$WeekDay='Tuesday'

If(($month -lt 1) -or ($month -gt 12)){Write-Host "Month not valid" -ForegroundColor Red ;Break}


$strTargetMonth = $month.toString()
$strTargetYear = $year.ToString()


[string]$strTempDate = $strTargetMonth+'/1/'+$strTargetYear
[datetime]$strFirstInstance = $strTempDate

while ($strFirstInstance.DayofWeek -ine $WeekDay ) { $strFirstInstance = $strFirstInstance.AddDays(1) }


#Get the nth weekday, then find 2 days later
$global:target = ($strFirstInstance.AddDays(7*($FindNthDay-1))).AddDays(2)

Return $global:target.ToString("dd/MM/yyyy")

}

function Get-PatchThursdayWeek{ 
Param(                     
    $patchDay)

$patchThursdaydt = [datetime]::ParseExact($patchDay, "dd/MM/yyyy", $null)

$numDaysDecremented = 0
[string]$strTempDate = ($patchThursdaydt.Month).Tostring()+'/1/'+($patchThursdaydt.Year).ToString()
[datetime]$strFirstInstance = $strTempDate
while ($patchThursdaydt -ine $strFirstInstance ) {
    $patchThursdaydt = $patchThursdaydt.AddDays(-1)
    $numDaysDecremented++
    }

Return ([math]::Truncate($numDaysDecremented / 7) + 1)

}

    
#get cluster's current WeekOfMonth value
$currentWeekOfMonth = (Get-CauSchedule $ClusterName).WeeksOfMonth[0]

#get cluster's current StartDate value
$currentStartDate = (Get-CauSchedule $ClusterName).StartDate[0]

#for ($i = 1; $i -le 12; $i++){ this loop is for testing the script for each month of the year

$actualPatchThursday = Get-PatchThursday #-month $i uncomment for loop testing the script for each month of the year
$actualWeekOfMonth = Get-PatchThursdayWeek -patchday $actualPatchThursday

#decide if update is required, and perform the update
If ($currentWeekOfMonth -eq $actualWeekOfMonth){
    $changeRequired = $false
    $newWeekOfMonth = $currentWeekOfMonth
    }
ElseIf ($currentWeekOfMonth -ne $actualWeekOfMonth){
    $changeRequired = $true
    Set-CauSchedule $ClusterName $actualWeekOfMonth | Out-Null
    $newWeekOfMonth = $newActualWeeksOfMonth
    }



 
Send-Email $currentWeekOfMonth $actualWeekOfMonth $ClusterName $actualPatchThursday $changeRequired $newWeekOfMonth

#} this loop is for testing the script for each month of the year

