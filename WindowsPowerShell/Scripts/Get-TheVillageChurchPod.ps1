function Get-TheVillageChurchPodCast {
	<#
	.SYNOPSIS
		Gets The Village Church sermon podcasts.

	.DESCRIPTION
		The Get-TheVillageChurchPodcast function returns objects of all the available sermon podcasts from The Village Church.
		The objects can be filtered by speaker, series, title, or date and optionally downloaded to a specified folder.

	.PARAMETER Speaker
		Specifies the name of the podcast speaker. The wildcard '*' is allowed.

	.PARAMETER Series
		Specifies the series of the podcast. The wildcard '*' is allowed.

	.PARAMETER Title
		Specifies the title of the podcast. The wildcard '*' is allowed.

	.PARAMETER Date
		Specifies the date or date range of the podcast(s).

	.PARAMETER DownloadPath
		Specifies the download folder path to save the podcast files.

	.EXAMPLE
		Get-TheVillageChurchPodcast
		Gets all the available sermon podcasts from The Village Church.

	.EXAMPLE
		Get-TheVillageChurchPodcast -Speaker MattChandler -Series Habakkuk
		Gets all the sermon podcasts where Matt Chandler is the speaker and the series is Habakkuk.
		
	.EXAMPLE
		Get-TheVillageChurchPodcast -Speaker MattChandler -Date 1/1/2003,3/31/2003
		Gets all the sermon podcasts where Matt Chandler is the speaker and the podcasts are in the date ranage 1/1/2003 - 3/31/2003.
		
	.EXAMPLE
		Get-TheVillageChurchPodcast -Speaker MattChandler -Date 1/1/2003,3/31/2003 -DownloadPath C:\temp\TheVillage
		Gets all the sermon podcasts where Matt Chandler is the speaker and the podcasts are in the date ranage 1/1/2003 - 3/31/2003 and
		downloads the podcast files to the folder path C:\temp\TheVillage.

	.INPUTS
		System.String

	.OUTPUTS
		PSObject

	.NOTES
		Name: Get-TheVillageChurchPodCast
		Author: Rich Kusak
		Created: 2011-06-14
		LastEdit: 2011-09-12 11:07
		Version: 1.2.0.0

	.LINK
		http://fm.thevillagechurch.net/sermons

	.LINK
		about_regular_expressions

#>

	[CmdletBinding()]
	param (
		[Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Speaker = '*',

		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Series = '*',

		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Title = '*',

		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateCount(1,2)]
		[datetime[]]$Date = ([datetime]::MinValue,[datetime]::MaxValue),

		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateScript({
				if ($_) {
					if (Test-Path $_ -IsValid) {$true} else {
						throw "The download path '$_' is not valid."
					}
				} else {$true}
			})]
		[string]$DownloadPath
	)

	begin {

		$sermonsUri = 'http://fm.thevillagechurch.net/sermons'
		$studiesSeminarsUri = 'http://fm.thevillagechurch.net/studies-seminars'
		$resourceFilesAudioUri = 'http://fm.thevillagechurch.net/resource_files/audio/'

		$partRegex = "href='/resource_files/audio/(?<file>(?<date>\d{8}).*_(?<speaker>\w+)_(?<series>\w+)Pt(?<part>\d+)-(?<title>\w+)\.mp3)'"
		$noPartRegex = "href='/resource_files/audio/(?<file>(?<date>\d{8}).*_(?<speaker>\w+)_(?<series>\w+)-(?<title>\w+)\.mp3)'"

		$webClient = New-Object System.Net.WebClient
		if ([System.Net.WebProxy]::GetDefaultProxy().Address) {
			$webClient.UseDefaultCredentials = $true
			$webClient.Proxy.Credentials = $webClient.Credentials
		}

	} # begin

	process {

		try {
			Write-Debug "Performing operation 'DownloadString' on target '$sermonsUri'."
			$reference = $webClient.DownloadString($sermonsUri)

			$pages = [regex]::Matches($reference, 'page=(\d+)&') | ForEach {$_.Groups[1].Value} | Sort -Unique
			$pages | ForEach -Begin {$sermons = @()} -Process {
				$sermonsPageUri = "http://fm.thevillagechurch.net/sermons?type=sermons&page=$_&match=any&kw=&topic=&sb=date&sd=desc"
				Write-Debug "Performing operation 'DownloadString' on target '$sermonsPageUri'."
				$sermons += $webClient.DownloadString($sermonsPageUri)
			}
		} catch {
			return Write-Error $_
		}

		$obj = foreach ($line in $sermons -split '(?m)\s*$') {
			if ($line -match $partRegex) {
				New-Object PSObject -Property @{
					'File' = $matches['file']
					'Date' = "{0:####-##-##}" -f [int]$matches['date']
					'Speaker' = $matches['speaker']
					'Series' = $matches['series']
					'Part' = "{0:d2}" -f [int]$matches['part']
					'Title' = $matches['title']
				}

			} elseif ($line -match $noPartRegex) {
				New-Object PSObject -Property @{
					'File' = $matches['file']
					'Date' = "{0:####-##-##}" -f [int]$matches['date']
					'Speaker' = $matches['speaker']
					'Series' = $matches['series']
					'Part' = '00'
					'Title' = $matches['title']
				}
			}
		} # foreach ($line in $sermons -split '(?m)\s*$')

		if ($PSBoundParameters['Date']) {
			switch ($Date.Length) {
				1 {$Date += $Date ; break}
				2 {
					if ($Date[0] -gt $Date[1]) {
						[array]::Reverse($Date)
					}
				}
			} # switch
		} # if ($PSBoundParameters['Date'])

		if ($DownloadPath) {
			try {
				if (-not (Test-Path $DownloadPath -PathType Container)) {
					New-Item $DownloadPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
				}
			} catch {
				return Write-Error $_
			}

			[PSObject[]]$filter = $obj | Where {
				$_.Speaker -like $Speaker -and
				$_.Series -like $Series -and
				(					[datetime]$_.Date -ge $Date[0]) -and ([datetime]$_.Date -le $Date[1])
			}

			$count = $filter.Length
			$i = 0

			foreach ($podcast in $filter) {
				$fullPath = Join-Path $DownloadPath $podcast.File
				if (Test-Path $fullPath) {
					Write-Warning "File '$fullPath' already exists."
					continue
				}

				try {
					Write-Debug "Performing operation 'DownloadFile' on target '$($podcast.File)'."
					Write-Progress -Activity 'Downloading PodCast' -Status $podcast.File -PercentComplete $(($i / $count)*100 ; $i++) -CurrentOperation "$i of $count"
					$webClient.DownloadFile($resourceFilesAudioUri + $podcast.File, $fullPath)
				} catch {
					Write-Error $_
					continue
				}
			} # foreach ($podcast in $filter)

			Write-Progress -Activity 'Downloading PodCast' -Status 'Complete' -PercentComplete 100
			Sleep -Seconds 1

		} else {
			$obj | Where {
				$_.Speaker -like $Speaker -and
				$_.Series -like $Series -and
				$_.Title -like $Title -and
				(					[datetime]$_.Date -ge $Date[0]) -and ([datetime]$_.Date -le $Date[1])
			} | Select Date, Speaker, Series, Part, Title | Sort Date
		}
	} # process
} # function Get-TheVillageChurchPodCast {
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoU8lWhNkKXPrbx/ky5tGCUW6
# CumgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFBYvCjY6FTzJ0Gud
# hSv80seRBP8WMA0GCSqGSIb3DQEBAQUABIIBAJxZY5U5r4vs9RSNZbpRbednNZZ7
# t+T3u6MrLNOGt/UjQJ1KCiCqMffJyi8nypVZquZe2liKXJ8eg4h4DaiP93mHT6X6
# YfV9kpBrn/XYwAhFL5M5VBceoHwQwAmOtlDtdxbLeKDnO7AxoV4bfbYW7fMdJOxM
# EjpCp87a2kzzmsOyqzxkODFhijcbNx56twAgoSoj6w4ruHgflxgbn1siS1oqy6fH
# 7LOyuRWRjiCxB0W2AIC6zM0oWDKBaEcALNC9C+2HTbtumQFs1n+ov9UR6XMxfd0l
# vREPNZ/YBuYzCbcT+dXM7yYx4VnOdyA4ioKkKzv+zcPFwVaSvcsl/EeBuwI=
# SIG # End signature block
