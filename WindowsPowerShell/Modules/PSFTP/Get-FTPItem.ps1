Function Get-FTPItem
{
    <#
	.SYNOPSIS
	    Send specific file from ftop server to location disk.

	.DESCRIPTION
	    The Get-FTPItem cmdlet download file to specific location on local machine.
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER LocalPath
	    Specifies a local path. 
		
	.PARAMETER RecreateFolders
		Recreate locally folders structure from ftp server.

	.PARAMETER BufferSize
	    Specifies size of buffer. Default is 20KB. 
		
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
	
	.EXAMPLE
		PS P:\> Get-FTPItem -Path ftp://ftp.contoso.com/folder/subfolder1/test.xlsx -LocalPath P:\test
		226 File send OK.

		PS P:\> Get-FTPItem -Path ftp://ftp.contoso.com/folder/subfolder1/test.xlsx -LocalPath P:\test

		A File name already exists in location: P:\test
		What do you want to do?
		[C] Cancel  [O] Overwrite  [?] Help (default is "O"): O
		226 File send OK.

	.EXAMPLE	
		PS P:\> Get-FTPChildItem -path folder/subfolder1 -Recurse | Get-FTPItem -localpath p:\test -RecreateFolders -Verbose
		VERBOSE: Performing operation "Download item: 'ftp://ftp.contoso.com/folder/subfolder1/test.xlsx'" on Target "p:\test\folder\subfolder1".
		VERBOSE: Creating folder: folder\subfolder1
		226 File send OK.

		VERBOSE: Performing operation "Download item: 'ftp://ftp.contoso.com/folder/subfolder1/ziped.zip'" on Target "p:\test\folder\subfolder1".
		226 File send OK.

		VERBOSE: Performing operation "Download item: 'ftp://ftp.contoso.com/folder/subfolder1/subfolder11/ziped.zip'" on Target "p:\test\folder\subfolder1\subfolder11".
		VERBOSE: Creating folder: folder\subfolder1\subfolder11
		226 File send OK.

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
		[parameter(Mandatory=$true,
			ValueFromPipelineByPropertyName=$true,
			ValueFromPipeline=$true)]
		[Alias("FullName")]
		[String]$Path = "",
		[String]$LocalPath = (Get-Location).Path,
		[Switch]$RecreateFolders,
		[Int]$BufferSize = 20KB,
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

		$TotalData = Get-FTPItemSize $RequestUri -Silent
		if($TotalData -eq -1) { Return }
		if($TotalData -eq 0) { $TotalData = 1 }

		$AbsolutePath = ($RequestUri -split $CurrentSession.ServicePoint.Address.AbsoluteUri)[1]
		$LastIndex = $AbsolutePath.LastIndexOf("/")
		$ServerPath = $CurrentSession.ServicePoint.Address.AbsoluteUri
		if($LastIndex -eq -1)
		{
			$FolderPath = "\"
		}
		else
		{
			$FolderPath = $AbsolutePath.SubString(0,$LastIndex) -replace "/","\"
		}	
		$FileName = $AbsolutePath.SubString($LastIndex+1)
					
		if($RecreateFolders)
		{
			if(!(Test-Path (Join-Path -Path $LocalPath -ChildPath $FolderPath)))
			{
				Write-Verbose "Creating folder: $FolderPath"
				New-Item -Type Directory -Path $LocalPath -Name $FolderPath | Out-Null
			}
			$LocalDir = Join-Path -Path $LocalPath -ChildPath $FolderPath
		}
		else
		{
			$LocalDir = $LocalPath
		}
					
		if ($pscmdlet.ShouldProcess($LocalDir,"Download item: '$RequestUri'")) 
		{	
			if($CurrentSession -ne $null)
			{
				[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
				$Request.Credentials = $CurrentSession.Credentials
				$Request.EnableSsl = $CurrentSession.EnableSsl
				$Request.KeepAlive = $CurrentSession.KeepAlive
				$Request.UseBinary = $CurrentSession.UseBinary
				$Request.UsePassive = $CurrentSession.UsePassive

				$Request.Method = [System.Net.WebRequestMethods+FTP]::DownloadFile  
				Try
				{
					[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
					$SendFlag = 1
					
					if((Get-ItemProperty $LocalDir -ErrorAction SilentlyContinue).Attributes -match "Directory")
					{
						$LocalDir = Join-Path -Path $LocalDir -ChildPath $FileName
					}
					
					if(Test-Path ($LocalDir))
					{
						$FileSize = (Get-Item $LocalDir).Length
						
						$Title = "A file ($RequestUri) already exists in location: $LocalDir"
						$Message = "What do you want to do?"

						$Overwrite = New-Object System.Management.Automation.Host.ChoiceDescription "&Overwrite"
						$Cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel"
						if($FileSize -lt $TotalData)
						{
							$Resume = New-Object System.Management.Automation.Host.ChoiceDescription "&Resume"
							$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Cancel, $Overwrite, $Resume)
							$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 2) 
						}
						else
						{
							$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Cancel, $Overwrite)
							$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 1)
						}
					}

					if($SendFlag)
					{
						[Byte[]]$Buffer = New-Object Byte[] $BufferSize

						$ReadedData = 0
						$AllReadedData = 0
						
						if($SendFlag -eq 2)
						{      
							$File = New-Object IO.FileStream ($LocalDir,[IO.FileMode]::Append)
							$Request.UseBinary = $True
							$Request.ContentOffset  = $FileSize 
							$AllReadedData = $FileSize
						}
						else
						{
							$File = New-Object IO.FileStream ($LocalDir,[IO.FileMode]::Create)
						}
						
						$Response = $Request.GetResponse()
						$Stream  = $Response.GetResponseStream()
						
						Do{
							$ReadedData=$Stream.Read($Buffer,0,$Buffer.Length)
							$AllReadedData +=$ReadedData
							$File.Write($Buffer,0,$ReadedData)
							Write-Progress -Activity "Download File: $Path" -Status "Downloading:" -Percentcomplete ([int]($AllReadedData/$TotalData * 100))
						}
						While ($ReadedData -ne 0)
						$File.Close()

						$Status = $Response.StatusDescription
						$Response.Close()
						Return $Status
					}
				}
				Catch
				{
					$Error = $_#.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAAvgcoMpSFRG4I0wrQUMatHt
# kwagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAL/UZ5bR6FYVFEE
# eEDvDJE3IGGzMA0GCSqGSIb3DQEBAQUABIIBAIPVb4ky5H66okqZo8sUicZnJknd
# twTptqeH7JKMnaaJUX+9NnbgWQxKlpZcObq46bwd5cVgCHT9vgjiHK8g9mn3ogM0
# +VtUl6AgWnSwxQPw+PnWRdVshNjIQlFH8cQN4/0eYhvJpPRpiblU8B9SVgIUxXtM
# aYDiqZkwKETWfMCISb1VaFkZehxnuOcd3dLy0Q9Mq1PtD+6sY1u8P1hcuAunXD5e
# moXWfkY4gexTPV8eMVBffcdk7tU0aV1r9M/TpUCIfnebFttyqiCSseewieWrwJhI
# g7nmdLprlwlDFPgFGrBcamvPFpM6vxidN2bL1AF5BAT//ElcLJGjh1Yes7E=
# SIG # End signature block
