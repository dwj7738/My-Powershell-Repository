# ------------------------------------------------------------------
# Title: Find problematic Windows Services on Multiple Servers.
# Author: Aman Dhally
# Description: Hi,If you are an IT administrator and managing multiple Servers. Then i think in daily life you deals with that sometime Services on Servers get stopped. If you have monitioring Solution like SCOM installed in your environmnet then it is ok, but is you dont have... Sometime the w
# Date Published: 06-Mar-2012 9:06:54 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Find-problematic-Windows-5aea7513
# Tags: Powershell;Windows Services;Services
# Rating: 4.5 rated by 2
# ------------------------------------------------------------------

<#
			"SatNaam WaheGuru"

Date: 06:03:2012, 20:20PM
Author: Aman Dhally
Email:  amandhally@gmail.com
web:	www.amandhally.net/blog
blog:	http://newdelhipowershellusergroup.blogspot.com/
More Info : 

Version : 1

	/^(o.o)^\ 


#>


$compname = "LocalHost","S2k8r2e" # change this with your Computers Name 

foreach ($comp in $compname) {

write-Host -ForegroundColor Green "=========$comp==============="
Get-WmiObject win32_Service -ComputerName $comp| where {$_.StartMode -eq "Auto" -and $_.State -eq "stopped"} |  Select SystemName,Name,StartMode,State | ft -AutoSize


}
