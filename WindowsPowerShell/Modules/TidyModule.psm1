##############################################################################
##
## TidyModule.psm1
## Demonstrates how to handle cleanup tasks when a module is removed
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.EXAMPLE

PS >Import-Module TidyModule
PS >$TidyModuleStatus
Initialized
PS >Remove-Module TidyModule
PS >$TidyModuleStatus
Cleaned Up

#>

## Perform some initialization tasks
$GLOBAL:TidyModuleStatus = "Initialized"

## Register for cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    $GLOBAL:TidyModuleStatus = "Cleaned Up"
}