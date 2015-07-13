###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl 
# DATE    : 26-04-2012 
# COMMENT : This script creates new Active Directory users
#           including different kind of properties based
#           on an input_create_ad_users.csv.
###########################################################
Import-Module ActiveDirectory
# Get current directory and set import file in variable
$path     = Split-Path -parent $MyInvocation.MyCommand.Definition
$newpath  = $path + "\import_create_ad_users.csv"
# Define variables
$log      = $path + "\create_ad_users.log"
$date     = Get-Date
$i        = 0
# Change this to the location you want the users to be created in your AD
$location = "CN=NewYork,$DC=corp,DC=techsupport4me,DC=com"
# FUNCTIONS
Function createUsers
{
  "Created following users (on " + $date + "): " | Out-File $log -append
  "--------------------------------------------" | Out-File $log -append
  $newpath
  $users = Import-CSV $newpath

ForEach  ($user in $users) 
    {
$CommonName = $user.FirstName + "."
if ($User.MiddleName.length -ge 0){
     $CommonName = $CommonName  + $user.MiddleName
     }
$CommonName = $CommonName + "." + $user.LastName
$CommonName

# A check for the country, because those were full names and need 
    # to be landcodes in order for AD to accept them. I used Netherlands 
    # as example
    If($User.CO -eq "Canada")
    {
      $User.CO = "CA"
    }
    If($User.CO -eq "United States")
    {
      $User.CO = "US"
    }
    If($User.CO -eq "France")
    {
      $User.CO = "FR"
    }
    # Replace dots / points (.) in names, because AD will error when a 
    # name ends with a dot (and it looks cleaner as well)
    
    # Create sAMAccountName according to this 'naming convention':
    # <FirstLetterInitials><FirstFourLettersLastName> for example
    # hhica
    $sam = $User.FirstName + $user.middlename + $User.LastName
    $sam = $sam.toLower()
    $sam
    
    Try   { $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$sam)" }
    Catch { }
    If(!$exists)
    {
      $i++
      New-ADUser -SamAccountName $sam -GivenName $user.FirstName 
      New-ADUser -City $user.City -Company "Tech Support 4 Me" -Department $user.department
     



-Intials $user.initials -
      # Set all variables according to the table names in the Excel 
      # sheet / import CSV. The names can differ in every project, but 
      # if the names change, make sure to change it below as well.
      $setpass = ConvertTo-SecureString -AsPlainText $User.Password -force
      New-ADUser $sam -GivenName $User.GivenName -Initials $User.Initials `
      -Surname $User.LastName -DisplayName $User.DisplayName -Office "New York" `
      -Description $User.Description -EmailAddress $User.Mail `
      -StreetAddress $User.StreetAddress -City $User.City `
      -PostalCode $User.PostalCode -Country $User.CO -UserPrincipalName $User.UPN `
      -Company $User.Company  -EmployeeID $User.EmployeeID `
      -Title $User.Title -OfficePhone $User.Phone -AccountPassword $setpass
 
      # Set an ExtensionAttribute
      $dn  = (Get-ADUser $sam).DistinguishedName
      $ext = [ADSI]"LDAP://$dn"
      If ($User.ExtensionAttribute1 -ne "" -And $User.ExtensionAttribute1 -ne $Null)
      {
        $ext.Put("extensionAttribute1", $User.ExtensionAttribute1)
        $ext.SetInfo()
      }
 
      # Move the user to the OU you set above. If you don't want to
      # move the user(s) and just create them in the global Users
      # OU, comment the string below
  #    Move-ADObject -Identity $dn -TargetPath $location
 
      # Rename the object to a good looking name (otherwise you see
      # the 'ugly' shortened sAMAccountNames as a name in AD. This 
      # can't be set right away (as sAMAccountName) due to the 20
      # character restriction
      $newdn = (Get-ADUser $sam).DistinguishedName
#      Rename-ADObject -Identity $newdn -NewName $CommonName
 
      $output  = $i.ToString() + ") Name: " + $CommonName + "  sAMAccountName: " 
      $output += $sam + "  Pass: " + $User.Password
      $output | Out-File $log -append
    }
    Else
    {
      "SKIPPED - ALREADY EXISTS OR ERROR: " + $CommonName | Out-File $log -append
    }
  }
  "----------------------------------------" + "`n" | Out-File $log -append
}


# RUN SCRIPT
createUsers
#Finished
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUz26KDbPGEBtsjt5yfzHj0xyH
# vlygggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFE1iERKsVE5SNOE7
# 1Oz4E6yMgeaIMA0GCSqGSIb3DQEBAQUABIIBAF3tz8FoQyMQa9S+i/ie8g3P7HUs
# UcBR3vdELqOrNwj1jdW1fYNfiPxFClx+JYbljhhox535jZxDIqWpwHZbJdjWq96+
# Qpe/YFvUavtBO3/WB5zHa0jX5NzMzhsSxS44ztpyMwQ1Gagy+n1IG145GmmYTf64
# 2WAMH04FSxjgb0jNCJ9ONz24qqF7MBpVVWgHX6tEecWma2MGNJf105DOuSirRpdF
# V8cyyv76A83tQK296OMTbG5ep3s2gjIrSk1dFoYsmD/u1SHSMzB9mDORHUpdw5MZ
# EiJtoWMafScmkC6SgqfofwtwjgZ6IEWmfN5sHjnQYTq8jf1NQgMYYtFPlWo=
# SIG # End signature block
