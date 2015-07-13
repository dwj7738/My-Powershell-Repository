#requires -version 2.0
function Set-Privilege {
  <#
    .SYNOPSIS
        Adjusts privilege for a process ($PID is default).
    .EXAMPLE
        PS C:\> Set-Privilege SeShutdownPrivilege
    .EXAMPLE
        PS C:\> Set-Privilege SeShutdownPrivilege -Disbale
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet(
      'SeAssignPrimaryTokenPrivilege', 'SeAuditPrivilege', 'SeBackupPrivilege', 'SeChangeNotifyPrivilege',
      'SeCreateGlobalPrivilege', 'SeCreatePagefilePrivilege', 'SeCreatePermanentPrivilege',
      'SeCreateSymbolicLinkPrivilege', 'SeCreateTokenPrivilege', 'SeDebugPrivilege', 'SeEnableDelegationPrivilege',
      'SeImpersonatePrivilege', 'SeIncreaseBasePriorityPrivilege', 'SeIncreaseQuotaPrivilege',
      'SeIncreaseWorkingSetPrivilege', 'SeLoadDriverPrivilege', 'SeLockMemoryPrivilege', 'SeMachineAccountPrivilege',
      'SeManageVolumePrivilege', 'SeProfileSingleProcessPrivilege', 'SeRelabelPrivilege', 'SeRemoteShutdownPrivilege',
      'SeRestorePrivilege', 'SeSecurityPrivilege', 'SeShutdownPrivilege', 'SeSyncAgentPrivilege',
      'SeSystemEnvironmentPrivilege', 'SeSystemProfilePrivilege', 'SeSystemtimePrivilege', 'SeTakeOwnershipPrivilege',
      'SeTcbPrivilege', 'SeTimeZonePrivilege', 'SeTrustedCredManAccessPrivilege', 'SeUndockPrivilege',
      'SeUnsolicitedInputPrivilege'
    )]
    [String]$Privilege,
    
    [Parameter(Position=1)]
    [Switch]$Disable,
    
    [Parameter(Position=2)]
    [Diagnostics.Process]$Process = (Get-Process -Id $PID)
  )
  
  begin {
    #SE_PRIVILEGE_[DIS|EN]ABLED
    ($Win32Native = ($mscorlib = [Object].Assembly).GetType(
      'Microsoft.Win32.Win32Native'
    )).GetFields(($bfs = [Reflection.BindingFlags]40)) | ? {
      $_.Name -match '\Ase_p.*d\Z'
    } | % {
      Set-Variable $_.Name ([UInt32]$_.GetValue($null))
    }
    #AdjustTokenPrivileges, LookupPrivilegeValue and OpenProcessToken
    $Win32Native.GetMethods($bfs) | ? {
      $_.Name -match '\A(Adjust|LookupP|OpenP).*\Z'
    } | % {
      Set-Variable $_.Name $_
    }
    #LUID, LUID_AND_ATTRIBUTES and TOKEN_PRIVILEGES
    $Win32Native.GetNestedTypes(($bfi = [Reflection.BindingFlags]36)) | ? {
      $_.Name -match '\A(LUID|TOKEN_P).*\Z'
    } | % {
      Set-Variable $_.Name $_
    }
  }
  process {
    try {
      $SafeTokenHandle = $mscorlib.GetType(
        'Microsoft.Win32.SafeHandles.SafeTokenHandle'
      ).GetConstructor(
        $bfi, $null, [Type[]]@([IntPtr]), $null
      ).Invoke([IntPtr]::Zero)
      
      if (!$OpenProcessToken.Invoke($null, (
        $sth = [Object[]]@($Process.Handle, [Security.Principal.TokenAccessLevels]40, $SafeTokenHandle)
      ))) {
        throw (New-Object Exception('Could not find specified process.'))
      }
      
      $LUID = [Activator]::CreateInstance($LUID)
      $LUID.GetType().GetFields($bfi) | % { $_.SetValue($LUID, [UInt32]0) }
      
      if (!$LookupPrivilegeValue.Invoke($null, (
        $LUID = [Object[]]@($null, $Privilege, $LUID)
      ))) {
        throw (New-Object Exception('Could not retrieve the locally unique identifier.'))
      }
      
      $State = switch ($Disable) {
        $true  { $SE_PRIVILEGE_DISABLED }
        $false { $SE_PRIVILEGE_ENABLED }
      }
      
      $LUID_AND_ATTRIBUTES = [Activator]::CreateInstance($LUID_AND_ATTRIBUTES)
      $LUID_AND_ATTRIBUTES.GetType().GetField('Luid', $bfi).SetValue($LUID_AND_ATTRIBUTES, $LUID[2])
      $LUID_AND_ATTRIBUTES.GetType().GetField('Attributes', $bfi).SetValue($LUID_AND_ATTRIBUTES, $State)
      
      $TOKEN_PRIVILEGE = [Activator]::CreateInstance($TOKEN_PRIVILEGE)
      $TOKEN_PRIVILEGE.GetType().GetField('Privilege', $bfi).SetValue($TOKEN_PRIVILEGE, $LUID_AND_ATTRIBUTES)
      $TOKEN_PRIVILEGE.GetType().GetField('PrivilegeCount', $bfi).SetValue($TOKEN_PRIVILEGE, [UInt32]1)
      
      [UInt32]$sz = [Runtime.InteropServices.Marshal]::SizeOf($TOKEN_PRIVILEGE)
      if (!$AdjustTokenPrivileges.Invoke($null, @(
        $sth[2], $false, $TOKEN_PRIVILEGE, $sz, $null, $null
      ))) {
        throw (New-Object Exception('Could not adjust privilege.'))
      }
    }
    catch { $_.Exception }
    finally {
      if ($sth -is [Array] -and $sth[2] -ne $null) { $sth[2].Close() }
      if ($SafeTokenHandle -ne $null) { $SafeTokenHandle.Close() }
    }
  }
  end {}
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0Y7QH6fQYkYEvYDdSrWyDjm9
# SMagggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAUcMRMys910UhOG
# nHkzV1fapFNzMA0GCSqGSIb3DQEBAQUABIIBAGixgd7MRFCKIlhvcJZ1fGJ6b5a8
# 3cDq4S46DedAwn6PjUrnxE7ogGqTirE5Ts+GyYIYpk9xafCt1XT5yH2/U3xqsNVl
# udvywXlqqwCQKy7LWlfrDs/3rILtt6XYAgpVEhP1RYWVQsDyrGysLn4XzrbMLr/X
# 1XLj26lFd74/5zcwLRjZ+XZZBSRl89jPgUm5xDaEKkXaZzjfGfxQhYDvdptauyfi
# m/1uAE0baJo2iRpZY+553jXCuuX35x/83vn4oui/bbJYzMFcqvqtS8Y2TY5Rg19Z
# UCPUakmpKgReDvo6pXMB9aolSwSvgjxGCzSDnmxui+mrrK6H5iCMs+GYTsQ=
# SIG # End signature block
