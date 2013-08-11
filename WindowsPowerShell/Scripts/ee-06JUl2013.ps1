#setup collection of IP address strings, include original IP
$ipaddress = "192.168.0.50"
$computername = "Davidjohnson-w8"
$ips = @()
$ips += $ipaddress
$ips += "192.168.3.20"
$ips += "192.168.4.30"

#also subnet masks, need as many as IP addresses
$masks = 0..$ips.count | %{ "255.255.255.0" }

#get the NIC
$nic = Get-WMIObject win32_networkadapterconfiguration -computer $computername | where { $_.IPAddress -contains $ipaddress }

#set addresses
$nic.EnableStatic($ips,$masks)