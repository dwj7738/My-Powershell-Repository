
<#
This script is supposed to create some new PSDrives
based on environmental variables like %APPDATA% and
%USERPROFILE%\DOCUMENTS. However, after the script 
runs the drives don't exist. Why? What changes would you
make?
#>

Function New-Drives {

Param()

New-PSDrive -Name AppData -PSProvider FileSystem -Root $env:Appdata 
New-PSDrive -Name Temp -PSProvider FileSystem -Root $env:TEMP 

$mydocs=Join-Path -Path $env:userprofile -ChildPath Documents
New-PSDrive -Name Docs -PSProvider FileSystem -Root $mydocs

}

New-Drives
DIR temp: | measure-object –property length -sum