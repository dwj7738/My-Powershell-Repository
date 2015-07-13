function Get-Email
{
    <#
    .Synopsis
        Gets email from exchange    
    .Description
        Gets email from an exchange server
    #>
    [CmdletBinding(DefaultParameterSetName='UserNameAndPasswordSetting')]
    param(    
    # The account
    [Parameter(Mandatory=$true,ParameterSetName='SpecificAccount')]
    [Management.Automation.PSCredential]
    $Account,

    # The setting containing the username
    [Parameter(ParameterSetName='UserNameAndPasswordSetting')]
    [string]
    $UserNameSetting = 'Office365Username',

    # The setting containing the password
    [Parameter(ParameterSetName='UserNameAndPasswordSetting')]
    [string]
    $PasswordSetting = 'Office365Password',

    # The email account to connect to retreive data from.  If not specified, email will be retreived for the account used to connect.
    [string]
    $Email,

    # If set, will only return unread messages
    [Switch]
    $Unread,

    # The name of the contact the email was sent to.  This the displayed name, not a full email address
    [string]
    $To,
    
    # The email that sent the message
    [string]
    $From,

    # If set, will download the email content, not just the headers
    [Switch]
    $Download
    )

    begin {
$wsPath = $MyInvocation.MyCommand.ScriptBlock.File |
    Split-Path | 
    Get-ChildItem -Filter bin |
    Get-ChildItem -Filter Microsoft.Exchange.WebServices.dll 
     
$ra = Add-Type -Path $wspath.FullName -PassThru | Select-Object -ExpandProperty Assembly -Unique | Select-Object -ExpandProperty Location

Add-Type -ReferencedAssemblies $ra -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.Exchange.WebServices.Data;
using System.Net.Security;
using System.Net;
using Microsoft.Exchange.WebServices.Autodiscover;
using System.Configuration;

public class Office365EWSHelper2
{
    /// <summary>
    /// Bind to Mailbox via AutoDiscovery
    /// </summary>
    /// <returns>Exchange Service object</returns>
    public static ExchangeService GetBinding(WebCredentials credentials, string lookupEmail)
    {
        // Create the binding.
        ExchangeService service = new ExchangeService(ExchangeVersion.Exchange2010_SP1);

        // Define credentials.
        service.Credentials = credentials; 

        // Use the AutodiscoverUrl method to locate the service endpoint.
        service.AutodiscoverUrl(lookupEmail, RedirectionUrlValidationCallback);                                
        return service;
    }


    // Create the callback to validate the redirection URL.
    static bool RedirectionUrlValidationCallback(String redirectionUrl)
    {
        // Perform validation.
        return true; // (redirectionUrl == "https://autodiscover-s.outlook.com/autodiscover/autodiscover.xml");
    }

}

'@



    }
    process {
        if ($Account) {
            $Cred = $Account
        } elseif ($UserNameSetting -and $PasswordSetting) {
            $cred = New-Object Management.Automation.PSCredential (Get-SecureSetting $UserNameSetting -ValueOnly), 
                (ConvertTo-SecureString -AsPlainText -Force (Get-SecureSetting $PasswordSetting -ValueOnly))
        }

        if (-not $script:ewsForUser) { 
            $script:ewsForUser = @{}
        }
        $ForEmail = if ($Email) {
            $Email
        } else {
            $cred.UserName
        }
        if (-not $ewsForUser["${ForEmail}_AS_$($Cred.UserName)"]) {
            
            $ews = [Office365EwsHelper2]::GetBinding($cred.GetNetworkCredential(), $ForEmail)
            $script:ewsForUser["${ForEmail}_AS_$($Cred.UserName)"] = $ews
        } else {
            $ews = $script:ewsForUser["${ForEmail}_AS_$($Cred.UserName)"]
        }
        
        $coll =New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+SearchFilterCollection

        if ($Unread) {
            $unreadFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo -Property @{PropertyDefinition=[Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::IsRead;Value='false'} 
            $coll.add($unreadFilter)
        }

        if ($To -and $to -notlike "*@.*") {
            $toEmail = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo -Property @{PropertyDefinition=[Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::DisplayTo;Value=$To} 
            $coll.add($toEmail)
            
        }

        if ($From) {
            $fromEmail = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo -Property @{PropertyDefinition=[Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::From;Value=$From} 
            $coll.add($fromEmail )
            
        }
        


        $fid = New-Object Microsoft.Exchange.WebServices.Data.FolderId "Inbox", $ForEmail
        $iv = New-Object Microsoft.Exchange.WebServices.Data.ItemView 1000
        $fiItems  = $null
        do{
            
            if ($coll.Count) {
	            $fiItems = $ews.FindItems($fid , $coll, $iv)
            } else {
                $fiItems = $ews.FindItems($fid , "", $iv)
            }

	        foreach ($Item in $fiItems) {
                if ($Download) {
                    $item.load()
                }
                $Item
	        }
	        $iv.offset += $fiItems.Items.Count
        }while($fiItems.MoreAvailable -eq $true)

    }
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUl80w6nJqqRuLiwb4CpBpwML+
# Y3CgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLw9PCytAtKKhbZM
# wXLZujuvT+FQMA0GCSqGSIb3DQEBAQUABIIBAJZfLLxTeZWy3psLK3VQs7LxfuLS
# xisYzVR/F0mbq5GFjRxgMSkxfuDngMthvMa8rEu6UKAahCJLWmYfsS5rxZFuXO1c
# 6vjIg6STI9LCMgNoEtRu31zyBV2I7p0+tPfz9l2CoA3yCOCbYEZRxHNNGa24qKA5
# 4izuauEJ7I/XhGRETxW68SEX+LXJLRfZc1qpNMPj5beYk6mWr/XTLjuXzQAw1cjR
# XHWo33dvRPvXYqrymzLMRwkm9O/6NVz4K/UW7mEH1GC4ds3qoclc76RT/6XyWZ06
# OXzADPNVQUSaGLQeXIeeHfNXcwXIM/W9UZM3pIo0Bde3UiG9ZrCWaXK2aEY=
# SIG # End signature block
