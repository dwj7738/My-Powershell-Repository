<#
.SYNOPSIS
       The purpose of this script is to test if a user is in a particular role for a SQL server instance.
.DESCRIPTION
       The purpose of this script is to test if a user is in a particular role for a SQL server instance.
       It can be invoked in many different ways.
       Usage: .\Check-SQLServerUserInRole.ps1 [SQLServerName[\Instance]] [Domain\User] [-PrintList] [-And] [role1 [role2...]]

       ServerName defaults to localhost
       User defaults to current user

       Without any roles specified, the script returns an array of the roles the user is in.
       If you specify the -PrintList option, the script will not return anything, but print a complete list of roles and
       highlight the roles the user is in.
       If you specify one or more roles on the command line, the script will True or False depending on whether the user is
       in one of those roles or not. By default it will return TRue if the user is in role1 OR role2 OR role3 etc.
       You can use the -And switch to test for user in role1 AND role2 AND role3 etc.

       Please see the examples for ways to invoke this script.
.EXAMPLE
C:\> .\CheckSQLServerIsInRole.ps1 
List which roles the currently logged in user is in on a SQL server instance running on localhost.

C:\> .\CheckSQLServerIsInRole.ps1 
sysadmin
dbcreator

C:\> $a = .\CheckSQLServerIsInRole.ps1
C:\> $a -is [Array]
True
C:\> $a
sysadmin
dbcreator

.EXAMPLE
C:\> .\Check-SQLServerUserInRole.ps1 -PrintList 
Print a list of all the database roles the scripts checks and highlight the roles the user is in. Nothing is returned.

C:\> .\Check-SQLServerUserInRole.ps1 -PrintList 
[sysadmin] securityadmin serveradmin setupadmin processdmin diskadmin [dbcreator] bulkadmin

.EXAMPLE
C:\> .\Check-SQLServerUserInRole.ps1 somehost contoso\alfonso sysadmin dbcreator
Check if the user contoso\alfonso is in the sysadmin OR the dbcreator role on a SQL server instance running on the host somehost. Returns True or False.

C:\> .\Check-SQLServerUserInRole.ps1 somehost contoso\alfonso sysadmin dbcreator
True

.EXAMPLE
C:\> .\Check-SQLServerUserInRole.ps1 somehost contoso\alfonso -And diskadmin bulkadmin
Check if the user contoso\alfonso is in the sysadmin AND the bulkadmin role on a SQL server instance running on the host somehost. Returns True or False.

C:\> .\Check-SQLServerUserInRole.ps1 somehost contoso\alfonso -a diskadmin bulkadmin
False

.LINK
http://gallery.technet.microsoft.com/ScriptCenter
.NOTES
  File Name : Check-SQLServerUserInRole.ps1
  Author    : Frode Sivertsen

  Please check out the DownloadScripts script for a convenient way to download a collection of useful scripts:
  http://gallery.technet.microsoft.com/scriptcenter/b9fe96c4-9bf1-4d61-903b-5e6c2a65ec66

#>

param
 
(
	[switch]
	# Signifies that the script will print a list of all the roles it is testing for and highlight the roles the user is in.
	# In this case the script is not returning anything, it just prints to the screen
	$PrintList,
	
	[switch]
	# Only makes sense when you provide roles to test for on the command line. By default it will return True
	# if the user is in one of the roles (one OR the other). With this switch it will return true only if the user is in
	# all roles (role1 AND role2 And role3)
	$And,
	
	[string]
	# The SQL server host and instance we are connecting to. E.g: servername[\instance] Default: localhost
	$ServerString = "localhost",
	
	[string]
	# The SQL server login name we are testing for. e.g: domain\user  Default: current user
	$LoginName = "$env:USERDOMAIN\$env:USERNAME"
)

Function PrintRole {
	param([Microsoft.SqlServer.Management.Smo.Login]$login, [string]$role)

	if ( $login ) {

		if ( $login.IsMember($role) ) {
			# Write-Host -NoNewline -ForegroundColor black -BackgroundColor green "[$role]"
			Write-Host -NoNewline "[$role]"
		} else {
			Write-Host -NoNewline -ForegroundColor gray  $role
		}

		Write-Host -NoNewline " "
	}
}

# Load SQL server SMO
 
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null


$roles = "sysadmin", "securityadmin", "serveradmin", "setupadmin", "processdmin", "diskadmin", "dbcreator", "bulkadmin"

try {
	# Create an SMO connection to the instance
	$s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $ServerString

	$s.Logins | Out-Null     # Throws and exception if we cannot connect to the server

	# Check that login exists


	$login = [Microsoft.SqlServer.Management.Smo.Login] $s.Logins["$LoginName"] 

	if ( ! $login ) {
		Throw "The login $LoginName does not appear to be valid."
	}


	if ( $PrintList ) {

		foreach ($role in $roles) {
			PrintRole $login $role
		}

		Write-Host ""
	} elseif ( $args.Length -gt 0 ) {

		$Result = 0

		if ($And) { $Result = 1 }
		
		foreach ($arg in $args) {
			if ( ! ($roles -contains $arg) ) {
				Throw "$arg is not a valid role!"     # TODO: Give hint for how to see valid roles
			}

			if ($And) {
				$Result = $login.IsMember($arg) -and $Result
			} else {
				$Result = $login.IsMember($arg) -or $Result
			}
		}

		Write-Output $Result
		
	} else {
		$myroles = @()

		foreach ($role in $roles) {
		
			if ($login.IsMember($role)) {
				$myroles += $role
			}
		}
		

		Write-Output $myroles
	}
	
}
catch [Exception] {
	Write-Error -Message $_.Exception.Message -Category InvalidArgument
	exit 1
	#write-host $_.Exception.Message; 
}



# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtnSYv4NzzRqKWrd8DRip4uph
# HCSgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKQyOYuIVoPElAPe
# gyNCgo+SOLhrMA0GCSqGSIb3DQEBAQUABIIBADrhKIPYCDKzQShwnM0biAH1NgfC
# 5kSvvxjI9m/7on14Bwkr3cdMXiIweOTEQ/j0fc532Ci68EsX+M+sjFBfqeBklMmG
# FIdiNFa17eutBc8OZDHMN4kOQv2XUiTKET28tLjIyZGxQn//munA3VYatBx4Tw2w
# PID3ect3hEmFffjy7T9sUDeTxG933HDtGiveCa5GQocHeisFUknnlQ1rcLlFaJZc
# RPWvEYfojnRh6xAlyAXWC0+htmQZtY0gfmisn+bWg7fvNvtVhndFgPupNzuhYIDj
# ZU9QBY16mAdlmE9pDrRdXLZJ1AKoNanv2CWr+tiTqjcOhATzBTql8jHCeZA=
# SIG # End signature block
