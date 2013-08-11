# --------------------------------- Meta Information for Microsoft Script Explorer for Windows PowerShell V1.0 ---------------------------------
# Title: Robocopy and PowerShell
# Author: Mario cortés
# Description: This script allow you to run the Robocopy comand with powershell with various folders.When you donwload this script you'll have to edit it and change the source and destination folders. The below sample configuration run script twice, the first time copy the files from D:\MySour
# Date Published: 09-Nov-2011 2:42:22 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Robocopy-and-PowerShell-8e3d8011
# Tags: backup files;robocopy
# ------------------------------------------------------------------

$arSourceFolders = ("D:\MySourcePath1", "D:\MySourcePath2");
$arDestinationFolders = ("F:\MyDestinationPath1", "F:\MyDestinationPath2");