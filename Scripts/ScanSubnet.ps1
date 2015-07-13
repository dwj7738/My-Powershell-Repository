#======================================================
#
#             	 Ping Hosts in IP range 
#				 and Mail Status Changes 
#						Part 1
#
#            	==> Rustam KARIMOV <==
#               	Date: 20/06/2012
#
#
#======================================================

clear
function ScanSubnet {
#Ensure Validity of entered data. Must be in "xxx.xxx.xxx." format
do {
    try {
        $numOk = $true
        $subnet = Read-Host "First 3 bits of IP subnet to scan (put dot (.) at the end"
		$ok= ($subnet -match "(\d{1,3}).(\d{1,3}).(\d{1,3})." -and -not ([int[]]$matches[1..3] -gt 255))
        } # end try
    catch {$numOK = $false}
    } # end do 
until (($ok -eq $true) -and $numOK)

#Check if number entered is between 1-255 
do {
    try {
        $numOk = $true
        [int]$a = Read-host "Scan from (1-255)"
        } # end try
    catch {$numOK = $false}
    } # end do 
until (($a -ge 1 -and $a -lt 256) -and $numOK)

#Check if number entered is between 1-255 
do {
    try {
        $numOk = $true
        [int]$b = Read-host "Scan To (1-255)"
        } # end try
    catch {$numOK = $false}
    } # end do 
until (($b -ge 1 -and $b -lt 256) -and $numOK)

If (($subnet -eq "")) { 
	Write-Host No qualified data entered
	Exit 
	}

#Array of last bits of IP addresses
[array]$nrange=$a..$b

#Array of last bits of IP addresses to store time stamps later
[array]$trange=$a..$b

$cnt=0



		clear
		Write-Host ==========================Scanning hosts $subnet$a-$b==================================
		Write-Host  HostName`tActive`tTime`t`t`tResp. Time`tHost Name
		Write-Host =========================================================================================

			
		while ($t=1) #t=1 never changes, just to make it running in constant loop
		{     
		$i=0
		$cnt+=1

		foreach ($r in $nrange)
	    	{     	
			#Initial test if host is active returns Boolean
	    	$var=(Test-Connection $subnet$r -Count 1 -quiet )	
			$ip = $subnet+$r
			$fqdn=""
			
			 try {
        			$Ok = $true
					$fqdn = [net.dns]::gethostbyaddress($ip).hostname 
				}
				catch {$Ok = $false}

	        If ($var.ToString() -eq "False")
		        {	
					#Check if variable is Active then set current time and send email, if time is set in variable will skip
					#this requires to keep the time since when host was not active
					if (($trange[$r-$a] -eq "Active") -or ($trange[$r-$a] -is [int])) {
						$trange[$r-$a]=((get-date).ToString())
						
						if($cnt -ne 1) {
						#Send email with detailes of not active host
						$subject =$ip + " - " + $fqdn + " is down at " + ((get-date).ToString()) 
						foreach($mail in (gc "Mailto.txt"))
							{
							Send-MailMessage -To $mail -From "PowerShell <powershell@powershell.com>" `
							-Subject $subject `
							-SmtpServer 10.10.10.10 -Body "Notification" -BodyAsHtml
							}
						}
					}

					#print out result on corresponding line
					#i+x. X is a number of row from which to start output of current ping results
					[console]::SetCursorPosition([Console]::CursorLeft,$i+3) 
					Write-Host  $subnet$r`t`t>>>>No responce from Host since $trange[$r-$a]`t`t`t -ForegroundColor "Black"  -BackgroundColor "Red"           
	        	}
	        	else
	        	{
					#I used WMI object, parent of Test-Connection to get more info on ping status
					#$var1= Get-WmiObject win32_pingstatus -f "Address='$subnet$r' and ResolveAddressNames=$True"
					$var1= Get-WmiObject win32_pingstatus -f "Address='$subnet$r'"
					
					#Set "Active" if host was not active/pingable and send email.
					if ( ($trange[$r-$a] -ne "Active")) {
						$trange[$r-$a]="Active"
						
						if($cnt -ne 1) {
						#Generates HTML Code with Ping results in $body variable.
						$body = ($var1 | Select-Object 	@{Name="Source &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<hr>";Expression={$_.__SERVER}}, `
										@{Name="Destination IP &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<hr>";Expression={$_.Address}}, `
										@{Name="Bytes &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<hr>";Expression={$_.Replysize}}, `
										@{Name="Time(ms)&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp<hr>";Expression={$_.ResponseTime}} | ConvertTo-Html)
						
						$subject =$ip + " - " + $fqdn + " is back online at " + ((get-date).ToString()) 
						#Send email with detailes of host
							foreach($mail in (gc "Mailto.txt"))
								{
								Send-MailMessage -To $mail -From "PowerShell <powershell@powershell.com>" `
								-Subject $subject `
								-SmtpServer 10.10.10.10 -Body $body.GetEnumerator() -BodyAsHtml
								}
							}
						}
					
					#print out result on corresponding line
					#i+x. X is a number of row from which to start output of current ping results
					[console]::SetCursorPosition([Console]::CursorLeft,$i+3)
					Write-Host  $subnet$r`t$var`t((get-date).ToString())`t($var1.ResponseTime.ToString())`t`t$fqdn`t`t -ForegroundColor "green"
				} 
				$i+=1
	      	}
			sleep 3				
			Write-Host `n===========================Round "#" $cnt finished at (get-date).ToString()=======================
		
		}
	}



ScanSubnet



# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPgh2eaU5iG3354rA6Fxtu3Br
# QHCgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEaNszbcJwvH7dnS
# SrbsCym+gPLTMA0GCSqGSIb3DQEBAQUABIIBAAJMXht6bxW0EkfIC3XVOVNbrE3K
# //QJe74SsV7nshKz4emVTT9Vw0pRP2kPNkpmA9si7oCQ8z/ZRqfC5/6C6vVUUfiX
# CpJuoyp0yKe5rEVyQ+pbXps7E1ezxHHufs3fzwHqIGEV9O586f4hCHH96ShHVaD2
# WDNmDT9XsWJH/wuQ4Ad5zwPSrcLyzv+jxavTLoOo9vumtzm8+My31GG/9H8FSvc7
# rrQNrXhYlCzAf6JjXyCf/xYVJhb33IgQ41DpMI3S3E3+RAD7I1t6l6S17Hl2FiU6
# M3/FoxhKMDa7fvwPrdDT60+mRzM5hIDFyA1TLvi7V3anWTwjIs8PUd3Jp5k=
# SIG # End signature block
