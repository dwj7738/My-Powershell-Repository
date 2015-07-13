 $netname = get-netadapter |select name
 foreach ($net in $netname)
 {
 Enable-NetAdapterIPsecOffload -Name $net.name
 Enable-NetAdapterRss -Name $net.name
 Enable-NetAdapterIPsecOffload -Name $net.name
 }
 Start-Process sc -ArgumentList " config srv start=demand"
If (-not (Get-Module DNSServer -ErrorAction SilentlyContinue)) {
    Import-Module DNSServer
    }
 
#Set New values
$DnsServer = $env:COMPUTERNAME
$IPofDNS = [System.Net.DNS]::GetHostAddresses($DnsServer).IPAddressToString
$Zones = Get-DnsServerZone | Where-Object {$_.IsAutoCreated -eq $False -and $_.ZoneName -ne 'TrustAnchors'}
$WrongZones = $Zones | Get-DnsServerZoneAging | Where-Object {$_.ScavengeServers -eq $IPofDNS}
$WrongZones |Set-DnsServerZoneAging -Aging $True -ScavengeServers $IPofDNS
Get-DnsServerResourceRecord -ZoneName 'techsupport4me.ca' -RRType A  |Export-Csv c:\temp\demo.csv -NoTypeInformation
Get-ADOrganizationalUnit -filter * -Properties ProtectedFromAccidentalDeletion 
Get-ADOrganizationalUnit -filter * -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $false} | Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $true
Push-Location
Set-Location HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem
Set-ItemProperty -Name .\NtfsDisable8dot3NameCreation -Value 1
Pop-Location
