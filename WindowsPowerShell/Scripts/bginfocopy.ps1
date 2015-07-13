<#
.SYNOPSIS
   <A brief description of the script>
.DESCRIPTION
   <A detailed description of the script>
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>
$mainserver = "\\xxxxxxxxxxx\_Server_Support\support"
$ServerList = Get-Content ./testing.txt
if ($ServerList -eq $NULL)
                  {
                        Write-Output ("Could not read server list.  You  may not have permission. Exiting.")
                        return
                  }

if (Test-Path($supportpath) 
$FolderToCopy = "\\xxxxxxxxxxx\_Server_Support\support"

foreach ($Server in $ServerList)
      {
      #Echo back current server
      Write-Host "Processing Server $Server..." -ForeGroundColor "Yellow"
      if ($server -eq $NULL) {
	  	Write-Output("Server is NULL.. Exiting")
		exit	
		}
      #Remove Path if it exists on remote server
      $UNCPath = "\\$Server\c$\Support"
      Write-Host "Checking/Removing UNC Path $UNCPath"
      if (Test-Path $UNCPath)
      {
            Remove-Item -path $UNCPath -Recurse -Force
      }
      
      #Copy folder content from source to destination
      Write-Host "Copying folder $FolderToCopy to destination $UNCPath"
      Copy-Item $FolderToCopy -Destination $UNCPath -Recurse -Force
      }
      
      $FilesAndFolders = gci "c:\support" -recurse | % {$_.FullName}
foreach($FileAndFolder in $FilesAndFolders)
{
    $item = gi -literalpath $FileAndFolder 
    $acl = $item.GetAccessControl() 
    $permission = "Everyone","FullControl","Allow"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.SetAccessRule($rule)
    $item.SetAccessControl($acl)
}
{      [CmdletBinding(SupportsShouldProcess=$true)]
      param
      (
            [Parameter(Position=0, Mandatory=$false)]
            [System.String]
            $Server = "$ServerList",
            [Parameter(Position=1, Mandatory=$false)]
            [ValidateSet("ClassesRoot","CurrentConfig","CurrentUser","DynData","LocalMachine","PerformanceData","Users")]
            [System.String]
            $Hive = "LocalMachine",
            [Parameter(Position=2, Mandatory=$false, HelpMessage="Enter Registry key in format System\CurrentControlSet\Services")]
            [ValidateNotNullOrEmpty()]
            [System.String]
            $Key = "SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            [Parameter(Position=3, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [System.String]
            $Name = "BGInfo",
            [Parameter(Position=4, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [System.String]
            $Value = "C:\support\bginfo\Bginfo.exe C:\support\bginfo\standard.bgi /TIMER:0 /silent /NOLICPROMPT",
            [Parameter(Position=5, Mandatory=$false)]
            [ValidateSet("String","ExpandString","Binary","DWord","MultiString","QWord")]
            [System.String]
            $Type = "String",
            [Parameter(Position=6, Mandatory=$false)]
            [switch]
            $Force
      )
      
      if ($pscmdlet.ShouldProcess($Server, "Open registry $Hive"))
      {
      #Open remote registry
      try
      {
                  $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $Server)
            
      }
      catch 
      {
            Write-Error "The computer $Server is inaccessible. Please check computer name. Please ensure remote registry service is running and you have administrative access to $Server."
            return
      }
      }

      if ($pscmdlet.ShouldProcess($Server, "Check existense of $Key"))
      {
      #Open the targeted remote registry key/subkey as read/write
      $regKey = $reg.OpenSubKey($Key,$true)
            
      #Since trying to open a regkey doesn't error for non-existent key, let's sanity check
      #Create subkey if parent exists. If not, exit.
      if ($regkey -eq $null)
      {      
            Write-Warning "Specified key $Key does not exist in $Hive."
            $Key -match ".*\x5C" | Out-Null
            $parentKey = $matches[0]
            $Key -match ".*\x5C(\w*\z)" | Out-Null
            $childKey = $matches[1]

            try
            {
                  $regtemp = $reg.OpenSubKey($parentKey,$true)
            }
            catch
            {
                  Write-Error "$parentKey doesn't exist in $Hive or you don't have access to it. Exiting."
                  return
            }
            if ($regtemp -ne $null)
            {
                  Write-Output "$parentKey exists. Creating $childKey in $parentKey."
                  try
                  {
                        $regtemp.CreateSubKey($childKey) | Out-Null
                  }
                  catch 
                  {
                        Write-Error "Could not create $childKey in $parentKey. You  may not have permission. Exiting."
                        return
                  }

                  $regKey = $reg.OpenSubKey($Key,$true)
            }
            else
            {
                  Write-Error "$parentKey doesn't exist. Exiting."
                  return
            }
      }
      
      #Cleanup temp operations
      try
      {
            $regtemp.close()
            Remove-Variable $regtemp,$parentKey,$childKey
      }
      catch
      {
            #Nothing to do here. Just suppressing the error if $regtemp was null
      }
      }
      #If we got this far, we have the key, create or update values
      if ($Force)
      {
            if ($pscmdlet.ShouldProcess($ComputerName, "Create or change $Name's value to $Value in $Key. Since -Force is in use, no confirmation needed from user"))
            {
                  $regKey.Setvalue("$Name", "$Value", "$Type")
            }
      }
      else
      {
            if ($pscmdlet.ShouldProcess($ComputerName, "Create or change $Name's value to $Value in $Key. No -Force specified, user will be asked for confirmation"))
            {
            $message = "Value of $Name will be set to $Value. Current value `(If any`) will be replaced. Do you want to proceed?"
            $regKey.Setvalue("$Name", "$Value", "$Type")
            }
      }
      
      #Cleanup all variables
      try
      {
            $regKey.close()
            Remove-Variable $Server,$Hive,$Key,$Name,$Value,$Force,$reg,$regKey,$yes,$no,$caption,$message,$result
      }
      catch
      {
            #Suppressing the error if any variable is null
}      }
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAHdxM+W4WGUgllh4WevNOY4l
# riigggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFtKYkbbpaovgmmu
# jA7+a6bcZjtqMA0GCSqGSIb3DQEBAQUABIIBACbbSqZbmX4fuCAzHWFsaWckmteo
# MiMTEIcGVzXwgyRh7/LPtNFR5+geAfcQptEVQx6SmWgg+EWc1deinUPYQ8Eajksb
# DckpNuT+TObWLnpUBWSHdrXsXF/HBU7/NmBnIHIXFU+GxZMYvYLoj5xRIq8kRp2C
# sH8JbCy+Ktn5IXrON8x5kbEbR8y82E67FXchcU8I4P9/xiTBRXaC1AQei4CjJtfC
# DIYOmbN1TpA9pwK27lzkNYG/4KG/g9VTyV8EgJXc7u6cSSb6qKtHpIRfGhG8g7BU
# DjYJvuuy0uAsdL/VoREHbepz+3ZNroXBynQZIJzFQXELI2kt9T3XfsVyErw=
# SIG # End signature block
