##############################################################################
##
## Start-ProcessAsUser
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Launch a process under alternate credentials, providing functionality
similar to runas.exe.

.EXAMPLE

PS >$file = Join-Path ([Environment]::GetFolderPath("System")) certmgr.msc
PS >Start-ProcessAsUser Administrator mmc $file

#>

param(
    ## The credential to launch the process under
    $Credential = (Get-Credential),

    ## The process to start
    [Parameter(Mandatory = $true)]
    [string] $Process,

    ## Any arguments to pass to the process
    [string] $ArgumentList = ""
)

Set-StrictMode -Version Latest

## Create a real credential if they supplied a username
$credential = Get-Credential $credential

## Exit if they canceled out of the credential dialog
if(-not ($credential -is "System.Management.Automation.PsCredential"))
{
    return
}

## Prepare the startup information (including username and password)
$startInfo = New-Object Diagnostics.ProcessStartInfo
$startInfo.Filename = $process
$startInfo.Arguments = $argumentList

## If we're launching as ourselves, set the "runas" verb
if(($credential.Username -eq "$ENV:Username") -or
    ($credential.Username -eq "\$ENV:Username"))
{
    $startInfo.Verb = "runas"
}
else
{
    $startInfo.UserName = $credential.Username
    $startInfo.Password = $credential.Password
    $startInfo.UseShellExecute = $false
}

## Start the process
[Diagnostics.Process]::Start($startInfo)
