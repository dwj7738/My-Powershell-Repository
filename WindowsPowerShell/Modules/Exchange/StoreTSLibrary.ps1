# Copyright (c) 2010 Microsoft Corporation. All rights reserved.
#
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

# Requires -Version 2

# Figures out on which volume our path is residing. This is necessary
# because customers mount spindles into a folder.
function Get-WmiVolumeFromPath([string] $FilePath, [string] $Server)
{
    do
    {
        $FilePath = $FilePath.Substring(0, $FilePath.LastIndexOf('\') + 1)

        $wmiFilter = ('Name="{0}"' -f $FilePath.Replace("\", "\\"))

        $volume = get-wmiobject -class win32_volume -computername $Server -filter $wmiFilter

        $FilePath = $FilePath.Substring(0, $FilePath.LastIndexOf('\'))

    } while ($volume -eq $null)

    return $volume
}

# Returns a descending list of the users generating the most log bytes for a given database
# based on the output of Get-StoreUsageStatistics the list contains the MailboxGuid and the
# number of bytes generated during the captured sampling periods (~ 1 hour)
function Get-TopLogGenerators([string] $DatabaseIdentity)
{
    # The Filter parameter doesn't accept complex filters, so filter on the category
    # and then use a where clause to filter out the Quarantined mailboxes.
    $topGenerators = New-Object Collections.ArrayList
    
    $global:StoreUsageStatsLB = Get-StoreUsageStatistics -Database $DatabaseIdentity `
                    -Filter "DigestCategory -eq 'LogBytes'"
         
    if ($global:StoreUsageStatsLB)
    {                               
        $stats = $global:StoreUsageStatsLB | where {$_.IsQuarantined -eq $false} `
                        | group MailboxGuid

        if ($null -ne $stats)
        {
            foreach($mailboxStats in $stats)
            {
                $total = 0
                $statSummary = new-object PSObject

                foreach($stat in $mailboxStats.Group)
                {
                    $total += $stat.LogRecordBytes
                }

                Add-Member -in $statSummary -Name TotalLogBytes -MemberType NoteProperty -Value $total
                Add-Member -in $statSummary -Name MailboxGuid -MemberType NoteProperty -Value $mailboxStats.Group[0].MailboxGuid

                # Tell PS we don't care about the return value for this function
                # otherwise these values will be output to the pipeline!
                [void]$topGenerators.Add($statSummary)
            }
            $topGenerators = Sort-Object -InputObject $topGenerators -Property TotalLogBytes -Descending
        }
    }

    return $topGenerators
}

# Returns a descending list of the users using up the most time in server for a given database
# based on the output of Get-StoreUsageStatistics the list contains the MailboxGuid and the
# time in server used up during the captured sampling periods (10 min)
function Get-TopCpuUsers([string] $DatabaseIdentity, [int] $TimeInServerThreshold, [int] $RopLatencyThreshold, [int] $PercentSampleBelowThresholdToAlert, [int] $MinimumStoreUsageStatisticsSampleCount)
{
    $topUsers = New-Object Collections.ArrayList

    $global:StoreUsageStatsTS = Get-StoreUsageStatistics -Database $DatabaseIdentity `
                    -Filter "DigestCategory -eq 'TimeInServer'"

    if ($global:StoreUsageStatsTS)
    {
        # First let's see if most users are being affected by high latency
        # or if it's just a small percent of users
        $totalCountAboveThreshold = 0
        $totalPctBelowThreshold = 0
        $totalCountAboveThreshold = ($global:StoreUsageStatsTS | ? {$_.TimeInServer/$_.RopCount -ge $RopLatencyThreshold} | measure).count; 
        $totalPercentBelowThreshold = [Math]::Round(100*($global:StoreUsageStatsTS.count - $totalCountAboveThreshold)/($global:StoreUsageStatsTS.count),1);
        
        # This is a condition that requires further investigation - If we have enough samples
        # and if users above the totalPercentBelowThreshold are having a bad experience
        If ($global:StoreUsageStatsTS.count -ge $MinimumStoreUsageStatisticsSampleCount -and $totalPercentBelowThreshold -lt $PercentSampleBelowThresholdToAlert)
        {
            $stats = $global:StoreUsageStatsTS | where {$_.IsQuarantined -eq $false} `
                        | group MailboxGuid    
                    
            if ($null -ne $stats)
            {
                foreach($mailboxStats in $stats)
                {
                    $statSummary = new-object PSObject
                    $totalTimeInServer = 0
                    $totalROPCount = 0
                    
                    # Get Total TimeInServer and ROPCount
                    foreach($stat in $mailboxStats.Group)
                    {
                        $totalTimeInServer += $stat.TimeInServer
                        $totalROPCount += $stat.ROPCount
                    }
                
                    # Calculate averages
                    $averageTimeInServer = $totalTimeInServer / $mailboxStats.Count
                    $averageROPCount = $totalROPCount / $mailboxStats.Count
                    $ropLatency = $averageTimeInServer / $averageROPCount
                    
                    # If either TimeInServer or RopLatency is above the threshold, include that mailbox in the list
                    if (($averageTimeInServer -ge $TimeInServerThreshold) -or ($ropLatency -ge $RopLatencyThreshold))
                    {
                        Add-Member -in $statSummary -Name TotalTimeInServer -MemberType NoteProperty -Value $totalTimeInServer
                        Add-Member -in $statSummary -Name AverageTimeInServer -MemberType NoteProperty -Value $averageTimeInServer
                        Add-Member -in $statSummary -Name RopLatency -MemberType NoteProperty -Value $ropLatency
                        Add-Member -in $statSummary -Name MailboxGuid -MemberType NoteProperty -Value $mailboxStats.Group[0].MailboxGuid
                        Add-Member -in $statSummary -Name Count -MemberType NoteProperty -Value $mailboxStats.Count

                        # Tell PS we don't care about the return value for this function
                        # otherwise these values will be output to the pipeline!
                        [void]$topUsers.Add($statSummary)
                    }
                }
                $topUsers = Sort-Object -InputObject $topUsers -Property TotalTimeInServer -Descending
            }
        }        
    }

    return $topUsers
}

function Get-RegistryValue
{
	param(
		[string]$Server = ".",
		[Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
		[Parameter(Mandatory=$true)][string]$KeyName,
		[Parameter(Mandatory=$true)][string]$ValueName,
		[object]$DefaultValue = $null
	)

	try
	{
	    $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $Server)
	    $key = $baseKey.OpenSubKey($KeyName, $false)
	    if ($key -ne $null)
	    {
    		$key.GetValue($ValueName, $DefaultValue)
	    }
    }
    finally
    {
        if ($key -ne $null)
        {
            $key.Close()
        }
	    if ($baseKey -ne $null)
	    {
    	    $baseKey.Close()
	    }
	}
}

function Set-RegistryValue
{
	param(
		[string]$Server = ".",
		[Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
		[Parameter(Mandatory=$true)][string]$KeyName,
		[Parameter(Mandatory=$true)][string]$ValueName,
		[Parameter(Mandatory=$true)][object]$Value,
		[Microsoft.Win32.RegistryValueKind]$ValueKind = "Unknown"
	)

    try
    {
	    $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $Server)
	    $key = $baseKey.OpenSubKey($KeyName, $true)
	    if ($key -eq $null)
	    {
    		$key = $baseKey.CreateSubKey($KeyName)
    	}

    	$key.SetValue($ValueName, $Value, $ValueKind)
	}
    finally
    {
        if ($key -ne $null)
        {
            $key.Close()
        }
	    if ($baseKey -ne $null)
	    {
    	    $baseKey.Close()
	    }
	}
}

function Remove-RegistryValue
{
	param(
		[string]$Server = ".",
		[Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
		[Parameter(Mandatory=$true)][string]$KeyName,
		[Parameter(Mandatory=$true)][string]$ValueName
	)

    try
    {
	    $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $Server)
	    $key = $baseKey.OpenSubKey($KeyName, $true)
	    if ($key -ne $null)
	    {
    		$key.DeleteValue($ValueName, $false)
    	}
    }
    finally
    {
        if ($key -ne $null)
        {
            $key.Close()
        }
	    if ($baseKey -ne $null)
	    {
    	    $baseKey.Close()
	    }
	}
}

function Remove-RegistryKey
{
	param(
		[string]$Server = ".",
		[Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
		[Parameter(Mandatory=$true)][string]$KeyName
	)

    try
    {
	    $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $Server)
	    $baseKey.DeleteSubKeyTree($KeyName)
	}
    finally
    {
        if ($key -ne $null)
        {
            $key.Close()
        }
	    if ($baseKey -ne $null)
	    {
    	    $baseKey.Close()
	    }
	}
}

function Get-RegistrySubKeyNames
{
	param(
		[string]$Server = ".",
		[Parameter(Mandatory=$true)][Microsoft.Win32.RegistryHive]$Hive,
		[Parameter(Mandatory=$true)][string]$KeyName
	)

    try
    {
	    $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $Server)
	    $key = $baseKey.OpenSubKey($KeyName, $false)
    	if ($key -ne $null)
    	{
		    $key.GetSubKeyNames()
	    }
	}
    finally
    {
        if ($key -ne $null)
        {
            $key.Close()
        }
	    if ($baseKey -ne $null)
	    {
    	    $baseKey.Close()
	    }
	}
}

function Get-AverageResultForCounter($results, $counter, $instance)
{
    #Turn strictmode off so that if we don't have cookedvalue
    #for a particular instance, we don't get an exception. 
    #This way, we can get average from whatever counters are 
    #available and continue as far as we can. Turning strict mode
    #off is only within the scope of this function.
    Set-StrictMode -off
    
    $count = 0
    $total = $null
    $counterName = $counter
    
    if ($instance)
    {
        $counterName = $counterName.replace("*", $instance)
    }

    foreach ($sample in $results)
    {
        $cookedValue = ($sample.CounterSamples | ?{$_.Path -like "*$counterName*"}).CookedValue
        
        if ($cookedValue -ne $null)
        {
            #We want to increment the number of samples here so that
            #we can calculate the avg properly rather than assuming
            #that we got samples equal to the length of results
            $total += $cookedValue
            $count++
        }
    }
    
    If ($total -ne $null -and $count -ne 0)
    {
    	return $total/($count)
    }
    else
    {
        $failureReason = ($StoreLocStrings.FailureToGetCounter + $counterName)
        if ($Arguments -ne $null)
        {
            #Get the invoking scriptname so we can put in the event
            $script = $MyInvocation.ScriptName.Substring($MyInvocation.ScriptName.LastIndexOf('\') + 1)
            if ($script -ne $null)
            {
                $script = $script.Substring(0,$script.Length - 4)
            }
            else
            {
                $script = "Troubleshooter"
            }
            
            Log-Event `
                -Arguments $Arguments `
                -EventInfo $StoreLogEntries.DatabaseTroubleShooterNotRun `
                -Parameters @($script, $failureReason)
        }
        
        throw $failureReason
    }
}

Import-LocalizedData -BindingVariable StoreLocStrings -FileName StoreTSLibrary.strings.psd1

$StoreLogEntries = @{
#
# Events logged to application log and windows event (crimson) log
# Information: 5100-5199; Warning: 5400-5499; Error: 5700-5799;
#
#   Informational events
#
    DatabaseSpaceTroubleShooterStarted=(5100,"Information", $StoreLocStrings.DatabaseSpaceTroubleShooterStarted)
    DatabaseSpaceTroubleShooterNoProblemDetected=(5101,"Information", $StoreLocStrings.DatabaseSpaceTroubleShooterNoProblemDetected)
    DatabaseLatencyTroubleShooterStarted=(5110,"Information", $StoreLocStrings.DatabaseLatencyTroubleShooterStarted)
    DatabaseLatencyTroubleShooterNoLatency=(5111,"Information", $StoreLocStrings.DatabaseLatencyTroubleShooterNoLatency)
    DatabaseLatencyTroubleShooterLowOps=(5112,"Information", $StoreLocStrings.DatabaseLatencyTroubleShooterLowOps)
    DatabaseTroubleShooterNotRun=(5113,"Information", $StoreLocStrings.DatabaseTroubleShooterNotRun)
    DatabaseLatencyTroubleShooterNotRunDatabase=(5114,"Information", $StoreLocStrings.DatabaseLatencyTroubleShooterNotRunDatabase)
    DatabaseLatencyTroubleShooterUniqueMailbox=(5115,"Information", $StoreLocStrings.DatabaseLatencyTroubleShooterUniqueMailbox)
    DatabaseLatencyTroubleShooterNoMailbox=(5116,"Information", $StoreLocStrings.DatabaseLatencyTroubleShooterNoMailbox)

    DatabaseSpaceTroubleShooterFoundLowSpace=(5400,"Warning", $StoreLocStrings.DatabaseSpaceTroubleShooterFoundLowSpace)
    DatabaseSpaceTroubleShooterFoundLowSpaceNoQuarantine=(5401,"Warning", $StoreLocStrings.DatabaseSpaceTroubleShooterFoundLowSpaceNoQuarantine)
    DatabaseSpaceTroubleDetectedWarningSpaceIssue=(5402,"Warning", $StoreLocStrings.DatabaseSpaceTroubleDetectedWarningSpaceIssue)
    DatabaseSpaceTroubleShooterQuarantineUser=(5410,"Warning", $StoreLocStrings.DatabaseSpaceTroubleShooterQuarantineUser)
    DatabaseLatencyTroubleShooterQuarantineUser=(5411,"Warning", $StoreLocStrings.DatabaseLatencyTroubleShooterQuarantineUser)
    DatabaseLatencyTroubleShooterNoQuarantine=(5412,"Warning", $StoreLocStrings.DatabaseLatencyTroubleShooterNoQuarantine)

    DatabaseSpaceTroubleShooterFinishedInsufficient=(5700,"Error", $StoreLocStrings.DatabaseSpaceTroubleShooterFinishedInsufficient)
    DatabaseSpaceTroubleDetectedAlertSpaceIssue=(5701,"Error", $StoreLocStrings.DatabaseSpaceTroubleDetectedAlertSpaceIssue)
    DatabaseSpaceTroubleDetectedCriticalSpaceIssue=(5702,"Error", $StoreLocStrings.DatabaseSpaceTroubleDetectedCriticalSpaceIssue)
    DatabaseLatencyTroubleShooterBadDiskLatencies=(5710,"Error", $StoreLocStrings.DatabaseLatencyTroubleShooterBadDiskLatencies)
    DatabaseLatencyTroubleShooterBadDSAccessActiveCallCount=(5711,"Error", $StoreLocStrings.DatabaseLatencyTroubleShooterBadDSAccessActiveCallCount)
    DatabaseLatencyTroubleShooterIneffective=(5712,"Error", $StoreLocStrings.DatabaseLatencyTroubleShooterIneffective)
    DatabaseLatencyTroubleShooterBadDSAccessAverageLatency=(5713,"Error", $StoreLocStrings.DatabaseLatencyTroubleShooterBadDSAccessAverageLatency)
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZBLU0SgWPq6EnyVMP0qu1JGk
# VlqgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJwqXewJzQK22hN1
# 654vAFXY7RyTMA0GCSqGSIb3DQEBAQUABIIBAGJM/vEaaV8rqEE5aSbv7SfjYO3p
# fivpawHMCKEy3/KNbCyKuMqkO4lqvwOqs9BYedMOhp1EZfPCYPOUXUko2zOZXapZ
# eL3vpOQGl8IHBgwiAxPVl35wYARqdR7DXZnmnWmfQCnU/6jauvrN3aEedX9pjiGu
# If8DiTVXhZVQoPtFk1EYWD/rE5MaT+z4R0RczkG519VH1GYNiqSelkz29IpZv3/m
# EQBBmvw/RHbfT6IUqstxXsvYJlYokKQd7U0xjuNDKenrI9pHD2+67tCZqYqCR9cI
# rlzJQBHv0jk1FEqPmmZRtrf38jxp9RDh/aNsXqNieoKR4D9bV27QMOFhF8g=
# SIG # End signature block
