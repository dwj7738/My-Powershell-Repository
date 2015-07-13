Function Add-FTPItem
{
    <#
	.SYNOPSIS
	    Send file to specific ftp location.

	.DESCRIPTION
	    The Add-FTPItem cmdlet send file to specific location on ftp server.
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER LocalPath
	    Specifies a local path. 

	.PARAMETER BufferSize
	    Specifies size of buffer. Default is 20KB. 		
			
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
		
	.PARAMETER Overwrite
	    Overwrite item on remote location. 		
	
	.EXAMPLE
		PS> Add-FTPItem -Path "/myfolder" -LocalPath "C:\myFile.txt"

		Dir          : -
		Right        : rw-r--r--
		Ln           : 1
		User         : ftp
		Group        : ftp
		Size         : 82033
		ModifiedDate : Aug 17 12:27
		Name         : myFile.txt

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/

	.LINK
        Get-FTPChildItem
	#>    

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[String]$Path = "",
		[parameter(Mandatory=$true)]
		[String]$LocalPath,
		[Int]$BufferSize = 20KB,
		[String]$Session = "DefaultFTPSession",
		[Switch]$Overwrite = $false
	)
	
	Begin{}
	
	Process
	{
        $CurrentSession = Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue -ValueOnly
		
		if(Test-Path $LocalPath)
		{
			if($Path -match "ftp://")
			{
				$RequestUri = $Path+"/"+(Get-Item $LocalPath).Name
			}
			else
			{
				$RequestUri = $CurrentSession.RequestUri.OriginalString+"/"+$Path+"/"+(Get-Item $LocalPath).Name
			}
			$RequestUri = [regex]::Replace($RequestUri, '/+', '/')
			$RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')
			
			if ($pscmdlet.ShouldProcess($RequestUri,"Send item: '$LocalPath' in ftp location")) 
			{	
				if($CurrentSession -ne $null)
				{
					[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
					$Request.Credentials = $CurrentSession.Credentials
					$Request.EnableSsl = $CurrentSession.EnableSsl
					$Request.KeepAlive = $CurrentSession.KeepAlive
					$Request.UseBinary = $CurrentSession.UseBinary
					$Request.UsePassive = $CurrentSession.UsePassive

					Try
					{
						[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
						
						$SendFlag = 1
						if($Overwrite -eq $false)
						{
							if((Get-FTPChildItem -Path $RequestUri).Name)
							{
								$FileSize = Get-FTPItemSize -Path $RequestUri -Silent
								
								$Title = "A File name already exists in this location."
								$Message = "What do you want to do?"

								$ChoiceOverwrite = New-Object System.Management.Automation.Host.ChoiceDescription "&Overwrite"
								$ChoiceCancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel"
								if($FileSize -lt (Get-Item -Path $LocalPath).Length)
								{
									$ChoiceResume = New-Object System.Management.Automation.Host.ChoiceDescription "&Resume"
									$Options = [System.Management.Automation.Host.ChoiceDescription[]]($ChoiceCancel, $ChoiceOverwrite, $ChoiceResume)
									$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 2) 
								}
								else
								{
									$Options = [System.Management.Automation.Host.ChoiceDescription[]]($ChoiceCancel, $ChoiceOverwrite)		
									$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 1) 
								}	
							}
						}
						
						if($SendFlag -eq 2)
						{
							$Request.Method = [System.Net.WebRequestMethods+FTP]::AppendFile
						}
						else
						{
							$Request.Method = [System.Net.WebRequestMethods+FTP]::UploadFile
						}
						
						if($SendFlag)
						{
							$File = [IO.File]::OpenRead( (Convert-Path $LocalPath) )
							
		           			$Response = $Request.GetRequestStream()
	            			[Byte[]]$Buffer = New-Object Byte[] $BufferSize
							
							$ReadedData = 0
							$AllReadedData = 0
							$TotalData = (Get-Item $LocalPath).Length
							
							if($SendFlag -eq 2)
							{
								$SeekOrigin = [System.IO.SeekOrigin]::Begin
								$File.Seek($FileSize,$SeekOrigin) | Out-Null
								$AllReadedData = $FileSize
							}
							
							if($TotalData -eq 0)
							{
								$TotalData = 1
							}
							
						    Do {
	               				$ReadedData = $File.Read($Buffer, 0, $Buffer.Length)
	               				$AllReadedData += $ReadedData
	               				$Response.Write($Buffer, 0, $ReadedData);
	               				Write-Progress -Activity "Upload File: $Path" -Status "Uploading:" -Percentcomplete ([int]($AllReadedData/$TotalData * 100))
	            			} While($ReadedData -gt 0)
				
				            $File.Close()
	            			$Response.Close()
							
							Return Get-FTPChildItem -Path $RequestUri
						}
						
					}
					Catch
					{
						$Error = $_.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
						Write-Error $Error -ErrorAction Stop
					}
				}
				else
				{
					Write-Warning "First use Set-FTPConnection to config FTP connection."
				}
			}
		}
		else
		{
			Write-Error "Cannot find local path '$LocalPath' because it does not exist." -ErrorAction Stop 
		}
	}
	
	End{}				
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+NfDmsFSsAQin87L6ejLIhSe
# hkmgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFBp9bk77W4JT5mgM
# WC2FYtfUzcbkMA0GCSqGSIb3DQEBAQUABIIBAJZQ91xSnv/iNVe9nWKWLR5EEiT1
# A6AT3recpQiFzs9fKO6+gSVz40suKEhbCPKnR0qXNoRZngaNt2w72A7qterx8ciH
# YuclH2eg0qumSmGeSrWPe4cyfoR5ToIWfMXct/ocncL9cbZsR8p8UVjOJHzH0Nr+
# +S8iQKwOOgViI9J8LV2dfzHULlZBIVasTeV1T8fQgvYV7IEYouzIXkvOp+znouiO
# 7TPSyBy3teNpAvQVRiDmis7xFBkLqTMUYH17wGTokvT4zS6euUVki9UVzTtzLa/z
# PXkHYT13DMpOqM1zX7K+Qdmhjh+Uq8th1jyWX3aI8lb4GzOHykaAmb9tLqQ=
# SIG # End signature block
