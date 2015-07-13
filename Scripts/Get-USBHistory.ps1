Function Get-USBHistory
{
<#
.SYNOPSIS
	This fucntion will get the history for USB devices that have been plugged into a machine.

.DESCRIPTION
	 This funciton queries the "SYSTEM\CurrentControlSet\Enum\USBSTOR" key to get a list of all USB storage devices that have
	been connected to a machine.  The funciton can run against local or remote machines.

.PARAMETER  ComputerName
	Specifies the computer which you want to get the USB storage device history from.  The value can be a fully qualified domain
	name or an IP address.  This parameter can be piped to the function.  The local computer is the default.

.Parameter Ping
    Use Ping to verify a computer is online before connecting to it.
    
.EXAMPLE
	PS C:\>Get-USBHistory -ComputerName LAPTOP
		
	Computer                                                         USBDevice                                                              
	--------                                                         ---------                                                              
	LAPTOP                                                           A-DATA USB Flash Drive USB Device                                      
	LAPTOP                                                           CBM Flash Disk USB Device                                              
	LAPTOP                                                           WD 3200BEV External USB Device                                         

	Description
	-----------
	This command displays the history of USB storage device on the localhost.
		
.EXAMPLE
	PS C:\>$Servers = Get-Content ServerList.txt
		
	PS C:\>Get-USBHistory -ComputerName $Servers
		
		
	Description
	-----------
	This command first creates an array of server names from ServerList.txt then executes the Get-USBHistory script on the array of servers.
	
.EXAMPLE
	PS C:\>Get-USBHistory Server1 | Export-CSV -Path C:\Logs\USBHistory.csv -NoTypeInformation
    		
		
	Description
	-----------
	This command gets run the Get-USBHistory command on Server1 and pipes the output to a CSV file located in the C:\Logs directory.

	
.Notes
LastModified: 5/09/2012
Author:       Jason Walker

	
#>

 [CmdletBinding()]

Param
(
	[parameter(ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
	[alias("CN","Computer")]
	[String[]]$ComputerName=$Env:COMPUTERNAME,
    [Switch]$Ping	
)
       
 Begin
 {
          
     $USBDevices      = @()
     $TempErrorAction = $ErrorActionPreference
     $ErrorActionPreference = "Stop"
     $Hive   = "LocalMachine"
     $Key    = "SYSTEM\CurrentControlSet\Enum\USBSTOR"
     
  }

  Process
  {            
     $ComputerCounter = 0        
        
     ForEach($Computer in $ComputerName)
     {
        $ComputerCounter++        
    	$Computer = $Computer.Trim().ToUpper()
        Write-Progress -Activity "Collecting USB history" -Status "Retrieving USB history from $Computer" -PercentComplete (($ComputerCounter/($ComputerName.Count)*100))
        
                       	
        If($Ping)
        {
           If(-not (Test-Connection -ComputerName $Computer -Count 1 -Quiet))
           {
              Write-Warning "Ping failed on $Computer"
              Continue
           }
        }#end if ping            			
    	   
    		    			
    	Try
    	{
           $SubKeys2        = @()
           $USBSTORSubKeys1 = @()
           $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive,$Computer)
    	   $USBSTORKey = $Reg.OpenSubKey($Key)
    	   $USBSTORSubKeys1  = $USBSTORKey.GetSubKeyNames()           
                  
    	   ForEach($SubKey1 in $USBSTORSubKeys1)
    	   {	
    	      $Key2 = "SYSTEM\CurrentControlSet\Enum\USBSTOR\$SubKey1"
    		  $RegSubKey2  = $Reg.OpenSubKey($Key2)
    		  $SubkeyName2 = $RegSubKey2.GetSubKeyNames()	
    	      $Subkeys2   += "$Key2\$SubKeyName2"
    		  $RegSubKey2.Close()		
    		}#end foreach SubKey1

    		ForEach($Subkey2 in $Subkeys2)
    		{	
    		   $USBKey      = $Reg.OpenSubKey($Subkey2)
    		   $USBDevice   = $USBKey.GetValue('FriendlyName')
               If($USBDevice)
               {	
    		      $USBDevices += New-Object -TypeName PSObject -Property @{
    		         USBDevice = $USBDevice
    			     Computer  = $Computer
    			       }
                }
                 $USBKey.Close()    		      						
    	     }#end foreach SubKey2
            
               $USBSTORKey.Close()
           }#end try
           Catch
           {
              Write-Warning "There was an error connecting to the registry on $Computer or USBSTOR key not found. Ensure the remote registry service is running on the remote machine."
           }#end catch
        
     }#end foreach computer 
              
  }#end process
    				    	
  End
  {
     #Display results		
     $USBDevices | Select Computer,USBDevice	
        
     #Set error action preference back to original setting		
     $ErrorActionPreference = $TempErrorAction 		
  }
           	
}#end function
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfmg7fGm1v2e+ks16TvWgSix+
# DIagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJtC+G8UhDjPEHXG
# a5u/t+7nIfD0MA0GCSqGSIb3DQEBAQUABIIBAIrTwomh+YrMxGpvP/PtVuRqbfIy
# ooOgUfTEdUEYk2fmo/5XuMPUBVtwb+9A6/+qjB97j6khLZsTHvy7gxdW62q6wE+5
# /u+6fFclMx2v6mz4uzEsXSgCCuK1Ct/mGD/m9XplZRFhPmDG+8VnjRoxnYvsO3E7
# 7Nqs1l+GOEhIRhotzbCnCJk7cqkf6gy+kyOeXNnBx+QDScwpcfKWeBibIouAxTO6
# Xn1r93UblWoWIFAAJxsmcSxleFGeMRgxqqXLbysSHP0aip+hv6MHzNT/FQOoEVkc
# 4loMlWBDWoq36lcbco28UCLKUp/Nz0a+wS8LWRC7Xypofs0WjlxXOh+nRDo=
# SIG # End signature block
