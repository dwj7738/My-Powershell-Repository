<#
.SYNOPSIS

    This script queries remote machines to find out if a private build of a file resides there.

.DESCRIPTION

    This script is a worked solution for the Scripting Games.

.NOTES

    File Name  : Get-PrivateBuildInfo.ps1

    Author     : Thomas Lee - tfl@psp.co.uk

    Requires   : PowerShell Version 2.0

.EXAMPLE

    Get-PrivateBuildInfo -file "C:\windows\notepad.exe" -computer "cookham8"

    Process, computer, PrivateBuild

    C:\windows\notepad.exe, Cookham8, False

.EXAMPLE

    get-privatebuildinfo  -file "C:\windows\notepad.exe" -computer "cookham8","cookham1"

    Process, computer, PrivateBuild

    C:\windows\notepad.exe, Cookham8, False

    C:\windows\notepad.exe, Cookham1, False

#>

Function Get-PrivateBuildInfo {

Param(

   [string]$file,

   [string[]] $computer

)

# Start of function

# Write header output

"Process, computer, PrivateBuild"

# Specify query and store away

$qs  = "`$filver `= [System.Diagnostics.FileVersionInfo]::GetVersionInfo(`"{0}`")`n" -f $file

$qs += "hostname;"

$qs += "`$filver"

$qs | Out-File .\query.ps1

# Run query on each system

$computer | foreach {

  $result = invoke-command -file .\query.ps1 -computername $_

  #output info

  $h   = $result[0]

  $ipb = $result[1].isprivatebuild

  "{0}, {1}, {2}" -f $file, $h, $ipb 

}

}