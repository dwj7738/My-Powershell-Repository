## =====================================================================
## Title       : Get-IADGroup
## Description : Retrieve all groups in a domain or container that match the specified conditions.
## Author      : Idera
## Date        : 8/11/2009
## Input       : Get-IADGroup [[-Name] <String>] [[-SearchRoot] <String>] [[-PageSize] <Int32>] [[-SizeLimit] <Int32>] [[-SearchScope] <String>] [[-GroupType] <String>] [[-GroupScope] <String>]
##                    
## Output      : System.DirectoryServices.DirectoryEntry 
##
## Usage       :
##               1. Retrieve distribution groups which name starts with 'test'
##               Get-IADGroup -Name test* -GroupType distribution
##
##               2. Retrieve all universal security groups
##               Get-IADGroup -GroupType security -GroupScope universal
## Notes       :
## Tag         : group, activedirectory
## Change log  :
## =====================================================================  
  
function Get-IADGroup {
 param(
  [string]$Name = "*",
  [string]$SearchRoot,
  [int]$PageSize = 1000,
  [int]$SizeLimit = 0,
  [string]$SearchScope = "SubTree",
  [string]$GroupType,
  [string]$GroupScope
 ) 

  


 if($SearchScope -notmatch '^(Base|OneLevel|Subtree)$')
 {
  Throw "SearchScope Value must be one of: 'Base','OneLevel or 'Subtree'"
 } 


 # validating group type values
 if($GroupType -ne "" -or $GroupType)
 {
  if($GroupType -notmatch '^(Security|Distribution)$')
  {
   Throw "GroupType Value must be one of: 'Security' or 'Distribution'"
  }
 }
  
  
 # validating group scope values
 if($GroupScope -ne "" -or $GroupScope)
 {
  if($GroupScope -notmatch '^(Universal|Global|DomainLocal)$')
   {
   Throw "GroupScope Value must be one of: 'Universal', 'Global' or 'DomainLocal'"
  }
 } 

  

 $resolve = "(|(sAMAccountName=$Name)(cn=$Name)(name=$Name))" 


 $parameters = $GroupScope,$GroupType
 
 switch (,$parameters)
 {
  @('Universal','Distribution') {$filter = "(&(objectcategory=group)(sAMAccountType=268435457)(grouptype:1.2.840.113556.1.4.804:=8)$resolve)"}
  @('Universal','Security') {$filter = "(&(objectcategory=group)(sAMAccountType=268435456)(grouptype:1.2.840.113556.1.4.804:=-2147483640)$resolve)"}
  @('Global','Distribution') {$filter = "(&(objectcategory=group)(sAMAccountType=268435457)(grouptype:1.2.840.113556.1.4.804:=2)$resolve)"}
  @('Global','Security') {$filter = "(&(objectcategory=group)(sAMAccountType=268435456)(grouptype:1.2.840.113556.1.4.803:=-2147483646)$resolve)"}
  @('DomainLocal','Distribution') {$filter = "(&(objectcategory=group)(sAMAccountType=536870913)(grouptype:1.2.840.113556.1.4.804:=4)$resolve)"}
  @('DomainLocal','Security') {$filter = "(&(objectcategory=group)(sAMAccountType=536870912)(grouptype:1.2.840.113556.1.4.804:=-2147483644)$resolve)"}
  @('Global','') {$filter = "(&(objectcategory=group)(grouptype:1.2.840.113556.1.4.804:=2)$resolve)"}
  @('DomainLocal','') {$filter = "(&(objectcategory=group)(grouptype:1.2.840.113556.1.4.804:=4)$resolve)"}
  @('Universal','') {$filter = "(&(objectcategory=group)(grouptype:1.2.840.113556.1.4.804:=8)$resolve)"}
  @('','Distribution') {$filter = "(&(objectCategory=group)(!groupType:1.2.840.113556.1.4.803:=2147483648)$resolve)"}
  @('','Security') {$filter = "(&(objectcategory=group)(groupType:1.2.840.113556.1.4.803:=2147483648)$resolve)"}
  default {$filter = "(&(objectcategory=group)$resolve)"}
 }
 
  


 $root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
 $searcher = New-Object System.DirectoryServices.DirectorySearcher $filter 

       
 if($SearchRoot -eq [string]::Empty)
 {
  $SearchRoot=$root.defaultNamingContext
 }
 elseif( ![ADSI]::Exists("LDAP://$SearchRoot"))
 {
  Throw "SearchRoot value: '$SearchRoot' is invalid, please check value"
 } 


 $searcher.SearchRoot = "LDAP://$SearchRoot"
 $searcher.SearchScope = $SearchScope
 $searcher.SizeLimit = $SizeLimit
 $searcher.PageSize = $PageSize
 $searcher.FindAll() | Foreach-Object { $_.GetDirectoryEntry() }

}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWvvnwZHAAtzLJLBGAeXsyrOR
# CMCgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLK5RRHKgVbxgRiG
# aBLE8SfK5gTQMA0GCSqGSIb3DQEBAQUABIIBAFRlgzaG8B/hgCoLQeM1cKoMhQs4
# PRAueMGPeleJNCsmdFiERYqnfr3pYWkO8isAUiIFXedU5pJir4CpOvtYOvXDC8Z+
# qiFDoIrBt2aMaqotlihMxD6IBdbNcvK7YvLqJKS3RaOFl3xvHS+klosy86eI2eDB
# 0e1CXL9V7vUIVcUj9hElQaaQyAlHeT2v3zWtImjwnwoaIPRsjBbMAzLn3t7kSsg5
# f3/Hp0RIUCVzhQfckqo042kXpH1UCr7H/GFnivp5MIQVzpb41zGHkphlrcn0ruxA
# x9WFtSBWxEUJJOm/gKdv11Ta07DT8cBg3Ob37aGkkL7IOOs6eH0L+vthV/A=
# SIG # End signature block
