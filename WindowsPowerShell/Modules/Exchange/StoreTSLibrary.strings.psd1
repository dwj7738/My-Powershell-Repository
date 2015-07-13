ConvertFrom-StringData @'
###PSLOC
# Event Log strings
    DatabaseSpaceTroubleShooterStarted=The database space troubleshooter started on volume %1 for database %2.
    DatabaseSpaceTroubleShooterFoundLowSpace=The database space troubleshooter finished on volume %1 for database %2. The database is over the expected threshold. Users were quarantined to avoid running out of space. \nEDB free space (drive space + free space): %3 GB \nPercent EDB free space (drive space + free space): %4% \nLog drive free space: %5 GB \nPercent Log drive free space: %6% \nEDB Free space threshold: %7% \nLog Free space threshold: %8% \nHour threshold: %9 Hrs \nGrowth rate threshold: %10 B/Hr \nInitial growth rate: %11 B/Hr \nFinal growth rate: %12 B/Hr \nNumber of users quarantined: %13 \nPercent EdbFreeSpaceCriticalThreshold: %14% \nPercent EdbFreeSpaceAlertThreshold: %15% \nQuarantine: %16
    DatabaseSpaceTroubleShooterFoundLowSpaceNoQuarantine=The database space troubleshooter finished on volume %1 for database %2. The database is over the expected threshold, but is not growing at an unusual rate. No quarantine action was taken. \nEDB free space (drive space + free space): %3 GB \nPercent EDB free space (drive space + free space): %4% \nLog drive free space: %5 GB \nPercent Log drive free space: %6% \nEDB Free space threshold: %7% \nLog Free space threshold: %8% \nHour threshold: %9 Hrs \nGrowth rate threshold: %10 B/Hr \nInitial growth rate: %11 B/Hr \nFinal growth rate: %12 B/Hr \nPercent EdbFreeSpaceCriticalThreshold: %13% \nPercent EdbFreeSpaceAlertThreshold: %14% \nQuarantine: %15
    DatabaseSpaceTroubleShooterFinishedInsufficient=The database space troubleshooter finished on volume %1 for database %2. The database is over the expected threshold and continues to grow. Manual intervention is required. \nEDB free space (drive space + free space): %3 GB \nPercent EDB free space (drive space + free space): %4% \nLog drive free space: %5 GB \nPercent Log drive free space: %6% \nEDB Free space threshold: %7% \nLog Free space threshold: %8% \nHour threshold: %9 Hrs \nGrowth rate threshold: %10 B/Hr \nInitial growth rate: %11 B/Hr \nFinal growth rate: %12 B/Hr \nNumber of users quarantined: %13 \nPercent EdbFreeSpaceCriticalThreshold: %14% \nPercent EdbFreeSpaceAlertThreshold: %15% \nQuarantine: %16
    DatabaseSpaceTroubleShooterNoProblemDetected=The database space troubleshooter finished on volume %1 for database %2. No problems were detected. \nEDB free space (drive space + free space): %3 GB \nPercent EDB free space (drive space + free space): %4% \nLog drive free space: %5 GB \nPercent Log drive free space: %6% \nEDB free space threshold: %7% \nLog free space threshold: %8% \nHour threshold: %9 hrs \nCurrent growth rate: %10 B/hr \nPercent EdbFreeSpaceCriticalThreshold: %11% \nPercent EdbFreeSpaceAlertThreshold: %12% \nQuarantine: %13
    DatabaseSpaceTroubleShooterQuarantineUser=The database space troubleshooter quarantined mailbox %1 in database %2.
    DatabaseSpaceTroubleDetectedAlertSpaceIssue=The database space troubleshooter detected a low space condition on volume %1 for database %2. Provisioning for this database has been disabled. Database is under %3% free space.
    DatabaseSpaceTroubleDetectedCriticalSpaceIssue=The database space troubleshooter has detected a critically low space condition on volume %1 for database %2. Provisioning for this database has been disabled. The database has less than %3% free space.    
    DatabaseSpaceTroubleDetectedWarningSpaceIssue=The database space troubleshooter detected a low space condition on volume %1 for database %2. Provisioning for this database has been disabled. Database is under %3% free space.

    DatabaseLatencyTroubleShooterStarted=The database latency troubleshooter started on database %1.
    DatabaseLatencyTroubleShooterNoLatency=The database latency troubleshooter detected that the current latency of %1 ms for database %2 is within the threshold of %3 ms.
    DatabaseLatencyTroubleShooterLowOps=The database latency troubleshooter detected that the current latency for database %1 appears high, but the current load on the database is too low for this metric to be meaningful. \n\nCurrent latency: %2 ms. (Usual threshold is %3 ms.) \nCurrent load: %4 operations per second. (Minimum load for meaningful latency: %5 ops/sec.)
    DatabaseLatencyTroubleShooterBadDiskLatencies=The database latency troubleshooter detected that disk latencies are abnormal for database %1. You need to replace the disk. \nRead Latency: %2 \nRead Rate: %3 \nRPC Average Latency: %4
    DatabaseLatencyTroubleShooterBadDSAccessActiveCallCount=The database latency troubleshooter detected that the DSAccess Active Call Count is abnormal for database %1. This may be due to an Active Directory problem. \nDSAccess Average Latency: %2 \nDSAccess Active Calls: %3 \nRPC Average Latency: %4
    DatabaseLatencyTroubleShooterBadDSAccessAverageLatency=The database latency troubleshooter detected that the DSAccess Average Latency is abnormal for database %1. This may be due to an Active Directory problem. \nDSAccess Average Latency: %2 \nDSAccess Active Calls: %3 \nRPC Average Latency: %4
    DatabaseLatencyTroubleShooterQuarantineUser=The database latency troubleshooter quarantined user %1 on database %2 due to unusual activity in the mailbox. If the problem persists, manual intervention will be required. \nAverage time in server: %3 \nRPC Average Latency: %4 \nRPC Operations per second: %5
    DatabaseLatencyTroubleShooterNoQuarantine=The database latency troubleshooter identified a problem with user %1 on database %2 due to unusual activity in the mailbox. No quarantine has been performed since the Quarantine parameter wasn't specified. If the problem persists, manual intervention is required. \nAverage time in server: %3 \nRPC Average Latency: %4 \nRPC Operations per second: %5
    DatabaseLatencyTroubleShooterIneffective=The database latency troubleshooter detected high RPC Average latencies for database %1 but was unable to determine a cause. Manual intervention is required. \nRPC Average Latency: %2 \nRPC Operations per second: %3
    DatabaseLatencyTroubleShooterUniqueMailbox=The database latency troubleshooter detected high RPC Average latencies for database %1 and found a unique mailbox to be the cause. \nRPC Average Latency: %2 \nAverageTimeInServer: %3 \nMailbox: %4
    DatabaseLatencyTroubleShooterNoMailbox=The database latency troubleshooter detected high RPC Average latencies for database %1 but found insufficient mailboxes impacted. \nRPC Average Latency: %2
    DatabaseLatencyTroubleShooterNotRunDatabase=The database latency troubleshooter was not able to complete for database %1. \nReason: %2
    DatabaseTroubleShooterNotRun=%1 was not able to complete. \nReason: %2
    
# English strings
    FailureToGetCounter = Could not get average value for counter:
    DatabaseMoved = Database moved while the troubleshooter was running. Error:
    UnableToGetAnyCounters = Troubleshooter cannot continue as we were unable to get any perf counters.
    UnableToAnalyze = Troubleshoot-DatabaseLatency completed without being able to determine the cause of high latency. Please investigate further; StoreUsageStatistics data collected by the TS could be useful in further analysis and can be found at:
###PSLOC
'@

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoDx5onieHDrPN0BOd45I1wUj
# 9cOgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAN0ZOWCIOEyhtxA/koB0azqKK40Pw3fa8GLif/ZM0cXJWGawkVgxOMbejeJW
# YCqXgEHF2MX/cJY8svCmLlX8M7AdjXYgtAS+C+cEHxrGAMMzj3/9EOu6DjzxIcwL
# l1GKoUwy8X3/GRGk3sBWT5CwKYRJdh9goWy74ltZN+sTKKeDHqpfuvxye6c++PC7
# 86wzm4MwfOIuPE9StFeo/0nKheEukfK9cpthlE5dUHpW0OjmJdX/g0mEdIjm2/Q2
# 50fzQyLQXOuMVIJ4Qk2comMDNRvZZvSPOBwWZ6fAR4tXfZwlpUcLv3wBbIjslhT7
# XasCm73TdBj+ZFDx2tUtpWguP/0CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBS+FASXsrRle2tLXdkVyoT1Dbw7
# QDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAbhjcmv+WCZwWCIYQwiEsH94SesBr0cPqWjEtJrBefqU9zFdB
# u5oc/WytxdCkEj5bxkoN9aJmuDAZnHNHBwIYeUz0vNByZRz6HsPzNPxLxThajJTe
# YOHlSTMI/XzBhJ7VzCb3YFhkD5f9gcJ5n+Z94ebd/1SoIvc9iwC3tTf5x2O7aHPN
# iyoWLTV4+PgDntCy/YDj11+uviI9sUUjAajYPEDvoiWinyT+7RlbStlcEuBwqvqT
# nLaiRsK17rjawW87Nkq/jB8rymUR/fzluIpHmPA4P0NazH4v5f62mpMFqdk0osMU
# QJ/qqACQ+2+/eAw7Gr6igNvlsxQpPfxsPNtUkTCCBTAwggQYoAMCAQICEAQJGBtf
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
# Q0ECEAYOIt5euYhxb7GIcjK8VwEwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFO6LsGuYw9tbPBGO
# EOiJFAMUf76LMA0GCSqGSIb3DQEBAQUABIIBADNr6p6tf9jC+nd0G1aVkig2wXSj
# QKFCnKgTwvOyIOBX1vq4R1qAV1H7W43TuApV5rGlB1L+FHyCA80wH9VC37uxical
# 5yLjDotWa7PK3KaxQYeQlpUykP/TUJRJ1rKoyElz6aHD2zABF+l6lnuPbpR3BtFV
# yCyHmVJ+x0uGtUx6RyO2CL6BobmaiwvNrQu9xYvesgwPEJGGUdzGKodJUCO44+7C
# DhRachMZ897qgZaCSG++goztWIoJfZ44/Uil6PtlZ+L+/4LFoDZ0gReE8QLmqYux
# yViiCxnW0WEdKPevSFIcJlsnyILLlhNY8qjo8hzO8zfEG/BNELenTA21L+8=
# SIG # End signature block
