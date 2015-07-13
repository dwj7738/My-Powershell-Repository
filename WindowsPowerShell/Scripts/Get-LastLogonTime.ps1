#requires -version 2.0
function Get-LastLogonTime {
  <#
    .SYNOPSIS
        Gets the time of the last logon of the current user.
    .OUTPUTS
        DateTime
    .NOTES
        Author: greg zakharov
  #>
  
  begin {
    if (($HKCU = ($o = [Object].Assembly).GetType(
      'Microsoft.Win32.SafeHandles.SafeRegistryHandle'
    ).GetConstructor(
      [Reflection.BindingFlags]36, $null, [Type[]]@([IntPtr], [Boolean]), $null
    ).Invoke(
      @([Microsoft.Win32.RegistryKey].GetField(
        'HKEY_CURRENT_USER', ($bf = [Reflection.BindingFlags]40)
      ).GetValue($null), $true)
    )) -eq $null) {
      return
    }
    
    $KEY_READ = ($Win32Native = $o.GetType(
      'Microsoft.Win32.Win32Native'
    )).GetField('KEY_READ', $bf).GetValue($null)
    $ERROR_SUCCESS = $Win32Native.GetField('ERROR_SUCCESS', $bf).GetValue($null)
    
    if ($Win32Native.GetMethod('RegOpenKeyEx', $bf).Invoke(
      $null, ($out = [Object[]]@($HKCU, 'Volatile Environment', 0, $KEY_READ, $out))
    ) -ne $ERROR_SUCCESS) {
      $HKCU.Close()
      return
    }
    
    Set-Content function:dynmod {
      $name = -join (0..7 | % {$rnd = New-Object Random}{
        [Char]$rnd.Next(97, 122)
      })
      
      if (!($asm = ($cd = [AppDomain]::CurrentDomain).GetAssemblies() | ? {
        $_.ManifestModule.ScopeName.Equals(($mem = 'RefEmit_InMemoryManifestModule'))
      })) {
        ($cd.DefineDynamicAssembly(
          (New-Object Reflection.AssemblyName($name)), 'Run'
        )).DefineDynamicModule($name, $false)
      }
      else { $asm.GetModules() | ? {$_.FullyQualifiedName -ne $mem} }
    } #dynasm
  }
  process {
    [UInt32]$p1 = $p2 = $p3 = $p4 = $p5 = $p6 = $p7 = 0
    $sb = New-Object Text.StringBuilder(1024)
    [UInt32]$sz = $sb.Capacity
    $ft = New-Object Runtime.InteropServices.ComTypes.FILETIME
    
    $LastLogonTime = if (!(($mb = dynmod).GetTypes() | ? { $_.Name -eq 'LastLogonTime' })) {
      $par = @(
        [IntPtr],
        [Text.StringBuilder],
        [UInt32].MakeByRefType(),
        [IntPtr],
        [UInt32].MakeByRefType(),
        [UInt32].MakeByRefType(),
        [UInt32].MakeByRefType(),
        [UInt32].MakeByRefType(),
        [UInt32].MakeByRefType(),
        [UInt32].MakeByRefType(),
        [UInt32].MakeByRefType(),
        [Runtime.InteropServices.ComTypes.FILETIME].MakeByRefType()
      )
      $attr = 'AnsiClass, Class, Public, Sealed, BeforeFieldInit'
      $type = $mb.DefineType('LastLogonTime', $attr)
      $meth = $type.DefinePInvokeMethod('RegQueryInfoKey', 'advapi32.dll',
        'Public, Static, PinvokeImpl', 'Standard', [Int32], $par, 'WinApi', 'Auto'
      )
      $par | % {$i = 1}{
        if ($_.IsByRef) { [void]$meth.DefineParameter($i, 'Out', $null) }
        $i++
      }
      $OpCodes = [Reflection.Emit.OpCodes]
      $Shift = $type.DefineMethod('Shift', 'Public, Static', [Int64], [Type[]]@([Int64], [Int32]))
      $IL = $Shift.GetILGenerator()
      $IL.Emit($OpCodes::Ldarg_0)
      $IL.Emit($OpCodes::Ldarg_1)
      $IL.Emit($OpCodes::Ldc_I4_S, 63)
      $IL.Emit($OpCodes::And)
      $IL.Emit($OpCodes::Shl)
      $IL.Emit($OpCodes::Ret)
      $type.CreateType()
    }
    else { $mb.GetType('LastLogonTime') }
    
    if ($LastLogonTime::RegQueryInfoKey(
      $HKCU.DangerousGetHandle(), $sb, [ref]$sz, [IntPtr]::Zero,
      [ref]$p1, [ref]$p2, [ref]$p3, [ref]$p4, [ref]$p5, [ref]$p6, [ref]$p7,
      [ref]$ft
    ) -eq $ERROR_SUCCESS) {
      $low = [BitConverter]::ToUInt32([BitConverter]::GetBytes($ft.dwLowDateTime), 0)
      $top = [Int64]$ft.dwHighDateTime
      [DateTime]::FromFileTime(($LastLogonTime::Shift($top, 32) -bor $low))
    }
  }
  end {
    $out[4].Close()
    $HKCU.Close()
  }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUrXMEWl2h5d71GgGpNkc3p0L1
# 7/SgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCeE2CR//iH1AKDu
# QMx+lLqJu2koMA0GCSqGSIb3DQEBAQUABIIBAK0DfRMXupP4hMqsDiNZABQzahsY
# enNrFAUMjQD5hF5026DVOMCh/wOlfL6yQiB+k0kVndbbO+QXCB+/L8MSkv0xzy6L
# caXawvBuT1Amc4UQtRUl+DT4t4Zr5WWw5S5Y91CcVLpUeQoMTWkKI7FslEPHYaFa
# xnfJPkVI++eOhALJGdRGOtaHXdb9bjV0Osq5fT7DIiAmT+UAPK6u+GPNIe6emsjw
# Fr8Nwx4ny15StDjhcpFx7Z5Ohyeg+e5OCf4rAJNClRcUqtbH9r8NFjQUVFF66nEj
# tXthN0CsxVXjnXHi/nynj6X2mq+7mp0kQxoDVzHoTH30/nBQjD4d8pg5lCY=
# SIG # End signature block
