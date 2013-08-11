##############################################################################
## Get-Tomorrow
##
## Get the date that represents tomorrow
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

Set-StrictMode -Version Latest

function GetDate
{
    Get-Date
}

$tomorrow = (GetDate).AddDays(1)
$tomorrow
