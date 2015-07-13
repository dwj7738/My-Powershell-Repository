# Copyright (c) Microsoft Corporation. All rights reserved.  
# 
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

# Synopsis: This script creates a user that can be used for testing connectivity 
#           for Client Access Servers. This script has to be run by an admin who 
#           has permissions to create users in the Active Directory. 
#

#
# This function generates a test user name based on a name prefix and length.
#

function GenerateTestUserName
{
param($namePrefix, $totalChars)

    $HexDigits = "0123456789ABCDEF"
    $GenCount = $totalChars - $namePrefix.Length
                    
    $provider = new-object System.Security.Cryptography.RNGCryptoServiceProvider
    $builder = new-object char[] $GenCount
    $data = new-object byte[] 4

    for($num = 0; ($num -lt $GenCount); $num++)
    {
        $provider.GetBytes($data)
        $index = ([System.BitConverter]::ToUInt32($data, 0) % $HexDigits.Length)
        $builder[$num] = $HexDigits[$index]
    }
    
    $name = $namePrefix
    foreach ($char in $builder)
    {
        $name += $char
    }
    
    return $name
}

#
# This function is used to generate a cryptographically-secure random password.
#

function GenerateSecureRandomPassword
{
param($PasswordLength)

    $UpperCaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $LowerCaseLetters = "abcdefghijklmnopqrstuvwxyz"
    $NumberChars = "0123456789"
    $SymbolChars = "`~!@#$%^*()_+-={}|[]:`";`'?,./"
    $PasswordChars = $LowerCaseLetters + $UpperCaseLetters + $NumberChars + $SymbolChars
                    
    $provider = new-object System.Security.Cryptography.RNGCryptoServiceProvider
    $builder = new-object char[] $PasswordLength
    $data = new-object byte[] 4

    for($num = 0; ($num -lt $PasswordLength); $num++)
    {
        $provider.GetBytes($data)
        $index = ([System.BitConverter]::ToUInt32($data, 0) % $PasswordChars.Length)
        $builder[$num] = $PasswordChars[$index]
    }

    $provider.GetBytes($data)
    $num2 = (([System.BitConverter]::ToUInt32($data, 0) % ($PasswordLength-1)) + 1)

    # Write some lower case characters to meet complexity requirements
    #
    for($num = 0; ($num -lt $num2); $num++)
    {
        $provider.GetBytes($data)
        $num3 = (([System.BitConverter]::ToUInt32($data, 0) % ($PasswordLength-1)) + 1)
        $provider.GetBytes($data)
        $builder[$num3] = $LowerCaseLetters[([System.BitConverter]::ToUInt32($data, 0) % $LowerCaseLetters.Length)]
    }

    $provider.GetBytes($data)
    $num2 = (([System.BitConverter]::ToUInt32($data, 0) % ($PasswordLength-1)) + 1)

    # Write some upper case characters to meet complexity requirements.
    #
    for($num = 0; ($num -lt $num2); $num++)
    {
        $provider.GetBytes($data)
        $num3 = (([System.BitConverter]::ToUInt32($data, 0) % ($PasswordLength-1)) + 1)
        $provider.GetBytes($data)
        $builder[$num3] = $UpperCaseLetters[([System.BitConverter]::ToUInt32($data, 0) % $UpperCaseLetters.Length)]
    }

    $provider.GetBytes($data)
    $num2 = (([System.BitConverter]::ToUInt32($data, 0) % ($PasswordLength-1)) + 1)

    # Write some symbols to meet complexity requirements.
    #
    for($num = 0; ($num -lt $num2); $num++)
    {
        $provider.GetBytes($data)
        $num3 = (([System.BitConverter]::ToUInt32($data, 0) % ($PasswordLength-1)) + 1)
        $provider.GetBytes($data)
        $builder[$num3] = $SymbolChars[([System.BitConverter]::ToUInt32($data, 0) % $SymbolChars.Length)]
    }

    $provider.GetBytes($data)
    $num2 = (([System.BitConverter]::ToUInt32($data, 0) % ($PasswordLength-1)) + 1)

    # Write some numbers to meet complexity requirements.
    #
    for($num = 0; ($num -lt $num2); $num++)
    {
        $provider.GetBytes($data)
        $num3 = (([System.BitConverter]::ToUInt32($data, 0) % ($PasswordLength-1)) + 1)
        $provider.GetBytes($data)
        $builder[$num3] = $NumberChars[([System.BitConverter]::ToUInt32($data, 0) % 10)]
    }

    $securePassword = new-object System.Security.SecureString
    $plaintext = ""
    foreach($char in $builder)
    {
      $securePassword.AppendChar($char)
      $plaintext += $char
    }
    
    write-host "Generated password:" $plaintext

    return $securePassword
}
    

#
# This function deletes all test user accounts from the test organization
#

function DeleteTestUserMailboxes
{
param($OrganizationId, $namePrefix)

    $mailboxes = get-mailbox -Organization $OrganizationId  -ErrorAction SilentlyContinue | where{$_.Name -like $NamePrefix+"*" }
    if ($mailboxes -ne $null)
    {
        foreach ($mailbox in $mailboxes)
        {
            write-host "Removing obsolete test mailbox:" $mailbox.Name
            remove-mailbox $mailbox -Confirm:$false
        }
    }
}

#
# This function creates the test user
#

function CreateTestUser
{
param($exchangeServer, $mailboxServer, $verbose)

  #
  # Create the CAS probing user with UPN.  The user will be searched for by the probing using UPN.  Note that this task must be run on
  # every mailbox server.
  #
  
  #
  #
  #
  
  $NamePrefix = "Extest_"
  $ADSiteName = (get-exchangeserver $(hostname)).Site.Name
  $SamAccountName = GenerateTestUserName $NamePrefix 20
  $UserName = $SamAccountName
  $ExchangeMonOrg = $ADSiteName + ".exchangemon.net"
  $UserPrincipalName =  $UserName + "@" + $ExchangeMonOrg
  
  write-host "===============================================================" 
  write-host "This script will create test user: $UserName"
  write-host "In the custom domain: $ExchangeMonOrg" 
  write-host "On mailbox server: $mailboxServer"
  write-host "===============================================================" 
  write-host 
  read-host "Type Control-Break to quit or Enter to continue"
  
  $OfferId = 2
  $ProgramId = "HostingSample"
  $Location = "us"
  
  $err= $null
  
  $orgCreated = $false

  $org = get-Organization $ExchangeMonOrg -ErrorAction SilentlyContinue
  if ($org -eq $null)
  {
    $AdminUser = "Administrator@" + $ExchangeMonOrg
    $org = new-organization -name $ExchangeMonOrg -domainname $ExchangeMonOrg -OfferId $OfferId -ProgramId $ProgramId -Location $Location -ErrorAction SilentlyContinue
    $orgCreated = $org -ne $null
  }
  
  if ($org -eq $null)
  {
     $err = "Could not find or create organization:" + $ExchangeMonOrg
  }
  else
  {
      # If organization already existed, delete test user mailboxes
      #
      if (!$orgCreated)
      {
          DeleteTestUserMailboxes $ExchangeMonOrg $NamePrefix
      }
      
      # Password length is 16 characters
      $MaxPasswordLength = 16

      "Generating secure password for the test user."
      $SecurePassword = GenerateSecureRandomPassword $MaxPasswordLength

      # Look up this user's mailbox
      #
      $newUser = $null
      $newUser = get-Mailbox -Organization:$ExchangeMonOrg -ErrorAction SilentlyContinue | where {$_.UserPrincipalName -eq $UserPrincipalName} 

      if ($newUser -ne $null)
      {
          $err = "There's an issue with the test user account. It already exists."
      }
      else
      {
        #
        # If there are multiple mailbox databases on this server, the user will be created in the last database returned
        #
        $mailboxDatabaseName = $null;
        get-MailboxDatabase -server $mailboxServer | foreach {$mailboxDatabaseName = $_.Guid.ToString()}
      
        if ($mailboxDatabaseName -ne $null)
        {
          write-host "Creating test user $UserName on:" $exchangeServer.Name
          write-host "In mailbox database:" $mailboxDatabaseName

          new-Mailbox -Name:$UserName -Alias:$UserName -SamAccountName:$SamAccountName -Password:$SecurePassword -Database:$mailboxDatabaseName -Organization:$ExchangeMonOrg -UserPrincipalName:$UserPrincipalName -ErrorVariable err -ErrorAction SilentlyContinue
          $newUser = get-Mailbox -Organization:$ExchangeMonOrg -ErrorAction SilentlyContinue | where {$_.UserPrincipalName -eq $UserPrincipalName} 
        }
        else
        {
          $err = "The server must have a mailbox database for creating the test user."
        }
      }
      
      if ($newUser -ne $null)
      {
        write-Host "UserPrincipalName: " $newUser.UserPrincipalName

        # Provide the newly creted user with Remote PowerShell support
        Set-User $newUser -RemotePowerShellEnabled:$true

        set-Mailbox $newUser -MaxSendSize:1000KB -MaxReceiveSize:1000KB -IssueWarningQuota:unlimited -ProhibitSendQuota:1000KB -ProhibitSendReceiveQuota:unlimited -HiddenFromAddressListsEnabled:$True

        #
        # Set the credentials and save them in the system
        #

        $Credentials = new-object System.Management.Automation.PSCredential ($UserPrincipalName, $securePassword)
      
        test-ActiveSyncConnectivity -ResetTestAccountCredentials -MailboxServer:($mailboxServer) -MailboxCredential:($Credentials) -Verbose:$Verbose -ErrorAction SilentlyContinue -ErrorVariable err
      }
  }

  #
  # Output any errors that may have occurred
  #
  if ($err -ne $null)
  {
    foreach ($e in $err)
    {
        if ($e.Exception -ne $null)
        {
            write-error $e.Exception
        }
        else
        {
            write-error $e
        }
    }
    
    return $false
  }
  
  return $true
  
}

#
# Script begins here
#

$Verbose = $true

# check for specified parameters.

if ($args.Count -gt 0) 
{
    $i = 0
    while($i -lt $args.Count)
    {
        switch($args[$i])
        {
            { $_ -eq "-Verbose" }
            { $Verbose = $args[$i + 1] }
        }
        $i = $i + 2
    }
}

$atLeastOneServer = $false
$pipedInput = $false
$expectedMailboxServerType = "Microsoft.Exchange.Data.Directory.Management.MailboxServer"
$mailboxServer = $null
$exchangeServer = $null

foreach ($mailboxServer in $Input)
{
  $pipedInput = $true
  if ($mailboxServer.GetType().ToString() -ne $expectedMailboxServerType)
  {
    write-Host "Skipping: " $mailboxServer " of type " $mailboxServer.GetType().ToString() ", expected type is " $expectedMailboxServerType
    continue;
  }
  $exchangeServer = get-ExchangeServer $mailboxServer
  if ($exchangeServer -ne $null)
  {
      $atLeastOneServer = $true
      break;
  }
}

$result = $true

if ($atLeastOneServer)
{
  $result = CreateTestUser $exchangeServer $mailboxServer $Verbose
}
elseif (!$pipedInput)
{
  $exchangeServer = get-ExchangeServer $(hostname.exe) -ErrorAction:SilentlyContinue
  if ($exchangeServer -ne $null)
  {
    if ($exchangeServer.IsMailboxServer)
    {
      $mailboxServer = get-MailboxServer $exchangeServer.Fqdn
      $result = CreateTestUser $exchangeServer $mailboxServer $Verbose
      $atLeastOneServer = $true
    }
  }
}

if (!$atLeastOneServer)
{
  write-Host
  write-Host "Please either run the command on an Exchange Mailbox Server or pipe at least one mailbox server into this task."
  write-Host "For example:"
  write-Host
  write-Host "  get-mailboxServer | new-TestCasConnectivityUser.Hosting.ps1"
  write-Host
  write-Host "or"
  write-Host
  write-Host "  get-mailboxServer MBXSERVER | new-TestCasConnectivityUser.Hosting.ps1"
  write-Host
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUf39pTqDBS0X9yZDBCnJt1G7w
# TQGgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFBj66zdPFRO8yXnB
# Kqn7nSlpj4DRMA0GCSqGSIb3DQEBAQUABIIBANfBQ68JiKGI0wgE0kLjA29hyATy
# EtI50lgwWnbNaI3Lep3n3Dsnu0fwt0Jzeg6/++Q7+XVjO8w3WjZg4rMvKsxM4lsS
# Wn5FF1lA62A1cPy0KIMXK1qr+7c7ciPqf5FacjPyxf68NJ1Aj6V14I7W3L0SG6nN
# OfCrDx3YVeSIQGcHQmSQBEXx6uzBq5/1+tp/V1euWyklWdTKPPpkO+RTZhmPaFr8
# ms2uEBWGmzTq/lCfGHLa5Vfucz4mBp6JKWSZQbr5kYCvhtOaiil1yCXwt3qDu7hU
# hDB8gCoAzM1nZg9+hzkKmcy2GdTcvCOlsy8oZKr8XT/ud9yjcurXQZTCdLs=
# SIG # End signature block
