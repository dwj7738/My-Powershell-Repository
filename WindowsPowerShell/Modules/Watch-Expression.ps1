#############################################################################
##
## Watch-Expression
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Updates your prompt to display the values of information you want to track.


.EXAMPLE

PS >Watch-Expression { (Get-History).Count }

Expression          Value
----------          -----
(Get-History).Count     3

PS >Watch-Expression { $count }

Expression          Value
----------          -----
(Get-History).Count     4
$count

PS >$count = 100

Expression          Value
----------          -----
(Get-History).Count     5
$count                100

PS >Watch-Expression -Reset
PS >

#>

param(
    ## The expression to track
    [ScriptBlock] $ScriptBlock,

    ## Switch to no longer watch an expression
    [Switch] $Reset
)

Set-StrictMode -Version Latest

if($Reset)
{
    Set-Item function:\prompt ([ScriptBlock]::Create($oldPrompt))

    Remove-Item variable:\expressionWatch
    Remove-Item variable:\oldPrompt

    return
}

## Create the variableWatch variable if it doesn't yet exist
if(-not (Test-Path variable:\expressionWatch))
{
    $GLOBAL:expressionWatch = @()
}

## Add the current variable name to the watch list
$GLOBAL:expressionWatch += $scriptBlock

## Update the prompt to display the expression values,
## if needed.
$GLOBAL:oldPrompt = Get-Content function:\prompt
if($oldPrompt -notlike '*$expressionWatch*')
{
    $newPrompt = @'
        $results = foreach($expression in $expressionWatch)
        {
            New-Object PSObject -Property @{
                Expression = $expression.ToString().Trim();
                Value = & $expression
            } | Select Expression,Value
        }
        Write-Host "`n"
        Write-Host ($results | Format-Table -Auto | Out-String).Trim()
        Write-Host "`n"

'@

    $newPrompt += $oldPrompt

    Set-Item function:\prompt ([ScriptBlock]::Create($newPrompt))
}
