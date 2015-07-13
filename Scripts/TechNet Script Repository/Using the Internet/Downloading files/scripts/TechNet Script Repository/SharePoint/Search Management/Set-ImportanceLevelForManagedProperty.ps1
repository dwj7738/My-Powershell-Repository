<#
.SYNOPSIS
       The purpose of this script is to set the importance level for a FAST Managed Property
.DESCRIPTION
       The purpose of this script is to set the importance level for a FAST Managed Property. 
	   You must specify a managed property name and the importance level. The importance level
	   needs to be a number between 1 and 7. The full text index name is optional and will default
	   to content if you do not specify one. This script can be used in conjunction with Get-ImportanceLevelForManagedProperty.
	   
.EXAMPLE
.\Set-ImportanceLevelForManagedProperty.ps1 -DebugMode -fullTextIndexName content -managedPropertyName Keywords -importanceLevel 7

Output:
Importance level correctly set for Managed Property:Keywords in Full Text Index:content to:7

.EXAMPLE
.\Set-ImportanceLevelForManagedProperty.ps1 -managedPropertyName Keywords -importanceLevel 7

Output:
Using default full text index name:content
Importance level for Managed Property:Keywords in Full Text Index:content is set to:4 Expected:7
Updated Importance level for Managed Property:Keywords in Full Text Index:content to:7

.LINK
This Script - http://gallery.technet.microsoft.com/scriptcenter/6c246f1e-75e7-478c-a514-a33a37f353c6
.NOTES
  File Name : Set-ImportanceLevelForManagedProperty.ps1
  Author    : Ben Lin, Brent Groom 
#>

# TODO - implement uninstall, drive from config file, use return codes

param
  (
	
 	[switch]
    # Signifies that the script should output debug statements
    $DebugMode, 
   
 	[string]
    # Allows you to specify the name of the rank profile
	$fullTextIndexName = "",
    
	[string]
    # name of the managed property
	$managedPropertyName = "",
    
	[int]
    # Allows you to specify the expected weight 
	$importanceLevel = 100
    
    )

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

function setImportanceLevelForMP ( )
{
	if($managedPropertyName.Length -eq 0)
	{
		write-host ("You must specify a valid managed property name") -Foregroundcolor Red 		
		return
	}
	
	# Check the importance level
	$mp = Get-FASTSearchMetadataManagedProperty -Name $managedPropertyName
	if($mp -eq $null)
	{
		write-host ("You must specify a valid managed property name") -Foregroundcolor Red 		
		return
	}
	
	$fullTextIndexesEnum  = $mp.GetFullTextIndexMappings()
	
	if($fullTextIndexName.Length -eq 0)
	{
	    $fullTextIndexName = "content"
		write-host ("Using default full text index name:$fullTextIndexName") -Foregroundcolor Red 
	}
	if($importanceLevel -lt 1 -or $importanceLevel -gt 7)
	{
		write-host ("You must specify a valid importance level. Please choose a number between 1 and 7.") -Foregroundcolor Red 
		return
	}
    
	
	$hasmappings = $false
	foreach($index in $fullTextIndexesEnum)
	{
		
		if($index.FullTextIndex.Name -ne $fullTextIndexName)
		{
			continue
		}
		$hasmappings = $true
		
		if($index.ImportanceLevel -ne $importanceLevel)
		{
			write-host ("Importance level for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName is set to:"+$index.ImportanceLevel+" Expected:$importanceLevel") -Foregroundcolor Red 
			$fuu = Get-FASTSearchMetadataFullTextIndexMapping|Where-Object {$_.ManagedProperty.Name -eq $managedPropertyName}
			Remove-FASTSearchMetadataFullTextIndexMapping -Mapping $fuu
			$newMapping = New-FASTSearchMetadataFullTextIndexMapping –ManagedProperty (Get-FASTSearchMetadataManagedProperty $managedPropertyName) –FullTextIndex (Get-FASTSearchMetadataFullTextIndex $fullTextIndexName) –Level $importanceLevel
			write-host ("Updated Importance level for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName to:$importanceLevel") -Foregroundcolor Yellow 				
			
		}
		elseif($index.ImportanceLevel -eq $importanceLevel)
		{
			write-host ("Importance level correctly set for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName to:$importanceLevel") -Foregroundcolor Green 				
		
		}
	}
	if($hasmappings -eq $false)
	{
		write-host ("Could not find Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName") -Foregroundcolor Yellow 				
		$newMapping = New-FASTSearchMetadataFullTextIndexMapping –ManagedProperty (Get-FASTSearchMetadataManagedProperty $managedPropertyName) –FullTextIndex (Get-FASTSearchMetadataFullTextIndex $fullTextIndexName) –Level $importanceLevel
		write-host ("Updated Importance level for Managed Property:$managedPropertyName in Full Text Index:$fullTextIndexName to:$importanceLevel") -Foregroundcolor Yellow 				
	
	}

}

if($DebugMode)
{
	"Using following values:"
	"  DebugMode:$DebugMode"
	"  fullTextIndexName:$fullTextIndexName"
	"  ManagedPropertyName:$ManagedPropertyName"
	"  importanceLevel:$importanceLevel"

}

setImportanceLevelForMP 




# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwJo4h88lrx68CNy4DtKwvpRB
# 39SgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFOCYqTtOm5CezxkD
# mawUYlFkfjryMA0GCSqGSIb3DQEBAQUABIIBAImri0GtoiijgT6sO2GugB1Wxtru
# jKqTCx5JzrHBrtdeO2px0B3m40MwEJHwyrr3IdYLIwdU0Mi1uizJuK6gfab4B34Z
# UYAZeq621OJFJE7nSzNgZf7VlRhgcFDn/jPaabtQj6DoeYDqeQ9OwcIMccG8QQ/V
# fMxr+58VvEpgfJdo/pw5oQR8UTHf8zn99zzPsy/i6gdXqVKsUMQkvRXJyhcDnb68
# yw17eJfPOTc0BODiZDZxkGoMe0eWCKNgumNCxdiw1OTRUagmVh0q3+PJXRZnH6pt
# Rn6JNv/qqc8FkS/bl7Rdji43bbqBpWO1W3UjmlLxkdDiRDgppKZ5ZepMl4s=
# SIG # End signature block
