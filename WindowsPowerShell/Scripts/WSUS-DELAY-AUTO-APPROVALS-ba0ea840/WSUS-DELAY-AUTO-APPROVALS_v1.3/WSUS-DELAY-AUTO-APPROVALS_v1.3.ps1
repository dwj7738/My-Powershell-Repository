<#  
.SYNOPSIS  
    DELAY WSUS AUTO APPROVALS

.DESCRIPTION  
    This script delay approvals for specific target group (OU).
    The delay is customizable.
    You must run this script on your WSUS Server.
.NOTES  
    File Name            : DELAY-WSUS-AUTO-APPROVALS.ps1  
    Author               : Baptiste LEMARIE (FrameIP)
    Copyright 2013       : Veolia Transport
    Version              : 1.3 (2013/03/05) - make optional validation targetgroup
                                            - count delay from Creation Date (if validation target group exists) else from Arrival Date of updates
    History              : 1.2 (2013/02/14) - Fix
    History              : 1.1 (2013/01/29) - Fix
    History              : 1.0 (2013/01/22) - First Version
#>





###############################################################################
# GLOBALS

##################
# WSUS Part

# This the delay between arrival date of updates and automatic approvals
$DELAY = [TimeSpan]30d ; 

# Only these categories are concerned
# and "service packs" are hard coded excluded
$WSUS_CategoriesIncluded = @("Windows server 2008",  "Windows server 2008 R2", "Windows 7"); 

# We approve updates on this TargetGroup
$WSUS_TargetGroup_To_Approved = "All Computers";

# Optional : Validation TargetGroup
# If you don't have/want a Validation Target Group (with limited computers), set variable to null.
$WSUS_TargetGroup_Validation = "Validation Postes Serveurs";
#$WSUS_TargetGroup_Validation = $null;

##################
# LOG, REPORT and RUN files

$PATH_DIR = "D:\DELAY-WSUS-AUTO-APPROVALS";
$FILENAME_LOG = "DELAY-WSUS-AUTO-APPROVALS.log"
$FILENAME_REPORTS = "DELAY-WSUS-AUTO-APPROVALS_" + $(Get-Date -format yyyy-MM-dd_HH\hmm\mss\s)  + ".html"
$TITLE = "DELAY WSUS AUTO APPROVALS"



###############################################################################
# FUNCTIONS

function BuildHTMLTable($report){
    # The content
    if ($report.count -eq 0){
        return "<h3>No updates</h3>"
    } else {
        # $WSUS_TargetGroup_Validation is optinal 
        if ( $WSUS_TargetGroup_Validation -ne $null ) {
            $rows="<table>`
                <col>
                <col width=150px>
                <col width=100px>
                <col width=50px>
                <col width=180px>
                <tr>`
                <th>Name</th>`
                <th>Date of Arrivals</th>`
                <th>Approved by Validation</th>`
                <th>Action</th>`
                <th>Description</th>`
                </tr>"
            $rows+= $report | Sort-Object "Date of Arrival" -descending  | `
                foreach { "`
                    <tr>`
                    <td>"+$($_."name")+"</td>`
                    <td>"+$($_."Date of Arrival")+"</td>`
                    <td style='text-align:center'>"+$($_."Approved by Validation") +"</td>`
                    <td style='text-align:center'>"+$($_."Action") + "</td>`
                    <td>"+$($_."Description")+"</td>`
                    </tr>" }
            $rows+="</table>"
        } else {
            $rows="<table>`
                <col>
                <col width=150px>
                <col width=50px>
                <col width=180px>
                <tr>`
                <th>Name</th>`
                <th>Date of Arrivals</th>`
                <th>Action</th>`
                <th>Description</th>`
                </tr>"
            $rows+= $report | Sort-Object "Date of Arrival" -descending  | `
                foreach { "`
                    <tr>`
                    <td>"+$($_."name")+"</td>`
                    <td>"+$($_."Date of Arrival")+"</td>`
                    <td style='text-align:center'>"+$($_."Action") + "</td>`
                    <td>"+$($_."Description")+"</td>`
                    </tr>" }
            $rows+="</table>"
        }
    }
    return $rows
}


function filterUpdates($updates){

    $updates_filtered = @()
    $nb_rejected=0
    
    # Get update not approved for no targetgroup
    $updates | foreach {
        if ( $_.IsApproved -eq $False ){
            $updates_filtered += $_
        }
    }

    # Get update approved only for a specific Targetgroup
    $updates | where { $_.IsApproved -eq $True } | foreach { `
        $mark_tg_approved = $false
        $_.getUpdateApprovals() | foreach {
            if ($_.ComputerTargetGroupId -eq $tg_to_Approve.id ){
                $mark_tg_approved = $true
            }
        }
        if ( $mark_tg_approved ) {
            $nb_rejected++
        } else {
            $updates_filtered += $_
        }
    
    }

    return ($updates_filtered,$nb_rejected)
}


###############################################################################
# CORE PROGRAM - DON'T TOUCH !!! ... Normally



####
# INIT
####
# init trap
$logfile = $PATH_DIR + "\" + $FILENAME_LOG
trap {Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') Error - $_";break}
# get date
$now = Get-Date
# build filename for reports
$report_filename =$PATH_DIR + "\" + $FILENAME_REPORTS
$ErrorActionPreference = "Stop"

####
# Log
####
Add-content $logfile -value "----------------------------------------------------"
Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') Start"



####
# Load Assembly
####
Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') Loading Assembly ... "
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
# GetID of TargetGroup
$tg_to_Approve=$wsus.GetComputerTargetGroups() | where { $_.name -eq $WSUS_TargetGroup_To_Approved }
# $WSUS_TargetGroup_Validation is optinal 
if ( $WSUS_TargetGroup_Validation -ne $null ){
    $tg_valid_Approve=$wsus.GetComputerTargetGroups() | where { $_.name -eq $WSUS_TargetGroup_Validation }
}




####
# Get all updates we want.
####
Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') Collect and filter updates ... "

# building Rexgexp
$regexpCateg=""; $WSUS_CategoriesIncluded | foreach { $regexpCateg += "^$_$|" }
$regexpCateg = $regexpCateg.substring(0,$regexpCateg.length-1)
$allUpdates=$wsus.getUpdates()
$updates= $allUpdates | Where {$_.ProductTitles -match $regexpCateg `
                       -and $_.UpdateClassificationTitle -notmatch "Service Packs" `
                       -and $_.IsDeclined -eq $False `
                       -and $_.IsSuperseded -eq $False }

Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') - Total Updates : $($allUpdates.count)     Useful Updates : $($updates.count)"




####
# Eliminates some updates we collect
####
Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') Reject some useless updates ... "

($updates_filtered,$nb_rejected) = filterUpdates($updates)

Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') - Total updates rejected $nb_rejected (because they are already approved) "





####
# Automatic Approve
# and construct list of each updates
####
Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') Approving updates ... "

# Title, arrivaldate, producttitles, is not superseded, approved by validation, delay OK, action, remark
$report= @()
$nb_approved=0
$updates_filtered | foreach {
    $action=@()
    $desc=@()
    
    
    # $WSUS_TargetGroup_Validation is optinal 
    if ( $WSUS_TargetGroup_Validation -ne $null ){
        $isValidationApproved = $false
        $isDelayExceeded = $false
        if ( $_.isApproved ){
            $_.getUpdateApprovals() | foreach { 
                if ($_.ComputerTargetGroupId -eq $tg_valid_Approve.id ){ 
                    $isValidationApproved = $true
                    $delayCount = $_.CreationDate.add($DELAY)
                    $isDelayExceeded = $delayCount -lt $now
                 }
            }
        }
    } else {
        $delayCount = $_.ArrivalDate.add($DELAY)
        $isDelayExceeded = $delayCount -lt $now
        $isValidationApproved = $true
    }
    

    # $WSUS_TargetGroup_Validation is optinal 
    if ($isValidationApproved -or $WSUS_TargetGroup_Validation -eq $null ){
        if ($isDelayExceeded){
            Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') - Approve $($_.legacyname) "
            $nb_approved++
            $action="(Approve !)"
            $desc="Uncomment action in script"
            ## UNCOMMENT WHEN YOU'RE SURE 
            #$action="Approve !"
            #$desc = "$($($now - $_.ArrivalDate.add($DELAY) ).days) days left"
            #$_.approve(“Install”,$tg_to_Approve)
        } else {         
            $action="Wait"
            $desc= "$($($delayCount - $now).days) days remaining"
        }
    } else {
        if ( $WSUS_TargetGroup_Validation -ne $null ){
            $action="Wait"
            $desc="$($tg_valid_Approve.name) must be approved first"
        } else {
            $action="Wait"
            $desc="This case never happen - send comments on script center for this script"
        }
    }


    $line = New-Object System.Object
    $line | Add-Member -type NoteProperty -name "Name" -value $_.title
    $line | Add-Member -type NoteProperty -name "Date of Arrival" -value $_.ArrivalDate.ToString("yyyy/MM/dd HH:mm:ss")
    $line | Add-Member -type NoteProperty -name "Product" -value $_.ProductTitles
    # $WSUS_TargetGroup_Validation is optinal 
    if ( $WSUS_TargetGroup_Validation -ne $null ){
        $line | Add-Member -type NoteProperty -name "Approved by Validation" -value $isValidationApproved
    }
    $line | Add-Member -type NoteProperty -name "Action" -value $action
    $line | Add-Member -type NoteProperty -name "Description" -value $desc
    $report += $line
}
Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') - Total updates approved $nb_approved "






####
# Build report
####
Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') Building report ... "


$HTML_head = "<style> `
    th{background-color:#cce;} `
    tr:nth-child(odd){ background-color:#eee; } `
    tr:nth-child(even){ background-color:#fff; } `
    </style>";
    
$HTML_body = "<H2> $TITLE - Date of reports : $($now.ToString("yyyy/MM/dd HH:mm:ss"))</H2>`
    <p>Results are filtered and sorted by date</p>`
    <p>Delay before auto approve of target group <b>$WSUS_TargetGroup_To_Approved</b> is <b>$($DELAY.days) days</b></p>"

$report_html = BuildHTMLTable($report)

$html = "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN'  'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>`
    <html xmlns='http://www.w3.org/1999/xhtml'>" + `
    "<head>" + `
    "<title>" + $TITLE + "</title>" + `
    $HTML_style + `
    "</head>" + `
    "<body>" + `
    $HTML_body + `
    $report_html + `
    "</body>" + `
    "</html>"


$html | Set-Content $report_filename




####
# End
####

Add-content $logfile -value "$(Get-Date -format 'yyyy/MM/dd HH:mm:ss') End "