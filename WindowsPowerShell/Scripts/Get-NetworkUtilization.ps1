## Get Network Utilization
## 
## get utilization from all network interfaces

$counters = @()
foreach ($inst in (new-object System.Diagnostics.PerformanceCounterCategory("network interface")).GetInstanceNames()){
	$cur = New-Object system.Diagnostics.PerformanceCounter('Network Interface','Bytes Total/sec',   $inst)
	$max = New-Object system.Diagnostics.PerformanceCounter('Network Interface','Current Bandwidth', $inst)

	$cur.NextValue() | Out-Null
	$max.NextValue() | Out-Null

	$counters += @{"Throughput"=$cur;"Bandwidth"=$max;"Name"=$inst}
}

sleep 2

foreach($counter in $counters) {

	$curnum = $counter.Throughput.NextValue()
	$maxnum = $counter.Bandwidth.NextValue()

	New-Object PSObject -Property @{"Util"=$((( $curnum * 8 ) / $maxnum ) * 100);"Name"=$counter.Name}
}