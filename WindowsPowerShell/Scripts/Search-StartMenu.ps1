##############################################################################
##
## Search-StartMenu
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/blog)
##
##############################################################################

<#

.SYNOPSIS

Search the Start Menu for items that match the provided text. This script
searches both the name (as displayed on the Start Menu itself,) and the
destination of the link.

.Example

Search-StartMenu "Character Map" | Invoke-Item
Searches for the "Character Map" appication, and then runs it

Search-StartMenu PowerShell | Select-FilteredObject | Invoke-Item
Searches for anything with "PowerShell" in the application name, lets you
pick which one to launch, and then launches it.

#>

param(
    ## The pattern to match
    [Parameter(Mandatory = $true)]
    $Pattern
)

Set-StrictMode -Version Latest

## Get the locations of the start menu paths
$myStartMenu = [Environment]::GetFolderPath("StartMenu")
$shell = New-Object -Com WScript.Shell
$allStartMenu = $shell.SpecialFolders.Item("AllUsersStartMenu")

## Escape their search term, so that any regular expression
## characters don't affect the search
$escapedMatch = [Regex]::Escape($pattern)

## Search for text in the link name
dir $myStartMenu *.lnk -rec | ? { $_.Name -match "$escapedMatch" }
dir $allStartMenu *.lnk -rec | ? { $_.Name -match "$escapedMatch" }

## Search for text in the link destination
dir $myStartMenu *.lnk -rec |
    Where-Object { $_ | Select-String "\\[^\\]*$escapedMatch\." -Quiet }
dir $allStartMenu *.lnk -rec |
    Where-Object { $_ | Select-String "\\[^\\]*$escapedMatch\." -Quiet }
