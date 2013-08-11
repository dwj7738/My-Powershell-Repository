<#
.SYNOPSIS
   <A brief description of the script>
.DESCRIPTION
   <A detailed description of the script>
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>

#*****************Start Script******************** 
# schedulewrapper.ps1 - Scheduled Task Monitor 
# Created by P. Sukus  
# Version 1.0 3/21/08 
# Written for PowerShell 1.0 
# 
# Description: 
# This script uses schtasks to get all the task information on every server defined in scheduletaskServers.txt  
# Poweshell is then used to parse the information down to tasks that executed in the last 3 days that have 
# failed. Disabled Schedules for tasks are filtered out as well. This script then emails an html report of any failed  
# tasks 
  
$Dateminus=(get-date (get-date).AddDays(-3) -f g) 
$Dateminus = (get-date (get-date) -f g) 
$Dateminus

$a = "" 
$a = $a + "<BODY{background-color:grey;}" 
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}" 
$a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}" 
$a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:red}" 
$a = $a + "" 
$b = "<H2>Failed Scheduled Tasks since $Dateminus</H2>" 
$c = 0 
#read the list of servers that have scheduled tasks on them to monitor 
$Servers = Get-Content c:\scripts\scheduletaskServers.txt 
$servercount = 0 
$Body = "" 
foreach ($svr in $Servers){ 
$svr
               # EXAMPLE: schtasks /query /FO CSV /V > ScheduleTaskMon.log 
                If ($servercount -gt 0) { 
#                                write-host schtasks /query /s $svr /FO CSV /NH /v >> c:\scripts\ScheduleTaskMon.csv 
                                schtasks /query /s $svr /FO CSV /NH /v >> ScheduleTaskMon.csv 
                                } 
                Else { 
                                write-host schtasks /query /s $svr /FO CSV /v > C:\scripts\ScheduleTaskMon.csv 
                               # schtasks /query /s $svr /FO CSV /v > ScheduleTaskMon.csv 
                                } 
                 
                $servercount++ 
} 
$errors = Import-Csv C:\scripts\ScheduleTaskMon.csv |  
Where-Object {$_."Last Run Time" -lt $Dateminus -and $_."Schedule" -ne "Disabled" -and $_."Last Result" -ne 0} 

$body = Import-Csv ScheduleTaskMon.csv |  
Where-Object {$_."Last Run Time" -lt $Dateminus -and $_."Schedule" -ne "Disabled" -and $_."Last Result" -ne 0} |  
select-object Hostname, Taskname, "Last Run Time""|  
Sort-Object -Property "Last Run Time" -Descending | ConvertTo-Html -Head $a -Body $b
 
$c = $errors.count 
 if ($c -eq 0) {
  $msg  | Out-File C:\Scripts\Test.htm
    }    
Invoke-Expression C:\Scripts\Test.htm
                                            