## scraping method for ajax driven websites. in this example, google marketplace is the target.
## requires: watin, htmlagilitypack
##     http://watin.org/
##     http://htmlagilitypack.codeplex.com/
## this scripts directs watin to gunbros and angry birds product pages and htmlagility is used to scrape user reviews

$rootDir = "C:\Users\khtruong\Desktop\android review scrape"
$WatiNPath = "$rootDir\WatiN.Core.dll"
$HtmlAgilityPath = "$rootDir\HtmlAgilityPack.dll"

[reflection.assembly]::loadfrom( $WatiNPath )
[reflection.assembly]::loadfrom( $HtmlAgilityPath )

$ie = New-Object Watin.Core.IE

## application identifiers on android market.
$packages = @("com.glu.android.gunbros_free", "com.rovio.angrybirds")

$global:reviews = @()

foreach($package in $packages){
	$ie.Goto("https://market.android.com/details?id=$package")
	$ie.WaitForComplete(300)

	## clicks Read All User Reviews link
	$($ie.Links | ?{$_.ClassName -eq "tabBarLink"}).Click()

	## clicks the Sort By menu
	$($($ie.Divs | ?{$_.ClassName -eq "reviews-sort-menu-container goog-inline-block"}).Divs | ?{$_.ClassName -eq "goog-inline-block selected-option"}).ClickNoWait()

	## selects Newest option from the Sort By menu
	$($($($ie.Divs | ?{$_.ClassName -eq "reviews-menu"}).Divs | ?{$_.ClassName -eq "goog-menuitem-content"})[0]).ClickNoWait()

	$lastPage = $false
	## selects the page forward button
	$nextButton = $($ie.Divs | ?{$_.ClassName -eq "num-pagination-page-button num-pagination-next goog-inline-block"})

	## clicks through all 48 pages of review. review data isn't visibile in page source until a page is loaded.
	$count = 1

	while($count -lt 49){
		write-host $count
		$nextButton.Click()
		## make sure data is properly loaded before continuing to the next page
		Sleep 1
		$count++
	}

	## get html page source
	$result = $ie.Html

	$doc = New-Object HtmlAgilityPack.HtmlDocument 

	$doc.LoadHtml($result)

	$reviewSize = $($doc.DocumentNode.SelectNodes("//div[@class='doc-review']")).length

	$reviews += @(for($counter = 0; $counter -lt $reviewSize; $counter++){
			if($($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[-1]).ChildNodes[3].ChildNodes | %{$_.Attributes | ?{$_.Name -eq "href"}}).Value -ne $null){
				Write-Host "($counter / $reviewSize)" -fore Yellow
				$PackageName = $($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[3].ChildNodes | %{$_.Attributes | ?{$_.Name -eq "href"}}).Value.Split("=&")[1]
				$ReviewID = $($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[3].ChildNodes | %{$_.Attributes | ?{$_.Name -eq "href"}}).Value.Split("=&")[-1]
				Write-Host "$ReviewID"
			}

			## Author
			if($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[0].InnerText -ne $null){
				$Author = $($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[0].InnerText
			}
			else{
				$Author = "Unknown"
			}

			## Review Date
			if($($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[1].InnerText).Replace(" on ","").Trim() -ne $null){
				$Date = $($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[1].InnerText).Replace(" on ","").Trim()
			}
			else{
				$Date = "Unknown"
			}

			## Handset
			if($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[2].InnerText -like "*with*"){
				$Handset = $($($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[2].InnerText).Trim().replace("with","|").Split("|")[0]).Replace("(","").trim()
			}
			else{
				$Handset = "Unknown"
			}

			## Version
			if($($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[2].InnerText).Trim().Split(" ")[-1].replace(")","").Trim() -ne $null){
				$Version = $($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[2].InnerText).Trim().Split(" ")[-1].replace(")","").Trim()
			}
			else{
				$Version = "Unknown"
			}

			## Rating
			if($($($($($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[4]).ChildNodes) | %{$_.Attributes | ?{$_.Name -eq "Title"}}).Value) -ne $null){
				$Rating = [Int]$($($($($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[4]).ChildNodes) | %{$_.Attributes | ?{$_.Name -eq "Title"}}).Value).Split(" ")[1]

				if($Rating -lt 3){
					$Flag = "Critical"
				}
				else{
					$Flag = ""
				}

			}
			else{
				$Rating = "Unknown"
			}

			## Title
			if($($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[4].InnerText) -ne $null){
				$Title = $($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[4].InnerText)
			}
			else{
				$Title = "Review title not given."
			}

			## Review
			if($($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[5].InnerText) -ne "&nbsp;"){
				$Review = $($($($doc.DocumentNode.SelectNodes("//div[@class='doc-review']"))[$counter]).ChildNodes[5].InnerText)
			}
			else{
				$Review = "User did not write a review."
			}

			New-Object psobject -Property @{
				PackageName = $PackageName
				ReviewID = $ReviewID
				Author = $Author
				Date = $Date
				Handset = $Handset
				Version = $Version
				Rating = $Rating
				Title = $Title
				Review = $Review
				Flag = $Flag
			}
		})
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjv1JRPDmhDTjNvJA2/T2+50r
# 0M2gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFP0DisurRl6JXXel
# jlmub1WD+oBMMA0GCSqGSIb3DQEBAQUABIIBADssf9KDii2JpxxHny/Lm/kn4ArO
# BxJ6mGW8klRkytCx0ye8F/1s7Bk70HGNcW3Z3H9yF9VrYm6VpU2GsNgB9Yp7R2Ch
# xeNDm3WN+i4qYvsK1ZjvdDfw/wZNnpPTNV1TXZ5D6uZB2gUfo/Hx2vz3d4po/W5q
# Q3YLe1IQqckb5bwiSKjJ26+iVy2i7/Wcd284aYXzoSCM9Fy/XyiRFsFyonj569tE
# Ly/myHfdCMD921q3n1qSkuEzi0mAJWp14yqdChhM3z3pa9wOppK+w66LhCURsN8U
# xjpQ5EZBXKyX7Qyn057s2s+TK0aYUZrvRhLTIlxRHGM4S4GqOjcaWFA4+vg=
# SIG # End signature block
