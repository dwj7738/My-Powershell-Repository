Param(
  [string]$EnvironmentName = "localhost",
  [string]$EnvironmentPort = "81",
  [Parameter(Mandatory=$true)]
  $ActiveFolder,
  [Parameter(Mandatory=$true)]
  $DisabledFolder,
  [int]$MaxConcurrency = 10,
  [switch]$waitForComplete
)

#Ensure that the module path is loaded
$modulePath = "C:\Program Files\SCOrchDev\Modules"
if(-not($Env:PSModulePath -like "*$modulePath*"))
{
	#If the module path is not loaded, add it to the path
	$Env:PSModulePath += ";$modulePath"
}
#Import the scorch webservice module
Import-Module scorch

#Setup a script blog to pass to PowerShell Jobs
$checkRunbook = { 
Param($rb, $WS, $EnvironmentName, $shouldStart)
	try
	{		
		#Ensure that the module path is loaded
		$modulePath = "C:\Program Files\SCOrchDev\Modules"
		if(-not($Env:PSModulePath -like "*$modulePath*"))
		{
			#If the module path is not loaded, add it to the path
			$Env:PSModulePath += ";$modulePath"
		}
		#Import the scorch webservice module
		Import-Module scorch
		
		Write-Host "------------------------------------------------------------------------------------------------------------------------"
		if($shouldStart) { Write-Host "Starting" }
		else { Write-Host "Stopping" } 
		$rb.Path
		Write-Host ""
		
		#load the Runbook Object into this PowerShell instance
		$rb = Get-SCORunbook $WS -RunbookGUID $rb.Id
				
		#check for monitor running
		$monJob = $rb | Get-SCOJob $WS -jobStatus "Running"
		
		if($shouldStart)
		{
			#job is already running
			if(($monJob | Measure-Object).count -gt 0)
			{
				Write-Host "Already running in $EnvironmentName"
			}
			else
			{
				Write-Host "Monitor was not running: Creating new Job"
				
				#start the job for the runbook by path
				$monJob = $rb | Start-SCORunbook $WS
				$rbRunningJobs = $rb | Get-SCOJob $WS -jobStatus "Running"
				
				#wait for the job to start
				while(($rbRunningJobs | Measure-Object).count -gt 0)
				{
					Write-Host -NoNewline .
					$rbRunningJobs = $rb | Get-SCOJob $WS -jobStatus "Running"
				}
			}
		}
		else
		{
			#Monitor is running
			if(($monJob | Measure-Object).count -gt 0)
			{
				Write-Host "Monitor running in $EnvironmentName"

				#If there are more than 1 jobs running wait for all but the 'monitor' to finish
				$givenMessage = $false
				while($monJob.ActiveInstances -gt 1)
				{
					if($givenMessage)
					{
						Write-Host -NoNewline .
					}
					else
					{
						Write-Host "Waiting for jobs to complete in $EnvironmentName"
						Write-Host "Instance Count: "  $monJob.ActiveInstances
						$givenMessage = $true
					}
					#sleep -Seconds 5
					$monJob = $rb | Get-SCOJob $WS -jobStatus "Running" -LoadJobDetails
				}
				if($givenMessage) { Write-Host "" }
				
				Write-Host "Stopping in $EnvironmentName"
				
				#Stop the job			
				$monJob | Stop-SCOJob $WS | Out-Null
				$monJob = $rb | Get-SCOJob $WS -jobStatus "Running"
				
				#wait for job to stop
				while(($monJob | Measure-Object).count -gt 0)
				{
					#update Job Status
					Write-Host -NoNewline .
					$monJob | Stop-SCOJob $WS
					$monJob = $rb | Get-SCOJob $WS -jobStatus "Running" -LoadJobDetails
				}
			}
			else
			{
				Write-Host "Monitor not running"
			}
		}
		Write-Host ""
		Write-Host "------------------------------------------------------------------------------------------------------------------------"
	}
	catch { throw }
}

#setup a variable to hold the webservice URL
$WS = New-SCOWebserverURL $EnvironmentName $EnvironmentPort

Write-Host "Environment:   $WS"
Write-Host ""
Write-Host "Loading $EnvironmentName Monitor Runbooks"

$MonitorRunbooks = Get-SCOMonitorRunbook $WS
$runbooksToStart = @()
$runbooksToStop = @()

foreach($runbook in $MonitorRunbooks)
{
	#Check the runbook for running jobs
	$job = $runbook | Get-SCOJob $WS -jobStatus Running
	
	if(($job | Measure-Object).Count -gt 0)
	{
		#The Runbook is Running
		#Check Path to see if it should be stopped or started
		
		$notFound = $true
		foreach($Path in $ActiveFolder)
		{
			if($runbook.Path.StartsWith($Path))
			{
				#Should be started and is
				$notFound = $false
				break
			}
		}
		if($notFound)
		{
			foreach($Path in $DisabledFolder)
			{
				if($runbook.Path.StartsWith($Path))
				{
					#Should be stopped and isn't
					$runbooksToStop += $runbook
					break
				}
			}
		}
	}
	else
	{
		#The Runbook is not Running
		#Check Path to see if it should be stopped or started
		
		$notFound = $true
		foreach($Path in $ActiveFolder)
		{
			if($runbook.Path.StartsWith($Path))
			{
				#Should be started and isn't
				$notFound = $false
				$runbooksToStart += $runbook
				break
			}
		}
		if($notFound)
		{
			foreach($Path in $DisabledFolder)
			{
				if($runbook.Path.StartsWith($Path))
				{
					#Should be stopped and is
					break
				}
			}
		}
	}
}

if($runbooksToStop.count -gt 0)
{
	Write-Host "Monitors to Stop"
	$runbooksToStop | ft Path
	Write-Host "------------------------------------------------------------------------------------------------------------------------"
	Write-Host "Stopping Monitors"
	foreach($rb in $runbooksToStop)
	{
		$waited = $false
		if((Get-Job -State Running).Count -ge $MaxConcurrency) 
		{ 
			$waited = $true
			Write-Host "Max Concurrent Jobs Reached: Waiting" 
		}
		while((Get-Job -State Running).Count -ge $MaxConcurrency)
		{
			Write-Host -NoNewLine .
			sleep -Milliseconds 333
		}
		if($waited) { Write-Host "" }
		
		Write-Host "Stopping" $rb.Path
		$j = Start-Job -ArgumentList @($rb, $WS, $EnvironmentName, $false) -ScriptBlock $checkRunbook -Name $rb.path
		while($true)
		{
			$state = ($j | Get-Job).State
			if(($state -eq "Running") -or ($state -eq "Completed") -or ($state -eq "Failed"))
			{
				break
			}
		}
	}
	Write-Host "------------------------------------------------------------------------------------------------------------------------"
}

if($runbooksToStart.count -gt 0)
{
	Write-Host "Monitors to Start"
	$runbooksToStart | ft Path
	Write-Host "------------------------------------------------------------------------------------------------------------------------"
	Write-Host "Starting Monitors"
	foreach($rb in $runbooksToStart)
	{
		$waited = $false
		if((Get-Job -State Running).Count -ge $MaxConcurrency) 
		{ 
			$waited = $true
			Write-Host "Max Concurrent Jobs Reached: Waiting" 
		}
		while((Get-Job -State Running).Count -ge $MaxConcurrency)
		{
			Write-Host -NoNewLine .
			sleep -Milliseconds 333
		}
		if($waited) { Write-Host "" }
		
		Write-Host "Starting" $rb.Path
		$j = Start-Job -ArgumentList @($rb, $WS, $EnvironmentName, $true) -ScriptBlock $checkRunbook -Name $rb.path
		while($true)
		{
			$state = ($j | Get-Job).State
			if(($state -eq "Running") -or ($state -eq "Completed") -or ($state -eq "Failed"))
			{
				break
			}
		}
	}
	Write-Host "------------------------------------------------------------------------------------------------------------------------"
}


if($waitForComplete)
{
	Write-Host "------------------------------------------------------------------------------------------------------------------------"
	Write-Host "Waiting for Jobs to Complete"
	$jArray = Get-Job
	Write-Host ""
	Write-Host "Working"
	while($true)
	{
		Write-Host -NoNewline .
		$finishedCount = ($jArray | Get-Job | ? {$_.State -eq "Completed"}).Count
		$finishedCount += ($jArray | Get-Job | ? {$_.State -eq "Failed"}).Count
		if($finishedCount -eq $jArray.Count) { break }
		sleep -Milliseconds 333
	}
	Write-Host ""
	Write-Host "------------------------------------------------------------------------------------------------------------------------"
	foreach($j in Get-Job -State Completed)
	{
		Receive-Job $j
		Remove-Job $j
	}
	Write-Host ""
	Get-Job
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUMjo7EfW7sqFghCNsNVhheBCn
# mhqgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPYSigEEtHdsqlsW
# pW0mkSblr+42MA0GCSqGSIb3DQEBAQUABIIBAEatrr/ypvOumCH3RYGyLM3CbbJr
# 2XHsVp4AipOH1OpdFLWSAePf/II6XNPY/GwkmIazxdphDtRuI1PIwoIYcoWZ/X1Y
# qYtIOpvN/WGO8wMDHZiFalhDojQ2KNmiIdwI1f8kkyR99cy8M/BbJBF7mCScHqV7
# +9aL1bl3t9Cjr8dxDFvzNb4lyQN32m7iKQvKb6RiAw7kZduRwCjRZ7r7MMWezjjF
# PlVMepbs5B+eY+tPgw3jdJsLuPwJKu6tIO3yLod+oTiTryyQdjtKo8MIWLL8fEKD
# nXLLD5dKVeq7KoCL8vuMsMWhKVlM7+IDrJCFS1zqqXuVfMoDE6vhV2znNJM=
# SIG # End signature block
