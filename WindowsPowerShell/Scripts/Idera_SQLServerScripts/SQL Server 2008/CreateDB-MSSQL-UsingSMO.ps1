## =====================================================================
## Title       : CreateDB-MSSQL-UsingSMO
## Description : Create and empty database, drop if existing
## Author      : Idera
## Date        : 1/28/2009
## Input       : -server <server\instance>
##               -dbName <database name>
##               -verbose 
##               -debug	
## Output      : Formatted table with database name and creation date
## Usage			: PS> .\CreateDB-MSSQL-UsingSMO -server MyServer -dbName SMOTestDB -verbose -debug
## Notes			: Adapted from Allen White script
## Tag			: SQL Server, SMO, Create database
## Change Log  : Revised SMO Assemblies
##   5/11/2011   Added this line -> $database.LogFiles.Add($dblfile) before Create
## =====================================================================
 
param
(
  	[string]$server = "(local)",
	[string]$dbName = "SMOTestDB",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	CreateDB-MSSQL-UsingSMO $server $dbName 
}

function CreateDB-MSSQL-UsingSMO($server, $dbName)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}
	
	# Load-SMO assemblies
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Management.Common" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoExtended " );
	
	# Get a server object for the server instance
	Write-Debug "Creating SMO Server object for $server"
	$NamedInstance = New-Object -typeName Microsoft.SqlServer.Management.Smo.Server `
		-argumentList $server
	
	cls
	
	# Connect to the server with Windows Authentication and drop database if exist
	# TIP: using PowerShell "not equal" operator
	if ($NamedInstance.Databases[$dbName] -ne $null) 
	{
		Write-Debug "The test database already exists on $DefaultServer"
		Write-Debug "Deleting it now..."
		$NamedInstance.Databases[$dbName].Drop()
	}
	
	# Instantiate a database object
	Write-Debug "Createing SMO server, database and filegroup objects..."
	$namedInstance = new-object -typename Microsoft.SqlServer.Management.Smo.Server `
		-argumentlist $server
	$database = new-object -typename Microsoft.SqlServer.Management.Smo.Database `
		-argumentlist $namedInstance, $dbName
	$filegroup = new-object -typename Microsoft.SqlServer.Management.Smo.FileGroup `
		-argumentlist $database, "PRIMARY"

	# Add the PRIMARY filegroup to the database
	$database.FileGroups.Add($filegroup)
	
	# Instantiate the data file object and add it to the PRIMARY filegroup
	$dbfile = $dbName + "_Data"
	$dbdfile = new-object ('Microsoft.SqlServer.Management.Smo.DataFile') ($filegroup, $dbfile)
	$filegroup.Files.Add($dbdfile)
	
	Write-Debug "Set properties of the data and log file"
	
	#Set the properties of the data file
	$masterDBPath = $namedInstance.Information.MasterDBPath
	$dbdfile.FileName = $masterDBPath + "\" + $dbfile + ".mdf"
	$dbdfile.Size = [double](25.0 * 1024.0)
	$dbdfile.GrowthType = "Percent"
	$dbdfile.Growth = 25.0
	$dbdfile.MaxSize = [double](100.0 * 1024.0)
	
	#Instantiate the log file object and set its properties
	$masterDBLogPath = $namedInstance.Information.MasterDBLogPath
	$logfile = $dbName + "_Log"
	$dblfile = new-object ('Microsoft.SqlServer.Management.Smo.LogFile') ($database, $logfile)
	$dblfile.FileName = $masterDBLogPath + "\" + $logfile + ".ldf"
	$dblfile.Size = [double](10.0 * 1024.0)
	$dblfile.GrowthType = "Percent"
	$dblfile.Growth = 25.0
	$database.LogFiles.Add($dblfile)

	# Create the new database on the server
	$Database.Create()
	
	# List the database on the server that was just added to confirm that it was added
	# TIP: using PowerShell to pipe an object list to a Where-Object filtering on a variable
	#      and then building a formated table with properties as output to the console
	$NamedInstance.Databases | Where-Object {$_.name -eq "$dbName"} | Format-Table -property name, createdate
}

main


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURWH1pE9IBft6/8FkP1EmcAzV
# 91ugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFD46nWwJPvmeqQmc
# uJRQ03UdWdjRMA0GCSqGSIb3DQEBAQUABIIBAMjdx+SrIvgJNbk1M3MSH/EBu1Oh
# gtsYIOWyrZ7eSkod4LGjU9nyOazZWXiGJV0UZ38GdzNtwUXkZHqIQ7Tb8Wln9qPA
# RBRcmnaE/GZa7Xw/vywzEX8Us1TWFKs297X2Q5MPGODm1cDFDKT/Zy9MPNRjgzEu
# zo1/hQggwQWMcXMiaXns71vfByDEZmDPQPbCLcRCqmtGAOdqY05BRB1Q5CtZl0IF
# B21bBuGdZJhtdOYBkxAgASREWfy66OIAB6RF7tVx2B9z0r9Um0t4Ap7wG2Ls7wtV
# LZMHzYAbvP139Utby9zZXEBLoPMbSDUpvq14NUeHx+xV88lu3Vsm9THKdoU=
# SIG # End signature block
