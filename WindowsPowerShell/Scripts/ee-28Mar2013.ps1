<#
=====================================================================
Title       : Experts- Exchange Question
Description : http://www.experts-exchange.com/Programming/Languages/Scripting/Powershell/Q_28078813.html#a39031922
Author      : David Johnson (ve3ofa)
Date        : 29/04/2013
Input       : 
Output      : 
Usage		: PS> .\find-old-files.ps1Notes		: This will check all drives on All Named Servers
Tag			: included function http://gallery.technet.microsoft.com/scriptcenter/Get-files-older-than-a-76dd16fd get-filesolderthan
## =====================================================================
#>
function ee-28mar2013
{
$ErrorActionPreference = "silentlycontinue"
$servers = Get-Content c:\test\servers.txt
$LastWrite = get-date "01/01/2010"
$dtstart = Get-Date
$age = $dtstart - $LastWrite
$DaysOld = $age.Days
$MyObject = $null
$FileArray = $null
$i = 0
$FileArray = @()
foreach ($server in $servers) {

#	$drives = $null
#	$drive = $null
    $drives = get-drives1
     
#    $drives = Get-DriveInfo
	foreach ($drive in $drives) {
		$driveletter = $drive.deviceid + "\"
		$d = "Scanning Drive: " + $driveletter
		$d
		Get-FilesOlderThan -Path $driveletter -PeriodName Days -PeriodValue $DaysOld -Recurse | ft
	}
}
$dtend = Get-Date
Write-Output("Elapsed Time:" + ($dtend - $dtstart))
}

function get-drives1 {
get-wmiobject win32_logicaldisk -filter "drivetype=3" | select-object deviceid, freespace,size
}

function get-drives2 {
$d = Get-PSDrive | where {$_.Name -like "?" -and $_.free -ge 1} 
foreach ($dd in $d) {select_object Name }

}

Function Get-FilesOlderThan {
    [CmdletBinding()]
    [OutputType([Object])]   
    param (
        [parameter(ValueFromPipeline=$true)]
        [string[]] $Path = (Get-Location),
        [parameter()]
        [string[]] $Filter,
        [parameter(Mandatory=$true)]
        [ValidateSet('Seconds','Minutes','Hours','Days','Months','Years')]
        [string] $PeriodName,
        [parameter(Mandatory=$true)]
        [int] $PeriodValue,
        [parameter()]
        [switch] $Recurse = $false
    )
    
    process {
        
        #If one of more of the paths specified does not exist generate an error  
        if ($(test-path $path) -eq $false) {
            write-error "Cannot find the path: $path because it does not exist"
        }
        
        Else {
        
            <#  
            If the recurse switch is not passed get all files in the specified directories older than the period specified, if no directory is specified then
            the current working directory will be used.
            #>
            If ($recurse -eq $false) {
        
                Get-ChildItem -Path $(Join-Path -Path $Path -ChildPath \*) -Include $Filter | Where-Object { $_.LastWriteTime -lt $(get-date).('Add' + $PeriodName).Invoke(-$periodvalue) `
                -and $_.psiscontainer -eq $false } | `
                #Loop through the results and create a hashtable containing the properties to be added to a custom object
                ForEach-Object {
                    $properties = @{ 
                        Path = $_.Directory 
                        Name = $_.Name 
                        DateModified = $_.LastWriteTime }
                    #Create and output the custom object     
                    New-Object PSObject -Property $properties | select Path,Name,DateModified 
                }                
                  
            } #Close if clause on Recurse conditional
        
            <#  
            If the recurse switch is passed get all files in the specified directories and all subfolders that are older than the period specified, if no directory
            is specified then the current working directory will be used.
            #>   
            Else {
            
                Get-ChildItem  -Path $(Join-Path -Path $Path -ChildPath \*) -Include $Filter -recurse | Where-Object { $_.LastWriteTime -lt $(get-date).('Add' + $PeriodName).Invoke(-$periodvalue) `
                -and $_.psiscontainer -eq $false } | `
                #Loop through the results and create a hashtable containing the properties to be added to a custom object
                ForEach-Object {
                    $properties = @{ 
                        Path = $_.Directory 
                        Name = $_.Name 
                        DateModified = $_.LastWriteTime }
                    #Create and output the custom object     
                    New-Object PSObject -Property $properties | select Path,Name,DateModified 
                }

            } #Close Else clause on recurse conditional       
        } #Close Else clause on Test-Path conditional
    
    } #End Process block
} #End Function

ee-28mar2013