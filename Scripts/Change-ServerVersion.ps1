Function Show-BoxSelection{
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Select SKU Upgrade"
$objForm.Size = New-Object System.Drawing.Size(600,200) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objListBox.SelectedItem;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(200,133)
$OKButton.Size = New-Object System.Drawing.Size(75,25)
$OKButton.Text = "OK"
$OKButton.Add_Click({$objListBox.SelectedItem;$objForm.Close()})
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(300,133)
$CancelButton.Size = New-Object System.Drawing.Size(75,25)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({[environment]::exit(0);$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(400,20) 
$objLabel.Text = "Current SKU: " + [String]$CurrentWinCaption.Caption
$objForm.Controls.Add($objLabel) 

$objLabel2 = New-Object System.Windows.Forms.Label
$objLabel2.Location = New-Object System.Drawing.Size(10,40) 
$objLabel2.Size = New-Object System.Drawing.Size(400,20) 
$objLabel2.Text = "Select SKU Upgrade: "
$objForm.Controls.Add($objLabel2) 

$objListBox = New-Object System.Windows.Forms.ListBox 
$objListBox.Location = New-Object System.Drawing.Size(10,60) 
$objListBox.Size = New-Object System.Drawing.Size(560,40) 
$objListBox.Height = 80

If($UpgradeSelection01 -ne "NA"){[void] $objListBox.Items.Add($UpgradeSelection01)}
If($UpgradeSelection02 -ne "NA"){[void] $objListBox.Items.Add($UpgradeSelection02)}

$objForm.Controls.Add($objListBox) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()
}
Function Show-BoxResult{
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Select SKU Upgrade"
$objForm.Size = New-Object System.Drawing.Size(600,200) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objListBox.SelectedItem;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(200,133)
$OKButton.Size = New-Object System.Drawing.Size(75,25)
$OKButton.Text = "OK"
$OKButton.Add_Click({$objListBox.SelectedItem;$objForm.Close()})
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(300,133)
$CancelButton.Size = New-Object System.Drawing.Size(75,25)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({[environment]::exit(0);$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(400,20) 
$objLabel.Text = "Current SKU: " + [String]$CurrentWinCaption.Caption
$objForm.Controls.Add($objLabel) 

$objLabel2 = New-Object System.Windows.Forms.Label
$objLabel2.Location = New-Object System.Drawing.Size(10,40) 
$objLabel2.Size = New-Object System.Drawing.Size(400,20) 
$objLabel2.Text = "Selected SKU: $X"
$objForm.Controls.Add($objLabel2)

$objLabel3 = New-Object System.Windows.Forms.Label
$objLabel3.Location = New-Object System.Drawing.Size(10,60) 
$objLabel3.Size = New-Object System.Drawing.Size(600,40) 
$objLabel3.Text = "Command to run: $CMD"
$objForm.Controls.Add($objLabel3) 

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()
}
Function Show-BoxReboot{
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Select SKU Upgrade"
$objForm.Size = New-Object System.Drawing.Size(600,200) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objListBox.SelectedItem;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(200,133)
$OKButton.Size = New-Object System.Drawing.Size(75,25)
$OKButton.Text = "OK"
$OKButton.Add_Click({Restart-Computer -Force;$objForm.Close()})
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(300,133)
$CancelButton.Size = New-Object System.Drawing.Size(75,25)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({[environment]::exit(0);$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(400,20) 
$objLabel.Text = "You need to reboot the server"
$objForm.Controls.Add($objLabel) 

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()
}
Function Inventory-Computer{
    $CurrentWinCaption = Get-WmiObject -Class Win32_OperatingSystem
    #Write-Output $CurrentWinCaption.Caption
    Switch ($CurrentWinCaption.Caption){
        'Microsoft Windows Server 2008 R2 Standard '{
            Write-Verbose [String]$CurrentWinCaption.Caption
            $UpgradeSelection01 = "Microsoft Windows Server 2008 R2 Enterprise"
            $UpgradeSelection02 = "Microsoft Windows Server 2008 R2 Datacenter"
            }
        'Microsoft Windows Server 2008 R2 Enterprise '{
            Write-Verbose $CurrentWinCaption.Caption
            $UpgradeSelection01 = "Microsoft Windows Server 2008 R2 Datacenter"
            $UpgradeSelection02 = "NA"
            }
        'Microsoft Windows Server 2008 R2 Datacenter '{
            Write-Verbose $CurrentWinCaption.Caption
            $UpgradeSelection01 = "Unable to upgrade current edition"
            $UpgradeSelection02 = "NA"
            }
        'Microsoft Windows Server 2012 Standard'{
            Write-Verbose $CurrentWinCaption.Caption
            $UpgradeSelection01 = "Microsoft Windows Server 2012 Datacenter"
            $UpgradeSelection02 = "NA"
            }
        'Microsoft Windows Server 2012 Standard Evaluation'{
            Write-Verbose $CurrentWinCaption.Caption
            $UpgradeSelection01 = "Microsoft Windows Server 2012 Standard"
            $UpgradeSelection02 = "Microsoft Windows Server 2012 Datacenter"
            }
        'Microsoft Windows Server 2012 Datacenter Evaluation'{
            Write-Verbose $CurrentWinCaption.Caption
            $UpgradeSelection01 = "Microsoft Windows Server 2012 Datacenter"
            $UpgradeSelection02 = "NA"
            }
        'Microsoft Windows Server 2012 Datacenter'{
            Write-Verbose $CurrentWinCaption.Caption
            $UpgradeSelection01 = "Unable to upgrade current edition"
            $UpgradeSelection02 = "NA"
            }
        'Microsoft Windows Server 2012 R2 Standard'{
            Write-Verbose $CurrentWinCaption.Caption
            $UpgradeSelection01 = "Microsoft Windows Server 2012 R2 Datacenter"
            $UpgradeSelection02 = "NA"
            }
        'Microsoft Windows Server 2012 R2 Standard Evaluation'{
            Write-Verbose $CurrentWinCaption.Caption
            $UpgradeSelection01 = "Microsoft Windows Server 2012 R2 Standard"
            $UpgradeSelection02 = "Microsoft Windows Server 2012 R2 Datacenter"
            }
        'Microsoft Windows Server 2012 R2 Datacenter Evaluation'{
            Write-Verbose $CurrentWinCaption.Caption
            $UpgradeSelection01 = "Upgrade to Microsoft Windows Server 2012 R2 Datacenter"
            $UpgradeSelection02 = "NA"
            }
        'Microsoft Windows Server 2012 R2 Datacenter'{
            Write-Verbose $CurrentWinCaption.Caption
            $UpgradeSelection01 = "Unable to upgrade current edition"
            $UpgradeSelection02 = "NA"
            }
        Default{
            Write-Verbose "Unable to upgrade"
            $UpgradeSelection01 = "Unable To Upgrade"
            $UpgradeSelection02 = "NA"
            }
        }
}
Function Upgrade-SKU{
    #$CurrentWindowsEdition = [String]$CurrentWinCaption.Caption
    Switch ($CurrentWinCaption.Caption){
        'Microsoft Windows Server 2008 R2 Standard '{
            Write-Verbose [String]$CurrentWinCaption.Caption
            if ($x -eq 'Microsoft Windows Server 2008 R2 Enterprise'){
                $UpgradeToWinEditionPID = "489J6-VHDMP-X63PK-3K798-CPX3Y"
				$CMD = "DISM.exe /Online /Set-Edition:ServerEnterprise /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            if ($x -eq 'Microsoft Windows Server 2008 R2 Datacenter'){
                $UpgradeToWinEditionPID = "74YFP-3QFB3-KQT8W-PMXWJ-7M648"
				$CMD = "DISM.exe /Online /Set-Edition:ServerDataCenter /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            }
        'Microsoft Windows Server 2008 R2 Enterprise '{
            Write-Verbose $CurrentWinCaption.Caption
            if ($x -eq 'Microsoft Windows Server 2008 R2 Datacenter'){
                $UpgradeToWinEditionPID = "74YFP-3QFB3-KQT8W-PMXWJ-7M648"
				$CMD = "DISM.exe /Online /Set-Edition:ServerDataCenter /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            }
        'Microsoft Windows Server 2008 R2 Datacenter '{
            Write-Verbose $CurrentWinCaption.Caption
            }
        'Microsoft Windows Server 2012 Standard'{
            Write-Verbose $CurrentWinCaption.Caption
            if ($x -eq 'Microsoft Windows Server 2012 Datacenter'){
				$UpgradeToWinEditionPID = "48HP8-DN98B-MYWDG-T2DCC-8W83P"
				$CMD = "DISM.exe /Online /Set-Edition:ServerDataCenter /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            }
        'Microsoft Windows Server 2012 Standard Evaluation'{
            Write-Verbose $CurrentWinCaption.Caption
            if ($x -eq 'Microsoft Windows Server 2012 Standard'){
				$UpgradeToWinEditionPID = "XC9B7-NBPP2-83J2H-RHMBY-92BT4"
				$CMD = "DISM.exe /Online /Set-Edition:ServerStandard /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            if ($x -eq 'Microsoft Windows Server 2012 Datacenter'){
				$UpgradeToWinEditionPID = "48HP8-DN98B-MYWDG-T2DCC-8W83P"
				$CMD = "DISM.exe /Online /Set-Edition:ServerDataCenter /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            }
        'Microsoft Windows Server 2012 Datacenter Evaluation'{
            Write-Verbose $CurrentWinCaption.Caption
            if ($x -eq 'Microsoft Windows Server 2012 Datacenter'){
				$UpgradeToWinEditionPID = "48HP8-DN98B-MYWDG-T2DCC-8W83P"
				$CMD = "DISM.exe /Online /Set-Edition:ServerDataCenter /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            }
        'Microsoft Windows Server 2012 Datacenter'{
            Write-Verbose $CurrentWinCaption.Caption
            }
        'Microsoft Windows Server 2012 R2 Standard'{
            Write-Verbose $CurrentWinCaption.Caption
            if ($x -eq 'Microsoft Windows Server 2012 R2 Datacenter'){
				$UpgradeToWinEditionPID = "W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9"
				$CMD = "DISM.exe /Online /Set-Edition:ServerDataCenter /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            }
        'Microsoft Windows Server 2012 R2 Standard Evaluation'{
            Write-Verbose $CurrentWinCaption.Caption
            if ($x -eq 'Microsoft Windows Server 2012 R2 Standard'){
				$UpgradeToWinEditionPID = "D2N9P-3P6X9-2R39C-7RTCD-MDVJX"
				$CMD = "DISM.exe /Online /Set-Edition:ServerStandard /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            if ($x -eq 'Microsoft Windows Server 2012 R2 Datacenter'){
				$UpgradeToWinEditionPID = "W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9"
				$CMD = "DISM.exe /Online /Set-Edition:ServerDataCenter /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            }
        'Microsoft Windows Server 2012 R2 Datacenter Evaluation'{
            Write-Verbose $CurrentWinCaption.Caption
            if ($x -eq 'Microsoft Windows Server 2012 R2 Datacenter'){
				$UpgradeToWinEditionPID = "W3GGN-FT8W3-Y4M27-J84CP-Q3VJ9"
				$CMD = "DISM.exe /Online /Set-Edition:ServerDataCenter /ProductKey:$UpgradeToWinEditionPID /AcceptEula /NoRestart"
                }
            }
        'Microsoft Windows Server 2012 R2 Datacenter'{
            Write-Verbose $CurrentWinCaption.Caption
            }
        Default {
            Write-Verbose "Unable to upgrade."
            }
        }
}

#Set retunr from forms to Zero
$x = ""
$CMD = ""

# Get a grip of reality
. Inventory-Computer

#Show the options
. Show-BoxSelection

#Set the return value to $X
$X = $objListBox.SelectedItem

#Find out what actully is being done here
. Upgrade-SKU

#Show the result of the selection and the command that will run
. Show-BoxResult

#Execute Upgrade
If($CMD -ne ""){
    cmd.exe /c $CMD
}


#Hold it for a sec...
if ($LastExitCode -eq '3010'){
    Write-Output "Reboot nedeed"
    . Show-BoxReboot
    }
Start-Sleep 5

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnlUU/cMzRhudtzn1xXOQzBxv
# l9ygggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPvlLdGosepde5Lh
# 6FQb7vJAFqMdMA0GCSqGSIb3DQEBAQUABIIBAB2M3SsbzXKmggBjp+5HUq4v+oPl
# PY+eouU3ycaaIIcGNeLnNH73g7aCHk142lSft444UDZu1cPbaRxTTTMdEgz8HnW9
# eqWEwxfYKZ2YeaYAc0KZjzEimHJtjSJC5Bu67Rx+eheIMUsOS3+kA3DmPSIycII+
# mGDv3nNyxZsU8u9rOpoFo7j8ff8Bf8yYqBXXFBal70/kK+5GC2jmYJ2ejb3qLzRZ
# toVxRJaRvZ2cFEdlNtU6dpgx24wJXWimy8KlV1hn8IYCMLCvgpveQ+GMTd51cxX6
# FQYQIE7TOpCVe+aGUdIpXfXW5Ae+Hrv/XwdgBV2q6qNjCnXlNSjL4DOpfbg=
# SIG # End signature block
