<#
.SYNOPSIS
  Author:......Vidrine
  Date:........2012/04/08
.DESCRIPTION
  Script connects to a SQL database and runs a query against the specified table. Depending on table record values, 
  an Active Directory user object will have it's password reset.  Once, the account is reset the SQL record is updated.
  This SQL update is to prevent resetting the user object's password, again, and to store the password for use.
.NOTES
  Requirements:
  .. Microsoft ActiveDirectory cmdlets
  .. Microsoft SQL cmdlets
  
  Additionally:
  The script must be ran as account that has access to the database and access to 'reset passwords' within ActiveDirectory.
#>

##====================================================================================
## Load snapins and modules
##====================================================================================
add-pssnapin SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue
add-pssnapin SqlServerProviderSnapin100 -ErrorAction SilentlyContinue
Import-Module activeDirectory -ErrorAction SilentlyContinue

##====================================================================================
## Variables: SQL Connection
##====================================================================================
$sqlServerInstance = 'SERVER\INSTANCE' # ex. '.\SQLEXPRESS'
$sqlDatabase = 'DatabaseName'
$sqlTable = 'TableName'

##====================================================================================
## Variables: Password Creation/Reset Configuration
##====================================================================================
## File contains a list of 5-character words, 1 per line.
$word = Get-Content "C:\..\5CharacterDictionary.txt"
## List of allowed special characters for use
$special ='!','@','#','$','%','^','&','*','(',')','-','_','+','='
## Length of the random number
$nmbr = 4

##====================================================================================
## Variables: Log
##====================================================================================
$logFile = (Get-Date -Format yyyyMMdd) + '_LogFile.csv'
$logPath = 'C:\..\Logs'
$log = Join-Path -ChildPath $logFile -Path $logPath

##====================================================================================
## Functions
##====================================================================================
function Get-Timestamp {
	Get-Date -Format u
}

function Write-Log {
	param(
		[string] $Path,
		[string] $Value
	)

	$Value | Out-File $Path -Append
}

function Create-Password {
	## Generate random 4 digit integer.
	$NewString = ""
	1..$nmbr | ForEach { $NewString = $NewString + (Get-Random -Minimum 0 -Maximum 9) }

	## Select random 5-character word from wordlist
	$lowerWord = Get-Random $word

	## Normalize the selected word. Convert all to lowerCase and then convert third character to UPPERcase
	$firstLetters = $lowerWord.Substring(0,2)
	$upperLetters = $lowerWord.Substring(2,1).toUpper()
	$lastLetters = $lowerWord.Substring(3,2)
	$NewWord = $firstLetters + $upperLetters + $lastLetters

	## Select random special character from wordlist
	$NewSpecial = Get-Random $special

	## Combine selected word, random number, and special character to generate password
	$NewPassword = ($NewWord + $NewSpecial + $NewString)

	## Returns the newly created random string to the function
	return $NewPassword
}

Function Reset-Password {
	param (
		[string]$emailAddress,
		[string]$password
	)

	## Convert the password to secure string
	$password_secure = ConvertTo-SecureString $password -AsPlainText -Force

	## Query for the user based on email address; Resets the user account password with value from database
	try
	{
		Get-ADUser -Filter {emailAddress -like $emailAddress} | Set-ADAccountPassword -Reset -NewPassword $password_secure
		$Value = (get-timestamp)+"`tSUCCESS`tReset Password`tPassword reset completed for end user ($emailAddress)."
		Write-Log -Path $log -Value $Value
	}
	catch
	{
		$Value = (get-timestamp)+"`tERROR`tReset Password`tUnable to reset password ($emailAddress). $_"
		Write-Log -Path $log -Value $Value
	}
}

function Get-Username {
	param (
		[string]$emailAddress
	)

	try
	{
		$user = Get-ADUser -Filter {emailAddress -like $emailAddress}
		$Value = (get-timestamp)+"`tSUCCESS`tQuery Username`tDirectory lookup for username was successful ($emailAddress)."
		Write-Log -Path $log -Value $Value

		return $user.sAMAccountName
	}
	catch
	{
		$Value = (get-timestamp)+"`tERROR`tQuery Username`tDirectory lookup failed ($emailAddress). $_"
		Write-Log -Path $log -Value $Value
	}
}

function SQL-Select {
	<#
.EXAMPLE
$results = SQL-Select -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -selectWhat '*'
.EXAMPLE
$results = SQL-Select -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -selectWhat '*' -where "id='64'"
#>

	param(
		[string]$server,
		[string]$database,
		[string]$table,
		[string]$selectWhat,
		[string]$where

	)

	## SELECT statement with a WHERE clause
	if ($where){
		$sqlQuery = @"
SELECT $selectWhat 
FROM $table 
WHERE $where
"@
	}

	## General SELECT statement
	else {
		$sqlQuery = @"
SELECT $selectWhat 
FROM $table
"@
	}

	try
	{
		$results = Invoke-SQLcmd -ServerInstance $server -Database $database -Query $sqlQuery
		$Value = (get-timestamp)+"`tSUCCESS`tSQL Select`tDatabase query was successful (WHERE: $where)."
		Write-Log -Path $log -Value $Value

		return $results
	}
	catch
	{
		$Value = (get-timestamp)+"`tERROR`tSQL Select`tDatabase query failed (WHERE: $where). $_"
		Write-Log -Path $log -Value $Value
	}
}

function SQL-Update {
	<#
.EXAMPLE
SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID
#>
	param(
		[string]$server,
		[string]$database,
		[string]$table,
		[string]$dataField,
		[string]$dataValue,
		[string]$updateID
	)

	$sqlQuery = @"
UPDATE $database.$table 
SET $dataField='$dataValue' 
WHERE id=$updateID
"@

	try
	{
		Invoke-SQLcmd -ServerInstance $server -Database $database -Query $sqlQuery
		$Value = (get-timestamp)+"`tSUCCESS`tSQL Update`tUpdated database record, ID $updateID ($dataField > $dataValue)."
		Write-Log -Path $log -Value $Value
	}
	catch
	{
		$Value = (get-timestamp)+"`tERROR`tSQL Update`tUnable to update database record, ID $updateID ($dataField > $dataValue). $_"
		Write-Log -Path $log -Value $Value
	}
}

function Check-Status {
	$results = $NULL
	$results = SQL-Select -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -selectWhat 'id,email,pword,pwordSet,status' -where "(pwordSet IS Null OR pwordSet='') AND status='CheckedIn'"
	$results | ForEach {
		if ($_.pword.GetType().name -eq 'DBNull')
		{
			## Generate a new password for the end-user
			$password = Create-Password

			$sqlDataID = $_.id

			## Configure SQL statement to UPDATE the end-user 'pword'
			$sqlDataField = 'pword'
			$sqlDataValue = $password
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID

			## Reset the end-user's password
			Reset-Password -emailAddress $_.email -password $password

			## Configure SQL statement to UPDATE the end-user 'pwordSet'
			$sqlDataField = 'pwordSet'
			$sqlDataValue = 'Yes'
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID

			## Configure SQL statement to UPDATE the end-user 'samaccountname'
			$sqlDataField = 'samaccountname'
			$sqlDataValue = Get-Username -emailAddress $_.email
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID
		}
		elseif($_.pword -eq '')
		{
			## Generate a new password for the end-user
			$password = Create-Password

			$sqlDataID = $_.id

			## Configure SQL statement to UPDATE the end-user 'pword'
			$sqlDataField = 'pword'
			$sqlDataValue = $password
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID

			## Reset the end-user's password
			Reset-Password -emailAddress $_.email -password $password

			## Configure SQL statement to UPDATE the end-user 'pwordSet'
			$sqlDataField = 'pwordSet'
			$sqlDataValue = 'Yes'
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID

			## Configure SQL statement to UPDATE the end-user 'samaccountname'
			$sqlDataField = 'samaccountname'
			$sqlDataValue = Get-Username -emailAddress $_.email
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID
		}
		else 
		{
			Reset-Password -emailAddress $_.email -password $_.pword

			$sqlDataID = $_.id

			## Configure SQL statement to UPDATE the end-user 'pwordSet'
			$sqlDataField = 'pwordSet'
			$sqlDataValue = 'Yes'
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID

			## Configure SQL statement to UPDATE the end-user 'samaccountname'
			$sqlDataField = 'samaccountname'
			$sqlDataValue = Get-Username -emailAddress $_.email
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID
		}
	}
	return $results
}

##====================================================================================
## Main script begins here
##====================================================================================
Check-Status
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCmRAVwsAfpKTmVosqjLZaWkK
# u/GgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEunDFkZc8kFQ7ay
# wzzI8wBcd64nMA0GCSqGSIb3DQEBAQUABIIBAEscPbwY0ukbBySYsVMmRarXycY8
# O5LYHkkO+fQKRiP9PKjhu3xGFqqJEmGG/bmzDYg4NDKgr6WJ1R6+C7WyF6lintRi
# 0pnyZh+RwAbYztKLS4bAH1H7mqBKhxc0fnrsyrre96+2RuyAyRHwQ4iDJQVg/XF2
# ovUWNf5fObwPWwxiKy24JKm9pQDqknNCbjjPUKwpxjqv8fS22K4gd5rPI/8cefX1
# 7wHyPhr8x0maBUWDCAkAVm+bxDgqL/JTXMtsmysnI+xO9tdpWOP2+bs4U3+8OSrT
# aIeKeS8hpaJdChufgI/ph7J/LOlHrMUzDZF6IDkNzS1NmGUV7gRMUEF+ROg=
# SIG # End signature block
