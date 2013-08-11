##############################################################################
##
## Grant-RegistryAccessFullControl
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Grants full control access to a user for the specified registry key.

.EXAMPLE

PS >$registryPath = "HKLM:\Software\MyProgram"
PS >Grant-RegistryAccessFullControl "LEE-DESK\LEE" $registryPath

#>

param(
    ## The user to grant full control
    [Parameter(Mandatory = $true)]
    $User,

    ## The registry path that should have its permissions modified
    [Parameter(Mandatory = $true)]
    $RegistryPath
)

Set-StrictMode -Version Latest

Push-Location
Set-Location -LiteralPath $registryPath

## Retrieve the ACL from the registry key
$acl = Get-Acl .

## Prepare the access rule, and set the access rule
$arguments = $user,"FullControl","Allow"
$accessRule = New-Object Security.AccessControl.RegistryAccessRule $arguments
$acl.SetAccessRule($accessRule)

## Apply the modified ACL to the regsitry key
$acl | Set-Acl  .

Pop-Location
