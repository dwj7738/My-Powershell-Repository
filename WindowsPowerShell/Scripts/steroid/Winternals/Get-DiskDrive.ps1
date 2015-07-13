#requires -version 2.0
function Get-DiskDrive {
  <#
    .SYNOPSIS
        Gets basic info of drives (alternative for Win32_DiskDrive).
    .NOTES
        Author: greg zakharov
  #>
  begin {
    $CreateFile = ($$ = [AppDomain]::CurrentDomain.GetAssemblies() | ? {
      $_.ManifestModule.ScopeName -match '\A(System|System.Data).dll\Z'
    })[0].GetType('Microsoft.Win32.UnsafeNativeMethods').GetMethod(
      'CreateFile', ($bf = [Reflection.BindingFlags]40)
    )
    $DeviceIoControl = $$[1].GetType(
      'System.Data.SqlTypes.UnsafeNativeMethods'
    ).GetMethod('DeviceIoControl', $bf)
    
    enum MEDIA_TYPE UInt32 {
      Unknown        = 0x00
      F5_1Pt2_512    = 0x01
      F3_1Pt44_512   = 0x02
      F3_2Pt88_512   = 0x03
      F3_20Pt8_512   = 0x04
      F3_720_512     = 0x05
      F5_360_512     = 0x06
      F5_320_512     = 0x07
      F5_320_1024    = 0x08
      F5_180_512     = 0x09
      F5_160_512     = 0x0a
      RemovableMedia = 0x0b
      FixedMedia     = 0x0c
      F3_120M_512    = 0x0d
      F3_640_512     = 0x0e
      F5_640_512     = 0x0f
      F5_720_512     = 0x10
      F3_1Pt2_512    = 0x11
      F3_1Pt23_1024  = 0x12
      F5_1Pt23_1024  = 0x13
      F3_128Mb_512   = 0x14
      F3_230Mb_512   = 0x15
      F8_256_128     = 0x16
      F3_200Mb_512   = 0x17
      F3_240M_512    = 0x18
      F3_32M_512     = 0x19
    } | Out-Null
    
    $PARTITION_STYLE = enum PARTITION_STYLE Int32 {
      MBR = 0
      GPT = 1
      RAW = 2
    }
    
    struct DISK_GEOMETRY {
      Int64      'Cylinders';
      MEDIA_TYPE 'MediaType';
      Int32      'TracksPerCylinder';
      Int32      'SectorsPerTrack';
      Int32      'BytesPerSector';
    } | Out-Null
    
    struct DISK_PARTITION_INFO {
      Int32           'SizeOfPartitionInfo 0';
      PARTITION_STYLE 'PartitionStyle 4';
      UInt32          'Signature 8';
      Guid            'DiskId 8';
    } -Explicit | Out-Null
    
    $DISK_GEOMETRY_EX = struct DISK_GEOMETRY_EX {
      DISK_GEOMETRY       'Geometry';
      Int64               'DiskSize';
      DISK_PARTITION_INFO 'PartitionInfo';
    }
    
    $key = 'HKLM:\SYSTEM\CurrentControlSet'
    $sub = '\Enum\', '\Services\Disk\Enum'
    $drv = '\\.\PhysicalDrive'
    
    [UInt32]$IOCTL_DISK_GET_DRIVE_GEOMETRY_EX = 0x000700A0
  }
  process {
    $i = 0
    while (1) {
      $sfh = $CreateFile.Invoke($null, @(($id = $drv + $i), 0, 3, [IntPtr]::Zero, 3, 0, [IntPtr]::Zero))
      if (!$sfh.IsInvalid) {
        [UInt32]$ret = 0
        [UInt32]$len = $DISK_GEOMETRY_EX::GetSize()
        $ptr = [Runtime.InteropServices.Marshal]::AllocHGlobal($len)
        try {
          if ($DeviceIoControl.Invoke($null, @(
            [Microsoft.Win32.SafeHandles.SafeFileHandle]$sfh,
            $IOCTL_DISK_GET_DRIVE_GEOMETRY_EX, [IntPtr]::Zero, [Uint32]0, $ptr, $len, $ret, [IntPtr]::Zero
          ))) {
            $geo = $ptr -as $DISK_GEOMETRY_EX
            $mod = Get-ItemProperty ($key + $sub[0] + ($int = (Get-ItemProperty ($key + $sub[1])).$i))
            $DISKDRIVE = New-Object PSObject -Property @{
              DeviceId          = $id
              Model             = $mod.FriendlyName
              Description       = $mod.DeviceDesc
              Interface         = ($int -split '\\')[0]
              MediaType         = $geo.Geometry.MediaType
              Signature         = $(if ($geo.PartitionInfo.PartitionStyle -eq $PARTITION_STYLE::MBR) {
                $geo.PartitionInfo.Signature
              })
              DiskId            = $(if ($geo.PartitionInfo.PartitionStyle -eq $PARTITION_STYLE::GPT) {
                $geo.PartitionInfo.DiskId
              })
              Cylinders         = $geo.Geometry.Cylinders
              TracksPerCylinder = $geo.Geometry.TracksPerCylinder
              SectorsPerTrack   = $geo.Geometry.SectorsPerTrack
              BytesPerSector    = $geo.Geometry.BytesPerSector
              DiskSize          = $geo.DiskSize
            }
            $DISKDRIVE.PSObject.TypeNames.Insert(0, 'DISKDRIVE')
            $DISKDRIVE
          }
        }
        catch { $_.Exception }
        finally {
          [Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
        }
      }
      else { break }
      $i++
    } #while
  }
  end {}
}

Export-ModuleMember -Function Get-DiskDrive

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5mdY8f11GMHjI1P5hmdxwHRh
# OuagggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFE9uMvDeUvEFO0QW
# aA77SYc62JeMMA0GCSqGSIb3DQEBAQUABIIBACKBTV21aNtdKMUYggBp0MquSd2P
# CYP6neWVYBnqMflonFTCtR7bF3HMIH1ReyC0Me9bXS0b9ipI5LtaWMvJ2slzrZ8V
# Lm8TLVFd5ypGPqq8WlOCd9CmVegIBFBCDNvFtPa9Hx6L6DbapWO7XihKZKg2xxt+
# 2NBtE6puoQ/wsB+LPCAmzw7nU1MkUqpqrnWBBl1ziYovKBWBYXHmF4llcVVqs6Rf
# XSuWDh4+6z8Axbqg4qUKf7O+uHfERkRkUpK0gkMzvkx0glONV9C/JmRNhpXDaFHh
# XBLV+9hgesdsfoLrJPryh+X2KORtPGsA2g0WQE0WCTNf7PzXxRp2rlrf7sY=
# SIG # End signature block
