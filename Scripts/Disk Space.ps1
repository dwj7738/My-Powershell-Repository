# Change the following variables based on your environment
$html_file_dir = "C:\PS_Scripts"
$server_file = "C:\PS_Scripts\servers.txt"
$from_address = "myemail@something.com"
$to_address = "whereiwanttosendit@something.com"
$email_gateway = "smtp.something.com" # Can either be DNS name or IP address to SMTP server
# The seventh line from the bottom (line 167) is used if your smtp gateway requires authentication. If you require smtp authentication
# you must uncomment it and set the following variables.
$smtp_user = ""
$smtp_pass = ""

# Change the following variables for the style of the report.
$background_color = "rgb(140,166,193)" # can be in rgb format (rgb(0,0,0)) or hex format (#FFFFFF)
$server_name_font = "Arial"
$server_name_font_size = "20px"
$server_name_bg_color = "rgb(77,108,145)" # can be in rgb format (rgb(0,0,0)) or hex format (#FFFFFF)
$heading_font = "Arial"
$heading_font_size = "14px"
$heading_name_bg_color = "rgb(95,130,169)" # can be in rgb format (rgb(0,0,0)) or hex format (#FFFFFF)
$data_font = "Arial"
$data_font_size = "11px"

# Colors for space
$very_low_space = "rgb(255,0,0)" # very low space equals anything in the MB
$low_space = "rgb(251,251,0)" # low space is less then or equal to 10 GB
$medium_space = "rgb(249,124,0)" # medium space is less then or equal to 100 GB

###########################################################################
#### NO CHANGES SHOULD BE MADE BELOW UNLESS YOU KNOW WHAT YOU ARE DOING
###########################################################################
# Define some variables
$ErrorActionPreference = "SilentlyContinue"
$date = Get-Date -UFormat "%Y%m%d"
$html_file = New-Item -ItemType File -Path "$html_file_dir\DiskSpace_$date.html" -Force
# Create the file
$html_file

# Function to be used to convert bytes to MB or GB or TB
Function ConvertBytes {
	param($size)
	If ($size -lt 1MB) {
		$drive_size = $size / 1KB
		$drive_size = [Math]::Round($drive_size, 2)
		[string]$drive_size + ' KB'
	}elseif ($size -lt 1GB){
		$drive_size = $size / 1MB
		$drive_size = [Math]::Round($drive_size, 2)
		[string]$drive_size + ' MB'
	}ElseIf ($size -lt 1TB){ 
		$drive_size = $size / 1GB
		$drive_size = [Math]::Round($drive_size, 2)
		[string]$drive_size + ' GB'
	}Else{
		$drive_size = $size / 1TB
		$drive_size = [Math]::Round($drive_size, 2)
		[string]$drive_size + ' TB'
	}
}

# Create the header and footer contents of the html page for output
$html_header = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Server Drive Space</title>
<style type="text/css">
.serverName { text-align:center; font-family:"' + $server_name_font + '"; font-size:' + $server_name_font_size + `
	'; font-weight:bold; background-color: ' + $server_name_bg_color + '; border: 1px solid black; width: 150px; }
.headings { text-align:center; font-family:"' + $heading_font + '"; font-size:' + $heading_font_size + `
	'; font-weight:bold; background-color: ' + $heading_name_bg_color + '; border: 1px solid black; width: 150px; }
.data { font-family:"' + $data_font + '"; font-size:' + $data_font_size + '; border: 1px solid black; width: 150px; }
#dataTable { border: 1px solid black; border-collapse:collapse; }
body { background-color: ' + $background_color + '; }
#legend { border: 1px solid black; position:absolute; right:500px; top:10px; }
</style>
<script language="JavaScript" type="text/javascript">
<!--

function zxcWWHS(){
 if (document.all){
	zxcCur=''hand'';
	zxcWH=document.documentElement.clientHeight;
	zxcWW=document.documentElement.clientWidth;
	zxcWS=document.documentElement.scrollTop;
	if (zxcWH==0){
		zxcWS=document.body.scrollTop;
		zxcWH=document.body.clientHeight;
		zxcWW=document.body.clientWidth;
	}
}
else if (document.getElementById){
	zxcCur=''pointer'';
	zxcWH=window.innerHeight-15;
	zxcWW=window.innerWidth-15;
	zxcWS=window.pageYOffset;
}
zxcWC=Math.round(zxcWW/2);
return [zxcWW,zxcWH,zxcWS];
}


window.onscroll=function(){
	var img=document.getElementById(''legend'');
	if (!document.all){ img.style.position=''fixed''; window.onscroll=null; return; }
	if (!img.pos){ img.pos=img.offsetTop; }
	img.style.top=(zxcWWHS()[2]+img.pos)+''px'';
}
//-->
</script>
</head>
<body>'

$html_footer = '</body>
</html>'

# Start to create the reports file
Add-Content $html_file $html_header

# Retrieve the contents of the server.txt file, this file should contain either the
# ip address or the host name of the machine on a single line. Loop through the file
# and get the drive information.
Get-Content $server_file |`
ForEach-Object { 
	# Get the hostname of the machine
	$hostname = Get-WmiObject -Impersonation Impersonate -ComputerName $_ -Query "SELECT Name From Win32_ComputerSystem"
	$name = $hostname.Name.ToUpper()
	Add-Content $html_file ('<Table id="dataTable"><tr><td colspan="3" class="serverName">' + $name + '</td></tr>
		<tr><td class="headings">Drive Letter</td><td class="headings">Total Size</td><td class="headings">Free Space</td></tr>')

	# Get the drives of the server
	$drives = Get-WmiObject Win32_LogicalDisk -Filter "drivetype=3" -ComputerName $_ -Impersonation Impersonate

	# Now that I have all the drives, loop through and add to report
	ForEach ($drive in $drives) {
		$space_color = ""
		$free_space = $drive.FreeSpace
		If ($free_space -le 1073741824) {
			$space_color = $very_low_space
		}elseif ($free_space -le 10737418240) {
			$space_color = $low_space
		}elseif ($free_space -le 107374182400) {
			$space_color = $medium_space
		}

		Add-Content $html_file ('<tr><td class="data">' + $drive.deviceid + '</td><td class="data">' + (ConvertBytes $drive.size) + `
			'</td><td class="data" bgcolor="' + $space_color + '">' + (ConvertBytes $drive.FreeSpace) + '</td></tr>')
	}
	# Close the table
	Add-Content $html_file ('</table></br><div id="legend">
		<Table><tr><td style="font-size:12px">Less then or equal to 1 GB</td><td bgcolor="' + $very_low_space + '" width="10px"></td></tr>
		<tr><td style="font-size:12px">Less then or equal to 10 GB</td><td bgcolor="' + $low_space + '" width="10px"></td></tr>
		<tr><td style="font-size:12px">Less then or equal to 100 GB</td><td bgcolor="' + $medium_space + '" width="10px"></td></tr>
		</table></div>')
}

# End the reports file
Add-Content $html_file $html_footer

# Email the file
$mail = New-Object System.Net.Mail.MailMessage
$att = new-object Net.Mail.Attachment($html_file)
$mail.From = $from_address
$mail.To.Add($to_address)
$mail.Subject = "Server Diskspace $date"
$mail.Body = "The diskspace report file is attached."
$mail.Attachments.Add($att)
$smtp = New-Object System.Net.Mail.SmtpClient($email_gateway)
#$smtp.Credentials = New-Object System.Net.NetworkCredential($smtp_user,$smtp_pass)

$smtp.Send($mail)
$att.Dispose()

# Delete the file
Remove-Item $html_file
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJK4zgK9dr1WSul8Acvf2vLIx
# EFmgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFI0ROHnvftuKnq9u
# +VPcti45Mb4pMA0GCSqGSIb3DQEBAQUABIIBAAkCM1z5yky7j/hST6bomYbQijav
# Y6Ai85Fa6epLheZ7g02TT4OxSdpsf0wEGE8/fQq0iO4Y/0gjv8xJOMgbbHY6DPNz
# JUwAmEfwc9EyEa2wfxfahTTDjFgm64VwK8WgM1428Vx8GY9Ez7iaZ8NyGaM/St+s
# iMOYtvj2FZOmsxYnUNFQ6xZ2wA8NXa3kF0htnUFR6uNIFdxwITwM4W5d3fUL4xIo
# Yq5EvM65tM5xU773oiV09LoZtzAYQ1zEETmbAlzfnHNEGCFv7INP3Wcetpy4p0D6
# P7D3E4E8g/g0H8LCzkJjIIgxn5ylQA6/zrF1oL7jXDqNsnta6fptHl5l4ho=
# SIG # End signature block
