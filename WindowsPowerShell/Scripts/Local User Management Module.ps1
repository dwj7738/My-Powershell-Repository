# --------------------------------- Meta Information for Microsoft Script Explorer for Windows PowerShell V1.0 ---------------------------------
# Title: Local User Management Module
# Author: IamMred
# Description: This Windows PowerShell module contains the following functions:<br />New-LocalGroup<br />New-LocalUser<br />Remove-LocalGro<wbr />up<br />Remove-LocalUse<wbr />r<br />Set-LocalGroup<br />Set-LocalUser<br />Set-LocalUserPa<wbr />ssword<br />Test-IsAdminist<wbr />rator
# Date Published: 29-Jun-2011 2:29:06 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/f75801e7-169a-4737-952c-1341abea5823
# Tags: local users
# ------------------------------------------------------------------

Function New-LocalUser
{
  <#
   .Synopsis
    This function creates a local user 
   .Description
    This function creates a local user
   .Example
    New-LocalUser -userName "ed" -description "cool Scripting Guy" `
        -password "password"
    Creates a new local user named ed with a description of cool scripting guy
    and a password of password. 
   .Parameter ComputerName
    The name of the computer upon which to create the user
   .Parameter UserName
    The name of the user to create
   .Parameter password
    The password for the newly created user
   .Parameter description
    The description for the newly created user
   .Notes
    NAME:  New-LocalUser
    AUTHOR: ed wilson, msft
    LASTEDIT: 06/29/2011 10:07:42
    KEYWORDS: Local Account Management, Users
    HSG: HSG-06-30-11
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 [CmdletBinding()]
 Param(
  [Parameter(Position=0,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$userName,
  [Parameter(Position=1,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$password,
  [string]$computerName = $env:ComputerName,
  [string]$description = "Created by PowerShell"
 )
 $computer = [ADSI]"WinNT://$computerName"
 $user = $computer.Create("User", $userName)
 $user.setpassword($password)
 $user.put("description",$description) 
 $user.SetInfo()
} #end function New-LocalUser

Function New-LocalGroup
{
 <#
   .Synopsis
    This function creates a local group 
   .Description
    This function creates a local group
   .Example
    New-LocalGroup -GroupName "mygroup" -description "cool local users"
    Creates a new local group named mygroup with a description of cool local users. 
   .Parameter ComputerName
    The name of the computer upon which to create the group
   .Parameter GroupName
    The name of the Group to create
   .Parameter description
    The description for the newly created group
   .Notes
    NAME:  New-LocalGroup
    AUTHOR: ed wilson, msft
    LASTEDIT: 06/29/2011 10:07:42
    KEYWORDS: Local Account Management, Groups
    HSG: HSG-06-30-11
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 [CmdletBinding()]
 Param(
  [Parameter(Position=0,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$GroupName,
  [string]$computerName = $env:ComputerName,
  [string]$description = "Created by PowerShell"
 )
 
  $adsi = [ADSI]"WinNT://$computerName"
  $objgroup = $adsi.Create("Group", $groupName)
  $objgroup.SetInfo()
  $objgroup.description = $description
  $objgroup.SetInfo()
 
} #end function New-LocalGroup

Function Set-LocalGroup
{
  <#
   .Synopsis
    This function adds or removes a local user to a local group 
   .Description
    This function adds or removes a local user to a local group
   .Example
    Set-LocalGroup -username "ed" -groupname "administrators" -add
    Assigns the local user ed to the local administrators group
   .Example
    Set-LocalGroup -username "ed" -groupname "administrators" -remove
    Removes the local user ed to the local administrators group
   .Parameter username
    The name of the local user
   .Parameter groupname
    The name of the local group
   .Parameter ComputerName
    The name of the computer
   .Parameter add
    causes function to add the user
   .Parameter remove
    causes the function to remove the user
   .Notes
    NAME:  Set-LocalGroup
    AUTHOR: ed wilson, msft
    LASTEDIT: 06/29/2011 10:23:53
    KEYWORDS: Local Account Management, Users, Groups
    HSG: HSG-06-30-11
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 [CmdletBinding()]
 Param(
  [Parameter(Position=0,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$userName,
  [Parameter(Position=1,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$GroupName,
  [string]$computerName = $env:ComputerName,
  [Parameter(ParameterSetName='addUser')]
  [switch]$add,
  [Parameter(ParameterSetName='removeuser')]
  [switch]$remove
 )
 $group = [ADSI]"WinNT://$ComputerName/$GroupName,group"
 if($add)
  {
   $group.add("WinNT://$ComputerName/$UserName")
  }
  if($remove)
   {
   $group.remove("WinNT://$ComputerName/$UserName")
   }
} #end function Set-LocalGroup

Function Set-LocalUserPassword
{
 <#
   .Synopsis
    This function changes a local user password 
   .Description
    This function changes a local user password
   .Example
    Set-LocalUserPassword -userName "ed" -password "newpassword"
    Changes a local user named ed password to newpassword.
   .Parameter ComputerName
    The name of the computer upon which to change the user's password
   .Parameter UserName
    The name of the user for which to change the password
   .Parameter password
    The new password for the user
   .Notes
    NAME:  Set-LocalUserPassword
    AUTHOR: ed wilson, msft
    LASTEDIT: 06/29/2011 10:07:42
    KEYWORDS: Local Account Management, Users
    HSG: HSG-06-30-11
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 [CmdletBinding()]
 Param(
  [Parameter(Position=0,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$userName,
  [Parameter(Position=1,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$password,
  [string]$computerName = $env:ComputerName
 )
 $user = [ADSI]"WinNT://$computerName/$username,user"
 $user.setpassword($password) 
 $user.SetInfo()
} #end function Set-LocalUserPassword

function Set-LocalUser
{
  <#
   .Synopsis
    Enables or disables a local user 
   .Description
    This function enables or disables a local user
   .Example
    Set-LocalUser -userName ed -disable
    Disables a local user account named ed
   .Example
    Set-LocalUser -userName ed -password Password
    Enables a local user account named ed and gives it the password password 
   .Parameter UserName
    The name of the user to either enable or disable
   .Parameter Password
    The password of the user once it is enabled
   .Parameter Description
    A description to associate with the user account
   .Parameter Enable
    Enables the user account
   .Parameter Disable
    Disables the user account
   .Parameter ComputerName
    The name of the computer on which to perform the action
   .Notes
    NAME:  Set-LocalUser
    AUTHOR: ed wilson, msft
    LASTEDIT: 06/29/2011 12:40:43
    KEYWORDS: Local Account Management, Users
    HSG: HSG-6-30-2011
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 [CmdletBinding()]
 Param(
  [Parameter(Position=0,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$userName,
  [Parameter(Position=1,
      Mandatory=$True,
      ValueFromPipeline=$True,
      ParameterSetName='EnableUser')]
  [string]$password,
  [Parameter(ParameterSetName='EnableUser')]
  [switch]$enable,
  [Parameter(ParameterSetName='DisableUser')]
  [switch]$disable,
  [string]$computerName = $env:ComputerName,
  [string]$description = "modified via powershell"
 )
 $EnableUser = 512 # ADS_USER_FLAG_ENUM enumeration value from SDK
 $DisableUser = 2  # ADS_USER_FLAG_ENUM enumeration value from SDK
 $User = [ADSI]"WinNT://$computerName/$userName,User"
 
 if($enable)
  {
      $User.setpassword($password)
      $User.description = $description
      $User.userflags = $EnableUser
      $User.setinfo()
  } #end if enable
 if($disable)
  {
      $User.description = $description
      $User.userflags = $DisableUser
      $User.setinfo()
  } #end if disable
} #end function Set-LocalUser

Function Remove-LocalUser
{
 <#
   .Synopsis
    This function deletes a local user 
   .Description
    This function deletes a local user
   .Example
    Remove-LocalUser -userName "ed" 
    Removes a new local user named ed. 
   .Parameter ComputerName
    The name of the computer upon which to delete the user
   .Parameter UserName
    The name of the user to delete
   .Notes
    NAME:  Remove-LocalUser
    AUTHOR: ed wilson, msft
    LASTEDIT: 06/29/2011 10:07:42
    KEYWORDS: Local Account Management, Users
    HSG: HSG-06-30-11
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 [CmdletBinding()]
 Param(
  [Parameter(Position=0,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$userName,
  [string]$computerName = $env:ComputerName
 )
 $User = [ADSI]"WinNT://$computerName"
 $user.Delete("User",$userName)
} #end function Remove-LocalUser

Function Remove-LocalGroup
{
 <#
   .Synopsis
    This function deletes a local group 
   .Description
    This function deletes a local group
   .Example
    Remove-LocalGroup -GroupName "mygroup" 
    Creates a new local group named mygroup. 
   .Parameter ComputerName
    The name of the computer upon which to delete the group
   .Parameter GroupName
    The name of the Group to delete
   .Notes
    NAME:  Remove-LocalGroup
    AUTHOR: ed wilson, msft
    LASTEDIT: 06/29/2011 10:07:42
    KEYWORDS: Local Account Management, Groups
    HSG: HSG-06-30-11
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 [CmdletBinding()]
 Param(
  [Parameter(Position=0,
      Mandatory=$True,
      ValueFromPipeline=$True)]
  [string]$GroupName,
  [string]$computerName = $env:ComputerName
 )
 $Group = [ADSI]"WinNT://$computerName"
 $Group.Delete("Group",$GroupName)
} #end function Remove-LocalGroup

function Test-IsAdministrator
{
    <#
    .Synopsis
        Tests if the user is an administrator
    .Description
        Returns true if a user is an administrator, false if the user is not an administrator        
    .Example
        Test-IsAdministrator
    #>   
    param() 
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
} #end function Test-IsAdministrator
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxQ8k0R9MDIfItyUGZvKoy1EE
# 8PugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEpkzSOOkXVpw/e6
# ayq9cqkrqnGFMA0GCSqGSIb3DQEBAQUABIIBAH+ofeoZQq52HW3KTMU+5c50F1Qt
# H4Dipf6IkPdBa8nMNo6YXO151/xT04OL6IWg4GtgUOlphx/U1h29w0QTgJ54a9cP
# lGu1EJbzmbik2rlptUbqso5XZoF9EDFVhjfibJmW4QSh82nYy3r1r2HfRBUjW8cY
# W7XJSl/DKB8KPNwPgtXRvQD/rq+kJVSpcQgatH36Cl4RkFCQDSi6YMWij0Dm4d2y
# 5Qi0JBz6+ChdW7qvofOedMj44latw+iqdJWnM0DLAYz7BXL3UjkvfejJ209JDdbT
# m6s2osg2nE7vHUng3W6Xb9F2zy7/pmoH9ZsF6YZu28zX78DGe7t3DI7PcY8=
# SIG # End signature block
