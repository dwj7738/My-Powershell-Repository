## =====================================================================
## Title       : Set-IADUser
## Description : Modify attributes of a user object in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       :   Set-IADUser [[-DistinguishedName] <String>] [[-sAMAccountname] <String>] [[-FirstName] <String>] [[-LastName] <String>]
##                     [[-Initials] <String>] [[-Description] <String>] [[-UserPrincipalName] <String>] [[-DisplayName] <String>] 
##                     [[-Office] <String>] [[-Department] <String>] [[-ManagerDN] <String>] [[-EmployeeID] <String>] [[-EmployeeNumber] <String>]
##                     [[-HomeDirectory] <String>] [[-HomeDrive] <String>] [[-Mobile] <String>] [[-Password] <String>] 
##                     [[-UserMustChangePassword] <Object>] [[-PasswordNeverExpires] <Object>]
##   
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       :
##               1. Sets the FirstName, LastName and Initials of a user
##               Get-IADUser User1 | Set-IADUser -FirstName Heli -LastName Copter -Initials HC
##
##               2. Set the HomeDirectory and HomeDrive for User1
##               Get-IADUser User1 | Set-IADUser -HomeDirectory '\\server\share\user1' -HomeDrive 'H:'
##
##               3. Set the Office attribute for all users in the Test OU
##               Get-IADUser -SearchRoot 'OU=TEST,DC=Domain,DC=com' | Set-IADUser -Description TestUsers -Office QA
##
##               4. Set the Description attribute for all users in the Test OU and password to never expiry
##               Get-IADUser -SearchRoot 'OU=TEST,DC=Domain,DC=com' | Set-IADUser -Description TestUsers -PasswordNeverExpires  
##            
## Notes       :
## Tag         : user, activedirectory
## Change log  :
## =====================================================================


filter Set-IADUser {
 param(
  [string]$DistinguishedName,
  [string]$sAMAccountname,
  [string]$FirstName,
  [string]$LastName,
  [string]$Initials,
  [string]$Description,
  [string]$UserPrincipalName,
  [string]$DisplayName,
  [string]$Office,
  [string]$Department,
  [string]$ManagerDN,
  [string]$EmployeeID,
  [string]$EmployeeNumber,
  [string]$HomeDirectory,
  [string]$HomeDrive,
  [string]$Mobile,
  [string]$Password,
  $UserMustChangePassword,
  $PasswordNeverExpires  
 ) 
  


 
 function Convert-IADSLargeInteger([object]$LargeInteger){
  
  $type = $LargeInteger.GetType()
  $highPart = $type.InvokeMember("HighPart","GetProperty",$null,$LargeInteger,$null)
  $lowPart = $type.InvokeMember("LowPart","GetProperty",$null,$LargeInteger,$null)
 
  $bytes = [System.BitConverter]::GetBytes($highPart)
  $tmp = New-Object System.Byte[] 8
  [Array]::Copy($bytes,0,$tmp,4,4)
  $highPart = [System.BitConverter]::ToInt64($tmp,0)
  $bytes = [System.BitConverter]::GetBytes($lowPart)
  $lowPart = [System.BitConverter]::ToUInt32($bytes,0)
 
  $lowPart + $highPart
 } 
  

 if($_ -is [ADSI] -and $_.psbase.SchemaClassName -eq 'User')
 {
  $user = $_
 }
 else
 {
     if($DistinguishedName)
     {    
   if(![ADSI]::Exists("LDAP://$DistinguishedName"))
      {
       Write-Error "The user '$DistinguishedName' doesn't exist"
       return
      }
      else
      { 
       $user = [ADSI]"LDAP://$DistinguishedName"
      }
     }
  else
  {
   Write-Error "'DistinguishedName' cannot be empty."
   return   
  }
 }
  
 if($sAMAccountname)
 {
  $null = $user.put("sAMAccountname",$sAMAccountname)
 }
 
 if ($FirstName)
 {
  $null = $user.put("givenName",$FirstName)
 } 
 
 if ($LastName)
 {
  $null = $user.put("sn",$LastName)
 } 
 
 if ($Initials)
 {
  $null = $user.put("initials",$Initials)
 } 
 
 if ($Description)
 {
  $null = $user.put("Description",$Description)
 }
 
 if ($UserPrincipalName)
 {
  $null = $user.put("userPrincipalName",$UserPrincipalName)
 }
 
 if ($UserPrincipalName)
 {
  $null = $user.put("userPrincipalName",$UserPrincipalName)
 }
 
 if($DisplayName)
 {
  $null = $user.put("displayName",$DisplayName)
 }
 
 if ($Office)
 {
  $null = $user.put("physicalDeliveryOfficeName",$Office)
 } 
 
 if ($Department)
 {
  $null = $user.put("department",$Department)
 } 
 
 if($ManagerDN)
 {
  if( ![ADSI]::Exists("LDAP://$ManagerDN"))
  {
   Write-Warning "Manager object '$ManagerDN' doesn't exist"
  }
  else
  {
   $m = [ADSI]"LDAP://$ManagerDN"
   if($m.psbase.SchemaClassName -notmatch 'User|Contact')
   {
    Throw "Wrong object type. Must be 'User' or 'Contact'."
   }
   else
   {
    $null = $user.put("manager",$ManagerDN)
    $null = $user.SetInfo() 
   } 
  }
 }
 
 if($EmployeeID)
 {
  $null = $user.psbase.Invoke("employeeID",$EmployeeID)             
 } 
 
 if($EmployeeNumber)
 {
  $null = $user.psbase.Invoke("employeeNumber",$EmployeeNumber)             
 }
 
 if($HomeDirectory)
 {
  $null = $user.psbase.Invoke("homeDirectory",$HomeDirectory)             
 }
 
 if($HomeDrive)
 {
  $null = $user.psbase.Invoke("homeDrive",$HomeDrive)             
 }
 
 if($Mobile)
 {
  $null = $user.psbase.InvokeSet("mobile",$Mobile)             
 }
 
 if($Password)
 {
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
  $null = $user.psbase.Invoke("setpassword",$Password)             
 } 

 if($UserMustChangePassword -is [bool])
 {
  if($UserMustChangePassword)
  {
   if ($user.userAccountControl[0] -band 65536)
   {
    $err = 'The password is already set to never expire.'
    $err += ' The user will not be required to change the password at next logon.'
    Write-Warning $err
   }
   elseif ($PasswordNeverExpires -and $PasswordNeverExpires -is [bool])
   {
    $err = 'You specified that the password should never expire.'
    $err += ' The user will not be required to change the password at next logon.'
    Write-Warning $err
   }
   else
   {
    $null = $user.pwdLastset=0
   }
  }
 }
 else
 {
  if($UserMustChangePassword -ne $null)
  {
   Write-Error "Parameter UserMustChangePassword only accept booleans, use $true, $false, 1 or 0 instead."
  }
 } 
  

 if($PasswordNeverExpires -is [bool])
 {
  if($PasswordNeverExpires)
  {
   $pwdLastSet = Convert-IADSLargeInteger $user.pwdLastSet[0]
   
   if ($pwdLastSet -eq 0)
   {
    $err = 'You specified that the password should never expire.'
    $err += "The attribute 'User must change password at next logon' will be unchecked."
    Write-Warning $err
   }
   
   $user.userAccountControl[0] = $user.userAccountControl[0] -bor 65536
  }
 }
 else
 {
  if($PasswordNeverExpires -ne $null)
  {
   Write-Error "Parameter PasswordNeverExpires only accept booleans, use $true, $false, 1 or 0 instead."
  }
 } 
 $null = $user.SetInfo()
 $user
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU71KS15iCK5MyRD4O5jHPlTa2
# gZGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFOLn5rf6lpjj+Q1d
# yPT0VU73KxazMA0GCSqGSIb3DQEBAQUABIIBAHDh00DVprYOUldkA0DUTEL3MOAE
# 4zFt4yKi7OGnZebMBi0iYLn6Ir/PwEncIOMmWAw5l5pPrvFnL2uExt8190VTAjPQ
# 0D9rWGRE3Iq2IwbHY4XTRq34z6tQzfTKPHcVeS904X+9TJULT16KN7I7kZPHo8UI
# Izud0jJEqmjTkkY/BNeemCTU9wdvtfoLqFHui9+CufrFgEzdPH3T9UZYl96KgtVc
# yao68aDLLf5pZywD3yOrXlP1E/HXNenNngmDYBVy8qioP/wNc8k4hXWGr6kMmyHe
# Ti/bR0Hb/VdBvzFatBA7tjWNrtEs/9oLfEz7nZi+wmthrw1DdFwJpYmr4Po=
# SIG # End signature block
