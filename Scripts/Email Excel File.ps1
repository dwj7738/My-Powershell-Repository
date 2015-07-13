### Morning Check of Agent Jobs
### Runs through the servers on       domains but not      domains
### Emails DBAs

$xl = new-object -comobject excel.application
$xl.Visible = $true
$wb = $xl.Workbooks.Add()
$ws = $wb.Worksheets.Item(1)
$date = Get-Date -format f
$Filename = ( get-date ).ToString('ddMMMyyyHHmm')

$cells = $ws.Cells

$cells.item(1,3).font.bold=$True
$cells.item(1,3).font.size=18
$cells.item(1,3)="Back Up Report $date"
$cells.item(5,9)="Last Job Run Older than 1 Day"
$cells.item(5,8).Interior.ColorIndex = 43
$cells.item(4,9)="Last Job Run Older than 7 Days"
$cells.item(4,8).Interior.ColorIndex = 53
$cells.item(7,9)="Successful Job"
$cells.item(7,8).Interior.ColorIndex = 4
$cells.item(8,9)="Failed Job"
$cells.item(8,8).Interior.ColorIndex = 3
$cells.item(9,9)="Job Status Unknown"
$cells.item(9,8).Interior.ColorIndex = 46


#define some variables to control navigation
$row = 3
$col = 2

#insert column headings

$cells.item($row,$col)="Server"
$cells.item($row,$col).font.size=16
$Cells.item($row,$col).Columnwidth = 10
$col++
$cells.item($row,$col)="Job Name"
$cells.item($row,$col).font.size=16
$Cells.item($row,$col).Columnwidth = 40
$col++
$cells.item($row,$col)="Enabled?"
$cells.item($row,$col).font.size=16 
$Cells.item($row,$col).Columnwidth = 15
$col++ 
$cells.item($row,$col)="Outcome"
$cells.item($row,$col).font.size=16
$Cells.item($row,$col).Columnwidth = 12
$col++
$cells.item($row,$col)="Last Run Time"
$cells.item($row,$col).font.size=16 
$Cells.item($row,$col).Columnwidth = 15
$col++


# Load SMO extension
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null;

# Get List of sql servers to check
$sqlservers = Get-Content "c:\sqlservers.txt";

# Loop through each sql server 
foreach($sqlserver in $sqlservers)
{
	# Create an SMO Server object
	$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver;

	# Jobs counts
	$totalJobCount = $srv.JobServer.Jobs.Count;
	$failedCount = 0;
	$successCount = 0;

	# Loop through each job on the server
	foreach($job in $srv.JobServer.Jobs)
	{

		$jobName = $job.Name;
		$jobEnabled = $job.IsEnabled;
		#if($jobEnabled -eq "True")
		#{ $colourenabled = "2"}
		if($jobEnabled -eq "FALSE")
		{			$colourenabled = "2"}
		else {$colourenabled = "48" } 
		$jobLastRunOutcome = $job.LastRunOutcome;
		$Time = $job.LastRunDate ;
		# Set write text to red for Failed jobs
		if($jobLastRunOutcome -eq "Failed")
		{			$colour = "3"}
		# Set write text to grey for Unknown jobs
		Elseif($jobLastRunOutcome -eq "Unknown")
		{			$colour = "46"} 

		else {$Colour ="4"} 
		$row++
		$col = 2
		$cells.item($Row,$col)=$sqlserver
		#$cells.item($Row,$col).Interior.ColorIndex = $colour
		$col++
		$cells.item($Row,$col)=$jobName
		$col++
		$cells.item($Row,$col)=$jobEnabled 
		#Set colour of cell for UnEnabled Jobs to Grey

		$cells.item($Row,$col).Interior.ColorIndex = $colourEnabled
		if ($colourenabled -eq "48") 
		{
			$cells.item($Row ,1 ).Interior.ColorIndex = 48
			$cells.item($Row ,2 ).Interior.ColorIndex = 48
			$cells.item($Row ,3 ).Interior.ColorIndex = 48
			$cells.item($Row ,4 ).Interior.ColorIndex = 48
			$cells.item($Row ,5 ).Interior.ColorIndex = 48
			$cells.item($Row ,6 ).Interior.ColorIndex = 48
			$cells.item($Row ,7 ).Interior.ColorIndex = 48
		} 
		$col++
		$cells.item($Row,$col)="$jobLastRunOutcome"
		$cells.item($Row,$col).Interior.ColorIndex = $colour
		if ($colourenabled -eq "48") 
		{			$cells.item($Row,$col).Interior.ColorIndex = 48}
		$col++
		$cells.item($Row,$col)=$Time 
		If($Time -lt ($(Get-Date).AddDays(-1)))
		{			$cells.item($Row,$col).Interior.ColorIndex = 43}
		If($Time -lt ($(Get-Date).AddDays(-7)))
		{			$cells.item($Row,$col).Interior.ColorIndex = 53} 

	}
	$row++
	$row++
	$ws.rows.item($Row).Interior.ColorIndex = 6
	$row++
	$ws.rows.item($Row).Interior.ColorIndex = 6
	$row++
}


$wb.Saveas("C:\Scripts\ExcelBackups\$filename.xlsx")
$xl.quit()

### Script on XP does not have either of the following lines and works fine
### Tried both
### ps excel | kill
### [System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl)


Send-MailMessage -To "XXXXXX", "XXXX@XXXXX" -Attachment "C:\Scripts\ExcelBackups\$filename.xlsx" -Subject "SQL Jobs Daily Report" ?From "DatabaseBackupAutoEmailer@XXXXXXXX" -SmtpServer "XXXXXX" -Body "Please see attachment for SQL Jobs Report <br><br> Note " ?BodyAsHtml
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUphKaicxfbMyv8VihKsi52bB5
# elWgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKiWHhOaPy+Wchbd
# NmMC0R7oUQEJMA0GCSqGSIb3DQEBAQUABIIBAHXfWtmFOYDetiDxCuXeeSdUETX7
# GovqitTP5+XCsAylvS8CUFK3xkLFDGi275MMy9ZQKY4XXA196w7yHgmgx5Nk+xao
# sWPF7nsGqrHdh/m07wJSYYIDxqhI8yGRbB43At59VN2PNVNZnAC48Lr/Hoja6Mjv
# RIPwWNT0/HAdcx7gAivCPzTNl2bf/Vw9DMX7p/FvscCzXUyjHqm3niczGixM4kFw
# RNnbjCBUoPbn1IrYcA20+1gA41kxzkMpaybCck5niyy+ZQThTSZdjgGTLeYSHlrB
# VTARb1JP2SD+yIRC0hXBXRF6X5KbdpMIUPoHyvFJiIYdNpRprY7ksDNXGss=
# SIG # End signature block
