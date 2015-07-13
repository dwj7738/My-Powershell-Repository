<#
.SYNOPSIS
    This is a binary clock that lists the time in hours, minutes and seconds
    
.DESCRIPTION
    This is a binary clock that lists the time in hours, minutes and seconds. Also available is the ability to 
    display the time in a "human readable" format, display the date and display a helper display showoing how to read
    the binary numbers to determine the time.
    
    Tips:
    Use the "h" key show and hide the helper column to better understand what the binary values are.
    Use the "d" key to show and hide the current date.
    Use the "t" key to show the time in a more "human readable" format.

.NOTES  
    Name: BinaryClock/ps1
    Author: Boe Prox
    DateCreated: 07/05/2011
    Version 1.0 
#>
$rs = [RunspaceFactory]::CreateRunspace()
$rs.ApartmentState = ?STA?
$rs.ThreadOptions = ?ReuseThread?
$rs.Open() 
$psCmd = {Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase}.GetPowerShell() 
$psCmd.Runspace = $rs 
$psCmd.Invoke() 
$psCmd.Commands.Clear() 
$psCmd.AddScript({ 

		#Load Required Assemblies
		Add-Type ?assemblyName PresentationFramework
		Add-Type ?assemblyName PresentationCore
		Add-Type ?assemblyName WindowsBase


		[xml]$xaml = @"
<Window
    xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
    xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
    x:Name='Window' Title='Binary Clock' WindowStartupLocation = 'CenterScreen' Width = '205' Height = '196' ShowInTaskbar = 'True' ResizeMode = 'NoResize' >
        <Window.Background>
        <LinearGradientBrush StartPoint='0,0' EndPoint='0,1'>
            <LinearGradientBrush.GradientStops> <GradientStop Color='#C4CBD8' Offset='0' /> <GradientStop Color='#E6EAF5' Offset='0.2' /> 
            <GradientStop Color='#CFD7E2' Offset='0.9' /> <GradientStop Color='#C4CBD8' Offset='1' /> </LinearGradientBrush.GradientStops>
        </LinearGradientBrush>
    </Window.Background>
        <Grid x:Name = 'Grid1' HorizontalAlignment="Stretch" ShowGridLines='False'>
            <Grid.ColumnDefinitions>
                <ColumnDefinition x:Name = 'Column1' Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>                
                <ColumnDefinition x:Name = 'helpcolumn' Width="0"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition x:Name = 'daterow' Height = '0'/>
                <RowDefinition Height = '*'/>
                <RowDefinition Height = '*'/>
                <RowDefinition Height = '*'/>                
                <RowDefinition Height = '*'/>
                <RowDefinition x:Name = 'timerow' Height = '0'/>
            </Grid.RowDefinitions>
            <RadioButton x:Name = 'HourA0' IsChecked = 'False' GroupName = 'A' Grid.Row = '4' Grid.Column = '0' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' /> 
            <RadioButton x:Name = 'HourA1' IsChecked = 'False' GroupName = 'B' Grid.Row = '3' Grid.Column = '0' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' /> 
            <RadioButton x:Name = 'HourB0' IsChecked = 'False' GroupName = 'C' Grid.Row = '4' Grid.Column = '1' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' /> 
            <RadioButton x:Name = 'HourB1' IsChecked = 'False' GroupName = 'D' Grid.Row = '3' Grid.Column = '1' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <RadioButton x:Name = 'HourB2' IsChecked = 'False' GroupName = 'E' Grid.Row = '2' Grid.Column = '1' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' /> 
            <RadioButton x:Name = 'HourB3' IsChecked = 'False' GroupName = 'F' Grid.Row = '1' Grid.Column = '1' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <RadioButton x:Name = 'MinuteA0' IsChecked = 'False' GroupName = 'G' Grid.Row = '4' Grid.Column = '3' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' /> 
            <RadioButton x:Name = 'MinuteA1' IsChecked = 'False' GroupName = 'H' Grid.Row = '3' Grid.Column = '3' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <RadioButton x:Name = 'MinuteA2' IsChecked = 'False' GroupName = 'I' Grid.Row = '2' Grid.Column = '3' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' /> 
            <RadioButton x:Name = 'MinuteB0' IsChecked = 'False' GroupName = 'J' Grid.Row = '4' Grid.Column = '4' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />                                                
            <RadioButton x:Name = 'MinuteB1' IsChecked = 'False' GroupName = 'K' Grid.Row = '3' Grid.Column = '4' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' /> 
            <RadioButton x:Name = 'MinuteB2' IsChecked = 'False' GroupName = 'L' Grid.Row = '2' Grid.Column = '4' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />                         
            <RadioButton x:Name = 'MinuteB3' IsChecked = 'False' GroupName = 'M' Grid.Row = '1' Grid.Column = '4' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' /> 
            <RadioButton x:Name = 'SecondA0' IsChecked = 'False' GroupName = 'N' Grid.Row = '4' Grid.Column = '6' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' /> 
            <RadioButton x:Name = 'SecondA1' IsChecked = 'False' GroupName = 'O' Grid.Row = '3' Grid.Column = '6' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <RadioButton x:Name = 'SecondA2' IsChecked = 'False' GroupName = 'P' Grid.Row = '2' Grid.Column = '6' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <RadioButton x:Name = 'SecondB0' IsChecked = 'False' GroupName = 'Q' Grid.Row = '4' Grid.Column = '7' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <RadioButton x:Name = 'SecondB1' IsChecked = 'False' GroupName = 'R' Grid.Row = '3' Grid.Column = '7' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <RadioButton x:Name = 'SecondB2' IsChecked = 'False' GroupName = 'S' Grid.Row = '2' Grid.Column = '7' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <RadioButton x:Name = 'SecondB3' IsChecked = 'False' GroupName = 'T' Grid.Row = '1' Grid.Column = '7' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' Grid.Row = '4' Grid.Column = '8' Content = '1' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' Grid.Row = '3' Grid.Column = '8' Content = '2' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' Grid.Row = '2' Grid.Column = '8' Content = '4' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' Grid.Row = '1' Grid.Column = '8' Content = '8' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' x:Name = 'H1Label' Grid.Row = '5' Grid.Column = '0' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' x:Name = 'H2Label' Grid.Row = '5' Grid.Column = '1' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' Grid.Row = '5' Grid.Column = '2' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' Content = ":" />
            <Label FontWeight = 'Bold' x:Name = 'M1Label' Grid.Row = '5' Grid.Column = '3' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' x:Name = 'M2Label' Grid.Row = '5' Grid.Column = '4' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' Grid.Row = '5' Grid.Column = '5' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' Content = ":" />
            <Label FontWeight = 'Bold' x:Name = 'S1Label' Grid.Row = '5' Grid.Column = '6' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' x:Name = 'S2Label' Grid.Row = '5' Grid.Column = '7' HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
            <Label FontWeight = 'Bold' x:Name = 'datelabel' Grid.Row = '0' Grid.Column = '1' Grid.ColumnSpan = "6" HorizontalAlignment = 'Center' VerticalAlignment = 'Center' />
        </Grid>
</Window>
"@ 

		$reader = (New-Object System.Xml.XmlNodeReader $xaml)
		$Global:Window = [Windows.Markup.XamlReader]::Load( $reader )

		$datelabel = $Global:window.FindName("datelabel")
		$H1Label = $Global:window.FindName("H1Label")
		$H2Label = $Global:window.FindName("H2Label")
		$M1Label = $Global:window.FindName("M1Label")
		$M2Label = $Global:window.FindName("M2Label")
		$S1Label = $Global:window.FindName("S1Label")
		$S2Label = $Global:window.FindName("S2Label")
		$timerow = $Global:window.FindName("timerow")
		$daterow = $Global:window.FindName("daterow")
		$helpcolumn = $Global:window.FindName("helpcolumn")
		$Global:Column1 = $Global:window.FindName("Column1")
		$Global:Grid = $column1.parent

		##Events
		#Show helper column   
		$Global:Window.Add_KeyDown({
				If ($_.Key -eq "h") {
					Switch ($helpcolumn.width) {
						"*" {$helpcolumn.width = "0"}
						0 {$helpcolumn.width = "*"}
					}
				}
			}) 

		#Show time column   
		$Global:Window.Add_KeyDown({
				If ($_.Key -eq "t") {
					Switch ($timerow.height) {
						"*" {$timerow.height = "0"}
						0 {$timerow.height = "*"}
					}
				}
			}) 
		#Show date column   
		$Global:Window.Add_KeyDown({
				If ($_.Key -eq "d") {
					Switch ($daterow.height) {
						"*" {$daterow.height = "0"}
						0 {$daterow.height = "*"}
					}
				}
			}) 

		$update = {
			$datelabel.content = Get-Date -f D
			$hourA,$hourB = [string](Get-Date -f HH) -split "" | Where {$_}
			$minuteA,$minuteB = [string](Get-Date -f mm) -split "" | Where {$_}
			$secondA,$secondB = [string](Get-Date -f ss) -split "" | Where {$_}

			$hourAradio = $grid.children | Where {$_.Name -like "hourA*"}
			$minuteAradio = $grid.children | Where {$_.Name -like "minuteA*"}
			$secondAradio = $grid.children | Where {$_.Name -like "secondA*"}
			$hourBradio = $grid.children | Where {$_.Name -like "hourB*"}
			$minuteBradio = $grid.children | Where {$_.Name -like "minuteB*"}
			$secondBradio = $grid.children | Where {$_.Name -like "secondB*"}

			#hourA
			$H1Label.content = $hourA
			[array]$splittime = ([convert]::ToString($houra,2)) -split"" | Where {$_}
			[array]::Reverse($splittime)
			$i = 0
			ForEach ($hradio in $hourAradio) {
				Write-Verbose "i: $($i)"
				Write-Verbose "split: $($splittime[$i])"
				If ($splittime[$i] -eq "1") {
					$hradio.Ischecked = $True
				}
				Else {
					$hradio.Ischecked = $False
				}
				$i++
			}
			$i = 0

			#hourB
			$H2Label.content = $hourB
			[array]$splittime = ([convert]::ToString($hourb,2)) -split"" | Where {$_}
			[array]::Reverse($splittime)
			$i = 0
			ForEach ($hradio in $hourBradio) {
				Write-Verbose "i: $($i)"
				Write-Verbose "split: $($splittime[$i])"
				If ($splittime[$i] -eq "1") {
					$hradio.Ischecked = $True
				}
				Else {
					$hradio.Ischecked = $False
				}
				$i++
			}
			$i = 0

			#minuteA
			$M1Label.content = $minuteA
			[array]$splittime = ([convert]::ToString($minutea,2)) -split"" | Where {$_}
			[array]::Reverse($splittime)
			$i = 0
			ForEach ($hradio in $minuteAradio) {
				Write-Verbose "i: $($i)"
				Write-Verbose "split: $($splittime[$i])"
				If ($splittime[$i] -eq "1") {
					$hradio.Ischecked = $True
				}
				Else {
					$hradio.Ischecked = $False
				}
				$i++
			}
			$i = 0

			#minuteB
			$M2Label.content = $minuteB
			[array]$splittime = ([convert]::ToString($minuteb,2)) -split"" | Where {$_}
			[array]::Reverse($splittime)
			$i = 0
			ForEach ($hradio in $minuteBradio) {
				Write-Verbose "i: $($i)"
				Write-Verbose "split: $($splittime[$i])"
				If ($splittime[$i] -eq "1") {
					$hradio.Ischecked = $True
				}
				Else {
					$hradio.Ischecked = $False
				}
				$i++
			}
			$i = 0

			#secondA
			$S1Label.content = $secondA
			[array]$splittime = ([convert]::ToString($seconda,2)) -split"" | Where {$_}
			[array]::Reverse($splittime)
			$i = 0
			ForEach ($hradio in $secondAradio) {
				Write-Verbose "i: $($i)"
				Write-Verbose "split: $($splittime[$i])"
				If ($splittime[$i] -eq "1") {
					$hradio.Ischecked = $True
				}
				Else {
					$hradio.Ischecked = $False
				}
				$i++
			}
			$i = 0

			#secondB
			$S2Label.content = $secondB
			[array]$splittime = ([convert]::ToString($secondb,2)) -split"" | Where {$_}
			[array]::Reverse($splittime)
			$i = 0
			ForEach ($hradio in $secondBradio) {
				Write-Verbose "i: $($i)"
				Write-Verbose "split: $($splittime[$i])"
				If ($splittime[$i] -eq "1") {
					$hradio.Ischecked = $True
				}
				Else {
					$hradio.Ischecked = $False
				}
				$i++
			}
			$i = 0
		}

		$Global:Window.Add_KeyDown({
				If ($_.Key -eq "F5") {
					&$update 
				}
			})

		#Timer Event
		$Window.Add_SourceInitialized({
				#Create Timer object
				Write-Verbose "Creating timer object"
				$Global:timer = new-object System.Windows.Threading.DispatcherTimer 

				Write-Verbose "Adding interval to timer object"
				$timer.Interval = [TimeSpan]"0:0:.10"
				#Add event per tick
				Write-Verbose "Adding Tick Event to timer object"
				$timer.Add_Tick({
						&$update
						Write-Verbose "Updating Window"
					})
				#Start timer
				Write-Verbose "Starting Timer"
				$timer.Start()
				If (-NOT $timer.IsEnabled) {
					$Window.Close()
				}
			})

		&$update
		$window.Showdialog() | Out-Null 
	}).BeginInvoke() | out-null
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpYwmCVsdCfPeYLOihFHSiC5B
# a6ygggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKgylZDDFpLPQEkt
# X5l4xVv7qcLkMA0GCSqGSIb3DQEBAQUABIIBAJa1qy1UUMrUYhVHEDW7aYtELozr
# BG6GaJbivQ8airTcJmRU3sm7Hdyw+FrStw9uMkyGecB0A+iEsFKtCg/GZWseogNM
# tdXhe1Gt7qvvK+eLPAefan9fZZ4/qfWVoL+KbfW4ss/SvTuIBZP3J2OMiU0A/dik
# 8X9cm/GPU6o4iMF5M8amdCOQh2x5lTH1VVtnk+9NlRdAz0zEogXDLd8LvwvDEsuM
# /R2op9qJdC6oHOC1dHtDqIE3uLrt1w8lIk4J1zsXDCU8OYyqLCo9DbFg0EP+B8dH
# /MbqblbBC/aVyKYOe7EMyygGcJA/yLhF3MrEV+aS2stdyDfzqz4iCIRWxck=
# SIG # End signature block
