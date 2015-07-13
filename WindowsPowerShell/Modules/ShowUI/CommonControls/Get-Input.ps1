function Get-Input
{
    <#
    .Synopsis
        Collects user input
    .Description
        Get-Input collects a series of fields.    
    #>
    param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        $in = $_
        $badKeys =$in.Keys | Where-Object { $_ -isnot [string] }
        if ($badKeys) {
            throw "Not all field names were strings.  All field names must be strings."
        }
        
        $badValues = $in.Values | 
            Get-Member | 
            Select-Object -ExpandProperty TypeName -Unique |
            Where-Object { 
                ($_ -ne 'System.RuntimeType' -and
                $_ -ne 'System.Management.Automation.ScriptBlock' -and
                $_ -ne 'System.String')
            }
        if ($badValues) {
            throw "Not all values were strings, types, or script blocks.  All values must be strings, types or script blocks."
        }   
        return $true             
    })]
    [Hashtable]$Field,    
    [string[]]$Order,
    [switch]$HideOKCancel,    
    # The name of the control        
    [string]$Name,
    # If the control is a child element of a Grid control (see New-Grid),
    # then the Row parameter will be used to determine where to place the
    # top of the control.  Using the -Row parameter changes the 
    # dependency property [Windows.Controls.Grid]::RowProperty
    [Int]$Row,
    # If the control is a child element of a Grid control (see New-Grid)
    # then the Column parameter will be used to determine where to place
    # the left of the control.  Using the -Column parameter changes the
    # dependency property [Windows.Controls.Grid]::ColumnProperty
    [Int]$Column,
    # If the control is a child element of a Grid control (see New-Grid)
    # then the RowSpan parameter will be used to determine how many rows
    # in the grid the control will occupy.   Using the -RowSpan parameter
    # changes the dependency property [Windows.Controls.Grid]::RowSpanProperty 
    [Int]$RowSpan,
    # If the control is a child element of a Grid control (see New-Grid)
    # then the RowSpan parameter will be used to determine how many columns
    # in the grid the control will occupy.   Using the -ColumnSpan parameter
    # changes the dependency property [Windows.Controls.Grid]::ColumnSpanProperty
    [Int]$ColumnSpan,
    # The -Width parameter will be used to set the width of the control
    [Int]$Width, 
    # The -Height parameter will be used to set the height of the control
    [Int]$Height,
    # If the control is a child element of a Canvas control (see New-Canvas),
    # then the Top parameter controls the top location within that canvas
    # Using the -Top parameter changes the dependency property 
    # [Windows.Controls.Canvas]::TopProperty
    [Double]$Top,
    # If the control is a child element of a Canvas control (see New-Canvas),
    # then the Left parameter controls the left location within that canvas
    # Using the -Left parameter changes the dependency property
    # [Windows.Controls.Canvas]::LeftProperty
    [Double]$Left,
    # If the control is a child element of a Dock control (see New-Dock),
    # then the Dock parameter controls the dock style within that panel
    # Using the -Dock parameter changes the dependency property
    # [Windows.Controls.DockPanel]::DockProperty
    [Windows.Controls.Dock]$Dock,
    # If Show is set, then the UI will be displayed as a modal dialog within the current
    # thread.  If the -Show and -AsJob parameters are omitted, then the control should be 
    # output from the function
    [Switch]$Show,
    # If AsJob is set, then the UI will displayed within a WPF job.
    [Switch]$AsJob
    )
    
    $uiParameters=  @{} + $psBoundParameters
    $null = $uiParameters.Remove('Field')
    $null = $uiParameters.Remove('Order')
    $null = $uiParameters.Remove('HideOKCancel')
    New-Grid -Columns 'Auto', 1* -ControlName Get-Input @uiParameters -On_Loaded {
        $this.RowDefinitions.Clear()
        $rows = ConvertTo-GridLength (@('Auto')*($field.Count + 2))
        foreach ($rd in $rows) {
            $r = New-Object Windows.Controls.RowDefinition -Property @{Height=$rd}
            $null =$this.RowDefinitions.Add($r)
        }
        $row = 0        
        
        if (-not $Order) {
            $Order = @($field.Keys |Sort-Object)
        }       
        
        foreach ($key in $Order) {            
            if ($field[$key]) {
                
                $value = $field[$key]
                New-Label $key -Row $row | 
                    Add-ChildControl -parent $this
                         
                $cueText = ""
                $validatePattern = ""
                $expectedType = [PSObject]                                     
                if ($value -is [ScriptBlock]) {
                    if ($value.Render) {
                        # If Render is set, the ScriptBlock creates the contents of a stackpanel
                        # otherwise, the scriptblock is the validation                    
                    } else {
                        if ($value.AllowScriptEntry) {
                        }
                    }
                } elseif ($value -is [Type]) {
                    # If a type is provided, try to find a match                     
                    $commands =Get-UICommand | 
                        Where-Object {
                            $outputTypes = ($_.OutputType | Select-Object -ExpandProperty Type)
                            (($outputTypes -contains $value) -or
                            ($outputTypes | Where-Object { $value.IsSubclassOf($_) })) 
                        }      
                        
                    $useTextBox = $true
                                       
                    if (-not $commands) {
                        # No match, default to primitives
                        if ($value.CueText) {
                            $cueText =  $value.CueText
                        }
                        $expectedType = $value -as [type]
                        
                        if (@([bool], [switch]) -contains $value) 
                        {
                            $useTextBox = $false
                            if ($cueText) {
                                $checkBox = New-CheckBox -Margin 5 -Content "$cueText" -FontStyle Italic -Name $key -Row $row -Column 1 
                                $this.Children.Add($checkBox)
                            } else {
                                $this.Children.Add((New-CheckBox -Margin 5 -Name $key -Row $row -Column 1))
                            }
                            $row++
                            continue
                        }
                    } else {
                        if ($commands.Count) {
                            $getKeyMatch = foreach ($_ in $commands) { 
                                if ($_.Name -eq "Get-$Key") { $_ }                                                         
                            }
                            $editKeyMatch = foreach ($_ in $commands) {
                                if ($_.Name -eq "Edit-$Key") { $_ } 
                            }
                            if ($getKeyMatch) {
                                $command = $getKeyMatch
                            } elseif ($editKeyMatch) {
                                $command = $editKeyMatch
                            } else {
                                $command = $commands | Select-Object -First 1 
                            }                     
                        } else {
                            # Only one match, use it
                            $command = $commands
                        }
                        & $command -Name $key -Row $row -Column 1 |                                 
                                Add-ChildControl -parent $this
                        $row++
                        continue 
                    }              
                } elseif ($value -is [string]) {
                    # The string is cue text
                    $expectedType = if ($value.ExpectedType -as [Type]) { $value.ExpectedType } else {[PSObject] }
                }
                
                
                New-TextBox -Name $key -Margin 4 -Column 1 -Row $row -VisualStyle CueText -Resource @{
                    ExpectedType=$expectedType
                } -Text $value -On_PreviewTextInput { 
                    if ((($this.Text + $_.Text) -as $expectedType)) {
                        $this.ClearValue([Windows.Controls.Control]::EffectProperty)
                        $toRemove = $errorList.Items | Where-Object { $_.Tag -eq $this } 
                        if ($toRemove) {
                            $errorList.Items.Remove($toRemove)                        
                        }
                        if (-not $errorList.Items.Count) { 
                            $errorList.Visibility = 'Collapsed'
                            if ($okButton) {
                                $okButton.IsEnabled = $true
                            }
                        }                         
                    } else {
                        $toUpdate = $errorList.Items | Where-Object { $_.Tag -eq $this } 
                        $errorMessage ="$($this.Name): Can't convert $($this.Text) to $($expectedType.Fullname)"
                        if ($toUpdate) {
                            $toUpdate.Content = $errorMessage
                        } else {
                            $errorLabel = New-Label -Tag $this -Content $errorMessage -Foreground Red                                                
                            $null = $errorList.Items.Add($errorLabel)
                        }
                        $errorList.Visibility = 'Visible'
                        $okButton.IsEnabled = $false
                        $this.Effect = New-DropShadowEffect -Color Red
                    }
                } | 
                    Add-ChildControl -parent $this
    
                $row++
            }
        }
        
        New-ListBox -ColumnSpan 2 -Row $row -Name 'ErrorList' -Visibility Collapsed | 
            Add-ChildControl -parent $this
        
        if (-not $HideOKCancel) {
            $row++
            New-UniformGrid -Row $row -ColumnSpan 2 {
                New-Button { "Cancel" } -Name CancelButton -IsCancel -On_Click {
                    Get-ParentControl | 
                        Close-Control
                }
                
                New-Button { "_OK" } -Column 1 -Name OKButton -IsDefault -On_Click {
                    Get-ParentControl | 
                        Set-UIValue -passThru | 
                        Close-Control
                } 
            }  | 
                Add-ChildControl -parent $this
        }
    }
} 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2qp+b+DU7pHmU139IcXV4ek+
# ynKgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJjE3UMEyoSm/wEt
# v/m6pqp+qMIFMA0GCSqGSIb3DQEBAQUABIIBAFmZV+Z/F+7QQV774jSBzsU1B7Hq
# 1hQ0fcCi1zNnO25ejuaNcKQ0q4QQ0W3fZgsFbMSQANn0AkmbA6avoGrSocNwZE6x
# jNYTGMEicGiH5D3WcXDmAkkjD94io/KqJKp7gUKCwCHUijBS4PQjZZm15TeUylAR
# 3NILD1eskUVCHVA5QYOKVT4Rb99+/CrfCI/PYbfaVZ2V4yN+3LN7i0GXP9BufY56
# 4eZfR9HvdWgwy9LGu2B0gQ0IeV/V4envYerp6ZngGGyifKX600kVx8p7duTo/gIK
# pMf8zFF5dcaLvGkHu2CL7Mkwp0Gwm+AGgplgESn/mU1eO/wv6h+0SGJb8jc=
# SIG # End signature block
