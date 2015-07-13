param (
[string]$SiteCode,
[string]$FilePath
)

$CollSettings = ""
[array]$CollIDs = @()

Function Convert-NormalDateToConfigMgrDate {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$starttime
    )

    return [System.Management.ManagementDateTimeconverter]::ToDateTime($starttime)
}

Function Read-ScheduleToken {

$SMS_ScheduleMethods = "SMS_ScheduleMethods"
$class_SMS_ScheduleMethods = [wmiclass]""
$class_SMS_ScheduleMethods.psbase.Path ="ROOT\SMS\Site_$($SiteCode):$($SMS_ScheduleMethods)"
        
$script:ScheduleString = $class_SMS_ScheduleMethods.ReadFromString($ServiceWindow.ServiceWindowSchedules)
return $ScheduleString
}

############### Main script starts here ######################

#Collecting all collections with Maintenance windows configured
$Collections = Get-WmiObject -Class SMS_Collection -Namespace root\SMS\Site_$($SiteCode) | Where-Object {$_.ServiceWindowsCount -gt 0}

#get the collection IDs of these collections
foreach ($Collection in $Collections)
    {
        $CollIDs += $Collection.CollectionID

    }

#get the maintenance window information
foreach ($CollectionID in $CollIDs)
    {   

        $CollName = (Get-WmiObject -Class SMS_Collection -Namespace root\sms\Site_$($SiteCode) | Where-Object {$_.CollectionID -eq "$($CollectionID)"}).Name
        "Working on Collection $($CollName)" | Out-File -FilePath $FilePath -Append
        "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\" | Out-File -FilePath $FilePath -Append
        $CollSettings = Get-WmiObject -class sms_collectionsettings -Namespace root\sms\site_$($SiteCode) | Where-Object {$_.CollectionID -eq "$($CollectionID)"}
        
        $CollSettings = [wmi]$CollSettings.__PATH
        
        #$CollSettings.Get() | Out-Null
        
        $ServiceWindows = $($CollSettings.ServiceWindows)
        
        $ServiceWindows = [wmi]$ServiceWindows.__PATH
               
        foreach ($ServiceWindow in $ServiceWindows)
            {
                
                $ScheduleString = Read-ScheduleToken
                
                "Working on maintenance window $($ServiceWindow.Name)" | Out-File -FilePath $FilePath -Append
                #$ServiceWindow.Description
                #$starttime = (Convert-NormalDateToConfigMgrDate $ScheduleString.TokenData.starttime)
                
                switch ($ServiceWindow.ServiceWindowType)
                    {
                        0 {"This is a Task Sequence maintenance window" | Out-File -FilePath $FilePath -Append}
                        1 {"This is a general maintenance window" | Out-File -FilePath $FilePath -Append}                        
                    }   
                switch ($ServiceWindow.RecurrenceType)
                    {
                        1 {"This maintenance window occurs only once on $($startTime) and lasts for $($ScheduleString.TokenData.HourDuration) hour(s) and $($ScheduleString.TokenData.MinuteDuration) minute(s)." | Out-File -FilePath $FilePath -Append}
                        2 
                            {
                                if ($ScheduleString.TokenData.DaySpan -eq "1")
                                    {
                                        $daily = "daily"
                                    }
                                else
                                    {
                                        $daily = "every $($ScheduleString.TokenData.DaySpan) days"
                                    }
                        
                                "This maintenance window occurs $($daily)." | Out-File -FilePath $FilePath -Append
                            }
                        3 
                            {
                                switch ($ScheduleString.TokenData.Day)
                                    {
                                        1 {$weekday = "Sunday"}
                                        2 {$weekday = "Monday"}
                                        3 {$weekday = "Tuesday"}
                                        4 {$weekday = "Wednesday"}
                                        5 {$weekday = "Thursday"}
                                        6 {$weekday = "Friday"}
                                        7 {$weekday = "Saturday"}
                                    }
                                
                                "This maintenance window occurs every $($ScheduleString.TokenData.ForNumberofWeeks) week(s) on $($weekday) and lasts $($ScheduleString.TokenData.HourDuration) hour(s) and $($ScheduleString.TokenData.MinuteDuration) minute(s) starting on $($startTime)." | Out-File -FilePath $FilePath -Append}
                        4 
                            {
                                switch ($ScheduleString.TokenData.Day)
                                    {
                                        1 {$weekday = "Sunday"}
                                        2 {$weekday = "Monday"}
                                        3 {$weekday = "Tuesday"}
                                        4 {$weekday = "Wednesday"}
                                        5 {$weekday = "Thursday"}
                                        6 {$weekday = "Friday"}
                                        7 {$weekday = "Saturday"}
                                    }
                                switch ($ScheduleString.TokenData.weekorder)
                                    {
                                        0 {$order = "last"}
                                        1 {$order = "first"}
                                        2 {$order = "second"}
                                        3 {$order = "third"}
                                        4 {$order = "fourth"}
                                    }
                                
                                "This maintenance window occurs every $($ScheduleString.TokenData.ForNumberofMonths) month(s) on every $($order) $($weekday)" | Out-File -FilePath $FilePath -Append
                            }

                        5 
                            {
                                if ($ScheduleString.TokenData.MonthDay -eq "0")
                                    { 
                                        $DayOfMonth = "the last day of the month"
                                    }
                                else
                                    {
                                        $DayOfMonth = "day $($ScheduleString.TokenData.MonthDay)"
                                    }
                                "This maintenance window occurs every $($ScheduleString.TokenData.ForNumberofMonths) month(s) on $($DayOfMonth)." | Out-File -FilePath $FilePath -Append                                                  
                                "It lasts $($ScheduleString.TokenData.HourDuration) hours and $($ScheduleString.TokenData.MinuteDuration) minutes." | Out-File -FilePath $FilePath -Append
                            }

                    }
                switch ($ServiceWindow.IsEnabled)
                    {
                        true {"The maintenance window is enabled" | Out-File -FilePath $FilePath -Append}
                        false {"The maintenance window is disabled" | Out-File -FilePath $FilePath -Append}
                    }
                "Going to next Maintenance window" | Out-File -FilePath $FilePath -Append
                "---------------------------------------------" | Out-File -FilePath $FilePath -Append
            }
        "No more maintenance windows present on this collection. Going to next collection." | Out-File -FilePath $FilePath -Append
        "###############################################" | Out-File -FilePath $FilePath -Append
    }
"No more maintenance windows present. Exiting documentation script"  | Out-File -FilePath $FilePath -Append
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULMUqM/H9j5dpx3NzDSt2hG4I
# rhKgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFA3RvHmBjV1mMhz
# /ONYp8DYBVy3MA0GCSqGSIb3DQEBAQUABIIBAAzY/t7ocF/n8S31NiZ5RF8oZOjm
# Zh2pldOuIjP0Jq39xBhaWG81VP3D9p0HOOYF6aqzNcF8Aucx/MZ1fcSzj9u3SLmE
# Q0OVIm7byi4NqUVR7mdvHolaShl4VTDDMtnM770tJk8QbB3VaeraXz8776hwGCKo
# H76kXjFoWj7z4MWvFsnpbwiQ2vm4L51LgYTVwbgruTyhoI6PswRTGVoTPMFsxKRN
# AHqrBIFr+x8SDcZC79zDELogBI0G1+2wXsbO6amQ9X6sizw3Uye8mRxeAbFmT6z8
# Hn+mKgUUvsMtrttVtLHIgyTL1ox0ujt8UgMwBwYIvN43aI78TqP/Jukm7J8=
# SIG # End signature block
