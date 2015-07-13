[CmdletBinding()]
param (
[string]$SiteCode,
[string]$NewSUPServerName,
[string]$MPServer,
[string]$DBServerName,
[string]$DBServerInstance,
[string]$WSUSContentPath
)

Function Set-Property
{
    PARAM(
        $MPServer,
        $SiteCode,
        $PropertyName,
        $Value,
        $Value1,
        $Value2
    )

    $embeddedproperty_class = [wmiclass]""
    $embeddedproperty_class.psbase.Path = "\\$($MPServer)\ROOT\SMS\Site_$($SiteCode):SMS_EmbeddedProperty"
    $embeddedproperty = $embeddedproperty_class.createInstance()
    
    $embeddedproperty.PropertyName = $PropertyName
    $embeddedproperty.Value = $Value
    $embeddedproperty.Value1 = $Value1
    $embeddedproperty.Value2 = $Value2
    
    return $embeddedproperty
}

Function new-SUP {
############### Create Site System ################################################

#CM12 built-in cmdlets need to run in x86 powershell, that's why it's called directly from here via another script
C:\windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -file ".\new-sitesystem.ps1" -SiteCode $SiteCode -MPServer $MPServer -NewSUPServerName $NewSUPServerName

# connect to SMS Provider for Site
$role_class             = [wmiclass]""
$role_class.psbase.Path = "\\$($MPServer)\ROOT\SMS\Site_$($SiteCode):SMS_SCI_SysResUse"
$role                     = $role_class.createInstance()
#create the SMS Distribution Point Role
$role.NALPath     = "[`"Display=\\$NewSUPServerName\`"]MSWNET:[`"SMS_SITE=$SiteCode`"]\\$NewSUPServerName\"
$role.NALType     = "Windows NT Server"
$role.RoleName     = "SMS Software Update Point"
$role.SiteCode     = "$($SiteCode)"



$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "UseProxy" -value 0 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "ProxyName" -value 0 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "ProxyServerPort" -value 80 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "AnonymousProxyAccess" -value 1 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "UserName" -value 0 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "UseProxyForADR" -value 0 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "IsIntranet" -value 1 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "Enabled" -value 1 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "DBServerName" -value 0 -value1 '' -value2 '$($DBServerName\$DBServerInstance)')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "NLBVIP" -value 0 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "WSUSIISPort" -value 8530 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "WSUSIISSSLPort" -value 8531 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "SSLWSUS" -value 0 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "UseParentWSUS" -value 0 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "WSUSAccessAccount" -value 0 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "IsINF" -value 0 -value1 '' -value2 '')
$role.Props += [System.Management.ManagementBaseObject](Set-Property -MPServer $MPServer -sitecode $sitecode -PropertyName "PublicVIP" -value 0 -value1 '' -value2 '')

$role.Put()

}

Function Install-WSUS { 

if (-not (Get-WindowsFeature -Name UpdateServices).Installed -eq $true)
    {
        Install-WindowsFeature -Name UpdateServices-DB, UpdateServices-Ui -IncludeManagementTools -LogPath C:\Windows\System32\LogFiles\WSUSInstall.log
        $command = ". `"$env:ProgramFiles\Update Services\Tools\WsusUtil.exe`" PostInstall SQL_INSTANCE_NAME=$DBServerName\$DBServerInstance CONTENT_DIR=$WSUSContentPath"
        Invoke-Expression -Command $command 
        Write-Host "WSUS installed and configured"
    }
else
    {
        Write-Host "WSUS is already installed and configured"

    }

}

######################### Main script starts here ###################

Install-WSUS


$SiteControlFile = Invoke-WmiMethod -Namespace "root\SMS\site_$SiteCode" -class "SMS_SiteControlFile" -name "GetSessionHandle" -ComputerName $MPServer
Invoke-WmiMethod -Namespace "root\SMS\site_$SiteCode" -class "SMS_SiteControlFile" -name "RefreshSCF" -ArgumentList $SiteCode -ComputerName $MPServer | Out-Null
new-SUP 
Invoke-WmiMethod -Namespace "root\SMS\site_$SiteCode" -class "SMS_SiteControlFile" -name "CommitSCF" $SiteCode -ComputerName $MPServer | Out-Null
$SiteControlFile = Invoke-WmiMethod -Namespace "root\SMS\site_$SiteCode" -class "SMS_SiteControlFile" -name "ReleaseSessionHandle" -ArgumentList $SiteControlFile.SessionHandle -ComputerName $MPServer
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0l68pRK05p6DEWfR5zUAFdGU
# KIugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLBY59Mhvy67QUOx
# Ns8uTJbXSMCQMA0GCSqGSIb3DQEBAQUABIIBADFicgFQSMPwU1tjEGquq3SSUXHy
# EUnXk/Q+S4QrQJOMqR0GIB0PTvByNqaMovZyyEYYDF5I/jsYhm57eb35G+/JA7pE
# FA3aawrvBaVq2MPpXimW3RNCrJ0d5os9RNlm/5jUp+nwrZnqF3yEwOUkru6A6f5U
# MGoIsDucQsadpfEIQIgfxI06cnI4DMJbfw9kvb2H4dFThLjxLFNPY507De8xei2b
# JjgHs5bazZM8TWz9Nv0tpB5G0RNnMswScWEAwEZ4Gfov7Xrg6PPtTEJIJCmoGGIT
# jt78bgr0xTvIeICXKHQI7D5DvJUBRSThTRwFxpaRdSUfGZplmdj503utJyw=
# SIG # End signature block
