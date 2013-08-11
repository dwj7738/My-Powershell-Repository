##############################################################################
##
## Show-HtmlHelp
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Launches the CHM version of PowerShell help.

.EXAMPLE

Show-HtmlHelp

#>

Set-StrictMode -Version Latest

$path = (Resolve-Path c:\windows\help\mui\*\WindowsPowerShellHelp.chm).Path
hh "$path::/html/defed09e-2acd-4042-bd22-ce4bf92c2f24.htm"
