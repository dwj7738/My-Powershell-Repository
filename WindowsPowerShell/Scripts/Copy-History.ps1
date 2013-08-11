##############################################################################
##
## Copy-History
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Copy selected commands from the history buffer into the clipboard as a script.

.EXAMPLE

Copy-History
Copies the entire contents of the history buffer into the clipboard.

.EXAMPLE

Copy-History -5
Copies the last five commands into the clipboard.

.EXAMPLE

Copy-History 2,5,8,4
Copies commands 2,5,8, and 4.

.EXAMPLE

Copy-History (1..10+5+6)
Copies commands 1 through 10, then 5, then 6, using PowerShell's array
slicing syntax.

#>

param(
    ## The range of history IDs to copy
    [int[]] $Range
)

Set-StrictMode -Version Latest

$history = @()

## If they haven't specified a range, assume it's everything
if((-not $range) -or ($range.Count -eq 0))
{
    $history = @(Get-History -Count ([Int16]::MaxValue))
}
## If it's a negative number, copy only that many
elseif(($range.Count -eq 1) -and ($range[0] -lt 0))
{
    $count = [Math]::Abs($range[0])
    $history = (Get-History -Count $count)
}
## Otherwise, go through each history ID in the given range
## and add it to our history list.
else
{
    foreach($commandId in $range)
    {
        if($commandId -eq -1) { $history += Get-History -Count 1 }
        else { $history += Get-History -Id $commandId }
    }
}

## Finally, export the history to the clipboard.
$history | Foreach-Object { $_.CommandLine } | clip.exe
