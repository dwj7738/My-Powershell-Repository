<#
This script will find and print all orphaned Group Policy Objects (GPOs).
Group Policy Objects (GPOs) are stored in two parts:
1) GPC (Group Policy Container). The GPC is where the GPO stores all the AD-related configuration under the
   CN=Policies,CN=System,DC=... container, which is replicated via AD replication.
2) GPT (Group Policy Templates). The GPT is where the GPO stores the actual settings located within SYSVOL
   area under the Policies folder, which is replicated by either File Replication Services (FRS) or
   Distributed File System (DFS).

This script will help find GPOs that are missing one of the parts, which therefore makes it an orphaned GPO.

A GPO typically becomes orphaned in one of two different ways:
1) If the GPO is deleted directly through Active Directory Users and Computers or ADSI edit.
2) If the GPO was deleted by someone that had permissions to do so in AD, but not in SYSVOL. In this case,
   the AD portion of the GPO would be deleted but the SYSVOL portion of the GPO would be left behind.

Although orphaned GPT folders do no harm they do take up disk space and should be removed as a cleanup task.
Lack of permissions to the corresponding objects in AD could cause a false positive. Therefore, verify GPT
folders are truly orphaned before moving or deleting them.

Original script written by Sean Metcalf
http://blogs.metcorpconsulting.com/tech/?p=1076

Release 1.1
Modified by Jeremy@jhouseconsulting.com 29th August 2012

#>

$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
# Get AD Domain Name
$DomainDNS = $Domain.Name
# Get AD Distinguished Name
$DomainDistinguishedName = $Domain.GetDirectoryEntry() | select -ExpandProperty DistinguishedName  

$GPOPoliciesDN = "CN=Policies,CN=System,$DomainDistinguishedName"
$GPOPoliciesSYSVOLUNC = "\\$DomainDNS\SYSVOL\$DomainDNS\Policies"

Write-Host -ForegroundColor Green "Finding all orphaned Group Policy Objects (GPOs)...`n"

Write-Host -ForegroundColor Green "Reading GPO information from Active Directory ($GPOPoliciesDN)..."
$GPOPoliciesADSI = [ADSI]"LDAP://$GPOPoliciesDN"
[array]$GPOPolicies = $GPOPoliciesADSI.psbase.children
ForEach ($GPO in $GPOPolicies) { [array]$DomainGPOList += $GPO.Name }
#$DomainGPOList = $DomainGPOList -replace("{","") ; $DomainGPOList = $DomainGPOList -replace("}","")
$DomainGPOList = $DomainGPOList | sort-object 
[int]$DomainGPOListCount = $DomainGPOList.Count
Write-Host -ForegroundColor Green "Discovered $DomainGPOListCount GPCs (Group Policy Containers) in Active Directory ($GPOPoliciesDN)`n"

Write-Host -ForegroundColor Green "Reading GPO information from SYSVOL ($GPOPoliciesSYSVOLUNC)..."
[array]$GPOPoliciesSYSVOL = Get-ChildItem $GPOPoliciesSYSVOLUNC
ForEach ($GPO in $GPOPoliciesSYSVOL) {If ($GPO.Name -ne "PolicyDefinitions") {[array]$SYSVOLGPOList += $GPO.Name }}
#$SYSVOLGPOList = $SYSVOLGPOList -replace("{","") ; $SYSVOLGPOList = $SYSVOLGPOList -replace("}","")
$SYSVOLGPOList = $SYSVOLGPOList | sort-object 
[int]$SYSVOLGPOListCount = $SYSVOLGPOList.Count
Write-Host -ForegroundColor Green "Discovered $SYSVOLGPOListCount GPTs (Group Policy Templates) in SYSVOL ($GPOPoliciesSYSVOLUNC)`n"

## COMPARE-OBJECT cmdlet note:
## The => sign indicates that the item in question was found in the property set of the second object but not found in the property set for the first object. 
## The <= sign indicates that the item in question was found in the property set of the first object but not found in the property set for the second object.

# Check for GPTs in SYSVOL that don't exist in AD
[array]$MissingADGPOs = Compare-Object $SYSVOLGPOList $DomainGPOList -passThru | Where-Object { $_.SideIndicator -eq '<=' }
[int]$MissingADGPOsCount = $MissingADGPOs.Count
$MissingADGPOsPCTofTotal = $MissingADGPOsCount / $DomainGPOListCount
$MissingADGPOsPCTofTotal = "{0:p2}" -f $MissingADGPOsPCTofTotal  
Write-Host -ForegroundColor Yellow "There are $MissingADGPOsCount GPTs in SYSVOL that don't exist in Active Directory ($MissingADGPOsPCTofTotal of the total)"
If ($MissingADGPOsCount -gt 0 ) {
  Write-Host "These are:"
  $MissingADGPOs
}
Write-Host "`n"

# Check for GPCs in AD that don't exist in SYSVOL
[array]$MissingSYSVOLGPOs = Compare-Object $DomainGPOList $SYSVOLGPOList -passThru | Where-Object { $_.SideIndicator -eq '<=' }
[int]$MissingSYSVOLGPOsCount = $MissingSYSVOLGPOs.Count
$MissingSYSVOLGPOsPCTofTotal = $MissingSYSVOLGPOsCount / $DomainGPOListCount
$MissingSYSVOLGPOsPCTofTotal = "{0:p2}" -f $MissingSYSVOLGPOsPCTofTotal  
Write-Host -ForegroundColor Yellow "There are $MissingSYSVOLGPOsCount GPCs in Active Directory that don't exist in SYSVOL ($MissingSYSVOLGPOsPCTofTotal of the total)"
If ($MissingSYSVOLGPOsCount -gt 0 ) {
  Write-Host "These are:"
  $MissingSYSVOLGPOs
}
Write-Host "`n"

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUa05X+JqmZaDZcvk7k3OWHb+Q
# dhCgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFH1zkZ38CNTyYxSd
# HBkx0sdk/xruMA0GCSqGSIb3DQEBAQUABIIBAIXF5/9NG6b7CDIzmhXOk8/eAjZ0
# NwgK3m4FRPf94kdDlY5Gqkzdb28ERCEUql4XYxH5zq2V39We8GE+n5szAFpKLJM2
# 9GieFAj7UERw6eg5D3BcscAu/mTiHIZ821vL8vXxOLOkLszM8VfOA836Rra/xaX6
# YLS62IkLvq+UByn3fr+nMAItRFR575/+W2nlEZpkt03bmlJpZKn7fR+ilH/n6XDT
# JVZR6gBoG5MdtZu+Z2KXPqXEa3MG/Ni8dCaRpaLxtmwAlI1PziAFkB6QP1ubO8TT
# Qr6EN3QNZl/dNTuLPtgnccy1yh3MEmC0OxdYTvRgwgpsY9Kw/G2tzE5rTX8=
# SIG # End signature block
