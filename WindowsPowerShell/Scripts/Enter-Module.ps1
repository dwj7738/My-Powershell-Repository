##############################################################################
##
## Enter-Module
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Lets you examine internal module state and functions by executing user
input in the scope of the supplied module.

.EXAMPLE

PS >Import-Module PersistentState
PS >Get-Module PersistentState

ModuleType Name                      ExportedCommands
---------- ----                      ----------------
Script     PersistentState           {Set-Memory, Get-Memory}


PS >"Hello World" | Set-Memory
PS >$m = Get-Module PersistentState
PS >Enter-Module $m
PersistentState: dir variable:\mem*

Name                           Value
----                           -----
memory                         {Hello World}

PersistentState: exit
PS >

#>

param(
    ## The module to examine
    [System.Management.Automation.PSModuleInfo] $Module
)

Set-StrictMode -Version Latest

$userInput = Read-Host $($module.Name)
while($userInput -ne "exit")
{
    $scriptblock = [ScriptBlock]::Create($userInput)
    & $module $scriptblock

    $userInput = Read-Host $($module.Name)
}
