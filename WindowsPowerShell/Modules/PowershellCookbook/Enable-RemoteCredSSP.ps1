##############################################################################
##
## Enable-RemoteCredSSP
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Enables CredSSP support on a remote computer. Requires that the machine
have PowerShell Remoting enabled, and that its operating system is Windows
Vista or later.

.EXAMPLE

Enable-RemoteCredSSP <Computer>

#>

param(
    ## The computer on which to enable CredSSP
    $Computername,

    ## The credential to use when connecting
    $Credential = (Get-Credential)
)

Set-StrictMode -Version Latest

## Call Get-Credential again, so that the user can type something like
## Enable-RemoteCredSSP -Computer Computer -Cred DOMAIN\user
$credential = Get-Credential $credential
$username = $credential.Username
$password = $credential.GetNetworkCredential().Password

## Define the script we will use to create the scheduled task
$powerShellCommand =
    "powershell -noprofile -command Enable-WsManCredSSP -Role Server -Force"
$script = @"
schtasks /CREATE /TN 'Enable CredSSP' /SC WEEKLY /RL HIGHEST ``
    /RU $username /RP $password ``
    /TR "$powerShellCommand" /F

schtasks /RUN /TN 'Enable CredSSP'
"@

## Create the task on the remote system to configure CredSSP
$command = [ScriptBlock]::Create($script)
Invoke-Command $computername $command -Cred $credential

## Wait for the remoting changes to come into effect
for($count = 1; $count -le 10; $count++)
{
    $output =
        Invoke-Command $computername { 1 } -Auth CredSSP -Cred $credential
    if($output -eq 1) { break; }

    "Attempt $count : Not ready yet."
    Sleep 5
}

## Clean up
$command = [ScriptBlock]::Create($script)
Invoke-Command $computername {
    schtasks /DELETE /TN 'Enable CredSSP' /F } -Cred $credential

## Verify the output
Invoke-Command $computername {
    Get-WmiObject Win32_ComputerSystem } -Auth CredSSP -Cred $credential
