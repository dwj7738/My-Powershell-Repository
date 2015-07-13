function Set-Property
{
    <#
    .Synopsis
        Sets properties on an object or subscribes to events
    .Description
        Set-Property is used by each parameter in the automatically generated
        controls in ShowUI.
    .Parameter InputObject
        The object to set properties on
    .Parameter Hashtable
        A Hashtable contains properties to set.
        The key is the name of the property on an object, or "On_" + the name 
        of an event you can subscribe to (i.e. On_Loaded).
        The value can either be a literal value (such as a string), a block of XAML,
        or a script block that produces the value that needs to be set.
    .Example
        $window = New-Window
        $window | Set-Property @{Width=100;Height={200}} 
        $window | show-Window
    #>
    param(    
    [Parameter(ValueFromPipeline=$true)]    
    [Object[]]$inputObject,
    
    [Parameter(Position=0)] 
    [Hashtable]$property,
    
    [switch]$AllowXaml,
    
    [switch]$doNotAutoCreateLabel,
    
    [Switch]$PassThru
    )
       
    process {
        foreach($object in $inputObject) {
            $inAsJob  = $host.Name -eq 'Default Host'
            if ($object.GetValue -and 
                ($object.GetValue([ShowUI.ShowUISetting]::StyleNameProperty))) {
                # Since Set-Property will be called by Set-UIStyle, make sure to check the callstack
                # rather than infinitely recurse            
                $styleName = $object.GetValue([ShowUI.ShowUISetting]::StyleNameProperty)
               

                if ($styleName) {
                    $setUiStyleInCallStack = foreach ($_ in (Get-PSCallStack)) { 
                        if ($_.Command -eq 'Set-UIStyle') { $_ }
                    }
                    if (-not $setUiStyleInCallStack) {
                        Set-UIStyle -Visual $object -StyleName $StyleName 
                    }
                } 
            }
                
            if ($property) {
                # Write-Verbose "Setting $($property.Keys -join ',') on $object"
                $p = $property
                foreach ($k in $p.Keys) {
                    $realKey = $k
                    if ($k.StartsWith("On_")) {
                        $realKey = $k.Substring(3)
                    }

                    if ($object.GetType().GetEvent($realKey)) {
                        # It's an Event!
                        foreach ($sb in $p[$k]) {
                            Add-EventHandler $object $realKey $sb
                        } 
                        continue
                    }
                    
                    $realItem  = $object.psObject.Members[$realKey]
                    if (-not $realItem) { 
                        continue 
                    }

                    $itemName = $realItem.Name
                    if ($realItem.MemberType -eq 'Property') {
                        if ($realItem.Value -is [Collections.IList]) {
                            $v = $p[$realKey]
                            # Write-Host "$itemName is collection on $object " -fore cyan -nonewline
                            $collection = $object.$itemName
                            if (-not $v) { continue } 
                            if ($v -is [ScriptBlock]) { 
                                if ($inAsJob) {
                                    $v = . ([ScriptBlock]::Create($v))
                                } else {
                                    $v = . $v
                                }
                            }
                            if (-not $v) { continue } 

                            foreach ($ri in $v) {
                                # Write-Host "`n`tAdding $ri to $object.$itemName" -fore cyan -nonewline
                                $null = $collection.Add($ri)
                                trap [Management.Automation.PSInvalidCastException] {
                                    $label = New-Label $ri
                                    $null = $collection.Add($label)
                                    continue
                                }
                            }
                            # Write-Host
                        } else {
                            $v = $p[$realKey]
                            if ($v -is [ScriptBlock]) {
                                if ($inAsJob) {
                                    $v = . ([ScriptBlock]::Create($v))
                                } else {
                                    $v = . $v
                                }
                            }

                            if ($allowXaml) {
                                $xaml = ConvertTo-Xaml $v
                                if ($xaml) {
                                    try {
                                        $rv = [Windows.Markup.XamlReader]::Parse($xaml)
                                        if ($rv) { $v = $rv } 
                                    }
                                    catch {
                                        Write-Debug ($_ | Out-String)
                                    }
                                }
                            }

                            if($debugPreference -ne 'SilentlyContinue') {
                                Write-Debug "Control: $($object.GetType().FullName)"
                                Write-Debug "Type: $(@($v)[0].GetType().FullName)"
                                Write-debug "Property: $($realItem.TypeNameOfValue)"
                            }

                            # Two Special cases: Templates and Bindings
                            if([System.Windows.FrameworkTemplate].IsAssignableFrom( $realItem.TypeNameOfValue -as [Type]) -and 
                               $v -isnot [System.Windows.FrameworkTemplate]) {
                                if($debugPreference -ne 'SilentlyContinue') {
                                    Write-Debug "TEMPLATING: $object" -fore Yellow
                                }
                                $Template = $v | ConvertTo-DataTemplate -TemplateType ( $realItem.TypeNameOfValue -as [Type])
                                if($debugPreference -ne 'SilentlyContinue') {
                                    Write-Debug "TEMPLATING: $([System.Windows.Markup.XamlWriter]::Save( $Template ))" -fore Yellow
                                }
                                $object.$itemName = $Template

                            } elseif(@($v)[0] -is [System.Windows.Data.Binding] -and 
                                    (($realItem.TypeNameOfValue -eq "System.Object") -or 
                                    !($realItem.TypeNameOfValue -as [Type]).IsAssignableFrom([System.Windows.Data.BindingBase]))
                            ) {
                                $Binding = @($v)[0];
                                if($debugPreference -ne 'SilentlyContinue') {
                                    Write-Debug "BINDING: $($object.GetType()::"${realKey}Property")" -fore Green
                                }

                                if(!$Binding.Source -and !$Binding.ElementName) {
                                    $Binding.Source = $object.DataContext
                                }
                                if($object.GetType()::"${realKey}Property" -is [Windows.DependencyProperty]) {
                                    try {
                                        # $object.Resources.Clear()
                                        $null = $object.SetBinding( ($object.GetType()::"${realKey}Property"), $Binding )
                                    } catch {
                                        Write-Debug "Nope, was not able to set it." -fore Red
                                        Write-Debug $_ -fore Red
                                        Write-Debug $this -fore DarkRed
                                    }
                                } else {
                                    $object.$itemName = $v
                                }
                            } else {
                                $object.$itemName = $v
                            }
                        }
                    } elseif ($realItem.MemberType -eq 'Method') {
                        $object."$($itemName)".Invoke(@($p[$realKey]))
                    }
                }
            }
            
            if ($passThru) {
                $object
            }
        }
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUefuhQ4r07dJYSmEEj9ZmzVyp
# b3WgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFP5OTu8ata9vWNRv
# synAPhgrf8KAMA0GCSqGSIb3DQEBAQUABIIBALG+hM1+7XGF2zevSUr4nLdKH/IK
# tmsnf8ukPw5yCT6vzDzMUz+da4qOwqDBIPAMs2AJK4Ik6XNHJ7/tIm0JoRUfUA4s
# zCQxDAFVsk27MovYxVtitOtCqhkZLVlYVJLMtNzs3Han7MLLQU14qJJqo65fcQpo
# dK6iRawGYwTI9uJEconL/N5F8xebuhnm2k/FpOe1i4u6YIpHEBLdB0r06ooWoJpI
# s8MnQWbxA531El+b2KuIJfKRcXhe93o1BUztBqEOU5kjw593n+blFgAPrhIwZKDq
# uJDfKMl8XWhends+FnYE2Q4Syayp5bjlJx1molrZFStfZK2f/WFUJat4aPQ=
# SIG # End signature block
