##############################################################################
##
## Get-AliasSuggestion
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Get an alias suggestion from the full text of the last command. Intended to
be added to your prompt function to help learn aliases for commands.

.EXAMPLE

Get-AliasSuggestion Remove-ItemProperty
Suggestion: An alias for Remove-ItemProperty is rp

#>

param(
    ## The full text of the last command
    $LastCommand
)

Set-StrictMode -Version Latest

$helpMatches = @()

## Find all of the commands in their last input
$tokens = [Management.Automation.PSParser]::Tokenize(
    $lastCommand, [ref] $null)
$commands = $tokens | Where-Object { $_.Type -eq "Command" }

## Go through each command
foreach($command in $commands)
{
    ## Get the alias suggestions
    foreach($alias in Get-Alias -Definition $command.Content)
    {
    $helpMatches += "Suggestion: An alias for " +
        "$($alias.Definition) is $($alias.Name)"
    }
}

$helpMatches
