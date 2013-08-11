#############################################################################
##
## Invoke-ComplexDebuggerScript
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Demonstrates the functionality of PowerShell's debugging support.

#>

Set-StrictMode -Version Latest

function HelperFunction
{
    $dirCount = 0
}

Write-Host "Calculating lots of complex information"

$runningTotal = 0
$runningTotal += [Math]::Pow(5 * 5 + 10, 2)
$runningTotal

$dirCount = @(Get-ChildItem $env:WINDIR).Count
$dirCount

HelperFunction

$dirCount

$runningTotal -= 10
$runningTotal /= 2
$runningTotal

$runningTotal *= 3
$runningTotal /= 2
$runningTotal
