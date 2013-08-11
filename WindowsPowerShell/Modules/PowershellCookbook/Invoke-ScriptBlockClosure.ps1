##############################################################################
##
## Invoke-ScriptBlockClosure
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Demonstrates the GetNewClosure() method on a script block that pulls variables
in from the user's session (if they are defined.)

.EXAMPLE

PS >$name = "Hello There"
PS >Invoke-ScriptBlockClosure { $name }
Hello There
Hello World
Hello There

#>

param(
    ## The scriptblock to invoke
    [ScriptBlock] $ScriptBlock
)

Set-StrictMode -Version Latest

## Create a new script block that pulls variables
## from the user's scope (if defined.)
$closedScriptBlock = $scriptBlock.GetNewClosure()

## Invoke the script block normally. The contents of
## the $name variable will be from the user's session.
& $scriptBlock

## Define a new variable
$name = "Hello World"

## Invoke the script block normally. The contents of
## the $name variable will be "Hello World", now from
## our scope.
& $scriptBlock

## Invoke the "closed" script block. The contents of
## the $name variable will still be whatever was in the user's session
## (if it was defined.)
& $closedScriptBlock
