param (
[parameter(Mandatory=$true)]
[string]$SiteCode,
[parameter(Mandatory=$true)]
[string]$UpdateGroupName,
[parameter(Mandatory=$true)]
[string]$ImageName,
[parameter(Mandatory=$true)]
[switch]$UpdateDP
)

Function Convert-NormalDateToConfigMgrDate {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$starttime
    )

    [System.Management.ManagementDateTimeconverter]::ToDMTFDateTime($starttime)
}

Function create-ScheduleToken { 

##Create a SMS_ST_NonRecurring object to use as schedule token 
$SMS_ST_NonRecurring = "SMS_ST_NonRecurring"
$class_SMS_ST_NonRecurring = [wmiclass]""
$class_SMS_ST_NonRecurring.psbase.Path ="ROOT\SMS\Site_$($SiteCode):$($SMS_ST_NonRecurring)"

$scheduleToken = $class_SMS_ST_NonRecurring.CreateInstance()   
    if($scheduleToken) 
        {
        $scheduleToken.DayDuration = 0
        $scheduleToken.HourDuration = 0
        $scheduleToken.IsGMT = FALSE
        $scheduleToken.MinuteDuration = 0
        $scheduleToken.StartTime = (Convert-NormalDateToConfigMgrDate $startTime)

        $SMS_ScheduleMethods = "SMS_ScheduleMethods"
        $class_SMS_ScheduleMethods = [wmiclass]""
        $class_SMS_ScheduleMethods.psbase.Path ="ROOT\SMS\Site_$($SiteCode):$($SMS_ScheduleMethods)"
        
        $script:ScheduleString = $class_SMS_ScheduleMethods.WriteToString($scheduleToken)
        
        } 
}##### end function

#### begin function
Function create-ImageServicingSchedule {

$SMS_ImageServicingSchedule = "SMS_ImageServicingSchedule"
$class_SMS_ImageServicingSchedule = [wmiclass]""
$class_SMS_ImageServicingSchedule.psbase.Path ="ROOT\SMS\Site_$($SiteCode):$($SMS_ImageServicingSchedule)"

$SMS_ImageServicingSchedule = $class_SMS_ImageServicingSchedule.CreateInstance()

$SMS_ImageServicingSchedule.Action = 1
$SMS_ImageServicingSchedule.Schedule = "$($ScheduleString.StringData)"
# Update the Distribution Point afterwards?
if ($UpdateDP) {
    $SMS_ImageServicingSchedule.UpdateDP = $true
    }
else {
    $SMS_ImageServicingSchedule.UpdateDP = $false
    }

$schedule = $SMS_ImageServicingSchedule.Put()

$script:scheduleID = $schedule.RelativePath.Split("=")[1]

# apply Schedule to Image
$SMS_ImageServicingScheduledImage = "SMS_ImageServicingScheduledImage"
$class_SMS_ImageServicingScheduledImage = [wmiclass]""
$class_SMS_ImageServicingScheduledImage.psbase.Path ="ROOT\SMS\Site_$($SiteCode):$($SMS_ImageServicingScheduledImage)"

$SMS_ImageServicingScheduledImage = $class_SMS_ImageServicingScheduledImage.CreateInstance()

$SMS_ImageServicingScheduledImage.ImagePackageID = "$($ImagePackageID)"
$SMS_ImageServicingScheduledImage.ScheduleID = $scheduleID
$SMS_ImageServicingScheduledImage.Put() | Out-Null

} ##### end function

#### begin function
Function add-UpdateToOfflineServicingSchedule {

$UpdateGroup = Get-WmiObject -Namespace root\sms\site_$SiteCode -Class SMS_AuthorizationList | where {$_.LocalizedDisplayName -eq "$($UpdateGroupName)"}

#direct reference to the Update Group
$UpdateGroup = [wmi]"$($UpdateGroup.__PATH)"

# get every CI_ID in the Update Group
foreach ($Update in $UpdateGroup.Updates)
    {
       $Update = Get-WmiObject -Namespace root\sms\site_$SiteCode -class SMS_SoftwareUpdate | where {$_.CI_ID -eq "$($Update)"}
       [array]$CIIDs += $Update.CI_ID       
    }


foreach ($CIID in $CIIDs) {
    
    $SMS_ImageServicingScheduledUpdate = "SMS_ImageServicingScheduledUpdate"
    $class_SMS_ImageServicingScheduledUpdate = [wmiclass]""
    $class_SMS_ImageServicingScheduledUpdate.psbase.Path ="ROOT\SMS\Site_$($SiteCode):$($SMS_ImageServicingScheduledUpdate)"

    $SMS_ImageServicingScheduledUpdate = $class_SMS_ImageServicingScheduledUpdate.CreateInstance()

    $SMS_ImageServicingScheduledUpdate.ScheduleID = $scheduleID
    $SMS_ImageServicingScheduledUpdate.UpdateID = $CIID
    $SMS_ImageServicingScheduledUpdate.Put() | Out-Null
    }
} #### end function

#### begin function
Function run-OfflineServicingManager {

$Class = "SMS_ImagePackage"
$Method = "RunOfflineServicingManager"

$WMIClass = [WmiClass]"ROOT\sms\site_$($SiteCode):$Class"


$Props = $WMIClass.psbase.GetMethodParameters($Method)

$Props.PackageID = "$($ImagePackageID)"
$Props.ServerName = "$(([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname)"
$Props.SiteCode = "$($SiteCode)"

$WMIClass.PSBase.InvokeMethod($Method, $Props, $Null) | Out-Null


} #end function

#### begin Function
Function get-ImagePackageID {

$script:ImagePackageID = (Get-WmiObject -Class SMS_ImagePackage -Namespace Root\SMS\site_$SiteCode | where {$_.name -eq "$($Imagename)"}).PackageID

}

############ Main Script starts here!

$schedule = $null
$ScheduleID = $null
[array]$script:CIIDs = @()
$CIID = $null
$ImagePackageID = $null


[datetime]$script:StartTime = Get-Date
get-ImagePackageID
create-ScheduleToken
create-ImageServicingSchedule
add-UpdateToOfflineServicingSchedule
run-OfflineServicingManager

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpdObTbbhxdW+0cL8ZhX6LW04
# 8iqgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFNO0FvLX9QI5DD2b
# c8QpYFkdnNZNMA0GCSqGSIb3DQEBAQUABIIBADBxQ0Os1hA749GkPUkR5mgDnuDM
# yQRjm7vNrA2atxbfwHUPdfQ/Qzs35H9Z3hoPKLlj5ZwC0j6KUmp1EXLx7q0LRKxi
# GulQsql0n06AxW1smBs+fj8TEGaTrNxJoXyfbSuhzZsS460+w+WEiCde5oE6btOJ
# yQ98e3CVaRGGD0Q2BV7MMji/qhAxipy8QMnsyCMlKFW9ZcTxPh0RPOMwkygzL2IH
# /NXI4mfZGsDhmdJ9wzxHCHExfC+voXno2W9cysv6Ezasbu3owOIkveNRx11zwgRj
# qSkI2gwkayKG+RCC5PUlU7UX5JQS2vxEjuu3vsI29Stp6vzcsda1Dbbh1Z0=
# SIG # End signature block
