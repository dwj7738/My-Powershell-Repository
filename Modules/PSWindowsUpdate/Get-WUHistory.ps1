Function Get-WUHistory
{
	<#
	.SYNOPSIS
	    Get list of updates history.

	.DESCRIPTION
	    Use function Get-WUHistory to get list of installed updates on current machine. It works similar like Get-Hotfix.
	       
	.PARAMETER ComputerName	
	    Specify the name of the computer to the remote connection.
 	       
	.PARAMETER Debuger	
	    Debug mode.
		
	.EXAMPLE
		Get updates histry list for sets of remote computers.
		
		PS C:\> "G1","G2" | Get-WUHistory

		ComputerName Date                KB        Title
		------------ ----                --        -----
		G1           2011-12-15 13:26:13 KB2607047 Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2607047)
		G1           2011-12-15 13:25:02 KB2553385 Aktualizacja dla programu Microsoft Office 2010 (KB2553385) wersja 64-bitowa
		G1           2011-12-15 13:24:26 KB2618451 Zbiorcza aktualizacja zabezpieczeñ funkcji Killbit formantów ActiveX w sy...
		G1           2011-12-15 13:23:57 KB890830  Narzêdzie Windows do usuwania z³oœliwego oprogramowania dla komputerów z ...
		G1           2011-12-15 13:17:20 KB2589320 Aktualizacja zabezpieczeñ dla programu Microsoft Office 2010 (KB2589320) ...
		G1           2011-12-15 13:16:30 KB2620712 Aktualizacja zabezpieczeñ systemu Windows 7 dla systemów opartych na proc...
		G1           2011-12-15 13:15:52 KB2553374 Aktualizacja zabezpieczeñ dla programu Microsoft Visio 2010 (KB2553374) w...      
		G2           2011-12-17 13:39:08 KB2563227 Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2563227)
		G2           2011-12-17 13:37:51 KB2425227 Aktualizacja zabezpieczeñ systemu Windows 7 dla systemów opartych na proc...
		G2           2011-12-17 13:37:23 KB2572076 Aktualizacja zabezpieczeñ dla programu Microsoft .NET Framework 3.5.1 w s...
		G2           2011-12-17 13:36:53 KB2560656 Aktualizacja zabezpieczeñ systemu Windows 7 dla systemów opartych na proc...
		G2           2011-12-17 13:36:26 KB979482  Aktualizacja zabezpieczeñ dla systemu Windows 7 dla systemów opartych na ...
		G2           2011-12-17 13:36:05 KB2535512 Aktualizacja zabezpieczeñ systemu Windows 7 dla systemów opartych na proc...
		G2           2011-12-17 13:35:41 KB2387530 Aktualizacja dla systemu Windows 7 dla systemów opartych na procesorach x...
	
	.EXAMPLE  
		Get information about specific installed updates.
	
		PS C:\> $WUHistory = Get-WUHistory
		PS C:\> $WUHistory | Where-Object {$_.Title -match "KB2607047"} | Select-Object *


		KB                  : KB2607047
		ComputerName        : G1
		Operation           : 1
		ResultCode          : 1
		HResult             : -2145116140
		Date                : 2011-12-15 13:26:13
		UpdateIdentity      : System.__ComObject
		Title               : Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2607047)
		Description         : Zainstalowanie tej aktualizacji umo¿liwia rozwi¹zanie problemów w systemie Windows. Aby uzyskaæ p
		                      e³n¹ listê problemów, które zosta³y uwzglêdnione w tej aktualizacji, nale¿y zapoznaæ siê z odpowi
		                      ednim artyku³em z bazy wiedzy Microsoft Knowledge Base w celu uzyskania dodatkowych informacji. P
		                      o zainstalowaniu tego elementu mo¿e byæ konieczne ponowne uruchomienie komputera.
		UnmappedResultCode  : 0
		ClientApplicationID : AutomaticUpdates
		ServerSelection     : 1
		ServiceID           :
		UninstallationSteps : System.__ComObject
		UninstallationNotes : Tê aktualizacjê oprogramowania mo¿na usun¹æ, wybieraj¹c opcjê Wyœwietl zainstalowane aktualizacje
		                       w aplecie Programy i funkcje w Panelu sterowania.
		SupportUrl          : http://support.microsoft.com
		Categories          : System.__ComObject

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc

	.LINK
		Get-WUList
		
	#>
	[OutputType('PSWindowsUpdate.WUHistory')]
	[CmdletBinding(
		SupportsShouldProcess=$True,
		ConfirmImpact="Low"
	)]
	Param
	(
		#Mode options
		[Switch]$Debuger,
		[parameter(ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)]
		[String[]]$ComputerName	
	)

	Begin
	{
		If($PSBoundParameters['Debuger'])
		{
			$DebugPreference = "Continue"
		} #End If $PSBoundParameters['Debuger'] 

		$User = [Security.Principal.WindowsIdentity]::GetCurrent()
		$Role = (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

		if(!$Role)
		{
			Write-Warning "To perform some operations you must run an elevated Windows PowerShell console."	
		} #End If !$Role		
	}
	
	Process
	{
		#region STAGE 0
		Write-Debug "STAGE 0: Prepare environment"
		######################################
		# Start STAGE 0: Prepare environment #
		######################################
		
		Write-Debug "Check if ComputerName in set"
		If($ComputerName -eq $null)
		{
			Write-Debug "Set ComputerName to localhost"
			[String[]]$ComputerName = $env:COMPUTERNAME
		} #End If $ComputerName -eq $null

		####################################
		# End STAGE 0: Prepare environment #
		####################################
		#endregion
		
		$UpdateCollection = @()
		Foreach($Computer in $ComputerName)
		{
			If(Test-Connection -ComputerName $Computer -Quiet)
			{
				#region STAGE 1
				Write-Debug "STAGE 1: Get history list"
				###################################
				# Start STAGE 1: Get history list #
				###################################
		
				If ($pscmdlet.ShouldProcess($Computer,"Get updates history")) 
				{
					Write-Verbose "Get updates history for $Computer"
					If($Computer -eq $env:COMPUTERNAME)
					{
						Write-Debug "Create Microsoft.Update.Session object for $Computer"
						$objSession = New-Object -ComObject "Microsoft.Update.Session" #Support local instance only
					} #End If $Computer -eq $env:COMPUTERNAME
					Else
					{
						Write-Debug "Create Microsoft.Update.Session object for $Computer"
						$objSession =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$Computer))
					} #End Else $Computer -eq $env:COMPUTERNAME

					Write-Debug "Create Microsoft.Update.Session.Searcher object for $Computer"
					$objSearcher = $objSession.CreateUpdateSearcher()
					$TotalHistoryCount = $objSearcher.GetTotalHistoryCount()

					If($TotalHistoryCount -gt 0)
					{
						$objHistory = $objSearcher.QueryHistory(0, $TotalHistoryCount)
						$NumberOfUpdate = 1
						Foreach($obj in $objHistory)
						{
							Write-Progress -Activity "Get update histry for $Computer" -Status "[$NumberOfUpdate/$TotalHistoryCount] $($obj.Title)" -PercentComplete ([int]($NumberOfUpdate/$TotalHistoryCount * 100))

							Write-Debug "Get update histry: $($obj.Title)"
							Write-Debug "Convert KBArticleIDs"
							$matches = $null
							$obj.Title -match "KB(\d+)" | Out-Null
							
							If($matches -eq $null)
							{
								Add-Member -InputObject $obj -MemberType NoteProperty -Name KB -Value ""
							} #End If $matches -eq $null
							Else
							{							
								Add-Member -InputObject $obj -MemberType NoteProperty -Name KB -Value ($matches[0])
							} #End Else $matches -eq $null
							
							Add-Member -InputObject $obj -MemberType NoteProperty -Name ComputerName -Value $Computer
							
							$obj.PSTypeNames.Clear()
							$obj.PSTypeNames.Add('PSWindowsUpdate.WUHistory')
						
							$UpdateCollection += $obj
							$NumberOfUpdate++
						} #End Foreach $obj in $objHistory
						Write-Progress -Activity "Get update histry for $Computer" -Status "Completed" -Completed
					} #End If $TotalHistoryCount -gt 0
					Else
					{
						Write-Warning "Probably your history was cleared. Alternative please run 'Get-WUList -IsInstalled'"
					} #End Else $TotalHistoryCount -gt 0
				} #End If $pscmdlet.ShouldProcess($Computer,"Get updates history")
				
				################################
				# End PASS 1: Get history list #
				################################
				#endregion
				
			} #End If Test-Connection -ComputerName $Computer -Quiet
		} #End Foreach $Computer in $ComputerName	
		
		Return $UpdateCollection
	} #End Process

	End{}	
} #In The End :)
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUs0jIC/LzkNe+A31vGVNGIgso
# dtKgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCDE+Oc2VFdILfxw
# ynGaxQ6yhlkyMA0GCSqGSIb3DQEBAQUABIIBAB1XNbbzhoNd8c+4Mvpl+PQbq0O7
# FSPVkwdgOzDw0aAXiO77mrzR83dPf/IrpTb25I8Deu9YBrIoW/EGQWqDVXnX6uMZ
# W/s98o0u6LmuTYmyJrr0gCNmjhqS4OpkaZhJtn0pXH9jkJhN3ByGItQ8tEj+/B0F
# 7LY+PebYkd1mYe5hQO2dTD6Wa9+jTXP9pOlvtVmqrfXC5OO7ngironALStWs/gjB
# pPkYCwtbN3IhfmDvKlgORCA21zqcMRM2C/k9peC8YoBmlEv8y+U2iBDfUxOrqTgL
# 6vxHjd4a6Rc1g2Y2j8Fuh2+q4OaSSPZdA5AEoGhhHc16DmvEcIxfyHpfTpc=
# SIG # End signature block
