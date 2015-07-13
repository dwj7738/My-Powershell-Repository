param
(
	[string]$domain = "<default domainName>"
)

## ==================================================================================
## Title       : Find All Servers in a Domain With SQL
## Description : Get a listing of all servers in a domain, test the connection
##               then check the registry for MS SQL Server Info.
##				 Output(ServerName, InstanceName, Version and Edition).
##				 Assumes that instances of MS SQL Server can be found under:
##				 HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names
## Author      : C.Perry
## Date        : 10/2/2012
## Input       : -domain <fully.qualified.domainname>	
## Output      : List of SQL Server names
## Usage	   : PS> . FindAllServersWithSQL.ps1 -domain dev.construction.enet
## Notes	   :
## Tag		   : SQL Server, test-connection, ping, AD, WMI
## Change log  :
## ==================================================================================
# INITIALIZATION SECTION
cls

# Domain context
#$domain = $null
#$domain="<domainName>"

# Initialize variables and files
$dom = $null
$ErrorActionPreference = "Continue"
$found = $null
$InstNameskey = "SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names"
$RegInstNameKey = $null
$MSSQLkey = "SOFTWARE\Microsoft\Microsoft SQL Server"
$notfound = $null
#Output file goes into directory you execute from
$outfile = "$domain" + "_Servers_out.csv" 
$reg = $null
$regInstance = $null
$regInstanceData = $null
$regKey = $null
$root = $null
$SetupVersionKey = $null
$SQLServerkey = $null
$sbky = $null
$sub = $null
$type = [Microsoft.Win32.RegistryHive]::LocalMachine
"Server, Instance, Version, Edition" | Out-File $outfile
# Domain Initalization
# create the domain context object
$context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$domain)
# get the domain object
$dom = [system.directoryservices.activedirectory.domain]::GetDomain($context)
# Debug line #$dom 
# go to the root of the Domain
$root = $dom.GetDirectoryEntry()
#create the AD Directory Searcher object
$searcher = new-object System.DirectoryServices.DirectorySearcher($root)
#filter for all servers that do not start with "wde"
$filter = "(&(objectClass=Computer)(operatingSystem=Windows Server*) (!cn=wde*))"
$searcher.filter = $filter
# By default, an Active Directory search returns only 1000 items.
# If your domain includes 1001 items, then that last item will not be returned.
# The way to get around that issue is to assign a value to the PageSize property. 
# When you do that, your search script will return (in this case) the first 1,000 items, 
# pause for a split second, then return the next 1,000. 
# This process will continue until all the items meeting the search criteria have been returned.
$searcher.pageSize=1000
$colProplist = "name"
foreach ($j in $colPropList){$searcher.PropertiesToLoad.Add($j)}
# get all matching computers
$colResults = $searcher.FindAll()

# PROCESS Section
# interate through all found servers
foreach ($objResult in $colResults)
{	#Begin ForEach
	$objItem = $objResult.Properties
	[string]$Server = $objItem.name
	Try
	{
		IF (test-connection -computername $Server -count 1 -TimeToLive 4 -erroraction continue -quiet)
		{			#IfConnectionFound   	
			$found = $Server + " is pingable"
			#echo $found
			$InstanceNameskey = "SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names"
			$MSSQLkey = "SOFTWARE\Microsoft\Microsoft SQL Server"
			$type = [Microsoft.Win32.RegistryHive]::LocalMachine
			$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Server)
			$SQLServerkey = $null
			$SQLServerkey = $regKey.OpenSubKey($MSSQLkey)
			# Check to see if MS SQL Server is installed
			IF ($SQLServerkey)
			{				#Begin IF $SQLSERVERKEY	
				#DEBUG Write to Host "Sub Keys"
				#Write-Host
				#Write-Host "Sub Keys for $MSSQLkey"
				#Write-Host "--------"
				#Foreach($sbky in $SQLServerkey.GetSubKeyNames()){$sbky}
				$Instkey = $null
				$Instkey = $regKey.OpenSubKey($InstanceNameskey)
				# Check to see in chargeable Instances of MS SQL Server are installed
				IF ($Instkey)
				{
					#DEBUG Write-Host "Values" of SubKeys
					#Write-Host
					#Write-Host "Sub Keys for $InstanceNameskey"
					#Write-Host "------"
					#Foreach($sub in $Instkey.GetSubKeyNames()){$sub}
					foreach ($regInstance in $Instkey.GetSubKeyNames()) 
					{
						$RegInstNameKey = $null
						$SetupKey = $null
						$SetupKey = "$InstanceNameskey\$regInstance"
						$RegInstNameKey = $regKey.OpenSubKey($SetupKey)
						#Open Instance Names Key and get all SQL Instances
						foreach ($SetupInstance in $RegInstNameKey.GetValueNames()) 
						{
							$version = $null 
							$edition = $null
							$regInstanceData = $null
							$SetupVersionKey = $null
							$VersionInfo = $null
							$versionKey = $null
							$regInstanceData = $RegInstNameKey.GetValue($SetupInstance) 
							$SetupVersionKey = "$MSSQLkey\$regInstanceData\Setup"
							#Open the SQL Instance Setup Key and get the version and edition
							$versionKey = $regKey.OpenSubKey($SetupVersionKey)
							$version = $versionKey.GetValue('PatchLevel') 
							$edition = $versionKey.GetValue('Edition') 
							# Write the version and edition info to output file
							$VersionInfo = $Server + ',' + $regInstanceData + ',' + $version + ',' + $edition 
							$versionInfo | Out-File $outfile -Append 
						}#end foreach $SetupInstance
					}#end foreach $regInstance
				}#end If $instKey
				ELSE
				{					#Begin No Instance Found
					$found = $found + " but no chargable instance found."
					echo $found
				}#End No Instance Found
			}#end If $SQLServerKey
		}#end If Connectionfound
		ELSE
		{			#ELSE Connection Not Found
			$notfound = $Server + " not pingable"
			echo $notfound
		}
	}#endTry
	Catch
	{
		$exceptionType = $_.Exception.GetType()
		if ($exceptionType -match 'System.Management.Automation.MethodInvocation')
		{			#IfExc
			#Attempt to access an non existant computer
			$Wha = $Server + " - " +$_.Exception.Message
			write-host -backgroundcolor red -foregroundcolor Black $Wha 
		}#endIfExc
		if ($exceptionType -match 'System.UnauthorizedAccessException')
		{			#IfEx
			$UnauthorizedExceptionType = $Server + " Access denied - insufficent privileges"
			# write-host "Exception: $exceptionType"
			write-host -backgroundcolor red "UnauthorizedException: $UnauthorizedExceptionType"
		}#endIfEx
		if ($exceptionType -match 'System.Management.Automation.RuntimeException')
		{			#IfExc
			# Attempt to access an non existant array, output is suppressed
			write-host -backgroundcolor cyan -foregroundcolor black "$Server - A runtime exception occured: " $_.Exception.Message; 
		}#endIfExc
	}#end Catch
}#end ForEach servers in domain
#number of servers
$colResults.count
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4McipEjDJBc9wwmZ8Nb4IPYu
# 9P+gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLjMdiQ0Kc20pfv3
# ojGtaJQedaMZMA0GCSqGSIb3DQEBAQUABIIBAFgXERWwQ5PWlE9mJhe9FpDdVSId
# a3ejJfryi23xJvkBu3qF23mZ8K1US/sURjS3WhEo5rA5KUDWCM/BDHBijT0p7i7Q
# JJbCHjdyLrrv8oWHd/rfVhlTs5EeI6i6eNNyfTTEsoJ/bM6gXccKvfXnrYxl5yZu
# NImLZ+xqFJwFReZI5GQWrizWpJyZLH+y0tYWiozHsTkQAA2jeAOcqAfowALUpGsp
# /dVyYHtiS5X4u055CnIoBx4ARyZgSDUVqg6Z5DboTdOGutUp6aqlhOiAJht8roQ6
# hBbv8wF5cNlS+WZeJS973Cvx1gliXOYULX3xfCYKJnkpJf+lU+vmLXj4fnk=
# SIG # End signature block
