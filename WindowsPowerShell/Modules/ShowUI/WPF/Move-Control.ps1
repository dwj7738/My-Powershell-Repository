function Move-Control {
    <#
    .Synopsis
        Moves a control to a location, and animates the transition
    .Description
        Moves a control to a fixed point on the screen, to another control's location, or to the location and size of the parent control.
        Also allows the control to be faded in or faded out
    .Example
        New-Button -show "Click me and I'll fade away" -On_Click { 
            $this | Move-Control -fadeOut -duration ([Timespan]::FromMilliseconds(500))
        }        
    .Parameter name
        The name of the control to move
    .Parameter control
        The real control to move
    .Parameter targetName
        The name of the target to move the control to
    .Parameter target
        The real control to move the target to
    .Parameter Width
        The width to resize the control to.
        If target or targetName is set, this will be replaced with the target's width.
    .Parameter Height
        The height to resize the control to.
        If target or targetName is set, this will be replaced with the target's height.
    .Parameter Top
        The new top location of the control
        If target or targetName is set, this will be replaced with the target's top.
    .Parameter Left
        The new left location of the control
        If target or targetName is set, this will be replaced with the target's left.    
    .Parameter duration
        The amount of time the transition should take.  If this is not set, then the transition will be immediate.
    .Parameter fadeIn
        If set, will fade in the opacity of the control
    .Parameter fadeOut
        If set, will fade out the opacity of the control
    .Parameter AccelerationRatio
        The AccelerationRatio used for all animation
    .Parameter DecelerationRatio
        The DeccelerationRatio used for all animation
    .Parameter autoScroll
        If set, will find the fist parent UI element containing this item and will scroll it to the upper left coordinates of the item.
    .Parameter On_Completed
        If set, will run the script block when the move is completed
    #>
    [CmdletBinding(DefaultParameterSetName="Name")]
    param(
        [Parameter(Mandatory=$true,
            ParameterSetName="Name",
            Position=0)]
        [string[]]
        $name,
        
        [Parameter(Mandatory=$true,
            ParameterSetName="Control",
            ValueFromPipeline=$true)]
        [Windows.UIElement]
        $control,
        
        [string]
        $targetName,
        
        [Windows.UIElement]
        $target,
        
        [Double]
        $Width,
        
        [Double]
        $Height,
        [Double]
        $Top,        
        
        [Double]
        $Left,
        
        [Timespan]$duration = [Timespan]"0:0:0.00",
        
        [Double]$AccelerationRatio,
        [Double]$DecelerationRatio,
        [ScriptBlock[]]$On_Completed = {},
        [switch]$fadeIn,
        [switch]$fadeOut,
        [switch]$autoScroll
    )
    begin {
        $controls = @()
    }
    process {
        switch ($psCmdlet.ParameterSetName) {
            Name {
                if ($window) {
                    foreach ($n in $name) {
                        $controls += ($window | Get-ChildControl $n)
                    }
                }
            }
            Control {                
                $controls += $control
            }
        }
    }
    end {
        if ($targetName) {
            $target = $window | Get-ChildControl $targetName
        }
                
        if ($target) {            
            $width = $target.ActualWidth            
            $height = $target.ActualHeight
            $top = $target.Top
            $left = $target.Left
        }
    
        $animationTemplate = @{
            AccelerationRatio = $AccelerationRatio
            DecelerationRatio = $DecelerationRatio
            Duration = $duration        
        }
        foreach ($c in $controls) {
            $dp = @{}
            $c.GetLocalValueEnumerator() | ForEach-Object {
                $value = $_
                switch ($_.Property.Name) {
                    Width { $dp.Width = $value.Property } 
                    Height { $dp.Height = $value.Property } 
                    Top { $dp.Top = $value.Property } 
                    Left { $dp.Left = $value.Property } 
                }
            }
            $widthProperty = $dp.Width
            if ($widthProperty -and 
                ($psBoundParameters.ContainsKey("Width") -or $psBoundParameters.Target -or $psBoundParameters.TargetName)) {                
                if ($width -ne ($c.GetValue($widthProperty))) {
                    if ($duration.TotalMilliseconds) {                        
                        $widthChange = New-DoubleAnimation `
                                -From $c.GetValue($widthProperty) `
                                -To $width `
                                -On_Completed $On_Completed @animationTemplate
                        $On_Completed = {}
                        $c.BeginAnimation(
                            $widthProperty,
                            $WidthChange
                        )
                    } else {
                        $c.SetValue($widthProperty, $width)                    
                    }
                }
            }
            
            $HeightProperty = $dp.Height
            if ($HeightProperty -and
                ($psBoundParameters.ContainsKey("Height") -or $psBoundParameters.Target -or $psBoundParameters.TargetName)) {                
                if ($height -ne ($c.GetValue($HeightProperty))) {
                    if ($duration.TotalMilliseconds) {
                        $heightChange = New-DoubleAnimation `
                                -From $c.GetValue($heightProperty) `
                                -To $height `
                                -On_Completed $On_Completed @animationTemplate
                        $On_Completed = {}
                        $c.BeginAnimation(
                            $HeightProperty,
                            $HeightChange
                        )
                    } else {
                        $c.SetValue($HeightProperty, $Height)
                    }
                }
            }
            $TopProperty = $dp.Top
            if ($TopProperty -and 
                ($psBoundParameters.ContainsKey("Top") -or $psBoundParameters.Target -or $psBoundParameters.TargetName)) {                
                if ($top -ne ($c.GetValue($topProperty))) {
                    if ($duration.TotalMilliseconds) {                
                        $topChange = New-DoubleAnimation `
                                -From $c.GetValue($topProperty) `
                                -To $top `
                                -On_Completed $On_Completed @animationTemplate
                        $On_Completed = {}
                        $c.BeginAnimation(
                            $TopProperty,
                            $TopChange
                        )
                    } else {
                        $c.SetValue($TopProperty, $Top)
                    }
                }
            }
            
            $LeftProperty = $dp.Left
            if ($LeftProperty -and 
                ($psBoundParameters.ContainsKey("Left") -or $psBoundParameters.Target -or $psBoundParameters.TargetName)) {                
                if ($left -ne ($c.GetValue($leftProperty))) {
                    if ($duration.TotalMilliseconds) {
                        $leftChange = New-DoubleAnimation `
                                -From $c.GetValue($leftProperty) `
                                -To $left `
                                -On_Completed $On_Completed @animationTemplate
                        $On_Completed = {}
                        $c.BeginAnimation(
                            $LeftProperty,
                            $LeftChange
                        )
                    } else {
                        $c.SetValue($LeftProperty, $Left)
                    }
                }
            }
            
            if ($fadeIn) {
                $c.Visibility = "Visible"
                if ($duration.TotalMilliseconds) {
                    $fadeChange = 
                        New-DoubleAnimation `
                            -From ($c.GetValue($c.GetType()::OpacityProperty)) `
                            -To 1 `
                            -On_Completed $on_Completed @animationTemplate
                    $On_completed = {}
                    $c.BeginAnimation(
                        $c.GetType()::OpacityProperty,
                        $fadeChange
                    )
                } else {
                    $c.SetValue($c.GetType()::OpacityProperty, [Double]1)
                }
            } else {
                if ($fadeOut) {
                    if ($duration.TotalMilliseconds) {
                        $guid = [GUID]::NewGuid().ToString()
                        $window.Resources.TemporaryControls."$guid" = $c
                        $hideScript = [ScriptBlock]::Create("
                            `$window.Resources.TemporaryControls.'$guid'.Visibility = 'Collapsed'
                            `$window.Resources.TemporaryControls.Remove('$guid')
                        ")
                        $fadeChange = 
                            New-DoubleAnimation @animationTemplate `
                                -from ([Double]($c.GetValue($c.GetType()::OpacityProperty)))`
                                -to ([Double]0) -On_Completed $hideScript
                        $on_Completed = {}
                        $c.BeginAnimation(
                            $c.GetType()::OpacityProperty,
                            $fadeChange
                        )
                    } else {
                        $c.SetValue($c.GetType()::OpacityProperty, [Double]0)
                        $c.Visibility = "Collapsed"
                    }                    
                }
            }
            if ($autoScroll) {
                #If there's a scrollviewer, then scroll the scrollviewer 
                $scrollViewer = $null
                $p = $c.Parent            
                while ($p) {
                    if ($p -is [Windows.Controls.ScrollViewer]) {
                        $scrollViewer = $p
                        break
                    }
                    $p = $p.Parent
                }
                if ($scrollViewer) {
                    if ($duration.TotalMilliseconds) {
                        $guid = [GUID]::NewGuid().ToString()
                        $window.Resources.TemporaryControls."$guid" = $c
                        $scrollViewerGuid = [GUID]::NewGuid().ToString()
                        $window.Resources.TemporaryControls."$scrollViewerGuid" = $scrollViewer                        
                        $scrollScript = [ScriptBlock]::Create("
                            `$scrollViewer = `$window.Resources.TemporaryControls.'$scrollViewerGuid'
                            `$c = `$window.Resources.TemporaryControls.'$guid'                            
                            `$p = `$c.TranslatePoint(
                                (New-Object Windows.Point 0,0),
                                `$scrollViewer)
                            `$scrollViewer.ScrollToVerticalOffset(`$p.Y)
                            `$scrollViewer.ScrollToHorizontalOffset(`$p.X)
                            `$window.Resources.TemporaryControls.Remove('$guid')
                            `$window.Resources.TemporaryControls.Remove('$scrollViewerGuid')
                        ")
                        Register-PowerShellCommand `
                            -run -once -in $duration `
                            -scriptBlock $scrollScript                     
                    } else {
                        $p = $c.TranslatePoint(
                            (New-Object Windows.Point 0,0),
                            $scrollViewer)
                        $scrollViewer.ScrollToVerticalOffset($p.X)
                        $scrollViewer.ScrollToHorizontalOffset($p.Y)
                    }
                }
            }                            
        }
    }   
}
 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTAZwFvkRWL+mpExphT72ANsc
# L+2gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFB+wVz+S/ApLGJuk
# SQ1WPM1GvbcXMA0GCSqGSIb3DQEBAQUABIIBAAkIQ6nm0FNGyVU0MuluTnpaQqyU
# OUUDuLlqxP+/LfZnxduxADkC36jbwwtpfMnQHUrMz6mwUv7z/EV116i3Vu6n1dAZ
# p1476Itrcaq+sTGMCltwpkXxkNCe60SCsJCrr5JqWn5cOYpbv29MY0A1XYta9eH8
# 9A+m3RkyZzvxXKNqoKZ7shvy5s38SVAqe4eugwFMtjfyZtN6hkBSBLXI9/rFWdKO
# emKDuALg+cOhIrU1CMoeGestAYu2uF0QGIsxQWPHXK3NKWwxNQ4b8Y/osaz2ksaP
# lfb5TWpbEfF5xv3EMlt+GLqDz1D/lA19ZtyJ0ubKxS7Yry5hxiyF9PK8c9c=
# SIG # End signature block
