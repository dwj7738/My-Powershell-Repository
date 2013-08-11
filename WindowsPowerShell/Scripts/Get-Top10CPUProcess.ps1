<#
.SYNOPSIS
   Gets top 10 CPU Process's and generates html report
.DESCRIPTION
   a Sample Script
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   get-top10cpuProcess
#>

$processes = Get-Process | Sort-Object CPU -desc | Select-Object ProcessName, CPU -First 10 | ConvertTo-Html | out-file c:\test\report.htm
c:\test\report.htm
