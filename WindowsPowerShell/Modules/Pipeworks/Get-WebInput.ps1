function Get-WebInput
{
    <#
    .Synopsis
        Get the Web Request parameters for a PowerShell command
    .Description
        Get the Web Request parameters for a PowerShell command.  
        
        Script Blocks parameters will automatically be run, and text values will be converted
        to their native types.
    .Example
        Get-WebInput -CommandMetaData (Get-Command Get-Command) -DenyParameter ArgumentList
    .Link
        Request-CommandInput
    #>
    [OutputType([Hashtable])]
    param(
    # The metadata of the command that is being wrapped
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [Management.Automation.CommandMetaData]
    $CommandMetaData,
    
    # The parameter set within the command
    [string]
    $ParameterSet,    
    
    # Explicitly allowed parameters (by default, all are allowed unless they are explictly denied)
    [string[]]
    $AllowedParameter,
    
    # Explicitly denied parameters.
    [string[]]
    $DenyParameter,
    
    # Any aliases for parameter names.
    [Hashtable]$ParameterAlias,
    
    # A UI element containing that will contain all of the values.  If this option is used, the module ShowUI should also be loaded.
    $Control        
    )
    
    process {
        $webParameters = @{}
        $safecommandName = $commandMetaData.Name.Replace("-", "")
        $webParameterNames = $commandMetaData.Parameters.Keys
        $webParameterNames = $webParameterNames  |
            Where-Object { $DenyParameter -notcontains $_ } | 
            ForEach-Object -Begin {
                if ($ParameterAlias) { 
                    foreach ($k in $ParameterAlias.Keys) { $k }  
                } 
            } -Process { 
                if ($_ -ne "URL") {
                } else {
                }
                "$($CommandMetaData.Name)_$_" 
            }
        
        
        if ($request.Params -is [Hashtable]) {
            
            $paramNames = $request.Params.Keys
            $global:ParameterList = $paramNAmes
        } else {
            $paramNames = @($request.Params) + ($request.Files)
            $global:ParameterList = $paramNAmes
            
        }
        
        
        if ($Control) {
            
            if (-not $ExecutionContext.SessionState.InvokeCommand.GetCommand("Get-ChildControl", "All")) {
                
                return
            }
            
            $uiValue = @{}
            $uivalue = Get-ChildControl -Control $control -OutputNamedControl
            
            foreach ($kv in @($uivalue.GetEnumerator())) {
                if (($kv.Key -notlike "${SafeCommandName}_*")) {
                    $uiValue.Remove($kv.Key)
                }
            }

            
            
            foreach ($kv in @($uiValue.GetEnumerator())) {
                if ($kv.Value.Text) {
                    $uiValue[$kv.Key] = $kv.Value.Text
                } elseif ($kv.Value.SelectedItems) {
                    $uiValue[$kv.Key] = $kv.Value.SelectedItems
                } elseif ($kv.Value -is [Windows.Controls.Checkbox] -and $kv.Value.IsChecked) {
                    $uiValue[$kv.Key] = $kv.Value.IsChecked
                } else {
                    $uiValue.Remove($kv.Key)
                }
            }
            $webParameterNames = $webParameterNames |
                ForEach-Object {
                    $_.Replace("-","")
                }
            $paramNames = $uiValue.Keys |
                ForEach-Object { $_.Trim() }                         
            
        }
        
        
        
        
        foreach ($param in $paramNames) {            
            
            if ($webParameterNames -notcontains $param) { 
                continue 
            } 
            
            if ($request.Params -is [Hashtable]) {                
                $value = $request.Params[$param]
            } elseif ($request) {                
                $value = $request[$param]
                if (-not $value -and $request.Files) {
                    $value =  $request.Files[$param]
                }
            } elseif ($uiValue) {                
                $value = $uiValue[$param]                               
            }
            
            if (-not $value) { 
                if ([string]::IsNullOrEmpty($value)) {
                    continue
                }
                if ($value -ne 0){ 
                    # Do not skip the the value is really 0
                    continue 
                }
                
            }            
            
            if ($value.Trim()[-1] -eq '=') {
                # Make everything handle base64 input (as long as it's not to short to be an accident)
                $valueFromBase64 = try { 
                    [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($value))
                } catch {
                
                }
            }
            
            # If the value was passed in base64, convert it
            if ($valueFromBase64) { 
                $value = $valueFromBase64 
            } 
            
            # If there was no value, quit
            if (-not $value) { continue }                         
                

            if ($parameterAlias -and $parameterAlias[$param]) {
                $realParamName = $parameterAlias[$param]
                
            } else {
                $realParamName= $param -iReplace 
                    "$($CommandMetaData.Name)_", "" -ireplace 
                    "$($commandMetaData.Name.Replace('-',''))_", ""
                
            }   
            
            #region Coerce Type
                         
            $expectedparameterType = $commandMetaData.Parameters[$realParamName].ParameterType                        
            if ($expectedParameterType -eq [ScriptBlock]) {
                # Script Blocks are converted after being trimmed.                
                $valueAsType = [ScriptBlock]::Create($value.Trim())                
                
                if ($valueAsType -and ($valueAsType.ToString().Length -gt 1)) {
                    $webParameters[$realParamName] = $valueAsType
                }
                
            } elseif ($expectedParameterType -eq [Security.SecureString]) {
                $trimmedValue = $value.Trim()

                if ($trimmedValue) {
                    $webParameters[$realParamName]  = ConvertTo-SecureString -AsPlainText -Force $trimmedValue
                }
            } elseif ([switch], [bool] -contains $expectedParameterType) {
                # Switches and bools do a check for false, otherwise true
                if ($value -ilike "false") {
                    $webParameters[$realParamName]  = $false
                } else {
                    $webParameters[$realParamName] = $true
                }
            } elseif ($ExpectedParameterType.IsArray) {
                # If it's an array, split each line and coerce the line into the correct type
                if ($expectedparameterType -eq [string[]] -or                    
                    $expectedparameterType -eq [ScriptBlock[]]) {
                    # String arrays are split on | or newlines
                    $valueAsType = @($value -split "[$([Environment]::NewLine)|]" -ne '' | ForEach-Object { $_.Trim() }) -as $expectedParameterType
                } elseif ($expectedParameterType -eq [Byte[]]) {
                    
                    

                    $is = $value.InputStream
                    $buffer = New-Object Byte[] $is.Length
                    $read = $is.Read($buffer, 0, $is.Length) 
        

                    $buffer
                } else {
                    # Everything else is split on |, newlines, or commas

                    $valueAsType = @($value -split "[$([Environment]::NewLine)|,]" | ForEach-Object { $_.Trim() }) -as $expectedParameterType
                }
                
                if ($valueAsType) {
                    $webParameters[$realParamName] = $valueAsType
                }
            } elseif ($ExpectedParameterType -eq [Hashtable] -or 
                $expectedparameterType -eq [Hashtable[]]) {
            
                $trimmedValue = $value.Trim()
                if ($trimmedValue -like "*@{*") {
                    $asScriptBlock = try { [ScriptBlock]::Create($trimmedValue) } catch { } 
                    if (-not $asScriptBlock) { continue } 
                        
                    # If it's a script block, make a data language block around it, and catch 
                    $asDataLanguage= try { [ScriptBlock]::Create("data { 
                        $asScriptBlock 
                    }") } catch { }
                    if  (-not $asDataLanguage) { continue } 
                        
                    # Run the data language block
                    $webParameters[$realParamName] =  & $asDataLanguage 
                } elseif ($trimmedValue) {
                    $fromStringData = ConvertFrom-StringData -StringData $value 
                    $webParameters[$realParamName] = $fromStringData
                }
                
            } else {
                if ($expectedParameterType) {
                    $valueAsType = $value -as $expectedparameterType
                    if ($valueAsType) {
                        $webParameters[$realParamName] = $valueAsType
                    }
                } else {
                    $webParameters[$realParamName] = $value
                }
                
            }        
            
            #endregion Coerce Type
            	
        }
        
        $finalParams = @{}

        foreach ($wp in $webParameters.GetEnumerator()) {
            if (-not $wp) {continue } 
            if (-not $wp.Value) { continue } 
            $finalParams[$wp.Key] = $wp.Value
        }
        
        $finalParams
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUC1bMJEDMqCzI+IqWOj0s/c9j
# jeCgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHbUy8n2kK9vm/YI
# U7leSKouJEXuMA0GCSqGSIb3DQEBAQUABIIBAL8Ina5rUTSj+0G31z1PQejijyFM
# D6eRNS0uMwPs+8iG5pzKrIqNFQ+/lYgSMJ0EHgVaSgi0YhIo3Yyou6e3+PQsDLAq
# c8t0hbJP6GapdFc5Ga8rSxQvFHqD0C/eF/unrtNaj5OcAxYc6HGBS83AbJ3LmRBY
# ZzS7WRs25+7f5CXrxz/DdWMpjvVTvCZvlxupmjdIEB5j03rJ2K7Zsrv8AJeIz4PG
# mqBMV/5tJX8Hcb+Zk1lAgVUs8csLP1MYlW5cqzLoNX1JFYQMuqGmYMwOWorxYNIu
# vUEIBY3/801427VJJzb64dOZfWBznoDl8MedEGsfjruhFsl3MK06ZiYwYO4=
# SIG # End signature block
