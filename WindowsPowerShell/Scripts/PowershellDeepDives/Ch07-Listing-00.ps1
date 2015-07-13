function Get-RequestRow {
[CmdletBinding()]
	param(
		[string]$ConfigString,
		[ValidateSet('Revoked','Issued','Pending','Failed')]
		[string]$Status,
		[String[]]$Filter,
		[String[]]$Property
	)
	$CaView = New-Object -ComObject CertificateAuthority.View
	$CaView.OpenConnection($ConfigString)
	# Retrieve "Disposition" column index to use it in filters.
	$RColumn = $CaView.GetColumnIndex(0, "Disposition")
# process certificate request status
	switch ($Status) {
		# Revoked certificates are identified by Disposition = 21
		"Revoked" {$CaView.SetRestriction($RColumn,1,0,21)}
		# Issued certificates are identified by Disposition = 20
		"Issued" {$CaView.SetRestriction($RColumn,1,0,20)}
		# there are default restriction tables for pending and failed requests.
		"Pending" {$CaView.SetRestriction(–1,0,0,0)}
		"Failed" {$CaView.SetRestriction(-3,0,0,0)}
	}
# determine if a caller has specified custom filters
	if ($Filter -ne $null) {
		# loop over each filter passed by a caller
		foreach ($line in $Filter) {
			# split each line to 3 tokens: column name, operator and column value
			if ($line -match "^(.+)\s(-eq|-lt|-le|-ge|-gt)\s(.+)$") {
				# get column index
				try {$Rcolumn = $CaView.GetColumnIndex($false, $matches[1])}
				catch {Write-Warning "Specified column '$($matches[1])' does not exist!"; return}
				# convert operator to its numerical value
				$Seek = switch ($matches[2]) {
					"-eq" {1}
					"-lt" {2}
					"-le" {4}
					"-ge" {8}
					"-gt" {16}
				}
				# assign value to a variable. This step is necessary to perform
				# value transformation
				$Value = $matches[3]
				# attempt to cast value to integer. We have to use '-as' operator as
				# it does not throw exceptions if conversion fails. Additionally we must
				# determine whehter the converted value is '[int]'. This is because
				# if the value is successfully converted to a zero, IF key word will
				# threat it as False and do not succeed. And the last note: do not use
				# explicit cast like this: [int]$Value = $Value, because if subsequent
				# filter values are not integers, value assignment fails.
				if (($Value -as [int]) -is [int]) {$Value = $Value -as [int]}
				# if conversion to '[int]' fails, attempt to convert value to date time
				else {
					# to avoid unnecessary exceptions, put the code in try/catch block
					try {
						$dt = [DateTime]::ParseExact(
							$Value,
							"MM/dd/yyyy HH:mm:ss",
							[Globalization.CultureInfo]::InvariantCulture
						)
						if ($dt -ne $null) {$Value = $dt}
					} catch {}
				}
				# if conversion still fails, then the value is a simple string.
				# Internally certificate templates are stored in their OID values.
				# to allow callers to specify template display names, we convert
				# value to Oid object and retrieve Oid value.
				if ($matches[1] -eq "CertificateTemplate") {
					if (([Security.Cryptography.Oid]$Value).FriendlyName) {
						$Value = ([Security.Cryptography.Oid]$Value).Value
					}
				}
				# attempt to set filters
				try {$CaView.SetRestriction($RColumn,$Seek,0,$Value)}
				catch {Write-Warning "Specified pattern '$line' is not valid!"; return}
			} else {Write-Warning "Malformed pattern: '$line'.!"; return}
		}
	}
# set output columns
	# check if a caller selected all properties
	if ($Property -contains "*") {
		$ColumnCount = $CaView.GetColumnCount(0)
		$CaView.SetResultColumnCount($ColumnCount)
		0..($ColumnCount - 1) | ForEach-Object {$CaView.SetResultColumn($_)}
	} else {
		# define default properties for each request status
		$properties = switch ($Status) {
			"Revoked" {"RequestID","Request.RevokedWhen","Request.RevokedReason","CommonName","SerialNumber"}
			"Issued" {"RequestID","Request.RequesterName","CommonName","NotBefore","NotAfter","SerialNumber"}
			"Pending" {"RequestID","Request.RequesterName","Request.SubmittedWhen","Request.CommonName","CertificateTemplate"}
			"Failed" {"RequestID","Request.StatusCode","Request.DispositionMessage","Request.SubmittedWhen","Request.CommonName","CertificateTemplate"}
		}
		# append user-defined columns to default column view and select unique columns
		$properties = $properties + $Property | Select-Object -Unique | Where-Object {$_}
		# specify how many columns to return
		$CaView.SetResultColumnCount($properties.Count)
		# specify exact column indexes to return
		$properties | ForEach-Object {$CaView.SetResultColumn($CaView.GetColumnIndex(0, $_))}
	}
# process search routine
	$Row = $CaView.OpenView()
	while ($Row.Next() -ne -1) {
		# create custom psobject to store current row
		$cert = New-Object psobject -Property @{
			# it is recommended to set ConfigString property for future calls
			ConfigString = $ConfigString;
		}
		# start column enumeration
		$Column = $Row.EnumCertViewColumn()
		# loop over each column
		while ($Column.Next() -ne -1) {
			$current = $Column.GetName()
			# we use $Column.GetName() to get column name and $Column.GetValue(1) to get column value for the
			# current row
			$Cert | Add-Member -MemberType NoteProperty $($Column.GetName()) -Value $($Column.GetValue(1)) -Force
			# if the certificate template property is selected, the value can be returned either as a string
			# (for version 1 templates) or template OID value (for other template versions)
			if ($Cert.CertificateTemplate -match "^(\d\.){3}") {
				$cert.CertificateTemplate = ([Security.Cryptography.Oid]$Column.GetValue(1)).FriendlyName
			}
		}
		# pass current row object to pipeline
		$Cert
	}
	# remove ICertView-related variable to free resources
	Remove-Variable Row, Column, CaView
	[GC]::Collect()
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9z1GyFp+O8d6f6DZLOLI9jxx
# XTOgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKPvP8y4RFV819Ve
# Kyx9Z7vszyY5MA0GCSqGSIb3DQEBAQUABIIBAKvV2GpaOVpKMRYVhLcnZUlOzhNN
# 6SF5cHpokCM9qjJ5MtpUVkFQ/zGvjZgQXg2+0Eo0yjS0IxHnVB0iZptSeBt5H1v4
# GqgTpuiMgVHuAm0/FKbWxGiWe9lqFHFwSucrI2pZGBsvYwPD9wZyVHcGe62VgVGo
# 67IE09EcATC9eevvLr577EuuZklWUFnHBGTZAFgKmtD2qAzMTTddsOz0qkGUDdXo
# yGhvbA0G8TcORQ6bIJeHIqRbnRM7bIvlqsuDStVICngFRXKvhtL3KCB04UU8AcIU
# 5AkY495aYJzV2NML6DuQlLjzICNZSzOleB8bfQa8zMnqC6kqr1xWBf5R3Lc=
# SIG # End signature block
