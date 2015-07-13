getFunction Get-PendingReboot
{
<#
.SYNOPSIS
    Gets the pending reboot status on a local or remote computer.

.DESCRIPTION
    This function will query the registry on a local or remote computer and determine if the
    system is pending a reboot, from either Microsoft Patching or a Software Installation.
    For Windows 2008+ the function will query the CBS registry key as another factor in determining
    pending reboot state.  "PendingFileRenameOperations" and "Auto Update\RebootRequired" are observed
    as being consistant across Windows Server 2003 & 2008.
	
    CBServicing = Component Based Servicing (Windows 2008)
    WindowsUpdate = Windows Update / Auto Update (Windows 2003 / 2008)
    CCMClientSDK = SCCM 2012 Clients only (DetermineIfRebootPending method) otherwise $null value
    PendFileRename = PendingFileRenameOperations (Windows 2003 / 2008)

.PARAMETER ComputerName
    A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).

.PARAMETER ErrorLog
    A single path to send error data to a log file.

.EXAMPLE
    PS C:\> Get-PendingReboot -ComputerName (Get-Content C:\ServerList.txt) | Format-Table -AutoSize
	
    Computer CBServicing WindowsUpdate CCMClientSDK PendFileRename PendFileRenVal RebootPending
    -------- ----------- ------------- ------------ -------------- -------------- -------------
    DC01           False         False                       False                        False
    DC02           False         False                       False                        False
    FS01           False         False                       False                        False

    This example will capture the contents of C:\ServerList.txt and query the pending reboot
    information from the systems contained in the file and display the output in a table. The
    null values are by design, since these systems do not have the SCCM 2012 client installed,
    nor was the PendingFileRenameOperations value populated.

.EXAMPLE
    PS C:\> Get-PendingReboot
	
    Computer       : WKS01
    CBServicing    : False
    WindowsUpdate  : True
    CCMClient      : False
    PendFileRename : False
    PendFileRenVal : 
    RebootPending  : True
	
    This example will query the local machine for pending reboot information.
	
.EXAMPLE
    PS C:\> $Servers = Get-Content C:\Servers.txt
    PS C:\> Get-PendingReboot -Computer $Servers | Export-Csv C:\PendingRebootReport.csv -NoTypeInformation
	
    This example will create a report that contains pending reboot information.

.LINK
    Component-Based Servicing:
    http://technet.microsoft.com/en-us/library/cc756291(v=WS.10).aspx
	
    PendingFileRename/Auto Update:
    http://support.microsoft.com/kb/2723674
    http://technet.microsoft.com/en-us/library/cc960241.aspx
    http://blogs.msdn.com/b/hansr/archive/2006/02/17/patchreboot.aspx

    SCCM 2012/CCM_ClientSDK:
    http://msdn.microsoft.com/en-us/library/jj902723.aspx

.NOTES
    Author:  Brian Wilhite
    Email:   bwilhite1@carolina.rr.com
    Date:    08/29/2012
    PSVer:   2.0/3.0
    Updated: 05/30/2013
    UpdNote: Added CCMClient property - Used with SCCM 2012 Clients only
             Added ValueFromPipelineByPropertyName=$true to the ComputerName Parameter
             Removed $Data variable from the PSObject - it is not needed
             Bug with the way CCMClientSDK returned null value if it was false
             Removed unneeded variables
             Added PendFileRenVal - Contents of the PendingFileRenameOperations Reg Entry
#>

[CmdletBinding()]
param(
	[Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	[Alias("CN","Computer")]
	[String[]]$ComputerName="$env:COMPUTERNAME",
	[String]$ErrorLog
	)

Begin
	{
		# Adjusting ErrorActionPreference to stop on all errors, since using [Microsoft.Win32.RegistryKey]
        # does not have a native ErrorAction Parameter, this may need to be changed if used within another
        # function.
		$TempErrAct = $ErrorActionPreference
		$ErrorActionPreference = "Stop"
	}#End Begin Script Block
Process
	{
		Foreach ($Computer in $ComputerName)
			{
				Try
					{
						# Setting pending values to false to cut down on the number of else statements
						$PendFileRename,$Pending,$SCCM = $false,$false,$false
                        
                        # Setting CBSRebootPend to null since not all versions of Windows has this value
                        $CBSRebootPend = $null
						
						# Querying WMI for build version
						$WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer

						# Making registry connection to the local/remote computer
						$RegCon = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine",$Computer)
						
						# If Vista/2008 & Above query the CBS Reg Key
						If ($WMI_OS.BuildNumber -ge 6001)
							{
								$RegSubKeysCBS = $RegCon.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\").GetSubKeyNames()
								$CBSRebootPend = $RegSubKeysCBS -contains "RebootPending"
									
							}#End If ($WMI_OS.BuildNumber -ge 6001)
							
						# Query WUAU from the registry
						$RegWUAU = $RegCon.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
						$RegWUAURebootReq = $RegWUAU.GetSubKeyNames()
						$WUAURebootReq = $RegWUAURebootReq -contains "RebootRequired"
						
						# Query PendingFileRenameOperations from the registry
						$RegSubKeySM = $RegCon.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\")
						$RegValuePFRO = $RegSubKeySM.GetValue("PendingFileRenameOperations",$null)
						
						# Closing registry connection
						$RegCon.Close()
						
						# If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
						If ($RegValuePFRO)
							{
								$PendFileRename = $true

							}#End If ($RegValuePFRO)

						# Determine SCCM 2012 Client Reboot Pending Status
						# To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
						$CCMClientSDK = $null
                        $CCMSplat = @{
                            NameSpace='ROOT\ccm\ClientSDK'
                            Class='CCM_ClientUtilities'
                            Name='DetermineIfRebootPending'
                            ComputerName=$Computer
                            ErrorAction='SilentlyContinue'
                            }
                        $CCMClientSDK = Invoke-WmiMethod @CCMSplat
						If ($CCMClientSDK)
                            {
                                If ($CCMClientSDK.ReturnValue -ne 0)
							        {
								        Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"
                            
							        }#End If ($CCMClientSDK -and $CCMClientSDK.ReturnValue -ne 0)

						        If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending)
							        {
								        $SCCM = $true

							        }#End If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending)

                            }#End If ($CCMClientSDK)
                        Else
                            {
                                $SCCM = $null

                            }                        
                        
                        # If any of the variables are true, set $Pending variable to $true
						If ($CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
							{
								$Pending = $true

							}#End If ($CBS -or $WUAU -or $PendFileRename)
							
						# Creating Custom PSObject and Select-Object Splat
                        $SelectSplat = @{
                            Property=('Computer','CBServicing','WindowsUpdate','CCMClientSDK','PendFileRename','PendFileRenVal','RebootPending')
                            }
						New-Object -TypeName PSObject -Property @{
								Computer=$WMI_OS.CSName
								CBServicing=$CBSRebootPend
								WindowsUpdate=$WUAURebootReq
								CCMClientSDK=$SCCM
								PendFileRename=$PendFileRename
                                PendFileRenVal=$RegValuePFRO
								RebootPending=$Pending
								} | Select-Object @SelectSplat

					}#End Try

				Catch
					{
						Write-Warning "$Computer`: $_"
						
						# If $ErrorLog, log the file to a user specified location/path
						If ($ErrorLog)
							{
								Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append

							}#End If ($ErrorLog)
							
					}#End Catch
					
			}#End Foreach ($Computer in $ComputerName)
			
	}#End Process
	
End
	{
		# Resetting ErrorActionPref
		$ErrorActionPreference = $TempErrAct
	}#End End
	
}#End Function
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtplW+enOxcvql+TZVvFj21ZH
# dl6gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCnuvCcZikKrgWPA
# 1DzFnDUS+opTMA0GCSqGSIb3DQEBAQUABIIBAC+3b9hnX9+qwuTquz9a+xw8AhGh
# bljxvUiOv+MbfHm+tZveITk4XTd8hgPbOs7sxp8ui5yvezS+5DfWqLr1iTyzsUNG
# H3lR+q6OM4eOSndNRyHfmtxS8S/6BOvoVsMdUG0jcLKu81D1v11c8h0LnkfQKcjv
# O9rS34IBofDnbwfI5tV4cILMMNd8E69qQZpYkcjJuPP3q8VNKTOt1NLGoqE8qAYR
# J5aaVvYkuWbAW+5SvC08M07Wchsia3W5rdKNEgHfJJ8ZdXhuBXNmS9d117EYSjEG
# fWOvIBV4A5gZEKUqn67HJMuaK15+uuZiae2iglp6ZHXgwaljSl6eHhQZXbQ=
# SIG # End signature block
