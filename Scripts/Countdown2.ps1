<#
.SYNOPSIS
    This is a countdown displays a continuous countdown based on user input.
    
.DESCRIPTION
    This is a countdown displays a continuous countdown based on user input.
    
    Key Input Tips:
    r: Toggles the resize mode of the clock so you can adjust the size.
    o: Toggles whether the countdown remains on top of windows or not.
    +: Increases the opacity of the clock so it is less transparent.
    -: Decreases the opacity of the clock so it appears more transparent.
    
    Right-Click to close.
    Use left mouse button to drag clock.
    
.PARAMETER EndDate
    Specified date that the countdown timer is ticking down to.

.PARAMETER Message
    Message that relates to what the timer is counting down to.

.PARAMETER Title
    Title that displays on the task bar window

.PARAMETER FontWeight
    Font weight used

.PARAMETER FontSize
    Size of font to use with countdown timer

.PARAMETER MessageColor
    Color of the message text that is displayed

.PARAMETER CountDownColor
    Color of the countdown number text that is displayed

.PARAMETER EndBeep
    Countdown will start beeping when it reaches 0

.PARAMETER EndFlash
    Countdown will start display random colors when it reaches 0

.NOTES  
    Name: Start-CountDownTimer.ps1
    Author: Boe Prox
    Created: 10/05/2011   
    Version: 2.0 //Boe Prox -- 04/20/2012
        Changed from using StackPanel to Grid
        Allowed use of keys for added features to include resizing,opacity and topmost display
        Changed from a function to script
    Version: 1.0 //Boe Prox -- 07/05/2011
        Initial Build

.EXAMPLE
    .\Start-CountDownTimer.ps1
    
Description
-----------
Starts a countdown timer 

.EXAMPLE
    .\Start-CountDownTimer.ps1 -EndDate "05/28/2012" -Title "Countdown to Something" -Message "Until The 28th Of May!" -CountDownColor "Yellow" -MessageColor "Red"
    
Description
-----------
Starts a countdown to the 28th of May.     

.EXAMPLE
    .\Start-CountDownTimer.ps1 -EndDate "12/25/2012" -Title "Countdown to Christmas" -Message "Until Christmas!!" -CountDownColor "Red" -MessageColor "Green"
    
Description
-----------
Starts a countdown until Christmas  
#>
[cmdletbinding()]
Param (
    [parameter()]
    [datetime]$EndDate = (Get-Date).AddDays(7),
    [parameter()]
    [string]$Message = ("Until a week from {0}" -f ((get-date).DayOfWeek)),
    [parameter()]
    [string]$Title = "Countdown To Next Week",  
    [parameter()]
    [ValidateSet('Black','Bold','DemiBold','ExtraBlack','ExtraBold','ExtraLight','Heavy','Light','Medium','Normal','Regular','SemiBold','Thin','UltraBlack','UltraBold','UltraLight')]
    [string]$FontWeight = 'Bold',   
    [parameter()]
    [ValidateSet('Normal','Italic','Oblique')]
    [string]$FontStyle = 'Normal',       
    [parameter()]
    [string]$FontSize = '25',
    [parameter()]
    [string]$MessageColor = 'Green',
    [parameter()]
    [string]$CountDownColor = 'Blue',
    [parameter()]
    [switch]$EndBeep,
    [parameter()]
    [switch]$EndFlash
    ) 
    
$rs = [RunspaceFactory]::CreateRunspace()
$rs.ApartmentState = “STA”
$rs.ThreadOptions = “ReuseThread”
$rs.Open() 
$rs.SessionStateProxy.SetVariable('EndDate',$EndDate) 
$rs.SessionStateProxy.SetVariable('Message',$Message) 
$rs.SessionStateProxy.SetVariable('Title',$Title) 
If ($PSBoundParameters['EndFlash']) {
    $rs.SessionStateProxy.SetVariable('EndBeep',$EndBeep)
}
If ($PSBoundParameters['EndBeep']) {
    $rs.SessionStateProxy.SetVariable('EndFlash',$EndFlash)
}
$rs.SessionStateProxy.SetVariable('FontWeight',$FontWeight) 
$rs.SessionStateProxy.SetVariable('FontStyle',$FontStyle) 
$rs.SessionStateProxy.SetVariable('FontSize',$FontSize) 
$rs.SessionStateProxy.SetVariable('CountDownColor',$CountDownColor) 
$rs.SessionStateProxy.SetVariable('MessageColor',$MessageColor) 
$psCmd = {Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase}.GetPowerShell() 
$psCmd.Runspace = $rs 
$psCmd.Invoke() 
$psCmd.Commands.Clear() 
$psCmd.AddScript({ 

    #Load Required Assemblies
    Add-Type –assemblyName PresentationFramework
    Add-Type –assemblyName PresentationCore
    Add-Type –assemblyName WindowsBase

    #Build the UI
    [xml]$xaml = @"
    <Window
        xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        x:Name='Window' ResizeMode = 'NoResize' WindowStartupLocation = 'CenterScreen' Title = '$title' Width = '860' Height = '321' ShowInTaskbar = 'True' WindowStyle = 'None' AllowsTransparency = 'True'>
        <Window.Background>
        <SolidColorBrush Opacity= '0' ></SolidColorBrush>
        </Window.Background>
        <Grid x:Name = 'Grid' HorizontalAlignment="Stretch" VerticalAlignment = 'Stretch' ShowGridLines='false'  Background = 'Transparent'>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="2"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="2"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="2"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>                
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition Height = '*'/>
                <RowDefinition Height = '*'/>
            </Grid.RowDefinitions>   
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '0'> 
                <Label x:Name='d_DayLabel' FontSize = '$FontSize' FontWeight = '$FontWeight' Foreground = '$CountDownColor' FontStyle = '$FontStyle' />
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '1'> 
                <Label x:Name='DayLabel' FontWeight = '$FontWeight' Content = 'Days' FontSize = '$FontSize' FontStyle = '$FontStyle' Foreground = '$MessageColor' />            
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '2'> 
                <Label Width = '5' /> 
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '3'> 
                <Label x:Name='d_HourLabel' FontSize = '$FontSize' FontWeight = '$FontWeight' Foreground = '$CountDownColor' FontStyle = '$FontStyle'/>
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '4'> 
                <Label x:Name='HourLabel' FontWeight = '$FontWeight' Content = 'Hours' FontSize = '$FontSize' FontStyle = '$FontStyle' Foreground = '$MessageColor' />
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '5'> 
                <Label Width = '5' /> 
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '6'> 
                <Label x:Name='d_MinuteLabel' FontSize = '$FontSize' FontWeight = '$FontWeight' Foreground = '$CountDownColor' FontStyle = '$FontStyle'/>
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '7'> 
                <Label x:Name='MinuteLabel' FontWeight = '$FontWeight' Content = 'Minutes' FontSize = '$FontSize' FontStyle = '$FontStyle' Foreground = '$MessageColor' />
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '8'> 
                <Label Width = '5' />
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '9'> 
                <Label x:Name='d_SecondLabel' FontSize = '$FontSize' FontWeight = '$FontWeight' Foreground = '$CountDownColor' FontStyle = '$FontStyle' />
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '0' Grid.Column = '10'> 
                <Label x:Name='SecondLabel' FontWeight = '$FontWeight' Content = 'Seconds' FontSize = '$FontSize' FontStyle = '$FontStyle' Foreground = '$MessageColor' />
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' StretchDirection = 'Both' Stretch = 'Fill' Grid.Row = '1' Grid.ColumnSpan = '11'> 
                <Label x:Name = 'TitleLabel' FontWeight = '$FontWeight' Content = '$Message' FontSize = '$FontSize' FontStyle = '$FontStyle' Foreground = '$MessageColor' />        
            </Viewbox>
        </Grid>
    </Window>
"@ 

    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $Global:Window=[Windows.Markup.XamlReader]::Load( $reader )

    #Collection of colors
    $Colors = @(
        "Blue","Red","Yellow","Black","Green","Orange","Purple","White"
        
    )

    ##Connect to controls
    $TitleLabel = $Global:Window.FindName("TitleLabel")
    $d_DayLabel = $Global:Window.FindName("d_DayLabel")
    $DayLabel = $Global:Window.FindName("DayLabel")
    $d_HourLabel = $Global:Window.FindName("d_HourLabel")
    $HourLabel = $Global:Window.FindName("HourLabel")
    $d_MinuteLabel = $Global:Window.FindName("d_MinuteLabel")
    $MinuteLabel = $Global:Window.FindName("MinuteLabel")
    $d_SecondLabel = $Global:Window.FindName("d_SecondLabel")
    $SecondLabel = $Global:Window.FindName("SecondLabel")

    ##Events
    $window.Add_MouseRightButtonUp({
        $this.close()
        })
    $Window.Add_MouseLeftButtonDown({
        $This.DragMove()
        })    
    #Timer Event
    $Window.Add_SourceInitialized({
        #Create Timer object
        Write-Verbose "Creating timer object"
        $Global:timer = new-object System.Windows.Threading.DispatcherTimer 
        #Fire off every 5 seconds
        Write-Verbose "Adding 1 second interval to timer object"
        $timer.Interval = [TimeSpan]"0:0:1.00"
        #Add event per tick
        Write-Verbose "Adding Tick Event to timer object"
        $timer.Add_Tick({
            If ($EndDate -gt (Get-Date)) {
                $d_DayLabel.Content = ([datetime]"$EndDate" - (Get-Date)).Days
                $d_HourLabel.Content = ([datetime]"$EndDate" - (Get-Date)).Hours
                $d_MinuteLabel.Content = ([datetime]"$EndDate" - (Get-Date)).Minutes
                $d_SecondLabel.Content = ([datetime]"$EndDate" - (Get-Date)).Seconds
            } Else {
                $d_DayLabel.Content = $d_HourLabel.Content = $d_MinuteLabel.Content = $d_SecondLabel.Content = 0    
                $d_DayLabel.Foreground = $d_HourLabel.Foreground = $d_MinuteLabel.Foreground = $d_SecondLabel.Foreground = Get-Random -InputObject $Colors
                $DayLabel.Foreground = $HourLabel.Foreground = $MinuteLabel.Foreground = $SecondLabel.Foreground = Get-Random -InputObject $Colors
                If ($EndFlash) {
                    $TitleLabel.Foreground = Get-Random -InputObject $Colors
                }
                If ($EndBeep) {
                    [console]::Beep()
                }
            }
            })
        #Start timer
        Write-Verbose "Starting Timer"
        $timer.Start()
        If (-NOT $timer.IsEnabled) {
            $Window.Close()
            }
        })   
    $Global:Window.Add_KeyDown({
        Switch ($_.Key) {
            {'Add','OemPlus' -contains $_} {
                If ($Window.Opacity -lt 1) {
                    $Window.Opacity = $Window.Opacity + .1
                    $Window.UpdateLayout()
                    }            
                }
            {'Subtract','OemMinus' -contains $_} {
                If ($Window.Opacity -gt .2) {
                    $Window.Opacity = $Window.Opacity - .1
                    $Window.UpdateLayout()
                    }             
                }
            "r" {
                If ($Window.ResizeMode -eq 'NoResize') {
                    $Window.ResizeMode = 'CanResizeWithGrip'
                    }      
                Else {
                    $Window.ResizeMode = 'NoResize'             
                    }       
                }     
            "o" {
                If ($Window.TopMost) {
                    $Window.TopMost = $False
                    }
                Else {
                    $Window.TopMost = $True
                    }
                }     
            }
        })     
    $Window.Topmost = $True   
    $Window.ShowDialog() | Out-Null
}).BeginInvoke() | out-null

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/UOtV6PsmusoWMqNa1/SIJYQ
# DiagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAof79OVTUlhTbBC
# eTLpUhbZvyA0MA0GCSqGSIb3DQEBAQUABIIBAMT9MFMbmuhgqCd2/r/r8xxngnx0
# 2YOaua5u7H9YeSu+HGGcAQt/+2CORqve31rERzDq7Nre5GXRA172SxBXnn8cbRoI
# nAlj7AOrviqsvmbYbWGOIdLdVqfVvCTuj13kLQBf3SKrASbx72WL2AvQGZVyKjy0
# HWggt5s603jpQuG/BXLhmOghCpY6VDSbMzLzLKr+4LKmJFvZuji4KOeGUnzohGCq
# kOicq4YGrUKJuKS91Ojwv7gqSHxDc7GgKwKXMq+XixfDUWuV3fNlt+ugIAnbrLZJ
# ziIR86f4NEvl/pNb9BW8njLPcPhgtNiSDp1Nq5pWGJy1j29bSAqTMpW4TSw=
# SIG # End signature block
