#requires -version 2.0

# -----------------------------------------------------------------------------
# Script: Set-ISEMostRecent.ps1
# Version: 0.9.1
# Author: Jeffery Hicks
#    http://jdhitsolutions.com/blog
#    http://twitter.com/JeffHicks
# Date: 3/31/2011
#  modified command to open file so it goes to Out-Null. 
#
# Keywords:
# Comments:
#
# "Those who forget to script are doomed to repeat their work."
#
#  ****************************************************************
#  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
#  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
#  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
#  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
#  ****************************************************************
# -----------------------------------------------------------------------------

[cmdletbinding()]
Param(
[string]$path="$env:Userprofile\Documents\WindowsPowershell",
[int]$Count=5)

#Create the add-on menu
$mru=$psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Most Recent",$null,$null)

$global:ISERecent=(Join-Path -path $path -child "$($psise.CurrentPowerShellTab.displayname) ISE Most Recent.csv")
if (-Not (Test-Path $global:ISERecent))
{
    #create the csv file header
    "Fullpath,DisplayName,LastEdit" | out-File $global:ISERecent -Encoding ASCII
}
else
{

#check for log file and trim it to $Count items if there are more than twice the $count items
$save=Import-CSV -Path $global:ISERecent | Sort LastEdit -descending
if ($save.count -ge ($count*2))
{
   $save[0..$count] | Export-Csv -Path $global:ISERecent -Encoding ASCII
}

  Import-CSV $global:ISERecent | Select -Last $count | Sort LastEdit -descending | foreach {
     #create a string with the filepath
     [string]$cmd="`$psise.CurrentPowerShelltab.Files.Add(""$($_.fullpath)"") | Out-Null"
     #turn it into a script block
     $action=$executioncontext.InvokeCommand.NewScriptBlock($cmd)
     #add it to the menu
     $mru.submenus.Add($_.Displayname,$action,$null) | out-Null
    }
}

#define a function to update the MRU
Function Update-ISEMRU {
Param()
     #remove the five most recent files
     $mru=$psise.CurrentPowerShellTab.AddOnsMenu.Submenus | where {$_.Displayname -eq "Most Recent"}
     $mru.submenus.clear()
     
     #get the five most recent files and add them to the menu
     #resort them so that the last closed file is on the top of the menu
     Import-CSV $global:ISERecent | Sort LastEdit | Select -Last $count  | Sort LastEdit -Descending | foreach {
     #create a string with the filepath
     [string]$cmd="`$psise.CurrentPowerShelltab.Files.Add(""$($_.fullpath)"") | Out-Null"
     #turn it into a script block
     $action=$executioncontext.InvokeCommand.NewScriptBlock($cmd)
     #add it to the menu
     $mru.submenus.Add($_.Displayname,$action,$null) 
    }
  } #end function

    
#register the event to watch for changes
Register-ObjectEvent $psise.CurrentPowerShellTab.Files -EventName collectionchanged `
-sourceIdentifier "ISEChangeLog"-action {
 #initialize an array to hold recent file paths
 $recent=@()
 #get a list of the $Count most recent files and add each path to the $recent array
 Import-CSV $global:ISERecent | Sort LastEdit | Select -Last $count | foreach {$recent+=$_.Fullpath}
 
  #iterate ISEFile objects but only those that have been saved, not Untitled and not already in the list.
  $event.sender | 
  where {($_.IsSaved) -AND (-Not $_.IsUntitled) -AND ($recent -notContains $_.Fullpath)} |  
  foreach {
    #add the filename to the list  
   "$($_.Fullpath),$($_.Displayname),$(Get-Date)" | out-file $global:ISERecent -append -Encoding ASCII
  } #foreach
  #refresh the menu
  Update-ISEMRU 
  
}  #close -action
