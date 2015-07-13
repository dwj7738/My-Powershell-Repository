## =====================================================================
## Title       : Set-SPItem
## Description : Modifies an SP Item
## Author      : Idera
## Date        : 24/11/2009
## Input       : Set-SPItem [[-url] <String>] [[-List] <String>] [[-Field] <String>] [[-Item] <String>] [[-Values] <String>]
## Output      : 
## Usage       : Set-SPItem -url http://moss -List Users -Field Title -Item "My Item" -Values "Description=Hello,MultipleChoice=First;Second,Lookup=LookupItem"
## Notes       : Sets The Item "My Item" from the Users List Where the Title field is equal to "My Item"
##             : When Adding Multiple Choice or Lookup Fields, use a ; to Separate the Choices.
##               Adapted From Niklas Goude Script
## Tag         : Item, Sharepoint, Powershell
## Change log  :
## =====================================================================

param (

   [string]$url = "$(Read-Host 'url [e.g. http://moss]')", 
   [string]$List = "$(Read-Host 'List Name [e.g. My List]')",
   [string]$Field = "$(Read-Host 'Field To match Item With [e.g. Title]')",
   [string]$Item = "$(Read-Host 'Item Name [e.g. First Item]')",
   [string]$Values = "$(Read-Host 'Item Values [e.g. Description=Hello,Choice=First Choice]')"
)

function main() {

	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

	$HashValues = @{}
	$Values.Split(",") | ForEach { $HashValues.Add($_.Split("=")[0],$_.Split("=")[1]) }
	
	Set-SPItem -url $url -List $List -Item $Item -Field $Field -Values $HashValues
}

function Get-SPSite([string]$url) {

	New-Object Microsoft.SharePoint.SPSite($url)
}

function Get-SPWeb([string]$url) {

	$SPSite = Get-SPSite $url
	return $SPSite.OpenWeb()
	$SPSite.Dispose()
}

function Set-SPItem([string]$url, [string]$List, [string]$Item, [string]$Field, [HashTable]$Values) {

	$OpenWeb = Get-SPWeb $url
	$OpenList = $OpenWeb.Lists[$List]

	if($OpenList.Items | Where { $_[$Field] -eq $Item }) {
		$OpenItem = $OpenList.Items | Where { $_[$Field] -eq $Item }

		$Values.Keys | ForEach {
	
			$FieldName = $_
			$Value = $Values[$_]
	
			Switch($OpenList.Fields[$FieldName].TypeDisplayName) {
	
				{ $_ -eq "Lookup" } {
	
					if($OpenList.Fields[$FieldName].LookupField -eq $Null) { $LookupField = "Title" } else { $LookupField = $OpenList.Fields[$FieldName].LookupField }
					$LookupGUID = (($OpenList.Fields[$FieldName].LookupList).Replace("{","")).Replace("}","")
					$LookupList = $OpenWeb.Lists | Where { $_.ID -match $LookupGUID }
	
					if($OpenList.Fields[$FieldName].AllowMultipleValues -eq $True) {
						$SplitValues = $Value.Split(";")
						foreach ($SplitValue in $SplitValues) {
							$SplitValue = ($SplitValue.TrimStart()).TrimEnd()
							$LookupItems = ($LookupList.Items | Where { $_[$LookupField] -eq $SplitValue } | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name + ";#" } }).Item
							$AddValue += $LookupItems
	
						}
					} else {
						$AddValue = ($LookupList.Items | Where { $_[$LookupField] -eq $Value } | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name} }).Item
					}
				}
	
				{ $_ -eq "Choice" } {
	
					if($OpenList.Fields[$FieldName].FieldValueType.Name -eq "SPFieldMultiChoiceValue") {
						$AddValue = New-Object Microsoft.SharePoint.SPFieldMultiChoiceValue
						$SplitValues = $Value.Split(";")
	
						foreach($SplitValue in $SplitValues) {
							$SplitValue = ($SplitValue.TrimStart()).TrimEnd()
							$AddValue.Add($SplitValue)
						}
					} else {
						$AddValue = [string]$Value
					}
				}
	
				{ $_ -eq "Currency" } {
					$AddValue = [Double]$Value
				}
	
				{ $_ -eq "Number" } {
					$AddValue = [Double]$Value
				}
	
				{ $_ -eq "Date and Time" } {
					$AddValue = [DateTime]$Value
				}
	
				{ $_ -eq "Yes/No" } {
					if($Value -eq "Yes") { $AddValue = [bool]$True } else { $AddValue = [bool]$False }
				}
	
				{ $_ -eq "Hyperlink or Picture" } {
					$AddValue = [string]$Value.Replace(";",",")
				}
	
				{ $_ -eq "Single line of text" } {
					$AddValue = [string]$Value
				}
	
				{ $_ -eq "Multiple lines of text" } {
					$AddValue = [string]$Value
				}
	
				{ $_ -eq "Person or Group" } {
					if($OpenList.Fields[$FieldName].AllowMultipleValues -eq $True) {
						$SplitValues = $Value.Split(";")
						foreach($SplitValue in $SplitValues) {
							$SplitValue = ($SplitValue.TrimStart()).TrimEnd()
							if($SplitValue -match "$env:USERDOMAIN\\") {
								$GetItem = ($OpenWeb.AllUsers[$SplitValue] | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name + ";#"} }).Item
							} else {
								$GetItem = ($OpenWeb.Groups[$SplitValue] | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name + ";#"} }).Item
							}
							$AddValue += $GetItem
						}
					} else {
						if($Value -match "$env:USERDOMAIN\\") {
							$GetItem = ($OpenWeb.AllUsers[$Value] | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name } }).Item
						} else {
							$GetItem = ($OpenWeb.Groups[$Value] | Select @{Name="Item";Expression={[string]$_.ID + ";#" + $_.Name } }).Item
						}
						$AddValue = $GetItem
					}
				}
				Default { Write-Host ”Item Unknown” }
			}
	
			$OpenItem[$FieldName] = $AddValue
	
			$AddValue = $Null
			$SplitValue = $Null
			$SplitValues = $Null
		}

	} else {

		Write-Host "$($Item) Not Found" -ForeGroundColor Red
	}
	
	$OpenItem.Update()
	$OpenWeb.Dispose()
}
	
main
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUCK8S/VqVAkzNwGyaMxHMMgg
# JWagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJzHYqOMc4BXwYDB
# cp3pd/xJTJyBMA0GCSqGSIb3DQEBAQUABIIBAFBYS73uvRj4XU7jWYR2p/KYNhYg
# HGjX96KeR3AmM0tqlROlyANnmTQIm6Sxb/gIeJYqOopfdhKt0qjGDYeuUcIBNMIg
# ksQOqWOoGI6DCYa9guIFQiWquOk35tCD1FQ72QnY+i67nPTuWzowIwkm33l2cLeW
# +qw6CbZoL6uueiB1nwlxEoK1ziTrFICqPGlP9Hpd3YxdFrjGCq7r42bmSq2CfKFf
# 05wAua7Ln5jQWkTVwZkO7zjaZIH43eY8XTPy5TlpIM2jDpl6ajHUbaT+x1lOg9ez
# 3QRXMYqiZ0dwvIo16kyTcIbR/vruKlKdDYKvRKveXX2EajTIhh8AR7pzp6s=
# SIG # End signature block
