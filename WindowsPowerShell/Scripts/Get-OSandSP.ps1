##  http://blog.getbusinessconfident.com 
##  This script will pull from a list of workstations in a text file and report back the OS and Service ##  Pack Level across  
##  the network, it will need to be run with appropriate priviledges to succeed 
 
 
 
$erroractionpreference = “SilentlyContinue” 
 
$servers = gc servers.txt 
 
foreach ($server in $servers) 
{ 
 
$testconn = test-path “\\$server\c$” 
 
if ($testconn -match “false”) 
{ 
write-host “Can’t connect to:” $server 
} 
if ($testconn -match “true”) 
{ 
#write-host “Server:” $server 
$os = gwmi win32_operatingsystem -computer $server 
$sp = $os | % {$_.servicepackmajorversion} 
$a = $os | % {$_.caption} 
 
write-host $server “:” “|” “Operating System:” $a “Service Pack:” “|” $sp 
 
} 
 
} 
 
#end script 
# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFhBr/1oSJ+4DrN98xXmxooWg
# XY2gggI9MIICOTCCAaagAwIBAgIQiDf4l7KfgJdCCCaJOuGruDAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2Vyc2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xMjA2MTYwNjIyMDdaFw0zOTEyMzEyMzU5NTlaMBoxGDAWBgNVBAMTD1Bvd2Vy
# c2hlbGwgVXNlcjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA2AQ5hTYXFzN9
# 62GIrE8tV+e3cYxFMYN5sG6TRa8ZBGAc2IEQ9uYrz7YXUstjYq6AkVpPjF/h4mlh
# WTFCjBSlhRQj8B6MOSy5pnKFM+cLM/5UcE7ZKcwXpvrbxntu4DiT8iBxKrSYjkqA
# BbMZCyrQ8BAIrFgqy/t97FyGaFFoDP0CAwEAAaN2MHQwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwXQYDVR0BBFYwVIAQe3Eaz1UlVI4+TqpVWMaLyKEuMCwxKjAoBgNVBAMT
# IVBvd2Vyc2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQrIslSDNpf4tLn3Ai
# OEZ3MTAJBgUrDgMCHQUAA4GBAHdn+q07uKxlU/ELAluEVTsKBDxoIHtNa9GDtUhE
# Hrl10nwwgmTtC6XO2UmwJVw/1J+LqebKe7mWpha5Uzyc8GgeNc+m8zdbGuvqzpQe
# vOZ9UZSYBKrXvNXhCqw46WqEVpQP9DM+fJzc6O1trbHQ9HAFPgTktEIz5fg8gz2V
# GoJxMYIBYDCCAVwCAQEwQDAsMSowKAYDVQQDEyFQb3dlcnNoZWxsIExvY2FsIENl
# cnRpZmljYXRlIFJvb3QCEIg3+Jeyn4CXQggmiTrhq7gwCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FGys9JlEqIqAAuQeAkTjaf9ojvWvMA0GCSqGSIb3DQEBAQUABIGAMxiqAXA4YA5p
# Mv+RI0E3+7wvYzadeC2AULwCs/VaSEPL+lb1gsUyQWSkA1UUU3DFxODJVHGM06Y8
# a78ZAz2WkwPOWFvbOGPY5XkTzcOSWgdM83/bYyQN9PNRfHzhNmvkAttwaONOHZW4
# waBaTBYTL3XIRwCC2wrbU2Z375bEoVM=
# SIG # End signature block
