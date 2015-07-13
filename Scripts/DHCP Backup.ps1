<#
    DHCP Backups Powershell Script
    v1.1
    2012-06-04
    By VulcanX
 
    .SYNOPSIS
        This script will automate the backup of DHCP Databases and copy
        them into a DFS Store at the following link:
        \\domain.com\DHCP
        Each location has a seperate folder and once the backup
        completes a mail sent out if any errors occur.
        ***NB*** : This can only be run in AD Environments where there is 1 DHCP Server per site
    
    .USAGE & REQUIREMENTS
        1. Open Powershell (Start->Run->Powershell.exe) from the DHCP Server
        2. cd %ScriptLocation%
        3. .\DHCPBackup_v1.1
          
    .SCHEDULED TASK CONFIGURATION
        If you have your ExecutionPolicy set to RemoteSigned you will need to run the file with the
        following, to execute it from a UNC Path unless you sign it yourself.
            powershell.exe -ExecutionPolicy Bypass -File "\\domain.com\DHCP\DHCPBackup_v1.1.ps1"
       
     
***RECOVERY***

    Please use the following when recovering a failed DHCP Server/Scope:
    OPTION A:
    netsh dhcp server import "\\domain.com\DHCP\$SiteName\$Date\NetshExport" all
   
    DID NOT WORK IN TESTING!
    OPTION B:
    netsh exec "\\domain.com\DHCP\$SiteName\$Date\Dump.cfg"
       
    First and foremost always try use OPTION A as this will be able to run on any DHCP Server. OPTION B is a last resort
    if OPTION A didnt work.
    ***NB*** : OPTION B can only be run on the same server as what it was dumped from.
       
    .CHANGELOG
       
    v1.1 -  Changed the names in the DHCP DFS Share to reflect the site names
            When selecting which share location, it is based on which site the server is in
            Found a way to run the script from the DFS DHCP repository
            Script now uses dynamic methods allowing it to be more versatile
#>

# Clear Error Variable in case anything carried forward
$Error.Clear()

# Create Temporary DHCP Directory if does not exist
if((Test-Path -Path "C:\DHCPTemp") -ne $true)
{
	New-Item -Verbose "C:\DHCPTemp" -type directory
}

# Clear any stale Backups that may have been created previously
Remove-Item -Path "C:\DHCPTemp\*" -Force -Recurse

# Start logging all the changes to a file in C:\DHCPTemp\LogFile.txt
Start-Transcript -Path "C:\DHCPTemp\LogFile.txt"

# Store the hostname
$Hostname = hostname

# Get Date and Format correctly
$Date = Get-Date -Format yyyy.MM.dd

# Echo Date for the Transcript
$DateTime = Get-Date
Write-Host "Time and Date Script executed:`r`n$DateTime`r`n`r`n"

# Check if ActiveDirectory Module is Imported, if not Import Module for ActiveDirectory
# This also ensures that the server is a DC and will be able to be checked based on Site
$ADModule = Get-Module -ListAvailable | Where {$_.Name -like "ActiveDirectory"} | Select-Object -ExpandProperty Name
if ($ADModule -eq "ActiveDirectory")
{
	Import-Module ActiveDirectory
	Write-Host "Active Directory Module Present and Loaded!`r`n"
}
else
{
	Write-Host "Active Directory Module Not Available.`r`nExiting Script!`r`n"
	Stop-Transcript
	Send-MailMessage -From 'sysadm@domain.com' -To 'sysadm@domain.com' -Subject "DHCP Backup Error - $Hostname" `
	-Body "Good day Sysadm`r`n`r`nThe following DHCP Backup for $Hostname has run on $Date`r`n`r`nNo AD Module Present!`r`n`r`nThank you`r`nSysAdm" -SmtpServer 'smtp.domain.com'
	Exit
}

# Run Netsh Export for the DHCP Server Scopes and Config
Invoke-Command -Scriptblock {netsh dhcp server export "C:\DHCPTemp\NetshExport" all}
Write-Host "NetSh Export Completed!`r`n"

# Run NetSh Dump for the DHCP Server Config
Invoke-Command -Scriptblock {netsh dhcp server dump > "C:\DHCPTemp\Dump.cfg"}
Write-Host "NetSh Dump Completed!`r`n"

# Selecting correct location based on Site Name
$Site = Get-ADDomainController | Select -ExpandProperty Site

# List of the sites available ***NB*** UPDATE LIST IF NEW SITE IS SETUP
$SitesList = "Site1", "Site2", "Site3", "Site4", "Site5", "Site6", "Site6", "Site7"

# Creating the necessary folder to use with the copying of new Export
if($SitesList -contains "$Site")
{
	if((Test-Path -Path "\\domain.com\DHCP\$Site\$Date") -ne $true)
	{
		New-Item "\\domain.com\DHCP\$Site\$Date" -type directory
	}
	Stop-Transcript
	Copy -Force "C:\DHCPTemp\*" "\\domain.com\DHCP\$Site\$Date"
}
# If the Sitename is not detected it will then create a folder using the Hostname
else{
	echo "Site selected is not valid for this Domain Controllers DHCP Backup"
	if((Test-Path -Path "\\domain.com\DHCP\$Hostname\$Date") -ne $true)
	{
		New-Item "\\domain.com\DHCP\$Hostname\$Date" -type directory
	}
	Stop-Transcript
	Copy -Force "C:\DHCPTemp\*" "\\domain.com\DHCP\$Hostname\$Date"
}

# Echo $Error to a File otherwise its unable to be used correctly as an Array/Variable
$CheckErrors = $Error.Count -ne "0"
if ($CheckErrors -eq "True")
{
	echo $Error > "C:\DHCPTemp\Errors.txt"
	$GCError = Get-Content "C:\DHCPTemp\Errors.txt" # Without this there is no way to output the errors in the email correctly
	Send-MailMessage -From 'sysadm@domain.com' -To 'sysadm@domain.com' -Subject "DHCP Backup Error - $Hostname" `
	-Body "Good day Sysadm`r`n`r`nThe following DHCP Backup Failed for $Hostname $Date`r`n`r`n<ERROR>`r`n`r`n$GCError`r`n`r`n</ERROR>`r`n`r`nThank you`r`nSysAdm" -SmtpServer 'smtp.domain.com'
	Exit
}
# If no errors are detected it will proceed and end the powershell session
else
{
	Exit
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhSQzOkgqNJ9HFIoQhjxMtX2O
# VS+gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJn3Ik5BUB64SmBr
# USTU4V25EqNbMA0GCSqGSIb3DQEBAQUABIIBAMHh/A+W4ZgMm273eXNMXXaXTsij
# ibuiDzx5nbW+rHYxH6ubrD/MUkV6QKmL9hYkW6xiBokVzyZb7hfUHXzCb5I2wZmR
# P3DeUP2h3kQaHwWvP+nIv4MtaCFzaLMvMBVv4uqxZmgJQr0prZUe9gRvbpjlMo8y
# jrGpxKBoxkY8+uGPAuWL3g6Er/jb2zF/nAjj9ETgxZol8CHwkxoEj49eXtAIGtrd
# H+LJ4rQwofg3dvQeekQVsbi33wBL3W2f5nuxriakHJPAHnE5H475CkdPmbNEHcBR
# mvNPA3qtA6LJboLD6JZVhMfbhN4NOB8cwn/7m4IdImURmIT2Y6K07jLOrS8=
# SIG # End signature block
