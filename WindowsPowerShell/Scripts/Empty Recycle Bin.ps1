# --------------------------------- Meta Information for Microsoft Script Explorer for Windows PowerShell V1.0 ---------------------------------
# Title: Empty Recycle Bin
# Author: Rich Prescott
# Description: This script allows you to view the contents of the recycle bin in your profile.  The first line creates a ComObject and then the second line grabs the Recycling Bin special folder.  It then enumerates the items contained in that special folder<br /> and removes each of them.  The Rem
# Date Published: 27-Aug-2011 11:39:06 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Empty-Recycle-Bin-1a3388ba
# ------------------------------------------------------------------

$Shell = New-Object -ComObject Shell.Application
$RecBin = $Shell.Namespace(0xA)
$RecBin.Items() | %{Remove-Item $_.Path -Recurse -Confirm:$false}