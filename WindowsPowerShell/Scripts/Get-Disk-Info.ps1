<#
.Synopsis
Gets Drive Free Space
.DESCRIPTION
   Gets Drive Free Space in MB
.EXAMPLE
   get-diskinfo -computername computer
#>


    
[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)]
    [string] $computername
    )
    get-wmiobject -ComputerName $computername -Class win32_logicaldisk -Filter "drivetype=3" |
        Select-Object DeviceID,@{name='FreeSpace(MB)';expression={$_.freespace / 1MB -as [int]}}


