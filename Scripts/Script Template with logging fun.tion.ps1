#*******************************************************************
# Global Variables
#*******************************************************************
$Script:Version = '1.0.9.1126'
$Script:LogSeparator = '*******************************************************************************'
$Script:LogFile = ""

#*******************************************************************
# Functions
#*******************************************************************
function Get-ScriptName(){
#
# .SYNOPSIS
# 	     Extracts the script name
# 	 .DESCRIPTION
# 	     Extracts the script file name without extention
# 	 .NOTES
#		 Author:    Axel Kara, axel.kara@gmx.de
#
$tmp = $MyInvocation.ScriptName.Substring($MyInvocation.ScriptName.LastIndexOf('\') + 1)
$tmp.Substring(0,$tmp.Length - 4)
}

function Write-Log($Msg, [System.Boolean]$LogTime = $true){
	#
	# 	 .SYNOPSIS
	# 	     Creates a log entry
	# 	 .DESCRIPTION
	# 	     By default a time stamp will be logged too. This can be
	#        disabled with the -LogTime $false parameter
	# 	 .NOTES
	#		 Author:    Axel Kara, axel.kara@gmx.de
	# 	 .EXAMPLE
	# 	     Write-Log -Msg 'Log entry created successfull.' [-LogTime $false]
	#
	if($LogTime){
		$date = Get-Date -format dd.MM.yyyy
		$time = Get-Date -format HH:mm:ss
		Add-Content -Path $LogFile -Value ($date + " " + $time + "   " + $Msg)
	}
	else{
		Add-Content -Path $LogFile -Value $Msg
	}
}

function Initialize-LogFile($File, [System.Boolean]$reset = $false){
	#
	# 	 .SYNOPSIS
	# 	     Initializes the log file
	# 	 .DESCRIPTION
	#		 Creates the log file header
	# 	     Creates the folder structure on local drives if necessary
	#        Resets existing log if used with -reset $true
	# 	 .NOTES
	#		 Author:    Axel Kara, axel.kara@gmx.de
	# 	 .EXAMPLE
	# 	     Initialize-LogFile -File 'C:\Logging\events.log' [-reset $true]
	#
	try{
		#Check if file exists
		if(Test-Path -Path $File){
			#Check if file should be reset
			if($reset){
				Clear-Content $File -ErrorAction SilentlyContinue
			}
		}
		else{
			#Check if file is a local file
			if($File.Substring(1,1) -eq ':'){
				#Check if drive exists
				$driveInfo = [System.IO.DriveInfo]($File)
				if($driveInfo.IsReady -eq $false){
					Write-Log -Msg ($driveInfo.Name + " not ready.")
				}

				#Create folder structure if necessary
				$Dir = [System.IO.Path]::GetDirectoryName($File)
				if(([System.IO.Directory]::Exists($Dir)) -eq $false){
					$objDir = [System.IO.Directory]::CreateDirectory($Dir)
					Write-Log -Msg ($Dir + " created.")
				}
			}
		}
		#Write header
		Write-Log -LogTime $false -Msg $LogSeparator
		Write-Log -LogTime $false -Msg (((Get-ScriptName).PadRight($LogSeparator.Length - ("   Version " + $Version).Length," ")) + "   Version " + $Version)
		Write-Log -LogTime $false -Msg $LogSeparator
	}
	catch{
		Write-Log -Msg $_
	}
}

function Read-Arguments($Values = $args) {
	#
	# 	 .SYNOPSIS
	# 	     Reads named script arguments
	# 	 .DESCRIPTION
	# 	     Reads named script arguments separated by '=' and tagged with'-' character
	# 	 .NOTES
	#		 Author:    Axel Kara, axel.kara@gmx.de
	#
	foreach($value in $Values){

		#Change the character that separates the arguments here
		$arrTmp = $value.Split("=")

		switch ($arrTmp[0].ToLower()) {
			-log {
				$Script:LogFile = $arrTmp[1]
			}
		}
	}
}

#*******************************************************************
# Main Script
#*******************************************************************
if($args.Count -ne 0){
	#Read script arguments
	Read-Arguments
	if($LogFile.StartsWith("\\")){
		Write-Host "UNC"
	}
	elseif($LogFile.Substring(1,1) -eq ":"){
		Write-Host "Local"
	}
	else{
		$LogFile = [System.IO.Path]::Combine((Get-Location), $LogFile)
	}

	if($LogFile.EndsWith(".log") -eq $false){
		$LogFile += ".log"
	}
}

if($LogFile -eq ""){
	#Set log file
	$LogFile = [System.IO.Path]::Combine((Get-Location), (Get-ScriptName) + ".log")
}

#Write log header
Initialize-LogFile -File $LogFile -reset $false



#///////////////////////////////////
#/// Enter your script code here ///
#///////////////////////////////////


#Write log footer
Write-Log -LogTime $false -Msg $LogSeparator
Write-Log -LogTime $false -Msg ''
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVZt/ZPRuKe/oRFcrDB4c4rMn
# YVOgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFF4gl2+lOTgB+dvU
# ojiDWZe0T2b7MA0GCSqGSIb3DQEBAQUABIIBAMTAVT70F1AuCC/SpPdDsd63z/tH
# KXm6GS/dD2hz42ZlsT3wPEF8WY4H5LSvhTC42o8/KEIxTpVn9xg751KjaSeQQh8X
# dJwYmn4GCRgmR5k4clTuq4oQyso+e0YYSPtT1RT9qrFx4+vfVaV364CgWFwDqtZl
# h5Wjvn/1JtQi/CsIfCGmOjIjTYbNisYQOK45EE75v9Im+Btsy1HrwcwgfB9ScQMH
# 48oT0VHtk/4nlxFn6QUWs1lidS7WPTwb1P4m4IJQ7O/aOl8AmnPMSEHhweNj9ITP
# CFYV2viw8lZfs7O6xtiR6d/bMmqahdBSIzip37wBRreAKTXgl/BuugxUXvU=
# SIG # End signature block
