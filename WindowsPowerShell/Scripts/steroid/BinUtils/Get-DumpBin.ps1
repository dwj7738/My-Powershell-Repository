#requires -version 2.0
function Get-DumpBin {
  <#
    .SYNOPSIS
        Gets dump of a binary file.
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateScript({Test-Path $_})]
    [String]$FileName
  )
  
  begin {
    $IMAGE_DOS_SIGNATURE = enum IMAGE_DOS_SIGNATURE UInt16 {
      DOS    = 0x5A4D
      OS2    = 0x454E
      VXD    = 0x454C
    }
    
    enum IMAGE_FILE_MACHINE UInt16 {
      UNKNOWN   = 0
      I386      = 0x014C
      R3000     = 0x0162
      R4000     = 0x0166
      R10000    = 0x0168
      WCEMIPSV2 = 0x0169
      ALPHA     = 0x0184
      SH3       = 0x01A2
      SH3DSP    = 0x01A3
      SH3E      = 0x01A4
      SH4       = 0x01A6
      SH5       = 0x01A8
      ARM       = 0x01C0
      THUMB     = 0x01C2
      AM33      = 0x01D3
      POWERPC   = 0x01F0
      POWERPCFP = 0x01F1
      IA64      = 0x0200
      MIPS16    = 0x0266
      ALPHA64   = 0x0284
      MIPSFPU   = 0x0366
      MIPSFPU16 = 0x0466
      AXP64     = 0x0284
      TRICORE   = 0x0520
      CEF       = 0x0CEF
      EBC       = 0x0EBC
      AMD64     = 0x8664
      M32R      = 0x9041
      CEE       = 0xC0EE
    } | Out-Null
    
    enum IMAGE_FILE_CHARACTERISTICS UInt16 {
      RELOCS_STRIPPED         = 0x0001
      EXECUTABLE              = 0x0002
      LINE_NUMS_STRIPPED      = 0x0004
      LOCAL_SYMS_STRIPPED     = 0x0008
      AGGRESSIVE_WS_TRIM      = 0x0010
      LARGE_ADDRESS_AWARE     = 0x0020
      I16BIT_MACHINE          = 0x0040
      BYTES_RESERVED_LO       = 0x0080
      I32BIT_MACHINE          = 0x0100
      DEBIG_STRIPPED          = 0x0200
      REMOVABLE_RUN_FROM_SWAP = 0x0400
      NET_RUN_FROM_SWAP       = 0x0800
      SYSTEM                  = 0x1000
      DLL                     = 0x2000
      UP_SYSTEM_ONLY          = 0x4000
      BYTES_RESERVED_HI       = 0x8000
    } -Flags | Out-Null
    
    $IMAGE_MAGIC_SIGNATURE = enum IMAGE_MAGIC_SIGNATURE UInt16 {
      PE32 = 0x010B
      PE64 = 0x020B
    }
    
    enum IMAGE_SUBSYSTEM UInt16 {
      UNKNOWN                  = 0
      NATIVE                   = 1
      WINDOWS_GUI              = 2
      WINDOWS_CUI              = 3
      OS2_CUI                  = 5
      POSIX_CUI                = 7
      NATIVE_WINDOWS           = 8
      WINDOWS_CE_GUI           = 9
      EFI_APPLICATION          = 10
      EFI_BOOT_SERVICE_DRIVER  = 11
      EFI_RUNTIME_DRIVER       = 12
      EFI_ROM                  = 13
      XBOX                     = 14
      WINDOWS_BOOT_APPLICATION = 16
    } | Out-Null
    
    enum IMAGE_DLLCHARACTERISTICS UInt16 {
      DYNAMIC_BASE          = 0x0040
      FORCE_INTEGRITY       = 0x0080
      NX_COMPAT             = 0x0100
      NO_ISOLATION          = 0x0200
      NO_SEH                = 0x0400
      NO_BIND               = 0x0800
      WDM_DRIVER            = 0x2000
      TERMINAL_SERVER_AWARE = 0x8000
    } -Flags | Out-Null
    
    $IMAGE_NT_SIGNATURE = enum IMAGE_NT_SIGNATURE UInt32 {
      VALID_PE_SIGNATURE = 0x00004550
    }
    
    enum IMAGE_SCN Int32 {
      TYPE_NO_PAD            = 0x00000008
      CNT_CODE               = 0x00000020
      CNT_INITIALIZED_DATA   = 0x00000040
      CNT_UNINITIALIZED_DATA = 0x00000080
      LNK_OTHER              = 0x00000100
      LNK_INFO               = 0x00000200
      LNK_REMOVE             = 0x00000800
      LNK_COMDAT             = 0x00001000
      NO_DEFER_SPEC_EXC      = 0x00004000
      GPREL                  = 0x00008000
      MEM_FARDATA            = 0x00008000
      MEM_PURGEABLE          = 0x00020000
      MEM_16BIT              = 0x00020000
      MEM_LOCKED             = 0x00040000
      MEM_PRELOAD            = 0x00080000
      ALIGN_1BYTES           = 0x00100000
      ALIGN_2BYTES           = 0x00200000
      ALIGN_4BYTES           = 0x00300000
      ALIGN_8BYTES           = 0x00400000
      ALIGN_16BYTES          = 0x00500000
      ALIGN_32BYTES          = 0x00600000
      ALIGN_64BYTES          = 0x00700000
      ALIGN_128BYTES         = 0x00800000
      ALIGN_256BYTES         = 0x00900000
      ALIGN_512BYTES         = 0x00A00000
      ALIGN_1024BYTES        = 0x00B00000
      ALIGN_2048BYTES        = 0x00C00000
      ALIGN_4096BYTES        = 0x00D00000
      ALIGN_8192BYTES        = 0x00E00000
      ALIGN_MASK             = 0x00F00000
      LNK_NRELOC_OVFL        = 0x01000000
      MEM_DISCARDABLE        = 0x02000000
      MEM_NOT_CACHED         = 0x04000000
      MEM_NOT_PAGED          = 0x08000000
      MEM_SHARED             = 0x10000000
      MEM_EXECUTE            = 0x20000000
      MEM_READ               = 0x40000000
      MEM_WRITE              = 0x80000000
    } -Flags | Out-Null
    
    $IMAGE_DOS_HEADER = struct IMAGE_DOS_HEADER {
      IMAGE_DOS_SIGNATURE 'e_magic';
      UInt16              'e_cblp';
      UInt16              'e_cp';
      UInt16              'e_crlc';
      UInt16              'e_cparhdr';
      UInt16              'e_minalloc';
      UInt16              'e_maxalloc';
      UInt16              'e_ss';
      UInt16              'e_sp';
      UInt16              'e_csum';
      UInt16              'e_ip';
      UInt16              'e_cs';
      UInt16              'e_lfarlc';
      UInt16              'e_ovno';
      UInt16[]            'e_res ByValArray 4';
      UInt16              'e_oemid';
      UInt16              'e_oeminfo';
      UInt16[]            'e_res2 ByValArray 10';
      UInt32              'e_lfanew';
    }
    
    $IMAGE_OS2_HEADER = struct IMAGE_OS2_HEADER {
      IMAGE_DOS_SIGNATURE 'ne_magic';
      Byte                'ne_ver';
      Byte                'ne_rev';
      UInt16              'ne_enttab';
      UInt16              'ne_cbenttab';
      Uint32              'ne_crc';
      UInt16              'ne_flags';
      UInt16              'ne_autodata';
      UInt16              'ne_heap';
      UInt16              'ne_stack';
      UInt32              'ne_csip';
      UInt32              'ne_sssp';
      UInt16              'ne_cseg';
      UInt16              'ne_cmod';
      UInt16              'ne_cbnrestab';
      UInt16              'ne_segtab';
      UInt16              'ne_rsrctab';
      UInt16              'ne_restab';
      UInt16              'ne_modtab';
      UInt16              'ne_imptab';
      UInt32              'ne_nrestab';
      UInt16              'ne_cmovent';
      UInt16              'ne_align';
      UInt16              'ne_cres';
      Byte                'ne_exetyp';
      Byte                'ne_flagsothers';
      UInt16              'ne_pretthunks';
      UInt16              'ne_psegrefbytes';
      UInt16              'ne_swaparea';
      UInt16              'ne_expver';
    }
    
    $IMAGE_VXD_HEADER = struct IMAGE_VXD_HEADER {
      IMAGE_DOS_SIGNATURE 'e32_magic';
      Byte                'e32_border';
      Byte                'e32_worder';
      UInt32              'e32_level';
      UInt16              'e32_cpu';
      UInt16              'e32_os';
      UInt32              'e32_ver';
      UInt32              'e32_mflags';
      UInt32              'e32_mpages';
      UInt32              'e32_startobj';
      UInt32              'e32_eip';
      UInt32              'e32_stackobj';
      UInt32              'e32_esp';
      UInt32              'e32_pagesize';
      UInt32              'e32_lastpagesize';
      UInt32              'e32_fixupsize';
      UInt32              'e32_fixupsum';
      UInt32              'e32_ldrsize';
      UInt32              'e32_ldrsum';
      UInt32              'e32_objtab';
      UInt32              'e32_objcnt';
      UInt32              'e32_objmap';
      UInt32              'e32_itermap';
      UInt32              'e32_rsrctab';
      UInt32              'e32_rsrccnt';
      UInt32              'e32_restab';
      UInt32              'e32_enttab';
      UInt32              'e32_dirtab';
      UInt32              'e32_dircnt';
      UInt32              'e32_fpagetab';
      UInt32              'e32_frectab';
      UInt32              'e32_impmod';
      UInt32              'e32_impmodcnt';
      UInt32              'e32_impproc';
      UInt32              'e32_pagesum';
      UInt32              'e32_datapage';
      UInt32              'e32_preload';
      UInt32              'e32_nrestab';
      UInt32              'e32_cbnrestab';
      UInt32              'e32_nressum';
      UInt32              'e32_autodata';
      UInt32              'e32_debuginfo';
      UInt32              'e32_debuglen';
      UInt32              'e32_instpreload';
      UInt32              'e32_instdemand';
      UInt32              'e32_heapsize';
      Byte[]              'e32_res3 ByValArray 12';
      UInt32              'e32_winresoff';
      UInt32              'e32_winreslen';
      UInt16              'e32_devid';
      UInt16              'e32_ddkver';
    }
    
    $IMAGE_FILE_HEADER = struct IMAGE_FILE_HEADER {
      IMAGE_FILE_MACHINE         'Machine';
      UInt16                     'NumberOfSections';
      UInt32                     'TimeDateStamp';
      UInt32                     'PointerToSymbolTable';
      UInt32                     'NumberOfSymbols';
      UInt16                     'SizeOfOptionalHeader';
      IMAGE_FILE_CHARACTERISTICS 'Characteristics';
    }
    
    struct IMAGE_DATA_DIRECTORY {
      UInt32 'VirtualAddress';
      UInt32 'Size';
    } | Out-Null
    
    struct IMAGE_OPTIONAL_HEADER32 {
      IMAGE_MAGIC_SIGNATURE    'Magic';
      Byte                     'MajorLinkerVersion';
      Byte                     'MinorLinkerVersion';
      UInt32                   'SizeOfCode';
      UInt32                   'SizeOfInitializedData';
      UInt32                   'SizeOfUninitializedData';
      UInt32                   'AddressOfEntryPoint';
      UInt32                   'BaseOfCode';
      UInt32                   'BaseOfData';
      UInt32                   'ImageBase';
      UInt32                   'SectionAlignment';
      UInt32                   'FileAlignment';
      UInt16                   'MajorOperatingSystemVersion';
      UInt16                   'MinorOperatingSystemVersion';
      UInt16                   'MajorImageVersion';
      UInt16                   'MinorImageVersion';
      UInt16                   'MajorSubsystemVersion';
      UInt16                   'MinorSubsystemVersion';
      UInt32                   'Win32VersionValue';
      UInt32                   'SizeOfImage';
      UInt32                   'SizeOfHeaders';
      UInt32                   'CheckSum';
      IMAGE_SUBSYSTEM          'Subsystem';
      IMAGE_DLLCHARACTERISTICS 'DllCharacteristics';
      UInt32                   'SizeOfStackReserve';
      UInt32                   'SizeOfStackCommit';
      UInt32                   'SizeOfHeapReserve';
      UInt32                   'SizeOfHeapCommit';
      UInt32                   'LoaderFlags';
      UInt32                   'NumberOfRvaAndSizes';
      IMAGE_DATA_DIRECTORY[]   'DataDirectory ByValArray 16';
    } | Out-Null
    
    struct IMAGE_OPTIONAL_HEADER64 {
      IMAGE_MAGIC_SIGNATURE    'Magic';
      Byte                     'MajorLinkerVersion';
      Byte                     'MinorLinkerVersion';
      UInt32                   'SizeOfCode';
      UInt32                   'SizeOfInitializedData';
      UInt32                   'SizeOfUninitializedData';
      UInt32                   'AddressOfEntryPoint';
      UInt32                   'BaseOfCode';
      UInt64                   'ImageBase';
      UInt32                   'SectionAlignment';
      UInt32                   'FileAlignment';
      UInt16                   'MajorOperatingSystemVersion';
      UInt16                   'MinorOperatingSystemVersion';
      UInt16                   'MajorImageVersion';
      UInt16                   'MinorImageVersion';
      UInt16                   'MajorSubsystemVersion';
      UInt16                   'MinorSubsystemVersion';
      UInt32                   'Win32VersionValue';
      UInt32                   'SizeOfImage';
      UInt32                   'SizeOfHeaders';
      UInt32                   'CheckSum';
      IMAGE_SUBSYSTEM          'Subsystem';
      IMAGE_DLLCHARACTERISTICS 'DllCharacteristics';
      UInt64                   'SizeOfStackReserve';
      UInt64                   'SizeOfStackCommit';
      UInt64                   'SizeOfHeapReserve';
      UInt64                   'SizeOfHeapCommit';
      UInt32                   'LoaderFlags';
      UInt32                   'NumberOfRvaAndSizes';
      IMAGE_DATA_DIRECTORY[]   'DataDirectory ByValArray 16'
    } | Out-Null
    
    $IMAGE_NT_HEADERS32 = struct IMAGE_NT_HEADERS32 {
      IMAGE_NT_SIGNATURE      'Signature';
      IMAGE_FILE_HEADER       'FileHeader';
      IMAGE_OPTIONAL_HEADER32 'OptionalHeader';
    }
    
    $IMAGE_NT_HEADERS64 = struct IMAGE_NT_HEADERS64 {
      IMAGE_NT_SIGNATURE      'Signature';
      IMAGE_FILE_HEADER       'FileHeader';
      IMAGE_OPTIONAL_HEADER64 'OptionalHeader';
    }
    
    $IMAGE_SECTION_HEADER = struct IMAGE_SECTION_HEADER {
      String    'Name ByValTStr 7';
      UInt32    'VirtualSize';
      UInt32    'VirtualAddress';
      UInt32    'SizeOfRawData';
      UInt32    'PointerToRawData';
      UInt32    'PointerToRelocations';
      UInt32    'PointerToLinenumbers';
      UInt16    'NumberOfRelocations';
      UInt16    'NumberOfLinenumbers';
      IMAGE_SCN 'Characteristics';
    }
    
    $FileName = Convert-Path $FileName
    #CreateFile, CreateFileMapping, MapViewOfFile and UnmapViewOfFile
    [Object].Assembly.GetType('Microsoft.Win32.Win32Native').GetMethods(
      [Reflection.BindingFlags]40
    ) | ? {
      $_.Name -match '\A(CreateF|MapV|UnmapV).*\Z'
    } | % {
      Set-Variable $_.Name $_
    }
    #other variables
    [Int32]$GENERIC_READ   = 0x80000000
    [UInt32]$PAGE_READONLY = 0x00000002
    [UInt32]$FILE_MAP_READ = 0x00000004
  }
  process {
    try {
      $sfh = $CreateFile.Invoke($null, @(
        $FileName, $GENERIC_READ, [IO.FileShare]::Read, $null, [IO.FileMode]::Open, 0, [IntPtr]::Zero
      ))
      $smh = $CreateFileMapping.Invoke($null, @(
        $sfh, [IntPtr]::Zero, $PAGE_READONLY, [UInt32]0, [UInt32]0, $null
      ))
      $map = $MapViewOfFile.Invoke($null, @(
        $smh, $FILE_MAP_READ, [UInt32]0, [UInt32]0, [UIntPtr]::Zero
      ))
      #IMAGE_DOS_HEADER
      $IMAGE_DOS_HEADER = $map -as $IMAGE_DOS_HEADER
      if ($IMAGE_DOS_HEADER.e_magic -ne $IMAGE_DOS_SIGNATURE::DOS) {
        throw (New-Object Exception('Invalid file format.'))
      }
      $NtHeaderOffset = [IntPtr]($map.ToInt64() + $IMAGE_DOS_HEADER.e_lfanew)
      #IMAGE_NT_HEADERS
      $IMAGE_NT_HEADERS = $NtHeaderOffset -as $IMAGE_NT_HEADERS32
      if ($IMAGE_NT_HEADERS.Signature -ne $IMAGE_NT_SIGNATURE::VALID_PE_SIGNATURE) {
        switch (($IMAGE_NT_HEADERS.Signature -band 0xffff) -as $IMAGE_DOS_SIGNATURE) {
          'OS2' {
            $IMAGE_OS2_HEADER = $NtHeaderOffset -as $IMAGE_OS2_HEADER
            return $IMAGE_OS2_HEADER
          }
          'VXD' {
            $IMAGE_VXD_HEADER = $NtHeaderOffset -as $IMAGE_VXD_HEADER
            return $IMAGE_VXD_HEADER
          }
          default {
            return $IMAGE_DOS_HEADER
          }
        } #switch
      } #if
      #Check bits
      if ($IMAGE_NT_HEADERS.OptionalHeader.Magic -eq $IMAGE_MAGIC_SIGNATURE::PE64) {
        $IMAGE_NT_HEADERS = $ntHeaderOffset -as $IMAGE_NT_HEADERS64
      }
      #Sections
      if (($sec = $IMAGE_NT_HEADERS.FileHeader.NumberOfSections) -ne 0) {
        $SectionOffset = $IMAGE_DOS_HEADER.e_lfanew + 4 + $IMAGE_FILE_HEADER::GetSize() +
                                        $IMAGE_NT_HEADERS.FileHeader.SizeOfOptionalHeader
        0..($sec - 1) | % {
          [Object[]]$Sections = @()
          $NextSection = [IntPtr]($map.ToInt64() + $SectionOffset)
        }{
          $Sections += $NextSection -as $IMAGE_SECTION_HEADER
          $NextSection = [IntPtr]($NextSection.ToInt64() + $IMAGE_SECTION_HEADER::GetSize())
        } #foreach
      } #if
      $DUMPBIN = New-Object PSObject -Property @{
        FileHeader     = $IMAGE_NT_HEADERS.FileHeader
        OptionalHeader = $IMAGE_NT_HEADERS.OptionalHeader
        DataDirectory  = $IMAGE_NT_HEADERS.OptionalHeader.DataDirectory
        Sections       = $Sections
      }
      $DUMPBIN.PSObject.TypeNames.Insert(0, 'DUMPBIN')
      $DUMPBIN
    }
    catch { $_.Exception }
    finally {
      if ($map -ne $null) { $UnmapViewOfFile.Invoke($null, @($map)) | Out-Null }
      if ($smh -ne $null) { $smh.Close() }
      if ($sfh -ne $null) { $sfh.Close() }
    }
  }
  end {}
}

Export-ModuleMember -Function Get-DumpBin

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaB4xwLkHyVOIOfYxz0KL8l9o
# UhCgggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKJvDLZ/Qxi7pGik
# uPxL6dE+yYDHMA0GCSqGSIb3DQEBAQUABIIBAFWP597k4hV7rkyqcUUZksiM6vU4
# RLg1IhbajfcY0eACPgRGe796Uyd/QxYJiOk+zgVxXKItKJJxts9BeSpjlWYUPI43
# Q4/8MQYg4mz+pwI9Y8ZYT4J2EEdBsMGNxXkdbvHdEvrD7JyL+NFZfNp6Gx07DzXp
# vffj/kt4Vqm0XSTKPy3x0CLBBIolZFovQnMY50dauAjCHX6w8p/A1jWElf66V6Mg
# B8ZAflDAtWZ4IQbS3fPFPaHcmeS/6qQM8uyRwUttFnR9EF5F/Ra6oDLp9EzR0PjG
# YcViIG/309BqEXYSYZAEIc6jlsBwZauEDXwYY3dG9kT5kGdPwY46SoQYANg=
# SIG # End signature block
