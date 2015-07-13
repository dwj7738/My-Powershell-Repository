# ========================================================
#
#	Title:				Snippet Manager Updater
#	Author:			(C) 2010 by Denniver Reining / www.bitspace.de
#	Version:       1.0.0.0002
#
# ========================================================

#region Hide Console
$script:showWindowAsync = Add-Type –memberDefinition @”
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru
 $null = $showWindowAsync::ShowWindowAsync((Get-Process –id $pid).MainWindowHandle, 2)
#endregion


#region #### VARIABLES #####
$snipmanUPpath= "$env:APPDATA\SnippetManager"
$snipmanUPupdatePath = "$env:APPDATA\SnippetManager\Updates"
if (!( [system.io.directory]::exists($snipmanUPupdatePath))) { md $snipmanUPupdatePath }
$updateURL = "http://www.boxtools.de/snipman/SnippetManager_setup.msi"
$Updatefile = "$env:APPDATA\SnippetManager\Updates\SnippetManager_setup.msi"
$scriptpath = Split-Path -parent $MyInvocation.MyCommand.Definition
$windowico = "$scriptpath\Resources\ico\snippet1.ico"
#endregion

#region ScriptForm Designer

#region Constructor

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

#endregion

#region Post-Constructor Custom Code

#endregion

#region Form Creation
#Warning: It is recommended that changes inside this region be handled using the ScriptForm Designer.
#When working with the ScriptForm designer this region and any changes within may be overwritten.
#~~< form1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$form1 = New-Object System.Windows.Forms.Form
$form1.ClientSize = New-Object System.Drawing.Size(342, 189)
$form1.MaximumSize = New-Object System.Drawing.Size(358, 227)
$form1.MinimumSize = New-Object System.Drawing.Size(358, 227)
$form1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form1.Icon = New-Object System.Drawing.Icon("$windowico")
$form1.Text = "SnippetManager Updater"
#~~< RichTextBox1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RichTextBox1 = New-Object System.Windows.Forms.RichTextBox
$RichTextBox1.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$RichTextBox1.Location = New-Object System.Drawing.Point(14, 15)
$RichTextBox1.ReadOnly = $true
$RichTextBox1.Size = New-Object System.Drawing.Size(315, 99)
$RichTextBox1.Font = New-Object System.Drawing.Font("Segoe UI", 8.0, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
$RichTextBox1.TabIndex = 2
$RichTextBox1.Text = ""
#~~< Button2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Location = New-Object System.Drawing.Point(55, 148)
$Button2.Size = New-Object System.Drawing.Size(90, 23)
$Button2.TabIndex = 1
$Button2.Text = "Retry"
$Button2.UseVisualStyleBackColor = $true
#~~< Button1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Point(183, 148)
$Button1.Size = New-Object System.Drawing.Size(90, 23)
$Button1.TabIndex = 0
$Button1.Text = "Cancel"
$Button1.UseVisualStyleBackColor = $true

$form1.Controls.Add($RichTextBox1)
$form1.Controls.Add($Button2)
$form1.Controls.Add($Button1)

#endregion

#region Custom Code
$Button1.add_Click({$form1.close()})
$Button2.add_Click({FNdownloadupdate})
$form1.add_shown({FNdownloadupdate})
$form1.topmost = $true
#endregion

#region Event Loop

function Main{
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form1.ShowDialog()
}

#endregion

#endregion

#region Event Handlers

function FNdownloadupdate {
	$RichTextBox1.text = ""
	$RichTextBox1.SelectionColor = "black"
	$RichTextBox1.selectedtext = "Starting download..."
	$RichTextBox1.selectedtext = "`n (this window may become unresponsive for a little while)"
	$RichTextBox1.SelectionColor = "#855306"
	$RichTextBox1.selectedtext = "`n`r> After the installation you should restart PowerGUI. <"
	$form1.refresh()
	if ( [system.io.file]::exists($Updatefile) ){ Remove-Item "$Updatefile"  } 
	try {
		[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
		$object = New-Object Microsoft.VisualBasic.Devices.Network
		$down = $object.DownloadFile($updateURL, $Updatefile,"","",$true, 40, $true, 'throwexception')
		}
	catch { 
		[void] [Windows.Forms.MessageBox]::Show($error, "SnippetManager Download - Error", [Windows.Forms.MessageBoxButtons]::ok, [Windows.Forms.MessageBoxIcon]::Warning)
		$date = Get-Date
		foreach ($err in $error) {
			Add-Content "$snipmanUPpath\SnippetManagerErrors.log" "$date :$err"
		}
		return
	}
	[void][System.Diagnostics.Process]::Start($Updatefile) 
	$form1.close()
}

Main # This call must remain below all other event functions

#endregion
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5xmE8rJPMxGSVvXDo/GLnia0
# V3qgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFJ/+kongs1Nb90v
# c3UNwv3I7tjMMA0GCSqGSIb3DQEBAQUABIIBABIf/SO5KZElZ+H4qBMYszZDswNy
# AIl36rys0+FAls+6dipDElk4bPZx2MyQytRMSEXRtkBxA/Th8zOjMvSWWgoaHlxu
# 3B4kQCYU0+NtCGz2X7VNJQSTwQLrTYL/Gvx7tSONo+hcNkOpUaXCrldTVoG0Ytva
# ntTyCmHjPU2cNJ3s3zHwAu+HmdtZ/gpOMuupdn7VeQz436NbIaUtVVTfOJLCPrIC
# 6pjrz192+c61oP4MFndiSuQSEAgNF/gVqzGH3e5zioNY9eU/LppnB+xBeVghuC1B
# drxW9Qm1DLcHARWKrG2Eph9IbvUmFqe3prWD0MhEqd3/V2d/lU5/W0q1Rv0=
# SIG # End signature block
