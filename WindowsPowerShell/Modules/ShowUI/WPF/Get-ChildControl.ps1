function Get-ChildControl
{
    <#
    .Synopsis
        Imports variables to interact with a control's children
    .Description
        
    #>
    param(
    [Parameter(ValueFromPipeline=$true, Mandatory=$false)]
    [Alias('Tree')]
    $Control = $Window,
    [Parameter(Position=0)][string[]]$ByName,

    [Switch]$OnlyDirectChildren,       
    [string[]]$ByControlName,
    [Type[]]$ByType,
    [string]$ByUid,
    [String]$GetProperty,        
    [switch]$OutputNamedControl,
    [Switch]$PeekIntoNestedControl
    )
    
    process {
        if ($byUid) { $PeekIntoNestedControl = $true } 
        $hasEnumeratedChildren = $false
        if (-not $Control) { return }
        $namedNestedControls = @{}
        $queue = New-Object Collections.Generic.Queue[PSObject]
        $queue.Enqueue($control)
        $hasOutputtedSomething = $false
        while ($queue.count) {
            $parent = $queue.Peek()
            
            if ('ShowUI.ShowUISetting' -as [type]) {
                $controlname = try {
                    $parent.GetValue([ShowUI.ShowUISetting]::ControlNameProperty)
                } catch {
                    $controlname  = ""
                }
            } else {
                $controlname = ""
            }
            
            if ($parent.Name) {
                $namedNestedControls[$parent.Name] = $parent
            }
            
            if (-not $OutputNamedControl) {
                if ($getProperty){
                    $__propertyExistsOnObject = $parent.psObject.Properties[$getProperty]
                    if ($__PropertyExistsOnObject) {
                        $parent.$getProperty
                    }
                } elseif ($byName) {
                    if ($ByName -contains $parent.Name) { 
                        $hasOutputtedSomething  = $true
                        $parent 
                    } 
                } elseif ($byControlName) {
                    if ($byControlName -contains $controlname) { 
                        $hasOutputtedSomething = $true
                        $parent 
                    } 
                } elseif ($ByType) {
                    foreach ($bt in $byType) {
                        if ($parent.GetType() -eq $bt -or 
                            $parent.GetType().IsSubclassOf($bt)) { 
                            $hasOutputtedSomething = $true
                            $parent 
                        } 
                    }
                } elseif ($byUid) {
                    if ($parent.Uid -eq $uid) { 
                        $hasOutputtedSomething = $true
                        $parent 
                    }
                } else {                    
                    if ((-not $hasOutputtedSomething) -and $OnlyDirectChildren) {
                        # When -OnlyDirectChildren is specified, the first item
                        # out would be the parent, so skip that
                        $hasOutputtedSomething = $true                        
                    } else {
                        $hasOutputtedSomething = $true                        
                        $parent                
                    }
                    
                }
            }
            
            
            $childCount = try {
                [Windows.Media.VisualTreeHelper]::GetChildrenCount($parent)
            } catch {
                Write-Debug $_
            }
            
            
            $shouldEnumerateChildren = $false            
            
            if ($childCount) {            
                if (-not ($hasEnumeratedChildren -and $OnlyDirectChildren)) {
                    if ((-not $HasEnumeratedChildren) -or                 
                        (-not $controlname -or $PeekIntoNestedControl)) {
                        $hasEnumeratedChildren = $true
                        for ($__i =0; $__i -lt $childCount; $__i++) {
                            $child = [Windows.Media.VisualTreeHelper]::GetChild($parent, $__i)
                            $queue.Enqueue($child)
                        }            
                    }                                        
                }
            } else {
                if ($parent -is [Windows.Controls.ContentControl]) {
                    $child = $parent.Content
                    
                    if ($child -and $child -is [Windows.Media.Visual]) {
                        $hasEnumeratedChildren = $true
                        $queue.Enqueue($child)
                    } else {
                        if (-not $outputNamedControl -and
                            -not $byType -and
                            -not $byName -and
                            -not $byUid -and 
                            -not $byControlName) {
                            $hasEnumeratedChildren = $true
                            $child
                        }
                        
                    }
                }
            }
            
            $parent = $queue.Dequeue() 
        }

        if ($OutputNamedControl) {
            $namedNestedControls
        }                                               
    }      
}
   

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2OoN+rDC/LPowj++4SJtzOdX
# Y62gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFMc1iOmqoMtBbUO
# lza3B8TTvlZRMA0GCSqGSIb3DQEBAQUABIIBAE2njvqcWtMBMgDCzMogASyoNClJ
# JwyZZ7ElpmhyjAVXiTstjoRa1PS4zoR67Zb2XOhhEtBjtuxp7orDNh1MYeEpeT4g
# mRbE9HeRAZgMHP4iWKJJYWPKgesEEqkiWBaKC8doHFJoctE5ERIl/XZFvPAewek9
# 7omFApHZNlDLO2erZTByMJ8m6/Zlc7WaConi4qANPuC0wLaADtmG4Hfx7b4QcAC6
# Qyv2jpQe3FmJ6Ka5L8sB2+7wcn1O6ncMc9vF+2182DqBtEyoTTBgeziqFi1gk8Vy
# gevlrcHnFYWmv+rAW6QY85AHesuD4vgMznU8SLnUyIfHIGFXZsUqUVlgkvM=
# SIG # End signature block
