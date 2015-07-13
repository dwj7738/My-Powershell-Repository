# ------------------------------------------------------------------
# Title: Hardware Inventory Using PowerShell
# Author: Aman Dhally
# Description: Hi,The basic idea of this script to find the Part Number and Serial Number of installed hardwares. For example serial Number of Harddisk, Physical ram , Cd drives.In my enviornmnet i want that this script should reside on Users Laptop/desktop. and create a batch file to call this
# Date Published: 05-Mar-2012 2:10:39 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Hardware-Inventory-Using-fe6611e0
# Tags: Hardware Information;Hardware inventory;aman dhally
# Rating: 3.75 rated by 4
# ------------------------------------------------------------------

<#
			"SatNaam WaheGuru"

Date: 03:03:2012, 18:20PM
Author: Aman Dhally
Email:  amandhally@gmail.com
web:	www.amandhally.net/blog
blog:	http://newdelhipowershellusergroup.blogspot.com/
More Info : 

Version : 1

	/^(o.o)^\ 


#>



$name = (Get-Item env:\Computername).Value
$filepath = (Get-ChildItem env:\userprofile).value

## Email Setting

$smtp = "Your-ExchangeServer"
$to = "YourIT@YourDomain.com"
$subject = "Hardware Info of $name"
$attachment = "$filepath\$name.html"
$from =  (Get-Item env:\username).Value + "@yourdomain.com"




#### HTML Output Formatting #######

$a = "<style><!--mce:0--></style>"

###############################################



#####

ConvertTo-Html -Head $a  -Title "Hardware Information for $name" -Body "<h1> Computer Name : $name </h1>" >  "$filepath\$name.html" 

# MotherBoard: Win32_BaseBoard # You can Also select Tag,Weight,Width 
Get-WmiObject -ComputerName $name  Win32_BaseBoard  |  Select Name,Manufacturer,Product,SerialNumber,Status  | ConvertTo-html  -Body "<H2> MotherBoard Information</H2>" >> "$filepath\$name.html"

# Battery 
Get-WmiObject Win32_Battery -ComputerName $name  | Select Caption,Name,DesignVoltage,DeviceID,EstimatedChargeRemaining,EstimatedRunTime  | ConvertTo-html  -Body "<H2> Battery Information</H2>" >> "$filepath\$name.html"

# BIOS
Get-WmiObject win32_bios -ComputerName $name  | Select Manufacturer,Name,BIOSVersion,ListOfLanguages,PrimaryBIOS,ReleaseDate,SMBIOSBIOSVersion,SMBIOSMajorVersion,SMBIOSMinorVersion  | ConvertTo-html  -Body "<H2> BIOS Information </H2>" >> "$filepath\$name.html"

# CD ROM Drive
Get-WmiObject Win32_CDROMDrive -ComputerName $name  |  select Name,Drive,MediaLoaded,MediaType,MfrAssignedRevisionLevel  | ConvertTo-html  -Body "<H2> CD ROM Information</H2>" >> "$filepath\$name.html"

# System Info
Get-WmiObject Win32_ComputerSystemProduct -ComputerName $name  | Select Vendor,Version,Name,IdentifyingNumber,UUID  | ConvertTo-html  -Body "<H2> System Information </H2>" >> "$filepath\$name.html"

# Hard-Disk
Get-WmiObject win32_diskDrive -ComputerName $name  | select Model,SerialNumber,InterfaceType,Size,Partitions  | ConvertTo-html  -Body "<H2> Harddisk Information </H2>" >> "$filepath\$name.html"

# NetWord Adapters -ComputerName $name
Get-WmiObject win32_networkadapter -ComputerName $name  | Select Name,Manufacturer,Description ,AdapterType,Speed,MACAddress,NetConnectionID |  ConvertTo-html  -Body "<H2> Nerwork Card Information</H2>" >> "$filepath\$name.html"

# Memory
Get-WmiObject Win32_PhysicalMemory -ComputerName $name  | select BankLabel,DeviceLocator,Capacity,Manufacturer,PartNumber,SerialNumber,Speed  | ConvertTo-html  -Body "<H2> Physical Memory Information</H2>" >> "$filepath\$name.html"

# Processor 
Get-WmiObject Win32_Processor -ComputerName $name  | Select Name,Manufacturer,Caption,DeviceID,CurrentClockSpeed,CurrentVoltage,DataWidth,L2CacheSize,L3CacheSize,NumberOfCores,NumberOfLogicalProcessors,Status  | ConvertTo-html  -Body "<H2> CPU Information</H2>" >> "$filepath\$name.html"

## System enclosure 

Get-WmiObject Win32_SystemEnclosure -ComputerName $name  | Select Tag,AudibleAlarm,ChassisTypes,HeatGeneration,HotSwappable,InstallDate,LockPresent,PoweredOn,PartNumber,SerialNumber  | ConvertTo-html  -Body "<H2> System Enclosure Information </H2>" >> "$filepath\$name.html"

## Invoke Expressons

invoke-Expression "$filepath\$name.html"


#### Sending Email

Send-MailMessage -To $to -Subject $subject -From $from  $subject -SmtpServer $smtp -Priority "High" -BodyAsHtml -Attachments "$filepath\$name.html" 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUn/GuzTCFKsySAFvKQ7EwPVuk
# m6agggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAazEnlzVbhkJzFf
# vuoJo7HMgxF+MA0GCSqGSIb3DQEBAQUABIIBAKXap9pwNQOr6M1Sh+Rhm/OsBIjB
# bY5nMRnVcfvbo/PEehRiMCqrP+RFQOD8uZWGIDomDCdHj6LwRiNf973u1TBvFiOU
# vRyUB8B27r+0lGOyXxILdoN5oGbYSHDky/aMvg7OojEiXUTq0MyY+lw33RYxxs0N
# SrrZ7afeVX0S+8MIVsb2dkpDfy43mkEpHLqHMla8MIaK5oUJukLlvVzezFcUbJin
# aDW9aAz7qHb0L28U0jzcZ/8VbOOtJf/MIj6juLxUIqVNulJlI5xsX4g52aD8BwxH
# G1oZqmYP/JAXjlsRj+CQP1HvMMu9soQRFYjcAAUIVt13RGPi1zZx8Xjmhps=
# SIG # End signature block
