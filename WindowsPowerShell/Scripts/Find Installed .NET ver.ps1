# Svendsen Tech's .Net version finding script.
# See the full documentation at:
# http://www.powershelladmin.com/wiki/Script_for_finding_which_dot_net_versions_are_installed_on_remote_workstations

param([Parameter(Mandatory=$true)][string[]] $ComputerName,
	[switch] $Clobber)

##### START OF FUNCTIONS #####

function ql { $args }

function Quote-And-Comma-Join {

	param([Parameter(Mandatory=$true)][string[]] $Strings)

	# Replace all double quotes in the text with single quotes so the CSV isn't messed up,
	# and remove the trailing newline (all newlines and carriage returns).
	$Strings = $Strings | ForEach-Object { $_ -replace '[\r\n]', '' }
	(		$Strings | ForEach-Object { '"' + ($_ -replace '"', "'") + '"' }) -join ','

}

##### END OF FUNCTIONS #####

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$StartTime = Get-Date
"Script start time: $StartTime"

$Date = (Get-Date).ToString('yyyy-MM-dd')
$OutputOnlineFile = ".\DotNetOnline-${date}.txt"
$OutputOfflineFile = ".\DotNetOffline-${date}.txt"
$CsvOutputFile = ".\DotNet-Versions-${date}.csv"

if (-not $Clobber) {

	$FoundExistingLog = $false

	foreach ($File in $OutputOnlineFile, $OutputOfflineFile, $CsvOutputFile) {

		if (Test-Path -PathType Leaf -Path $File) {

			$FoundExistingLog = $true
			"$File already exists"

		}

	}

	if ($FoundExistingLog -eq $true) {

		$Answer = Read-Host "The above mentioned log file(s) exist. Overwrite? [yes]"

		if ($Answer -imatch '^n') { 'Aborted'; exit 1 }

	}

}

# Deleting existing log files if they exist (assume they can be deleted...)
Remove-Item $OutputOnlineFile -ErrorAction SilentlyContinue
Remove-Item $OutputOfflineFile -ErrorAction SilentlyContinue
Remove-Item $CsvOutputFile -ErrorAction SilentlyContinue

$Counter = 0
$DotNetData = @{}
$DotNetVersionStrings = ql v4\Client v4\Full v3.5 v3.0 v2.0.50727 v1.1.4322
$DotNetRegistryBase = 'SOFTWARE\Microsoft\NET Framework Setup\NDP'

foreach ($Computer in $ComputerName) {

	$Counter++
	$DotNetData.$Computer = New-Object PSObject

	# Skip malformed lines (well, some of them)
	if ($Computer -notmatch '^\S') {

		Write-Host -Fore Red "Skipping malformed item/line ${Counter}: '$Computer'"
		Add-Member -Name Error -Value "Malformed argument ${Counter}: '$Computer'" -MemberType NoteProperty -InputObject $DotNetData.$Computer
		continue

	}

	if (Test-Connection -Quiet -Count 1 $Computer) {

		Write-Host -Fore Green "$Computer is online. Trying to read registry."

		$Computer | Add-Content $OutputOnlineFile

		# Suppress errors when trying to open the remote key
		$ErrorActionPreference = 'SilentlyContinue'
		$Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
		$RegSuccess = $?
		$ErrorActionPreference = 'Stop'

		if ($RegSuccess) {

			Write-Host -Fore Green "Successfully connected to registry of ${Computer}. Trying to open keys."

			foreach ($VerString in $DotNetVersionStrings) {

				if ($RegKey = $Registry.OpenSubKey("$DotNetRegistryBase\$VerString")) {

					#"Successfully opened .NET registry key (SOFTWARE\Microsoft\NET Framework Setup\NDP\$verString)."

					if ($RegKey.GetValue('Install') -eq '1') {

						#"$computer has .NET $verString"
						Add-Member -Name $VerString -Value 'Installed' -MemberType NoteProperty -InputObject $DotNetData.$Computer

					}

					else {

						Add-Member -Name $VerString -Value 'Not installed' -MemberType NoteProperty -InputObject $DotNetData.$Computer

					}

				}

				else {

					Add-Member -Name $VerString -Value 'Not installed (no key)' -MemberType NoteProperty -InputObject $DotNetData.$Computer

				}

			}

		}

		# Error opening remote registry
		else {

			Write-Host -Fore Yellow "${Computer}: Unable to open remote registry key."
			Add-Member -Name Error -Value "Unable to open remote registry: $($Error[0].ToString())" -MemberType NoteProperty -InputObject $DotNetData.$Computer

		}

	}

	# Failed ping test
	else {

		Write-Host -Fore Yellow "${Computer} is offline."
		Add-Member -Name Error -Value "No ping reply" -MemberType NoteProperty -InputObject $DotNetData.$Computer
		$Computer | Add-Content $OutputOfflineFile

	} 

}

$CsvHeaders = @('Computer') + @($DotNetVersionStrings) + @('Error')
$HeaderLine = Quote-And-Comma-Join $CsvHeaders
Add-Content -Path $CsvOutputFile -Value $HeaderLine

# Process the data and output to manually crafted CSV.
$DotNetData.GetEnumerator() | ForEach-Object {

	$Computer = $_.Name

	# I'm building a temporary hashtable with all $CsvHeaders
	$TempData = @{}
	$TempData.'Computer' = $Computer

	# This means there's an "Error" note property.
	if (Get-Member -InputObject $DotNetData.$Computer -MemberType NoteProperty -Name Error) {

		# Add the error to the temp hash.
		$TempData.'Error' = $DotNetData.$Computer.Error

		# Populate the .NET version strings with "Unknown".
		foreach ($VerString in $DotNetVersionStrings) {

			$TempData.$VerString = 'Unknown'

		}


	}

	# No errors. Assume all .NET version fields are populated.
	else {

		# Set the error key in the temp hash to "-"
		$TempData.'Error' = '-'

		foreach ($VerString in $DotNetVersionStrings) {

			$TempData.$VerString = $DotNetData.$Computer.$VerString

		} 

	}

	# Now we should have "complete" $TempData hashes.
	# Manually craft CSV data. Headers were added before the loop.

	# The array is for ordering the output predictably.
	$TempArray = @()

	foreach ($Header in $CsvHeaders) {

		$TempArray += $TempData.$Header

	}

	$CsvLine = Quote-And-Comma-Join $TempArray
	Add-Content -Path $CsvOutputFile -Value $CsvLine

}

@"
Script start time: $StartTime
Script end time:   $(Get-Date)
Output files: $CsvOutputFile, $OutputOnlineFile, $OutputOfflineFile
"@
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUkN4YR1Oje+EeC9PFdh5OQYz0
# qjWgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMR+ZVMmUunCRQ+s
# vSLyRWwfOneCMA0GCSqGSIb3DQEBAQUABIIBAG+xY9UPQXIsB/sGqYr3r7ofhrBP
# x6DVXIg47L9M8XvsZwfNgbKzZ+wWyZw3tRe4n+S0czpsGA5wudfZxcGA2WltRjUA
# KfKT+hoI+Btl1PHnqfI8Kfc6oZNfTV3LxHuM3Keoo9PWH9pyD/dFoHw7t3q3NSYa
# Ev2I1yq7FuA+pUkorrEjQTyxWYiFrGvfNE1Xs5NkCI7/Zzg1Xi8jNDotY9ei9+Z4
# yOMpe7osLKR7UJZkOPfYlH8YoZsP0BQArJtRFCEDfirWnl8rw0VJrr8r145zu8cb
# 27tsJtNdV/bBx5EvOWcWHUjm+y+1eiLtNVVhAAywdwhzYZT1bqbuh23ZNvM=
# SIG # End signature block
