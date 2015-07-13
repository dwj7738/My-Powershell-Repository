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
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBmDW58f+uy7RIQl86SlUQkY/
# G+mgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFN04iklPEuHt2E5e
# 1VYZlVLcC0H7MA0GCSqGSIb3DQEBAQUABIIBALF4hOxC9wMY83aX0yhgPiAHvXnF
# hGYypIwFTksUpk2MA/1oFNi9Ghna2vI7e/nMuwyF8MYEkMR0AxcgJ7b4Gq891R0p
# nP5gR2hmDBllnwqHzRDX/n66us9xNLRjs1A8ZDpK0VPUMD3HEBlppDSQLiQpwyNL
# 6jE2VIUoxrgukkzr0ZchRk7czHEQ64WU6nwctgqcKVv50roNi+79SJ4MzsKRAdyI
# kKgQHgOTJ1lGM+6mv1zJD8rJMQOlS4gWpnDdOhudMfL1sp0v43J+DYdJg4dZ/0mr
# oUxykk7pFvpoTk08jwAJbEN91nQvnlfnj5mG9/J5B3pJYjNNT0mteU+iaVs=
# SIG # End signature block
