function Invoke-Office365
{
    <#
    .Synopsis
        Invokes commands within Office365
    .Description
        Invokes PowerShell commands within Office365
    .Example
        Invoke-Office365 -ScriptBlock { Get-Mailbox -Identity james.brundage@start-automating.com } 
    .LINK
        http://help.outlook.com/en-us/140/cc952755.aspx
    #>
    [CmdletBinding(DefaultParameterSetName='Office365')]
    [OutputType([PSObject])]
    param(        
    # The credential for the Office365 account
    [Parameter(Position=1,ParameterSetName='ExchangeServer', ValueFromPipelineByPropertyName=$true)]
    [Parameter(Position=1,ParameterSetName='Office365', ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSCredential]
    $Account,  
    
    # A list of account settings to use.  
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $AccountSetting  =  @("Office365UserName", "Office365Password"),
    
    # The exchange server name.  Only required if you're not invoking against Office365
    [Parameter(Mandatory=$true,Position=2,ParameterSetName='ExchangeServer', ValueFromPipelineByPropertyName=$true)]    
    [string]
    $ServerName,        
   
    # The script block to run in Office365
    [Parameter(Position=0)]
    [string[]]
    $ScriptBlock,
    
    # Any arguments to the script
    [Parameter(ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
    [PSObject[]]
    $ArgumentList,
    
    # The name of the session.  If omitted, the name will contain the email used to connect to Office365.    
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$Name,
    

    # If set, will run the command in a background job
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]
    $AsJob,

    # If set, will create a fresh connection and destroy the connection when the command is complete.  
    # This is slower, but less likely to make the exchange server experience a session bottleneck.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]
    $FreshConnection
    )
    
    begin {
        if (-not $script:JobCounter) {
            $script:JobCounter = 1 
        }
    }

    process {
        #region Copy Credential for Office365
        if (-not $Account) {
            if ($AccountSetting -and $accountSetting.Count -eq 2) {
                $username = Get-SecureSetting $accountSetting[0] -ValueOnly 
                $password = Get-SecureSetting $accountSetting[1] -ValueOnly 
                if ($username -and $password) {
                    $account = New-Object Management.Automation.PSCredential $username,(ConvertTo-SecureString -AsPlainText -Force $password )
                    $psBoundParameters.Account = $account
                }
            }
        }

        if (-not $account) {
            Write-Error "Must provide an Account or AccountSetting to connect to Office365"
            return
        }
        #endregion Copy Credential for Office365

        

        #region Launch Background Job if Needed 
        if ($AsJob) {
            $myDefinition = [ScriptBLock]::Create("function Invoke-Office365 {
$(Get-Command Invoke-Office365 | Select-Object -ExpandProperty Definition)
}
")
            $null = $psBoundParameters.Remove('AsJob')            
            
            $myJob= [ScriptBLock]::Create("" + {
                param([Hashtable]$parameter) 
                
            } + $myDefinition + {
                
                Invoke-Office365 @parameter
            }) 
            if (-not $name) { 
                $name = "Office365Job${script:JobCounter}"
                $script:JobCounter++ 
            } 
            Start-Job -Name "$name " -ScriptBlock $myJob -ArgumentList $psBoundParameters 
            return
        }
        #endregion Launch Background Job if Needed 

        
                
        #region Prepare Session Parameters
        if ($psCmdlet.ParameterSetName -eq 'Office365') {
            if ($script:ExchangeWebService -and $script:CachedCredential.Username -eq $script:CachedCredential) {
                return
            }    
            $ExchangeServer = "https://ps.outlook.com/"
            Write-Progress "Connecting to Office365" "$exchangeServer"
            $script:CachedCredential = $Account
        
            $newSessionParameters = @{
                ConnectionUri='https://ps.outlook.com/powershell'
                ConfigurationName='Microsoft.Exchange'
                Authentication='Basic'           
                Credential=$Account
                AllowRedirection=$true
                WarningAction = "silentlycontinue"
                SessionOption=(New-Object Management.Automation.Remoting.PSSessionOption -Property @{OpenTimeout="00:30:00"})
                Name = "https://$($Account.UserName)@ps.outlook.com/powershell"
                
            }
            
            $ExchangeServer = "https://ps.outlook.com/"            
        } else { 
            $ExchangeServer = $ServerName
            $newSessionParameters = @{
                ConnectionUri="https://$ServerName/powershell"
                ConfigurationName='Microsoft.Exchange'
                Authentication='Basic'           
                Credential=$Account
                AllowRedirection=$true
                WarningAction = "silentlycontinue"
                Name = "https://$ServerName/powershell"
                SessionOption=(New-Object Management.Automation.Remoting.PSSessionOption -Property @{OpenTimeout="00:30:00"})
                
            }
        }

        if ($psBoundParameters.Name) {
            $newSessionParameters.Name = $psBoundParameters.Name
        }
        #endregion Prepare Session Parameters


        #region Find or Create Session
        $existingSession = (Get-PSSession -Name $newSessionParameters.Name -ErrorAction SilentlyContinue)
        if ($FreshConnection -or (-not $existingSession ) -or ($existingSession.State -ne 'Opened')) {
            if ($existingSession) {
                $existingSession | Remove-PSSession
            }
            if (-not $FreshConnection) {
                $Session = New-PSSession @newSessionParameters -WarningVariable warning 
            }
        } else {
            $Session = $existingSession
        }
        #endregion Find or Create Session
        
        
        #region Invoke on Office365
        if (-not $Session -and -not $FreshConnection) { return } 
                
        foreach ($s in $scriptBlock) {
            $realScriptBlock  =[ScriptBlock]::Create($s)
            if (-not $realScriptBlock) { continue } 
            
            if (-not $FreshConnection) {
                Invoke-Command -Session $session -ArgumentList $Arguments -ScriptBlock $realScriptBlock  
            } else {
                $null = $newSessionParameters.Remove("Name")
                Start-Job -ArgumentList $Account, $realScriptBlock,$Arguments -ScriptBlock {
                    param([Management.Automation.PSCredential]$account, $realScriptBlock, $Arguments) 

                    $realScriptBlock = [ScriptBlock]::Create($realScriptBlock)
                    $newSessionParameters = @{
                        ConnectionUri='https://ps.outlook.com/powershell'
                        ConfigurationName='Microsoft.Exchange'
                        Authentication='Basic'           
                        Credential=$Account
                        AllowRedirection=$true
                        WarningAction = "silentlycontinue"
                        SessionOption=(New-Object Management.Automation.Remoting.PSSessionOption -Property @{OpenTimeout="00:30:00"})
                        
                
                    }

                    Invoke-Command @newsessionParameters -ArgumentList $Arguments -ScriptBlock $realScriptBlock 
                } | Wait-Job | Receive-Job
                
            }
            
        }

        if ($session -and $FreshConnection) {
            Remove-PSSession -Session $session
        }   
        #endregion Invoke on Office365
    }
}                       
 


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOP95OemFuEzD74xt/rfHEhuX
# uYugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCm9jY5pOxZX7Oce
# hox42xItn4msMA0GCSqGSIb3DQEBAQUABIIBABPJLrNl8Mu+H6/Ra0f/TLQe8v0H
# 6d99Yi6TnmBYQIjz48675IoT6IdM/4NIV5KCTmAmenwhaTBZUmOniGjqg7f890Kt
# +xnmUEDCy2WkgXujWRGxbHi3ceoNL5Tyt6WbsUnzpxCan1cmH9H+Rfa08lceXXfX
# VJfj4PjNaNETyUv3d3tYcWv6MTIgrmPK69xE4Kn3fyxWyfZtXwnI77jAuMf084+1
# fUEN3jmUTYAnhxBiNXNUDhhX/XVEUKYcNH4x+jRg0Fye0Dfj0tkDymACgI1QfJin
# Qe7tmHU3slRe7owQHvb87hZGd+ZqRQX8jlRsKfXrYFgca3mQxUEuU8t/6bg=
# SIG # End signature block
