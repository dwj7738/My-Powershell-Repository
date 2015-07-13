# Copyright (c) Microsoft Corporation. All rights reserved.  
# 
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

# Synopsis: This script creates a user that can be used for testing connectivity 
#           for Client Access Servers. This script has to be run by an admin who 
#           has permissions to create users in the Active Directory. 
#


function CreateTestUser
{
param($exchangeServer, $mailboxServer, $securePassword, $OrganizationalUnit, $UMDialPlan, $UMExtension, $Prompt)

  #
  # Create the CAS probing user with UPN.  The user will be searched for by the probing using UPN.  Note that this task must be run on
  # every mailbox server.
  #
  $adSiteGuidLeft13 = $exchangeServer.Site.ObjectGuid.ToString().Replace("-","").Substring(0, 13);
  $UserName = "extest_" + $adSiteGuidLeft13;
  $SamAccountName = "extest_" + $adSiteGuidLeft13;
  $UserPrincipalName =  $SamAccountName + "@" + $exchangeserver.Domain
  
  $err= $null
  
  #
  # Create the mailbox if the user doen't exist.  Otherwise just look up this user's mailbox
  #
  $newUser = $null
  $newUser = get-Mailbox $UserPrincipalName -ErrorAction SilentlyContinue -ErrorVariable err
  
  if ($newUser -eq $null)
  {
    #
    # If there are multiple mailbox databases on this server, the user will be created in the last database returned
    #
    $mailboxDatabaseName = $null;
    get-MailboxDatabase -server $mailboxServer | foreach {$mailboxDatabaseName = $_.Guid.ToString()}
  
    if ($mailboxDatabaseName -ne $null)
    {
      write-host $new_testcasuser_LocalizedStrings.res_0000 $exchangeServer.Fqdn 
      if ($Prompt -eq $true)
      {
          read-host $new_testcasuser_LocalizedStrings.res_PromptToQuitOrContinue
      }
  
      new-Mailbox -Name:$UserName -Alias:$UserName -UserPrincipalName:$UserPrincipalName -SamAccountName:$SamAccountName -Password:$SecurePassword -Database:$mailboxDatabaseName  -OrganizationalUnit:$OrganizationalUnit -ErrorVariable err -ErrorAction SilentlyContinue
      $newUser = get-Mailbox $UserPrincipalName -ErrorAction SilentlyContinue
      
      if ($newUser -eq $null)
      {
          $err = "Mailbox could not be created. Verify that OU ( $OrganizationalUnit ) exists and that password meets complexity requirements."
      }
    }
    else
    {
      $err = $new_testcasuser_LocalizedStrings.res_0002
    }
  }
  else
  {
      write-host $new_testcasuser_LocalizedStrings.res_0003 $exchangeServer.Fqdn
      if ($Prompt -eq $true)
      {
          read-host $new_testcasuser_LocalizedStrings.res_PromptToQuitOrContinue
      }
  }
  
  if ($newUser -ne $null)
  {
    write-Host $new_testcasuser_LocalizedStrings.res_0005 $newUser.UserPrincipalName

    set-Mailbox $newUser -MaxSendSize:1000KB -MaxReceiveSize:1000KB -IssueWarningQuota:unlimited -ProhibitSendQuota:1000KB -ProhibitSendReceiveQuota:unlimited -HiddenFromAddressListsEnabled:$True

    # Provide the newly creted user with Remote PowerShell support
    Set-User $newUser -RemotePowerShellEnabled:$true

    #
    # Reset the credentials and save them in the system
    #
    test-ActiveSyncConnectivity -ResetTestAccountCredentials -MailboxServer:($mailboxServer) -ErrorAction SilentlyContinue -ErrorVariable err
  }
 
  # check if user is UM enabled. If not try to UM enable if passed correct parameters

  $simpleuser = get-mailbox -id $UserName -ErrorAction SilentlyContinue
  $umuser = get-ummailbox -id $UserName -ErrorAction SilentlyContinue
  if (($simpleuser -ne $null) -and ($umuser -eq $null))
  {
    # if user exists and not UM enabled 
    if ($UMDialPlan -ne $null)
    {
        # if UMDialPlan was specified - showing intent to UM enable the user

        while($true)
        {
            # loop until you find a valid dialplan 

            $dialplan = get-umdialplan -id $UMDialPlan -ErrorAction SilentlyContinue -ErrorVariable err
            if ($dialplan -ne $null)
            {
                $policy = $dialplan.UMMailboxPolicies[0]    
                break;  
            }
            else
            {
                write-host  
                $UMDialPlan= (read-host $new_testcasuser_LocalizedStrings.res_0006)  
            }
        }

        [int] $num = $dialplan.NumberOfDigitsInExtension
        
        while($true)
        {
            # loop until you find a valid UM extension

            if($UMExtension.Length -ne $num)
            {
                write-host  
                write-host ($new_testcasuser_LocalizedStrings.res_0007 -f $num)   
                $UMExtension = (read-host $new_testcasuser_LocalizedStrings.res_0008)    
            }
            else
            {
                break;
            }
        }
        
        # UM enable the user. Any error thrown from the task should be reported to the user by the err variable
        
        Enable-UMMailbox -id $UserName -Pin '12121212121212121212' -PinExpired $false -UMMailboxPolicy $policy -Extensions $UMExtension -ErrorAction SilentlyContinue -ErrorVariable err
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
Import-LocalizedData -BindingVariable new_testcasuser_LocalizedStrings -FileName new-TestCasConnectivityUser.strings.psd1

$UMDialPlan  = $null
[string]$UMExtension = 0

$OrganizationalUnit = "Users"

$ArgsErrorMessage = $new_testcasuser_LocalizedStrings.res_0009

# check whether admin wants to UM enable the test user. If so .. check if he has specified the right parameters.

$securePassword = $null
$Prompt = $true

if ($args.Count -gt 0) 
{
    write-Host
    if(($args.Count % 2) -ne 0)
    {
        write-Host $ArgsErrorMessage
        write-Host
        exit
    }
    $i = 0
    while($i -lt $args.Count)
    {
        switch($args[$i])
        {
            { $_ -eq "-OU" } 
            { $OrganizationalUnit = $args[$i + 1] }

            { $_ -eq "-Password" } 
            { $securePassword = $args[$i + 1] 
              $Prompt = $false
            }

            { $_ -eq "-UMDialPlan" } 
            { $UMDialPlan = $args[$i + 1]
              write-Host ($new_testcasuser_LocalizedStrings.res_0010 -f $UMDialPlan)
            }

            { $_ -eq "-UMExtension" }
            { $UMExtension = $args[$i + 1] 
              write-Host ($new_testcasuser_LocalizedStrings.res_0011 -f $UMExtension)
            }
            
            default         
            {   write-Host $ArgsErrorMessage
                write-Host
                exit
            }
        }
        $i = $i + 2
    }
    
    write-Host
}

if ($securePassword -ne $null)
{
    # Make sure that the password parameter is a SecureString
    if ($securePassword.GetType() -ne [System.Security.SecureString])
    {
        write-host $new_testcasuser_LocalizedStrings.res_0021
        write-host
        exit
    }
}
else
{
    $new_testcasuser_LocalizedStrings.res_0012
    # Enter password
    $securePassword = (read-host -asSecureString $new_testcasuser_LocalizedStrings.res_EnterPasswordPrompt)
}

$result = $true
$atLeastOneServer = $false
$pipedInput = $false
$expectedMailboxServerType = "Microsoft.Exchange.Data.Directory.Management.MailboxServer"
foreach ($mailboxServer in $Input)
{
  $pipedInput = $true
  if ($mailboxServer.GetType().ToString() -ne $expectedMailboxServerType)
  {
    write-Host ($new_testcasuser_LocalizedStrings.res_0014 -f $mailboxServer,$mailboxServer.GetType().ToString(),$expectedMailboxServerType)
    continue;
  }
  $exchangeServer = get-ExchangeServer $mailboxServer

  $result = CreateTestUser $exchangeServer $mailboxServer $securePassword $OrganizationalUnit $UMDialPlan $UMExtension $Prompt
  $atLeastOneServer = $true
}

if ((!$atLeastOneServer) -and (!$pipedInput))
{
  $exchangeServer = get-ExchangeServer $(hostname.exe) -ErrorAction:SilentlyContinue
  if ($exchangeServer -ne $null)
  {
    if ($exchangeServer.IsMailboxServer)
    {
      $mailboxServer = get-MailboxServer $exchangeServer.Fqdn
      $result = CreateTestUser $exchangeServer $mailboxServer $securePassword $OrganizationalUnit $UMDialPlan $UMExtension $Prompt
      $atLeastOneServer = $true
    }
  }
}

if (!$atLeastOneServer)
{
  write-Host
  write-Host $new_testcasuser_LocalizedStrings.res_0015
  write-Host $new_testcasuser_LocalizedStrings.res_0016
  write-Host
  write-Host $new_testcasuser_LocalizedStrings.res_0017
  write-Host
  write-Host $new_testcasuser_LocalizedStrings.res_0018
  write-Host
  write-Host $new_testcasuser_LocalizedStrings.res_0019
  write-Host
}

if($result -eq $true -and $UMDialPlan -eq $null)
{
    write-Host
    write-Host $new_testcasuser_LocalizedStrings.res_0020
    write-Host
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxN/KzT9+b2ODFGO1duRsl9JL
# czmgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGxA7FT0fxKRwn7B
# 81H8IrK/F2+5MA0GCSqGSIb3DQEBAQUABIIBAJhnAiKJWw6sKBvjGN3ZDVysbEUq
# fpxvvpePnZCfhFqlV3ts+IeDmBzvX80er9GhU08ZMh71a7ouezHE1lTAN3MUmrQI
# PeKCYyJYr1tjgEpGSbBOGLE0RVLtrqydIt5+33OjePLWCFOwPGPL///9YApy5Oeh
# r5ELrlo0TXRrxIeN6hKhNSnZVXj9sU87VQGY/04ae9sIGFWIgdUlM5UYZbYPpjhc
# LXygzsU/p++henYpnVB+K37bAcEdmFK+gof1bMd5wMmhS915snXggfgrp9M/ATKV
# oHonrtXaS7riYpg29JQn6nTYF5MpnU28c0J9H1JIiwcVscgVOHXsfQA9d0Y=
# SIG # End signature block
