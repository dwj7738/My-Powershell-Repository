Function new-script
{
	$strName = $env:username
	$date = get-date -format d
	$name = Read-Host "Filename"
	$email = Read-Host "eMail Address"
	$file = New-Item -type file "c:\Scripts\$name.ps1" -force
	add-content $file "#=========================================================================="
	add-content $file "#"
	add-content $file "# NAME: $name.ps1"
	add-content $file "#"
	add-content $file "# AUTHOR: $strName"
	add-content $file "# EMAIL: $email"
	add-content $file "#"
	add-content $file "# COMMENT: "
	add-content $file "#"
	add-content $file "# You have a royalty-free right to use, modify, reproduce, and"
	add-content $file "# distribute this script file in any way you find useful, provided that"
	add-content $file "# you agree that the creator, owner above has no warranty, obligations,"
	add-content $file "# or liability for such use."
	add-content $file "#"
	add-content $file "# VERSION HISTORY:"
	add-content $file "# 1.0 $date - Initial release"
	add-content $file "#"
	add-content $file "#=========================================================================="
	ii $file
}