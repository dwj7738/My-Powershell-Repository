Function CheckDNSBL {
<#
.NOTES
    AUTHOR: Sunny Chakraborty(sunnyc7@gmail.com)
	WEBSITE: http://tekout.wordpress.com
    VERSION: 0.1
	CREATED: 16th July, 2012
	LASTEDIT: 16th July, 2012
	Requires: PowerShell v2 or better

.DESCRIPTION
	Basic Proof of Concept DNSBL Check Script
    You can add your own DNSBL's in the array and expand the list.
    Please use your Outbound STATIC IP as a parameter.
    You can run these checks for any version of Exchange [2003,2007,2010]
    Exchange doesnt need to be installed on the system to run this.
    Microsoft .Net Framework 3.5 and above required. 
     
#>

param(
$ip
)

## string reverse
$reverseIP = ($ip.split("."))[3..0]
[string[]]$newIP = [string]::join(".",$reverseIP)

##define hashtable for DNSBL's
[string[]]$dnsbl = @(
"b.barracudacentral.org";
"bl.deadbeef.com";
"bl.emailbasura.org";
"bl.spamcannibal.org";
"bl.spamcop.net";
"blackholes.five-ten-sg.com";
"blacklist.woody.ch";
"bogons.cymru.com";
"cbl.abuseat.org";
"cdl.anti-spam.org.cn";
"combined.abuse.ch";
"combined.rbl.msrbl.net";
"db.wpbl.info";
"dnsbl-1.uceprotect.net";
"dnsbl-2.uceprotect.net";
"dnsbl-3.uceprotect.net";
"dnsbl.ahbl.org";
"dnsbl.cyberlogic.net";
"dnsbl.inps.de";
"dnsbl.njabl.org";
"dnsbl.sorbs.net";
"drone.abuse.ch";
"drone.abuse.ch";
"duinv.aupads.org";
"dul.dnsbl.sorbs.net";
"dul.ru";
"dyna.spamrats.com";
"dynip.rothen.com";
"http.dnsbl.sorbs.net";
"images.rbl.msrbl.net";
"ips.backscatterer.org";
"ix.dnsbl.manitu.net";
"korea.services.net";
"misc.dnsbl.sorbs.net";
"noptr.spamrats.com";
"ohps.dnsbl.net.au";
"omrs.dnsbl.net.au";
"orvedb.aupads.org";
"osps.dnsbl.net.au";
"osrs.dnsbl.net.au";
"owfs.dnsbl.net.au";
"owps.dnsbl.net.au";
"pbl.spamhaus.org";
"phishing.rbl.msrbl.net";
"probes.dnsbl.net.au";
"proxy.bl.gweep.ca";
"proxy.block.transip.nl";
"psbl.surriel.com";
"rbl.interserver.net";
"rdts.dnsbl.net.au";
"relays.bl.gweep.ca";
"relays.bl.kundenserver.de";
"relays.nether.net";
"residential.block.transip.nl";
"ricn.dnsbl.net.au";
"rmst.dnsbl.net.au";
"sbl.spamhaus.org";
"short.rbl.jp";
"smtp.dnsbl.sorbs.net";
"socks.dnsbl.sorbs.net";
"spam.abuse.ch";
"spam.dnsbl.sorbs.net";
"spam.rbl.msrbl.net";
"spam.spamrats.com";
"spamlist.or.kr";
"spamrbl.imp.ch";
"t3direct.dnsbl.net.au";
"tor.ahbl.org";
"tor.dnsbl.sectoor.de";
"torserver.tor.dnsbl.sectoor.de";
"ubl.lashback.com";
"ubl.unsubscore.com";
"virbl.bit.nl";
"virus.rbl.jp";
"virus.rbl.msrbl.net";
"web.dnsbl.sorbs.net";
"wormrbl.imp.ch";
"xbl.spamhaus.org";
"zen.spamhaus.org";
"zombie.dnsbl.sorbs.net"
)

#Compose DNSBL Strings for each member in DNSBL Array
[string[]]$newDNSBL =@()
foreach ($hash in $dnsbl)
{
$newDNSBL += [string]$newIP+'.'+$hash
} # Enf of ForEach

#DNS Lookup Check for 127.0.0.10 for Membership
[String]$temp = @()

for ($i=1;$i -lt $newDNSBL.Count; $i++) {
    $temp = [System.Net.Dns]::GetHostAddresses($newDNSBL[$i]) | select-object IPAddressToString -expandproperty  IPAddressToString

switch($temp){

#127.0.0.10 indicates $IP is listed in DNSBL
'127.0.0.10'{
    Write-Host "IP $ip is listed in DNSBL " , ($newDNSBL[$i]).Replace("$newIP","") -foregroundcolor "Red"
    } # End of "127.0.0.10 check

#Blank returns not listed in DNSBL
''{
    "IP $ip is NOT listed in DNSBL " + ($newDNSBL[$i]).Replace("$newIP","")
    } # End of "" Check
} # End of Switch Block
} # End of For Loop to check DNSBL Listing

} # End of Function