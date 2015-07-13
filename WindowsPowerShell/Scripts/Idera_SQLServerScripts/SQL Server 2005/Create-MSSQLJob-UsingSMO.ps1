## =====================================================================
## Title       : Create-MSSQLJob-UsingSMO
## Description : Create a daily SQL job to call a powershell script
## Author      : Idera
## Date        : 9/1/2008
## Input       : -server <server\instance>
##					  -jobName <jobname>
##               -taskDesc <job description>
##					  -category <job category>
## 				  -hrSched <n - hour military time>
##               -minSched <n - minute military time>
##					  -psScript <path\script.ps1>
## 				  -verbose 
## 				  -debug	
## Output      : SQL Job, job step and schedule for running a PowerShell script
## Usage			: PS> .\Create-MSSQLJob-UsingSMO -server MyServer -jobname MyJob 
## 				         -taskDesc Perform something... -category Backup Job 
## 						   -hrSchedule 2 -psScript C:\TEMP\test.ps1 -minSchedule 0 -verbose -debug
## Notes			: Adapted from an Allen White script
## Tag			: SQL Server, SMO, SQL job
## Change Log  :
## =====================================================================
 
param
(
  	[string]$server = "(local)",
	[string]$jobname = "PowerShellJob",
	[string]$taskDesc = "Perform some task",
	[string]$category = "[Uncategorized (Local)]",
	[string]$psScript = "C:\TEMP\test.ps1",
	[int]$hrSchedule = 2,
	[int]$minSchedule = 0,
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Create-MSSQLJob-UsingSMO $server $jobName $taskDesc $category $psScript $hrSchedule $minSchedule
}

function Create-MSSQLJob-UsingSMO($server, $jobName, $taskDesc, $category, `
									$psScript, $hrSched, $minSched)
{
	# TIP: using PowerShell to create an exception handler
   trap [Exception] 
	{
      write-error $("TRAPPED: " + $_.Exception.Message);
      continue;
   }

	# Load SMO assembly
	[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
	
	# Instantiate SMO server object
	# TIP: instantiate object with parameters
	$namedInstance = new-object ('Microsoft.SqlServer.Management.Smo.Server') ($server)
	
	# Instantiate an Agent Job object, set its properties, and create it
	Write-Debug "Create SQL Agent job ..."
	$job = new-object ('Microsoft.SqlServer.Management.Smo.Agent.Job') ($namedInstance.JobServer, $jobName)
	$job.Description = $taskDesc
	$job.Category = $category
	$job.OwnerLoginName = 'sa'
	
	# Create will fail if job already exists
	#  so don't build the job step or schedule
	if (!$job.Create())
	{
		# Create the step to execute the PowerShell script
		#   and specify that we want the command shell with command to execute script, 
		Write-Debug "Create SQL Agent job step..."
		$jobStep = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobStep') ($job, 'Step 1')
		$jobStep.SubSystem = "CmdExec"
		$runScript = "powershell " + "'" + $psScript + "'"
		$jobStep.Command = $runScript
		$jobStep.OnSuccessAction = "QuitWithSuccess"
		$jobStep.OnFailAction = "QuitWithFailure"
		$jobStep.Create()
		
		# Alter the Job to set the target server and tell it what step should execute first
		Write-Debug "Alter SQL Agent to use designated job step..."
		$job.ApplyToTargetServer($namedInstance.Name)
		$job.StartStepID = $jobStep.ID
		$job.Alter()
	
		# Create start and end timespan objects to use for scheduling
		# TIP: using PowerShell to create a .Net Timespan object
		Write-Debug "Create timespan objects for scheduling the time for 2am..."
		$StartTS = new-object System.Timespan($hrSched, $minSched, 0)
		$EndTS = new-object System.Timespan(23, 59, 59)
		
		# Create a JobSchedule object and set its properties and create the schedule
		Write-Debug "Create SQL Agent Job Schedule..."
		$jobSchedule = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobSchedule') ($job, 'Sched 01')
		$jobSchedule.FrequencyTypes = "Daily"
		$jobSchedule.FrequencySubDayTypes = "Once"
		$jobSchedule.ActiveStartTimeOfDay = $StartTS
		$jobSchedule.ActiveEndTimeOfDay = $EndTS
		$jobSchedule.FrequencyInterval = 1
		$jobSchedule.ActiveStartDate = get-date
		$jobSchedule.Create()
		
		Write-Host SQL Agent Job: $jobName was created
	}
}

main


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/FYBNhxPm+4n10MYvbCmJxeD
# DxagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFIbGNkdPLANdYd1T
# NEp98H62Xe+OMA0GCSqGSIb3DQEBAQUABIIBAChoQwwr12uisNXVc/Qx6C354AHw
# tqNlZzWkF5RHMKilCRqtAGBaa98/erdNX7E1ez3SneNfi05RRSwBXfVKW9RzfgCJ
# UBiP3Ruiuzvxxm5Otlkx4oVTzLMVaLCk0kEf36H80k0VgRuf5nL6tBlrgXRT+Vf/
# 4U+snZrFgq9qCemU9FJ2C7sPB4pEj1OVqiCKliw1tTUi/6YMfhrYTSgfoFqy/7Vl
# NMpqeXRlr0XkWLT4MR1Oe3/MLXZDqKaXBx24rXQYh75qnUDZJSfZKvIiTNl76a69
# BAgpMgThKJY881SaK5B9PSMJhmgERGPL7/WeLCfnAtRz+g81OVBI6jdW7Bw=
# SIG # End signature block
