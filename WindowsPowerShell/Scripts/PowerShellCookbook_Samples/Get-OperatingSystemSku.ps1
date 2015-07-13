##############################################################################
##
## Get-OperatingSystemSku
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Gets the sku information for the current operating system

.EXAMPLE

PS > Get-OperatingSystemSku
Professional with Media Center

#>

param($Sku = 
    (Get-CimInstance Win32_OperatingSystem).OperatingSystemSku)

Set-StrictMode -Version 3

switch ($Sku)
{
    0   { "An unknown product"; break; }
    1   { "Ultimate"; break; }
    2   { "Home Basic"; break; }
    3   { "Home Premium"; break; }
    4   { "Enterprise"; break; }
    5   { "Home Basic N"; break; }
    6   { "Business"; break; }
    7   { "Server Standard"; break; }
    8   { "Server Datacenter (full installation)"; break; }
    9   { "Windows Small Business Server"; break; }
    10  { "Server Enterprise (full installation)"; break; }
    11  { "Starter"; break; }
    12  { "Server Datacenter (core installation)"; break; }
    13  { "Server Standard (core installation)"; break; }
    14  { "Server Enterprise (core installation)"; break; }
    15  { "Server Enterprise for Itanium-based Systems"; break; }
    16  { "Business N"; break; }
    17  { "Web Server (full installation)"; break; }
    18  { "HPC Edition"; break; }
    19  { "Windows Storage Server 2008 R2 Essentials"; break; }
    20  { "Storage Server Express"; break; }
    21  { "Storage Server Standard"; break; }
    22  { "Storage Server Workgroup"; break; }
    23  { "Storage Server Enterprise"; break; }
    24  { "Windows Server 2008 for Windows Essential Server Solutions"; break; }
    25  { "Small Business Server Premium"; break; }
    26  { "Home Premium N"; break; }
    27  { "Enterprise N"; break; }
    28  { "Ultimate N"; break; }
    29  { "Web Server (core installation)"; break; }
    30  { "Windows Essential Business Server Management Server"; break; }
    31  { "Windows Essential Business Server Security Server"; break; }
    32  { "Windows Essential Business Server Messaging Server"; break; }
    33  { "Server Foundation"; break; }
    34  { "Windows Home Server 2011"; break; }
    35  { "Windows Server 2008 without Hyper-V for Windows Essential Server Solutions"; break; }
    36  { "Server Standard without Hyper-V"; break; }
    37  { "Server Datacenter without Hyper-V (full installation)"; break; }
    38  { "Server Enterprise without Hyper-V (full installation)"; break; }
    39  { "Server Datacenter without Hyper-V (core installation)"; break; }
    40  { "Server Standard without Hyper-V (core installation)"; break; }
    41  { "Server Enterprise without Hyper-V (core installation)"; break; }
    42  { "Microsoft Hyper-V Server"; break; }
    43  { "Storage Server Express (core installation)"; break; }
    44  { "Storage Server Standard (core installation)"; break; }
    45  { "Storage Server Workgroup (core installation)"; break; }
    46  { "Storage Server Enterprise (core installation)"; break; }
    46  { "Storage Server Enterprise (core installation)"; break; }
    47  { "Starter N"; break; }
    48  { "Professional"; break; }
    49  { "Professional N"; break; }
    50  { "Windows Small Business Server 2011 Essentials"; break; }
    51  { "Server For SB Solutions"; break; }
    52  { "Server Solutions Premium"; break; }
    53  { "Server Solutions Premium (core installation)"; break; }
    54  { "Server For SB Solutions EM"; break; }
    55  { "Server For SB Solutions EM"; break; }
    56  { "Windows MultiPoint Server"; break; }
    59  { "Windows Essential Server Solution Management"; break; }
    60  { "Windows Essential Server Solution Additional"; break; }
    61  { "Windows Essential Server Solution Management SVC"; break; }
    62  { "Windows Essential Server Solution Additional SVC"; break; }
    63  { "Small Business Server Premium (core installation)"; break; }
    64  { "Server Hyper Core V"; break; }
    72  { "Server Enterprise (evaluation installation)"; break; }
    76  { "Windows MultiPoint Server Standard (full installation)"; break; }
    77  { "Windows MultiPoint Server Premium (full installation)"; break; }
    79  { "Server Standard (evaluation installation)"; break; }
    80  { "Server Datacenter (evaluation installation)"; break; }
    84  { "Enterprise N (evaluation installation)"; break; }
    95  { "Storage Server Workgroup (evaluation installation)"; break; }
    96  { "Storage Server Standard (evaluation installation)"; break; }
    98  { "Windows 8 N"; break; }
    99  { "Windows 8 China"; break; }
    100 { "Windows 8 Single Language"; break; }
    101 { "Windows 8"; break; }
    103 { "Professional with Media Center"; break; }

    default {"UNKNOWN: " + $SKU }
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgQn1+HIfq4y7GCV55zSXh5MR
# gB+gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJSA4jZ1nhuH5yFC
# 7o3D350FemW/MA0GCSqGSIb3DQEBAQUABIIBAFz9aEbNMNDjKeZzg8N5sbWI9Yzb
# aJsZ7chhUynnQn+Cgx2besEoH2JR4lWY2dZXboYa+bFN2mSDJTZ8w+2pKDMGRsxw
# dy+DN8mu4nNIjA0o15GRI9hrwqUjLhNDVcrowhVbvqopKwGSBLiurkLkPomQJqLy
# 06Fl7yCjbwLq2WChIAMulV/H3khLSctIh8edFVC/fWo4osfW0km7OLYmMZtp85Zc
# XAmKNIt4z9C1zy7csoVG6qctZ706E7Ha0CPGm3AulPyXAniP2rEm3rmqySGJaOsy
# v8Uoo0V98XRnxWs4Tlz8qblIbBhGRxLeSWWBVVGuD4xWPecnk3Kdrli2y70=
# SIG # End signature block
