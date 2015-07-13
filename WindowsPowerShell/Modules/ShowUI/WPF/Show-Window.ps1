function Show-Window {
    <#
    .Synopsis
        Show-Window shows a WPF control within a window, 
        and is used by the -Show Parameter of all commands within WPK
    .Description
        Show-Window displays a control within a window and adds several resources to the window
        to make several scenarios (like timed events or reusable scripts) easier to accomplish
        within the WPF control.
    .Parameter Control
        The UI Element to display within the window
    .Parameter Xaml
        The xaml to display within the window
    .Parameter WindowProperty
        Any additional properties the window should have.
        Use the values of this dictionary as you would parameters to New-Window
    .Parameter OutputWindowFirst
        Outputs the window object just before it is displayed.
        This is useful when you need to interact with the window from outside 
        of the thread displaying it.
    .Example
        New-Label "Hello World" | Show-Window
    #>
    [CmdletBinding(DefaultParameterSetName="Window")]
    param(   
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        ParameterSetName="Control",        
    Position=0)]      
    [Windows.Media.Visual]
    $Control,     

    [Parameter(Mandatory=$true,ParameterSetName="Xaml",ValueFromPipeline=$true,Position=0)]      
    [xml]
    $Xaml,
       
    [Parameter(ParameterSetName='Window',Mandatory=$true,ValueFromPipeline=$true,Position=0)]
    [Windows.Window]
    $Window,
                      
    [Hashtable]
    $WindowProperty = @{},
    
    [Parameter(Mandatory=$true,ParameterSetName="ScriptBlock",ValueFromPipeline=$true,Position=0)]      
    [ScriptBlock]
    $ScriptBlock,
    
    [Parameter(ParameterSetName="ScriptBlock")]      
    [Hashtable]
    $ScriptParameter = @{},
       
    [Switch]
    $OutputWindowFirst,
    
    [Parameter(ParameterSetName="ScriptBlock")]      
    [Parameter(ParameterSetName="Xaml")]  
    [Alias('Async')]    
    [switch]$AsJob      
    )
   
   process {        
        try {
            $windowProperty += @{
                SizeToContent="WidthAndHeight"   
            }
        } catch {
            Write-Debug ($_ | Out-String)
        }        
        switch ($psCmdlet.ParameterSetName) {
            Control {
                $window = New-Window
                Set-Property -inputObject $window -property $WindowProperty
                $window.Content = $Control
                $instanceName = $control.Name
                $specificWindowTitle = $Control.GetValue([Windows.Window]::TitleProperty)
                if ($specificWindowTitle) {
                    $Window.Title = $specificWindowTitle
                } elseif ($instanceName) {
                    $Window.Title = $instanceName
                } else {
                    $controlName = $Control.GetValue([ShowUI.ShowUISetting]::ControlNameProperty)
                    if ($controlName) {
                        $Window.Title = $controlName
                    }
                }
            }
            Xaml {
                if ($AsJob) {
                    Start-WPFJob -Parameter @{
                        Xaml = $xaml
                        WindowProperty = $windowProperty
                    } -ScriptBlock {
                        param($Xaml, $windowProperty)
                        $window = New-Window
                        Set-Property -inputObject $window -property $WindowProperty
                        $strWrite = New-Object IO.StringWriter
                        $xaml.Save($strWrite)
                        $Control = [windows.Markup.XamlReader]::Parse("$strWrite")
                        $window.Content = $Control
                        Show-Window -Window $window
                    }   
                    return                  
                } else {
                    $window = New-Window
                    Set-Property -inputObject $window -property $WindowProperty
                    $strWrite = New-Object IO.StringWriter
                    $xaml.Save($strWrite)
                    $Control = [windows.Markup.XamlReader]::Parse("$strWrite")
                    $window.Content = $Control
                }                
            }
            ScriptBlock {
                if ($AsJob) {
                    Start-WPFJob -ScriptBlock {
                        param($ScriptBlock, $scriptParameter = @{}, $windowProperty) 
                        
                        $window = New-Window    
                        $exception = $null
                        $results = . $ScriptBlock @scriptParameter 2>&1
                        $errors = $results | Where-Object { $_ -is [Management.Automation.ErrorRecord] } 
                        
                        if ($errors) {
                            $window.Content = $errors | Out-String 
                            try {
                                $windowProperty += @{
                                    FontFamily="Consolas"   
                                    Foreground='Red'
                                }
                            } catch {
                                Write-Debug ($_ | Out-String)
                            }                                                    
                        } else {
                            if ($results -is [Windows.Media.Visual]) {
                                $window.Content = $results
                            } else {
                                $window.Content = $results | Out-String 
                                try {
                                    $windowProperty += @{
                                        FontFamily="Consolas"   
                                    }
                                } catch {
                                    Write-Debug ($_ | Out-String)
                                }                        
                            }
                        }                                                
                        Set-Property -inputObject $window -property $WindowProperty
                        Show-Window -Window $window
                    } -Parameter @{
                        ScriptBlock = $ScriptBlock
                        ScriptBlockParameter = $ScriptBlockParameter
                        WindowProperty = $windowProperty
                    } 
                    return 
                } else {
                
                    $window = New-Window
                    $results = & $ScriptBlock @scriptParameter
                    if ($results -is [Windows.Media.Visual]) {
                        $window.Content = $results
                    } else {
                        $window.Content = $results | Out-String
                     
                    }
                    try {
                        $windowProperty += @{
                            FontFamily="Consolas"   
                        }
                    } catch {
                        Write-Debug ($_ | Out-String)
                    }
                    Set-Property -inputObject $window -property $WindowProperty
                }
                
            }
        }
        $Window.Resources.Timers = 
            New-Object Collections.Generic.Dictionary["string,Windows.Threading.DispatcherTimer"]
        $Window.Resources.TemporaryControls = @{}
        $Window.Resources.Scripts =
            New-Object Collections.Generic.Dictionary["string,ScriptBlock"]
        $Window.add_Closing({
            foreach ($timer in $this.Resources.Timers.Values) {
                if (-not $timer) { continue }
                $null = $timer.Stop()
            }
            $this | 
                Get-ChildControl -PeekIntoNestedControl |
                Where-Object { 
                    $_.Resources.EventHandlers
                } |
                ForEach-Object {
                    $object = $_
                    $handlerNames  = @($_.Resources.EventHandlers.Keys)
                    foreach ($handler in $handlerNames){
                        $object."remove_$($handler.Substring(3))".Invoke($object.Resources.EventHandlers[$handler])
                        $null = $object.Resources.EventHandlers.Remove($handler)
                    }
                    $object.Resources.Remove("EventHandlers")
                }
        })
        if ($outputWindowFirst) {
            $Window
        }
        $null = $Window.ShowDialog()            
        if ($Control.Tag -ne $null) {
            $Control.Tag            
        } elseif ($Window.Tag -ne $null) {
            $Window.Tag
        } else {
            if ($Control.SelectedItems) {
                $Control.SelectedItems
            }
            if ($Control.Text) {
                $Control.Text
            }
            if ($Control.IsChecked) {
                $Control.IsChecked
            }
        }
        return
   }
}


Set-Alias Show-BootsWindow Show-Window 
Set-Alias Show-UI Show-Window 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEymxDRKTTYJGbjmYLjmSdy2h
# MHqgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFOKZLlz3UAh6YzpP
# F6YrcSkzhFvjMA0GCSqGSIb3DQEBAQUABIIBAHfqGqqH4pHHPfYJ13OgKtHuYLUF
# 6VcJylg07UEKa777TqgAbOlv86xSn1CCm/TmumEtqAoRP6YaxWHACk5q/7ilNWV/
# D0u+kmWfrOO5Ydt2NWmA+BJAZ4ojRCo83Lee5cQhYKHschKZw4a6xJgrmoLF/Up3
# gVPRhPvoN6hAf9V1pj0Rd1mTNxLQF5RAYOvNJSSq5v65WZHBDRbwe2QRDMO0Zfib
# qnR6KXNV4te69hI3ItcMptg1++eJjoUlN4yoWZ0qJywjmEMaL/Tdd+lnxm3yiNNH
# ZjSaGfpQdhzEquBcNIi40uNJ6ydpRBZHHx4Yxmli3J9hcAdyOelrbWaO+uA=
# SIG # End signature block
