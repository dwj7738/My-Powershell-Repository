#required -version 2.0
function Get-LogonSessions {
  <#
    .SYNOPSIS
        Describes the logon session or sessions associated with a user logged (
        instead Win32_LogonSession class).
    .NOTES
        Author: greg zakharov
  #>
  
  begin {
    [accelerators]::Add('marshal', [Runtime.InteropServices.Marshal])
    
    $LUID = struct LUID {
      UInt32 'LowPart';
      UInt32 'HighPart';
    }
    
    struct LSA_UNICODE_STRING {
      UInt16 'Length';
      UInt16 'MaximumLength';
      IntPtr 'Buffer';
    } | Out-Null
    
    struct LSA_LAST_INTER_LOGON_INFO {
      Int64  'LastSuccessfulLogon';
      Int64  'LastFailedLogon';
      UInt32 'FailedAttemptCountSinceLastSuccessfulLogon';
    } | Out-Null
    
    enum SECURITY_LOGON_TYPE UInt32 {
      Interactive             = 2
      Network                 = 3
      Batch                   = 4
      Serivce                 = 5
      Proxy                   = 6
      Unlock                  = 7
      NetworkCleartext        = 8
      NewCredentials          = 9
      RemoteInteractive       = 10
      CachedInteractive       = 11
      CachedRemoteInteractive = 12
      CachedUnlcok            = 13
    } | Out-Null
    
    $slsd = struct SECURITY_LOGON_SESSION_DATA {
      UInt32                    'Size';
      LUID                      'LogonId';
      LSA_UNICODE_STRING        'UserName';
      LSA_UNICODE_STRING        'LogonDomain';
      LSA_UNICODE_STRING        'AuthenticationPackage';
      SECURITY_LOGON_TYPE       'LogonType';
      UInt32                    'Session';
      IntPtr                    'Sid';
      Int64                     'LogonTime';
      LSA_UNICODE_STRING        'LogonServer';
      LSA_UNICODE_STRING        'DnsDomainName';
      LSA_UNICODE_STRING        'Upn';
      LSA_LAST_INTER_LOGON_INFO 'LastLogonInfo';
      LSA_UNICODE_STRING        'LogonScript';
      LSA_UNICODE_STRING        'ProfilePath';
      LSA_UNICODE_STRING        'HomeDirectory';
      LSA_UNICODE_STRING        'HomeDirectoryDrive';
      Int64                     'LogoffTime';
      Int64                     'KickOffTime';
      Int64                     'PassworkLastSet';
      Int64                     'PasswordCanChange';
      Int64                     'PasswordMustChange';
    }
    
    $LsaFreeReturnBuffer = delegate secur32.dll LsaFreeReturnBuffer Int32 @(
      [IntPtr]
    )
    $LsaEnumerateLogonSessions = delegate secur32.dll LsaEnumerateLogonSessions Int32 @(
      [UInt32].MakeByRefType(), [IntPtr].MakeByRefType()
    )
    $LsaGetLogonSessionData = delegate secur32.dll LsaGetLogonSessionData Int32 @(
      [IntPtr], [IntPtr].MakeByRefType()
    )
    
    $STATUS_SUCCESS       = 0x00000000
    $STATUS_ACCESS_DENIED = 0xC0000022
  }
  process {
    try {
      [UInt32]$count = 0 #sessions counter
      [IntPtr]$first = [IntPtr]::Zero #pointer to first entry
      
      if (($ret = $LsaEnumerateLogonSessions.Invoke([ref]$count, [ref]$first)) -ne $STATUS_SUCCESS) {
        throw (New-Object Exception($('Could not enumerate logon sessions. Error 0x{0:X}' -f $ret)))
      }
      
      $ptr = $first #iteration pointer
      $str = $slsd
      for ($i = 0; $i -lt $count; $i++) {
        [IntPtr]$out = [IntPtr]::Zero
        if ($LsaGetLogonSessionData.Invoke($ptr, [ref]$out) -eq $STATUS_ACCESS_DENIED) {
          "You have $(if(!(IsAdmin)){'not'}) administrator rights."
          break
        }
        
        $str = $out -as $str
        $SECURITY_LOGON_SESSION_DATA = New-Object PSObject -Property @{
          UserName       = ($str.LogonDomain.Buffer, $str.UserName.Buffer | % {
            [Marshal]::PtrToStringUni($_)
          }) -join '\'
          LogonType      = $str.LogonType
          Session        = $str.Session
          SID            = $(try{New-Object Security.Principal.SecurityIdentifier($str.Sid)}catch{})
          Authentication = [Marshal]::PtrToStringUni($str.AuthenticationPackage.Buffer)
          LogonTime      = [DateTime]::FromFileTime($str.LogonTime)
        }
        $SECURITY_LOGON_SESSION_DATA.PSObject.TypeNames.Insert(0, 'SECURITY_LOGON_SESSION_DATA')
        $SECURITY_LOGON_SESSION_DATA
        
        $ptr = [IntPtr]($ptr.ToInt64() + $LUID::GetSize())
        [void]$LsaFreeReturnBuffer.Invoke($out)
        $str = $slsd
      } #for
    }
    catch { $_.Exception }
    finally {
      [void]$LsaFreeReturnBuffer.Invoke($first)
    }
  }
  end {
    [void][accelerators]::Remove('marshal')
  }
}

Export-ModuleMember -Function Get-LogonSessions

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGHRCWM4WxRfkAigJ7SF/mPjp
# EXKgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJrf0d0D23pLDVuw
# EwVCihr9cM0aMA0GCSqGSIb3DQEBAQUABIIBABEgl0lQQXsYU0WcsSnEAM68BW2s
# v9gqS7jVNrR9uO+47TWuKI/Gtg/Xt1SQue6zryV8SXea3y6dN+s3IFPF0t8FNifp
# rjWzsBaVeXPmDO4AB7x5gfOtatuEm+U/OMcd8+sinE//TX7+XoQu2IkvGXpM0cv0
# lqGMBWP0DnEqtgoVkB4GKSExg9ZhxpfPEYxGcSP4ZdHTuHrk5Ksany5kT6sUlGne
# 87Bj5Ra+cYG6mAwxfyjCDFoX+9JnDrt8JRJwraCYYbLJSnkq64VtFik6LGTsRIB9
# iOXeGp1nQzQNEgdewVdqF9sSr4tdJB3gVCytIz6X6o0ax5zKqMR+sfFvDVQ=
# SIG # End signature block
