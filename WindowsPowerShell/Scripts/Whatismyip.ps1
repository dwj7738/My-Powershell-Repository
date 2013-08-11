$SecurityServer = "W2K8-VIEW"
 
# For logging creating a timestamp
$TimeStamp = Get-Date -format yyyy-MM-dd-H-mm
 
# Filling $CheckedIP with the external IP address, using whatismyip.com service
$wc = New-Object net.WebClient
$CheckedIP = $wc.downloadstring("http://automation.whatismyip.com/n09230945.asp")
 Write-output ($TimeStamp)
 Write-output ($checkedip)
