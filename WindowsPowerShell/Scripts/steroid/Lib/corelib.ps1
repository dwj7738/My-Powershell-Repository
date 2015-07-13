# Steroid v1.05 - core library
# Copyright (C) 2015 greg zakharov
# ==================================================================================
# THIS SAMPLE CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# WHETHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. IF THIS CODE AND
# INFORMATION IS MODIFIED, THE ENTIRE RISK OF USE OR RESULTS IN CONNECTION WITH THE
# USE OF THIS CODE AND INFORMATION REMAINS WITH THE USER.
# ==================================================================================
# GetProcAddress wrapper
# ==================================================================================
Set-Content function:GetProcAddress {
  [OutputType([IntPtr])]
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [String]$Dll,
    
    [Parameter(Mandatory=$true, Position=1)]
    [String]$Function
  )
  
  $href = New-Object Runtime.InteropServices.HandleRef(
    (New-Object IntPtr),
    [IntPtr]($$ = [Regex].Assembly.GetType(
      'Microsoft.Win32.UnsafeNativeMethods'
    ).GetMethods() | ? {
      $_.Name -match '\AGet(ModuleH|ProcA).*\Z'
    })[0].Invoke(
      $null, @($Dll)
  ))
  
  if (($ptr = [IntPtr]$$[1].Invoke($null,
    @([Runtime.InteropServices.HandleRef]$href, $Function)
  )) -eq [IntPtr]::Zero) {
    throw (New-Object Exception("Could not find $Function entry point in $Dll library."))
  }
  
  return $ptr
}
# ==================================================================================
# Dynamic assembly
# ==================================================================================
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
}

Set-Content function:delegate {
  [OutputType([Type])]
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [String]$Dll,
    
    [Parameter(Mandatory=$true, Position=1)]
    [String]$Function,
    
    [Parameter(Mandatory=$true, Position=2)]
    [Type]$ReturnType,
    
    [Parameter(Mandatory=$true, Position=3)]
    [Type[]]$Parameters
  )
  
  $ptr = GetProcAddress $Dll $Function
  $Delegate = $Function + 'Delegate'
  
  if (!(($mb = dynmod).GetTypes() | ? {$_.Name -eq $Delegate})) {
    $type = $mb.DefineType(
      $Delegate, 'AnsiClass, Class, Public, Sealed', [MulticastDelegate]
    )
    $ctor = $type.DefineConstructor(
      'HideBySig, Public, RTSpecialName', 'Standard', $Parameters
    )
    $ctor.SetImplementationFlags('Managed, Runtime')
    $meth = $type.DefineMethod(
      'Invoke', 'HideBySig, NewSlot, Public, Virtual', $ReturnType, $Parameters
    )
    $Parameters | % {$i = 1}{
      if ($_.IsByRef) { [void]$meth.DefineParameter($i, 'Out', $null) }
      $i++
    }
    $meth.SetImplementationFlags('Managed, Runtime')
    
    [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
      $ptr, ($type.CreateType())
    )
  }
  else {
    [Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
      $ptr, $mb.GetType($Delegate)
    )
  }
}

Set-Content function:enum {
  [OutputType([Type])]
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [String]$EnumName,
    
    [Parameter(Mandatory=$true, Position=1)]
    [Type]$Type,
    
    [Parameter(Mandatory=$true, Position=2)]
    [ScriptBlock]$Definition,
    
    [Parameter(Position=3)]
    [Switch]$FlagsAttribute
  )
  
  if (!(($mb = dynmod).GetTypes() | ? {$_.Name -eq $EnumName})) {
    $ret = $null
    $obj = $Type -as [Type]
    
    $type = $mb.DefineEnum($EnumName, 'Public', $obj)
    
    if ($FlagsAttribute) {
      $type.SetCustomAttribute((
        New-Object Reflection.Emit.CustomAttributeBuilder(
          [FlagsAttribute].GetConstructor(@()), @()
        )
      ))
    }
    
    [Management.Automation.PSParser]::Tokenize($Definition, [ref]$ret) | ? {
      $_.Type -match '\A(Command|Number)\Z'
    } | % {
      if ($_.Type -eq 'Command') { $lit = $_.Content }
      else {
        [void]$type.DefineLiteral($lit, $_.Content -as $obj)
      }
    } #foreach
    $type.CreateType()
  }
  else { $mb.GetType($EnumName) }
}

Set-Content function:struct {
  [OutputType([Type])]
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [String]$StructName,
    
    [Parameter(Mandatory=$true, Position=1)]
    [ScriptBlock]$Definition,
    
    [Parameter(Position=2)]
    [Reflection.Emit.PackingSize]$PackingSize = 'Unspecified',
    
    [Parameter(Position=3)]
    [Switch]$Explicit
  )
  
  if (!(($mb = dynmod).GetTypes() | ? {$_.Name -eq $StructName})) {
    [Reflection.TypeAttributes]$attr = 'AnsiClass, BeforeFieldInit, Class, Public, Sealed'
    $attr = switch ($Explicit) {
      $true  { $attr -bor [Reflection.TypeAttributes]::ExplicitLayout }
      $false { $attr -bor [Reflection.TypeAttributes]::SequentialLayout }
    }
    $type = $mb.DefineType($StructName, $attr, [ValueType], $PackingSize)
    $ctor = [Runtime.InteropServices.MarshalAsAttribute].GetConstructor(
      [Reflection.BindingFlags]20, $null, [Type[]]@([Runtime.InteropServices.UnmanagedType]), $null
    )
    $cnst = @([Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))
    
    $ret = $null
    
    [Management.Automation.PSParser]::Tokenize($Definition, [ref]$ret) | ? {
      $_.Type -match '\A(Command|String)\Z'
    } | % {
      if ($_.Type -eq 'Command') {
        $token = $_.Content #raw data (field type)
        $ft = switch (($def = $mb.GetType($token)) -eq $null) {
          $true  { [Type]$token }
          $false { $def } #locate type in dynamic assembly
        } #switch
      }
      else {
        $token = @($_.Content -split '\s') #field name, offset or unmanaged type and size
        switch ($token.Length) {
          1 { [void]$type.DefineField($token[0], $ft, 'Public') } #example: UInt32 'e_lfanew';
          2 { #if structure marked with Explicit attribute: Int64 'QuadPart 0'; else String 'Buffer LPWStr';
            switch ($Explicit) {
              $true  { [void]$type.DefineField($token[0], $ft, 'Public').SetOffset([Int32]$token[1]) }
              $false {
                $unm = [Runtime.InteropServices.UnmanagedType]$token[1]
                [void]$type.DefineField($token[0], $ft, 'Public, HasFieldMarshal').SetCustomAttribute(
                  (New-Object Reflection.Emit.CustomAttributeBuilder($ctor, [Object[]]@($unm)))
                )
              }
            } #switch
          }
          3 { #example: UInt16[] 'e_res ByValArray 10';
            $unm = [Runtime.InteropServices.UnmanagedType]$token[1]
            [void]$type.DefineField($token[0], $ft, 'Public, HasFieldMarshal').SetCustomAttribute(
              (New-Object Reflection.Emit.CustomAttributeBuilder($ctor, $unm, $cnst, @([Int32]$token[2])))
            )
          }
        } #switch
      }
    } #foreach
    $OpCodes = [Reflection.Emit.OpCodes]
    $Marshal = [Runtime.InteropServices.Marshal]
    $GetSize = $type.DefineMethod('GetSize', 'Public, Static', [Int32], [Type[]]@())
    $IL = $GetSize.GetILGenerator()
    $IL.Emit($OpCodes::Ldtoken, $type)
    $IL.Emit($OpCodes::Call, [Type].GetMethod('GetTypeFromHandle'))
    $IL.Emit($OpCodes::Call, $Marshal.GetMethod('SizeOf', [Type[]]@([Type])))
    $IL.Emit($OpCodes::Ret)
    $Implicit = $type.DefineMethod(
      'op_Implicit', 'PrivateScope, Public, Static, HideBySig, SpecialName', $type, [Type[]]@([IntPtr])
    )
    $IL = $Implicit.GetILGenerator()
    $IL.Emit($OpCodes::Ldarg_0)
    $IL.Emit($OpCodes::Ldtoken, $type)
    $IL.Emit($OpCodes::Call, [Type].GetMethod('GetTypeFromHandle'))
    $IL.Emit($OpCodes::Call, $Marshal.GetMethod('PtrToStructure', [Type[]]@([IntPtr], [Type])))
    $IL.Emit($OpCodes::Unbox_Any, $type)
    $IL.Emit($OpCodes::Ret)
    $type.CreateType()
  }
  else { $mb.GetType($StructName) }
}
# ==================================================================================
# kernel32.dll!FreeLibrary and kernel32.dll!LoadLibrary
# ==================================================================================
Set-Content function:FreeLibrary {
  [OutputType([Boolean])]
  param(
    [Parameter(Mandatory=$true)]
    [Runtime.InteropServices.HandleRef]$Handle
  )
  
  [Regex].Assembly.GetType(
    'Microsoft.Win32.SafeNativeMethods'
  ).GetMethod(
    'FreeLibrary'
  ).Invoke($null, @([Runtime.InteropServices.HandleRef]$Handle))
}

Set-Content function:LoadLibrary {
  [OutputType([Runtime.InteropServices.HandleRef])]
  param(
    [Parameter(Mandatory=$true)]
    [String]$Dll
  )
  
  if ([String]::IsNullOrEmpty([IO.Path]::GetExtension($Dll))) {
    $Dll += '.dll'
  }
  
  if ([String]::IsNullOrEmpty(
    ($Dll = (Get-Command -c Application $Dll -ea 0).Path)
  )) {
    throw (New-Object Exception("Could not find $Dll library."))
  }
  
  $Dll += "`0"
  
  New-Object Runtime.InteropServices.HandleRef(
    (New-Object IntPtr),
    [Regex].Assembly.GetType(
      'Microsoft.Win32.SafeNativeMethods'
    ).GetMethod(
      'LoadLibrary'
    ).Invoke($null, @($Dll))
  )
}
# ==================================================================================
# ntdll.dll!NtQuerySystemInformation
# ==================================================================================
$SYSTEM_INFORMATION_CLASS = @{
  SystemBasicInformation     = 0
  SystemTimeOfDayInformation = 3
  SystemFileCacheInformation = 21
}

Set-Content function:NtQuerySystemInformation {
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [Type]$Struct,
    
    [Parameter(Mandatory=$true, Position=1)]
    [String]$Class
  )
  
  $len = $Struct::GetSize()
  $ptr = [Runtime.InteropServices.Marshal]::AllocHGlobal($len)
  $cls = $SYSTEM_INFORMATION_CLASS[$Class]
  
  if ([Regex].Assembly.GetType('Microsoft.Win32.NativeMethods').GetMethod(
    'NtQuerySystemInformation'
  ).Invoke($null, @($cls, $ptr, $len, $ref)) -eq 0) {
    $str = $ptr -as $Struct
  }
  [Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
  
  return $str
}
# ==================================================================================
# Additional helpfull functions
# ==================================================================================
Set-Content function:_from {
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [String]$NameSpace,
    
    [Parameter(Mandatory=$true, Position=1)]
    [ScriptBlock]$Import
  )
  
  $ret = $null
  $arr = [Array][accelerators]::Get.Keys
  
  [Management.Automation.PSParser]::Tokenize($Import, [ref]$ret) | % {
    if ($_.Type -match 'Command' -and $arr -notcontains $_.Content) {
      [accelerators]::Add($_.Content, ("$($NameSpace).$($_.Content)"))
    }
  } #foreach
}

Set-Content function:_free {
  param(
    [Parameter(Mandatory=$true)]
    [ScriptBlock]$Accelerators
  )
  
  $ret = $null
  
  [Management.Automation.PSParser]::Tokenize($Accelerators, [ref]$ret) | ? {
    $_.Type -match 'Command'
  } | % { [void][accelerators]::Remove($_.Content) }
}

Set-Content function:IsAdmin {
  (New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
  )).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUH2nhN35XDb0Kvvjb+pr2ddV7
# 6sygggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEuUUoBDrRUBbmLN
# Sj8UjKoFlpS3MA0GCSqGSIb3DQEBAQUABIIBALNNEGd4B9tXc/UAlVDAm4+RYIK1
# gUeK5iKdslf7fFNfDzgeaQOhP72asIX4SD/5w0MZA/cAqCywM+81T25GGZPL5GWH
# 47pb7ul3slLTWJSt31xac/1jTethUTjaf3OvYtyYbhqEGkQ1T8MogkX0T8fljdC9
# R5MX7/M2SgzYrh7hY4CwXs+fkym1/kA8eRq7QcyP0X8FbXfTJHYE2qVR+d1i4Fn0
# cN5e/4W4/qkQ+k44rsq2ZXTYdZQonIgsBxJ6CQGDMDAjv5kELAQ+2r7VajMq0kn4
# pflawnwbhfgAecdv6EzhVIcK0kIbbnqFoC9tUFbE7WwBaKqVugkf7obf4Ho=
# SIG # End signature block
