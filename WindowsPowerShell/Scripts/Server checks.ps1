##Creates variable for filename

$date = (get-date).tostring("yyyy-MM-dd")
$filename = "H:\dailychecks\checks_$date.xls"

## Imports exchange modules

#Import-Module "\\emailserver\c$\PS Modules\vamail.videoarts.info.psm1"

## Start Internet Explorer to check that Video Arts website is up

Start-Process iexplore.exe

## Creates new excel object
$erroractionpreference = "SilentlyContinue"
$a = New-Object -comobject Excel.Application
$a.visible = $True 

##creates workbook and three worksheets. Names three worksheets.
$b = $a.Workbooks.Add()
$c = $b.Worksheets.Item(1)
$d = $b.Worksheets.Item(2)
$e = $b.Worksheets.Item(3)

$b.name = "$title"
$c.name = "Stopped Services"
$d.name = "Free Disk Space"
$e.name = "Server Connectivity"

##Populates cells with the titles

$c.Cells.Item(1,1) = "STOPPED SERVICES"
$c.Cells.Item(2,1) = "Machine Name"
$c.Cells.Item(2,2) = "Service Name"
$c.Cells.Item(2,3) = "State"

$d.Cells.Item(1,1) = "FREE DISK SPACE"
$d.Cells.Item(2,1) = "Machine Name"
$d.Cells.Item(2,2) = "Drive"
$d.Cells.Item(2,3) = "Total size (MB)"
$d.Cells.Item(2,4) = "Free Space (MB)"
$d.Cells.Item(2,5) = "Free Space (%)"

$e.Cells.Item(1,1) = "SERVER CONNECTIVITY"
$e.Cells.Item(2,1) = "Server Name"
$e.Cells.Item(2,2) = "Server Status"


##Changes colours and fonts for header sections populated above 
$c = $c.UsedRange
$c.Interior.ColorIndex = 19
$c.Font.ColorIndex = 11
$c.Font.Bold = $True

$d = $d.UsedRange
$d.Interior.ColorIndex = 19
$d.Font.ColorIndex = 11
$d.Font.Bold = $True

$e = $e.UsedRange
$e.Interior.ColorIndex = 19
$e.Font.ColorIndex = 11
$e.Font.Bold = $True
$e.EntireColumn.AutoFit()


##sets variables for the row in which data will start populating
$servRow = 3
$diskRow = 3
$pingRow = 3

###Create new variable to run connectivity check###

$colservers = Get-Content "C:\dailychecks\Servers.txt"
foreach ($strServer in $colservers)
##Populate computer names in first column
{
	$e.Cells.Item($pingRow, 1) = $strServer.ToUpper()

	## Create new object to ping computers, if they are succesful populate cells with green/success, if anything else then red/offline

	$ping = new-object System.Net.NetworkInformation.Ping
	$Reply = $ping.send($strServer)
	if ($Reply.status -eq "Success")
	{
		$rightcolor = $e.Cells.Item($pingRow, 2)
		$e.Cells.Item($pingRow, 2) = "Online"
		$rightcolor.interior.colorindex = 10
	}
	else
	{

		$wrongcolor = $e.Cells.Item($pingRow, 2)
		$e.Cells.Item($pingRow, 2) = "Offline"
		$wrongcolor.interior.colorindex = 3

	}
	$Reply = ""

	##Set looping variable so that one cell after another populates rather than the same cell getting overwritten
	$pingRow = $pingRow + 1

	##Autofit collumnn
	$e.EntireColumn.AutoFit()
}
##gets each computer
$colComputers = get-content "C:\dailychecks\Servers.txt"
foreach ($strComputer in $colComputers)
{
	##gets each service with startmode 'Auto' and state 'Stopped' for each computer
	$stoppedservices = get-wmiobject Win32_service -computername $strComputer | where{$_.StartMode -eq "Auto" -and $_.State -eq "stopped"} 
	foreach ($objservice in $stoppedservices)

	{
		##Populates cells
		$c.Cells.Item($servRow, 1) = $strComputer.ToUpper()
		$c.Cells.Item($servRow, 2) = $objService.Name
		$c.Cells.Item($servRow, 3) = $objService.State
		$servRow = $servRow + 1
		$c.EntireColumn.AutoFit()
	}

	##Gets disk information for each computer
	$colDisks = get-wmiobject Win32_LogicalDisk -computername $strComputer -Filter "DriveType = 3" 
	foreach ($objdisk in $colDisks)

	{
		##Populates cells
		$d.Cells.Item($diskRow, 1) = $strComputer.ToUpper()
		$d.Cells.Item($diskRow, 2) = $objDisk.DeviceID
		$d.Cells.Item($diskRow, 3) = "{0:N0}" -f ($objDisk.Size/1024 / 1024)
		$d.Cells.Item($diskRow, 4) = "{0:N0}" -f ($objDisk.FreeSpace/1024 / 1024)
		$d.Cells.Item($diskRow, 5) = "{0:P0}" -f ([double]$objDisk.FreeSpace/[double]$objDisk.Size)
		$diskRow = $diskRow + 1
		$d.EntireColumn.AutoFit()
	}


}

##Saves file using Filename variable set at the top of the document

$b.SaveAs($filename, 1)
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+0UelTlEtPQhZcAcZ7wWYpfH
# s1KgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHCLZ8EgGc0McWjl
# 5oDv7bR6bfDtMA0GCSqGSIb3DQEBAQUABIIBAISWkM0mzSkC8HR3D7K0XLnJgYzm
# N/Fwjr98M8OvOGI/AClIwKjGnuRS2j3/qxibfE3z1N67Twj+hJ8eTA1RzT8/d8OB
# f798ARIA11xYiQ6IW9PMDcUvnqgz/4syEz1iSJF1087yqLYKZnz0+xtCpX5Nwc7T
# 2kV/PJrs5PkcNdbozpflgd7XBGufrc+VMyrK9F6YfWhd0XFMbtw9G1ARan8UHce6
# 6zftzVsgsKc8Sd1+VCTrQnoUye4vwyEhKvmZNx6E+jjuCPFGXS8Cr293fL775/DX
# U1LRvAT+Leu5CMSmW4fYNc+z+1sh+s8WoWgWYNlfQL+vDdTutz5k5gAeOjc=
# SIG # End signature block
