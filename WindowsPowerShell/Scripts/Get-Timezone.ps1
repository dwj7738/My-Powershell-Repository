Function Get-TimeZone
{
[cmdletbinding()]
param([string]$Name)
([system.timezoneinfo]::GetSystemTimeZones() | where { $_.ID –like “*$Name*” }) 
}

function Set-TimeZone 
 {
[CmdletBinding(SupportsShouldProcess = $True)]
param(
    [Parameter(ValueFromPipeline = $False, ValueFromPipelineByPropertyName = $True, Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [string]$TimeZone = “Eastern Standard Time”
  )

If (GET-TIMEZONEMATCH $TimeZone) {  
  $process = New-Object System.Diagnostics.Process
  $process.StartInfo.WindowStyle = “Hidden”
  $process.StartInfo.FileName = “tzutil.exe”
  $process.StartInfo.Arguments = “/s `”$TimeZone`”"
  $process.Start() | Out-Null }

ELSE { WRITE-ERROR “InvalidTimeZone” }
}

