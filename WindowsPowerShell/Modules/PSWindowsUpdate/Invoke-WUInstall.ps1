Function Invoke-WUInstall
{
	<#
	.SYNOPSIS
		Invoke Get-WUInstall remotely.

	.DESCRIPTION
		Use Invoke-WUInstall to invoke Windows Update install remotly. It Based on TaskScheduler because 
		CreateUpdateDownloader() and CreateUpdateInstaller() methods can't be called from a remote computer - E_ACCESSDENIED.
		
		Note:
		Because we do not have the ability to interact, is recommended use -AcceptAll with WUInstall filters in script block.
	
	.PARAMETER ComputerName
		Specify computer name.

	.PARAMETER TaskName
		Specify task name. Default is PSWindowsUpdate.
		
	.PARAMETER Script
		Specify PowerShell script block that you what to run. Default is {ipmo PSWindowsUpdate; Get-WUInstall -AcceptAll | Out-File C:\PSWindowsUpdate.log}
		
	.EXAMPLE
		PS C:\> $Script = {ipmo PSWindowsUpdate; Get-WUInstall -AcceptAll -AutoReboot | Out-File C:\PSWindowsUpdate.log}
		PS C:\> Invoke-WUInstall -ComputerName pc1.contoso.com -Script $Script
		...
		PS C:\> Get-Content \\pc1.contoso.com\c$\PSWindowsUpdate.log
		
	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/

	.LINK
		Get-WUInstall
	#>
	[CmdletBinding(
		SupportsShouldProcess=$True,
		ConfirmImpact="High"
	)]
	param
	(
		[Parameter(ValueFromPipeline=$True,
					ValueFromPipelineByPropertyName=$True)]
		[String[]]$ComputerName,
		[String]$TaskName = "PSWindowsUpdate",
		[ScriptBlock]$Script = {ipmo PSWindowsUpdate; Get-WUInstall -AcceptAll | Out-File C:\PSWindowsUpdate.log},
		[Switch]$OnlineUpdate
	)

	Begin
	{
		$User = [Security.Principal.WindowsIdentity]::GetCurrent()
		$Role = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

		if(!$Role)
		{
			Write-Warning "To perform some operations you must run an elevated Windows PowerShell console."	
		} #End If !$Role
		
		$PSWUModule = Get-Module -Name PSWindowsUpdate -ListAvailable
		
		Write-Verbose "Create schedule service object"
		$Scheduler = New-Object -ComObject Schedule.Service
			
		$Task = $Scheduler.NewTask(0)

		$RegistrationInfo = $Task.RegistrationInfo
		$RegistrationInfo.Description = $TaskName
		$RegistrationInfo.Author = $User.Name

		$Settings = $Task.Settings
		$Settings.Enabled = $True
		$Settings.StartWhenAvailable = $True
		$Settings.Hidden = $False

		$Action = $Task.Actions.Create(0)
		$Action.Path = "powershell"
		$Action.Arguments = "-Command $Script"
		
		$Task.Principal.RunLevel = 1	
	}
	
	Process
	{
		ForEach($Computer in $ComputerName)
		{
			If ($pscmdlet.ShouldProcess($Computer,"Invoke WUInstall")) 
			{
				if(Test-Connection -ComputerName $Computer -Quiet)
				{
					Write-Verbose "Check PSWindowsUpdate module on $Computer"
					Try
					{
						$ModuleTest = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-Module -ListAvailable -Name PSWindowsUpdate} -ErrorAction Stop
					} #End Try
					Catch
					{
						Write-Warning "Can't access to machine $Computer. Try use: winrm qc"
						Continue
					} #End Catch
					$ModulStatus = $false
					
					if($ModuleTest -eq $null -or $ModuleTest.Version -lt $PSWUModule.Version)
					{
						if($OnlineUpdate)
						{
							Update-WUModule -ComputerName $Computer
						} #End If $OnlineUpdate
						else
						{
							Update-WUModule -ComputerName $Computer	-LocalPSWUSource (Get-Module -ListAvailable -Name PSWindowsUpdate).ModuleBase
						} #End Else $OnlineUpdate
					} #End If $ModuleTest -eq $null -or $ModuleTest.Version -lt $PSWUModule.Version
					
					#Sometimes can't connect at first time
					$Info = "Connect to scheduler and register task on $Computer"
					for ($i=1; $i -le 3; $i++)
					{
						$Info += "."
						Write-Verbose $Info
						Try
						{
							$Scheduler.Connect($Computer)
							Break
						} #End Try
						Catch
						{
							if($i -ge 3)
							{
								Write-Error "Can't connect to Schedule service on $Computer" -ErrorAction Stop
							} #End If $i -ge 3
							else
							{
								sleep -Seconds 1
							} #End Else $i -ge 3
						} #End Catch					
					} #End For $i=1; $i -le 3; $i++
					
					$RootFolder = $Scheduler.GetFolder("\")
					$SendFlag = 1
					if($Scheduler.GetRunningTasks(0) | Where-Object {$_.Name -eq $TaskName})
					{
						$CurrentTask = $RootFolder.GetTask($TaskName)
						$Title = "Task $TaskName is curretly running: $($CurrentTask.Definition.Actions | Select-Object -exp Path) $($CurrentTask.Definition.Actions | Select-Object -exp Arguments)"
						$Message = "What do you want to do?"

						$ChoiceContiniue = New-Object System.Management.Automation.Host.ChoiceDescription "&Continue Current Task"
						$ChoiceStart = New-Object System.Management.Automation.Host.ChoiceDescription "Stop and Start &New Task"
						$ChoiceStop = New-Object System.Management.Automation.Host.ChoiceDescription "&Stop Task"
						$Options = [System.Management.Automation.Host.ChoiceDescription[]]($ChoiceContiniue, $ChoiceStart, $ChoiceStop)
						$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 0)
					
						if($SendFlag -ge 1)
						{
							($RootFolder.GetTask($TaskName)).Stop(0)
						} #End If $SendFlag -eq 1	
						
					} #End If !($Scheduler.GetRunningTasks(0) | Where-Object {$_.Name -eq $TaskName})
						
					if($SendFlag -eq 1)
					{
						$RootFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $Null, 1) | Out-Null
						$RootFolder.GetTask($TaskName).Run(0) | Out-Null
					} #End If $SendFlag -eq 1
					
					#$RootFolder.DeleteTask($TaskName,0)
				} #End If Test-Connection -ComputerName $Computer -Quiet
				else
				{
					Write-Warning "Machine $Computer is not responding."
				} #End Else Test-Connection -ComputerName $Computer -Quiet
			} #End If $pscmdlet.ShouldProcess($Computer,"Invoke WUInstall")
		} #End ForEach $Computer in $ComputerName
		Write-Verbose "Invoke-WUInstall complete."
	}
	
	End {}

}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1zZ3TrRAeM2NoCCdKozHa8PR
# XIWgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKm39B2+fxbQDTDL
# fpUCLlEcw4I9MA0GCSqGSIb3DQEBAQUABIIBAHtZ2ZOaJX/7iOZwFfat4Wj7scEr
# +eOU1Zqsk7CdrthM55n1eZCMJUUEqdp7Lhwpa1s+bSEw8d4Z86QAUL1l/x1aztEM
# x8rOCzs1iSWWkeZBa3VaXC4X5QOL4YtL2wPQkj5c24hHhlsa7dsDlfb64iquVM7/
# w5I6zot1/m83mNNBmadt+Eth6YuYJd+GccP5fdKXPjzcXQE7btfgv4Y/Ig0pbq+R
# foLYsNICVEIJTe4290acHd9iZLRQ6HAIfP5XRT+r4A8oMtVte8QhpvBcrl4qHtIm
# 2MURHIM0LYAg029ivR5NYMoWcwBKzqbqfvGV9nejXf73f/s9cV94TAnPBP8=
# SIG # End signature block
