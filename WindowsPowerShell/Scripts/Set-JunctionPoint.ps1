#requires -version 2.0
function Set-JunctionPoint {
  <#
    .SYNOPSIS
        Windows junction creator.
    .EXAMPLE
        PS C:\> $dest = "$([Environment]::GetFolderPath('Desktop')\foo"
        PS C:\> Set-JunctionPoint C:\bar $dest
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateScript({Test-Path $_})]
    [String]$SourcePath,
    
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [String]$JunctionPoint
  )
  
  begin {
    Set-Content function:accelerate {
      param([Type]$type)
      
      if ([Array]($ta = [Type]::GetType(
        'System.Management.Automation.TypeAccelerators'
      ))::Get.Keys -notcontains $type.Name) {
        $ta::Add($type.Name, $type)
      }
    } #accelerate
    
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
    
    Set-Content function:struct {
      param(
        [Parameter(Mandatory=$true, Position=0)]
        [String]$StructName,
        
        [Parameter(Mandatory=$true, Position=1)]
        [ScriptBlock]$Definition,
        
        [Parameter(Position=2)]
        [Reflection.Emit.PackingSize]$PackingSize = 'Unspecified'
      )
      
      if (!(($mb = dynmod).GetTypes() | ? { $_.Name -eq $StructName })) {
        $ret = $null #PSParser outputs
        
        $attr = 'AnsiClass, Class, Public, Sealed, SequentialLayout, BeforeFieldInit'
        $type = $mb.DefineType($StructName, $attr, [ValueType], $PackingSize)
        $ctor = [MarshalAsAttribute].GetConstructor(
          [Reflection.BindingFlags]20, $null, [Type[]]@([Runtime.InteropServices.UnmanagedType]), $null
        )
        $cnst = @([MarshalAsAttribute].GetField('SizeConst'))
        
        [Management.Automation.PSParser]::Tokenize($Definition, [ref]$ret) | ? {
          $_.Type -match '(?:(Command)|(String))'
        } | % {
          if (($token = $_.PSBase).Type -eq 'Command') {
            $ft = [Type]$token.Content #field type
          }
          else {
            $fn = switch ($token.Content -match '\s') { #field name
              $true  {
                ($itm = $token.Content -split '\s')[0]
                $ml = $itm[1]
                $sz = $itm[2]
              }
              $false { $token.Content }
            } #switch
            
            if (!$ml -and !$sz) {
              [void]$type.DefineField($fn, $ft, 'Public')
            }
            else {
              $unm = $type.DefineField($fn, $ft, 'Public, HasFieldMarshal')
              $atr = New-Object Reflection.Emit.CustomAttributeBuilder(
                $ctor, [Runtime.InteropServices.UnmanagedType]$ml, $cnst, @([Int32]$sz)
              )
              $unm.SetCustomAttribute($atr)
            }
          } #if
          $ml = $sz = $null
        } #foreach
        $type.CreateType()
      }
      else { $mb.GetType($StructName) }
    } #struct
    
    accelerate ([Type]::GetType('System.Management.Automation.TypeAccelerators'))
    accelerate ([Runtime.InteropServices.MarshalAsAttribute])
    accelerate ([Runtime.InteropServices.Marshal])
    
    $GENERIC_WRITE                = 0x40000000
    $FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000
    $FILE_FLAG_BACKUP_SEMANTICS   = 0x02000000
    
    [UInt32]$IO_REPARSE_POINT_TAG_MOUNT_POINT = [BitConverter]::ToUInt32(
      [BitConverter]::GetBytes(0xA0000003), 0
    )
    [UInt32]$FSCTL_SET_REPASE_POINT           = 0x000900A4
    
    $CreateFile = ($asm = ($all = ($cd = [AppDomain]::CurrentDomain).GetAssemblies()) | ? {
      $_.ManifestModule.ScopeName -cmatch '(?:(System)|(System.Data)).dll'
    })[0].GetType(
      'Microsoft.Win32.UnsafeNativeMethods'
    ).GetMethod(
      'CreateFile', ($bf = [Reflection.BindingFlags]40)
    )
    $DeviceIoControl = $asm[1].GetType(
      'System.Data.SqlTypes.UnsafeNativeMethods'
    ).GetMethod(
      'DeviceIoControl', $bf
    )
  }
  process {
    $rdb = struct REPARSE_DATA_BUFFER {
      UInt32 'ReparseTag';
      UInt16 'ReparseDataLength';
      UInt16 'Reserved';
      UInt16 'SubstituteNameOffset';
      UInt16 'SubstituteNameLength';
      UInt16 'PrintNameOffset';
      UInt16 'PrintNameLength';
      Byte[] 'PathBuffer ByValArray 0x3FF0';
    }
    
    $SourcePath = Convert-Path $SourcePath
    
    try {
      if (Test-Path $JunctionPoint) {
        throw (New-Object IO.IOException('Could not create junction point.'))
      }
      
      New-Item $JunctionPoint -ItemType Directory | Out-Null
      if (($sfh = $CreateFile.Invoke($null,
        @($JunctionPoint,
          $GENERIC_WRITE,
          7, #FileShare.ReadWrite | FileShare.Delete
          [IntPtr]::Zero,
          3, #FileMode.Open
          ($FILE_FLAG_OPEN_REPARSE_POINR -bor $FILE_FLAG_BACKUP_SEMANTICS),
          [IntPtr]::Zero
        )
      )).IsInvalid) {
        [Marshal]::ThrowExceptionForHR([Marshal]::GetHRForLastWin32Error())
      }
      
      $bts = [Text.Encoding]::Unicode.GetBytes('\??\' + $SourcePath)
      $rdb = [Activator]::CreateInstance($rdb)
      $rdb.ReparseTag           = $IO_REPARSE_POINT_TAG_MOUNT_POINT
      $rdb.ReparseDataLength    = [UInt16]($bts.Length + 12)
      $rdb.SubstituteNameOffset = [UInt16]0
      $rdb.SubstituteNameLength = [UInt16]$bts.Length
      $rdb.PrintNameOffset      = [UInt16]($bts.Length + 2)
      $rdb.PrintNameLength      = [UInt16]0
      $rdb.PathBuffer           = New-Object "Byte[]" 0x3FF0
      
      [Array]::Copy($bts, $rdb.PathBuffer, $bts.Length)
      $ptr = [Marshal]::AllocHGlobal([Marshal]::SizeOf($rdb))
      [Marshal]::StructureToPtr($rdb, $ptr, $false)
      if (!$DeviceIoControl.Invoke($null,
        @($sfh,
          $FSCTL_SET_REPASE_POINT,
          $ptr,
          [UInt32]($bts.Length + 20),
          [IntPtr]::Zero,
          [UInt32]0,
          [UInt32]$ret,
          [IntPtr]::Zero
        )
      )) {
        [Marshal]::TrowExceptionForHR([Marshal]::GetHRForLastWin32Error())
      }
    }
    catch {
      $_.Exception
      Remove-Item $JunctionPoint -Force
    }
    finally {
      if ($ptr -ne $null) { [Marshal]::FreeHGlobal($ptr) }
      if ($sfh -ne $null) { $sfh.Close() }
    }
  }
  end {
    [void][TypeAccelerators]::Remove('Marshal')
    [void][TypeAccelerators]::Remove('MarshalAsAttribute')
    [void][TypeAccelerators]::Remove('TypeAccelerators')
  }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGJgZMyRyqGw0Ffj+KvEwYxVk
# BXqgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFB267KiVwg/6+t30
# 0EKd2fnvBYImMA0GCSqGSIb3DQEBAQUABIIBAFRxe4+B096ivGNi96S2eoGMaQKq
# B/l3oCAp5yTIl5KXOuiejZBaQhQHaO4QO4omjvFbRnkJ/WhjQs9nDTeWwI/KmWhL
# 4/NeN651cYqe34gzv9Wzsnc51ytMO35YbtGTqMcKCDbFxlAcRTUqSZt+EH9DDTvT
# pr1hV3un8wKDH78oM9k34G8kdEyaK9vuY3uDXGvWmMciQ67D3aVN75MW5pQaWsPA
# DYlt8ommx8YvrYyXQuDMU/ltQIvBOThgZd7M6wReBi4wJSah18Mte5jagHo2YMtb
# wnuiL97bIscR5VqGFshKQK/1s4Io3am0RDl2ON6zPwfWpVLtO+jjvih91aw=
# SIG # End signature block
