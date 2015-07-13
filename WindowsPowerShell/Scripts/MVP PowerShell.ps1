# (C) 2012 Dr. Tobias Weltner, MVP PowerShell
# www.powertheshell.com
# you can freely use and distribute this code
# we only ask you to keep this comment including copyright and url
# as a sign of respect. 

# more information and documentation found here:
# http://www.powertheshell.com/iseconfig/


<#
.SYNOPSIS
reads one or more settings for the ISE editor
.PARAMETER Name
Name of setting to read. You can use wildcards.
If you do not supply a name, all settings are retrieved.
If you do not use wildcards, only the value will be returned.
If you do use wildcards, the setting name will also be returned.
.EXAMPLE
Get-ISESetting MRUCount
Reads the maximum number of files in your MRU list
.EXAMPLE
Get-ISESetting
returns all settings
.EXAMPLE
Get-ISESetting *wind*
returns all settings with "wind" in their name
#>
Function Get-ISESetting
{
  param
  (
    $Name = '*'
  )

  $folder = (Resolve-Path -Path $env:localappdata\microsoft_corporation\powershell_ise*\3.0.0.0).Path
  $filename = 'user.config'
  $path = Join-Path -Path $folder -ChildPath $filename

  [xml]$xml = Get-Content -Path $path -Raw

  # wildcards used?
  $wildCard = $Name -match '\*'

  # find all settings available with their correct casing:
  $settings = $xml.SelectNodes('//setting') | Where-Object serializeAs -EQ String | Select-Object -ExpandProperty Name
  # translate the user-submitted setting into the correct casing:
  $CorrectSettingName = @($settings -like $Name)

  # if no setting is found, try with wildcards
  if ($CorrectSettingName.Count -eq 0)
  {
    $CorrectSettingName = @($settings -like "*$Name*")
    $wildCard = $true
  }

  if ($CorrectSettingName.Count -gt 1 -or $wildCard)
  {
    $CorrectSettingName |
    ForEach-Object {
      $xml.SelectNodes(('//setting[@name="{0}"]' -f $_)) |
      Select-Object -Property Name, Value
    }
  }
  elseif ($CorrectSettingName.Count -eq 1)
  {
    $xml.SelectNodes(('//setting[@name="{0}"]' -f $CorrectSettingname[0])) |
    Select-Object -ExpandProperty Value
  }
  else
  {
    Write-Warning "The setting '$SettingName' does not exist. Try one of these valid settings:"
    Write-Warning ($settings -join ', ')
  }
}

<#
.SYNOPSIS
sets a settings for the ISE editor
.PARAMETER Name
Name of setting to change.
.PARAMETER Value
New value for setting. There is no validation. You are responsible for submitting valid values.
.EXAMPLE
Set-ISESetting MRUCount 12
Sets the maximum number of files in your MRU list to 12
#>
Function Set-ISESetting
{
  param
  (
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    $Name,

    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    $Value
  )

  Begin
  {
    $folder = (Resolve-Path -Path $env:localappdata\microsoft_corporation\powershell_ise*\3.0.0.0).Path
    $filename = 'user.config'
    $path = Join-Path -Path $folder -ChildPath $filename

    [xml]$xml = Get-Content -Path $path -Raw

    # find all settings available with their correct casing:
    $settings = $xml.SelectNodes('//setting') | Where-Object serializeAs -EQ String | Select-Object -ExpandProperty Name
  }

  Process
  {
    # translate the user-submitted setting into the correct casing:
    $CorrectSettingName = $settings -like $Name

    if ($CorrectSettingName)
    {
      $xml.SelectNodes(('//setting[@name="{0}"]' -f $CorrectSettingName))[0].Value = [String]$Value
    }
    else
    {
      Write-Warning "The setting '$SettingName' does not exist. Try one of these valid settings:"
      Write-Warning ($settings -join ', ')
    }
  }

  End
  {
    $xml.Save($Path)
  }
}


<#
.SYNOPSIS
adds a new file path to the MRU list or replaces the list with new files 
.PARAMETER Path
Path to add to the list. Can be an array, can be received from the pipeline.
.PARAMETER Append
Adds the path(s) to the existing list
.EXAMPLE
Set-ISEMRUList -Path c:\dummy -Append
Adds a new path to the MRU list, keeping the old paths.
.EXAMPLE
dir $home *.ps1 -recurse -ea 0 | Select-Object -ExpandProperty Fullname | Set-ISEMRUList
replaces existing MRU list with the paths to all powershell script files in your profile
If the list exceeds the number of entries defined in the ISE setting MruCount, the remainder is truncated.
#>
Function Set-ISEMRUList
{
  param
  (
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [String[]]
    $Path,

    [Switch]
    $Append
  )

  Begin
  {
    $folder = (Resolve-Path -Path $env:localappdata\microsoft_corporation\powershell_ise*\3.0.0.0).Path
    $filename = 'user.config'
    $configpath = Join-Path -Path $folder -ChildPath $filename

    [xml]$xml = Get-Content -Path $configpath -Raw

    $PathList = @()
  }

  Process
  {
    $Path | ForEach-Object { $PathList += $_ }
  }

  End
  {
    if ($Append)
    {
      $PathList += @($xml.SelectNodes('//setting[@name="MRU"]').Value.ArrayOfString.string)
    }

    # is list too long?
    $max = Get-ISESetting -Name MRUCount
    $current = $PathList.Count

    if ($current -gt $max)
    {
      if (!$Append)
      {
        Write-Warning "Your MRU list is too long. It has $current elements but MRUCount is limited to $max elements."
        Write-Warning "Truncating the last $($current - $max) elements."
        Write-Warning 'You can increase the size of your MRU list like this:'
        Write-Warning "Set-ISESetting -Name MRUCount -Value $current"
      }

      $PathList = $PathList[0..$($max-1)]
    }

    $xml.SelectNodes('//setting[@name="MRU"]').Value.ArrayOfString.InnerXML = $PathList |
    ForEach-Object { "<string>$_</string>" } |
    Out-String
    $xml.Save($configpath)
  }
}

<#
.SYNOPSIS
dumps the current path names in the ISE MRU list 
.EXAMPLE
Get-ISEMRUList
dumps the paths to all recently used files in the ISE editor
#>
Function Get-ISEMRUList
{
  $newfile = 'c:\somescript.ps1'

  $folder = (Resolve-Path -Path $env:localappdata\microsoft_corporation\powershell_ise*\3.0.0.0).Path
  $filename = 'user.config'
  $path = Join-Path -Path $folder -ChildPath $filename

  [xml]$xml = Get-Content -Path $path -Raw
  $xml.SelectNodes('//setting[@name="MRU"]').Value.ArrayOfString.string
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvCRAcCIiLYxGGlq5vvQlHxAu
# va2gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEwQhge9IPBH1gep
# G050kxE2jiH6MA0GCSqGSIb3DQEBAQUABIIBAKNHlqM9sFv9FiXXah0qTm364tgQ
# JZ5OdbSUWe6INdqiBzO92GoRf62QHmFvFCjZ5G0UQm3lyIR8Ol4Dm07SdWf/Anr8
# ymVBpOp+Ql8q51iAfAMY+2Pkrc4/9baX6Zcev3H3Vq00t2XLFY3xhj8xoRmyYYUR
# FxEKS+nO7cdWMP7fKUjDyc+bBY2rSK77FfwMwpUT1+Xt30tjFgdelHVFC6cxJm9V
# b0SABZ3C36r2BLnAf7bg3o4o2F+Wb3mUbQlwGWA79GctKcLo44iMbh6oJQvp9WpV
# Adc23SAZTwBxhnd85Dm1qBgy5wo2a7U7n1pJtFUQoPEMuHADaVsqjivvMNs=
# SIG # End signature block
