$wid = "1200"
$bord = "2"
$colour ="BLUE"
$Fcolour = "White"


"<table width=$wid border=$bord>" | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<tr> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<td BGCOLOR=$colour><font color=$Fcolour> <b>Server</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<td BGCOLOR=$colour><font color=$Fcolour> <b>StorageGroupName</b> </td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<td BGCOLOR=$colour><font color=$Fcolour><b>LastFullBackup</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<td BGCOLOR=$colour><font color=$Fcolour><b>LastIncrementalBackup</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"<td BGCOLOR=$colour><font color=$Fcolour><b>BackupInProgess</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
"</tr> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append


Get-MailboxDatabase | where {$_.Recovery -eq $False } | Select-Object -Property Server, StorageGroupName, Name , LastFullBackup, LastIncrementalBackup, BackupInProgess | Export-csv Backuptatus.csv


foreach($line in $csv)
{
	$MailboxStats = Get-MailboxStatistics $Line.Alias | Select TotalItemSize,Itemcount,LastLogoffTime,LastLogonTime
	$L = "{0:N0}" -f $mailboxstats.totalitemsize.value.toMB()
	$Size = ""
	$Len = $L.Split(',')
	for ($i = 0; $i -lt $Len.length; $i++)
	{
		$Size = $Size +$Len[$i] 
	}
	$temp = $Line.PrimarysmtpAddress
	$adobjroot = [adsi]''
	$objdisabsearcher = New-Object System.DirectoryServices.DirectorySearcher($adobjroot)
	$objdisabsearcher.filter = "(&(objectCategory=Person)(objectClass=user)(mail= $Temp)(userAccountControl:1.2.840.113556.1.4.803:=2))"
	$resultdisabaccn = $objdisabsearcher.findone() | select path


	"<tr> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour> <b> $Line.Server </b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour><b>$Line.StorageGroupName</b> </td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour><b>$Line.Name</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour><b>$line.LastFullBackup</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour><b>$Line.LastIncrementalBackup</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"<td BGCOLOR=$colour><font size=2 color=$Fcolour><b>$Line.BackupInProgess</b></td> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
	"</tr> " | out-file -filePath "C:\Powershell\BackupDetails.txt" -append
}


$smtpServer = ?hutserver? 
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer) 
$msg.From = ?FromAddress?
$msg.To.Add(?ToAddress?)
$sub = Date
$msg.Subject = "Exchange Database Backup Status Report  " + $sub

$msg.IsBodyHTML = $true





$UserList = Get-Content "C:\Powershell\BackupDetails.txt"

$body = ""

foreach($user in $UserList) 
{
	$body = $body + $user + "`n"

}

$msg.Body = $body

$smtp.Send($msg)
Exit
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8To1FQG8H9GtBKuFus08jOn+
# TbygggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCeHXeOQIb8cYHaH
# oZtPz3c8iBHtMA0GCSqGSIb3DQEBAQUABIIBADG+Fg1s22ZDme6UhjT+lYzVCgRw
# 5ofZgoO6WsRow6wjEmTl59AS9CofuaPGOyzor1pAc2uC0fLlMK+Co8LZrIGevAwB
# BBxNw18AD/uCeHbSMU/cxSk7LjAvgjWi8/bxiDM/zcNKOsFL5XZRApAL7ZlruCbM
# 2Yx8Mgj+YvY2VJlVpGQbUQhrcdWLlUMczUPKuvdkqAuwSg/WPNmAIV2jhx9XRAVd
# l3XgXsSltgMAuxJv0h5pd1xa22fH4jQInyx1Y+7NAeVq/KSMlrBUW/wl4ivXPuGh
# JP5pmdMTtObxsIoy5RCKIP+QGTNNMBcRVAO9fyHsLqUdJDRjLh+KcmeCrjo=
# SIG # End signature block
