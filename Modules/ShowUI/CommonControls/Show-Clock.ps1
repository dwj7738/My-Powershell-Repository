function Show-Clock            
{            
    <#
    .Synopsis
        Shows a clock.
    .Description
        Shows a clock, or counts down to a time and displays a message
    .Example
        Show-Clock -AsJob
    .Example
        $now = Get-Date
        $christmas = $now.Subtract($now.TimeOfDay).AddDays(-$now.dayofyear).AddMonths(12).AddDays(25)
        Show-Clock -Foreground DarkGreen -CountDownTo $newYears -CompletedMessage "Merry Christmas" -TimeFormat "{0:dd} Days & {0:\:hh\:mm\:ss} Until Christmas" -FullScreen -AsJob
    .Example
        # A clock within a control
        New-StackPanel { 
            New-Label -HorizontalAlignment Center "The Time Is Now"
            Show-Clock -FontSize 12 -FontFamily Tahoma
        } -show           
    #>            
    [CmdletBinding(DefaultParameterSetName='Clock')]            
    param(            
    # Counts down to a point in time            
    [Parameter(Mandatory=$true,ParameterSetName='CountDown')]            
    [DateTime]            
    $CountDownTo,            
                
    # The message to show when the countdown completes            
    [Parameter(ParameterSetName='CountDown')]                   
    [string]            
    $CompletedMessage,            
                
    # The format string used for the DateTime, or TimeSpan.            
    # By default, this is "F" for the Clock parameter set and            
    # g for the countdown            
    [string]            
    $TimeFormat,            
            
    # The foreground brush.  By default, the foreground will be black.            
    $Foreground,            
                
    # The background brush.  By default, the background will be transparent            
    $Background,            
                
    # The font family (font name).  By default, the font family will be 'Impact'            
    $FontFamily,            
                
    # The Font Size            
    [Double]$FontSize,            
                
    # The Font Weight            
    $FontWeight,            
                
    # The Font Style.            
    $FontStyle,             
                
    [Switch]$FullScreen,             
                
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
        # The one parameter that is used for both the outer control and the inner            
        # command is the background.  Add a default value before anything else happens            
        if (-not $psBoundParameters.Background) {            
            $psBoundParameters.Background = 'Transparent'            
        }            
                
        # First, copy off the UI parameters, so the border doesn't have problems            
        # with parameters that it can't deal with.            
        $uiParameters = @{} + $psBoundParameters            
        $innerParameters = 'TimeFormat',            
            'CountDownTo',            
            'CompletedMessage',            
            'FontSize',            
            'FontFamily',            
            'FontWeight',            
            'FontStyle',            
            'Foreground',            
            'Fullscreen'            
                        
        foreach ($innerParameter in $innerParameters) {            
            $null = $uiParameters.Remove($innerParameter)            
        }                    
                   
        # If there was no timeformat, set the timeformat to a good default.            
        # "F" is the full localized date time format            
        # "g" is the short localized timespan format.            
        if (-not $timeFormat) {            
            if (-not $countDownTo) {            
                $TimeFormat = "F"            
            } else {            
                $TimeFormat = "hh\:mm\:ss"            
            }                               
        }            
                    
                    
        if ($timeFormat -notlike "{0:*") {            
            $TimeFormat = "{0:$TimeFormat}"            
        }            
            
        $psBoundParameters.TimeFormat = $TimeFormat            
                    
        if (-not $psBoundParameters.CompletedMessage) {            
            $psBoundParameters.CompletedMessage = "Done!"            
        }                            
        if (-not $psBoundParameters.FontSize) {             
            $psBoundParameters.FontSize = 32            
        }             
        if (-not $psBoundParameters.FontFamily) {            
            $psBoundParameters.FontFamily = 'Impact'            
        }             
        if (-not $psBoundParameters.FontStyle) {            
            $psBoundParameters.FontStyle = "Normal"            
        }             
        if (-not $psBoundParameters.FontWeight) {            
            $psBoundParameters.FontWeight = "Normal"            
        }             
        if (-not $psBoundParameters.Foreground) {            
            $psBoundParameters.ForeGround = 'Black'            
        }            
                    
        $psBoundParameters.FullScreen  =$fullScreen            
                    
        New-Border @uiParameters -HorizontalAlignment Stretch -VerticalAlignment Stretch -On_Initialized {            
            # Initialized happens right after the control has been created, but before it has been displayed.            
            # In this, we change the window settings if this resides directly inside of the window.            
            # This lets the clock be both cool, and practical            
            if ($this.Parent -is [Windows.Window]) {            
                if (-not $FullScreen) {            
                    $window.SizeToContent = 'WidthAndHeight'            
                                                
                    # If the background is transparent, make the window transparent as well.            
                    if ($background -eq 'Transparent') {            
                        $window.WindowStyle = 'None'            
                        $window.Background = 'Transparent'            
                        $window.AllowsTransparency  =$true            
                    } else {            
                        $this.CornerRadius = 20            
                        $this.BorderThickness = 2            
                        $this.BorderBrush = 'Black'            
                    }            
                } else {            
                    $window.WindowStyle = 'None'            
                    $window.WindowState = 'Maximized'            
                    $window.HorizontalContentAlignment = 'center'            
                    $window.VerticalContentAlignment = 'center'            
                    $window.SizeToContent = 'Manual'            
                }            
                            
                $window.WindowStartupLocation = 'CenterScreen'            
                            
                            
                # When the window is closing, stop the clock            
                Add-EventHandler -EventName "On_Closing" -Handler {             
                    if ($this.Content.DataContext.Command.Stop) {            
                        $this.Content.DataContext.Command.Stop()            
                    }            
                } -Object $window                        
                            
                # When the right mouse button is down, close the control            
                Add-EventHandler -EventName "On_PreviewMouseRightButtonDown" -Handler {             
                    $_.Handled = $true            
                    Close-Control            
                } -Object $window                        
                        
                if (-not $FullScreen) {            
                    # When the left mouse button is down, drag the window.            
                    Add-EventHandler -EventName "On_PreviewMouseLeftButtonDown" -Handler {             
                        $_.Handled = $true            
                        $this.DragMove()            
                    } -Object $window                  
                }                  
            }            
        } -On_Loaded {              
            # When the control is loaded, process the parameters.  Variables will automatically            
            # be created to help you work input from the parent function            
                        
            #  First, set the background, and create a label using the parameters that were passed on in            
            $this.Background = $Background            
                        
            # Now, go ahead and set the borders' child to be the            
            $this.Child =             
                New-Label -HorizontalContentAlignment Center -VerticalContentAlignment Center -Foreground $foreground -FontSize $FontSize -FontStyle $FontStyle -FontWeight $FontWeight -FontFamily $FontFamily                        
                        
            # We have two modes of using the control: CountDown and Clock            
            if (-not $CountDownTo) {                        
                # Clock is really easy.  Just create a background data source            
                # that outputs the time, and change the output accordingly.            
                $this.DataContext = Get-PowerShellDataSource -On_OutputChanged {            
                    $output = Get-PowerShellOutput -Last -OutputOnly            
                    $This.Child.Content = [String]::Format($timeFormat, $output)            
                } -Script {            
                    while ($true) { Get-Date; Start-Sleep -Seconds 1 }             
                }                                                                  
            } else {            
                        
                # Countdown is a little trickier.  We use [ScriptBlock]::Create()            
                # to embed the countdown's value inside of the countdown code            
                $sb = [ScriptBLock]::Create("
                    `$countdownTo = [DateTime]'$countDownTo'
                " + {            
                    do {            
                        $timeLeft = $countDownTo - (Get-Date)            
                        if ($timeLeft.TotalMilliseconds -le 0) {            
                            "Completed"            
                        } else {            
                            $timeLeft                                         
                        }                                    
                        Start-Sleep -Seconds 1
                    } while ($timeLeft.TotalMilliseconds -gt 0)            
                }            
                )            
            
                # The background data sources uses that script.  When the output changes,            
                # if the output was a timespan, update the label with the value.  Otherwise,            
                # set the labels' content to the completed message            
                $this.DataContext = Get-PowerShellDataSource -On_OutputChanged {            
                    $output = Get-PowerShellOutput -Last -OutputOnly            
                                
                    if ($output -is [TimeSpan]) {            
                        $This.Child.Content = [String]::Format($timeFormat, $Output)            
                    } else {            
                        $this.Child.Content = $CompletedMessage            
                    }            
                                
                } -Script $sb            
                                                            
            }            
        }                
    }            
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWMkVYAZHyuUIAYZBjPyoXIcf
# TwOgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDQjg5rFXYh1Y8ZO
# /WJYeDydv5bhMA0GCSqGSIb3DQEBAQUABIIBABK2W6M0uP5ymEmn7c12mYHCl1pZ
# uxeNIbJIIxJxdAWYwX8jblQg5UnrUKJmW4FVP+Yg+n5uqZDZB98fBBiXXvDygOMe
# XRCRCKdnq/Lvye2U4RFiEfho/y/AdDFDdzDU7N96/S1ANNHrWFZEvuF4Nwmg6LeG
# 78U5ObKps8UNw14bdnQJxd3i0J6yPDQOsdBWDXQK7k8vJSSEaG/WWuEkYAZDk/fA
# YpZXNhkNoeC/a8XR8jRvcJ8SJ0rqKbLk5pVrn7U4jbzmv8MnQZlFTVVz9AlYeAtG
# odLz3KBBFLPt/C8ootYb6dfSH1UYXOCVzfhcW7QzNjZzVQZ6cyr/yseRkAw=
# SIG # End signature block
