<#
.SYNOPSIS
       The purpose of this script is to set name/value pairs on the farm property bag. 
	   Values are read from/stored in an xml configuration file.
.DESCRIPTION
       The purpose of this script is to set name/value pairs on the farm property bag. 
	   Values are read from/stored in an xml configuration file. This is useful for 
	   storing farm wide environment variables. One use is to have scripts read farm 
	   variables and then scripts can run the same on production/qa/dev.
	   Perform a bulk download of this and other useful scripts with this batch downloader: 
	   http://gallery.technet.microsoft.com/scriptcenter/b9fe96c4-9bf1-4d61-903b-5e6c2a65ec66
	   
.EXAMPLE
.\Set-FarmProperties.ps1 -GenerateSampleConfigurationFile 
Generate a sample configuration file
.EXAMPLE
.\Set-FarmProperties.ps1 
Set farm properties

	   Output from sample normal run
	   PS C:\Users\sp_admin\Documents\MESGLab\scripts> .\Set-FarmProperties.ps1

           Set Farm Properties
__________________________________________________

  Setting Farm property name:UTFarm100 to value:<UTFarm100 Value>
  Setting Farm property name:UTFarm101 to value:<UTFFarm101 Value>
__________________________________________________

             All Farm properties 
__________________________________________________

Name                           Value
----                           -----
UTFarm100                      UTFarm100 Value
UTFarm101                      UTFFarm101 Value
__________________________________________________

.EXAMPLE
.\Set-FarmProperties.ps1 -DebugMode 
Run in debug mode


	   Output from sample debug run

PS C:\Users\sp_admin\Documents\MESGLab\scripts> .\Set-FarmProperties.ps1 -DebugMode 
Configuration file set to: Set-FarmProperties.config
Starting  main
<Configuration><configurationSection><FarmProperties><PropertyBag><property name="UTFarm100" value=
"UTFarm100 Value" /><property name="UTFarm101" value="UTFFarm101 Value" /></PropertyBag></FarmPrope
rties></configurationSection></Configuration>
Set-FarmProperties.config
Starting  setFarmProperties

           Set Farm Properties
__________________________________________________

  Set-FarmProperties.setFarmProperties() property name=UTFarm100 value=UTFarm100 Value
  Setting Farm property name:UTFarm100 to value:<UTFarm100 Value>
  Set-FarmProperties.setFarmProperties() property name=UTFarm101 value=UTFFarm101 Value
  Setting Farm property name:UTFarm101 to value:<UTFFarm101 Value>
__________________________________________________
Finished  setFarmProperties

             All Farm properties
__________________________________________________

Name                           Value
----                           -----
UTFarm100                      UTFarm100 Value
UTFarm101                      UTFFarm101 Value
__________________________________________________

Finished  main

.EXAMPLE
.\Set-FarmProperties.ps1 -ConfigurationFile .\Set-FarmProperties.config
Run using a specific config file
.LINK
http://gallery.technet.microsoft.com/scriptcenter/bbd7dc18-3677-45ba-b0c5-933336217a01
.NOTES
  File Name : Set-FarmProperties.ps1
  Author    : Ben Lin, Brent Groom 
#>

# TODO - implement uninstall and validate

param
  (
    [string]
    # Specifies whether the script should "install", "validate" or "uninstall". "install" is the default.
    $InstallMode="install",
	
    [switch]
    # Signifies that the script should output debug statements
    $DebugMode, 
    
    [string]
    # Specifies confuguration file name. The default is "this script name".config. i.e. 
    # Set-FarmProperties.config
    $ConfigurationFile="", 
    
    [switch]
    # Specifies whether the script should generate a sample configuration file. If you specify this flag, 
    # the script will generate the file and exit.
    $GenerateSampleConfigurationFile
    
    )

Add-PSSnapin AdminSnapIn -erroraction SilentlyContinue 
Add-PsSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

# reference: 
# This script: http://gallery.technet.microsoft.com/scriptcenter/bbd7dc18-3677-45ba-b0c5-933336217a01
# SPFarm Members http://technet.microsoft.com/en-us/library/microsoft.sharepoint.administration.spfarm_members.aspx


$configurationname = $myinvocation.mycommand.name.Substring(0, $myinvocation.mycommand.name.IndexOf('.'))
$debug = $false
$farm = get-SPFarm


function AddFarmProperty([string]$name, [string]$value)
{

  if ($name.length -gt 0 )
  { 
    if ($farm.Properties[$name])
    {
      $farm.Properties[$name] = $value
    }
    else
    {
      $farm.Properties.Add($name, $value)
    }
    $farm.update()
    # check to make sure the update was successful
    $checkval =  $farm.Properties[$name]
    if ($checkval -ne $value)
    {
	  write-host ( "  Failed setting Farm property:"+$propname +" to <"+$propvalue  +">" ) -Foregroundcolor Red
    }
    else
    {
	  write-host ( "  Set Farm property:"+$propname +" to <"+$propvalue  +">" ) -Foregroundcolor Green
    }
    
  }
  
}

Function FunctionGenerateSampleConfigurationFile()
{
    $funcname = "FunctionGenerateSampleConfigurationFile"
    if ($DebugMode) { "Starting  $funcname " }

"Writing file $configurationname.config"
$selfdocumentingxml = @" 
<Configuration>
  <configurationSection>
      <FarmProperties> 
       <PropertyBag>
          <property name="UTFarm100" value="UTFarm100 Value"/>
          <property name="UTFarm101" value="UTFarm101 Value"/>
        </PropertyBag>
      </FarmProperties>       
  </configurationSection>
 </Configuration>
"@ | Out-File "$configurationname.config"
    if ($DebugMode) { "Finished $funcname " }

} 

Function setFarmProperties([xml]$thedata)
{

    $funcname = "setFarmProperties"
    if ($DebugMode) { write-host ("Starting  $funcname" ) -Foregroundcolor Green }

    # handle all Properties
    $props = $thedata.SelectNodes("Configuration/configurationSection/FarmProperties/PropertyBag/property")

    if(!$props -or $props -eq $null -or $props.length -eq 0)
    {
          "No properties to set"
    }
   write-host ("`n           Set Farm Properties " ) -Foregroundcolor Yellow 
   write-host ("__________________________________________________`n" ) -Foregroundcolor Yellow 

          
	foreach ($prop in $props)
	{      
      $propname = $prop.name
      $propvalue = $prop.value
      
      if ($DebugMode) { "  $configurationname.setFarmProperties() property name="+$propname +" value="+$propvalue  }
	  write-host ( "  Setting Farm property:"+$propname +" to <"+$propvalue  +">" ) 
      
	  AddFarmProperty $propname $propvalue
      
    }
    
	write-host ("__________________________________________________" ) -Foregroundcolor Yellow 

    if ($DebugMode) { write-host ("Finished  $funcname" ) -Foregroundcolor Red }

}



Function main([string]$ConfigurationFile)
{
    $funcname = "main"
    if ($DebugMode) { write-host ("Starting  $funcname" ) -Foregroundcolor Green }


	# check to make sure the file exists
	if(!(test-path $ConfigurationFile)){"Configuration file $ConfigurationFile not found";break}


    [xml]$xmldata = [xml](Get-Content $ConfigurationFile)
    if($DebugMode)
    {
      $xmldata.get_InnerXml()
      $ConfigurationFile
	}

    setFarmProperties $xmldata
    
   write-host ("`n             All Farm properties " ) -Foregroundcolor Yellow 
   write-host ("__________________________________________________" ) -Foregroundcolor Yellow 

   $farm.Properties.GetEnumerator() | sort Name
   write-host ("__________________________________________________`n" ) -Foregroundcolor Yellow 
   
    
    if ($DebugMode) { write-host ("Finished  $funcname" ) -Foregroundcolor Red }
	
	
}


if($ConfigurationFile.length -eq 0)
{
  $ConfigurationFile = "$configurationname.config"
    if ($DebugMode) { write-host ("Configuration file set to: $ConfigurationFile" )  }
	
}

""
"	   Perform a bulk download of this and other useful scripts with this batch downloader: "
"	   http://gallery.technet.microsoft.com/scriptcenter/b9fe96c4-9bf1-4d61-903b-5e6c2a65ec66"
""

if($GenerateSampleConfigurationFile)
{
  FunctionGenerateSampleConfigurationFile
}
else
{
  main $ConfigurationFile
}



# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzRWsUcy3gON/UvvZvOj5QecI
# mP2gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJ4g+w9g+hlVb3CO
# ktQMdKIxJbRyMA0GCSqGSIb3DQEBAQUABIIBAFKIU3dhKsj6CF60OkbEyb/9Jq4j
# Zi3Cnkr8QSIGg2O5xJK4L/L5f2rg1ag3Urj6qk6vW50ZHMvUzd1E1VGZlMI5oO83
# 0MqAy5yk9Twa1A0u9i1rvDYJKrtpcgmV7QkaW8crcKv++23AagIWUx8gnLbVvHss
# OIHj+75Uyfy3j5UuXrgnIdrxcdHaoJsBnYl930xcpgS1GdDlLFshSOHuPCMYAt/1
# N8W5DUYLGeg1lucjyB36IK194MHcTsPEyqkp5oLp0JjovKPm8IzQBfkW+7+Yial+
# aGrcZnoKPxie2MCEOUiczajFDxKo0JQz1bf3DALSezps+K8lQ9XqBR+QSxU=
# SIG # End signature block
