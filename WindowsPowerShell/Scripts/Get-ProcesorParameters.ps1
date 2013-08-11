Param(
	$computername = $env:computername
	)
$totalproc =0
$coreperproc = 0
$totalcores = 0
$totallogproc = 0
Get-WmiObject -computername $computername -class win32_processor | foreach {
$totalproc = $totalproc + 1
$coreperproc = $_.numberofcores
$totalcores = $totalcores + $_.numberofcores
$totallogproc = $totallogproc + $_.numberoflogicalprocessors}
if ($totallogproc -gt $totalcores) { $hyperthreading = "IS"} else {$hyperthreading= "is NOT"}

write-host "Total Physical Processors: $totalproc Cores per processor: $coreperproc Total cores: $totalcores Total Logical Processors: $totallogproc Hyperthreading $hyperthreading enabled" 
                                            