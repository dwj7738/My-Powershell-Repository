@{
    Name = 'Find'
    Screen = {
        New-Border -ControlName FindInFiles -BorderBrush Black -CornerRadius 5 -Child {
            New-grid -rows ((@('Auto') * 9) + '1*') -children {
                New-TextBlock "Find in Files"  -FontSize 19 -FontFamily 'Segoe UI' -Row 0 -Margin 3 -FontWeight DemiBold
                
                New-StackPanel -Row 1 -Children {
                    New-Grid -Columns 2 -Children {
                        New-TextBlock -Text "Keyword" -FontFamily 'Segoe UI' -Row 2 -Margin 5 -FontSize 14 
                        New-CheckBox -horizontalalignment right  -Name IsRegex -Content "Regular E_xpression" -FontFamily 'Segoe UI'  -FontSize 14 -Column 1 
                    }
                    New-TextBox -Name "Keyword" -Row 3  -Margin 5 -On_TextChanged {
                        $nc = $this.Parent.Parent | 
                                Get-childControl -OutputNamedControl
                        $nc.FindButton.IsEnabled = $this.Text -as [bool]
                    }
                }
                
                
                
                
                New-CheckBox -Row 4 -Margin 5 -Name InLoadedFiles -Content "Find in Loaded Files" -ToolTip "Finds within currently loaded files" -IsChecked $true
                New-CheckBox -Row 5 -Margin 5 -Name InLoadedDirectories -Content "Find in Loaded _Directories" -ToolTip "Finds within the directories of open files"
                New-CheckBox -Row 6 -Margin 5 -Name InModules -Content "Find in _Modules" -ToolTip "Finds beneath different system wide module locations"
                New-CheckBox -Row 7 -Margin 5 -Name InPowerShell -Content "Find in _PowerShell" -ToolTip "Finds beneath MyDocuments\WindowsPowerShell"

                                
                
                New-Button -Row 8 -Name FindButton -Content "F_ind"  -FontFamily 'Segoe UI' -FontSize 19 -FontWeight DemiBold -On_Click {
                    $nc = $this.Parent | 
                            Get-childControl -OutputNamedControl

                    $keyword = $nc.Keyword.Text

                    
                    

                    $options = @{
                        Keyword = $keyword
                        SimpleMatch = $true
                    }


                    if ($nc.InLoadedFiles.IsChecked) {
                        $options.FindInLoadedFiles = $true
                        #
                    } 
                    if ($nc.InLoadedDirectories.IsChecked) {
                        $options.FindInLoadedDirs = $true
                        #$filesList  += $nc.OpenedFilesList.ItemsSource | Split-Path | Select-Object -Unique
                    }
                    
                    if ($nc.InModules.IsChecked) {
                        $options.FindInModules= $true
                        #$filesList  += $nc
                    }

                    if ($nc.InPowerShell.IsChecked) {
                        $options.FindInPSDir= $true
                        #$filesList  += $nc.PSDir 
                    }

                    if ($nc.IsRegex.IsChecked) {
                        $options.SimpleMatch = $false
                    }

                    

                    $mainRunspace = [Windows.Window]::GetWindow($this).Resources["MainRunspace"]
                    if ($rs.RunspaceAvailability -ne 'Busy') {
                        #$mainRunspace.sessionStateProxy.SetVariable("FileList", $filesList)
                        $mainRunspace.sessionStateProxy.SetVariable("FindOptions", $Options)
                        
                        $ise = [Windows.Window]::GetWindow($this).Resources["ISE"]

                        $findScript = {
                            param([Hashtable]$FindOptions)
                            
                            $filesList = @()
                            if ($FindOptions.FindInPSDir) {
                                $filesList += Get-ChildItem $home\Documents\WindowsPowerShell -Recurse
                            }
                            if ($findOptions.FindInLoadedFiles) {
                                
                                $filesList  += $psise.CurrentPowerShellTab.Files | 
                                    ForEach-Object { $_.FullPath } 
                            }
                            if ($findOptions.FindInLoadedDirs) {
                                $filesList  += $psise.CurrentPowerShellTab.Files | 
                                    ForEach-Object { $_.FullPath } | 
                                    Split-Path | 
                                    Select-Object -Unique
                            }   
                            if ($findOptions.FindInModules) {
                                $filesList += $env:PSModulePath -split ';' | 
                                    Get-ChildItem |
                                    Get-ChildItem |
                                    Get-ChildItem
                            }
                            
                            $filesList | Dir | Select-String $FindOptions.Keyword -SimpleMatch:$($findOptions.SimpleMatch)
                        }
                        $mainRunspace.sessionStateProxy.SetVariable("FindScript", $findScript)

                        $ise.currentPowerShellTab.Invoke({. ([ScriptBLock]::Create($findScript)) $FindOptions})
                    }
                    
                    
                    
                }

                #New-ListBox -Row 9 -Name FoundFiles 



                New-ListBox -Visibility Collapsed -Name OpenedFilesList
                New-TextBox -Visibility Collapsed -Name CurrentDir
                New-TextBox -Visibility Collapsed -Name PSDir
                New-ListBox -Visibility Collapsed -Name ModuleDirList

            }
        }
    }
    DataUpdate = {
        New-Object PSObject -Property @{
            OpenedFiles = @($psise.CurrentPowerShellTab.Files | ForEach-Object { $_.FullPath })
            CurrentDir = "$pwd"
            ModulePaths =@($Env:psmodulePath -split ';')
            PowerShellDir = "$home\Documents\WindowsPowerShell"
        }
        
        
    } 
    UiUpdate = {
        $hi = $Args

        
        
        $nc = $this.Content | 
            Get-ChildControl -OutputNamedControl 
        
        $nc.OpenedFilesList.itemssource = @($hi.OpenedFiles)
        $nc.ModuleDirList.itemssource = @($hi.ModulePaths)
        $nc.CurrentDir.Text = @($hi.CurrentDir)
        $nc.PSDir.Text = @($hi.PowerShellDir)


        $this.Content.Resources.Ise = $this.Parent.HostObject
    }
    UpdateFrequency = "0:0:10"
    ShortcutKey = "Ctrl + Shift + F"
} 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUh+9KWlsDlLgAn7i4hsuebB/0
# BS6gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDoCjy/zWhWx6fB7
# 2Kid/iUXnjuIMA0GCSqGSIb3DQEBAQUABIIBAF5IoHUIJhOFZZ8Q2JL4T7m9LFfM
# Ndco694wayMYRZiTOdS5qZBLy3q0vGqBTDxzh90nVNZctiAVABUFkM+gEU8w37UT
# JOX9Pg6Qm8sc15sT1WeSJziDY6Z9SBlZUzIDg/C7XEKAqQgKjAoBQnLSagOHFhKJ
# 3B/ZOY09NEuS5sGVV/MWttX5XoC93z5SDqwsh7yaZO0LnOOyBhwpCQqNCG+tNjB+
# mcUxS5959s7ClFA4XKZMCXFPknTZ1ub3xIlV0i/4YMGq78rs1YNLQBKgXV35fIK/
# +jg0aAnL4VFts/KV/zSObF7U49O3RhaxDI7tr5Wuw8ZWFTdiuhJKVpnb8I4=
# SIG # End signature block
