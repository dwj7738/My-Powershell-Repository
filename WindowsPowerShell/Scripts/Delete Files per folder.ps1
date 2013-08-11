<#

.SYNOPSIS
Deletes files in directory based on age measured in days

.DESCRIPTION
Delete files in folder with use of regular filter, either recursive or not.

.PARAMETER DelFilter 
Provide a filter like "*.txt" or "mylogs*"

.PARAMETER DelPath
The directory where files are to be deleted from, use the Recurse switch to delete from subfolder as well

.EXAMPLE
Remove-Files -delpath "C:\temp" -delfilter "Whatever-*" -fileage "30" -LogPath "C:\temp"

.NOTES
Instead of simply using a gci -Path -Filter -Recurse | Remove-Item I wanted a clean output per folder
Enable debug mode, to write delete actions to the log file without actually deleting the files

#>

Param(
	$DelPath = $(throw "Provide path to delete files from"),
	$DelFilter = $(throw "Provide a filter like *.txt or mylogs*"),
	[int] $FileAge = $(throw "number of days to keep, set it to 0 for all files"),
	$LogPath = $($Env:windir),
	[switch] $Recurse, 
	[switch] $Debug
)
#named parameters
"Path: {0}" -f $DelPath
"DelFilter: {0}" -f $DelFilter
"Age: {0}" -f $FileAge
"LogPath: {0}" -f $LogPath
#begin log action
$LogFile = $LogPath + "\DelFiles" + ".log"
$global:FileCount = 0

# function as one place to set output action
Function WriteLog ($Output){
	Write-output $Output | Out-File -Append -FilePath $LogFile
}
# delete files in every parsed folder
Function DeleteFiles ($DelFolder){
	foreach ($Item in Get-ChildItem -Force -Path $DelFolder -Filter $DelFilter){
		if ($Item.CreationTime -lt ($(Get-Date).AddDays(-$FileAge))){
			#if -debug parameter is used only log action, no delete action
			if (-not $Debug) { Remove-Item $Item.FullName}
			#delete log action
			WriteLog "`t $Item"
			$global:FileCount = $global:FileCount +1
		}
	}
}
# actual script execution
WriteLog "Deleting file(s) older than $FileAge day(s) at $DelPath"
$Date = Get-Date
WriteLog "Begin of operation at: $Date"
# file delete action
WriteLog $Delpath
DeleteFiles $Delpath
if ($Recurse){
	foreach ($Folder in (gci -Path $DelPath -recurse:$Recurse | ?{$_.PSIsContainer})){
		# create array first to report if only one or no item
		$NrFiles = @(Get-ChildItem -Force -Path $Folder.Fullname -Filter $DelFilter).count
		if ( $NrFiles -gt 0){
			WriteLog $Folder.Fullname
			DeleteFiles $Folder.Fullname
		}
	}
}
# end log action
WriteLog "$global:FileCount file(s) deleted successfully"
$Date = Get-Date
WriteLog "End of operation at: $Date"