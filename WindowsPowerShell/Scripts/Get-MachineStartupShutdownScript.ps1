##############################################################################
##
## Get-MachineStartupShutdownScript
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Get the startup or shutdown scripts assigned to a machine

.EXAMPLE

Get-MachineStartupShutdownScript -ScriptType Startup
Gets startup scripts for the machine

#>

param(
    ## The type of script to search for: Startup, or Shutdown.
    [Parameter(Mandatory = $true)]
    [ValidateSet("Startup","Shutdown")]
    $ScriptType
)

Set-StrictMode -Version Latest

## Store the location of the group policy scripts for the machine
$registryKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\Scripts"

## There may be no scripts defined
if(-not (Test-Path $registryKey))
{
    return
}

## Go through each of the policies in the specified key
foreach($policy in Get-ChildItem $registryKey\$scriptType)
{
    ## For each of the scripts in that policy, get its script name
    ## and parameters
    foreach($script in Get-ChildItem $policy.PsPath)
    {
        Get-ItemProperty $script.PsPath | Select Script,Parameters
    }
}
