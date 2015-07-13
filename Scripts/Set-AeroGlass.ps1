Function Set-AeroGlass {
    <#
        .SYSNOPSIS
            Enables or Disable an Aero Glass effect on the PowerShell console.

        .DESCRIPTION
            Enables or Disable an Aero Glass effect on the PowerShell console.

        .PARAMETER Enable
            Enables the Aero Glass effect on the PowerShell console

        .PARAMETER Disable
            Disables the Aero Glass effect on the PowerShell console

        .NOTES
            Name: Set-AeroGlass
            Author: Boe Prox
            Version History: 
                1.0 -- Boe Prox 19 Sept 2014 
                    - Initial Creation

            View types of font colors with this; not all work well with the Aero Glass effect 
            FOREGROUND
            [System.ConsoleColor]|gm -static -Type Property | ForEach {
                $host.ui.RawUI.ForegroundColor = $_.Name;Write-Host "$($_.Name)"
            }
            $host.ui.rawui.ForegroundColor='White'

            BACKGROUND
            [System.ConsoleColor]|gm -static -Type Property | ForEach {
                $host.ui.rawui.BackgroundColor=$_.Name;Write-Host ("{0}" -f (" " * ($host.ui.rawui.WindowSize.Width-1)))
            }
            $host.ui.rawui.BackgroundColor='DarkMagenta'


        .LINK
            http://learn-powershell.net

        .INPUTS
            None

        .OUPUTS
            None

        .EXAMPLE
            Set-AeroGlass -Enabled

        .EXAMPLE
            Set-AeroGlass -Disabled
    #>
    #requires -version 2
    [cmdletbinding(
        DefaultParameterSetName = 'Enable'
    )]
    param(
        [parameter(ParameterSetName='Enable')]
        [switch]$Enable,        
        [parameter(ParameterSetName='Disable')]
        [switch]$Disable
    )

    #region Module Builder
    $Domain = [AppDomain]::CurrentDomain
    $DynAssembly = New-Object System.Reflection.AssemblyName('AeroAssembly')
    # Only run in memory
    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run) 
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('AeroModule', $False)
    #endregion Module Builder

    #region STRUCTs

    #region Margins
    $Attributes = 'AutoLayout, AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
    $TypeBuilder = $ModuleBuilder.DefineType('MARGINS', $Attributes, [System.ValueType], 1, 0x10)
    [void]$TypeBuilder.DefineField('left', [Int], 'Public')
    [void]$TypeBuilder.DefineField('right', [Int], 'Public')
    [void]$TypeBuilder.DefineField('top', [Int], 'Public')
    [void]$TypeBuilder.DefineField('bottom', [Int], 'Public')

    #Create STRUCT Type
    [void]$TypeBuilder.CreateType()
    #endregion Margins

    #endregion STRUCTs

    #region DllImport
    $TypeBuilder = $ModuleBuilder.DefineType('Aero', 'Public, Class')
    
    #region DwmExtendFrameIntoClientArea Method
    $PInvokeMethod = $TypeBuilder.DefineMethod(
        'DwmExtendFrameIntoClientArea', #Method Name
        [Reflection.MethodAttributes] 'PrivateScope, Public, Static, HideBySig, PinvokeImpl', #Method Attributes
        [Void], #Method Return Type
        [Type[]] @([IntPtr],[Margins]) #Method Parameters
    )

    $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
    $FieldArray = [Reflection.FieldInfo[]] @(
        [Runtime.InteropServices.DllImportAttribute].GetField('EntryPoint'),
        [Runtime.InteropServices.DllImportAttribute].GetField('PreserveSig')
    )

    $FieldValueArray = [Object[]] @(
        'DwmExtendFrameIntoClientArea', #CASE SENSITIVE!!
        $False
    )

    $CustomAttributeBuilder = New-Object Reflection.Emit.CustomAttributeBuilder(
        $DllImportConstructor,
        @('dwmapi.dll'),
        $FieldArray,
        $FieldValueArray
    )

    $PInvokeMethod.SetCustomAttribute($CustomAttributeBuilder)
    #endregion DwmExtendFrameIntoClientArea Method

    #region DwmIsCompositionEnabled Method
    $PInvokeMethod = $TypeBuilder.DefineMethod(
        'DwmIsCompositionEnabled', #Method Name
        [Reflection.MethodAttributes] 'PrivateScope, Public, Static, HideBySig, PinvokeImpl', #Method Attributes
        [Bool], #Method Return Type
        $Null #Method Parameters
    )

    $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))
    $FieldArray = [Reflection.FieldInfo[]] @(
        [Runtime.InteropServices.DllImportAttribute].GetField('EntryPoint'),
        [Runtime.InteropServices.DllImportAttribute].GetField('PreserveSig')
    )

    $FieldValueArray = [Object[]] @(
        'DwmIsCompositionEnabled', #CASE SENSITIVE!!
        $False
    )

    $CustomAttributeBuilder = New-Object Reflection.Emit.CustomAttributeBuilder(
        $DllImportConstructor,
        @('dwmapi.dll'),
        $FieldArray,
        $FieldValueArray
    )

    $PInvokeMethod.SetCustomAttribute($CustomAttributeBuilder)
    #endregion DwmIsCompositionEnabled Method

    [void]$TypeBuilder.CreateType()
    #endregion DllImport

    # Desktop Window Manager (DWM) is always enabled in Windows 8
    # Calling DwmIsCompsitionEnabled() only applies if running Vista or Windows 7
    If ([Aero]::DwmIsCompositionEnabled()) {
        $hwnd = (Get-Process -Id $PID).mainwindowhandle
        $margin = New-Object 'MARGINS'
 
        Switch ($PSCmdlet.ParameterSetName) {
            'Enable' {
                # Negative values create the 'glass' effect
                $margin.top = -1
                $margin.left = -1     
                $margin.right = -1    
                $margin.bottom = -1    
                New-Variable -Name PreviousConsole -Value @{
                    BackgroundColor = $host.ui.RawUI.BackgroundColor
                    Foregroundcolor = $host.ui.RawUI.Foregroundcolor
                } -Scope Global
                $host.ui.RawUI.BackgroundColor = "black"
                $host.ui.rawui.Foregroundcolor = "white"   

                Clear-Host
            }
            'Disable' {
                # Revert back to original style
                $margin.top = 0
                $margin.left = 0  
                $margin.right = 0
                $margin.bottom = 0      
                $host.ui.RawUI.BackgroundColor = $PreviousConsole.BackgroundColor
                $host.ui.rawui.Foregroundcolor = $PreviousConsole.Foregroundcolor
                Remove-Variable PreviousConsole -ErrorAction SilentlyContinue -Scope Global
                Clear-Host
            }
        }
        [Aero]::DwmExtendFrameIntoClientArea($hwnd, $margin)
    } Else {
        Write-Warning "Aero is either not available or not enabled on this workstation."
    }
} 
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGGaYLtSloO3z0CayHQR7oHZh
# JW6gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMyD8qis/GKbsSAb
# pSYd8Xj/odlgMA0GCSqGSIb3DQEBAQUABIIBAAqCdm7G082XGF/ZTn/q5jgEkh53
# 952bIocCKRycbDf23amzxoYhtqPcG/pU87U24j+bW/cfYmFgjwjd/lnnrEcko6ic
# 6ocn4k0+9xvCPL+me/5iMALFn+xLzucUbq8ccg2O/cQdkSoGAoWzj9Rd7H9JPfty
# bzWB1gTgKqDFzLoCr+DYKXy0szpZlREx5GWRpgVZ5Du2P3dzv2X22fOLYwlb7rS5
# pINIcudQxmu7msYGGGPWAmwGQd+7ueqZmxXcGJGsaX3nFBD303LXvEpOGzu6r44W
# 9GhPsoAKvqKKlPYSHRUxEG3bjze6rsZEWp63B0hLSJHa4zYqJdFPTAY6BCE=
# SIG # End signature block
