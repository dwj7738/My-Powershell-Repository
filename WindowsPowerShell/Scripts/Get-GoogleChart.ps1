## =====================================================================
## Title       : Get-GoogleChart
## Description : Example of creating a chart from data using Google Chart API
## Author      : Idera
## Date        : 10/15/2009
## Input       : 
## Output      : Chart
## Usage	   : PS> .\Get-GoogleChart
## Tag         : Google Chart
## Attributed  : Jabob Bindslet
##               http://mspowershell.blogspot.com/2008/01/google-chart-api-powershell.html
## Change log  : 
## ===================================================================== 

function DownloadAndShowImage ($url) {
	$filename = $home + "\chart.png"
	$webClient = new-object System.Net.WebClient
	$webClient.Headers.Add("user-agent", "Idera PowerShellPlus")
	$Webclient.DownloadFile($url, $filename)
	Invoke-Item $filename
}

function simpleEncoding ($valueArray, $labelArray, $size, [switch] $chart3D) {
	$simpleEncoding = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
	if ($chart3D) {$chartType = "p3"} else {$chartType ="p"}
	$total = 0
	foreach ($value in $valueArray) {
		$total = $total + $value
	}
	for ($i = 0;$i -lt $valueArray.length;$i++) {
		$relativeValue = ($valueArray[$i] / $total)*62
		$relativeValue = [math]::round($relativeValue)
		$encodingValue = $simpleEncoding[$relativeValue]
		$chartData = $chartData + "" + $encodingValue
	} 
	$chartLabel = [string]::join("|",$labelArray)
	Write-Output "http://chart.apis.google.com/chart?chtt=Running Process CPU Usage&cht=$chartType&chd=s:$chartdata&chs=$size&chl=$chartLabel"
}

function GetProcessArray() {
	$ListOfProcs = Get-Process | Sort-Object CPU -desc | Select-Object CPU, ProcessName -First 10
	$ListOfProcs | ForEach-Object {
		$ProcName = $ProcName + "," + $_.ProcessName
		$ProcUsage = $ProcUsage + "," + $_.CPU
	}
	Write-Output (($ProcName.trimStart(",")).split(","), ($ProcUsage.trimStart(",")).split(","))
}

$data = GetProcessArray
$url = simpleEncoding $data[1] $data[0] "700x350" -chart3D
DownloadAndShowImage $url