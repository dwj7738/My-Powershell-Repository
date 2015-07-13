<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2014 v4.1.58
	 Created on:   	6/9/2014 1:57 PM
	 Created by:   	Adam Bertram
	 Filename:     	CMClient.psm1
	-------------------------------------------------------------------------
	 Module Name: CMClient
	===========================================================================
#>
#region Invoke-CMClientAction
<#
.SYNOPSIS
	This is a helper function that initiates many ConfigMgr client actions.
.DESCRIPTION

.PARAMETER  Computername
	The system you'd like to initate the action on.
.PARAMETER  AsJob
	A switch parameter that initates a job in the background
.PARAMETER  ClientAction
	The client action to initiate.
.EXAMPLE
	PS C:\> Invoke-CMClientAction -Computername 'Value1' -AsJob
	This example shows how to call the Invoke-CMClientAction function with named parameters.
.NOTES
#>
function Invoke-CMClientAction {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$Computername,
		[Parameter(Mandatory = $true)]
		[ValidateSet('MachinePolicy',
			'DiscoveryData',
			'ComplianceEvaluation',
			'AppDeployment', 
			'HardwareInventory',
			'UpdateDeployment',
			'UpdateScan',
			'SoftwareInventory')]
		[string]$ClientAction,
		[Parameter()]
		[switch]$AsJob
	)
	
	Begin {
		try {
			$ScheduleIDMappings = @{
				'MachinePolicy' = '{00000000-0000-0000-0000-000000000021}';
				'DiscoveryData' = '{00000000-0000-0000-0000-000000000003}';
				'ComplianceEvaluation' = '{00000000-0000-0000-0000-000000000071}';
				'AppDeployment' = '{00000000-0000-0000-0000-000000000121}';
				'HardwareInventory' = '{00000000-0000-0000-0000-000000000001}';
				'UpdateDeployment' = '{00000000-0000-0000-0000-000000000108}';
				'UpdateScan' = '{00000000-0000-0000-0000-000000000113}';
				'SoftwareInventory' = '{00000000-0000-0000-0000-000000000002}';
			}
			$ScheduleID = $ScheduleIDMappings[$ClientAction]
		} catch {
			Write-Error $_.Exception.Message
		}
		
	}
	Process {
		try {
			## Args1 represents the computername and $args[1] represents the scheduleID
			$ActionScriptBlock = {
				[void] ([wmiclass] "\\$($args[0])\root\ccm:SMS_Client").TriggerSchedule($args[1]);
				if (!$?) {
					throw "Failed to initiate a $ClientAction on $($args[0])"
				}
			}
			
			if ($AsJob.IsPresent) {
				$Params = @{
					'Computername' = $Computername;
					'OriginatingFunction' = $ClientAction;
					'ScriptBlock' = $ActionScriptBlock;
					'ScheduleID' = $ScheduleID
				}
				Initialize-CMClientJob @Params
			} else {
				Invoke-Command -ScriptBlock $ActionScriptBlock -ArgumentList $Computername,$ScheduleID
			}
		} catch {
			Write-Error $_.Exception.Message
		}
		
	}
	End {
		
	}
}
#endregion

#region Initialize-CMClientJob
<#
.SYNOPSIS
	This is a helper function that starts and manages background jobs for the all
	functions in this module.
.DESCRIPTION

.PARAMETER  OriginatingFunction
	The function where the job request came from.  This is used to keep track of
	which background jobs were started by which function.
.PARAMETER  ScriptBlock
	This is the scriptblock that is passed to the system.
.PARAMETER  Computername
	The computer name that the function is connecting to.  This is used to keep track
	of the functions initiated on computers.
.PARAMETER  ScheduleID
	This is the schedule ID to designate which client action to initiate.  This is needed
	because it has to be sent to the background job scriptblock.
.EXAMPLE

.NOTES
#>
function Initialize-CMClientJob {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$OriginatingFunction,
		[Parameter(Mandatory = $true)]
		[scriptblock]$ScriptBlock,
		[Parameter(Mandatory = $true)]
		[string]$Computername,
		[Parameter(Mandatory = $true)]
		[string]$ScheduleID
	)
	
	Begin {
		## The total number of jobs that can be concurrently running
		$MaxJobThreads = 75
		## How long to wait when the max job threads has been met to start another job
		$JobWaitSecs = 1
	}
	Process {
		try {
			Write-Verbose "Starting job `"$ComputerName - $OriginatingFunction`"..."
			Start-Job -ScriptBlock $ScriptBlock -Name "$ComputerName - $OriginatingFunction" -ArgumentList $Computername, $ScheduleID | Out-Null
			While ((Get-Job -state running).count -ge $MaxJobThreads) {
				Write-Verbose "Maximum job threshold has been met.  Waiting $JobWaitSecs second(s) to try again...";
				Start-Sleep -Seconds $JobWaitSecs
			}			
		} catch {
			Write-Error $_.Exception.Message
		}
	}
	End {
		
	}
}
#endregion

#region Invoke-CMClientMachinePolicyDownload
<#
.SYNOPSIS
	This function invokes a machine policy download on a ConfigMgr client
.DESCRIPTION

.PARAMETER  Computername
	The name of the system you'd like to invoke the machine policy download on
.PARAMETER  AsJob
	Specify this parameter if you'd like to run this as a background job.
.EXAMPLE
	PS C:\> Invoke-CMClientMachinePolicyDownload -Computername 'Value1' -AsJob
.NOTES

#>
function Invoke-CMClientMachinePolicyDownload {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[alias('Name')]
		[string]$Computername,
		[Parameter()]
		[switch]$AsJob
	)
	
	Begin {
		
	}
	Process {
		$Params = @{
			'Computername'	= $Computername;
			'ClientAction'  = 'MachinePolicy';
			'AsJob'			= $AsJob.IsPresent
		}
		Invoke-CMClientAction @Params
	}
	End {
		
	}
}
#endregion

#region Invoke-CMClientDiscoveryDataCycle
<#
.SYNOPSIS
	This function invokes a DDR cycle on a ConfigMgr client
.DESCRIPTION

.PARAMETER  Computername
	The name of the system you'd like to invoke the action on
.PARAMETER  AsJob
	Specify this parameter if you'd like to run this as a background job.
.EXAMPLE
	PS C:\> Invoke-CMClientDiscoveryDataCycle -Computername 'Value1' -AsJob
.NOTES

#>
function Invoke-CMClientDiscoveryDataCycle {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[string]$Computername,
		[Parameter()]
		[switch]$AsJob
	)
	
	Begin {
		
	}
	Process {
		$Params = @{
			'Computername' = $Computername;
			'ClientAction' = 'DiscoveryData';
			'AsJob' = $AsJob.IsPresent
		}
		Invoke-CMClientAction @Params
	}
	End {
		
	}
}
#endregion

#region Invoke-CMClientComplianceEvaluation
<#
.SYNOPSIS
	This function invokes a compliance evaluation on a ConfigMgr client
.DESCRIPTION

.PARAMETER  Computername
	The name of the system you'd like to invoke the action on
.PARAMETER  AsJob
	Specify this parameter if you'd like to run this as a background job.
.EXAMPLE
	PS C:\> Invoke-CMClientComplianceEvaluation -Computername 'Value1' -AsJob
.NOTES

#>
function Invoke-CMClientComplianceEvaluation {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[string]$Computername,
		[Parameter()]
		[switch]$AsJob
	)
	
	Begin {
		
	}
	Process {
		$Params = @{
			'Computername' = $Computername;
			'ClientAction' = 'ComplianceEvaluation';
			'AsJob' = $AsJob.IsPresent
		}
		Invoke-CMClientAction @Params
	}
	End {
		
	}
}
#endregion

#region Invoke-CMClientApplicationDeploymentEvaluation
<#
.SYNOPSIS
	This function invokes an application deployment eval on a ConfigMgr client
.DESCRIPTION

.PARAMETER  Computername
	The name of the system you'd like to invoke the action on
.PARAMETER  AsJob
	Specify this parameter if you'd like to run this as a background job.
.EXAMPLE
	PS C:\> Invoke-CMClientApplicationDeploymentEvaluation -Computername 'Value1' -AsJob
.NOTES

#>
function Invoke-CMClientApplicationDeploymentEvaluation {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[string]$Computername,
		[Parameter()]
		[switch]$AsJob
	)
	
	Begin {
		
	}
	Process {
		$Params = @{
			'Computername' = $Computername;
			'ClientAction' = 'AppDeployment';
			'AsJob' = $AsJob.IsPresent
		}
		Invoke-CMClientAction @Params
	}
	End {
		
	}
}
#endregion

#region Invoke-CMClientHardwareInventory
<#
.SYNOPSIS
	This function invokes a hardware inventory cycle on a ConfigMgr client
.DESCRIPTION

.PARAMETER  Computername
	The name of the system you'd like to invoke the action on
.PARAMETER  AsJob
	Specify this parameter if you'd like to run this as a background job.
.EXAMPLE
	PS C:\> Invoke-CMClientHardwareInventory -Computername 'Value1' -AsJob
.NOTES

#>
function Invoke-CMClientHardwareInventory {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[string]$Computername,
		[Parameter()]
		[switch]$AsJob
	)
	
	Begin {
		
	}
	Process {
		$Params = @{
			'Computername' = $Computername;
			'ClientAction' = 'HardwareInventory';
			'AsJob' = $AsJob.IsPresent
		}
		Invoke-CMClientAction @Params
	}
	End {
		
	}
}
#endregion

#region Invoke-CMClientUpdateDeploymentEvaluation
<#
.SYNOPSIS
	This function invokes an update deployment eval on a ConfigMgr client
.DESCRIPTION

.PARAMETER  Computername
	The name of the system you'd like to invoke the action on
.PARAMETER  AsJob
	Specify this parameter if you'd like to run this as a background job.
.EXAMPLE
	PS C:\> Invoke-CMClientUpdateDeploymentEvaluation -Computername 'Value1' -AsJob
.NOTES

#>
function Invoke-CMClientUpdateDeploymentEvaluation {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[string]$Computername,
		[Parameter()]
		[switch]$AsJob
	)
	
	Begin {
		
	}
	Process {
		$Params = @{
			'Computername' = $Computername;
			'ClientAction' = 'UpdateDeployment';
			'AsJob' = $AsJob.IsPresent
		}
		Invoke-CMClientAction @Params
	}
	End {
		
	}
}
#endregion

#region Invoke-CMClientUpdateScan
<#
.SYNOPSIS
	This function invokes an update scan eval on a ConfigMgr client
.DESCRIPTION

.PARAMETER  Computername
	The name of the system you'd like to invoke the action on
.PARAMETER  AsJob
	Specify this parameter if you'd like to run this as a background job.
.EXAMPLE
	PS C:\> Invoke-CMClientUpdateScan -Computername 'Value1' -AsJob
.NOTES

#>
function Invoke-CMClientUpdateScan {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[string]$Computername,
		[Parameter()]
		[switch]$AsJob
	)
	
	Begin {
		
	}
	Process {
		$Params = @{
			'Computername' = $Computername;
			'ClientAction' = 'UpdateScan';
			'AsJob' = $AsJob.IsPresent
		}
		Invoke-CMClientAction @Params
	}
	End {
		
	}
}
#endregion

#region Invoke-CMClientSoftwareInventory
<#
.SYNOPSIS
	This function invokes a software inventory scan on a ConfigMgr client
.DESCRIPTION

.PARAMETER  Computername
	The name of the system you'd like to invoke the action on
.PARAMETER  AsJob
	Specify this parameter if you'd like to run this as a background job.
.EXAMPLE
	PS C:\> Invoke-CMClientSoftwareInventory -Computername 'Value1' -AsJob
.NOTES

#>
function Invoke-CMClientSoftwareInventory {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true)]
		[string]$Computername,
		[Parameter()]
		[switch]$AsJob
	)
	
	Begin {
		
	}
	Process {
		$Params = @{
			'Computername' = $Computername;
			'ClientAction' = 'SoftwareInventory';
			'AsJob' = $AsJob.IsPresent
		}
		Invoke-CMClientAction @Params
	}
	End {
		
	}
}
#endregion

## Modify these function as advanced functions
<#
Function Set-CMClientBusinessHours ($ComputerName, $StartTime = 3, $EndTime = 7, $WorkingDays) {
	## The first digit is the start time (7am), the second digit is the end time (7pm) and the third digit is the days of the week.
	## The days of the week are calculated using the table below, so Monday – Friday is calculated as 2+4+8+16+32 = 62.
	## Sunday - 1, Monday - 2, Tuesday - 4, Wednesday - 8, Thursday - 16, Friday - 32, Saturday - 64
	
	try {
		Write-Debug "Initiating the $($MyInvocation.MyCommand.Name) function...";
		
		$cmClientUserSettings = [WmiClass]"\\$ComputerName\ROOT\ccm\ClientSDK:CCM_ClientUXSettings"
		$businessHours = $cmClientUserSettings.PSBase.GetMethodParameters("SetBusinessHours")
		$businessHours.StartTime = $StartTime
		$businessHours.EndTime = $EndTime
		$businessHours.WorkingDays = $WorkingDays
		
		$result = $cmClientUserSettings.PSBase.InvokeMethod("SetBusinessHours", $businessHours, $Null)
		
		if ($result.ReturnValue -eq 0) {
			$mResult = $true
		} else {
			$mResult = $false;
		}
		
		return $mResult
		
	} catch [System.Exception] {
		Write-Error $_.Exception.Message;
	}##endtry
}##endfunction

Function Get-CMClientBusinessHours ($ComputerName) {
	## The first digit is the start time (7am), the second digit is the end time (7pm) and the third digit is the days of the week.
	## The days of the week are calculated using the table below, so Monday – Friday is calculated as 2+4+8+16+32 = 62.
	## Sunday - 1, Monday - 2, Tuesday - 4, Wednesday - 8, Thursday - 16, Friday - 32, Saturday - 64
	
	try {
		Write-Debug "Initiating the $($MyInvocation.MyCommand.Name) function...";
		
		$cmClientUserSettings = [WmiClass]"\\$ComputerName\ROOT\ccm\ClientSDK:CCM_ClientUXSettings"
		$businessHours = $cmClientUserSettings.GetBusinessHours()
		$businessHoursCI = [string]$businessHours.StartTime + "," + [string]$businessHours.EndTime + "," + [string]$businessHours.WorkingDays
		
		return $businessHoursCI
		
	} catch [System.Exception] {
		Write-Error $_.Exception.Message;
	}##endtry
}##endfunction

Function Disable-CMClientBusinessHours ($ComputerName) {
	try {
		## Change the "automatic install or uninstall required software and restart the computer only outside of the specified business hours
		
		return $mResult
		
	} catch [System.Exception] {
		Write-Error $_.Exception.Message;
	}##endtry
}##endfunction

Function Get-SccmApplicationState ($ComputerName,$Name = $null,[switch]$IncludeDetails) {
	try {
		Write-Debug "Initiating the $($MyInvocation.MyCommand.Name) function...";
        
        $eval_states = @{0 = 'No state information is available';
                        1 = 'Application is enforced to desired/resolved state';
                        2 = 'Application is not required on the client';
                        3 = 'Application is available for enforcement (install or uninstall based on resolved state). Content may/may not have been downloaded';
                        4 = 'Application last failed to enforce (install/uninstall)';
                        5 = 'Application is currently waiting for content download to complete';
                        6 = 'Application is currently waiting for content download to complete';
                        7 = 'Application is currently waiting for its dependencies to download';
                        8 = 'Application is currently waiting for a service (maintenance) window';
                        9 = 'Application is currently waiting for a previously pending reboot';
                        10 = 'Application is currently waiting for serialized enforcement';
                        11 = 'Application is currently enforcing dependencies';
                        12 = 'Application is currently enforcing';
                        13 = 'Application install/uninstall enforced and soft reboot is pending';
                        14 = 'Application installed/uninstalled and hard reboot is pending';
                        15  = 'Update is available but pending installation';
                        16 = 'Application failed to evaluate';
                        17 = 'Application is currently waiting for an active user session to enforce';
                        18 = 'Application is currently waiting for all users to logoff';
                        19 = 'Application is currently waiting for a user logon';
                        20 = 'Application in progress, waiting for retry';
                        21 = 'Application is waiting for presentation mode to be switched off';
                        22 = 'Application is pre-downloading content (downloading outside of install job)';
                        23 = 'Application is pre-downloading dependent content (downloading outside of install job)';
                        24 = 'Application download failed (downloading during install job)';
                        25 = 'Application pre-downloading failed (downloading outside of install job)';
                        26 = 'Download success (downloading during install job)';
                        27 = 'Post-enforce evaluation';
                        28 = 'Waiting for network connectivity';
                    }

        if ($Name -and $IncludeDetails.IsPresent) {
            $aApps = Request-Wmi -ComputerName $ComputerName -Namespace 'root\ccm\clientsdk' -Query "SELECT * FROM CCM_Application WHERE FullName = '$Name'"
        } elseif ($Name -and !$IncludeDetails.IsPresent) {
            $aApps = Request-Wmi -ComputerName $ComputerName -Namespace 'root\ccm\clientsdk' -Query "SELECT * FROM CCM_Application WHERE FullName = '$Name'" | Select-Object PSComputerName,FullName,InstallState,ErrorCode,EvaluationState,@{label='StartTime';expression={$_.ConvertToDateTime($_.StartTime)}}
        } elseif (!$Name -and $IncludeDetails.IsPresent) {
            $aApps = Request-Wmi -ComputerName $ComputerName -Namespace 'root\ccm\clientsdk' -Query "SELECT * FROM CCM_Application"
        } elseif (!$Name -and !$IncludeDetails.IsPresent) {
            $aApps = Request-Wmi -ComputerName $ComputerName -Namespace 'root\ccm\clientsdk' -Query "SELECT * FROM CCM_Application" | Select-Object PSComputerName,FullName,InstallState,ErrorCode,EvaluationState,@{label='StartTime';expression={$_.ConvertToDateTime($_.StartTime)}}
        }
		
        if (!$aApps) {
			$mResult = "$($MyInvocation.MyCommand.Name): WMI query failed";
		} else {
			$mResult = $aApps | Sort-Object FullName;
		}##endif
		
		return $mResult;
		
	} catch [System.Exception] {
		Write-Error $_.Exception.Message;
	}##endtry
}##endfunction

Function Get-CMClientUpdateDeploymentState() {

}
#>

Export-ModuleMember Invoke-CMClientUpdateScan
Export-ModuleMember Invoke-CMClientUpdateDeploymentEvaluation
Export-ModuleMember Invoke-CMClientHardwareInventory
Export-ModuleMember Invoke-CMClientApplicationDeploymentEvaluation
Export-ModuleMember Invoke-CMClientComplianceEvaluation
Export-ModuleMember Invoke-CMClientDiscoveryDataCycle
Export-ModuleMember Invoke-CMClientMachinePolicyDownload
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxwLnTVWLPsIbAFsWmtYsvfMr
# /sagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJBJv9C344H/YP1s
# 1jf51D9snfueMA0GCSqGSIb3DQEBAQUABIIBAGT2IOg+Onxx17MZrTLGeHxspns2
# d7ykkvJwhqbM8Uy8q2Q3ulrFwH++c2qV2YqbLrw60OLMK5feJ5VGnLcksY3hWon2
# Krh4lzgfW13yqGah5jL0drL+9cIrE38PxXz97AUOOXhw2LDXO4PHG+CzcwUXcjx6
# ankKcPe173IYkkW7V9tbkvc1+LGyFvBX5YKPRK74EZkd06aZgxKW5HULzEqDZueT
# dkFS9pwTzjEiE2zV6g/nOYKKOJCEItY8FO+1YqHBaeDlUXVgsbdtn8alX9geENwM
# yoCzrWHHquwO5+HrjizCOqGjdq7ivJRiZHc3Mrr/Lm2fh6dPHg8G63Ctqsw=
# SIG # End signature block
