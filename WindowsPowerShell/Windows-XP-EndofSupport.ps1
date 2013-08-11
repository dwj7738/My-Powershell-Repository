$ds= New-TimeSpan $(Get-Date) $(Get-Date -month 04 -day 08 -year 2014)
$b = "Windows xP will expire in " + $ds.Days + " Days"
$cs =  "" + $ds.Days + " Until End of Support for Windows XP"
$b
$cs
