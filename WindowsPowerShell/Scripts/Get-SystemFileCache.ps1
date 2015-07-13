#requires -version 2.0
function Get-SystemFileCache {
  <#
    .SYNOPSIS
        Shows system cache status.
    .DESCRIPTION
        GetSystemFileCacheSize function is just wrapper for NtQuerySystemInformation. This script directly
        uses NtQuerySystemInformation to check current system file cache status. Pay close attention that
        this is alternative way to know about system file cache status without WMI.
    .OUTPUTS
        Array <Object[]>
    .NOTES
        Author: greg zakharov
  #>
  
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
    } #dynmod
    
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
        
        [Management.Automation.PSParser]::Tokenize($Definition, [ref]$ret) | ? {
          $_.Type -match '(?:(Command)|(String))'
        } | % {
          if (($token = $_.PSBase).Type -eq 'Command') {
            $ft = [Type]$token.Content #field type
          }
          else {
            [void]$type.DefineField($token.Content, $ft, 'Public')
          } #if
        } #foreach
        $GetSize = $type.DefineMethod('GetSize', 'Public, Static', [Int32], [Type[]]@())
        $IL = $GetSize.GetILGenerator()
        $IL.Emit([OpCodes]::Ldtoken, $type)
        $IL.Emit([OpCodes]::Call, [Type].GetMethod('GetTypeFromHandle'))
        $IL.Emit([OpCodes]::Call, [Marshal].GetMethod('SizeOf', [Type[]]@([Type])))
        $IL.Emit([OpCodes]::Ret)
        $Implicit = $type.DefineMethod(
          'op_Implicit', 'PrivateScope, Public, Static, HideBySig, SpecialName', $type, [Type[]]@([IntPtr])
        )
        $IL = $Implicit.GetILGenerator()
        $IL.Emit([OpCodes]::Ldarg_0)
        $IL.Emit([OpCodes]::Ldtoken, $type)
        $IL.Emit([OpCodes]::Call, [Type].GetMethod('GetTypeFromHandle'))
        $IL.Emit([OpCodes]::Call, [Marshal].GetMethod('PtrToStructure', [Type[]]@([IntPtr], [Type])))
        $IL.Emit([OpCodes]::Unbox_Any, $type)
        $IL.Emit([OpCodes]::Ret)
        $type.CreateType()
      }
      else { $mb.GetType($StructName) }
    } #struct
    
    accelerate ([Type]::GetType('System.Management.Automation.TypeAccelerators'))
    accelerate ([Runtime.InteropServices.Marshal])
    accelerate ([Reflection.Emit.OpCodes])
    
    $SYSTEM_INFORMATION_CLASS = @{
      SystemBasicInformation     = 0
      SystemFileCacheInformation = 21
    } #SYSTEM_INFORMATION_CLASS
    
    Set-Content function:query {
      param([Type]$type, [String]$kind)
      
      $len = $type::GetSize()
      $ptr = [Marshal]::AllocHGlobal($len)
      $cls = $SYSTEM_INFORMATION_CLASS[$kind]
      
      if ([Regex].Assembly.GetType('Microsoft.Win32.NativeMethods').GetMethod(
        'NtQuerySystemInformation'
      ).Invoke($null, @($cls, $ptr, $len, $ref)) -eq 0) {
        $str = $ptr -as $type
      }
      [Marshal]::FreeHGlobal($ptr)
      
      return $str
    } #query
  }
  process {
    $sbi = struct SYSTEM_BASIC_INFORMATION {
      UInt32 'Reserved';
      UInt32 'TimerResolution';
      UInt32 'PageSize';
      UInt32 'NumberOfPhysicalPages';
      UInt32 'LowestPhysicalPageNumber';
      UInt32 'HighestPhysicalPageNumber';
      UInt32 'AllocationGranularity';
      UInt32 'MinimumUserModeAddress';
      UInt32 'MaximumUserModeAddress';
      UInt32 'ActiveProcessorAffinityMask';
      Byte   'NumberOfProcessors';
    }
    
    $sfi = struct SYSTEM_FILECACHE_INFORMATION {
      UInt32 'CurrentSize';
      UInt32 'PeakSize';
      UInt32 'PageFaultCount';
      UInt32 'MinimumWorkingSet';
      UInt32 'MaximumWorkingSet';
      UInt32 'CurrentSizeIncludingTransitionInPages';
      UInt32 'PeakSizeIncludingTransitionInPages';
      UInt32 'TransitionRePurposeCount';
      UInt32 'Flags';
    }
    
    $PageSize = (query $sbi 'SystemBasicInformation').PageSize
    $sfi = query $sfi 'SystemFileCacheInformation'
    
    New-Object PSObject -Property @{
      MinimumWorkingSetKB = $sfi.MinimumWorkingSet * $PageSize / 1Kb
      MaximumWorkingSetKB = $sfi.MaximumWorkingSet * $PageSize / 1Kb
      PeakSizeKB          = $sfi.PeakSize / 1Kb
      CurrentSizeKB       = $sfi.CurrentSize / 1Kb
    } | Format-List
  }
  end {
    [void][TypeAccelerators]::Remove('OpCodes')
    [void][TypeAccelerators]::Remove('Marshal')
    [void][TypeAccelerators]::Remove('TypeAccelerators')
  }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5ms7absNzgUM0IoMRFRHYTSd
# uhegggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFBWwHsTPQJH/3hsj
# 0beMAzMfgB0mMA0GCSqGSIb3DQEBAQUABIIBAB7DO7Rxy/us1D8fXgVNH37UgQ+e
# fTj7MlsV2Obr0W42KY/5zA2Ztoc2qgZUqIfww3BGEzgb9LASBHDAsN7QJ6hf8zcW
# eX4+g8clBii3Jgvx1A/DEbpttSG/ZGh6f3K4BYwpSpKDilud7+kmXR9F2GtA6Jcf
# l4654bAsaetQcQ6lQLLVJIfIhDVR1umZKKVLrvsv76QlW8xISC0Ztk2+lfcASXST
# NIWQSsn8wo5stEa/nve7zm0q/8S9HP9a+icbTf7ZU6Cty8EVQAZNDk+bgoE+Tm7q
# MjeiiSuuDjIZszavLDGOcto9S277LEL6o7CCFhSJiDCflxiBCl4IfGgCD4U=
# SIG # End signature block
