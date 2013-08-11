<#
.SYNOPSIS
   <A brief description of the script>
.DESCRIPTION
   <A detailed description of the script>
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>

$processes = Get-Process | Sort-Object CPU -desc | Select-Object ProcessName, CPU -First 10 | ConvertTo-Html | out-file c:\report.htm
c:\report.htm
