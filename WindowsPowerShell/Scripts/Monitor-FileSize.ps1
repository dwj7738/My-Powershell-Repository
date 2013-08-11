function Monitor-FileSize
{

<#

.Synopsis
    Checks the file size of a given file until it reaches the specified size
.Description
    Checks the file size of a given file until it reaches the specified size.  AT that point, it alerts the user as to what the original file-size-boundry was and what it currently is.  The interval at which the script runs can be specified by the user.
.Parameter FilePath
    Path of the file that will be monitored.  If not pointed to a specific file, the script will montior all sub-directories as well.  ie. if pointed to C:\ drive, will monitor ALL files on C:\ drive
.Parameter Size
    File size is monitored against this value. When file size is equal or greater than this value, user alert is triggered.  Enter size constraints as integer values (ex: -Size 100 NOT -Size 100kb)
.Parameter Interval
    The wait interval between the executions of the function. The value of this parameter is in seconds and default value is 5 seconds
.Example
    Monitor-FileSize -FilePath C:\Test -Size 100
    
    Returns a message to the user alerting them when at least 100kb worth of memory is stored in the selected location.
.Example
    Monitor-FileSize -FilePath C:\Test -Size 100 -Interval 20
    
    Checking the size of the file and all sub-directories every 20 seconds
.Notes
    This script cannot be run as a background job and so must have a separate PowerShell window on which it can be running.

	Author: Paul Kiri.
#>

param
(
[Parameter(mandatory=$true,position=0)]
[string[]]$FilePath
,
[Parameter(mandatory=$true,position=1)]
[int]$Size
,
[Parameter(mandatory=$false)]
[int]$Interval=5
)
if((Test-Path $FilePath))
{
   While($FS -le $Size)
   {
      Start-Sleep -Seconds $Interval
      $FileSize = get-childitem $FilePath -Recurse -Include *.* | foreach-object -Process { $_.length / 1024 } | Measure-Object -Sum | Select-Object -Property Sum
      $FS = $FileSize.Sum
   }
} 

if (Test-Path)
{
Write-Output "The files at location, $FilePath , have exceeded $Size kb and are now $('{0:N4}' -f $FileSize.Sum) kb in size."
}

else{"File does not exist!"}


}