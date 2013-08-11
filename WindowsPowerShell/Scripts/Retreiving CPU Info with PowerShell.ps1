# --------------------------------- Meta Information for Microsoft Script Explorer for Windows PowerShell V1.0 ---------------------------------
# Title: Retreiving CPU Info with PowerShell
# Author: jreypo
# Description: This is a way to do with PowerShell the same as the VB.NET script for retreiving CPU info also included on this hardware section. I tested it on Windows 7 and Windows Sever 2008<br /> R2.This is the script working on my laptop:<br />PowerShell-[~\D<wbr />oc\WindowsPower<wbr />Shell] % .\Get-CPUInfo.p
# Date Published: 18-Aug-2011 7:35:12 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Retriving-CPU-Info-with-d309d341
# Tags: Powershell Code
# ------------------------------------------------------------------

# Get-CPUInfo.ps1
# Code produced by Juan Manuel Rey (@jreypo)
#

$strComputer = "."
$colItems = Get-WmiObject -class "Win32_Processor" -namespace "root/CIMV2" -computername $strComputer

foreach ($objItem in $colItems) {
	Write-Host
	Write-Host "CPU ID: " -foregroundcolor yellow -NoNewLine
	Write-Host $objItem.DeviceID -foregroundcolor white
	Write-Host "CPU Model: " -foregroundcolor yellow -NoNewLine
	Write-Host $objItem.Name -foregroundcolor white
	Write-Host "CPU Cores: " -foregroundcolor yellow -NoNewLine
	Write-Host $objItem.NumberOfCores -foregroundcolor white
	Write-Host "CPU Max Speed: " -foregroundcolor yellow -NoNewLine
	Write-Host $objItem.MaxClockSpeed
	Write-Host "CPU Status: " -foregroundcolor yellow -NoNewLine
	Write-Host $objItem.Status
	Write-Host
}