# This powershell script is attached to a job and run at system start-up.
# It registers for SPM events and writes to a specifically created classic
# system event log that captures storage spaces events and information.
#
# Author: Tobias Klima
# Organization: Microsoft
# Last Updated: July 25, 2012
# Code Segments adapted from: Bruce Langworthy, Himanshu Kale

$LogName = "SpaceCommand Events"

# Registers for SPM Events, specifically: Arrival, Departure, Alert, and Modification.
function Register-SPMEvent
(
    [switch]$RegisterArrival,
    [switch]$RegisterDeparture,
    [switch]$RegisterAlert,
    [switch]$RegisterModification
)
{
    $SPMNamespace = "root\microsoft\windows\storage"
    if($RegisterArrival)
    {
       register-wmievent -namespace $SPMNamespace -class MSFT_StorageArrivalEvent -SourceIdentifier SPMArrival
       Write-Host "Arrival Registration Complete" -ForegroundColor Yellow
    }
    if($RegisterDeparture)
    {
       register-wmievent -namespace $SPMNamespace -class MSFT_StorageDepartureEvent -SourceIdentifier SPMDeparture
       Write-Host "Departure Registration Complete" -ForegroundColor Yellow
    }
    if($RegisterAlert)
    {
       register-wmievent -namespace $SPMNamespace -class MSFT_StorageAlertEvent -SourceIdentifier SPMAlert
       Write-Host "Alert Registration Complete" -ForegroundColor Yellow
    }
    if($RegisterModification)
    {
       register-wmievent -namespace $SPMNamespace -class MSFT_StorageModificationEvent -SourceIdentifier SPMModification
       Write-Host "Modification Registration Complete" -ForegroundColor Yellow
    }
}

# Returns all events in the queue
function Get-SPMEvent
(
    [switch]$SPMArrival,
    [switch]$SPMDeparture,
    [switch]$SPMAlert,
    [switch]$SPMModification
)
{
        if($SPMArrival)
        {
           return Get-Event -SourceIdentifier SPMArrival -ErrorAction SilentlyContinue
        }

        if($SPMDeparture)
        {
           return Get-Event -SourceIdentifier SPMDeparture -ErrorAction SilentlyContinue
        }

        if($SPMAlert)
        {
           return Get-Event -SourceIdentifier SPMAlert -ErrorAction SilentlyContinue
        }

        if($SPMModification)
        {
           return Get-Event -SourceIdentifier SPMModification -ErrorAction SilentlyContinue
        }
}

# Checks for the presence of pool, space or physical disk in the SourceClass field and constructs a corresponding message
function Create-Message
(
    $Event
)
{
    # Create a standard Message
    $Message = "Event Class: " + $Event.__Class + "`r" + "Affected Resource: " + $Event.SourceClassName + "`r" + "Resource ObjectId: " + $Event.SourceObjectId

    $ID = "`"" + $Event.SourceObjectId + "`""

    if($Event.SourceClassName -eq "MSFT_StoragePool")
    {
        $Resource = Get-StoragePool | ? {$_.ObjectId -eq $Event.SourceObjectId}
        $Message += "`r" + "Storage Pool Friendly Name: "     + $Resource.FriendlyName
        $Message += "`r" + "Storage Pool HealthStatus: "      + $Resource.HealthStatus
        $Message += "`r" + "Storage Pool OperationalStatus: " + $Resource.OperationalStatus

        return $Message
    }
    elseif($Event.SourceClassName -eq "MSFT_VirtualDisk")
    {
        $Resource = Get-VirtualDisk | ? {$_.ObjectId -eq $Event.SourceObjectId}
        $Message += "`r" + "Storage Space Friendly Name: "     + $Resource.FriendlyName
        $Message += "`r" + "Storage Space HealthStatus: "      + $Resource.HealthStatus
        $Message += "`r" + "Storage Space OperationalStatus: " + $Resource.OperationalStatus

        return $Message
    }
    elseif($Event.SourceClassName -eq "MSFT_PhysicalDisk")
    {
        $Resource = Get-PhysicalDisk | ? {$_.ObjectId -eq $Event.SourceObjectId}
        $Message += "`r" + "Physical Disk Friendly Name: "     + $Resource.FriendlyName
        $Message += "`r" + "Physical Disk HealthStatus: "      + $Resource.HealthStatus
        $Message += "`r" + "Physical Disk OperationalStatus: " + $Resource.OperationalStatus
        $Message += "`r" + "Note: A physical disk's ObjectID may change upon addition or removal from a storage pool."

        return $Message
    }
    else
    {
        return $Message
    }
}

# Register for SPM events
Register-SPMEvent -RegisterArrival
Register-SPMEvent -RegisterDeparture
Register-SPMEvent -RegisterAlert
Register-SPMEvent -RegisterModification

# Periodically check for SPM events and write them to the log if new events exist.
while($true)
{
    # Update the "Daily" Job Trigger to run again in half an hour
    Get-ScheduledJob -Name "SpaceCommand Event Monitor" | Get-JobTrigger -TriggerId 2 | Set-JobTrigger -Daily -At (Get-Date).AddMinutes(30)

    $Arrival = Get-SPMEvent -SPMArrival
    $Departure = Get-SPMEvent -SPMDeparture
    $Alert = Get-SPMEvent -SPMAlert
    $Modification = Get-SPMEvent -SPMModification

    # Get the most recent arrival events
    if($Arrival.count -gt 0)
    {
        # Get the arrival time of the most recent arrival event
        $RecentArrival = $Arrival | ? {$_.TimeGenerated -gt $TimeStamp}

        if($RecentArrival.count -gt 0)
        {
            # Loop through the events returned and write them to the log
            foreach($Event in $RecentArrival)
            {
                $Identifier = $Event.EventIdentifier

                # Convert to NewEvent
                $Event = $Event | % {$_.SourceEventArgs.NewEvent}

                # Create a Message
                $Message = Create-Message -Event $Event

                Write-EventLog -LogName $LogName -Source "SpaceCommand Events" -EventId 1 -ComputerName $Event.__Server -Message $Message
            }
        }
    }
    
    if($Departure.count -gt 0)
    {
        # Get the departure time of the most recent departure event
        $RecentDeparture = $Departure | ? {$_.TimeGenerated -gt $TimeStamp}

        if($RecentDeparture.count -gt 0)
        {
            # Loop through the events returned and write them to the log
            foreach($Event in $RecentDeparture)
            {
                $Identifier = $Event.EventIdentifier

                # Convert to NewEvent
                 $Event = $Event | % {$_.SourceEventArgs.NewEvent}

                # Create a Message
                $Message = Create-Message -Event $Event

                Write-EventLog -LogName $LogName -Source "SpaceCommand Events" -EventId 2 -ComputerName $Event.__Server -Message $Message
            }
        }
    }

    if($Alert.count -gt 0)
    {
        # Get the Alert time of the most recent Alert event
        $RecentAlert = $Alert | ? {$_.TimeGenerated -gt $TimeStamp}

        if($RecentAlert.count -gt 0)
        {
            # Loop through the events returned and write them to the log
            foreach($Event in $RecentAlert)
            {
                $Identifier = $Event.EventIdentifier

                # Convert to NewEvent
                $Event = $Event | % {$_.SourceEventArgs.NewEvent}

                # Create a Message
                $Message = Create-Message -Event $Event

                Write-EventLog -LogName $LogName -Source "SpaceCommand Events" -EventId 3 -ComputerName $Event.__Server -Message $Message
            }
        }
    }

    if($Modification.count -gt 0)
    {
        # Get the Modification time of the most recent modification event
        $RecentModification = $Modification | ? {$_.TimeGenerated -gt $TimeStamp}

        if($RecentModification.count -gt 0)
        {
            # Loop through the events returned and write them to the log
            foreach($Event in $RecentModification)
            {
                $Identifier = $Event.EventIdentifier

                # Convert to NewEvent
                $Event = $Event | % {$_.SourceEventArgs.NewEvent}

                # Create a Message
                $Message = Create-Message -Event $Event

                Write-EventLog -LogName $LogName -Source "SpaceCommand Events" -EventId 4 -ComputerName $Event.__Server -Message $Message
            }
        }
    }

    $TimeStamp = Get-Date

    sleep 60
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU00Nmgo0zYwONrbijaz4RJrX6
# DdSgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLM9IYjNSoNroDSb
# 1XfZvaxATlktMA0GCSqGSIb3DQEBAQUABIIBAGDK6X15R8Por9sDCQp5KEIiTU9L
# URFW6pH8yjRgeURqk7hmnQ0nrzhrKCG9wblI9lIg7GP5vz26+/JxSIVh3TYzjAlr
# e5sKYuNr61FdJ+D/gcgDyx1FytQZD48irecKXD1VWS9X7TpmfUYHW3wDs7h/Jm+Y
# nLJsZXq2cF+THwWAR64Guh2eTeaF/em0vcLC8Eth3MoEXP8PsjSGKdTl+6dcom2F
# s0xfyFkP+EK/7H8HvHEAq9JfVMTE7XfDhRuoMX/tF39v+jYGardU4cATsg7wU1c8
# /NjHY3OiR31/U7C57vb5ns91c4PRwEq6gSHI1ez63bT7kwLX8z8NWzqSUeI=
# SIG # End signature block
