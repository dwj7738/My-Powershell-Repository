Add-PSSnapin quest.activeroles.admanagement
$cred = Get-Credential
$conn = connect-QADService -service 'x.x.x.x' -credential $cred

#region Script Settings
#<ScriptSettings xmlns="http://tempuri.org/ScriptSettings.xsd">
#  <ScriptPackager>
#    <process>powershell.exe</process>
#    <arguments />
#    <extractdir>%TEMP%</extractdir>
#    <files />
#    <usedefaulticon>true</usedefaulticon>
#    <showinsystray>false</showinsystray>
#    <altcreds>false</altcreds>
#    <efs>true</efs>
#    <ntfs>true</ntfs>
#    <local>false</local>
#    <abortonfail>true</abortonfail>
#    <product />
#    <version>1.0.0.1</version>
#    <versionstring />
#    <comments />
#    <includeinterpreter>false</includeinterpreter>
#    <forcecomregistration>false</forcecomregistration>
#    <consolemode>false</consolemode>
#    <EnableChangelog>false</EnableChangelog>
#    <AutoBackup>false</AutoBackup>
#    <snapinforce>false</snapinforce>
#    <snapinshowprogress>false</snapinshowprogress>
#    <snapinautoadd>0</snapinautoadd>
#    <snapinpermanentpath />
#  </ScriptPackager>
#</ScriptSettings>
#endregion


#region ScriptForm Designer (Created with Admin Script Editor trial edition)

#region Constructor

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

#endregion

#region Post-Constructor Custom Code

#endregion

#region Form Creation
#Warning: It is recommended that changes inside this region be handled using the ScriptForm Designer.
#When working with the ScriptForm designer this region and any changes within may be overwritten.
#~~< Form1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Form1 = New-Object System.Windows.Forms.Form
$Form1.ClientSize = New-Object System.Drawing.Size(336, 490)
$Form1.Text = "AD Utility - Test Environment"
#~~< Label4 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label4 = New-Object System.Windows.Forms.Label
$Label4.Location = New-Object System.Drawing.Point(12, 449)
$Label4.Size = New-Object System.Drawing.Size(106, 21)
$Label4.TabIndex = 17
$Label4.Text = "Changed Password"
#~~< Label3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label3 = New-Object System.Windows.Forms.Label
$Label3.Location = New-Object System.Drawing.Point(11, 287)
$Label3.Size = New-Object System.Drawing.Size(171, 20)
$Label3.TabIndex = 16
$Label3.Text = "Username to Change:"
$Label3.add_Click({Label3Click($Label3)})
#~~< Label2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label2 = New-Object System.Windows.Forms.Label
$Label2.Location = New-Object System.Drawing.Point(173, 16)
$Label2.Size = New-Object System.Drawing.Size(82, 20)
$Label2.TabIndex = 15
$Label2.Text = "Select Domain "
$Label2.add_Click({Label2Click($Label2)})
#~~< RichTextBox2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RichTextBox2 = New-Object System.Windows.Forms.RichTextBox
$RichTextBox2.Location = New-Object System.Drawing.Point(12, 422)
$RichTextBox2.Size = New-Object System.Drawing.Size(144, 24)
$RichTextBox2.TabIndex = 14
$RichTextBox2.Text = ""
#~~< TextBox3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox3 = New-Object System.Windows.Forms.TextBox
$TextBox3.Location = New-Object System.Drawing.Point(11, 310)
$TextBox3.Size = New-Object System.Drawing.Size(144, 20)
$TextBox3.TabIndex = 13
$TextBox3.Text = ""
#~~< ComboBox1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ComboBox1 = New-Object System.Windows.Forms.ComboBox
$ComboBox1.FormattingEnabled = $true
$ComboBox1.Location = New-Object System.Drawing.Point(12, 12)
$ComboBox1.Size = New-Object System.Drawing.Size(158, 21)
$ComboBox1.TabIndex = 12
$ComboBox1.Text = ""
$ComboBox1.Items.AddRange([System.Object[]](@("10.153.95.3", "10.153.110.131")))
#~~< Button4 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button4 = New-Object System.Windows.Forms.Button
$Button4.Location = New-Object System.Drawing.Point(212, 345)
$Button4.Size = New-Object System.Drawing.Size(78, 22)
$Button4.TabIndex = 10
$Button4.Text = "Enable User"
$Button4.UseVisualStyleBackColor = $true
$Button4.add_Click({Button4Click($Button4)})
#~~< Button3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button3 = New-Object System.Windows.Forms.Button
$Button3.Location = New-Object System.Drawing.Point(124, 345)
$Button3.Size = New-Object System.Drawing.Size(82, 22)
$Button3.TabIndex = 9
$Button3.Text = "Unlock User"
$Button3.UseVisualStyleBackColor = $true
$Button3.add_Click({Button3Click($Button3)})
#~~< Button2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Location = New-Object System.Drawing.Point(12, 345)
$Button2.Size = New-Object System.Drawing.Size(106, 24)
$Button2.TabIndex = 8
$Button2.Text = "Reset Password"
$Button2.UseVisualStyleBackColor = $true
$Button2.add_Click({Button2Click($Button2)})
#~~< Label1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label1 = New-Object System.Windows.Forms.Label
$Label1.Location = New-Object System.Drawing.Point(212, 463)
$Label1.Size = New-Object System.Drawing.Size(117, 18)
$Label1.TabIndex = 7
$Label1.Text = "For Use by: VaforVets"
$Label1.add_Click({Label1Click($Label1)})
#~~< Button1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Point(249, 73)
$Button1.Size = New-Object System.Drawing.Size(67, 20)
$Button1.TabIndex = 1
$Button1.Text = "Search"
$Button1.UseVisualStyleBackColor = $true
$Button1.add_Click({ButtonClick($Button1)})
#~~< RadioButton3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RadioButton3 = New-Object System.Windows.Forms.RadioButton
$RadioButton3.Location = New-Object System.Drawing.Point(152, 48)
$RadioButton3.Size = New-Object System.Drawing.Size(82, 24)
$RadioButton3.TabIndex = 5
$RadioButton3.TabStop = $true
$RadioButton3.Text = "User Name"
$RadioButton3.UseVisualStyleBackColor = $true
#~~< RadioButton2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RadioButton2 = New-Object System.Windows.Forms.RadioButton
$RadioButton2.Location = New-Object System.Drawing.Point(72, 48)
$RadioButton2.Size = New-Object System.Drawing.Size(104, 24)
$RadioButton2.TabIndex = 4
$RadioButton2.TabStop = $true
$RadioButton2.Text = "Last Name"
$RadioButton2.UseVisualStyleBackColor = $true
$RadioButton2.add_CheckedChanged({RadioButton2CheckedChanged($RadioButton2)})
#~~< RadioButton1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RadioButton1 = New-Object System.Windows.Forms.RadioButton
$RadioButton1.Location = New-Object System.Drawing.Point(16, 48)
$RadioButton1.Size = New-Object System.Drawing.Size(104, 24)
$RadioButton1.TabIndex = 3
$RadioButton1.TabStop = $true
$RadioButton1.Text = "Email"
$RadioButton1.UseVisualStyleBackColor = $true
$RadioButton1.add_CheckedChanged({RadioButton1CheckedChanged($RadioButton1)})
#~~< RichTextBox1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RichTextBox1 = New-Object System.Windows.Forms.RichTextBox
$RichTextBox1.Location = New-Object System.Drawing.Point(11, 99)
$RichTextBox1.Size = New-Object System.Drawing.Size(305, 175)
$RichTextBox1.TabIndex = 2
$RichTextBox1.Text = ""
#~~< TextBox1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox1 = New-Object System.Windows.Forms.TextBox
$TextBox1.Location = New-Object System.Drawing.Point(12, 73)
$TextBox1.Size = New-Object System.Drawing.Size(219, 20)
$TextBox1.TabIndex = 0
$TextBox1.Text = ""
$Form1.Controls.Add($Label4)
$Form1.Controls.Add($Label3)
$Form1.Controls.Add($Label2)
$Form1.Controls.Add($RichTextBox2)
$Form1.Controls.Add($TextBox3)
$Form1.Controls.Add($ComboBox1)
$Form1.Controls.Add($Button4)
$Form1.Controls.Add($Button3)
$Form1.Controls.Add($Button2)
$Form1.Controls.Add($Label1)
$Form1.Controls.Add($Button1)
$Form1.Controls.Add($RadioButton3)
$Form1.Controls.Add($RadioButton2)
$Form1.Controls.Add($RadioButton1)
$Form1.Controls.Add($RichTextBox1)
$Form1.Controls.Add($TextBox1)

#endregion

#region Custom Code

#endregion

#region Event Loop

function Main{
 [System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($Form1)
}

#endregion

#endregion

#region Event Handlers

function ButtonClick( $object ){


	$domain = $combobox1.Text
	$samaccountname = $textbox1.text
	function Get-UTCAge
{
 #get date time of the last password change
	Param([int64] $Last = 0)
	if ($Last -eq 0)
	{
		write 0
	}
	else
	{
		#clock starts counting from 1/1/1601.
		[datetime]$utc = "1/1/1601"
		#calculate the number of days based on the int64 number
		$i = $Last / 864000000000

		#Add the number of days to 1/1/1601
		#and write the result to the pipeline
		write($utc.AddDays($i))
	}
} # end Get-UTCAge function

function Get-PwdAge
{
 
Param([int64] $LastSet = 0)

if ($LastSet -eq 0)
{
	write "0"
}
else
{
	#get the date the password was last changed
	[datetime]$ChangeDate = Get-UTCAge $LastSet

	#get the current date and time
	[datetime]$RightNow = Get-Date

	#write the difference in days
	write $RightNow.Subtract($ChangeDate).Days
}
} #end Get-PwdAge function


#main code
#define some constants

#New-Variable ADS_UF_ACCOUNTDISABLE 0 x0002 -Option Constant
#New-Variable ADS_UF_PASSWD_CANT_CHANGE 0 x0040 -Option Constant
#New-Variable ADS_UF_DONT_EXPIRE_PASSWD 0 x10000 -Option Constant
#New-Variable ADS_UF_PASSWD_EXPIRED 0 x800000 -Option Constant

#define our searcher object
$searchroot = ([ADSI] "LDAP://$domain")
$Searcher = New-Object DirectoryServices.DirectorySearcher($SearchRoot) 


# find the user
if ($radiobutton1.checked) {$filter = "(&(objectCategory=person)(objectClass=user)(mail=$samaccountname))"}
if ($radiobutton2.checked) {$filter = "(&(objectCategory=person)(objectClass=user)(sn=$samaccountname))"}
if ($radiobutton3.checked) {$filter = "(&(objectCategory=person)(objectClass=user)(samaccountname=$samaccountname))"}

$searcher.filter = $filter

#get the user information

$user = $searcher.findOne()

if (-not $user.path )
{
	$RichTextBox1.Text = "Could not find $samaccountname"
	return
}

$user | foreach-Object {

	#get password properties from useraccountcontrol field
	if ($_.properties.item("useraccountcontrol")[0] -band $ADS_UF_DONT_EXPIRE_PASSWD)
	{
		$pwdNeverExpires = $True
	}
	else
	{
		$pwdNeverExpires = $False
	}

	#Password expired should be calculated from a computed UAC value
	$user = $_.GetDirectoryEntry()
	$user.psbase.refreshcache("msDS-User-Account-Control-Computed")
	[int]$computed = $user.psbase.properties.item("msDS-User-Account-Control-Computed").value

	if ($computed -band $ADS_UF_PASSWD_EXPIRED)
	{
		$pwdExpired = $True
	}
	else
	{
		$pwdExpired = $False
	}
	#account disabled
	if ($_.properties.item("useraccountcontrol")[0] -band $ADS_UF_ACCOUNTDISABLE)
	{
		$disabled = $True
	}
	else
	{
		$disabled = $False
	}
	#account lockedout
	if ($_.properties.item("lockoutTime")[0])
	{
		$lockedout = $True
	}
	else
	{
		$lockedout = $False
	}
	#check if user can change their password
	if ($_.properties.item("useraccountcontrol")[0] -band $ADS_UF_PASSWD_CANT_CHANGE)
	{
		$pwdChangeAllowed = $False
	}
	else
	{
		$pwdChangeAllowed = $True
	}
	# Collect Property Values and write to results box

	$value = "Name: $($_.properties.item("name")[0])
Description:$($_.properties.item("description")[0])
Email:$($_.properties.item("mail")[0])
AccountCreated:$($_.properties.item("whencreated")[0])
AccountModified:$($_.properties.item("WhenChanged")[0])
LastLogon:$(Get-UTCAge $_.properties.item("lastlogon")[0])
PasswordNeverExpires:$pwdNeverExpires
PasswordChangeAllowed:$pwdChangeAllowed
Lockout:$lockedout
Disabled:$disabled
UserName:$($_.properties.item("samaccountname")[0])
"}

$RichTextBox1.Text = $value

}

function Button2Click( $object ){
	$username = $textbox3.text

	function CreatePassword([int]$length)
{
 
	$specialCharacters = "$@#!"

	$lowerCase = "abcdefghijklmnopqrstuvwxyz"

	$upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

	$numbers = "1234567890"

	$res = ""

	$rnd = New-Object System.Random

	do

	{

		$flag = $rnd.Next(4); 

		if ($flag -eq 0)
		{			$res += $specialCharacters[$rnd.Next($specialCharacters.Length)];

		}
		elseif ($flag -eq 1)

		{			$res += $lowerCase[$rnd.Next($lowerCase.Length)];

		}
		elseif ($flag -eq 2)

		{			$res += $upperCase[$rnd.Next($upperCase.Length)];

		}
		else

		{			$res += $numbers[$rnd.Next($numbers.Length)];

		}

	} while ( 0 -lt $length--)

	return $res

}
$Pwd = CreatePassword 8
$RichTextBox2.Text = "$pwd"
GET-QADUSER $username | Set-QADUser -userPassword "$pwd" 
}

#Set-QADUser -Identity $samaccountname -UserPassword "$pwd"


function Label1Click( $object ){
	$RichTextBox1.Text = get-qaduser -SamAccountName $TextBox1.Text
}

function RadioButton2CheckedChanged( $object ){

}

function RadioButton1CheckedChanged( $object ){

}

function Button4Click( $object ){
	$username = $textbox3.text
	GET-QADUSER $username | enable-QADUser
}

function Button3Click( $object ){
	$username = $textbox3.text
	GET-QADUSER $username | UNLOCK-QADUSER
}

function Label3Click( $object ){

}

function Label2Click( $object ){

}

Main # This call must remain below all other event functions

#endregion
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9WVyGwMMy2YBI2/TozjplTSm
# wQOgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLuik4NvVVEUHPWL
# xv3FYtVpKPItMA0GCSqGSIb3DQEBAQUABIIBALrrvaHCCI2OAdIf79+ZrN8s+Dy8
# saJ6l80LXR4j8NH8W3bAeSuI7ls0X1lC1vrOBgLgOQb+Dxp1KslC/SliJ4PV9Edz
# Kc2bUUvB2ZK9n0VnxJZi0xJnwNpyqBgrAlDr1C/OyzheHKlq3nrepIiB65vipSIW
# KaOlvlrD4Dpq5LJMLiNRdEUEVutMNZT9PK5Ip0jBOhBcAOCCDVZTVpxehPwy1uFE
# M+wnvtQyApOTuLWnLJ+sfMtNTuolI0Ejm7glBC7IBKbNij16KcT0srCVnGhKLO+L
# LOb/dxXUqIRG9hZVOXFlnTWN7Ezx7Lld45HDWEpIzRoXVJYNJ6da1n+QO9Y=
# SIG # End signature block
