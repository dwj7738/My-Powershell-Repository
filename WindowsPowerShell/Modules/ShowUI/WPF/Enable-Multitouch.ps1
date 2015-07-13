function Enable-MultiTouch
{
    <#
    .Synopsis
        Enables multiple touch events on a window
    .Description
        Registers a window for multiple touch events and creates
        three buffers (TouchStarts,TouchStops,TouchMoves) that
        will contain all of the touch events that have occured within 
        a buffer window.
        This enables raw multitouch support, but does not 
        enable gestures such as pinching or zooming
    .Parameter Window
        The Window to Enable for multitouch events
    .Parameter Buffer
        The time buffer to record event
    .Example
    
    
New-Window -WindowState Maximized -Resource @{
    Styluses=@{}
} -On_Loaded {
    $this | 
        Enable-MultiTouch
} -On_StylusDown {
    $styluses = $this.Resources.Styluses 
    $origin = $_.GetPosition($this.Content)
    $color = 'Black', 'Pink', 'Red', 'Blue', 'Green', 'Orange','DarkRed', 'MidnightBlue', 'Maroon', 'SaddleBrown' | 
        Get-Random 
    
    $line = New-Polyline -Stroke $color -StrokeThickness 3 -Points { $origin } 
    $styluses.($_.StylusDevice.ID) = @{
        Line = $line
    }
    $line | 
        Add-ChildControl $this.Content
} -On_StylusMove {
    $styluses = $this.Resources.Styluses
    $line = $styluses.($_.StylusDevice.ID).Line
    $point = $_.GetPosition($this.Content)
    $null = $line.Points.Add($point)
} -On_StylusUp {
    $styluses = $this.Resources.Styluses 
    $styluses.($_.StylusDevice.ID).Line | 
        Move-Control -fadeOut -duration ([timespan]::FromMilliseconds(500))
    $styluses.Remove($_.StylusDevice.ID) 
} -Content {
    New-Canvas 
} -asJob        
    #>
    param(
    [Parameter(ValueFromPipeline=$true, 
        Mandatory=$true)]
    [Windows.Window]
    $Window,
    
    [Timespan]
    $Buffer = [Timespan]::FromSeconds(30)
    )
    begin {
        if (-not ('WPK.MT' -as [TYPE])) {
            $referencedAssemblies = 'WindowsBase, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35',
        'PresentationCore, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35',
        'PresentationFramework, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35'
            Add-Type 'MT' -Namespace WPK -IgnoreWarnings `
            -ReferencedAssemblies $referencedAssemblies `
            -UsingNamespace System.Windows, System.Windows.Interop `
            -MemberDefinition '
[DllImport("user32")]
public static extern bool SetProp(IntPtr hWnd, string lpString, IntPtr hData);
','
/// <summary>
/// Enable Stylus events, that represent touch events. 
/// </summary>
/// <remarks>Each stylus device has an Id that is corelate to the touch Id</remarks>
/// <param name="window">The WPF window that needs stylus events</param>
public static void EnableStylusEvents(System.Windows.Window window)
{
    WindowInteropHelper windowInteropHelper = new WindowInteropHelper(window);

    // Set the window property to enable multitouch input on inking context.
    SetProp(windowInteropHelper.Handle, "MicrosoftTabletPenServiceProperty", new IntPtr(0x01000000));
}
' 
        }
    }
    process {
        [WPK.MT]::EnableStylusEvents($window)
        $LinkedListType = "Collections.Generic.LinkedList"

        $window.Resources.TouchStarts = New-Object "$LinkedListType[PSObject]"
        $window.Resources.TouchStops = New-Object "$LinkedListType[PSObject]"
        $window.Resources.TouchMoves = New-Object "$LinkedListType[PSObject]"
        $window.Resources.TouchBuffer = $Buffer
        $window.add_StylusUp({
            $object = $_ |
                Add-Member NoteProperty Sender $this -PassThru |
                Add-Member NoteProperty TimeGenerated ([DateTime]::Now) -PassThru
            $TouchStops =$this.Resources.TouchStops
            $Buffer = $this.Resources.TouchBuffer
            $check = $TouchStops.First
            $time = $check.Value.TimeGenerated
            while ($time -and 
                (($time.Add($Buffer)) -lt (Get-Date))) {
                $oldCheck = $check
                $check = $check.Next
                if (-not $check) { return } 
                $time = $check.Value.TimeGenerated
                $null = $TouchStops.Remove($oldCheck)
                $oldCheck = $null
            }
            $null = $TouchStops.AddLast($Object)            
        })
        $window.add_StylusDown({
            $object = $_ |
                Add-Member NoteProperty Sender $this -PassThru |
                Add-Member NoteProperty TimeGenerated ([DateTime]::Now) -PassThru
            $TouchStarts =$this.Resources.TouchStarts
            $Buffer = $this.Resources.TouchBuffer
            $check = $TouchStarts.First
            $time = $check.Value.TimeGenerated
            while ($time -and 
                (($time.Add($Buffer)) -lt (Get-Date))) {
                $oldCheck = $check
                $check = $check.Next
                if (-not $check) { return } 
                $time = $check.Value.TimeGenerated
                $null = $TouchStarts.Remove($oldCheck)
                $oldCheck = $null
            }
            $null = $TouchStarts.AddLast($Object)            
        })
        $window.add_StylusMove({
            $object = $_ |
                Add-Member NoteProperty Sender $this -PassThru |
                Add-Member NoteProperty TimeGenerated ([DateTime]::Now) -PassThru
            $TouchMoves =$this.Resources.TouchMoves
            $Buffer = $this.Resources.TouchBuffer
            $check = $TouchMoves.First
            $time = $check.Value.TimeGenerated
            while ($time -and 
                (($time.Add($Buffer)) -lt (Get-Date))) {
                $oldCheck = $check
                $check = $check.Next
                if (-not $check) { return } 
                $time = $check.Value.TimeGenerated
                $null = $TouchMoves.Remove($oldCheck)
                $oldCheck = $null
            }
            $null = $TouchMoves.AddLast($Object)            
        })                
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUf7EOeTVG8IOYhJjQwy6IAkPM
# gWegggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJkeXTMfEjGJt7Bd
# DgMVx13jLOjxMA0GCSqGSIb3DQEBAQUABIIBADJYF0zsf6ykt+mpiQNjXKhUkY0y
# 0YetiO5fawevRGQRjZIqvcLuNLcizHbpi1n6ebC0JRO51cXOjhV5UbT/qmcUh4VX
# HDt3rhSNiF22icbUGEpV1eBTzhOUPJg93fxwNjAKbBZHZoGosQqMLbhR02f8jFBw
# yBGQZ2J2RPraS36JGs/V0sXDCMKxdr+6ky7sn5N6Xwa53tuJCGLzzVwkc4tSax0H
# NzznsIo35Vor1BRaR0WwGon1yXzB04VLbOUDzTQ17k8AHCKalbrFZgUNrcMqk9Iz
# U9EqY1BsYdyBgDInGt+PKAhJ143rLjr/lmuozG+5ADTVeszTDYW4VzEzK28=
# SIG # End signature block
