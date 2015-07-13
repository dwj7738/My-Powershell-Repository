# ==============================================================================================
# NAME:			Change-ServiceAcct
# AUTHOR:		Brian Hagerty
# DATE:			03/04/2009
# COMMENT: 		Changes service account properties for the specified computer(s)
# MODIFIED:		
# ==============================================================================================

function Change-ServiceAcct ([string]$ServiceName, $DisplayName = $null, $PathName = $null, $ServiceType = $null, $ErrorControl = $null, $StartMode = $null, $DesktopInteract = $true, [string]$StartName, [string]$StartPassword, $LoadOrderGroup = $Null, $LoadOrderGroupDependencies = $Null, $ServiceDependencies = $Null, [switch]$GrantNTRights) {
	BEGIN { 
		# Display help content, if -? is specified at command line
		if ($args -contains '-?') {
			ChangeServiceAccountHelp
			break
		}
		if($ServiceName -eq $([regex]"[A-z0-9]")) {Throw "A service name must be specified"}
	}
	PROCESS {
		Test-Pipeline # Ensures valid pipeline input is specified
		$computer = $_ # Store incoming computer name from pipeline for readability

		$service = Get-WmiObject -ComputerName $computer -Class WIN32_Service | Where-Object {$_.Name -match $ServiceName}
		$OriginalServiceState = $($service.State)

		if($service -eq $Null) {Throw "The service $ServiceName, does not exist on $computer"}
		else {
			if($service.State -eq "Started") { 
				Write-Host -ForegroundColor Green "`n`nComputer: $computer"
				Write-Host -ForegroundColor Yellow "Service $($service.Name) is started, stopping the service..."
				$service.StopService()

				Write-Host -ForegroundColor Cyan "`nApplying changes to the service $($service.Name)..."
				$returnCode = $($service.Change($DisplayName,$PathName,$ServiceType,$ErrorControl,$StartMode,$DesktopInteract,$StartName,$StartPassword,$LoadOrderGroup,$LoadOrderGroupDependencies,$ServiceDependencies)).ReturnValue

				if($GrantNTRights.IsPresent) { GrantNTRights $StartName $computer }

				ReturnCodeTest $returnCode $OriginalServiceState
			} else {
				Write-Host -ForegroundColor Green "`n`nComputer: $computer"
				Write-Host -ForegroundColor Yellow "Service $($service.Name) is stopped, continuing..."

				Write-Host -ForegroundColor Cyan "Applying changes to the service $($service.Name)..."
				$returnCode = $($service.Change($DisplayName,$PathName,$ServiceType,$ErrorControl,$StartMode,$DesktopInteract,$StartName,$StartPassword,$LoadOrderGroup,$LoadOrderGroupDependencies,$ServiceDependencies)).ReturnValue

				if($GrantNTRights.IsPresent) { GrantNTRights $StartName $computer }

				ReturnCodeTest $returnCode $OriginalServiceState
			}
		}
	}
}

function GrantNTRights ([string]$user, [string]$computer) {
	$NTRights = 'C:\Program` Files\Windows` Resource Kits\Tools\ntrights.exe'
	$NTRightsCmd = $NTRights + " -u $user -m \\$computer +r SeServiceLogonRight"
	Invoke-Expression $NTRightsCmd
}

function ReturnCodeTest ([int]$returnCode, [string]$OriginalServiceState) {
	if ($returnCode -eq 0) {
		if($OriginalServiceState -eq "Started") {
			Write-Host -ForegroundColor Cyan "Service was originally started, restarting service: $($service.Name)"
			$service.StartService()
		}
		else { Write-Host -ForegroundColor Cyan "Service was not originally started, not restarting service: $($service.Name)" }
	}
	else { ReturnCodeSwitch $returnCode }
}

function ReturnCodeSwitch ([int]$returnCode) {
	switch ($returnCode) {
		1 {Write-Host -ForegroundColor Red "Not Supported"; break}
		2 {Write-Host -ForegroundColor Red "Access Denied"; break}
		3 {Write-Host -ForegroundColor Red "Dependent Services Running"; break}
		4 {Write-Host -ForegroundColor Red "Invalid Service Control"; break}
		5 {Write-Host -ForegroundColor Red "Service Cannot Accept Control"; break}
		6 {Write-Host -ForegroundColor Red "Service Not Active"; break}
		7 {Write-Host -ForegroundColor Red "Service Request Timeout"; break}
		8 {Write-Host -ForegroundColor Red "Unknown Failure"; break}
		9 {Write-Host -ForegroundColor Red "Path Not Found"; break}
		10 {Write-Host -ForegroundColor Red "Service Already Running"; break}
		11 {Write-Host -ForegroundColor Red "Service Database Locked"; break}
		12 {Write-Host -ForegroundColor Red "Service Dependency Deleted"; break}
		13 {Write-Host -ForegroundColor Red "Service Dependency Failure"; break}
		14 {Write-Host -ForegroundColor Red "Service Disabled"; break}
		15 {Write-Host -ForegroundColor Red "Service Logon Failure"; break}
		16 {Write-Host -ForegroundColor Red "Service Marked For Deletion"; break}
		17 {Write-Host -ForegroundColor Red "Service No Thread"; break}
		18 {Write-Host -ForegroundColor Red "Status Circular Dependency"; break}
		19 {Write-Host -ForegroundColor Red "Status Duplicate Name"; break}
		20 {Write-Host -ForegroundColor Red "Status Invalid Name"; break}
		21 {Write-Host -ForegroundColor Red "Status Invalid Parameter"; break}
		22 {Write-Host -ForegroundColor Red "Status Invalid Service Account"; break}
		23 {Write-Host -ForegroundColor Red "Status Service Exists"; break}
		24 {Write-Host -ForegroundColor Red "Service Already Paused"; break}
	}
}

# ==============================================================================================
# NAME:			ChangeServiceAccountHelp
# AUTHOR:		Brian Hagerty
# DATE:			03/03/2009
# COMMENT: 		Help function for the Change-ServiceAcct function
# MODIFIED:		
# ==============================================================================================

function ChangeServiceAccountHelp {
	Write-Host -ForegroundColor Yellow "`n`nPURPOSE: Pipeline function! Accepts computer names from pipeline & changes specific properties for the specified service account."
	Write-Host -ForegroundColor Cyan "`nSYNTAX: $computername_array [[string]computerName] | Change-ServiceAcct [string]ServiceName [[string]DisplayName [string]PathName [byte]ServiceType [byte]ErrorControl [string]StartMode [boolean]DesktopInteract [string]StartName [string]StartPassword [string]LoadOrderGroup [string[]]LoadOrderGroupDependencies [string[]]ServiceDepencies"

	Write-Host -ForegroundColor Cyan "`n`nDisplayName :"
	Write-Host -ForegroundColor Green "The display name of the service. This string has a maximum length of 256 characters. The name is case-preserved in the service control manager. DisplayName comparisons are always case-insensitive."
	Write-Host -ForegroundColor Yellow "Example :  ""Atdisk"""

	Write-Host -ForegroundColor Cyan "`n`nPathName :"
	Write-Host -ForegroundColor Green "The fully-qualified path to the executable file that implements the service."
	Write-Host -ForegroundColor Yellow "Example :  ""\SystemRoot\System32\drivers\afd.sys"""

	Write-Host -ForegroundColor Cyan "`n`nServiceType:"
	Write-Host -ForegroundColor Green "The type of services provided to processes that call them."
	Write-Host -ForegroundColor Yellow "`nValues [Value - Meaning]:"
	Write-Host -ForegroundColor Yellow "------------------------------------------"
	Write-Host -ForegroundColor Yellow "10x1 - Kernel Driver"
	Write-Host -ForegroundColor Yellow "20x2 - File System Driver"
	Write-Host -ForegroundColor Yellow "40x4 - Adapter"
	Write-Host -ForegroundColor Yellow "80x8 - Recognizer Driver"
	Write-Host -ForegroundColor Yellow "160x10 - Own Process"
	Write-Host -ForegroundColor Yellow "320x20 - Share Process"
	Write-Host -ForegroundColor Yellow "2560x100 - Interactive Process"

	Write-Host -ForegroundColor Cyan "`n`nErrorControl :"
	Write-Host -ForegroundColor Green "Severity of the error if this service fails to start during startup. The value indicates the action taken by the startup program if failure occurs. All errors are logged by the system."
	Write-Host -ForegroundColor Yellow "`nValues [Value - Meaning]:"
	Write-Host -ForegroundColor Yellow "------------------------------------------"
	Write-Host -ForegroundColor Yellow "0 - Ignore. User is not notified."
	Write-Host -ForegroundColor Yellow "1 - Normal. User is notified."
	Write-Host -ForegroundColor Yellow "2 - Severe. System is restarted with the last-known-good configuration."
	Write-Host -ForegroundColor Yellow "3 - Critical. System attempts to restart with a good configuration."


	Write-Host -ForegroundColor Cyan "`n`nStartMode:" 
	Write-Host -ForegroundColor Green "Start mode of the Windows base service."
	Write-Host -ForegroundColor Yellow "`nValues [Value - Meaning]:"
	Write-Host -ForegroundColor Yellow "------------------------------------------"
	Write-Host -ForegroundColor Yellow "Boot - Device driver started by the operating system loader."
	Write-Host -ForegroundColor Yellow "System - Device driver started by the operating system initialization process. Valid only for driver services."
	Write-Host -ForegroundColor Yellow "Automatic - Service to be started automatically by the service control manager during system startup."
	Write-Host -ForegroundColor Yellow "Manual - Service to be started by the service control manager when a process calls the StartService method."
	Write-Host -ForegroundColor Yellow "Disabled - Service that can no longer be started."

	Write-Host -ForegroundColor Cyan "`n`nDesktopInteract:"
	Write-Host -ForegroundColor Green "If true, the service can create or communicate with a window on the desktop."

	Write-Host -ForegroundColor Cyan "`n`nStartName:"
	Write-Host -ForegroundColor Green "Account name the service runs under. Depending on the service type, the account name may be in the form of DomainName\Username or .\Username. The service process will be logged using one of these two forms when it runs. If the account belongs to the built-in domain, .\Username can be specified. If NULL is specified, the service will be logged on as the LocalSystem account. For kernel or system-level drivers, StartName contains the driver object name (that is, \FileSystem\rdr or \Driver\Xns) that the input and output (I/O) system uses to load the device driver. If NULL is specified, the driver runs with a default object name created by the I/O system based on the service name, for example, ""DWDOM\Admin"". You also can use the User Principal Name (UPN) format to specify the StartName, for example, Username@DomainName."

	Write-Host -ForegroundColor Cyan "`n`nStartPassword:"
	Write-Host -ForegroundColor Green "Password to the account name specified by the StartName parameter. Specify NULL if you are not changing the password. Specify an empty string if the service has no password. (Note:  When changing a service from a local system to a network, or from a network to a local system, StartPassword must be an empty string ("""") and not NULL.)"

	Write-Host -ForegroundColor Cyan "`n`nLoadOrderGroup:"
	Write-Host -ForegroundColor Green "Group name that it is associated with. Load order groups are contained in the system registry, and determine the sequence in which services are loaded into the operating system. If the pointer is NULL, or if it points to an empty string, the service does not belong to a group. Dependencies between groups should be listed in the LoadOrderGroupDependencies parameter. Services in the load-ordering group list are started first, followed by services in groups not in the load-ordering group list, followed by services that do not belong to a group. The system registry has a list of load ordering groups located at HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\ServiceGroupOrder."

	Write-Host -ForegroundColor Cyan "`n`nLoadOrderGroupDependencies:"
	Write-Host -ForegroundColor Green "List of load-ordering groups that must start before this service starts. The array is doubly null-terminated. If the pointer is NULL, or if it points to an empty string, the service has no dependencies. Group names must be prefixed by the SC_GROUP_IDENTIFIER (defined in the Winsvc.h file) character to differentiate them from service names because services and service groups share the same name space. Dependency on a group means that this service can run if at least one member of the group is running after an attempt to start all of the members of the group."

	Write-Host -ForegroundColor Cyan "`n`nServiceDependencies:"
	Write-Host -ForegroundColor Green "List that contains the names of services that must start before this service starts. The array is doubly NULL-terminated. If the pointer is NULL, or if it points to an empty string, the service has no dependencies. Dependency on a service indicates that this service can run only if the service it depends on is running."
	Write-Host
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQR8w/HfEkHnIZuQHLKkkum42
# dVSgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKUQdokG3zGtllsr
# WRPGI1tw349+MA0GCSqGSIb3DQEBAQUABIIBAEkQ80Eu92jrfri2GLC6slhE5Q2z
# o3JzNIlbpaSGuv2Cw8zFC/2pMYagUG/kluSvMdrgmJe+MWkHGCmvMNDr8pjNY9Dn
# TLEjkhzpYjnK27XtuGP/+OIwC5oHVbNwfjsaRYUQrjyvn//kGHG4pQKTycCZGUxo
# gCWi/uaqBsCnxcWmpNIMltI/ZNGchV2YOPrKIUP5CJPf6px0tk+RToqXkejOGLA4
# WF8V9HmNJ8ftCSRV+ykHwd3RWz4W/SB0Tpyh9hOHrqYliGUlYX0cgb5/+TVutuue
# 3E1f62WQpa8FCe0qmuX1REH7Y5mnn6+fOGYVWZYo5pcZbrhSdAf5OnzscZE=
# SIG # End signature block
