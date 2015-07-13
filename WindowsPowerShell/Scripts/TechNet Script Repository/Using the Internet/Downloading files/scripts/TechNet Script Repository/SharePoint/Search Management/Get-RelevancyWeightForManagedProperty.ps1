<#
.SYNOPSIS
       The purpose of this script is to check the managed property weight for a rank profile 
.DESCRIPTION
       The purpose of this script is to check the managed property weight for a rank profile. 
	   You may specify a rank profile name, managed property name, and expected weight. 
	   This script can be used for validating an installation. It can be used see what the 
	   current relevancy settings are and to find out if they need to be changed or if they 
	   are already set correctly.
	   
.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1 -ManagedPropertyName urldepthrank -ExpectedWeight 300

Output:
Rank profile URLboost1 has weight set to 200 for urldepthrank.

.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1

This example shows running the script with no parameters. The script will display all rank profiles along with all managed properties and their weights

Output:
Rank profile default has weight set to 300 for hwboost
Rank profile default has weight set to 300 for docrank
Rank profile default has weight set to 300 for siterank
Rank profile default has weight set to 300 for urldepthrank
Rank profile URLboost has weight set to 300 for hwboost
Rank profile URLboost has weight set to 300 for docrank
Rank profile URLboost has weight set to 300 for siterank
Rank profile URLboost has weight set to 300 for urldepthrank
Rank profile URLboost1 has weight set to 300 for hwboost
Rank profile URLboost1 has weight set to 300 for docrank
Rank profile URLboost1 has weight set to 300 for siterank
Rank profile URLboost1 has weight set to 300 for urldepthrank

.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1 -ManagedPropertyName urldepthrank -ExpectedWeight 300

This checks given a rank profile name, a managed property name and an expected weight. If everything matches up the output displays in green otherwise it is red

Output:
Rank profile URLboost1 has weight set to 300 for urldepthrank

.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1 -ManagedPropertyName urldepthrank

This example shows specifying the rank profile name as well as a property name

Output:
Rank profile URLboost1 has weight set to 300 for urldepthrank

.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1

This example shows output of all managed properties with their weight for a given rank profile

Output:
Rank profile URLboost1 has weight set to 300 for hwboost
Rank profile URLboost1 has weight set to 300 for docrank
Rank profile URLboost1 has weight set to 300 for siterank
Rank profile URLboost1 has weight set to 300 for urldepthrank

.EXAMPLE
.\Get-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1ss

This example shows the output for an invalid rank profile name

Output:
Rank profile not found: URLboost1ss

.LINK
This Script - http://gallery.technet.microsoft.com/scriptcenter/a30df851-a439-4441-9c0f-e9f8cf08b070
.NOTES
  File Name : Get-RelevancyWeightForManagedProperty.ps1
  Author    : Ben Lin, Brent Groom 
#>

# TODO - implement uninstall, drive from a config file, use return codes

param
  (
	
	[switch]
    # Signifies that the script should output debug statements
    $DebugMode, 
    
    [string]
    # Specifies name of the rank profile to update or create 
    $RankProfileName="", 
	
    [string]
    # Allows you to specify the From: email address from the command line 
	$ManagedPropertyName = "",
    
	[int]
    # Allows you to specify the To: email address from the command line 
	$ExpectedWeight = -1
    
    )

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

$global:foundMP = $false

function GetRelevancyWeightForManagedProperty($rankprofilename)
{
	
	$customRP = Get-FASTSearchMetadataRankProfile -Name $rankprofilename -erroraction SilentlyContinue
	
	if($customRP -ne $null)
	{
		$customQCEnum = $customRP.GetQualityComponents()

		foreach($qc in $customQCEnum)
		{
			if($ManagedPropertyName.Length -eq 0)
			{
				write-host ("Rank profile $rankprofilename has weight set to "+$qc.Weight+" for " + $qc.ManagedPropertyReference.Name ) -Foregroundcolor Red 
				#$qc.ManagedPropertyReference.Name
			}
			elseif($qc.ManagedPropertyReference.Name -eq $ManagedPropertyName ) 
			{
			    $global:foundMP = $true
				if($ExpectedWeight -eq $qc.Weight)
				{
					write-host ("Rank profile $rankprofilename has weight set to "+$qc.Weight+" for " + $qc.ManagedPropertyReference.Name ) -Foregroundcolor Green 			
					
				}
				else
				{
				    write-host ("Rank profile $rankprofilename has weight set to "+$qc.Weight+" for " + $qc.ManagedPropertyReference.Name ) -Foregroundcolor Red 			
				}
			}
		}
		
	}
	else
	{
        write-host ("Rank profile not found: $rankprofilename ") -Foregroundcolor Red
	
	}
	
}


function GetRelevancyWeightForManagedProperties()
{
	
	if($RankProfileName.length -eq 0)
	{
	    $rpEnum = Get-FASTSearchMetadataRankProfile
		foreach($rp in $rpEnum)
		{
			GetRelevancyWeightForManagedProperty($rp.Name)
		}
	}
	else
	{
        GetRelevancyWeightForManagedProperty($RankProfileName)
		if($ManagedPropertyName.Length -gt 0 -and $global:foundMP -eq $false)
		{
            write-host ("Managed property not found: $ManagedPropertyName ") -Foregroundcolor Red			
		}
	}
		
	# Map a managed property to a full-text index at a specific importance level by using Windows PowerShell (FAST Search Server 2010 for SharePoint)
	# http://msdn.microsoft.com/en-us/library/ff191254.aspx
	
}

if($DebugMode)
{
	"Using following values:"
	"  DebugMode:$DebugMode"
	"  RankProfileName:$RankProfileName"
	"  ManagedPropertyName:$ManagedPropertyName"
	"  ExpectedWeight:$ExpectedWeight"
}

GetRelevancyWeightForManagedProperties




# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaeUp8e52URQlMOCk2iFCg+OR
# isWgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMNyplGQGsDGJNLk
# GQmryX2m02OrMA0GCSqGSIb3DQEBAQUABIIBABiteaN4WB+dUkJq6Rbydi4P+taE
# Mz+dYbarLfPfvmGmip0e4fwAt5uDyKQ8oMiJqCVNiG3e2XN/gioYuU8RXx5iItHQ
# e3sLBC/koUbwpW9+tzm6Er8y+2knuXMUnwBLWyTgtdR3o0VeC0/9QvcBfzRzjpLb
# su/ZSvGrL/krjSpRDzIuNanYX6ZQA31G58zTV+cPhdutWiSEIP55D5I6wd/fpv44
# sT6QQQTCp4gWhSWtUp0jjBrkxsI/oLuyHTHTrzSPWI/lkrhwPqRCAfVfooHPCz0G
# C4f5zdwkMO2kc9G+td/ERWEuZAFF/0V+r7L/od7vQ8Ub8g/fDW0ER0+syhk=
# SIG # End signature block
