 
<# 
.Synopsis 
    Gets today's latest event from enabled event logs.

.Description 
    This script gets the latest event for today from each of the enabled logs. 
    You can specify a computer name to fetch the events from remote computer. 
   The wildcard '*' is supported for computer name.
    The events can be filtered in ID or the severity level.
    NOTE: For the script to get events from remote computers the firewall exception
    for 'Remote Event Log Management (RPC)' has to be enabled on remote computers
    and the user should have privileges to query the event logs.

.Parameter ComputerName
    The name of one or more remote computers to query. Wildcards are permitted.

.Example 
    PS C:\> .\Get-LatestEvent.ps1

    Gets today's latest event from enabled event logs on the local machine.

.Example 
    PS C:\> .\Get-LatestEvent.ps1 -Id 1006
    Gets today's latest event from local machine with event Id 1006.

.Example 
   PS C:\> .\Get-LatestEvent.ps1 -Severity Error
    Gets today's latest event from enabled event logs on the local machine whose 
    severity level is 'Error'(2).

.Example
    PS C:\> .\Get-LatestEvent.ps1 -ComputerName server02
    Gets today's latest event from enabled event logs on the remote machine server02.
.Example
    PS C:\> .\Get-LatestEvent.ps1 -ComputerName server02, server05
    Gets today's latest event from enabled event logs on the remote machines server02 
    and server05.
.Example
    PS C:\> .\Get-LatestEvent.ps1 -ComputerName server*
    Gets today's latest event from enabled event logs on the remote machines in the 
    domain, name matching 'server*'.

#>

 

param(
      [Parameter(Mandatory=$false, Position=0)] 
      [ValidateNotNullOrEmpty()] 
      [System.String[]]
      $ComputerName = @('localhost'),
      [Parameter(Mandatory=$false)]
      [System.Int32[]]
      $Id,
      [Parameter(Mandatory=$false)]
      [System.Diagnostics.Eventing.Reader.StandardEventLevel[]]
     $Severity
)
# This function queries the AD DS to resolve the computer name.
# =============================================================================
function Get-ComputerName {
param(
      [Parameter(Mandatory=$true, Position=0)] 
      [ValidateNotNullOrEmpty()] 
      [System.String]
      $ComputerName
)
      $filter = "(&(objectCategory=Computer)(name=$ComputerName))"
      $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
      $root = [ADSI]"GC://$($domain.Name)"
      $searcher = new-Object System.DirectoryServices.DirectorySearcher($root, $filter)
      $searcher.PropertiesToLoad.Add("name") | Out-Null
      $searcher.FindAll() | Foreach-Object {$computer = $_.Properties; $computer.name}
}

# This function queries the remote computer for today's latest event.
# =============================================================================
function Get-TodaysLatestEvent {
param(
    [Parameter(Mandatory=$true, Position=0)] 
    [ValidateNotNullOrEmpty()] 
    [System.String]
    $ComputerName
)
$enabledLogs = Get-WinEvent -ListLog * -ComputerName $ComputerName | Where-Object {$_.IsEnabled} | ForEach-Object {$_.LogName}
      $filter = @{}
      if (${script:Id}) { $filter['ID'] = ${script:Id} }
      if (${script:Severity}) { $filter['Level'] = (${script:Severity} | %{$_.Value__})}
      foreach ($logName in $enabledLogs)
      {
            $filter['LogName'] = $logName
            Get-WinEvent -FilterHashtable $filter -MaxEvents 1 -ComputerName $ComputerName -ErrorAction SilentlyContinue | Where-Object {$_.TimeCreated.Date -eq [DateTime]::Today}
     }
}
# We loop in here for each computer name specified and query for the events.
# =============================================================================
foreach ($name in $ComputerName)
{
      if ($name -ne 'localhost')
      {
            $ResolvedComputerNames = Get-ComputerName $name
            if (($ResolvedComputerNames -eq $null) -and ($name -notmatch '\*'))
            {
                  Write-Error "Specified Computer '$name' does not exist!"
                  continue
            }
      }
      else
      {
            $ResolvedComputerNames = $name
      }
     
      $ResolvedComputerNames | ForEach-Object {Get-TodaysLatestEvent $_}
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWaXr/WW/gWME2Z1gL50zdB0Z
# uISgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFJ4iLsAKGY/Zg3y
# WiOr2fXguDjSMA0GCSqGSIb3DQEBAQUABIIBAFSyFYBNwOvPT/RT+OgR67jqFJZa
# lW0QLNXcyOnrwoez7W7OPe5RTxWi2XhjKvBzpKoPNwOJ+DtzC2InOl9uRAPPZ0uv
# e5PMJaD7tJhaTqC+TNWBfHZCEVF+g0lMixFSK+qtEtcXSUcEXOGipwbzAnkMHgnj
# 8czmoawx5mnGytQwLESxFcfEZM/AHMT2r5bNYbmzmVbKQZF5/FzlkETWzZ6xXJvr
# nJ2CXVT1e0qaANW9QwhAvu6gmNkc77ZdB8LVGNNljBZeV+TEe0+5B/dPgxJ4LMx9
# Wi+b6CFoVD0qBr+sOqERV/TbSH3m2hCvOvixSPFude+DecjLUqdcChdquyE=
# SIG # End signature block
