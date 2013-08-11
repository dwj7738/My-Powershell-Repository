#############################################################################
##
## Get-ScriptCoverage
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Uses conditional breakpoints to obtain information about what regions of
a script are executed when run.

.EXAMPLE

PS >Get-Content c:\temp\looper.ps1

param($userInput)

for($count = 0; $count -lt 10; $count++)
{
    "Count is: $count"
}

if($userInput -eq "One")
{
    "Got 'One'"
}

if($userInput -eq "Two")
{
    "Got 'Two'"
}

PS >$action = { c:\temp\looper.ps1 -UserInput 'One' }
PS >$coverage = Get-ScriptCoverage c:\temp\looper.ps1 -Action $action
PS >$coverage | Select Content,StartLine,StartColumn | Format-Table -Auto

Content   StartLine StartColumn
-------   --------- -----------
param             1           1
(                 1           6
userInput         1           7
)                 1          17
Got 'Two'        15           5
}                16           1

This example exercises a 'looper.ps1' script, and supplies it with some
user input. The output demonstrates that we didn't exercise the
"Got 'Two'" statement.

#>

param(
    ## The path of the script to monitor
    $Path,

    ## The command to exercise the script
    [ScriptBlock] $Action = { & $path }
)

Set-StrictMode -Version Latest

## Determine all of the tokens in the script
$scriptContent = Get-Content $path
$ignoreTokens = "Comment","NewLine"
$tokens = [System.Management.Automation.PsParser]::Tokenize(
    $scriptContent, [ref] $null) |
    Where-Object { $ignoreTokens -notcontains $_.Type }
$tokens = $tokens | Sort-Object StartLine,StartColumn

## Create a variable to hold the tokens that PowerShell actually hits
$visited = New-Object System.Collections.ArrayList

## Go through all of the tokens
$breakpoints = foreach($token in $tokens)
{
    ## Create a new action. This action logs the token that we
    ## hit. We call GetNewClosure() so that the $token variable
    ## gets the _current_ value of the $token variable, as opposed
    ## to the value it has when the breakpoints gets hit.
    $breakAction = { $null = $visited.Add($token) }.GetNewClosure()

    ## Set a breakpoint on the line and column of the current token.
    ## We use the action from above, which simply logs that we've hit
    ## that token.
    Set-PsBreakpoint $path -Line `
        $token.StartLine -Column $token.StartColumn -Action $breakAction
}

## Invoke the action that exercises the script
$null = . $action

## Remove the temporary breakpoints we set
$breakpoints | Remove-PsBreakpoint

## Sort the tokens that we hit, and compare them with all of the tokens
## in the script. Output the result of that comparison.
$visited = $visited | Sort-Object -Unique StartLine,StartColumn
Compare-Object $tokens $visited -Property StartLine,StartColumn -PassThru

## Clean up our temporary variable
Remove-Item variable:\visited