function Edit-StringList
{
    <#
    .Synopsis
        Edits a list of strings
    .Description
        Edits a list of strings.          
    #>
    [OutputType([Windows.Controls.Grid], [string[]])]
    param(
    # Starting contents of a list
    [string[]]$List,
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
    
    
    process {
        $uiParameters = @{} + $psBoundParameters
        $null = $uiParameters.Remove('List')
        New-Grid -Rows (@('Auto')*4) -Columns 1 -ControlName Edit-List @uiParameters -Resource @{
            # The Resource dictionary is used to store information 
            # and default settings
            Cmdlet = $psCmdlet
            PSBoundParameters = $PSBoundParameters
            Args = $args   
        } -On_Loaded {
            if ($psBoundParameters.List) {
                $list.ItemsSource = $psBoundParameters.List
            }
            
        } {
            New-ListBox -SelectionMode Multiple -Row 0 -Name List -On_SelectionChanged {
                $remove.IsEnabled = $this.SelectedItem
            }          
            New-UniformGrid -Row 1 -Rows 1 {            
                New-Button -Name Add -FontSize 14 -FontWeight Bold '+' -On_Click {
                    $addTextBox.Visibility = $okButton.Visibility = 'Visible'
                    $addTextBox.Focus()                     
                    
                }
                New-Button -Name Remove -FontSize 14 -FontWeight Bold '-' -On_Click {
                    $list.ItemsSource = @($list.ItemsSource | 
                            Where-Object { $list.SelectedItems -notcontains $_ } |
                            Sort-Object)
                    Set-UIValue -Ui $parent -Value ($list.ItemsSource -as [string[]])
                }
            }
            
            New-TextBox -Row 2 -Visibility Collapsed -Name AddTextBox -AcceptsReturn -On_PreviewKeyDown {
                if ($_.Key -eq 'Enter') {
                    $_.Handled = $true                    
                    if ($this.Text) {
                        $List.ItemsSource = @(@($this.Text) + @($list.ItemsSource) | 
                            Sort-Object                        
                        )
                        Set-UIValue -Ui $parent -Value ($list.ItemsSource -as [string[]])
                        $addTextBox.Visibility = $okButton.Visibility = 'Collapsed'
                    } 
                }                
            }
                                            
            New-Button -Row 3 -Visibility Collapsed -Name OkButton "_Ok" -On_Click {
                if ($AddTextBox.Text) {
                    $List.ItemsSource = @(@($AddTextBox.Text) + @($list.ItemsSource) | 
                        Sort-Object                        
                    )
                    Set-UIValue -Ui $parent -Value ($list.ItemsSource -as [string[]])
                    $addTextBox.Visibility = $okButton.Visibility = 'Collapsed'
                }
            }        
        }
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUU4e268G1jNwl0hbUhg4cnisM
# LDygggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEsoC7IUOZRilMAQ
# 1nhK9B1cLd3uMA0GCSqGSIb3DQEBAQUABIIBALJHHk/oWI+RUeOkoD+4thFsqi1g
# WJuPPBzdUQI4m1/f7G0QW2ZjGm2+4qp6Q/2drZcReDSiqI2toIGHOEHwBwuF2g2s
# XyhyXYMeYHc0IN+x259EdZz/bOyvu+xI+EtUjD7R2LPQFFSfG/gM9DdU/f4kTw1x
# SL6Z+QARKCpq5HO/eirnUyL/AW9XfTReHV57c6AvfnA/4DscJKMVmk/EhJAD/eWA
# Kc0wNFPEyOxLUZtursrKA+67CBFEbCBs5PALNsgQDfnNfboZR67F2FbCx+OQACqf
# NO9NEbBH39Q7NJU8SUGeaXOslyBVS/Ez4BhYQJks4VmNadnFXB4sb294LcU=
# SIG # End signature block
