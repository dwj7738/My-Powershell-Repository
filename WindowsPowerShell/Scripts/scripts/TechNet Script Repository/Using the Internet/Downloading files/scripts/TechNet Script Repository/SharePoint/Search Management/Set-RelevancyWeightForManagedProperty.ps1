<#
.SYNOPSIS
       The purpose of this script is to check the managed property weight for a rank profile and update it
.DESCRIPTION
       The purpose of this script is to check the managed property weight for a rank profile and update it.
	   You must specify the managed property name, rank profile name, and expected weight. if the rank profile
	   name is not specified then the script uses the default rank profile name. This script can be used in conjunction
	   with Get-RelevancyWeightForManagedProperty.
	   
.EXAMPLE
.\Set-RelevancyWeightForManagedProperty.ps1 -RankProfileName URLboost1 -ManagedPropertyName urldepthrank -ExpectedWeight 300 

Output:
Rank profile URLboost1 has weight set to 200 for urldepthrank. We were expecting it to be set to 300
Updated URLboost1 urldepthrank weight to 300.

.LINK
This Script - http://gallery.technet.microsoft.com/scriptcenter/858ff2e3-c391-40f8-a5b7-29da74f54d41
.NOTES
  File Name : Set-RankProfileWeight.ps1
  Author    : Ben Lin, Brent Groom 
#>

# TODO - implement uninstall, drive from a config file

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
	$ExpectedWeight = 0
    
    )

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

function SetRelevancyWeightForManagedProperty()
{
	if ( $RankProfileName.Length -eq 0)
	{
		write-host ("Rank profile not specified. Using default rank profile.") -Foregroundcolor Yellow
		$RankProfileName = "default"
	}

	if ( $ManagedPropertyName.Length -eq 0)
	{
		write-host ("Managed property must be set to a valid name.") -Foregroundcolor Red
		write-host ("We will now exit the script.") -Foregroundcolor Red
		return
	}
	
	$defaultRP = Get-FASTSearchMetadataRankProfile -Name default
	$customRP = Get-FASTSearchMetadataRankProfile -Name $RankProfileName -erroraction SilentlyContinue
	if($customRP -eq $null)
	{
		write-host ("Creating new rank profile $RankProfileName") -Foregroundcolor Yellow
		$global:customRP = New-FASTSearchMetadataRankProfile -Name $RankProfileName -Template $defaultRP
		write-host ("Created new rank profile $RankProfileName") -Foregroundcolor Green
	}

	#$customRP = Get-FASTSearchMetadataRankProfile -Name $RankProfileName -erroraction SilentlyContinue
	
	if($customRP -ne $null)
	{
		$customQCEnum = $customRP.GetQualityComponents()

		
		#######################
		$foundMP = $false
		foreach($qc in $customQCEnum)
		{
			if($qc.ManagedPropertyReference.Name -eq $ManagedPropertyName ) 
			{
				$foundMP = $true
				"1"
				$ExpectedWeight
				if($ExpectedWeight -eq $qc.Weight)
				{
					write-host ("Rank profile $rankprofilename has weight set to "+$qc.Weight+" for " + $qc.ManagedPropertyReference.Name ) -Foregroundcolor Green 								
				}
				else
				{
				    write-host ("Updating Rank profile $rankprofilename Managed property:" + $qc.ManagedPropertyReference.Name +" from weight:"+$qc.Weight+" to:$ExpectedWeight") -Foregroundcolor Red 			
					$qc.Weight = $ExpectedWeight
					$upd1 = $qc.Update()
					$upd1
				}
			}
		}
		if($foundMP -eq $false)
		{
		    write-host ("Could not find specified managed property:$ManagedPropertyName in rank profile:$RankProfileName ") -Foregroundcolor Red 						
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

SetRelevancyWeightForManagedProperty




# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaZN89w/OMde1BZe4A7p4KS3c
# RkigggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAN0ZOWCIOEyhtxA/koB0azqKK40Pw3fa8GLif/ZM0cXJWGawkVgxOMbejeJW
# YCqXgEHF2MX/cJY8svCmLlX8M7AdjXYgtAS+C+cEHxrGAMMzj3/9EOu6DjzxIcwL
# l1GKoUwy8X3/GRGk3sBWT5CwKYRJdh9goWy74ltZN+sTKKeDHqpfuvxye6c++PC7
# 86wzm4MwfOIuPE9StFeo/0nKheEukfK9cpthlE5dUHpW0OjmJdX/g0mEdIjm2/Q2
# 50fzQyLQXOuMVIJ4Qk2comMDNRvZZvSPOBwWZ6fAR4tXfZwlpUcLv3wBbIjslhT7
# XasCm73TdBj+ZFDx2tUtpWguP/0CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBS+FASXsrRle2tLXdkVyoT1Dbw7
# QDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAbhjcmv+WCZwWCIYQwiEsH94SesBr0cPqWjEtJrBefqU9zFdB
# u5oc/WytxdCkEj5bxkoN9aJmuDAZnHNHBwIYeUz0vNByZRz6HsPzNPxLxThajJTe
# YOHlSTMI/XzBhJ7VzCb3YFhkD5f9gcJ5n+Z94ebd/1SoIvc9iwC3tTf5x2O7aHPN
# iyoWLTV4+PgDntCy/YDj11+uviI9sUUjAajYPEDvoiWinyT+7RlbStlcEuBwqvqT
# nLaiRsK17rjawW87Nkq/jB8rymUR/fzluIpHmPA4P0NazH4v5f62mpMFqdk0osMU
# QJ/qqACQ+2+/eAw7Gr6igNvlsxQpPfxsPNtUkTCCBTAwggQYoAMCAQICEAQJGBtf
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
# Q0ECEAYOIt5euYhxb7GIcjK8VwEwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJVCssFU17dZyGjV
# Y3iSj5GyW8YgMA0GCSqGSIb3DQEBAQUABIIBAKNeBl3RxvbsK7CA06KAt4iCNBlo
# mO8nWtAfc646cA2PPHVC7wI3XbOGQrtnqiI14fTG1+p6EtWKItznpZv+7GVjIzdi
# E9XbQGvn+GGGfBwCLCivIneT6Fe5bRiadXzsGjthndFTLd/fRsxAE3CQjETn2xuf
# //BSiydN7IigCA7Vz330VIUZA5n95zlfx6MbrUc2aljeTvpWMGoA77HJvpTvZK37
# 0KvH3y1eIC8frBW7iddeJCH7WDp3xu0SdMg9SchxyRbAyhCwiyP6rm9PSprZ0uqH
# H3GTMgjO79D6gymqnBdusBaNVpSl6sFVXmX7khx+iPY1dyBzBdmamRHgY/c=
# SIG # End signature block
