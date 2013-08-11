# ------------------------------------------------------------------
# Title: Allow PowerShell V2 access to .NET 4.0 framework
# Author: Boe Prox
# Description: This is an advanced function that I put together that will allow you to use the .NET 4.0 framework with PowerShell V2 (such as working with DataGrids in WPF). This script can be used against local or remote computers and gives you the option of enabling this configuration again
# Date Published: 10-Jan-2012 9:37:10 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Allow-PowerShell-V2-access-525799cc
# Rating: 5 rated by 1
# ------------------------------------------------------------------

.\Enable-DotNet4Access.ps1 -Console
$env:Version
