## =====================================================================
## Title       : New-IADUser
## Description : Create a new user object in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : New-IADUser [[-Name] <String>] [[-sAMAccountName] <String>] [[-ParentContainer] <String>] [[-Password] <String>]             
##                     
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       :
##               1. Create new user in the Test OU and enable the account
##               New-IADUser -Name 'Idera User' -sAMAccountname 'IUser' -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd' -EnableAccount
##
##               2. Create new user in the Test OU and enable the account. The user will have to change password at next logon
##               New-IADUser -Name 'Idera User' -sAMAccountname 'IUser' -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd' -EnableAccount -UserMustChangePassword
##
##               3.Create new user in the Test OU and enable the account. The user password will not expire.
##               New-IADUser -Name 'Idera User' -sAMAccountname 'IUser' -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd' -EnableAccount -PasswordNeverExpires
##
##               4. Create disabled users from text file in the Test OU (spaces are not allowed in sAMAccountName )
##               Get-Content users.txt | foreach { New-IADUser -Name $_ -sAMAccountName ($_ -replace " ") -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd'} 
##            
## Notes       :
## Tag         : user, activedirectory
## Change log  :
## =====================================================================

function New-IADUser {  

 param(
  [string]$Name = $(Throw "Please enter a full user name."),
  [string]$sAMAccountName = $(Throw "Please enter a sAMAccountname."),
  [string]$ParentContainer = $(Throw "Please enter a parent container DN."),
  [string]$Password = $(Throw "Password cannot be empty"),
  [switch]$UserMustChangePassword,
  [switch]$PasswordNeverExpires,
  [switch]$EnableAccount
 ) 
  
 if($sAMAccountName -match '\s') 
 { 
    Write-Error "sAMAccountName cannot contain spaces"

    return 
 } 
  
  if( ![ADSI]::Exists("LDAP://$ParentContainer"))
  {
   Write-Error "ParentContainerject '$ParentContainer' doesn't exist" 
   return 
  }



 $filter = "(&(objectCategory=Person)(objectClass=User)(samaccountname=$sAMAccountname))"
 $root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
 $searcher = New-Object System.DirectoryServices.DirectorySearcher $filter
 $searcher.SearchRoot= "LDAP://"+$root.defaultNamingContext
 $searcher.SizeLimit = 0
 $searcher.PageSize = 1000
 $result = $searcher.FindOne() 
  
 if($result)
 {
  Throw "User with the same sAMAccountname already exists in your domain."
 } 

 if($UserMustChangePassword -and $PasswordNeverExpires) 
 {
  $err = 'You specified that the password should never expire.'
  $err += ' The user will not be required to change the password at next logon.'
  Write-Warning $err
 } 
  
 $Container = [ADSI]"LDAP://$ParentContainer"
 $user = $Container.Create("user","cn=$Name") 
 if($Name -match '\s')
 {
  $n = $Name.Split()
  $FirstName = $n[0]
  $LastName = "$($n[1..$n.length])"
  $null = $user.put("sn",$LastName)
 }
 else
 {
  $FirstName = $Name
 }
   
 $null = $user.put("givenName",$FirstName)
 $null = $user.put("displayName",$Name) 
 $suffix = $root.defaultNamingContext -replace "dc=" -replace ",","."
 $upn = "$samaccountname@$suffix"
 $null = $user.put("userPrincipalName",$upn)
 $null = $user.put("sAMAccountName",$sAMAccountName)
 $null = $user.SetInfo() 
 
 
 trap
 {
  $pwdPol = "The password does not meet the password policy requirements"
  $InnerException=$_.Exception.InnerException 
  if($InnerException -match $pwdPol)
  {
   $script:PasswordChangeError=$true
   Write-Error $InnerException
  }
  else
  {
   Write-Error $_
  } 
  continue
 }
  
 $null = $user.psbase.Invoke("SetPassword",$Password)
   
 
 if($UserMustChangePassword)
 {
  $null = $user.pwdLastset=0
 } 
 if($PasswordNeverExpires)
 {
  $null = $user.userAccountControl[0] = $user.userAccountControl[0] -bor 65536
 } 
 
 if($EnableAccount)
 {
  if($script:PasswordChangeError)
  {
   Write-Warning "Accound cannot be enabled since setting the password did not succeed."   
  }
  else
  {
   $null = $user.psbase.InvokeSet("AccountDisabled",$false)
  }
 }
 else
 {
  $null = $user.psbase.InvokeSet("AccountDisabled",$true)
 } 
 $null = $user.SetInfo()
 $user 
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3MZKBzYt5MXELCj5E1QETs9P
# 0Z6gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFNEh1ukzgSdkaPXM
# 4TfeaQnUfxJNMA0GCSqGSIb3DQEBAQUABIIBAH90VJcC0oL9mJ8iuMLR2jEAkXAp
# wKm3Bz3KeecW2BC2BkA1xL2FlA8/NrwhwL+gC8I2sgP+Wcjk5mzpuPGvTG7cofGs
# Ojz6bGhP6YTTgsRNUbLLVVJ2WE/mOEHk6s5hLEggwtzpFziaSIWxljdqXivQlDsr
# Kv4d8RVDEslQrr6mpyHmIvWNFB8Su4dvDdhiZHELhHGl9UDQWCbidvqktleYEOQV
# QsbvHl5GwAOv+uAxJqCt0CwtOnIQuHzdByhPEDQQZGa4Yip3DrN4paTQUWlIFE/o
# aSsCBOF6IoL9UJiiSxvq1NoaFaSa6s0TPnlLyY0YkEMpTcus3+U4fYiEpOI=
# SIG # End signature block
