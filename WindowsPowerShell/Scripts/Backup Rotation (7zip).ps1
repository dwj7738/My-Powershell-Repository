First file RotateBackups_MasterList.txt
RowNbr,BackupName,VersionsRetained,BackupType
1,TargetBackup,2,Folder
2,LstDefBackup,5,File
3,XMLBackup,3,File
4,SourceBackup,2,Folder
5,TXTBackup,8,File

Second file RotateBackups_FolderList.txt
RowNbr,BackupName,FolderName
1,TargetBackup,c:\MyBooks\target
2,SourceBackup,c:\MyBooks\source

Third file RotateBackups_FileExtensions.txt
RowNbr,BackupName,FileExtension,FolderLoc
1,LstDefBackup,*.def,c:\MyBooks\target
2,LstDefBackup,*.lst,c:\MyBooks\target
3,XMLBackup,*.xml,c:\MyBooks\target
4,TXTBackup,*.txt,c:\MyBooks\rfiles


When executed, files are created in c:\Zipfiles that have a name associated with the BackupName, a batch date-time. BackupName files are counted & compared to VersionsRetained value, and excess ones (oldest first) are marked for deletion upon next run of script. Can specify a delete to recycle bin (default) or a destructive delete of the backup. 

Use at your own risk.


Script:

function create-7zip([String] $aDirectory, [String] $aZipfile){
	[string]$pathToZipExe = "C:\Program Files\7-zip\7z.exe";
	[Array]$arguments = "a", "-tzip", "$aZipfile", "$aDirectory", "-r";
	& $pathToZipExe $arguments;
}
#  Call it by using:
#create-7zip "c:\temp\myFolder" "c:\temp\myFolder.zip"

#************************************************************************************
#************************************************************************************
# Initialize variables
$zipFolder = "C:\ZipFiles"
$nameConv = "{0:yyyyMMdd_HHmmss}" -f (Get-Date) + ".zip"
$fileList = @{}
$FileCountArray = @()
$bkupTypeArr = @()
$myDocFolder = "c:\Documents and Settings\MyPC\My Documents\"

# Import text files for master, folder and file backup information
$bkupRotateMasterArr = Import-Csv $myDocFolder"RotateBackups_MasterList.txt"
$fldrBkupArray = Import-Csv $myDocFolder"RotateBackups_FolderList.txt"
$fileExtBkupArr = Import-Csv $myDocFolder"RotateBackups_FileExtensions.txt"

# Switch to delete Item or to send to recycle bin
#      delete is destructive and cannot recover file.  
#      Recycle setting removes file from folder, but sends to recycle bin
#      and can be restored if needed.
#      Must be either "Kill" or "Recycle"
$KillOrRecycle = "Recycle"
#************************************************************************************
#************************************************************************************

# Load contents of master backup array
$bkup_Counts = @{}
$b = $null
foreach($b in $bkupRotateMasterArr) 
{
	$bkup_Counts[$b.BackupName] = $b.VersionsRetained
} 


#set Backup Types from the array we just defined
$type = $null
foreach ($type in $bkup_Counts.Keys) {
	$bkupTypeArr += $type
}

#create array of our filenames for this batch
$type = $null
$fArray = @{}
foreach ($type in $bkupRotateMasterArr) {
	$fArray[$type.BackupName] = ($type.BackupName + $nameConv)
}

# if extension array not null, get list of files to back up
if ($fileExtBkupArr) { 
	#  Gather the list of files to be backed up
	$f = $null 
	foreach ($f in $fileExtBkupArr) {
		$arr = @()
		$arr = (Get-ChildItem $f.FolderLoc -Recurse -Include $f.FileExtension | Select-Object fullname)
		foreach ($a in $arr) {
			if ($a) {
				$fileList[$a] = $f.BackupName
			} # if $a not null
		} # end inner foreach
	} # end outer foreach
} # if FileExtension Backup Array not null


# if filelist count gt zero, then create zip file of them for appropriate backup
if ($fileList.Count -gt 0) { # must have entries in hashtable
	$f = $null
	#Loop thru file list & associate file with the appropriate backup
	foreach ($f in $fileList.Keys) {
		$arcFile = $null
		if ($fileList.ContainsKey($f)) {
			if ($fArray.ContainsKey($fileList[$f])) {
				$arcFile = $fArray[$fileList[$f]]
				create-7zip $f.FullName $zipFolder\$arcFile
			} #if key in fArray
		} # if key in Filelist
	} # end foreach
} # if hastable not empty

# if folder backup not null then back up folders
if ($fldrBkupArray) { # check if array not null (no entries)
	$f = $null
	#Backup Folders now
	foreach ($f in $fldrBkupArray) {
		$arcFldr = $null
		#if ($fArray.ContainsKey($f[1])) {
		if ($fArray.ContainsKey($f.BackupName)) {
			$arcFldr = $fArray[$f.BackupName]
			create-7zip $f.FolderName $zipFolder\$arcFldr
		} #end if
	} # end foreach
} # end if $fldrBkupArray not null


# if 7zip succeeded, we'll continue 
if ($LASTEXITCODE -gt 0)
{	Throw "7Zip failed" } 
ELSE { # if Exitcode = 0 then continue with job
	# Remove any files with Archive bit = False 
	#    we marked it for deletion in previous run
	Add-Type -AssemblyName Microsoft.VisualBasic
	$files = get-childitem -path $zipFolder
	# we'll delete all files that don't have the archive bit set 
	Foreach($file in $files) { 
		If((Get-ItemProperty -Path $file.fullname).attributes -band [io.fileattributes]::archive)
		{			Write-output "$file is set to be retained" }
		ELSE {
			if ($KillOrRecycle = "Recycle") {
				Write-output "$file does not have the archive bit set. Deleting (Sent to recycle bin)."
				[Microsoft.VisualBasic.FileIO.Filesystem]::DeleteFile($file.fullname,'OnlyErrorDialogs','SendToRecycleBin')
				$output = $_.ErrorDetails
			}
			ELSE {
				Write-output "$file does not have the archive bit set. Deleting."
				remove-item -recurse $file.fullname
				$output =$_.ErrorDetails 
			}
		} 
	} #end Foreach

	# Export BackupCounts to XML 
	$bkup_counts | Export-Clixml bkup_counts.xml

	# Get Number of ZIP files in folder
	$btype = $null
	foreach ($btype in $bkupTypeArr) {
		$FileCountArray += ,@(($btype),(dir $zipFolder\$btype"*.zip").count)
	}

	# Import BkupCounts from XML
	$bkup_Counts = Import-Clixml bkup_counts.xml

	# set Attribute byte on ALL files in zipfolder so we know we'll get the right ones
	attrib $zipFolder"\*" +a 

	$row = $null
	# Get LST & DEF filenames in array & display count
	foreach ($row in $bkup_Counts.Keys) {
		Get-ChildItem -Path $zipFolder -Include $row"*" -Recurse #|
		(			dir $zipFolder\$row"*".zip).count - $bkup_Counts[$row]
		$delfiles = 0
		$delfiles = (dir $zipFolder\$row"*".zip).count - $bkup_Counts[$row]
		if ($delfiles -gt 0) { #sort folder by createdtime 
			# if more than specified nbr of backups present, un-archive excess ones to delete next run.
			dir $zipFolder\$row"*" | sort-object -property {$_.CreationTime} |
			select-object -first $delfiles |
			foreach-object { attrib $_.FULLNAME -A} 
		} # end if delfiles gt 0
	} # End foreach in bkup_counts

} #  End Else Last ExitCode = 0
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhcGkCokMQi4doo6w0Y01h4hA
# CTigggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMtEllZBeEtbZFOY
# wDLXGqPZSyFRMA0GCSqGSIb3DQEBAQUABIIBAB13nr3VPLDe96Tz5wAnuaiBn8u7
# gkxsPHHerpkgzWom+3msB3QVpHuHMTNR9GmbofEFrGYJK/zwYMj9s7MX/hphVufl
# cDMN93DqyujuI5WHoZpjzawHuxB/ZfjqkFFRgGaFynbFkNHpi5mfk8HTXUKQeYAC
# WALACZfEVJ7TlJRcjRjHbfPZNMUap+0TX2cvYyzd6+/9X8WSRjPFqF7Z6oh5yccF
# /zhCJ/BKcaCnHwHKXnwKwrJgax5QfvY0Wxeqv0vfZcmvUcnugocZezIlceVA2E20
# Ij3jp5jhiFf1fMEN6PzPhi1oej/6wGWnbIEZZgTqHb9fMAh9hcXv52CrEU8=
# SIG # End signature block
