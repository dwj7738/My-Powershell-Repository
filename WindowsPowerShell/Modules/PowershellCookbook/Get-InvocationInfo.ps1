##############################################################################
##
## Get-InvocationInfo
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Display the information provided by the $myInvocation variable

#>

param(
    ## Switch to no longer recursively call ourselves
    [switch] $PreventExpansion
)

Set-StrictMode -Version Latest

## Define a helper function, so that we can see how $myInvocation changes
## when it is called, and when it is dot-sourced
function HelperFunction
{
    "    MyInvocation from function:"
    "-"*50
    $myInvocation

    "    Command from function:"
    "-"*50
    $myInvocation.MyCommand
}

## Define a script block, so that we can see how $myInvocation changes
## when it is called, and when it is dot-sourced
$myScriptBlock = {
    "    MyInvocation from script block:"
    "-"*50
    $myInvocation

    "    Command from script block:"
    "-"*50
    $myInvocation.MyCommand
}

## Define a helper alias
Set-Alias gii .\Get-InvocationInfo

## Illustrate how $myInvocation.Line returns the entire line that the
## user typed.
"You invoked this script by typing: " + $myInvocation.Line

## Show the information that $myInvocation returns from a script
"MyInvocation from script:"
"-"*50
$myInvocation

"Command from script:"
"-"*50
$myInvocation.MyCommand

## If we were called with the -PreventExpansion switch, don't go
## any further
if($preventExpansion)
{
    return
}

## Show the information that $myInvocation returns from a function
"Calling HelperFunction"
"-"*50
HelperFunction

## Show the information that $myInvocation returns from a dot-sourced
## function
"Dot-Sourcing HelperFunction"
"-"*50
. HelperFunction

## Show the information that $myInvocation returns from an aliased script
"Calling aliased script"
"-"*50
gii -PreventExpansion

## Show the information that $myInvocation returns from a script block
"Calling script block"
"-"*50
& $myScriptBlock

## Show the information that $myInvocation returns from a dot-sourced
## script block
"Dot-Sourcing script block"
"-"*50
. $myScriptBlock

## Show the information that $myInvocation returns from an aliased script
"Calling aliased script"
"-"*50
gii -PreventExpansion
