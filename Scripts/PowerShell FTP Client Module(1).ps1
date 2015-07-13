# --------------------------------- Meta Information for Microsoft Script Explorer for Windows PowerShell V1.0 ---------------------------------
# Title: PowerShell FTP Client Module
# Author: MichalGajda
# Description: The PSFTP module allow you to connect and manage the contents of ftp account. Module contain set of function to get list of items, download and send files on ftp location.
# Date Published: 18-Aug-2011 7:09:33 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/PowerShell-FTP-Client-db6fe0cb
# Tags: Powershell;FTP
# ------------------------------------------------------------------

Function Set-FTPConnection
{
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[parameter(Mandatory=$true)]
		[System.Net.NetworkCredential]$Credentials,
		[parameter(Mandatory=$true)]
		[String]$Server,
		[Switch]$EnableSsl = $False,
		[Switch]$ignoreCert = $False,
		[Switch]$KeepAlive = $False,
		[Switch]$UseBinary = $False,
		[Switch]$UsePassive = $False,
		[String]$Session = "DefaultFTPSession"
	)
	
	Begin{}
	
	Process
	{
        if ($pscmdlet.ShouldProcess($Server,"Connect to FTP Server")) 
		{	
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($Server)
			$Request.Credentials = $Credentials
			$Request.EnableSsl = $EnableSsl
			$Request.KeepAlive = $KeepAlive
			$Request.UseBinary = $UseBinary
			$Request.UsePassive = $UsePassive
			$Request | Add-Member -MemberType NoteProperty -Name ignoreCert -Value $ignoreCert

			$Request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectoryDetails
			Try
			{
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$ignoreCert}
				$Response = $Request.GetResponse()
				$Response.Close()
				
				if((Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue) -eq $null)
				{
					New-Variable -Scope Global -Name $Session -Value $Request
				}
				else
				{
					Set-Variable -Scope Global -Name $Session -Value $Request
				}
				
				Return $Response
			}
			Catch
			{
				$Error = $_.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
				Write-Warning $Error
			}
		}
	}
	
	End{}				
}

Function Get-FTPChildItem
{
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[String]$Path = "",
		[String]$Session = "DefaultFTPSession"
	)
	
	Begin{}
	
	Process
	{
        $CurrentSession = Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue -ValueOnly
		if($Path -match "ftp://")
		{
			$RequestUri = $Path
		}
		else
		{
			$RequestUri = $CurrentSession.RequestUri.OriginalString+"/"+$Path
		}
		$RequestUri = [regex]::Replace($RequestUri, '/+', '/')
		$RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')
		
		if ($pscmdlet.ShouldProcess($RequestUri,"Get child items from ftp location.")) 
		{	
			if($CurrentSession -ne $null)
			{
				[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
				$Request.Credentials = $CurrentSession.Credentials
				$Request.EnableSsl = $CurrentSession.EnableSsl
				$Request.KeepAlive = $CurrentSession.KeepAlive
				$Request.UseBinary = $CurrentSession.UseBinary
				$Request.UsePassive = $CurrentSession.UsePassive
				
				$Request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectoryDetails
				Try
				{
					[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
					$Response = $Request.GetResponse()

					[System.IO.StreamReader]$Stream = $Response.GetResponseStream()

					$Array = @()
					[string]$Line = $Stream.ReadLine()
					While ($Line)
					{
						$null, [string]$isDirectory, [string]$flag, [string]$link, [string]$userName, [string]$groupName, [string]$size, [string]$date, [string]$name = `
						[regex]::split($Line,'^([d-])([rwxt-]{9})\s+(\d{1,})\s+([A-Za-z0-9-]+)\s+([A-Za-z0-9-]+)\s+(\d{1,})\s+(\w+\s+\d{1,2}\s+\d{1,2}:?\d{2})\s+(.+?)\s?$',"SingleLine,IgnoreCase,IgnorePatternWhitespace")

						$LineObj = New-Object PSObject -Property @{            
        					Dir           = $isDirectory
							Right         = $flag               
        					Ln            = $link               
        					User          = $userName        
        					Group         = $groupName      
        					Size          = $size      
        					ModifiedDate  = $date    
        					Name          = $name           
        				} 
						
						if($LineObj.Dir)
						{
							$Array += $LineObj
						}
						$Line = $Stream.ReadLine()
					}
					
					$Response.Close()
					if($Array.count -eq 0)
					{
						Return 
					}
					else
					{
						Return $Array | Select-Object Dir, Right, Ln, User, Group, Size, ModifiedDate, Name | Sort-Object -Property @{Expression="Dir";Descending=$true}, @{Expression="Name";Descending=$false} 
					}	
				}
				Catch
				{
					$Error = $_.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
					Write-Warning $Error
				}
			}
			else
			{
				Write-Warning "First use Set-FTPConnection to config FTP connection."
			}
		}
	}
	
	End{}				
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUA/748gqfnUVVGrMZxPwGVdsS
# pK6gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFE3MQzF7Wb2amcnA
# vWb9R2jtGGoEMA0GCSqGSIb3DQEBAQUABIIBAH9Xer772NwDm3IMbpsi59ysqpnG
# 4/KmClgRm/9IArISbo53Cs+wYt5W89zBfs97uoDybVDXzZlOipRQAUXI3pUFx9pU
# +bD73GRbeCB6BXL53DZ1tkwxyiN1xMOgkiKuC6/iBHZrExjYsvrOUrFgNC9CP8/I
# Jn9i4Sofqq35Vc/qMoEoL6jFkZUI32QF+7NX60NOeL4D0DMNnh8HZnPnuR0a4nyl
# ldbSYR+a/hohDVX23YoPAeorSWO3kvd11ySrre3u1BQm8GvC7TTj4Gr9OKPLSCT/
# p1W1NP5Q5dDXFUHBTh3vaMx6fmzxvGbUrgaT+pwobpNphQXyHOFFQPSxeuc=
# SIG # End signature block
