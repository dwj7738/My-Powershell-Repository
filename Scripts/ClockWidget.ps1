<#
    .SYSNOPSIS
        Displays a clock on the screen with date.

    .DESCRIPTION
        Displays a clock on the screen with date.

    .PARAMETER TimeColor
        Specify the color of the time display.

    .PARAMETER DateColor
        Specify the color of the date display.

        Default is White

    .NOTES
        Author: Boe Prox
        Created: 27 March 2014
        Version History:
            Version 1.0 -- 27 March 2014
                -Initial build

    .EXAMPLE
        .\ClockWidget.ps1

        Description
        -----------
        Clock is displayed on screen

    .EXAMPLE
        .\ClockWidget.ps1 -TimeColor DarkRed -DateColor Gold

        Description
        -----------
        Clock is displayed on screen with alternate colors

    .EXAMPLE
        .\ClockWidget.ps1 –TimeColor "#669999" –DateColor "#334C4C"

        Description
        -----------
        Clock is displayed on screen with alternate colors as hex values
            
#>
Param (
    [parameter()]
    [string]$TimeColor = "White",
    [parameter()]
    [string]$DateColor = "White"
)
$Clockhash = [hashtable]::Synchronized(@{})
$Runspacehash = [hashtable]::Synchronized(@{})
$Runspacehash.host = $Host
$Clockhash.TimeColor = $TimeColor
$Clockhash.DateColor = $DateColor
$Runspacehash.runspace = [RunspaceFactory]::CreateRunspace()
$Runspacehash.runspace.ApartmentState = “STA”
$Runspacehash.runspace.ThreadOptions = “ReuseThread”
$Runspacehash.runspace.Open() 
$Runspacehash.psCmd = {Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase}.GetPowerShell() 
$Runspacehash.runspace.SessionStateProxy.SetVariable("Clockhash",$Clockhash)
$Runspacehash.runspace.SessionStateProxy.SetVariable("Runspacehash",$Runspacehash)
$Runspacehash.runspace.SessionStateProxy.SetVariable("TimeColor",$TimeColor)
$Runspacehash.runspace.SessionStateProxy.SetVariable("DateColor",$DateColor)
$Runspacehash.psCmd.Runspace = $Runspacehash.runspace 
$Runspacehash.Handle = $Runspacehash.psCmd.AddScript({ 

$Script:update = {
    $day,$Month,$Day_n,$Year,$Time,$AMPM = (Get-Date).DateTime -split "\s" -replace ","
    $Day_n = $Day_n.PadLeft(2,"0")
    $Time = $Time -replace '(.*):.*','$1'

    $Clockhash.time_txtbox.text = $Time
    $Clockhash.day_txtbx.Text = $day
    $Clockhash.ampm_txtbx.text = $AMPM
    $Clockhash.day_n_txtbx.text = $Day_n
    $Clockhash.month_txtbx.text = $Month
    $Clockhash.year_txtbx.text = $year   
}

[xml]$xaml = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle = "None" WindowStartupLocation = "CenterScreen" SizeToContent = "WidthAndHeight" ShowInTaskbar = "False"
        ResizeMode = "NoResize" Title = "Weather" AllowsTransparency = "True" Background = "Transparent" Opacity = "1" Topmost = "True">
    <Grid x:Name = "Grid" Background = "Transparent">
        <TextBlock x:Name = "time_txtbox" FontSize = "72" Foreground = "$($Clockhash.TimeColor)" VerticalAlignment="Top" 
        HorizontalAlignment="Left" Margin="0,-26,0,0">
                <TextBlock.Effect>
                    <DropShadowEffect Color = "Black" ShadowDepth = "1" BlurRadius = "5" />
                </TextBlock.Effect>
        </TextBlock>
        <TextBlock x:Name = "ampm_txtbx" FontSize=  "20" Foreground = "$($Clockhash.TimeColor)" Margin  = "133,0,0,0" 
        HorizontalAlignment="Left">
                <TextBlock.Effect>
                    <DropShadowEffect Color = "Black" ShadowDepth = "1" BlurRadius = "2" />
                </TextBlock.Effect>
        </TextBlock>
        <TextBlock x:Name = "day_n_txtbx" FontSize=  "38" Foreground = "$($Clockhash.DateColor)" Margin="5,42,0,0" 
        HorizontalAlignment="Left">
                <TextBlock.Effect>
                    <DropShadowEffect Color = "Black" ShadowDepth = "1" BlurRadius = "2" />
                </TextBlock.Effect>
        </TextBlock>
        <TextBlock x:Name = "month_txtbx" FontSize=  "20" Foreground = "$($Clockhash.DateColor)" Margin="54,48,0,0" 
        HorizontalAlignment="Left">
                <TextBlock.Effect>
                    <DropShadowEffect Color = "Black" ShadowDepth = "1" BlurRadius = "2" />
                </TextBlock.Effect>
        </TextBlock>
        <TextBlock x:Name = "day_txtbx" FontSize=  "15" Foreground = "$($Clockhash.DateColor)" Margin="54,68,0,0" 
        HorizontalAlignment="Left">
                <TextBlock.Effect>
                    <DropShadowEffect Color = "Black" ShadowDepth = "1" BlurRadius = "2" />
                </TextBlock.Effect>
        </TextBlock>
        <TextBlock x:Name = "year_txtbx" FontSize=  "38" Foreground = "$($Clockhash.DateColor)" Margin="0,42,0,0" 
        HorizontalAlignment="Left">
                <TextBlock.Effect>
                    <DropShadowEffect Color = "Black" ShadowDepth = "1" BlurRadius = "2" />
                </TextBlock.Effect>
        </TextBlock>
    </Grid>
</Window>
"@
 
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Clockhash.Window=[Windows.Markup.XamlReader]::Load( $reader )

$Clockhash.time_txtbox = $Clockhash.window.FindName("time_txtbox")
$Clockhash.ampm_txtbx = $Clockhash.Window.FindName("ampm_txtbx")
$Clockhash.day_n_txtbx = $Clockhash.Window.FindName("day_n_txtbx")
$Clockhash.month_txtbx = $Clockhash.Window.FindName("month_txtbx")
$Clockhash.year_txtbx = $Clockhash.Window.FindName("year_txtbx")
$Clockhash.day_txtbx = $Clockhash.Window.FindName("day_txtbx")

#Timer Event
$Clockhash.Window.Add_SourceInitialized({
    #Create Timer object
    Write-Verbose "Creating timer object"
    $Script:timer = new-object System.Windows.Threading.DispatcherTimer 
    #Fire off every 1 minutes
    Write-Verbose "Adding 1 minute interval to timer object"
    $timer.Interval = [TimeSpan]"0:0:1.00"
    #Add event per tick
    Write-Verbose "Adding Tick Event to timer object"
    $timer.Add_Tick({
    $Update.Invoke()
    [Windows.Input.InputEventHandler]{ $Clockhash.Window.UpdateLayout() }
    
})
    #Start timer
    Write-Verbose "Starting Timer"
    $timer.Start()
    If (-NOT $timer.IsEnabled) {
        $Clockhash.Window.Close()
    }
}) 

$Clockhash.Window.Add_Closed({
    $timer.Stop()
    $Runspacehash.PowerShell.Dispose()
    
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()    
})
$Clockhash.month_txtbx.Add_SizeChanged({
    [int]$clockhash.length = [math]::Round(($Clockhash.day_txtbx.ActualWidth,$Clockhash.month_txtbx.ActualWidth | 
        Sort -Descending)[0])
    [int]$Adjustment = $clockhash.length + 52 + 10 #Hard coded margin plus white space
    
    $YearMargin = $Clockhash.year_txtbx.Margin
    $Clockhash.year_txtbx.Margin = ("{0},{1},{2},{3}" -f ($Adjustment),
        $YearMargin.Top,$YearMargin.Right,$YearMargin.Bottom)
})
$Clockhash.month_txtbx.Add_SizeChanged({
    [int]$clockhash.length = [math]::Round(($Clockhash.day_txtbx.ActualWidth,$Clockhash.month_txtbx.ActualWidth | 
        Sort -Descending)[0])
    [int]$Adjustment = $clockhash.length + 52 + 10 #Hard coded margin plus white space
    
    $YearMargin = $Clockhash.year_txtbx.Margin
    $Clockhash.year_txtbx.Margin = ("{0},{1},{2},{3}" -f ($Adjustment),
        $YearMargin.Top,$YearMargin.Right,$YearMargin.Bottom)
})
$Clockhash.time_txtbox.Add_SizeChanged({
    If ($Clockhash.time_txtbox.text.length -eq 4) {        
        $Clockhash.ampm_txtbx.Margin  = "133,0,86,0"
    } Else {
        $Clockhash.ampm_txtbx.Margin  = "172,0,48,0"
    }     
})
$Clockhash.Window.Add_MouseRightButtonUp({
    $This.close()
})
$Clockhash.Window.Add_MouseLeftButtonDown({
    $This.DragMove()
})
$Update.Invoke()
$Clockhash.Window.ShowDialog() | Out-Null
}).BeginInvoke()
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEpc9JMAhdKSW3a5RJo7vj1aL
# rlSgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKyc+0NHWF9OsHyp
# xDXmRWom2sz+MA0GCSqGSIb3DQEBAQUABIIBAEGiL0z4B/86ZsOHI5Cg6R0fBRf2
# fN29kIi83tRgAUdNvxSrUacH4P4a/pUHud/qszZCFy1MS47PTRurynUvHB7iwDtV
# YCp1crvnHne953VrpWVwf+gM4FkR9htqqM7P1vGuQ4ZbN/dBrhoAoQJv8GxJzD7b
# ltne22B4ny+cApZ8Pa7LNP+P9ckHzzXfqos/Os3Ap5Kg9OeBSYwafvrIoPLjVvSi
# lvpTkAg9LPZrVclef11dVPRF8t1vPkmUCHdXzsiBPqzQMiMtjtXtJxiGmPZFvx91
# MROyfZqEcNmy3A9gppd6iuCY7ZgY3d/SRXRX9o77H2OgQNx04qfCCXv2T5Y=
# SIG # End signature block
