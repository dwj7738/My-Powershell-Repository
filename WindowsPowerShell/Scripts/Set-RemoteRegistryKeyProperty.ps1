##############################################################################
##
## Set-RemoteRegistryKeyProperty
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Set the value of a remote registry key property

.EXAMPLE

PS >$registryPath =
    "HKLM:\software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell"
PS >Set-RemoteRegistryKeyProperty LEE-DESK $registryPath `
      "ExecutionPolicy" "RemoteSigned"

#>

param(
    ## The computer to connect to
    [Parameter(Mandatory = $true)]
    $ComputerName,

    ## The registry path to modify
    [Parameter(Mandatory = $true)]
    $Path,

    ## The property to modify
    [Parameter(Mandatory = $true)]
    $PropertyName,

    ## The value to set on the property
    [Parameter(Mandatory = $true)]
    $PropertyValue
)

Set-StrictMode -Version Latest

## Validate and extract out the registry key
if($path -match "^HKLM:\\(.*)")
{
    $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
        "LocalMachine", $computername)
}
elseif($path -match "^HKCU:\\(.*)")
{
    $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
        "CurrentUser", $computername)
}
else
{
    Write-Error ("Please specify a fully-qualified registry path " +
        "(i.e.: HKLM:\Software) of the registry key to open.")
    return
}

## Open the key and set its value
$key = $baseKey.OpenSubKey($matches[1], $true)
$key.SetValue($propertyName, $propertyValue)

## Close the key and base keys
$key.Close()
$baseKey.Close()
