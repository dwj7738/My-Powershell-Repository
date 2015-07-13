# Copyright (c) Microsoft Corporation. All rights reserved.
#
# StartDagServerMaintenenance.ps1

# .SYNOPSIS
# Calls Suspend-MailboxDatabaseCopy on the database copies.
# Pauses the node in Failover Clustering so that it can not become the Primary Active Manager.
# Suspends database activation on each mailbox database.
# Sets the DatabaseCopyAutoActivationPolicy to Blocked on the server.
# Moves databases and cluster group off of the designated server.
#
# If there's a failure in any of the above, the operations are undone, with
# the exception of successful database moves.
#
# Can be run remotely, but it requires the cluster administrative tools to
# be installed (RSAT-Clustering).

# .PARAMETER serverName
# The name of the server on which to start maintenance. FQDNs are valid

# .PARAMETER whatif
# Does not actually perform any operations, but logs what would be executed
# to the verbose stream.

# .PARAMETER overrideMinimumTwoCopies
# Allows users to override the default minimum number of database copies to require
# to be up after shutdown has completed.  This is meant to allow upgrades
# in situations where users only have 2 copies of a database in their dag.

Param(
	[Parameter(Mandatory=$true)]
	[System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
	[string] $serverName,

	[string] $Force = 'false',
	[Parameter(Mandatory=$false)] [switch] $whatif = $false,
	[Parameter(Mandatory=$false)] [switch] $overrideMinimumTwoCopies = $false
)

# Global Values
$ServerCountinTwoServerDAG = 2
$RetryCount = 2

Import-LocalizedData -BindingVariable StartDagServerMaintenance_LocalizedStrings -FileName StartDagServerMaintenance.strings.psd1

# Define some useful functions.

# Load the Exchange snapin if it's no already present.
function LoadExchangeSnapin
{
    if (! (Get-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction:SilentlyContinue) )
    {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction:Stop
    }
}

# Handle Cluster Error Codes during Start-DagServerMaintenance
function HandleClusterErrorCode ([string]$Server = $servername, [int]$ClusterErrorCode, [string]$Action)
{
	switch ($ClusterErrorCode)
	{
		# 0 is success
		0		
		{   
			log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0026 -f $Server,$Action,"Start-DagServerMaintenance")
			# clear $LastExitCode
			cmd /c "exit 0"
		}
        
        # 5 is returned when the Server is powered down 
		5
		{
			log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0025 -f $Server,$Action,"Server powered down","Start-DagServerMaintenance")
			# clear $LastExitCode
			cmd /c "exit 0"
		}
		
		# 1753 is EPT_S_NOT_REGISTERED
		1753
		{
			log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0025 -f $Server,$Action,"EPT_S_NOT_REGISTERED","Start-DagServerMaintenance")
			# clear $LastExitCode
			cmd /c "exit 0"
		}
		
		# 1722 is RPC_S_SERVER_UNAVAILABLE
		1722
		{
			log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0025 -f $Server,$Action,"RPC_S_SERVER_UNAVAILABLE","Start-DagServerMaintenance")
			# clear $LastExitCode
			cmd /c "exit 0"
		}
		
		# 5042 is ERROR_CLUSTER_NODE_NOT_FOUND
		5042
		{
			log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0025 -f $Server,$Action,"ERROR_CLUSTER_NODE_NOT_FOUND","Start-DagServerMaintenance")
			# clear $LastExitCode
			cmd /c "exit 0"
		}
		
		# 5043 is ERROR_CLUSTER_LOCAL_NODE_NOT_FOUND
		5043
		{
			log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0025 -f $Server,$Action,"ERROR_CLUSTER_LOCAL_NODE_NOT_FOUND","Start-DagServerMaintenance")
			# clear $LastExitCode
			cmd /c "exit 0"
		}
		
		# 5050 is ERROR_CLUSTER_NODE_DOWN
		5050
		{
			log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0025 -f $Server,$Action,"ERROR_CLUSTER_NODE_DOWN","Start-DagServerMaintenance")
			# clear $LastExitCode
			cmd /c "exit 0"
		}
		
		# Not a known code, so error at this point
		default {Log-Error ($StartDagServerMaintenance_LocalizedStrings.res_0004 -f $Server,$Action,$ClusterErrorCode,"Start-DagServerMaintenance") -stop}
	}
}

# The meat of the script!
&{
	# Get the current script name. The method is different if the script is
	# executed or if it is dot-sourced, so do both.
	$thisScriptName = $myinvocation.scriptname
	if ( ! $thisScriptName )
	{
		$thisScriptName = $myinvocation.MyCommand.Path
	}

	# Many of the script libraries already use $DagScriptTesting
	if ( $whatif )
	{
		$DagScriptTesting = $true;
	}

	# Load the Exchange cmdlets.
	& LoadExchangeSnapin

	# Load some of the common functions.
	. "$(split-path $thisScriptName)\DagCommonLibrary.ps1";
	
	Test-RsatClusteringInstalled

	# Allow an FQDN to be passed in, but strip it to the short name.
	$shortServerName = $serverName;
	if ( $shortServerName.Contains( "." ) )
	{
		$shortServerName = $shortServerName -replace "\..*$"
	}
	
	# Variables to keep track of what needs to be rolled back in the event of failure.
	$pausedNode = $false;
	$activationBlockedOnServer = $false;
	$databasesSuspended = $false;
	$scriptCompletedSuccessfully = $false;

	try {
        # Stage 1 - block auto activation on the server,
        # both at the server level and the database copy level
        
		log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0008 -f $shortServerName)
		if ($DagScriptTesting)
		{
			write-host ($StartDagServerMaintenance_LocalizedStrings.res_0009 -f $shortServerName,"Set-MailboxServer","-Identity","-DatabaseCopyAutoActivationPolicy")
		}
		else
		{
			Set-MailboxServer -Identity $shortServerName -DatabaseCopyAutoActivationPolicy:Blocked
			$activationBlockedOnServer = $true;
		}
			
		# Get all databases with multiple copies.
		$databases = Get-MailboxDatabase -Server $shortServerName | where { $_.ReplicationType -eq 'Remote' }
	
		if ( $databases )
		{
			# Suspend database copy. When suspended with ActivationOnly,
			# no alerts should be raised.
			log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0010 -f $shortServerName,"Start-DagServerMaintenance")
	
			if ( $DagScriptTesting )
			{
				$databases | foreach { write-host ($StartDagServerMaintenance_LocalizedStrings.res_0011 -f ($_.Name),(get-date -format s),$shortServerName,$false,"Suspend-MailboxDatabaseCopy","-ActivationOnly","-Confirm","-SuspendComment") }
			}
			else
			{
                try
                {
                    $databasesSuspended = $true;
				    $databases | foreach { Suspend-MailboxDatabaseCopy "$($_.Name)\$shortServerName" -ActivationOnly -Confirm:$false -SuspendComment "Suspended ActivationOnly by StartDagServerMaintenance.ps1 at $(get-date -format s)" }				    
                }
                catch
                {
                    log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0028 -f $shortServerName,"Start-DagServerMaintenance","Suspend-MailboxDatabaseCopy -ActivationOnly", $_)
                }
			}
		}
		else
		{
			log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0012 -f $shortServerName,"get-mailboxdatabase")
		}
        
        # Stage 2 - pause the node in the cluster to stop it becoming the PAM
        
		# Explicitly connect to clussvc running on serverName. This script could
		# easily be run remotely.
		log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0000 -f $shortServerName);
		if ( $DagScriptTesting )
		{
			log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0001 )
		}
		else
		{
			# Try to fetch $dagName if we can.
			$dagName = $null
			$mbxServer = get-mailboxserver $serverName -erroraction:silentlycontinue
			if ( $mbxServer -and $mbxServer.DatabaseAvailabilityGroup )
			{
				$dagName = $mbxServer.DatabaseAvailabilityGroup.Name;
			}

			# Start with $serverName (which may or may not be a FQDN) before
			# falling back to the (short) names of the DAG.

			$outputStruct = Call-ClusterExe -dagName $dagName -serverName $serverName -clusterCommand "node $shortServerName /pause"
			$LastExitCode = $outputStruct[ 0 ];
			$output = $outputStruct[ 1 ];
			HandleClusterErrorCode -ClusterErrorCode $LastExitCode -Action "Pause"
			$pausedNode = $true;
		}
        
        # Stage 3 - move all the resources off the server
            
		log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0005 -f $shortServerName,"Start-DagServerMaintenance")
		$criticalMailboxResources = @(GetCriticalMailboxResources $shortServerName )
		$numCriticalResources = ($criticalMailboxResources | Measure-Object).Count
		log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0006 -f $numCriticalResources,"Start-DagServerMaintenance")

		if ( $criticalMailboxResources )
		{
			write-host ($StartDagServerMaintenance_LocalizedStrings.res_0007 -f ( PrintCriticalMailboxResourcesOutput($criticalMailboxResources)),$shortServerName)
		}
		
		# Move the critical resources off the specified server. 
		# This includes Active Databases, and the Primary Active Manager.
		# If any error occurs in this stage, script execution will halt.
		# (If we don't assign the result to a variable then the script will
		# print out 'True')
		$try = 0
		$dagObject = Get-DatabaseAvailabilityGroup $dagName			
		$dagServers = $dagObject.Servers.Count			
		$stoppedDagServers = $dagObject.StoppedMailboxServers.Count	
		while (($numCriticalResources -gt 0) -and ($try -lt $RetryCount))
		{
			# Sleep for 60 seconds if this is not the first move attempt
			if ($try -gt 0)
			{
				Sleep-ForSeconds 60
			}
			$ignoredResult = Move-CriticalMailboxResources -Server $shortServerName
		
			# Check again to see if the moves were successful. (Unless -whatif was
			# specified, then it's pretty likely it will fail).
			if ( !$DagScriptTesting )
			{
				log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0013 -f $shortServerName,"Start-DagServerMaintenance")			
						
				if (($dagServers - $stoppedDagServers) -eq $ServerCountinTwoServerDAG -or $overrideMinimumTwoCopies)
				{				
					$criticalMailboxResources = @(GetCriticalMailboxResources $shortServerName -AtleastNCriticalCopies ($ServerCountinTwoServerDAG - 1))
				}
				else
				{			
					$criticalMailboxResources = @(GetCriticalMailboxResources $shortServerName)	
				}			
				$numCriticalResources = ($criticalMailboxResources | Measure-Object).Count
			}
			$try++
		}
		if( $numCriticalResources -gt 0 )
		{
			Log-CriticalResource $criticalMailboxResources
			write-error ($StartDagServerMaintenance_LocalizedStrings.res_0014 -f ( PrintCriticalMailboxResourcesOutput($criticalMailboxResources)),$shortServerName) -erroraction:stop 
		}
		$scriptCompletedSuccessfully = $true;
	}
	finally
	{
		# Rollback only if something failed and Force flag was not used
		if ( !$scriptCompletedSuccessfully)
		{
			if ($Force -ne 'true')
			{
				log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0015 -f "Start-DagServerMaintenance")

				# Create a new script block so that $ErrorActionPreference only
				# affects this scope.
				&{
					# Cleanup code is run with "Continue" ErrorActionPreference
					$ErrorActionPreference = "Continue"
	                
					if ( $pausedNode )
					{
						# Explicitly connect to clussvc running on serverName. This script could
						# easily be run remotely.
						log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0018 -f $serverName,$shortServerName,$serverName);
						if ( $DagScriptTesting )
						{
							write-host ($StartDagServerMaintenance_LocalizedStrings.res_0019 )
						}
						else
						{
							$outputStruct = Call-ClusterExe -dagName $dagName -serverName $serverName -clusterCommand "node $shortServerName /resume"
							$LastExitCode = $outputStruct[ 0 ];
							$output = $outputStruct[ 1 ];
							HandleClusterErrorCode -ClusterErrorCode $LastExitCode -Action "Resume"
						}
					}

					if ( $databasesSuspended )
					{
						if ( $databases )
						{
							# 1. Resume database copy. This clears the ActivationOnly suspension.
							foreach ( $database in $databases )
							{
								log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0024 -f ($database.Name),$shortServerName);
								if ( $DagScriptTesting )
								{
									write-host ($StartDagServerMaintenance_LocalizedStrings.res_0017 -f "resume-mailboxdatabasecopy")
								}
								else
								{
									Resume-MailboxDatabaseCopy "$($database.Name)\$shortServerName" -Confirm:$false
								}
							}
						}
					}
					
					if ( $activationBlockedOnServer )
					{
						log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0016 -f $shortServerName)
						
						if ( $DagScriptTesting )
						{
							write-host ($StartDagServerMaintenance_LocalizedStrings.res_0017 -f "set-mailboxserver")
						}
						else
						{
							Set-MailboxServer -Identity $shortServerName -DatabaseCopyAutoActivationPolicy:Unrestricted
						}
					}
				}
			}
			else
			{
				log-verbose ($StartDagServerMaintenance_LocalizedStrings.res_0027 -f "Start-DagServerMaintenance")
			}
		}		
	}
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/6aCPoC+HfPRI7Vx6qkSSMBK
# Y+OgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJ9hj1lY31MMput+
# 9igVJLNNO206MA0GCSqGSIb3DQEBAQUABIIBAFSPdraFUjcU9b6aJdi37ex6q826
# Q3tbttxjoPEWPM2KeEMJT+TIb5c7qcOIww4vtual83KUG9Mrupqs5giojIyjrbWw
# 12G0HDrG52GMVfsMroNGg0STQh6dufYQgd4HYUTFzlcPdr9a+GesN708L7lHCCzH
# l0OZk0QzSxuyMH7DWacRxY3QvtDUnRAusS8IApfqbB7IviN/80iBudZ0uIDdlwvU
# c6kIkoETcDi2HtTi8PcZWtfMhEHu8ZJKTj5SdLH/zLro8YFCHUNH5hbIKSzy2cEA
# tsgclTmqh6c8VhQT0gXUt0QX1IHJ4x8v71qlWji+9t+fnohUIQA87BUew1k=
# SIG # End signature block
