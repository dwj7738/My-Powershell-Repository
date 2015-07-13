<#   
.SYNOPSIS   
	Script that return informations about scheduled tasks on a computer
    
.DESCRIPTION 
	This script uses the Schedule.Service COM-object to query the local or a remote computer in order to gather	a
	formatted list including the Author, UserId and description of the task. This information is parsed from the
	XML attributed to provide a more human readable format
 
.PARAMETER Computername
    The computer that will be queried by this script, local administrative permissions are required to query this
    information

.NOTES   
    Name: Get-ScheduledTask.ps1
    Author: Jaap Brasser
    DateCreated: 2012-05-23
    DateUpdated: 2012-07-22
    Site: http://www.jaapbrasser.com
    Version: 1.2

.LINK
	http://www.jaapbrasser.com
	
.EXAMPLE   
	.\Get-ScheduledTask.ps1 -Computername mycomputer1

Description 
-----------     
This command query mycomputer1 and display a formatted list of all scheduled tasks on that computer

.EXAMPLE   
	.\Get-ScheduledTask.ps1

Description 
-----------     
This command query localhost and display a formatted list of all scheduled tasks on the local computer	
#>

Function Get-ScheduledTask {

    param(
    	$computername = "localhost",
        [switch]$RootFolder
    )

    #region Functions
    function Get-AllTaskSubFolders {
        [cmdletbinding()]
        param (
            # Set to use $Schedule as default parameter so it automatically list all files
            # For current schedule object if it exists.
            $FolderRef = $Schedule.getfolder("\")
        )
        if ($RootFolder) {
            $FolderRef
        } else {
            $FolderRef
            $ArrFolders = @()
            if(($folders = $folderRef.getfolders(1))) {
                foreach ($folder in $folders) {
                    $ArrFolders += $folder
                    if($folder.getfolders(1)) {
                        Get-AllTaskSubFolders -FolderRef $folder
                    }
                }
            }
            $ArrFolders
        }
    }
    #endregion Functions


    try {
    	$schedule = new-object -com("Schedule.Service") 
    } catch {
    	Write-Warning "Schedule.Service COM Object not found, this script requires this object"
    	return
    }

    $Schedule.connect($ComputerName) 
    $AllFolders = Get-AllTaskSubFolders

    foreach ($Folder in $AllFolders) {
        if (($Tasks = $Folder.GetTasks(0))) {
            $TASKS | % {[array]$results += $_}
            $Tasks | Foreach-Object {
    	        New-Object -TypeName PSCustomObject -Property @{
    	            'Name' = $_.name
                    'Path' = $_.path
                    'State' = $_.state
                    'Enabled' = $_.enabled
                    'LastRunTime' = $_.lastruntime
                    'LastTaskResult' = $_.lasttaskresult
                    'NumberOfMissedRuns' = $_.numberofmissedruns
                    'NextRunTime' = $_.nextruntime
                    'Author' =  ([xml]$_.xml).Task.RegistrationInfo.Author
                    'UserId' = ([xml]$_.xml).Task.Principals.Principal.UserID
                    'Description' = ([xml]$_.xml).Task.RegistrationInfo.Description
                }
            }
        }
    } 

}