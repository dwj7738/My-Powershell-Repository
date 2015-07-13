param(
[parameter(Mandatory=$true)]
[String]$ServerName,
[parameter(Mandatory=$true)]
[String]$SiteCode
)

# Set the schedules first!
#Array containing 24 elements, one for each hour of the day. A value of true indicates that the address (sender) embedding SMS_SiteControlDaySchedule can be used as a backup.
$UsageAsBackup = @($true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true,$true)
#Array containing 24 elements, one for each hour of the day. This property specifies the type of usage for each hour.
# 1 means all Priorities, 2 means all but low, 3 is high only, 4 means none
$HourUsageSchedule = @(4,4,4,4,4,4,4,4,4,4,4,1,4,4,4,4,4,4,4,4,4,4,4,2)
#Set RateLimitingSchedule, array for every hour of the day, percentage of how much bandwidth can be used, min 1, max 100
$RateLimitingSchedule = @(100,20,30,40,50,60,70,80,90,100,90,80,70,60,50,40,30,20,10,70,10,20,30,90)

$SMS_SCI_ADDRESS = "SMS_SCI_ADDRESS"
$class_SMS_SCI_ADDRESS = [wmiclass]""
$class_SMS_SCI_ADDRESS.psbase.Path ="ROOT\SMS\Site_$($SiteCode):$($SMS_SCI_ADDRESS)"

$SMS_SCI_ADDRESS = $class_SMS_SCI_ADDRESS.CreateInstance()

# Set the UsageSchedule
$SMS_SiteControlDaySchedule           = "SMS_SiteControlDaySchedule"
$SMS_SiteControlDaySchedule_class     = [wmiclass]""
$SMS_SiteControlDaySchedule_class.psbase.Path = "ROOT\SMS\Site_$($SiteCode):$($SMS_SiteControlDaySchedule)"
$SMS_SiteControlDaySchedule	          = $SMS_SiteControlDaySchedule_class.createInstance()
$SMS_SiteControlDaySchedule.Backup    = $UsageAsBackup
$SMS_SiteControlDaySchedule.HourUsage = $HourUsageSchedule
$SMS_SiteControlDaySchedule.Update    = $true
$SMS_SCI_ADDRESS.UsageSchedule        = @($SMS_SiteControlDaySchedule,$SMS_SiteControlDaySchedule,$SMS_SiteControlDaySchedule,$SMS_SiteControlDaySchedule,$SMS_SiteControlDaySchedule,$SMS_SiteControlDaySchedule,$SMS_SiteControlDaySchedule)

$SMS_SCI_ADDRESS.RateLimitingSchedule = $RateLimitingSchedule

$SMS_SCI_ADDRESS.AddressPriorityOrder = "0"
$SMS_SCI_ADDRESS.AddressType          = "MS_LAN"
$SMS_SCI_ADDRESS.DesSiteCode          = "$($ServerName)"
$SMS_SCI_ADDRESS.DestinationType      = "1"
$SMS_SCI_ADDRESS.SiteCode             = "$($SiteCode)"
$SMS_SCI_ADDRESS.UnlimitedRateForAll  = $false

# Set the embedded Properties
$embeddedpropertyList = $null
$embeddedproperty_class = [wmiclass]""
$embeddedproperty_class.psbase.Path = "ROOT\SMS\Site_$($SiteCode):SMS_EmbeddedPropertyList"
$embeddedpropertyList 				= $embeddedproperty_class.createInstance()
$embeddedpropertyList.PropertyListName 	= "Pulse Mode"
$embeddedpropertyList.Values		= @(0,5,8) #second value is size of data block in KB, third is delay between data blocks in seconds
$SMS_SCI_ADDRESS.PropLists += $embeddedpropertyList

$embeddedproperty = $null   
$embeddedproperty_class = [wmiclass]""
$embeddedproperty_class.psbase.Path = "ROOT\SMS\Site_$($SiteCode):SMS_EmbeddedProperty"
$embeddedproperty 				= $embeddedproperty_class.createInstance()
$embeddedproperty.PropertyName 	= "Connection Point"
$embeddedproperty.Value 		= "0"
$embeddedproperty.Value1		= "$($ServerName)"
$embeddedproperty.Value2		= "SMS_DP$"		
$SMS_SCI_ADDRESS.Props += $embeddedproperty

$embeddedproperty = $null
$embeddedproperty_class = [wmiclass]""
$embeddedproperty_class.psbase.Path = "ROOT\SMS\Site_$($SiteCode):SMS_EmbeddedProperty"
$embeddedproperty 				= $embeddedproperty_class.createInstance()
$embeddedproperty.PropertyName 	= "LAN Login"
$embeddedproperty.Value 		= "0"
$embeddedproperty.Value1		= ""
$embeddedproperty.Value2		= ""		
$SMS_SCI_ADDRESS.Props += $embeddedproperty


$SMS_SCI_ADDRESS.Put() | Out-Null

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUySOQsCvbB+MUUj8pvD/sKbAA
# 1sqgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHoowDuUIGCXeWK9
# sbNgsza/++3VMA0GCSqGSIb3DQEBAQUABIIBADcWjQq+YikHyt0sDoNCzdYzntI0
# p+pElBfwT9z5QYAvUpUVYQSSz28ZME0Ta+2yYY2t2SvVFrf03sjxpTeTys1ww8jg
# ZnLuCpQ3DzViFExnuoIR7RY9PtbzBScW3hzjgZl/xd451QNiByZ6/1pg+OlUfUDJ
# iJNRlFw0d/kwx7OZR1D36bmB28NuqDrOdfw/D6tSx+pZZrikUodrSZ9tBAGcbm4v
# 9hmjZAk4MbhpPCiXpYrti1xYLI81cnjRyFrt3nNNkLd6a4K4J7Z83et+juKyJYJs
# +7QdKbCJhZqbahyRatzh6KxSZBApaz9ND+/m2OzyQiF/fqzcWi57qovd2Uc=
# SIG # End signature block
