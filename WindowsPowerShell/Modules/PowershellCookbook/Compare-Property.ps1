##############################################################################
##
## Compare-Property
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Compare the property you provide against the input supplied to the script.
This provides the functionality of simple Where-Object comparisons without
the syntax required for that cmdlet.

.EXAMPLE

Get-Process | Compare-Property Handles gt 1000

.EXAMPLE

PS >Set-Alias ?? Compare-Property
PS >dir | ?? PsIsContainer

#>

param(
    ## The property to compare
    $Property,

    ## The operator to use in the comparison
    $Operator = "eq",

    ## The value to compare with
    $MatchText = "$true"
)

Begin { $expression = "`$_.$property -$operator `"$matchText`"" }
Process { if(Invoke-Expression $expression) { $_ } }