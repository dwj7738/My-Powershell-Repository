<#
.SYNOPSIS
   Experts-Exchange Question:Passing Arguments from HTA Textboxes to Powershell Script Called from HTA Button press
   http://www.experts-exchange.com/Programming/Languages/Scripting/Powershell/Q_27760476.html
.DESCRIPTION
   <A detailed description of the script>
.PARAMETER <paramName>
   none	
.EXAMPLE
   .\Experts-Exchange Forms.ps1
#>
$title = "Experts Exchange Script"



[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$objForm = New-Object System.Windows.Forms.Form
$objForm.Text = $title
$objForm.Size = New-Object System.Drawing.Size(300,200) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objTextBox.Text;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click(
	{
	$x=$objTextBox.Text;
	$y=$objTextBox1.Text;
	$objForm.Close()
	}
	)
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(260,20) 
$objLabel.Text = "Netbios Name"
$objForm.Controls.Add($objLabel) 

$objTextBox = New-Object System.Windows.Forms.TextBox 
$objTextBox.Location = New-Object System.Drawing.Size(10,40) 
$objTextBox.Size = New-Object System.Drawing.Size(260,20) 
$objForm.Controls.Add($objTextBox) 


$objLabel1 = New-Object System.Windows.Forms.Label
$objLabel1.Location = New-Object System.Drawing.Size(10,60) 
$objLabel1.Size = New-Object System.Drawing.Size(260,20) 
$objLabel1.Text = "IP Address"
$objForm.Controls.Add($objLabel1) 

$objTextBox1 = New-Object System.Windows.Forms.TextBox 
$objTextBox1.Location = New-Object System.Drawing.Size(10,80) 
$objTextBox1.Size = New-Object System.Drawing.Size(260,20) 
$objForm.Controls.Add($objTextBox1) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

$x
$y
#
# Insert your script here
#
# myscriptname $x $y
# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7qyPDM8RLN3L+Yr+3FBRHd8v
# zrugggI9MIICOTCCAaagAwIBAgIQiDf4l7KfgJdCCCaJOuGruDAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2Vyc2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xMjA2MTYwNjIyMDdaFw0zOTEyMzEyMzU5NTlaMBoxGDAWBgNVBAMTD1Bvd2Vy
# c2hlbGwgVXNlcjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA2AQ5hTYXFzN9
# 62GIrE8tV+e3cYxFMYN5sG6TRa8ZBGAc2IEQ9uYrz7YXUstjYq6AkVpPjF/h4mlh
# WTFCjBSlhRQj8B6MOSy5pnKFM+cLM/5UcE7ZKcwXpvrbxntu4DiT8iBxKrSYjkqA
# BbMZCyrQ8BAIrFgqy/t97FyGaFFoDP0CAwEAAaN2MHQwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwXQYDVR0BBFYwVIAQe3Eaz1UlVI4+TqpVWMaLyKEuMCwxKjAoBgNVBAMT
# IVBvd2Vyc2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQrIslSDNpf4tLn3Ai
# OEZ3MTAJBgUrDgMCHQUAA4GBAHdn+q07uKxlU/ELAluEVTsKBDxoIHtNa9GDtUhE
# Hrl10nwwgmTtC6XO2UmwJVw/1J+LqebKe7mWpha5Uzyc8GgeNc+m8zdbGuvqzpQe
# vOZ9UZSYBKrXvNXhCqw46WqEVpQP9DM+fJzc6O1trbHQ9HAFPgTktEIz5fg8gz2V
# GoJxMYIBYDCCAVwCAQEwQDAsMSowKAYDVQQDEyFQb3dlcnNoZWxsIExvY2FsIENl
# cnRpZmljYXRlIFJvb3QCEIg3+Jeyn4CXQggmiTrhq7gwCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FAF6OXdtQ5VFI/2tseQy5401e85wMA0GCSqGSIb3DQEBAQUABIGAjRiIihfPQr/Y
# i362oVQ9bt8c+RnP7Pn1H+pPT2oHrhc3fi0STojZEnon/9VHw79iYkMe8VAOHzX0
# 0EOT46RonQPM6uitjKv47XkRGqiY8+UCh5fGWDOGxUPwj/yDkIUSIpWnB+OXtNxW
# gOkja8iPf0NtBdjv8lqIt0NrxHcZtag=
# SIG # End signature block
