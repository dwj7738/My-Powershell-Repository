function Invoke-TSPingSweep {
  <#
    .SYNOPSIS
    Scan IP-Addresses, Ports and HostNames

    .DESCRIPTION
    Scan for IP-Addresses, HostNames and open Ports in your Network.
    
    .PARAMETER StartAddress
    StartAddress Range

    .PARAMETER EndAddress
    EndAddress Range

    .PARAMETER ResolveHost
    Resolve HostName

    .PARAMETER ScanPort
    Perform a PortScan

    .PARAMETER Ports
    Ports That should be scanned, default values are: 21,22,23,53,69,71,80,98,110,139,111,
    389,443,445,1080,1433,2001,2049,3001,3128,5222,6667,6868,7777,7878,8080,1521,3306,3389,
    5801,5900,5555,5901

    .PARAMETER TimeOut
    Time (in MilliSeconds) before TimeOut, Default set to 100

    .EXAMPLE
    Invoke-TSPingSweep -StartAddress 192.168.0.1 -EndAddress 192.168.0.254

    .EXAMPLE
    Invoke-TSPingSweep -StartAddress 192.168.0.1 -EndAddress 192.168.0.254 -ResolveHost

    .EXAMPLE
    Invoke-TSPingSweep -StartAddress 192.168.0.1 -EndAddress 192.168.0.254 -ResolveHost -ScanPort

    .EXAMPLE
    Invoke-TSPingSweep -StartAddress 192.168.0.1 -EndAddress 192.168.0.254 -ResolveHost -ScanPort -TimeOut 500

    .EXAMPLE
    Invoke-TSPingSweep -StartAddress 192.168.0.1 -EndAddress 192.168.10.254 -ResolveHost -ScanPort -Port 80

    .LINK
    http://www.truesec.com

    .NOTES
    Goude 2012, TrueSec
  #>
  Param(
    [parameter(Mandatory = $true,
      Position = 0)]
    [ValidatePattern("\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")]
    [string]$StartAddress,
    [parameter(Mandatory = $true,
      Position = 1)]
    [ValidatePattern("\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b")]
    [string]$EndAddress,
    [switch]$ResolveHost,
    [switch]$ScanPort,
    [int[]]$Ports = @(21,22,23,53,69,71,80,98,110,139,111,389,443,445,1080,1433,2001,2049,3001,3128,5222,6667,6868,7777,7878,8080,1521,3306,3389,5801,5900,5555,5901),
    [int]$TimeOut = 100
  )
  Begin {
    $ping = New-Object System.Net.Networkinformation.Ping
  }
  Process {
    foreach($a in ($StartAddress.Split(".")[0]..$EndAddress.Split(".")[0])) {
      foreach($b in ($StartAddress.Split(".")[1]..$EndAddress.Split(".")[1])) {
        foreach($c in ($StartAddress.Split(".")[2]..$EndAddress.Split(".")[2])) {
          foreach($d in ($StartAddress.Split(".")[3]..$EndAddress.Split(".")[3])) {
            write-progress -activity PingSweep -status "$a.$b.$c.$d" -percentcomplete (($d/($EndAddress.Split(".")[3])) * 100)
            $pingStatus = $ping.Send("$a.$b.$c.$d",$TimeOut)
            if($pingStatus.Status -eq "Success") {
              if($ResolveHost) {
                write-progress -activity ResolveHost -status "$a.$b.$c.$d" -percentcomplete (($d/($EndAddress.Split(".")[3])) * 100) -Id 1
                $getHostEntry = [Net.DNS]::BeginGetHostEntry($pingStatus.Address, $null, $null)
              }
              if($ScanPort) {
                $openPorts = @()
                for($i = 1; $i -le $ports.Count;$i++) {
                  $port = $Ports[($i-1)]
                  write-progress -activity PortScan -status "$a.$b.$c.$d" -percentcomplete (($i/($Ports.Count)) * 100) -Id 2
                  $client = New-Object System.Net.Sockets.TcpClient
                  $beginConnect = $client.BeginConnect($pingStatus.Address,$port,$null,$null)
                  if($client.Connected) {
                    $openPorts += $port
                  } else {
                    # Wait
                    Start-Sleep -Milli $TimeOut
                    if($client.Connected) {
                      $openPorts += $port
                    }
                  }
                  $client.Close()
                }
              }
              if($ResolveHost) {
                $hostName = ([Net.DNS]::EndGetHostEntry([IAsyncResult]$getHostEntry)).HostName
              }
              # Return Object
              New-Object PSObject -Property @{
                IPAddress = "$a.$b.$c.$d";
                HostName = $hostName;
                Ports = $openPorts
              } | Select-Object IPAddress, HostName, Ports
            }
          }
        }
      }
    }
  }
  End {
  }
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDtjslARLrEIY+LjC2tihCYoE
# ax2gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGGdjjPAicJNVNbF
# +Rz5j79kKh51MA0GCSqGSIb3DQEBAQUABIIBAHRy5Qa+5mmePnP9ZpS8YCsexj+6
# OvA2XD4lNpQEsvuW68ECTEpwUXCPSKIimKompsdKdNJ147fjvRPl1FTkC7G1XCn2
# qymNxFpUabdiKpyQL042k4o8Naa8CfQLsnlaG2boew6Jay9w8dlXGmuVG3CDtD5r
# mId6oTEZjauK3vU5+eUfDIMO6U7MaTF0C3ItmGyvfOENSnWTCSWoeRUSqHc8v/np
# 2qay6qvKFX8F5yMG4K5WGYFL5q37FKiMdsXiG3hj3xRYmr3g+yWoZm6AVBGGDOBk
# 62IpemyM98KuozkzTxUtvzbucaVnpu+l0z4yrGbqIVBNxe+gu7QchKrjDVc=
# SIG # End signature block
