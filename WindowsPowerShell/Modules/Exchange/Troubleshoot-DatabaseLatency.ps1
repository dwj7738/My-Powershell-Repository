# Copyright (c) 2010 Microsoft Corporation. All rights reserved.
#
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

# Requires -Version 2
[CmdletBinding(DefaultParametersetName="Default")]
PARAM(
    [parameter(
        ParameterSetName = "Default",
        Mandatory = $true,
        HelpMessage = "The database to troubleshoot.")]
    [String]
    [ValidateNotNullOrEmpty()]
    $MailboxDatabaseName,

    [parameter(
        ParameterSetName = "Default",
        Mandatory = $true,
        HelpMessage = "The maximum RPC average latency the server should be experiencing. (Typical thresholds might be 70 or 150.)")]
    [int]
    [ValidateRange(1, 200)]
    [ValidateNotNullOrEmpty()]
    $LatencyThreshold,

    [parameter(
        ParameterSetName = "NoOp",
        Mandatory = $true,
        HelpMessage = "Loads helper libraries, then quits. Used to verify proper deployment/installation.")]
    [switch]
    $Deploy,

    [int]
    [ValidateRange(1,600000)]
    [ValidateNotNullOrEmpty()]
    $TimeInServerThreshold,

    [int]
    [ValidateRange(1,500)]
    [ValidateNotNullOrEmpty()]
    $OperationPerSecondThreshold,
    
    [parameter(
        Mandatory = $false,
        HelpMessage = "Minimum number of samples of StoreUsageStatistics a user should have to be able to positively identify a single user problem.")]
    [int]
    [ValidateRange(1,10)]
    [ValidateNotNullOrEmpty()]
    $MinimumUserSampleCount,
    
    [parameter(
        Mandatory = $false,
        HelpMessage = "Minimum number of samples of StoreUsageStatistics in the set that was collected.")]
    [int]
    [ValidateRange(1,250)]
    [ValidateNotNullOrEmpty()]
    $MinimumStoreUsageStatisticsSampleCount,
    
    [parameter(
        Mandatory = $false,
        HelpMessage = "Percent of samples below rop latency threshold at which we want to investigate further.")]
    [int]
    [ValidateRange(1,100)]
    [ValidateNotNullOrEmpty()]
    $PercentSampleBelowThresholdToAlert,
    
    [parameter(
        Mandatory = $false,
        HelpMessage = "Whether or not to quarantine heavy users.")]
    [switch]
    $Quarantine,

    [parameter(
        Mandatory = $false,
        HelpMessage = "Whether or not we're running under the monitoring context.")]
    [switch]
    $MonitoringContext,

    [parameter(
        Mandatory = $false,
        HelpMessage = "Whether or not to quarantine heavy users.")]
    [String]
    $QuarantineString,

    [parameter(
        Mandatory = $false,
        HelpMessage = "Whether or not we're running under the monitoring context.")]
    [String]
    $MonitoringContextString,
    
    [parameter(
        Mandatory = $false,
        HelpMessage = "Alert Guid if executed in response to an alert.")]
    [String]
    $AlertGUID
)

###################################################################################################################################
#                                                                                                                                 #
#                                                     Script Body                                                                 #
#                                                                                                                                 #
###################################################################################################################################

    Set-StrictMode -Version Latest

    if ($QuarantineString -eq "true")
    {
        $Quarantine = $true;
    }
    if ($MonitoringContextString -eq "true")
    {
        $MonitoringContext = $true;
    }
        
    $scriptPath = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)

    . $scriptPath\CITSLibrary.ps1
    . $scriptPath\StoreTSLibrary.ps1
    . $scriptPath\StoreTSConstants.ps1
    . $scriptPath\DiagnosticScriptCommonLibrary.ps1

    Load-ExchangeSnapin

    # Since we're in strict mode we must declare all variables we use
    $script:monitoringEvents = $null

    if ($PSCmdlet.ParameterSetName -eq "NoOp")
    {
        if ($MonitoringContext)
        {
            #E14:303295 Add a dummy monitoring event to supress SCOM failure alerts
            Add-MonitoringEvent -Id $StoreLogEntries.DatabaseSpaceTroubleShooterStarted[0] -Type $EVENT_TYPE_INFORMATION -Message "Latency TS in No-op mode"
            Write-MonitoringEvents
        }
        
        return
    }

    $database = Get-MailboxDatabase $MailboxDatabaseName -Status

    if ($database -eq $null)
    {
        $argError = new-object System.ArgumentException ($error[0].Exception.ToString())
        throw $argError
    }

    if (!$MyInvocation.BoundParameters.ContainsKey("TimeInServerThreshold"))
    {
        $TimeInServerThreshold = $TimeInServerDefaultThreshold
    }

    # Event log source name for application log
    $appLogSourceName = "Database Latency Troubleshooter"

    # Event log source name for crimson log
    $crimsonLogSourceName = "Database Latency"

    # The Arguments object is needed for logging
    # events.
    $Arguments = new-object -typename Arguments

    $Arguments.Server = $database.MountedOnServer
    $Arguments.Database = $database
    $Arguments.MonitoringContext = $MonitoringContext

    # Since this TS doesn't run in SCOM we need to write App event logs
    # for alerts to fire
    $Arguments.WriteApplicationEvent = $MonitoringContext

    Log-Event `
        -Arguments $Arguments `
        -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterStarted `
        -Parameters @($database)

    $rpcLatencyCounterName = "\MSExchangeIS Mailbox($database)\rpc average latency"
    $rpcOpsPerSecondCounterName = "\MSExchangeIS Mailbox($database)\RPC Operations/sec"
    $readLatencyCounterName = "\MSExchange Database ==> Instances($database)\I/O Database Reads Average Latency"
    $readRateCounterName = "\MSExchange Database ==> Instances($database)\I/O Database Reads/sec"
    $writeLatencyCounterName = "\MSExchange Database ==> Instances($database)\I/O Database Writes Average Latency"
    $writeRateCounterName = "\MSExchange Database ==> Instances($database)\I/O Database Writes/sec"
    $dsaccessLatencyCounterName = "\MSExchangeIS\dsaccess average latency"
    $dsaccessCallsCounterName = "\MSExchangeIS\dsaccess active call count"

    $counterNames = @($rpcLatencyCounterName, $rpcOpsPerSecondCounterName, $readLatencyCounterName, $readRateCounterName, $writeLatencyCounterName, $writeRateCounterName, $dsaccessLatencyCounterName, $dsaccessCallsCounterName)
        
    $retries = 0
    
    do
    {
        $success = $true
        $error.Clear()    
    
        $counterValues = get-counter -ComputerName $database.MountedOnServer -Counter $counterNames -MaxSamples 10 -ErrorAction SilentlyContinue
    
        #Verify there were no errors when trying to get the perf counters
        #Even if we are unsuccessful getting the perf counters and come
        #out of this loop, it will be handled properly when we try to get
        #the average results for the counters. This way, we handle the case
        #where we at least got some counters back and try to go as far into 
        #the TS as possible
        if ($error.Count -gt 0)
        {
            #Check to see if the error was related to the database being failed over,
            #in this case, we should get CounterPathIsInvalid (E14 Bug: 468424)
            if ($error[0].FullyQualifiedErrorId -match "CounterPathIsInvalid")
            {            
                #Get the computername database is currently on to verify that the
                #database indeed moved
                $currentDatabase = Get-MailboxDatabase $MailboxDatabaseName -Status
                if ($currentDatabase.MountedOnServer -ne $database.MountedOnServer)
                {                
                    #Log an event for TS not able to run due to database moved
                    $failureReason = ($StoreLocStrings.DatabaseMoved + $error[0])
                    Log-Event `
                        -Arguments $Arguments `
                        -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterNotRunDatabase `
                        -Parameters @($database, $failureReason)
                        
                    if ($MonitoringContext)
                    {
                        Write-MonitoringEvents
                    }
            
                    #Clear the error so that it does not get escalated
                    $error.Clear()
                    
                    return
                }
            }
            elseif ($error[0].FullyQualifiedErrorId -match "CounterApiError")
            {
                #This could be due to stale powershell session or some other transient issue
                #Let's try a few more times to get the counters after sleeping for a few
                #seconds between each retries, with a total sleep time of 30 seconds
                $retries++
                $success = $false
                
                if ($retries -lt 5)
                {
                    $sleepSeconds = $retries * 3
                    write-verbose ("Unable to get perf counters after {0} retries, Re-trying after sleeping for {1} seconds." -f $retries, $sleepSeconds)
                    Start-Sleep -Seconds $sleepSeconds
                }
            }
            else
            {
                #Not the expected error, throw so recovery workflow will escalate
                if ($MonitoringContext)
                {
                    Write-MonitoringEvents
                }
                        
                throw $error[0]
            }
        }    
    } while ((-not $success) -and $retries -lt 5)

    #Check to see if we got any perf counters back
    #If we didn't, does not make sense to continue
    #executing the troubleshooter
    if (!$counterValues)
    {
        if ($MonitoringContext)
        {
            Write-MonitoringEvents
        }
        
        $failureReason = "{0} Error: {1}" -f $StoreLocStrings.UnableToGetAnyCounters, $error[0]
        Log-Event `
            -Arguments $Arguments `
            -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterNotRunDatabase `
            -Parameters @($database, $failureReason)
                        
        throw $failureReason
    }

    #Check that latencies are still high
    $rpcLatency = Get-AverageResultForCounter -results $counterValues -counter $rpcLatencyCounterName
    if ($rpcLatency -lt $LatencyThreshold)
    {
        Log-Event `
            -Arguments $Arguments `
            -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterNoLatency `
            -Parameters @($rpcLatency, $database, $LatencyThreshold)

        if ($MonitoringContext)
        {
            Write-MonitoringEvents
        }

        return
    }

    # Check that Rpc operations/sec are high enough to monitor.
    if (!$MyInvocation.BoundParameters.ContainsKey("OperationPerSecondThreshold"))
    {
        $OperationPerSecondThreshold = $OperationPerSecondDefaultThreshold
    }
    
    $rpcOpsPerSecond = Get-AverageResultForCounter -results $counterValues -counter $rpcOpsPerSecondCounterName
    if ($rpcOpsPerSecond -lt $OperationPerSecondThreshold)
    {
        Log-Event `
            -Arguments $Arguments `
            -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterLowOps `
            -Parameters @($database, $rpcLatency, $LatencyThreshold, $rpcOpsPerSecond, $OperationPerSecondThreshold)

        if ($MonitoringContext)
        {
            Write-MonitoringEvents
        }

        return
    }

    # check if disk transfers/sec < X and disk secs/transfer > Y... if yes, disk is bad.
    $readLatency = Get-AverageResultForCounter -results $counterValues -counter $readLatencyCounterName
    $readRate = Get-AverageResultForCounter -results $counterValues -counter $readRateCounterName
    $writeLatency = Get-AverageResultForCounter -results $counterValues -counter $writeLatencyCounterName
    $writeRate =  Get-AverageResultForCounter -results $counterValues -counter $writeRateCounterName

    # We don't want to report a bad disk if the disk is being overloaded
    # so check to see if we have a lot of read/write requests to the disk
    # if we don't have many requests and either latency (read or write)
    # is above our thresholds then we have a bad disk.
    if ((($readRate -lt $DiskReadRateThreshold) -and
            ($writeRate -lt $DiskWriteRateThreshold)) `
            -and
        (($readLatency -gt $DiskReadLatencyThreshold) -or
            ($writeLatency -gt $DiskWriteLatencyThreshold)))
    {
        # DatabaseLatencyTroubleShooterBadDiskLatencies is only reporting read rate
        # and read latency, it should be really report write rate and latencies as well
        Log-Event `
            -Arguments $Arguments `
            -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterBadDiskLatencies `
            -Parameters @($database, $readLatency, $readRate, $rpcLatency)

        if ($MonitoringContext)
        {
            Write-MonitoringEvents
        }

        return
    }

    # Look for high AD latencies and/or call count.
    $dsaccessLatency = Get-AverageResultForCounter -results $counterValues -counter $dsaccessLatencyCounterName
    $dsaccessCalls =  Get-AverageResultForCounter -results $counterValues -counter $dsaccessCallsCounterName

    # Report a very-high call count, or a medium-high call count in combination with a medium-high latency.
    if (($dsaccessCalls -gt $DSAccessCallsStandaloneThreshold) -or
        (($dsaccessCalls -gt $DSAccessCallsCombinedThreshold) -and
         ($dsaccessLatency -gt $DSAccessLatencyCombinedThreshold)))
    {
        Log-Event `
            -Arguments $Arguments `
            -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterBadDSAccessActiveCallCount `
            -Parameters @($database, $dsaccessLatency, $dsaccessCalls, $rpcLatency)

        if ($MonitoringContext)
        {
            Write-MonitoringEvents
        }

        return
    }

    # Report a very-high latency, even without a high call count. This test must come after the combined test.
    if ($dsaccessLatency -gt $DSAccessLatencyStandaloneThreshold)
    {
        Log-Event `
            -Arguments $Arguments `
            -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterBadDSAccessAverageLatency `
            -Parameters @($database, $dsaccessLatency, $dsaccessCalls, $rpcLatency)

        if ($MonitoringContext)
        {
            Write-MonitoringEvents
        }

        return
    }

    # Run get-storeusagestatistics to find the user who is not already quarantined, has TimeInServer > Threshold
    # and RopLatency (TimeInServer/RopCount) > Threshold when averaged across all samples and is the top user
    if (!$MyInvocation.BoundParameters.ContainsKey("PercentSampleBelowThresholdToAlert"))
    {
        $PercentSampleBelowThresholdToAlert = $PercentSampleBelowThresholdToAlertDefault
    }
    
    if (!$MyInvocation.BoundParameters.ContainsKey("MinimumStoreUsageStatisticsSampleCount"))
    {
        $MinimumStoreUsageStatisticsSampleCount = $MinimumStoreUsageStatisticsSampleCountDefault
    }
        
    $topCpuUsers = @(Get-TopCpuUsers $database -TimeInServerThreshold $TimeInServerThreshold -ROPLatencyThreshold $ROPLatencyThreshold -PercentSampleBelowThresholdToAlert $PercentSampleBelowThresholdToAlert -MinimumStoreUsageStatisticsSampleCount $MinimumStoreUsageStatisticsSampleCount)
    
    # See if there is one or more user with TimeInServer and ROP Latency greater than the threshold
    # If no user in the list, there is no impact to anybody even with high latency
    # It could likely be SystemMailbox causing this. In any case, we don't care so
    # just suppress
    if ($topCpuUsers.Length -eq 0)
    {
        # Log an event and return
            Log-Event `
                -Arguments $Arguments `
                -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterNoMailbox `
                -Parameters @($database, $rpcLatency)

            if ($MonitoringContext)
            {
                Write-MonitoringEvents
            }
            
            return
    }    
    else
    {
        # If we have a top user and we are down here, the only action left to take is quarantine *only that user*. 
        # Fire an event indicating quarantine. Exit
        # In production, we have quarantine set to false. So if we get this far, we are going to get a paging
        # or non-paging alert (based on RPC latency) with a pointer to saved SUS data.
        if ($Quarantine -eq $true)
        {
            # Quarantine the mailbox
            write-verbose ("Quarantining: " + $topCpuUsers[0].MailboxGuid + " due to following:")
            write-verbose ("TotalTimeInServer: " + $topCpuUsers[0].TotalTimeInServer)
            write-verbose ("AverageTimeInServer: " + $topCpuUsers[0].AverageTimeInServer)
            write-verbose ("TimeInServerThreshold: " + $TimeInServerThreshold)
            write-verbose ("RPC Operations per sec: " + $rpcOpsPerSecond)
                        
            Enable-MailboxQuarantine -Identity $topCpuUsers[0].MailboxGuid.ToString() -Confirm:$false -ErrorAction Stop

            Log-Event `
                -Arguments $Arguments `
                -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterQuarantineUser `
                -Parameters @($topCpuUsers[0].MailboxGuid, $database, $topCpuUsers[0].AverageTimeInServer, $rpcLatency, $rpcOpsPerSecond)

            if ($MonitoringContext)
            {
                Write-MonitoringEvents
            }

            return
        }
        else
        {
            Log-Event `
                -Arguments $Arguments `
                -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterNoQuarantine `
                -Parameters @($topCpuUsers[0].MailboxGuid, $database, $topCpuUsers[0].AverageTimeInServer, $rpcLatency, $rpcOpsPerSecond)
        }
    }

    # If we are down here, let's save store usage statistics and send mail to on-calls
    # so that it can be analysed irrespective of whether we quarantine the mailbox or not.
    # We only want to do this in prod.
    Log-Event `
        -Arguments $Arguments `
        -EventInfo $StoreLogEntries.DatabaseLatencyTroubleShooterIneffective `
        -Parameters @($database, $rpcLatency, $rpcOpsPerSecond)
        
    if ($MonitoringContext -and $global:StoreUsageStatsTS)
    {
        $exchangeInstallPath = (get-item HKLM:\SOFTWARE\Microsoft\ExchangeServer\V14\Setup).GetValue("MsiInstallPath")
        $StoreLibraryPath = Join-Path $exchangeInstallPath "Datacenter\StoreCommonLibrary.ps1"
        if (Test-Path $StoreLibraryPath)
        {
            # Dot-source common libraries to populate alert details.
            . ($StoreLibraryPath)
            
            # Get store usage statistics and send mail
            $statsPath = Output-StoreUsageStatistics $global:StoreUsageStatsTS $alertGUID
            
            # Because of E14:497368, we are going to just throw here so that proper alert mail gets sent
            # to the on-calls instead of us trying to populate alert details.
            $failureReason = "{0} {1}" -f $StoreLocStrings.UnableToAnalyze, $statsPath
            Write-MonitoringEvents
            throw $failureReason
        }
    }
    
    if ($MonitoringContext)
    {
        Write-MonitoringEvents

        # Throw an exception to make the workflow that invoked us go to its failure state.
        # This should result in an escalation - either urgent or non-urgent, depending on what
        # the health manifest specified in the RecoveryAction.
        throw "Troubleshoot-DatabaseLatency failed. See the event log for further details."
    }


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpW6nGzvZZwYSous7ihM4fagt
# kU+gggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMwvYKPNs2hO6WwT
# O9dQzZGUV2c6MA0GCSqGSIb3DQEBAQUABIIBADA3gsovz7XEvfuHUTofVMjUXf/A
# ufnK2L/HvthggUnAJ0ykmQ8uTxd7BbsFB+/JwyIXe62151ADg/JFAUc7+YUthBV8
# VwKBijrCpVS3NTl3rG2Gv+9HHcEqFyD/kxkkBlGVIHwI/9S/qJr/DGCMRQGVWr06
# /Av+r83pSsx4ptrCv5HpF9rNwSQfFfENc8xUPStakZhQxGJLK+6qemcK3E8UcgjQ
# Ex02AJ975bRo6EZSUKCaVsorlzBaQv38qTNutORxF188fTuP8TgLzkn5DNQYkfAW
# XoIRBzX75ZYw6wpaNo8F4IfP33R0NPAEzbpH8EGRdfupPTI0jvAa/KYoXNw=
# SIG # End signature block
