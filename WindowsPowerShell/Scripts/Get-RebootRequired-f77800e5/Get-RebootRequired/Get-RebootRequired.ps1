Function Get-RebootRequired
{
<#
.SYNOPSIS
Determines if a reboot is required on a particular computer

.DESCRIPTION
Uses a registry query to determine if a system has pending file writes

.EXAMPLE
Get-RebootRequired -computername Target1

Returns Boolean true or false

.NOTES
Written by Jason Morgan
Last modified 7/15/2013

#>
[CmdletBinding()]
param
    (
        [Parameter(Mandatory=$false,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True) ]
        [string[]]$ComputerName	= $env:COMPUTERNAME
    )
process 
    {
        Write-Verbose "Testing $ComputerName"
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                    Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" 
                }
    }
}