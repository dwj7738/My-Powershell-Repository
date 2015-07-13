Function Get-FTPChildItem
{
	<#
	.SYNOPSIS
		Gets the item and child items from ftp location.

	.DESCRIPTION
		The Get-FTPChildItem cmdlet gets the items from ftp locations. If the item is a container, it gets the items inside the container, known as child items. 
		
	.PARAMETER Path
		Specifies a path to ftp location or file. 
			
	.PARAMETER Session
		Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
		
	.PARAMETER Recurse
		Get recurse child items.
		
	.EXAMPLE
		PS P:\> Get-FTPChildItem -path ftp://ftp.contoso.com/folder


		   Parent: ftp://ftp.contoso.com/folder

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		d   rwxr-xr-x 3   ftp    ftp           2012-06-19 12:58:00 subfolder1
		d   rwxr-xr-x 2   ftp    ftp           2012-06-19 12:58:00 subfolder2
		-   rw-r--r-- 1   ftp    ftp    1KB    2012-06-15 12:49:00 textitem.txt

	.EXAMPLE
		PS P:\> Get-FTPChildItem -path folder -Recurse


		   Parent: ftp://ftp.contoso.com/folder

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		d   rwxr-xr-x 3   ftp    ftp           2012-06-19 12:58:00 subfolder1
		d   rwxr-xr-x 2   ftp    ftp           2012-06-19 12:58:00 subfolder2
		-   rw-r--r-- 1   ftp    ftp    1KB    2012-06-15 12:49:00 textitem.txt


		   Parent: ftp://ftp.contoso.com/folder/subfolder1

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		d   rwxr-xr-x 2   ftp    ftp           2012-06-19 12:58:00 subfolder11
		-   rw-r--r-- 1   ftp    ftp    21KB   2012-06-19 09:20:00 test.xlsx
		-   rw-r--r-- 1   ftp    ftp    14KB   2012-06-19 11:27:00 ziped.zip


		   Parent: ftp://ftp.contoso.com/folder/subfolder1/subfolder11

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		-   rw-r--r-- 1   ftp    ftp    14KB   2012-06-19 11:27:00 ziped.zip


		   Parent: ftp://ftp.contoso.com/folder/subfolder2

		Dir Right     Ln  User   Group  Size   ModifiedDate        Name
		--- -----     --  ----   -----  ----   ------------        ----
		-   rw-r--r-- 1   ftp    ftp    1KB    2012-06-15 12:49:00 textitem.txt
		-   rw-r--r-- 1   ftp    ftp    14KB   2012-06-19 11:27:00 ziped.zip

	.EXAMPLE
		PS P:\> $ftpFile = Get-FTPChildItem -path /folder/subfolder1/test.xlsx
		PS P:\> $ftpFile | Select-Object Parent, Name, ModifiedDate

		Parent                                  Name                                    ModifiedDate
		------                                  ----                                    ------------
		ftp://ftp.contoso.com/folder/subfolder1 test.xlsx                               2012-06-19 09:20:00
		
	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/

	.LINK
		Set-FTPConnection
	#>	 

	[OutputType('PSFTP.Item')]
	[CmdletBinding(
		SupportsShouldProcess=$True,
		ConfirmImpact="Low"
	)]
	Param(
		[parameter(ValueFromPipelineByPropertyName=$true,
			ValueFromPipeline=$true)]
		[String]$Path = "",
		[String]$Session = "DefaultFTPSession",
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Switch]$Recurse
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
		
		if ($pscmdlet.ShouldProcess($RequestUri,"Get child items from ftp location")) 
		{	
			if((Get-FTPItemSize $RequestUri -Silent) -eq -1)
			{
				$ParentPath = $RequestUri
			}
			else
			{
				$LastIndex = $RequestUri.LastIndexOf("/")
				$ParentPath = $RequestUri.SubString(0,$LastIndex)
			}
						
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
					$mode = "Unknown"
					[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
					$Response = $Request.GetResponse()

					[System.IO.StreamReader]$Stream = $Response.GetResponseStream()

					#$Array = @()
					$ItemsCollection = @()
					Try
					{
						[string]$Line = $Stream.ReadLine()
					}
					Catch
					{
						$Line = $null
					}
					
					While ($Line)
					{
						if($mode -eq "Compatible" -or $mode -eq "Unknown")
						{
							$null, [string]$IsDirectory, [string]$Flag, [string]$Link, [string]$UserName, [string]$GroupName, [string]$Size, [string]$Date, [string]$Name = `
							[regex]::split($Line,'^([d-])([rwxt-]{9})\s+(\d{1,})\s+([.@A-Za-z0-9-]+)\s+([A-Za-z0-9-]+)\s+(\d{1,})\s+(\w+\s+\d{1,2}\s+\d{1,2}:?\d{2})\s+(.+?)\s?$',"SingleLine,IgnoreCase,IgnorePatternWhitespace")

							if($IsDirectory -eq "" -and $mode -eq "Unknown")
							{
								$mode = "IIS6"
							}
							else
							{
								$mode = "Compatible" #IIS7/Linux
							}
							
							if($mode -eq "Compatible")
							{
								$DatePart = $Date -split "\s+"
								$NewDateString = "$($DatePart[0]) $('{0:D2}' -f [int]$DatePart[1]) $($DatePart[2])"
								
								Try
								{
									if($DatePart[2] -match ":")
									{
										$Month = ([DateTime]::ParseExact($DatePart[0],"MMM",[System.Globalization.CultureInfo]::InvariantCulture)).Month
										if((Get-Date).Month -ge $Month)
										{
											$NewDate = [DateTime]::ParseExact($NewDateString,"MMM dd HH:mm",[System.Globalization.CultureInfo]::InvariantCulture)
										}
										else
										{
											$NewDate = ([DateTime]::ParseExact($NewDateString,"MMM dd HH:mm",[System.Globalization.CultureInfo]::InvariantCulture)).AddYears(-1)
										}
									}
									else
									{
										$NewDate = [DateTime]::ParseExact($NewDateString,"MMM dd yyyy",[System.Globalization.CultureInfo]::InvariantCulture)
									}
								}
								Catch
								{}							
							}
						}
						
						if($mode -eq "IIS6")
						{
							$null, [string]$NewDate, [string]$IsDirectory, [string]$Size, [string]$Name = `
							[regex]::split($Line,'^(\d{2}-\d{2}-\d{2}\s+\d{2}:\d{2}[AP]M)\s+<*([DIR]*)>*\s+(\d*)\s+(.+).*$',"SingleLine,IgnoreCase,IgnorePatternWhitespace")
							
							if($IsDirectory -eq "")
							{
								$IsDirectory = "-"
							}
						}
						
						Switch($Size)
						{
							{[int]$_ -lt 1024} { $HFSize = $_+"B"; break }
							{[System.Math]::Round([int]$_/1KB,0) -lt 1024} { $HFSize = [String]([System.Math]::Round($_/1KB,0))+"KB"; break }
							{[System.Math]::Round([int]$_/1MB,0) -lt 1024} { $HFSize = [String]([System.Math]::Round($_/1MB,0))+"MB"; break }
							{[System.Math]::Round([int]$_/1GB,0) -lt 1024} { $HFSize = [String]([System.Math]::Round($_/1GB,0))+"GB"; break }
							{[System.Math]::Round([int]$_/1TB,0) -lt 1024} { $HFSize = [String]([System.Math]::Round($_/1TB,0))+"TB"; break }
						} #End Switch
						
						if($IsDirectory -eq "d" -or $IsDirectory -eq "DIR")
						{
							$HFSize = ""
						}
					
						$LineObj = New-Object PSObject -Property @{
							Dir = $IsDirectory
							Right = $Flag
							Ln = $Link
							User = $UserName
							Group = $GroupName
							Size = $HFSize
							SizeInByte = $Size
							OrgModifiedDate = $Date
							ModifiedDate = $NewDate
							Name = $Name
							FullName = $ParentPath.Trim() + "/" + $Name.Trim()
							Parent = $ParentPath
						}
						
						$LineObj.PSTypeNames.Clear()
						$LineObj.PSTypeNames.Add('PSFTP.Item')
				
						if($LineObj.Dir)
						{
							$ItemsCollection += $LineObj
						}
						$Line = $Stream.ReadLine()
					}
					
					$Response.Close()
					
					if($Recurse)
					{
						$RecurseResult = @()
						$ItemsCollection | Where-Object {$_.Dir -eq "d" -or $_.Dir -eq "DIR"} | ForEach-Object {
							$RecurseResult += Get-FTPChildItem -Path ($_.FullName) -Session $Session -Recurse
						}
						
						$ItemsCollection += $RecurseResult
					}	
					
					if($ItemsCollection.count -eq 0)
					{
						Return 
					}
					else
					{
						Return $ItemsCollection | Sort-Object -Property @{Expression="Parent";Descending=$false}, @{Expression="Dir";Descending=$true}, @{Expression="Name";Descending=$false} 
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
	
	End{}
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsZv5bYLVlLP/MsXW5vkNEuZS
# 65ugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJxl77vzzb3/ausJ
# U6En5Deylc16MA0GCSqGSIb3DQEBAQUABIIBAICbMERpnohT5TISyIDqOnfeuLl/
# dUQP218lYD3JwCWm2C3/fDNDucua2eR35L+T+t6AEbqI9oeEmR/YJ+36am4Qmrkm
# 03a0wwGEMKDcKOLNOYZ10o0HtM4mUbn49ZiNxehlH15VCwN3Byo1A24inqAs4ZDo
# s0FeIP5q9CaC9YCx0YGMvNt5Qja+FY/Xc3lJJXysmgdAbT1+zyM2ZthCCn59J2zn
# OIs+T5+pk/Rrru5f90unuxl4QmARC3bmdVOYsKjDhUnNO+66BN+QY1qsSnhKCfi0
# SEMsxHTKVE3HUidY88JNVh+dXlfjMWv9+CsQfsC1F8u3bAcPq0H3sz8r3sY=
# SIG # End signature block
