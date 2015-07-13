# ------------------------------------------------------------------
# Title: Get-InstalledApplications.ps1
# Author: Lars Jostein Silihagen
# Description: Get a list of installed applications based on uninstall information in Registry and creates a WQL-query for each installed application.
# Date Published: 19-Mar-2012 5:06:46 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Get-InstalledApplicationsps-e2aee784
# Tags: SCCM;Applications;Configuration Manager
# Rating: 4 rated by 1
# ------------------------------------------------------------------

<#
    .SYNOPSIS
        Get a list of installed applications based on uninstall information in Registry and creates
		a WQL-query for each installed application.
		
		The Objects retuned:
		 - AppName
		 - AppVersion
		 - AppVendor
		 - UninstallString
		 - AppGui
		 - WQLQuery
					
    .PARAMETER ComputerName
		Name of the machine to retrieve data from 
          
    .EXAMPLE
        Get a list of installed applications on local computer:
        
		Get-InstalledApplications.ps1  
		
		AppName         : Aruba Networks Virtual Intranet Access
		AppVersion      : 2.0.1.0.30205
		AppVendor       : Aruba Networks
		UninstallString : MsiExec.exe /X{F5CE8021-D68C-44A9-A69E-14725B63212D}
		AppGUID         : {F5CE8021-D68C-44A9-A69E-14725B63212D}
		WQLQuery        : SELECT * FROM Win32Reg_AddRemovePrograms WHERE Displayname LIKE 'Aruba Networks Virtual Intranet Access 2.0.1.0.30205' AND Version LIKE '2.0.1.0.30205'
	
	.EXAMPLE
		Get application name and WQL-query for installed applications on remote computer:
		
		Get-InstalledApplications.ps1 -ComputerName <ComputerName> | select AppName, WQLquery | Format-List
		AppName  : Aruba Networks Virtual Intranet Access
		WQLQuery : SELECT * FROM Win32Reg_AddRemovePrograms WHERE Displayname LIKE 'Aruba Networks Virtual Intranet Access 2.0.1.0.30205' AND Version LIKE '2.0.1.0.30205'

	.NOTES 
		AUTHOR:    Lars Jostein SIlihagen 
		BLOG:      http://blog.silihagen.net 
		LASTEDIT:  19.03.2012
		You have a royalty-free right to use, modify, reproduce, and 
		distribute this script file in any way you find useful, provided that 
		you agree that the creator, owner above has no warranty, obligations, 
		or liability for such use. 
#>


[cmdletbinding()]
param
(
	[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	[string[]]$ComputerName = $env:computername            
)            
begin 
{
$ErrorActionPreference = "SilentlyContinue"
	# Registry	
	$UninstallRegKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
}            
process 
{
	foreach($Computer in $ComputerName) 
	{
   		# Test computer connection
		if (Test-Connection -ComputerName $Computer -Count 1 -ea 0)
		{
			$HKLM = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computer)
			$UninstallRef = $HKLM.OpenSubKey($UninstallRegKey)
			$Applications = $UninstallRef.GetSubKeyNames()            

   			foreach ($App in $Applications) 
			{
    			$AppRegistryKey  = $UninstallRegKey + "\\" + $App
    			$AppDetails = $HKLM.OpenSubKey($AppRegistryKey)
    			$AppGUID = $App
    			$AppDisplayName = $($AppDetails.GetValue("DisplayName"))
    			$AppVersion = $($AppDetails.GetValue("DisplayVersion"))
    			$AppPublisher = $($AppDetails.GetValue("Publisher"))
    			$AppUninstall = $($AppDetails.GetValue("UninstallString"))
    
				if (!$AppDisplayName) 
				{ 
					continue 
				}
			    # App information
				$OutputObj = New-Object -TypeName PSobject
 				$OutputObj | Add-Member -MemberType NoteProperty -Name AppName -Value $AppDisplayName
    			$OutputObj | Add-Member -MemberType NoteProperty -Name AppVersion -Value $AppVersion
    			$OutputObj | Add-Member -MemberType NoteProperty -Name AppVendor -Value $AppPublisher
 				$OutputObj | Add-Member -MemberType NoteProperty -Name UninstallString -Value $AppUninstall
    			$OutputObj | Add-Member -MemberType NoteProperty -Name AppGUID -Value $AppGUID    			
				
				# AMD64 or X86 App?
				$GetWmiClass =  Get-WmiObject -Class "Win32reg_addRemovePrograms" -ComputerName $Computer | Select Displayname
				if ($GetWmiClass)
				{
					foreach ($DispName in $GetWmiClass)
					{
						If ($DispName.Displayname -eq $AppDisplayName)					
						{
							#x86
							$WMIType = "Win32Reg_AddRemovePrograms"	
						}
						else
						{
							#AMD64
							$WMIType = "Win32Reg_AddRemovePrograms64"	
						}
					}
				
					#WQL query
					$WqlQuery = "SELECT * FROM " + $WMIType + " WHERE Displayname LIKE '" + $AppDisplayName + "' AND Version LIKE '" + $AppVersion + "'"
										
					#Test WQL query
					$TestWQLQuery = Get-WmiObject -query $WQLQuery -ComputerName $Computer
					if ($TestWQLQuery)
					{
						#WQL-query verifyed
						$OutputObj | Add-Member -MemberType NoteProperty -Name WQLQuery -Value $WqlQuery 
						$OutputObj
					}
					else
					{
						# error in WMI query
						$OutputObj | Add-Member -MemberType NoteProperty -Name WQLQuery -Value "Error testing WQL query."	
						$OutputObj
					}
				}
				else
				{
					# error connection WMI
					$OutputObj | Add-Member -MemberType NoteProperty -Name WQLQuery -Value "Error: Can't determine WQL-query. Error in WMI-connection for computer: " $Computer
					$OutputObj
				}
   			}
  		}
		else
		{
			Write-host -BackgroundColor Black -ForegroundColor Red "Error: Can not reach the machine: " $Computer 
			Write-host -BackgroundColor Black -ForegroundColor Red "Quit PowerShell script"
		}
 	}
}            
end {}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUL5x8gYGdgBpreRG17F64H+4F
# lJCgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFNzlOB3X/nzyGxHf
# OOxUe2OZB+jaMA0GCSqGSIb3DQEBAQUABIIBACpcEqsKNNJ4au+fo/1CGxnxSBf/
# ivzVo/LsY1P6+qA6y6GYgc+6N0mxvI+hnW+xNxuyBUETd2W2v1WPuyfUa2mvQ5Sk
# 5wvuD6GqgcE7gXM9UT2F/90dStT76vfhrgsWYhs4uflFHsCiabnSWJvwx6OM3sPV
# nI2etrYaH2HCS+0fewcLMte5BKDVhicOxFfQYYkGp8el3AyO/TV6FW5j19qQemV+
# qdYT0gdP3Lfa6taYOjV6oFuXmoxVCSckq0mN/D6cgfJSgWjx8C2u8XMzMXHvsF6X
# V08qRlvrJ0aBxoJduHzaSDWCkDLIXfuLoshObFPFOAWb4E7/5WEB2W+VBHw=
# SIG # End signature block
