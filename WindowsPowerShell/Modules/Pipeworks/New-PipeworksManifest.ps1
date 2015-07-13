function New-PipeworksManifest
{
    <#
    .Synopsis
        Creates a Pipeworks manifest for a module, so it can become a site.  
    .Description
        Creates a Pipeworks manifest for a module, so that it can become a pipeworks site.

        
        The Pipeworks manifest is at the heart of how you publish your PowerShell as a web site or software service.

        
        New-PipeworksManifest is designed to help you create Pipeworks manifests for most common cases.
    .Example
        # Creates a quick site to download the ScriptCoverage module
        New-PipeworksManifest -Name ScriptCoverage -Domain ScriptCoverage.Start-Automating.com, ScriptCoverasge.StartAutomating.com -AllowDownload
    .Link
        Get-PipeworksManifest        
    #>
    param(
    # The name of the module
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
    [string]
    $Name,

    # A list of domains where the site will be published 
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]
    [Uri[]]
    $Domain,

    # The names of secure settings that will be used within the website.  You should have already configured these settings locally with Add-SecureSetting.
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=2)]
    [string[]]
    $SecureSetting,

    <#
    
    Commands used within the site.  


    #>
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=3)]
    [Hashtable]
    $WebCommand,

    # The logo of the website.      
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=4)]
    [string]
    $Logo,

    # If set, the module will be downloadable.
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=5)]
    [Switch]
    $AllowDownload,
    
    
    # The table for the website.  
    # This is used to store public information
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=6)]
    [string]
    $Table,    

    # The usertable for the website.  
    # This is used to enable logging into the site, and to store private information
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=7)]
    [string]
    $UserTable,

    # The partition in the usertable where information will be stored.  By default, "Users".  
    # This is used to enable logging into the site, and to store private information
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=8)]
    [string]
    $UserPartition = "Users",


    # The name of the secure setting containing the table storage account name.  By default, AzureStorageAccountName
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $TableAccountNameSetting = "AzureStorageAccountName",

    # The name of the secure setting containing the table storage account key.  By default, AzureStorageAccountKey
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $TableAccountKeySetting = "AzureStorageAccountKey",

    <#
    The LiveConnect ID.
    
    
    This is used to enable Single Sign On using a Microsoft Account.  
    
    
    You must also provide a LiveConnectSecretSetting, and a SecureSetting containing the LiveConnect App Secret.
    #>
    [Parameter(ValueFromPipelineByPropertyName=$true, Position=9)]
    [string]
    $LiveConnectID,

    <# 
    
    The name of the SecureSetting that contains the LiveConnect client secret.


    This is used to enable Single Sign On using a Microsoft Account.  
    #>
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=10)]
    [string]
    $LiveConnectSecretSetting,

    # The LiveConnect Scopes to use.  If not provided, wl.basic, wl.signin, wl.birthday, and wl.emails will be requested
    [Parameter(ValueFromPipelineByPropertyName=$true, Position=11)]
    [string[]]
    $LiveConnectScope,

    # The facebook AppID to use.  If provided, then like buttons will be added to each page and users will be able to login with Facebook
    [string]
    $FacebookAppId,

    # The facebook login scope to use. 
    [string]
    $FacebookScope,
    
    # The schematics used to publish the website.          
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=12)]
    [string[]]
    $Schematic = "Default",


    # A group describes how commands and topics should be grouped together.  
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=13)]
    [Hashtable[]]
    $Group,

    # A paypal email to use for payment processing.
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=14)]
    [string]
    $PaypalEmail,

    # The in which the commands will be shown.  If not provided, commands are sorted alphabetically.  
    # If a Group is provided instead, the Group will be used
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $CommandOrder,

    # Settings related to the main region.  
    # If you need to change the default look and feel of the main region on a pipeworks site, supply a hashtable containing parameters you would use for New-Region.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Hashtable]
    $MainRegion,


    # Settings related to the inner region.  
    # If you need to change the default look and feel of the inner regions in a pipeworks site, supply a hashtable containing parameters you would use for New-Region.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Hashtable]
    $InnerRegion,

    # Any addtional settings
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Hashtable[]]
    $AdditionalSetting,

    # A Google Analytics ID.  This will be added to each page for tracking purposes
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $AnalyticsID,

    # A google site verification.  This will validate the site for Google Webmaster Tools
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $GoogleSiteVerification,
    
    # A Bing Validation Key.  This will validate the site for Bing Webmaster Tools
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $BingValidationKey,

    # A style sheet to use
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Hashtable]
    $Style,

    # A list of CSS files to use
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $Css,

    # The JQueryUI Theme to use.  
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $JQueryUITheme,

    # Trusted walkthrus will run their sample code.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $TrustedWalkthru,

    # Web walkthrus will output HTML
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $webWalkthru,   

    # An AdSense ID
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $AdSenseID,   

    # An AdSense AdSlot 
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $AdSlot,   

    # If set, will add a plusone to each page
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]
    $AddPlusOne,

    # If set, will add a tweet button to each page
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]
    $Tweet,


    # If set, will use the Raphael.js library in the site
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]
    $UseRaphael,

    # If set, will use the g.Raphael.js library in the site
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]
    $UseGraphael,

    # If set, will use the tablesorter JQuery plugin in the site
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]
    $UseTablesorter,

    # If set, will change the default branding.  By default, pages will display "Powered By PowerShell Pipeworks"
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $Branding,

    # Provides the identity of a Win8 App
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $Win8Identity,

    # Provides the publisher of a Win8 App
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $Win8Publisher,

    # Provides the version of a Win8 App
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Version]
    $Win8Version = "1.0.0.0",

    # Provides logos for use in a Win8 App
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [ValidateScript({
    $requiredKeys = "splash","small","wide","store","square"

    $missingKeys = @()
    $ht = $_
    foreach ($r in $requiredKeys) {
        if (-not $ht.Contains($r)) {
            $missingKeys +=$r
        }
    }
    if ($missingKeys) {
        throw "Missing $missingKeys"
    } else {
        return $true
    }    
    })]
    [Hashtable]
    $Win8Logo   
    )


    process {
        $params = @{} + $PSBoundParameters
        $params.Remove("AdditionalSetting")
        $params.Remove("Name")
        $params.Remove("CSS")
        $params.Remove("Domain")
        $params.Remove("Schematic")
        $params.Remove("AdditionalSetting")
        $params.Remove("UserTable")
        $params.Remove("Table")
        $params.Remove("LiveConnectId")
        $params.Remove("LiveConnectSecretSetting")
        $params.Remove("LiveConnectScope")
        $params.Remove("PayPalEmail")
        $params.Remove("Win8Logo")
        $params.Remove("Win8Version")
        $params.Remove("Win8Identity")
        $params.Remove("Win8Publisher")
        
        if ($Win8Logo -and $Win8Identity -and $Win8Publisher) {
            $params += @{
                Win8 = @{
                    Identity = @{
                        Name = $Win8Identity
                        Publisher = $Win8Publisher
                        Version = $Win8Version
                    }
                    Assets = @{
                        "splash.png" = $Win8Logo.Splash
                        "smallTile.png" = $Win8Logo.Small
                        "wideTile.png" = $Win8Logo.Wide
                        "storeLogo.png" = $Win8Logo.Store
                        "squareTile.png" = $Win8Logo.Square
                    }

                    ServiceUrl = "http://$Domain/"
                    Name  = $Name

                    
                }
            }       
        }

        
        if ($PSBoundParameters.PayPalEmail) {
            $params+= @{
                PaymentProcessing = @{
                    "PayPalEmail" = $PaypalEmail
                }
            }
        }
        
        if ($PSBoundParameters.Domain) {
            $params+= @{
                DomainSchematics = @{
                    "$($domain -join ' | ')" = ($Schematic -join "','")
                }
            }
        }

        if ($PSBoundParameters.Css) {
            $c = 0
            $cssDict = @{}
            foreach ($cs in $css) {
                $cssDict["Css$c"] = $cs
                $c++
            }
            $params+= @{
                Css = $cssDict
            }
        }

        if ($PSBoundParameters.AdditionalSetting) {
            foreach ($a in $AdditionalSetting) {
                $params+= $a
            }
        }

        if ($PSBoundParameters.UserTable) {
            $params += @{
                UserTable = @{
                    Name = $UserTable
                    Partition = $UserPartition
                    StorageAccountSetting = $TableAccountNameSetting
                    StorageKeySetting = $TableAccountKeySetting
                }
            }
        }

        if ($PSBoundParameters.Table) {
            $params += @{
                Table = @{
                    Name = $Table                    
                    StorageAccountSetting = $TableAccountNameSetting
                    StorageKeySetting = $TableAccountKeySetting
                }
            }
        }

        if ($PSBoundParameters.LiveConnectID -and $psBoundParameters.LiveConnectSecretSetting) {            
            $params += @{
                LiveConnect = @{
                    ClientID = $LiveConnectID
                    ClientSecretSetting = $LiveConnectSecretSetting                    
                }
            }

            if ($liveconnectScope) {
                $params.LiveConnect.Scope = $LiveConnectScope
            }
        }

        if ($PSBoundParameters.FacebookAppId) {            
            $params += @{
                Facebook = @{
                    AppId = $FacebookAppId                    
                }
            }

            if ($FacebookScope) {
                $params.Facebook.Scope = $FacebookScope
            }
        }
        Write-PowerShellHashtable $params
    }
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUek1HpnDKA9xzVmXlv6Wi6I+9
# /HegggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKQFV+q+xJUD7+CY
# HIQTC4x3acj2MA0GCSqGSIb3DQEBAQUABIIBAGXGs6MWDIoLHvQ3NIWuEYXtrgk/
# DUP7OPCByRMHvXabBlmLRTp3NFRre6gPGf8mNRijzhqsqkkRMoNdlzV2e7ms19Xk
# SUTHLM9gxP+/hUnCRGyTxwUufFvy0I8A5ZYXfGhPnK4L30DirldDkhBtMQLLGLTG
# 055BBogUgtuEs2FmiST1S1Xn1Cg+MgvXFEOPGp+onC9XERJYftXYMgiHw/eIps1T
# u0x8gUEYpIwCBJMjPqM6g+C3gJmh8xOgmi0r8en4HyNHFy2g/H6dM0Lfz+Fp7fHb
# Tx4ur0oHISzEBZqKRGDfaJUDmiTfD0GohMMHKgJaM57uc4HbaDI39t2zXIM=
# SIG # End signature block
