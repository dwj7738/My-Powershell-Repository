Function Test-Server{
	[cmdletBinding()]
	param(
		[parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string[]]$ComputerName,
		[parameter(Mandatory=$false)]
		[switch]$CredSSP,
		[Management.Automation.PSCredential] $Credential)

	begin{
		$total = Get-Date
		$results = @()
		if($credssp){if(!($credential)){Write-Host "must supply Credentials with CredSSP test";break}}
	}
	process{
		foreach($name in $computername)
		{
			$dt = $cdt = Get-Date
			Write-verbose "Testing: $Name"
			$failed = 0
			try{
				$DNSEntity = [Net.Dns]::GetHostEntry($name)
				$domain = ($DNSEntity.hostname).replace("$name.","")
				$ips = $DNSEntity.AddressList | %{$_.IPAddressToString}
			}
			catch
			{
				$rst = "" | select Name,IP,Domain,Ping,WSMAN,CredSSP,RemoteReg,RPC,RDP
				$rst.name = $name
				$results += $rst
				$failed = 1
			}
			Write-verbose "DNS:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
			if($failed -eq 0){
				foreach($ip in $ips)
				{

					$rst = "" | select Name,IP,Domain,Ping,WSMAN,CredSSP,RemoteReg,RPC,RDP
					$rst.name = $name
					$rst.ip = $ip
					$rst.domain = $domain
					####RDP Check (firewall may block rest so do before ping
					try{
						$socket = New-Object Net.Sockets.TcpClient($name, 3389)
						if($socket -eq $null)
						{
							$rst.RDP = $false
						}
						else
						{
							$rst.RDP = $true
							$socket.close()
						}
					}
					catch
					{
						$rst.RDP = $false
					}
					Write-verbose "RDP:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
					#########ping
					if(test-connection $ip -count 1 -Quiet)
					{
						Write-verbose "PING:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
						$rst.ping = $true
						try{############wsman
							Test-WSMan $ip | Out-Null
							$rst.WSMAN = $true
						}
						catch
						{							$rst.WSMAN = $false}
						Write-verbose "WSMAN:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
						if($rst.WSMAN -and $credssp) ########### credssp
						{
							try{
								Test-WSMan $ip -Authentication Credssp -Credential $cred
								$rst.CredSSP = $true
							}
							catch
							{								$rst.CredSSP = $false}
							Write-verbose "CredSSP:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
						}
						try ########remote reg
						{
							[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $ip) | Out-Null
							$rst.remotereg = $true
						}
						catch
						{							$rst.remotereg = $false}
						Write-verbose "remote reg:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)"
						try ######### wmi
						{
							$w = [wmi] ''
							$w.psbase.options.timeout = 15000000
							$w.path = "\\$Name\root\cimv2:Win32_ComputerSystem.Name='$Name'"
							$w | select none | Out-Null
							$rst.RPC = $true
						}
						catch
						{							$rst.rpc = $false}
						Write-verbose "WMI:  $((New-TimeSpan $dt ($dt = get-date)).totalseconds)" 
					}
					else
					{
						$rst.ping = $false
						$rst.wsman = $false
						$rst.credssp = $false
						$rst.remotereg = $false
						$rst.rpc = $false
					}
					$results += $rst 
				}}
			Write-Verbose "Time for $($Name): $((New-TimeSpan $cdt ($dt)).totalseconds)"
			Write-Verbose "----------------------------"
		}
	}
	end{
		Write-Verbose "Time for all: $((New-TimeSpan $total ($dt)).totalseconds)"
		Write-Verbose "----------------------------"
		return $results
	}
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmohJ5pXOMymChmB54fkODazy
# tzmgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJjSR0G/Ujca416U
# TRdabIw3df60MA0GCSqGSIb3DQEBAQUABIIBAEHBitEo7AyvsUprjbkv7m4bwY5w
# CtayVyIP1vOZGw3p4146H3uPUM3M6453rMF8JyONwpYE2zrPQ7BxkQzaGmGL3UI9
# 4INIzhfUV77X8mMkLjn0aijHFLVNv7Wp3wu68BNwqLD9qKKlkVJB19E0O8ihnfpF
# /IAb2ppRQFthqXEyoiaz+OROjgF+ToxSYEK+XSd4sKWDKxpwx3xRF3TrBkh1znIM
# W9eoTmNzFO2pMUGTxR3bcJZBhYJJP6358W71I31lIWKE+bTGKfBNjQkdXl14qY9a
# xnjd2CBRINJsohFTSnasQVfQveBlshdOMwkKnCLjavH/rSzr8kmfUMxbr8Q=
# SIG # End signature block
