function get-ipaddress 
{
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName . | Format-Table -Property IPAddress
}

function get-detailed-ipaddress 
{
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName .
}
get-detailed-ipaddress-no-ipx-wins
{
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName . | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS*
}

function get-networkadapter-wmi-class-members {
Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "DHCPEnabled=true" –ComputerName . | Get-Member
}

function set-ip-static{
$NICs = Get-WMIObject Win32_NetworkAdapterConfiguration -computername . | where{$_.IPEnabled -eq $true -and $_.DHCPEnabled -eq $true}
Foreach($NIC in $NICs) {
    $ip = ($NIC.IPAddress[0])
    $gateway = $NIC.DefaultIPGateway
    $subnet = $NIC.IPSubnet[0]
    $dns = $NIC.DNSServerSearchOrder
    $NIC.EnableStatic($ip, $subnet)
    $NIC.SetGateways($gateway)
    $NIC.SetDNSServerSearchOrder($dns)
    $NIC.SetDynamicDNSRegistration("FALSE")
}
IPConfig /all
}

function set-ip=dynamic {
$NICs = Get-WMIObject Win32_NetworkAdapterConfiguration `
| where{$_.IPEnabled -eq “TRUE”}
Foreach($NIC in $NICs) {
$NIC.EnableDHCP()
$NIC.SetDNSServerSearchOrder()
}
IPConfig /all
}