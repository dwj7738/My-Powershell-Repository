<#
			"SatNaam WaheGuru"

Date: 04-04-2012, 11:09AM
Author: Aman Dhally
Email:  amandhally@gmail.com
web:	www.amandhally.net/blog
blog:	http://newdelhipowershellusergroup.blogspot.com/
More Info : http://newdelhipowershellusergroup.blogspot.in/2012/04/ip-address-release-renew-using.html

Version : 1

	/^(o.o)^\ 


#>

$ethernet = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where { $_.IpEnabled -eq $true -and $_.DhcpEnabled -eq $true} 


foreach ($lan in $ethernet) {
	Write-Host "Flushing IP addresses" -ForegroundColor Yellow
	Sleep 2
	$lan.ReleaseDHCPLease() | out-Null
	Write-Host "Renewing IP Addresses" -ForegroundColor Green
	$lan.RenewDHCPLease() | out-Null 
	Write-Host "The New Ip Address is "$lan.IPAddress" with Subnet "$lan.IPSubnet"" -ForegroundColor Yellow 
}