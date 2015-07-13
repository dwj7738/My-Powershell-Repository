#requires -version 2.0
if (!(Test-Path alias:vprot)) {Set-Alias vprot Get-ProcessMemory}

function Get-ProcessMemory {
  <#
    .SYNOPSIS
        Retrieves virtual memory information of the given process (WinDbg !vadump).
    .OUTPUTS
        Array <Object[]>
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [Int32]$Id
  )
  
  begin {
    Set-Variable ($si = 'SYSTEM_INFO') ($a = [Object].Assembly).GetType(
      "$($$ = 'Microsoft.Win32.Win32Native')$(Get-Variable $ -ValueOnly)+$si"
    ).InvokeMember($null, [Reflection.BindingFlags]512, $null, $null, $null)
    
    $a.GetType($$).GetMethod('GetSystemInfo', [Reflection.BindingFlags]40).Invoke(
      $null, ($si = [Object[]]@($SYSTEM_INFO))
    )
    $si[0].GetType().GetFields([Reflection.BindingFlags]36) | % {$s = @{}}{
      $s[$_.Name] = $_.GetValue($si[0])
    }
    
    enum MEM_PROTECT Int32 {
      PAGE_NOACCESS          = 0x00000001
      PAGE_READONLY          = 0x00000002
      PAGE_READWRITE         = 0x00000004
      PAGE_WRITECOPY         = 0x00000008
      PAGE_EXECUTE           = 0x00000010
      PAGE_EXECUTE_READ      = 0x00000020
      PAGE_EXECUTE_READWRITE = 0x00000040
      PAGE_EXECUTE_WRITECOPY = 0x00000080
      PAGE_GUARD             = 0x00000100
      PAGE_NOCACHE           = 0x00000200
      PAGE_WRITECOMBINE      = 0x00000400
    } -Flags | Out-Null
    
    enum MEM_STATE Int32 {
      MEM_COMMIT  = 0x00001000
      MEM_RESERVE = 0x00002000
      MEM_FREE    = 0x00010000
    } -Flags | Out-Null
    
    enum MEM_TYPE Int32 {
      MEM_PRIVATE = 0x00020000
      MEM_MAPPED  = 0x00040000
      MEM_IMAGE   = 0x01000000
    } -Flags | Out-Null
    
    $MEMORY_BASIC_INFORMATION = switch ([IntPtr]::Size -eq 4) {
      $true  {
        struct MEMORY_BASIC_INFORMATION {
          Int32       'BaseAddress';
          Int32       'AllocationBase';
          MEM_PROTECT 'AllocationProtect';
          Int32       'RegionSize';
          MEM_STATE   'State';
          MEM_PROTECT 'Protect';
          MEM_TYPE    'Type';
        }
      } #x86
      $false {
        struct MEMORY_BASIC_INFORMATION {
          Int64       'BaseAddress';
          Int64       'AllocationBase';
          MEM_PROTECT 'AllocationProtect';
          Int32       'Alignment1';
          Int64       'RegionSize';
          MEM_STATE   'State';
          MEM_PROTECT 'Protect';
          MEM_TYPE    'Type';
          Int32       'Alignment2';
        }
      } #x64
    } #switch
    
    $VirtualQueryEx = delegate kernel32.dll VirtualQueryEx Int32 @(
      [IntPtr], [IntPtr], $MEMORY_BASIC_INFORMATION.MakeByRefType(), [Int32]
    )
    
    $PROCESS_QUERY_INFORMATION = 0x00000400
  }
  process {
    if (($sph = [Regex].Assembly.GetType( #SafeProcessHandle
      'Microsoft.Win32.NativeMethods'
    ).GetMethod(
      'OpenProcess'
    ).Invoke($null, @($PROCESS_QUERY_INFORMATION, $false, $Id))).IsInvalid) {
      throw (New-Object Exception('Could not open process.'))
    }
    
    $hndl = $sph.DangerousGetHandle()
    $MEMORY_BASIC_INFORMATION = [Activator]::CreateInstance($MEMORY_BASIC_INFORMATION)
    
    if ($VirtualQueryEx.Invoke(
      $hndl, [IntPtr]::Zero, [ref]$MEMORY_BASIC_INFORMATION, $s.dwPageSize
    ) -ne 0) {
      $MEMORY_BASIC_INFORMATION
      
      while ((
        $BaseAlloc = $MEMORY_BASIC_INFORMATION.BaseAddress + $MEMORY_BASIC_INFORMATION.RegionSize
      ) -lt $s.lpMaximumApplicationAddress) {
        if ($VirtualQueryEx.Invoke(
          $hndl, [IntPtr]$BaseAlloc, [ref]$MEMORY_BASIC_INFORMATION, $s.dwPageSize
        ) -eq 0) {
          break
        }
        $MEMORY_BASIC_INFORMATION
      } #while
    } #if
  }
  end {
    if ($sph -ne $null) { $sph.Close() }
  }
}

Export-ModuleMember -Alias vprot -Function Get-ProcessMemory

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2r+0/1T5XmObr6kjMJXwNo+z
# H0igggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAN0ZOWCIOEyhtxA/koB0azqKK40Pw3fa8GLif/ZM0cXJWGawkVgxOMbejeJW
# YCqXgEHF2MX/cJY8svCmLlX8M7AdjXYgtAS+C+cEHxrGAMMzj3/9EOu6DjzxIcwL
# l1GKoUwy8X3/GRGk3sBWT5CwKYRJdh9goWy74ltZN+sTKKeDHqpfuvxye6c++PC7
# 86wzm4MwfOIuPE9StFeo/0nKheEukfK9cpthlE5dUHpW0OjmJdX/g0mEdIjm2/Q2
# 50fzQyLQXOuMVIJ4Qk2comMDNRvZZvSPOBwWZ6fAR4tXfZwlpUcLv3wBbIjslhT7
# XasCm73TdBj+ZFDx2tUtpWguP/0CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBS+FASXsrRle2tLXdkVyoT1Dbw7
# QDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAbhjcmv+WCZwWCIYQwiEsH94SesBr0cPqWjEtJrBefqU9zFdB
# u5oc/WytxdCkEj5bxkoN9aJmuDAZnHNHBwIYeUz0vNByZRz6HsPzNPxLxThajJTe
# YOHlSTMI/XzBhJ7VzCb3YFhkD5f9gcJ5n+Z94ebd/1SoIvc9iwC3tTf5x2O7aHPN
# iyoWLTV4+PgDntCy/YDj11+uviI9sUUjAajYPEDvoiWinyT+7RlbStlcEuBwqvqT
# nLaiRsK17rjawW87Nkq/jB8rymUR/fzluIpHmPA4P0NazH4v5f62mpMFqdk0osMU
# QJ/qqACQ+2+/eAw7Gr6igNvlsxQpPfxsPNtUkTCCBTAwggQYoAMCAQICEAQJGBtf
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
# Q0ECEAYOIt5euYhxb7GIcjK8VwEwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHmGSnDPCVIEcxCR
# Ug0Slq4+75J9MA0GCSqGSIb3DQEBAQUABIIBABXd+z2Y23zlhQAYwZ/Qru/AKozA
# rtmysD6rWj+n6SSyhPlzde/k6wZhqQWHNrcJS6P/gnfl5BuW25+qGePt/07wPvTl
# df8vHo2dXBdMs+qbs/KS+szr0C1/hkAIucDW16rSP03SJlNc59LH4hNMvak8LXIA
# zbGd/V8niywby8NoGnnUJyqZtqs7YSiSrlwky6g2Scixhf3p7EDrTTzXMsNFBu0t
# vOwQbs5hewI7jIqbHgSCyX6/ULdHFadM7Npl8N/67u7aquyPYeTSKiZ45t8b0wxJ
# RZlH6NhSu8FI3fivryHTDoX4znq0l1a6WCvT7Q396c3x2GehSyMZbkejC3k=
# SIG # End signature block
