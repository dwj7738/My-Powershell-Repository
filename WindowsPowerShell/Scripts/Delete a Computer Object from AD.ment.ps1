## ==================================================================================
## Title       : Delete Computer Object from AD in a Multi-Domain environment
## Description : Deletes a computer object from the AD after allowing selection of
##				 the correct domain in a  multi-domain environment.
## Author      : C.Perry
## Date        : 14/2/2012
## Input       : 	
## Output      : 
## Usage	   : PS> .\DeleteComputerObject.ps1
## Notes	   :
## Tag		   : Forms, .NET Framework, AD
## Change log  :
## ==================================================================================
## INITIALIZATION SECTION ##
CLS
$x = $null
$y = $null
$domain = $null
# Error display on console
Function ErrorDisplay ([string]$strErrorMsg)
{
	write-host -backgroundcolor yellow -foregroundcolor black $strErrorMsg ; 
}
# Displays an Input Form to input the computer object
Function InputForm ([string]$strFormText, [string]$strLabelText)
{
	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

	$objForm = New-Object System.Windows.Forms.Form 
	$objForm.Text = $strFormText
	$objForm.Size = New-Object System.Drawing.Size(300,200) 
	$objForm.StartPosition = "CenterScreen"

	$objForm.KeyPreview = $True
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
			{				$x = $objTextBox.Text;$objForm.Close()}})
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
			{				$objForm.Close()}})

	$OKButton = New-Object System.Windows.Forms.Button
	$OKButton.Location = New-Object System.Drawing.Size(75,120)
	$OKButton.Size = New-Object System.Drawing.Size(75,23)
	$OKButton.Text = "OK"
	$OKButton.Add_Click({$x = $objTextBox.Text;$objForm.Close()})
	$objForm.Controls.Add($OKButton)

	$CancelButton = New-Object System.Windows.Forms.Button
	$CancelButton.Location = New-Object System.Drawing.Size(150,120)
	$CancelButton.Size = New-Object System.Drawing.Size(75,23)
	$CancelButton.Text = "Cancel"
	$CancelButton.Add_Click({$objForm.Close()})
	$objForm.Controls.Add($CancelButton)

	$objLabel = New-Object System.Windows.Forms.Label
	$objLabel.Location = New-Object System.Drawing.Size(10,20) 
	$objLabel.Size = New-Object System.Drawing.Size(280,20) 
	$objLabel.Text = $strLabelText
	$objForm.Controls.Add($objLabel) 

	$objTextBox = New-Object System.Windows.Forms.TextBox 
	$objTextBox.Location = New-Object System.Drawing.Size(10,40) 
	$objTextBox.Size = New-Object System.Drawing.Size(250,40) 
	$objForm.Controls.Add($objTextBox) 
	$objForm.Controls.($objTextBox)

	$objForm.Topmost = $True
	#make cursor appear in textbox first
	$handler = {$objForm.ActiveControl = $objTextBox}
	$objForm.add_Load($handler)
	$objForm.Add_Shown({$objForm.Activate()})
	[void] $objForm.ShowDialog()

	return $x #  Returns the computer name string
}
# Information Display Form
Function DisplayForm ([string]$strFormText, [string]$strLabelText,[string]$strBackColor)
{

	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
	$FontBold = new-object System.Drawing.Font("Arial",8,[Drawing.FontStyle]'Bold' )

	$objForm = New-Object System.Windows.Forms.Form 
	$objForm.Text = $strFormText
	$objForm.Backcolor = $strBackColor
	$objForm.Size = New-Object System.Drawing.Size(300,200) 
	$objForm.StartPosition = "CenterScreen"

	$objForm.KeyPreview = $True
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
			{				$y = "True";$objForm.Close()}})
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
			{				$y = "False";$objForm.Close()}})

	$OKButton = New-Object System.Windows.Forms.Button
	$OKButton.Location = New-Object System.Drawing.Size(75,120)
	$OKButton.Size = New-Object System.Drawing.Size(75,23)
	$OKButton.Text = "OK"
	$OKButton.Add_Click({$y = "True";$objForm.Close()})
	$objForm.Controls.Add($OKButton)

	$CancelButton = New-Object System.Windows.Forms.Button
	$CancelButton.Location = New-Object System.Drawing.Size(150,120)
	$CancelButton.Size = New-Object System.Drawing.Size(75,23)
	$CancelButton.Text = "Cancel"
	$CancelButton.Add_Click({$y = "False";$objForm.Close()})
	$objForm.Controls.Add($CancelButton)

	$objLabel = New-Object System.Windows.Forms.Label
	$objLabel.Location = New-Object System.Drawing.Size(10,20) 
	$objLabel.Size = New-Object System.Drawing.Size(280,50) 
	$objLabel.Text = $strLabelText
	$objLabel.Font = $FontBold
	$objForm.Controls.Add($objLabel) 
	$objForm.Topmost = $True
	$objForm.Add_Shown({$objForm.Activate()})
	[void] $objForm.ShowDialog()

	return $y #  Returns a confirmation
}
# Choose Item from List
Function Select-Item 
{	<# 
    .Synopsis        Allows the user to select simple items, returns a number to indicate the selected item. 
    .Description 
        Produces a list on the screen with a caption followed by a message, the options are then
		displayed one after the other, and the user can one. 
        Note that help text is not supported in this version. 
    .Example 
        PS> select-item -Caption "Configuring RemoteDesktop" -Message "Do you want to: " -choice "&Disable Remote Desktop",           "&Enable Remote Desktop","&Cancel"  -default 1       Will display the following 
          Configuring RemoteDesktop           Do you want to:           [D] Disable Remote Desktop  [E] Enable Remote Desktop  [C] Cancel  [?] Help (default is "E"): 
    .Parameter Choicelist 
        An array of strings, each one is possible choice. The hot key in each choice must be prefixed with an & sign 
    .Parameter Default 
        The zero based item in the array which will be the default choice if the user hits enter. 
    .Parameter Caption 
        The First line of text displayed 
    .Parameter Message 
        The Second line of text displayed     #> 
	Param( [String[]]$choiceList, 
		[String]$Caption, 
		[String]$Message, 
		[int]$default
	) 
	$choicedesc = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription] 
	$choiceList | foreach { $choicedesc.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $_))} 
	$Host.ui.PromptForChoice($caption, $message, $choicedesc, $default) 
} 

## PROCESS SECTION ##
# Do until user Cancels
While ($domain -ne "Cancel")
{
	TRY
	{		#TRY
		$domain = select-item -Caption "Domain Selection for AD Server Deletion" -Message "Please select a domain: " `
		-choice "&1 DomainA", "&2 DomainB", "&3 DomainC", "&4 DomainD", "&5 DomainE", "&6 Cancel" -default 5
		switch ($domain) 
		{
			0 {$domain = "DomainA"} 
			1 {$domain = "DomainB"} 
			2 {$domain = "DomainC"} 
			3 {$domain = "DomainD"} 
			4 {$domain = "DomainE"} 
			5 {$domain = "Cancel"} 
			default {$domain = "Cancel"}
		}
		If ($domain -eq "Cancel")
		{
			echo "Cancel selected"
			exit
		}
		$HeaderTxt = "Data Entry Form"
		$LabelTxt = "Please enter the computer name below:"
		[string]$x = InputForm $HeaderTxt $LabelTxt 
		$e = $x.TrimStart(" ")
		#create the domain context object
		$context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$domain)
		#get the domain object
		$dom = [system.directoryservices.activedirectory.domain]::GetDomain($context)
		#$dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()   
		#$dom # Debug line
		$root = $dom.GetDirectoryEntry() 
		#$root  #Debug line
		$search = [System.DirectoryServices.DirectorySearcher]$root 
		$search.filter = "(&(objectclass=computer)(name=*$e*))" 
		#$search.Filter #Debug line
		$ComputerToDelete = $search.findall() | %{$_.GetDirectoryEntry() }
		If ($ComputerToDelete -eq $null)
		{			#IFnull
			$ErrorTitle = "Computer " + $e + " Not Found in the AD"
			$ErrorMsg = "Computer Not Found"
			$BackColour = "Yellow"
			ErrorDisplay $ErrorTitle $ErrorMsg
			$y = Displayform $ErrorMsg $ErrorTitle $BackColour
		}#endIfNull
		Else
		{			#ElseFound
			#display confirmation form
			$HeaderTxt = "Fat Finger Checker Form"
			$LabelTxt = "Is this the computer you want to delete?  `n`n " + $ComputerToDelete.Name 
			$y = DisplayForm $HeaderTxt $LabelTxt 
			#Delete computer object from AD
			$search.findall() | %{$_.GetDirectoryEntry() } | %{$_.DeleteObject(0)}
			#Test to make sure it is deleted
			$ComputerToDelete = $search.findall() | %{$_.GetDirectoryEntry() }
			If ($ComputerToDelete -eq $null)
			{				#IFnull
				$LabelTxt = "Computer " + $e + " deleted from AD."
				$HeaderTxt = "Computer Object Deleted"
				$BackColour = "Green"
				$y = Displayform $HeaderTxt $LabelTxt $BackColour
			}#endIfNull
			Else
			{				#ElseFound
				#display confirmation form
				$LabelTxt = "Computer " + $e + " was not deleted from AD."
				$HeaderTxt = "Error Deleting Computer Object"
				$BackColour = "Red"
				ErrorDisplay $LabelTxt 
				$y = DisplayForm $HeaderTxt $LabelTxt $BackColour 
			}#endElseFound
		}#endElseFound
	}#endTRY
	Catch
	{
		$exceptionType = $_.Exception.GetType()
		if ($exceptionType -match 'System.Management.Automation.MethodInvocation')
		{			#IfExc
			#Attempt to access an non existant computer
			$Wha = $Server + " - " +$_.Exception.Message
			write-host -backgroundcolor red -foregroundcolor Black $Wha 
		}#endIfExc
		if ($exceptionType -match 'System.Management.Automation.Host.PromptingException')
		{			#IfExc
			#Attempt to access an non existant computer
			$Wha = $Server + " - " +$_.Exception.Message
			write-host -backgroundcolor red -foregroundcolor Black $Wha 
			$domain = "Cancel"
			exit
		}#endIfExc
		if ($exceptionType -match 'System.UnauthorizedAccessException')
		{			#IfEx
			$UnauthorizedExceptionType = $Server + " Access denied - insufficent privileges"
			# write-host "Exception: $exceptionType"
			write-host -backgroundcolor red "UnauthorizedException: $UnauthorizedExceptionType"
		}#endIfEx
		if ($exceptionType -match 'System.Management.Automation.RuntimeException')
		{			#IfExc
			# Attempt to access an non existant array, output is suppressed
			write-host -backgroundcolor cyan -foregroundcolor black "$Server - A runtime exception occured: " $_.Exception.Message; 
		}#endIfExc
	}#end Catch
}#end While
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+mOObmagIK8Zang1loKu9uK6
# iWugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCbMjdEGx2DaRl+S
# jNC+VGUxtoEBMA0GCSqGSIb3DQEBAQUABIIBAIoJPi7V9XG0fl6zjZwXHJGPv+/j
# y4+PswDnyihufrmRPuXZB+6oI4WPIbENoEG3p2f5njjXO8DBlm0hOlC15ACaHmMU
# Ig4TbGto04g/ImsZeBvnUOblKGAhzORZndr0LBmq8eNZuAN2MqfOt83viF7ZiJ1X
# lIRDBXbzeTtzYLheJFU2iN+/WRhDWb+3v0RX8e1kXKoSuZlgG9GPdiYb1i94zkSX
# ysLX4a0VhbQUusSWSkmrV+Aid8Ys3nWU3DrDgNPSOMZ+EMxWzxGpy+GunRb3JYrq
# MzoVgQ7hGOEIPyBP3oH/87dVuBi181LG/b4HhQGZWSz+/ME/qlN9ksZf2U8=
# SIG # End signature block
