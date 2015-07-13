#Twitbrain Cheat PowerShell script
#Description: PowerShell script to beat everyone at the Twitter twitbrain game
#             For more info follow @twitbrain at www.twitter.com
#Change the Twitter Username and Password in the script.
#Author: Stefan Stranger
#Website: http://tinyurl.com/sstranger
#Date: 03/07/2009
#Version: 0.1
#Function Publish-Tweet from James O'Neills blog (http://blogs.technet.com/jamesone/archive/2009/02/16/how-to-drive-twitter-or-other-web-tools-with-powershell.aspx)


[System.Reflection.Assembly]::LoadWithPartialName(?System.Web) | Out-Null

Function Publish-Tweet([string] $TweetText)
{
	[System.Net.ServicePointManager]::Expect100Continue = $false
	$request = [System.Net.WebRequest]::Create("http://twitter.com/statuses/update.xml")
	$Username = "username"
	$Password = "password"
	$request.Credentials = new-object System.Net.NetworkCredential($Username, $Password)
	$request.Method = "POST"
	$request.ContentType = "application/x-www-form-urlencoded" 
	write-progress "Tweeting" "Posting status update" -cu $tweetText

	$formdata = [System.Text.Encoding]::UTF8.GetBytes( "status=" + $tweetText )
	$requestStream = $request.GetRequestStream()
	$requestStream.Write($formdata, 0, $formdata.Length)
	$requestStream.Close()
	$response = $request.GetResponse()

	write-host $response.statuscode 
	$reader = new-object System.IO.StreamReader($response.GetResponseStream())
	$reader.ReadToEnd()
	$reader.Close()
}

Function Waiting()
{
 #Change $a if you want to wait longer or shorter
for ($a = 15; $a -gt 1; $a--) 
{
	Write-Progress -Activity "Waiting for next poll" `
	-SecondsRemaining $a -Status "Please wait."
	Start-Sleep 1
}
}

Write-Host "You are going to cheat;-)"
$strResponse = Read-Host "Are you sure you want to continue? (Y/N)"

if ($strResponse -eq 'N')
{
	Write-host "Maybe a good choice. It has to be a fair competition ;-)"
	break
}

#infinite loop
#Quit script by using Ctrl-C
for (;;)
{
	#Retrieve sum from Twitbrain website
	Write-host "Get calculation from Twitbrain website"
	$ws = New-Object net.WebClient

	#Download Twitbrain website
	$html = $ws.DownloadString("http://ajaxorized.com/twitbrain")

	#Save website content to temporarily file.
	$currentdir = [Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath
	$html | Set-Content "$currentdir\Twitbrain.html"

	$twitbrainpage = Get-Content "$currentdir\Twitbrain.html" | out-string

	#Search for calculation string in web page
	$calc = [regex]::match($twitbrainpage,'(?<=\<div class="challenge"\>).+(?=\</div>
			<p class="challenge-answer">)',"singleline").value.trim()

	#search/replace					
	$calc = $calc -replace "\*times\*","*"
	$calc = $calc -replace "\+plus\+","+"
	$calc = $calc -replace "\-minus\-","-"

	#Do the math on the sum
	$result = invoke-expression $calc

	#Create tweet to post to twitter
	$tweet = "@twitbrain " + $result

	#Post to Twitter
	#Check if result has not been posted earlier.
	$oldresult = Get-Content "$currentdir\oldresult.txt"
	if ($result -eq $oldresult)
	{
		write-host "No new Twitbrain question is published yet"
	}
	else 
	{
		Write-host "What is the result of the next question?"
		Write-host $calc
		Publish-Tweet $tweet
		write-host "Tweet publised"
		#Write old result to text file
		$oldresult = $result
		Write-host "Save oldresult to text file"
		$oldresult > "$currentdir\oldresult.txt"
	}

	#Wait 15 seconds
	#Call Waiting Function
	Waiting
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUuS2sKVz9VENtTDsAohqXpJ6K
# s+OgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMJhc+V2eeU+vYNU
# /2EzSUNYG0+8MA0GCSqGSIb3DQEBAQUABIIBAFCJ1ZhLK82m0nHaOSMcV/oAI/Pl
# JlqX+wYSSUTrqJYhOGhHLVkoO/lqQgOR2t4Fmvm1ssDB1vFVSt3rQ73ti4Rm5QZa
# 2OhO7pukM9Z5G1tPriKxgI7QBiFOmTmw6KXiOI2peQzLzdyJoh+b7Oqf/f0lv2Ia
# 7RW5qdA/eaYosLVOEOSzFXW8JOH1HAzz4y4bY9XOszeS9l2nrytxGsbrwfC1+2u6
# tlJ5jC1E7irDCUe/+ZJ065gOQXdPbj7oO/FbBGzhZWIa4B5oqnxvX3TNCkruBsE4
# DZhS7oUypAT5M0vMhlUzBgofldYnRtEOPHlzK6i9x6pMSlOFuYm9zbFXX4E=
# SIG # End signature block
