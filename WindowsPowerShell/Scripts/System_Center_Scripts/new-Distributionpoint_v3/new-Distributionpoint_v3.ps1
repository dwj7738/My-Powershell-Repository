Function Set-WMIProperty
{
    PARAM(
        $sdkserver,
        $SiteCode,
        $PropertyName,
        $Value,
        $Value1,
        $Value2
    )

    $embeddedproperty_class = [wmiclass]""
    $embeddedproperty_class.psbase.Path = "\\" + $sdkserver + "\ROOT\SMS\site_" + $SiteCode + ":SMS_EmbeddedProperty"
    $embeddedproperty = $embeddedproperty_class.createInstance()
    
    $embeddedproperty.PropertyName = $PropertyName
    $embeddedproperty.Value = $Value
    $embeddedproperty.Value1 = $Value1
    $embeddedproperty.Value2 = $Value2
    
    return $embeddedproperty
}

Function global:Set-Property(
    $PropertyName,
    $Value,
    $Value1,
    $Value2,
    $roleproperties) 
{
            $embeddedproperty_class 			= [wmiclass]""
			$embeddedproperty_class.psbase.Path = "\\.\ROOT\SMS\Site_PR1:SMS_EmbeddedProperty"
			$embeddedproperty 					= $embeddedproperty_class.createInstance()
                        			
            $embeddedproperty.PropertyName  = $PropertyName
			$embeddedproperty.Value 		= $Value
			$embeddedproperty.Value1		= $Value1 
			$embeddedproperty.Value2		= $Value2
            $global:roleproperties += [System.Management.ManagementBaseObject]$embeddedproperty
	}


$sdkserver = "localhost"
$servername = "XA-DEPLOY.DO.LOCAL"
$sitecode = "PR1"

$scf = Invoke-WmiMethod -Namespace "root\SMS\site_$sitecode" -ComputerName $sdkserver -class "SMS_SiteControlFile" -name "GetSessionHandle"
$refresh = Invoke-WmiMethod -Namespace "root\SMS\site_$sitecode" -ComputerName $sdkserver -class "SMS_SiteControlFile" -name "RefreshSCF" -ArgumentList $sitecode

############### Create Site System ################################################
$global:roleproperties = @()
$global:properties =@()
# connect to SMS Provider for Site 
$role_class = [wmiclass]""
$role_class.psbase.Path ="\\.\ROOT\SMS\Site_PR1:SMS_SCI_SysResUse"
$script:role = $role_class.createInstance()

#create the SMS Site Server
$role.NALPath 	= "[`"Display=\\$servername\`"]MSWNET:[`"SMS_SITE=$sitecode`"]\\$servername\"
$role.NALType 	= "Windows NT Server"
$role.RoleName 	= "SMS SITE SYSTEM"
$role.SiteCode 	= "PR1"

#####
#filling in properties
$IsProtected					= @("IsProtected",1,"","")  # 0 to disable fallback to this site system, 1 to enable 
set-property $IsProtected[0] $IsProtected[1] $IsProtected[2] $IsProtected[3]
$role.Props = $roleproperties
$role.Put()
            
$role_class = [wmiclass]""  
$role_class.psbase.Path = "\\" + $sdkserver + "\ROOT\SMS\site_" + $SiteCode + ":SMS_SCI_SysResUse"

$siterole = $role_class.createInstance()
$siterole.NALPath = "[`"Display=\\$servername\`"]MSWNET:[`"SMS_SITE=$SiteCode`"]\\$servername\"
$siterole.NALType = "Windows NT Server"
$siterole.SiteCode = $SiteCode
$siterole.RoleName = "sms distribution point"

$pxeauth = new-object -comobject Microsoft.ConfigMgr.PXEAuth
$strSubject = [System.Guid]::NewGuid().toString()
$strSMSID = [System.Guid]::NewGuid().toString()
$StartTime = [DateTime]::Now.ToUniversalTime()
$EndTime = $StartTime.AddYears(25)
$ident = $pxeauth.CreateIdentity($strSubject, $strSubject, $strSMSID, $StartTime, $EndTime)

$smssite_class = [wmiclass]""
$smssite_class.psbase.Path = "\\" + $sdkserver + "\ROOT\SMS\site_" + $SiteCode + ":SMS_Site"

$inParams = $smssite_class.GetMethodParameters("SubmitRegistrationRecord")
$inParams["SMSID"] = $strSMSID
$inParams["Certificate"] = $ident[1]
$inParams["CertificatePFX"] = $ident[0]
$inParams["Type"] = 2
$inParams["ServerName"] = $servername
$inParams["UdaSetting"] = '2' 
$inParams["IssuedCert"] = '2' 
$outParams = $smssite_class.InvokeMethod("SubmitRegistrationRecord", $inParams, $null)

$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "IsPXE" -value 1 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "IsActive" -value 1 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "SupportUnknownMachines" -value 1 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "UDASetting" -value 2 -value1 '' -value2 '')

$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "BITS download" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "Server Remote Name" -value 0 -value1 $servername -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "PreStagingAllowed" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "SslState" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "AllowInternetClients" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "IsAnonymousEnabled" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "DPDrive" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "MinFreeSpace" -value 50 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "InstallInternetServer" -value 1 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "RemoveWDS" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "BindPolicy" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "ResponseDelay" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "IdentityGUID" -value 0 -value1 $strSMSID -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "CertificatePFXData" -value 0 -value1 ($ident[0]) -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "CertificateContextData" -value 0 -value1 ($ident[1]) -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "PXEPassword" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "CertificateType" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "CertificateExpirationDate" -value 0 -value1 ([String]$EndTime.ToFileTime()) -value2 '')  
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "CertificateFile" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "DPShareDrive" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "IsMulticast" -value 0 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "DPMonEnabled" -value 1 -value1 '' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "DPMonSchedule" -value 0 -value1 '00011700001F2000' -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "DPMonPriority" -value 4 -value1 '' -value2 '')

$drive = Get-WmiObject Win32_LogicalDisk | where-object {($_.DriveType -eq 3) -and ($_.DeviceID -ne "c:")} | Sort-object $_.FreeSpace -descending
if ($drive -ne $null)
{
    foreach ($dr in $drive)
    { 
        $letterdrive = $dr.DeviceID
        break
    }
}
$letterdrive = $letterdrive -replace ':', ''

$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "AvailableContentLibDrivesList" -value 0 -value1 $letterdrive -value2 '')
$siterole.Props += [System.Management.ManagementBaseObject](Set-WMIProperty -sdkserver $sdkserver -sitecode $sitecode -PropertyName "AvailablePkgShareDrivesList" -value 0 -value1 $letterdrive -value2 '')


$siterole.Put() | Out-Null
$commit = Invoke-WmiMethod -Namespace "root\SMS\site_$sitecode" -ComputerName $sdkserver -class "SMS_SiteControlFile" -name "CommitSCF" $sitecode
$scf = Invoke-WmiMethod -Namespace "root\SMS\site_$sitecode" -ComputerName $sdkserver -class "SMS_SiteControlFile" -name "ReleaseSessionHandle" -ArgumentList $scf.SessionHandle




# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYMM/sCqqMonA4N93nOwVf6hd
# evygggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHOBM9joN9VPtanl
# +kA3jRtyrBqpMA0GCSqGSIb3DQEBAQUABIIBAKhCdg+8EVUiRcrtMAtivT4YEwl5
# GhalOLbhWWEs/i/9rjso7ZYN/qPHyMHX4+SAr4+DvxY2yTnR6/wXCT0mK3mMfKrh
# JRFxryHaQU+k5lFdrBFg7vXDH6uOZBz4yF3IqnxmztlsTSvaCebA9SNVgoaGRQXj
# Lo2A9Y0eVfx8IueXWiUmkPIyWutdTri8EAuf4yMKeWio2syiu9jygK9uIhwX4bG0
# zrv0rYsW9O1xzc2yzW+njJ2gdmfCHqryZ6Ob4XRk0iTBGCPDa81vLuQIDbRJ3GzV
# b5GZ9cJJBPPN09dPZQjtkhSq9XVSN3dMxhiNchYuUPxhrofhkVDbravJdNs=
# SIG # End signature block
