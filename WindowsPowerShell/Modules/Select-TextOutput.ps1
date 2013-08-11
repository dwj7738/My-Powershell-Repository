##############################################################################
##
## Select-TextOutput
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Searches the textual output of a command for a pattern.

.EXAMPLE

Get-Service | Select-TextOutput audio
Finds all references to "Audio" in the output of Get-Service

#>

param(
    ## The pattern to search for
    $Pattern
)

Set-StrictMode -Version Latest
$input | Out-String -Stream | Select-String $pattern
