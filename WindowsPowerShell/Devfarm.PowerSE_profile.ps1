Remove-Variable -Force HOME
Set-Variable HOME "D:\Documents\WindowsPowerShell\Scripts"
Remove-PSDRIVE -Name mod -ErrorAction SilentlyContinue
Remove-PSDRIVE -Name sysmod -ErrorAction SilentlyContinue
$time = Get-Date -Format "HH:mm"
Write-Host "Hi David, welcome back! It is now " $time
$mymod = ($env:PSModulePath -split ";")
$mod = $mymod[0]
$mysysmod = ($env:PSModulePath -split ";")
$sysmod = $mysysmod[1]
New-PSDRIVE -name mod -Root $mod -PSProvider FileSystem
New-PSDRIVE -name sysmod -Root $sysmod -PSProvider FileSystem
cd $HOME
