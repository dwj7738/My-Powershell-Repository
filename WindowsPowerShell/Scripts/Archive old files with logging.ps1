# Powershell script - move old files to an archive location. 
# Writes log files to $logpath 
# Ver 0.6 

$path = "C:\TEMP" 
$archpath = "D:\TEMP-ARCH" 
$days = "30" 
$logpath = "C:\Temp" 
$date = Get-Date -format yyyyMMddHHmm 

write-progress -activity "Archiving Data" -status "Progress:" 

If ( -not (Test-Path $archpath)) {ni $archpath -type directory} 

Get-Childitem -Path $path -recurse| Where-Object {$_.LastWriteTime -lt (get-date).AddDays(-$days)} | 
ForEach { $filename = $_.fullname 
	try { Move-Item $_.FullName -destination $archpath -force -ErrorAction:SilentlyContinue 
		"Successfully moved $filename to $archpath" | add-content $logpath\log-$date.txt } 
	catch { "Error moving $filename: $_ " | add-content $logpath\log-$date.txt } 
}