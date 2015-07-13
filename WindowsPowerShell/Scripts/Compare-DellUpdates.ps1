#Requires -version 2
#Author: Nathan Linley
#Script: Computer-DellUpdates
#Site: http://myitpath.blogspot.com
#Date: 2/9/2012

param(
	[parameter(mandatory=$true)][ValidateScript({test-path $_ -pathtype 'leaf'})][string]$catalogpath,
	[parameter(mandatory=$true,ValueFromPipeline=$true)][string]$server
)

function changedatacase([string]$str) {
	#we need to change things like this:  subDeviceID="1f17" to subDeviceID="1F17"
	#without changing case of the portion before the =
	if ($str -match "`=`"") {
		$myparts = $str.split("=")
		$result = $myparts[0] + "=" + $myparts[1].toupper()
		return $result
	} else { return $str}
}

$catalog = [xml](get-Content $catalogpath)
$oscodeid = &{
	$caption = (Get-WmiObject win32_operatingsystem -ComputerName $server).caption
	if ($caption -match "2003") {
		if ($caption -match "x64") { "WX64E" } else { "WNET2"}
	} elseif ($caption -match "2008 R2") { 
		"W8R2" 
	} elseif ($caption -match "2008" ) {
		if ($caption -match "x64") { 
			"WSSP2" 
		} else {
			"LHS86"
		} 
	}
}
write-debug $oscodeid

$systemID = (Get-WmiObject -Namespace "root\cimv2\dell" -query "Select Systemid from Dell_CMInventory" -ComputerName $server).systemid
$model = (Get-WmiObject -Namespace "root\cimv2\dell" -query "select Model from Dell_chassis" -ComputerName $server).Model
$model = $model.replace("PowerEdge","PE").replace("PowerVault","PV").split(" ") #model[0] = Brand Prefix  #model[1] = Model #

$devices = Get-WmiObject -Namespace "root\cimv2\dell" -Class dell_cmdeviceapplication -ComputerName $server
foreach ($dev in $devices) {
	$xpathstr = $parts = $version = ""
	if ($dev.Dependent -match "(version=`")([A-Z\d.-]+)`"") { $version = $matches[2] } else { $version = "unknown" }
	$parts = $dev.Antecedent.split(",")
	for ($i = 2; $i -lt 6; $i++) {
		$parts[$i] = &changedatacase $parts[$i]
	}
	$depparts = $dev.dependent.split(",")
	$componentType = $depparts[0].substring($depparts[0].indexof('"'))
	Write-Debug $parts[1]
	if ($dev.Antecedent -match 'componentID=""') {
		$xpathstr = "//SoftwareComponent[@packageType='LWXP']/SupportedDevices/Device/PCIInfo"
		if ($componentType -match "DRVR") {
			$xpathstr += "[@" + $parts[2] + " and @" + $parts[3] + "]/../../.."
			$xpathstr += "/SupportedOperatingSystems/OperatingSystem[@osVendor=`'Microsoft`' and @osCode=`'" + $osCodeID + "`']/../.."
		} else {
			$xpathstr += "[@" + $parts[2] + " and @" + $parts[3] + " and @" + $parts[4] + " and @" + $parts[5] + "]/../../.."
			#$xpathstr += "/SupportedSystems/Brand[@prefix=`'" + $model[0] + "`']/Model[@systemID=`'" + $systemID + "`']/../../.."
			$xpathstr += "/ComponentType[@value='FRMW']/.."

		}
		$xpathstr += "/ComponentType[@value=" + $componentType + "]/.."
	} else {
		$xpathstr = "//SoftwareComponent[@packageType='LWXP']/SupportedDevices/Device[@" 
		$xpathstr += $parts[0].substring($parts[0].indexof("componentID"))
		$xpathstr += "]/../../SupportedSystems/Brand[@prefix=`'" + $model[0] + "`']/Model[@systemID=`'"
		$xpathstr += $systemID + "`']/../../.."
	}
	Write-Debug $xpathstr

	$result = Select-Xml $catalog -XPath $xpathstr |Select-Object -ExpandProperty Node
	$result |Select-Object @{Name="Component";Expression = {$_.category.display."#cdata-section"}},path,vendorversion,@{Name="currentversion"; Expression = {$version}},releasedate,@{Name="Criticality"; Expression={($_.Criticality.display."#cdata-section").substring(0,$_.Criticality.display."#cdata-section".indexof("-"))}},@{Name="AtCurrent";Expression = {$_.vendorVersion -eq $version}}
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULcZRr1OkluwVJJA6uPvT84MI
# vH6gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFNONfISZzRRXtiJv
# +LQLvkbintuvMA0GCSqGSIb3DQEBAQUABIIBAJEYF/Ld92bFWCH/qs5PbXVNF2Ge
# Qh3jxG6zatSS5XgrJ9meTpyzVntktdOq8HPynhyeQseMSikaI9URMRg+TKvMiSo8
# fM8LJ5DxvjiXFzMZ++sEHh1XTvq2Vxe2aSCN0kMcRxpTEmjKQJ+ecL42h9rJA5uG
# zq3MYa9lGHQXRf5EBCKWsyIPUwlmWGp4nCGTskV0CbwZ+v4UMzMtSTNK/SW4ZXT4
# iZkpnmu1s2j17MwF4B1s5UcEbnSYOYWk3qpIPAajrsNajChsk2Wy8OicwN+6zymi
# mFCes2Vhc5SElvJJzZxB6BIvH2ymQyr5K4irHUdqAXPRciFGa3Utd7zWzlw=
# SIG # End signature block
