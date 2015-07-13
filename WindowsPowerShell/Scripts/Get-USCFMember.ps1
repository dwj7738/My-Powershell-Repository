#Requires -Version 2.0
<#
	.SYNOPSIS
		Get-USCFMember connects to USCF website and returns search results using specified Name or USCF ID.

	.DESCRIPTION
		Get-USCFMember requires connection to internet. If connected to internet, the function returns search results using specified Name of USCF ID of a USCF member. The script is able to search based on Lastname or USCF ID of members. It can also search using Firstname of wildcard if Lastname is specified.

	.PARAMETER  Lastname
		Lastname of USCF member to search.

	.PARAMETER  Firstname
		Firstname of USCF member to search.
	
	.PARAMETER Wildcard
		Perform a wildcard search when Lastname is specified.
	
	.PARAMETER USCFID
		Perform a search using USCF ID of a member.

	.PARAMETER OutFile
		Write search results to a csv file. When this parameter is specified, output to console is suppressed.
		
	.EXAMPLE
		PS C:\> Get-USCFMember -Lastname Shukla -Firstname Bhargav
		
		LastName       : SHUKLA
		Firstname      : BHARGAV L
		USCF ID        : 12837106
		State          : PA
		Regular Rating : 572P
		Quick Rating   : 580P

		This example shows how to call the Get-USCFMember function with named parameters.

	.EXAMPLE
		PS C:\> Get-USCFMember Shukla Bhargav
		
		LastName       : SHUKLA
		Firstname      : BHARGAV L
		USCF ID        : 12837106
		State          : PA
		Regular Rating : 572P
		Quick Rating   : 580P

		This example shows how to call the Get-USCFMember function with positional parameters.

.EXAMPLE
		PS C:\> Get-USCFMember -Lastname Shukla -OutFile c:\temp\shukla.csv

		This example shows how to write resulting data to csv file.
		
	.INPUTS
		System.String,System.Int32,System.Boolean

	.OUTPUTS
		System.String

	.NOTES
		For more information about advanced functions, call Get-Help with any
		of the topics in the links listed below.

	.LINK
		about_functions_advanced

	.LINK
		about_comment_based_help

	.LINK
		about_functions_advanced_parameters

	.LINK
		about_functions_advanced_methods
#>
function Get-USCFMember 
{
	[CmdletBinding()]
	param(
		[Parameter(Position=0)]
		[String]
		$Lastname,
		[Parameter(Position=1)]
		[String]
		$Firstname,
		[Parameter(Position=2)]
		[Switch]
		$Wildcard,
		[Int]
		$USCFID,
		[String]
		$OutFile
	)
	
	# Check if internet is accessible. Return error and exit if not connected
	[bool] $HasInternetAccess = ([Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}')).IsConnectedToInternet)
	If (-not ($HasInternetAccess))
	{
		Write-Error "Get-USCFMember requires connection to internet. Please ensure you are connected to internet before calling Get-USCFMember."
		return
	}

	# Validate parameters
	If ($USCFID)
	{
		If ($Lastname -or $Firstname -or $Wildcard)
		{
			Write-Error "USCFID is an exclusive parameter. It cannot be used with other parameters."
			return
		}
		If (-not ($USCFID -match [regex]"^\d{8}$"))
		{
			Write-Error "USCFID must be an 8 digit number."
			return
		}
	
		$Search = "$($USCFID.toString())"
	}
	Else
	{
		If (-not $Lastname)
		{
			Write-Error "Lastname or USCFID must be specified"
			return
		}
		Else
		{
			If ($Firstname -and $Wildcard)
			{
				$Search = "$Lastname, $Firstname*"
			}
			ElseIf ($Firstname)
			{
				$Search = "$Lastname, $Firstname"
			}
			ElseIf ($Wildcard)
			{
				$Search = "$Lastname*"
			}
			Else
			{
				$Search = "$Lastname"
			}
		}
	}
	If ($OutFile)
	{
		If (-not (Test-Path (Split-Path $OutFile)))
		{
			Write-Error "Specified path for outfile is incorrect or doesn't exist. Please provide correct path."
			return
		}
		If (Test-Path $OutFile)
		{
			Write-Error "Specified file exists. Please provide name of a new file to create."
			return
		}
		
		Out-File -FilePath $OutFile -InputObject 'Lastname,Firstname,USCF ID,State,Regular Rating,Quick Rating' -Encoding ascii
	}
	
	# Define regex and query USCF website with specified parameters
	$regex = [regex]"(?<USCFID>\d{8})\s*?\((?<State>.{2})\)\s*\d{4}-\d{2}-\d{2}\s*(?<Reg>.{3,5}\S)\s*(?<Quick>.{3,5}\S)\s*.*?>(?<Name>.*?)<"
	$HTTP = new-object -com Microsoft.XMLHTTP
	$HTTP.open( "POST", 'http://main.uschess.org/assets/msa_joomla/MbrLst.php', $False )
	$HTTP.setRequestHeader( 'Content-Type', 'application/x-www-form-urlencoded')
	$HTTP.send( "eMbrKey=$Search" )
	
	# Create object with search results
	$HTTPARR = $HTTP.responseText.Split("`n")
	ForEach ($line in $HTTPARR)
	{
		if ($line -match $Search -and -not($line -match "value")) {[array]$match += $line}
	}
	
	# Create Collection of member objects and output to file if requested
	$Members = ForEach ($Member in $match)
	{
		if ($Member -match "$regex")
		{
			$Member = New-Object PSObject
				add-member -InputObject $Member -MemberType Noteproperty -Name LastName -Value $((($($Matches['Name'])).split(","))[0].Trim())                 
            	add-member -InputObject $Member -MemberType Noteproperty -Name Firstname -Value $((($($Matches['Name'])).split(","))[1].Trim())             
            	add-member -InputObject $Member -MemberType Noteproperty -Name "USCF ID" -Value $($Matches['USCFID'])
            	add-member -InputObject $Member -MemberType Noteproperty -Name State -Value $($Matches['State'])
            	add-member -InputObject $Member -MemberType Noteproperty -Name "Regular Rating" -Value $($Matches['Reg'].trim())
				add-member -InputObject $Member -MemberType Noteproperty -Name "Quick Rating" -Value $($Matches['Quick'].trim())
			$Member
			
			If ($OutFile)
			{
			Out-File -FilePath $OutFile -InputObject "$($member.Lastname),$($member.Firstname),$($member.""USCF ID""),$($member.State),$($member.""Regular Rating""),$($member.""Quick Rating"")" -Append -Encoding ascii
			}
		}
	}

	# Write Output to console only if outfile is not specified
	If (-not ($OutFile))
	{
		Write-Output $Members
	}
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmVDRJGOl5EGzkzXGYRQjIh7Z
# aLigggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFIXMKQam/U8v7J0q
# OXRyPbf7Q2FEMA0GCSqGSIb3DQEBAQUABIIBAMtOcUjZ9r/GmzwYJv6RqXwPMbhP
# SXFTkbEO1dbJh8zxcqUQkcd+qcUJYvHCNp0MtyJphDMPgED/49U1egW2UFsHxPmT
# gW1nTs/FkmfhtRGrl+nbMa6wVAb+wu65h1cKF+Me+GW5x7Bum6OXmFnXCNjXUFld
# hmbCsjXsyWu7brVpLqYBGRT6FRHwHFlG0n1HZkB6aD6b7wtBpaI3DF2wTJyC034w
# A9vZxWWoZ76sPeKWFzidS+DSJIbdXm7JI35dov2zVsPB9qtJ2Hl51GKlrGXdGh14
# zqk6O9uolCPTjeoYH5X+q+70gBQZ3IDYfo4sBqN5qfaUQKUCsEd7LDMyilE=
# SIG # End signature block
