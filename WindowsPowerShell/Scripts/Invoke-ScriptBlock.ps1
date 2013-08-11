##############################################################################
##
## Invoke-ScriptBlock
##
## From Windows PowerShell, The Definitive Guide (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Apply the given mapping command to each element of the input. (Note that
PowerShell includes this command natively, and calls it Foreach-Object)

.EXAMPLE

1,2,3 | Invoke-ScriptBlock { $_ * 2 }

#>

param(
    ## The scriptblock to apply to each incoming element
    [ScriptBlock] $MapCommand
)

begin
{
    Set-StrictMode -Version Latest
}
process
{
    & $mapCommand
}
