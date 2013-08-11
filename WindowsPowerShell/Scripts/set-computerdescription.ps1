$path = (Get-WmiObject -Class Win32_OperatingSystem )._path
$path
Set-WmiInstance -Path $path -Argument @(
