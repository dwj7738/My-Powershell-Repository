function Get-TSLsaSecret {
  <#
    .SYNOPSIS
    Displays LSA Secrets from local computer.

    .DESCRIPTION
    Extracts LSA secrets from HKLM:\\SECURITY\Policy\Secrets\ on a local computer.
    The CmdLet must be run with elevated permissions, in 32-bit mode and requires permissions to the security key in HKLM.

    .PARAMETER Key
    Name of Key to Extract. if the parameter is not used, all secrets will be displayed.

    .EXAMPLE
    Enable-TSDuplicateToken
    Get-TSLsaSecret

    .EXAMPLE
    Enable-TSDuplicateToken
    Get-TSLsaSecret -Key KeyName

    .LINK
    http://www.truesec.com

    .NOTES
    Goude 2012, TreuSec
  #>

  param(
    [Parameter(Position = 0,
      ValueFromPipeLine= $true
    )]
    [Alias("RegKey")]
    [string[]]$RegistryKey
  )

Begin {
# Check if User is Elevated
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent())
if($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -ne $true) {
  Write-Warning "Run the Command as an Administrator"
  Break
}

# Check if Script is run in a 32-bit Environment by checking a Pointer Size
if([System.IntPtr]::Size -eq 8) {
  Write-Warning "Run PowerShell in 32-bit mode"
  Break
}



# Check if RegKey is specified
if([string]::IsNullOrEmpty($registryKey)) {
  [string[]]$registryKey = (Split-Path (Get-ChildItem HKLM:\SECURITY\Policy\Secrets | Select -ExpandProperty Name) -Leaf)
}

# Create Temporary Registry Key
if( -not(Test-Path "HKLM:\\SECURITY\Policy\Secrets\MySecret")) {
  mkdir "HKLM:\\SECURITY\Policy\Secrets\MySecret" | Out-Null
}

$signature = @"
[StructLayout(LayoutKind.Sequential)]
public struct LSA_UNICODE_STRING
{
  public UInt16 Length;
  public UInt16 MaximumLength;
  public IntPtr Buffer;
}

[StructLayout(LayoutKind.Sequential)]
public struct LSA_OBJECT_ATTRIBUTES
{
  public int Length;
  public IntPtr RootDirectory;
  public LSA_UNICODE_STRING ObjectName;
  public uint Attributes;
  public IntPtr SecurityDescriptor;
  public IntPtr SecurityQualityOfService;
}

public enum LSA_AccessPolicy : long
{
  POLICY_VIEW_LOCAL_INFORMATION = 0x00000001L,
  POLICY_VIEW_AUDIT_INFORMATION = 0x00000002L,
  POLICY_GET_PRIVATE_INFORMATION = 0x00000004L,
  POLICY_TRUST_ADMIN = 0x00000008L,
  POLICY_CREATE_ACCOUNT = 0x00000010L,
  POLICY_CREATE_SECRET = 0x00000020L,
  POLICY_CREATE_PRIVILEGE = 0x00000040L,
  POLICY_SET_DEFAULT_QUOTA_LIMITS = 0x00000080L,
  POLICY_SET_AUDIT_REQUIREMENTS = 0x00000100L,
  POLICY_AUDIT_LOG_ADMIN = 0x00000200L,
  POLICY_SERVER_ADMIN = 0x00000400L,
  POLICY_LOOKUP_NAMES = 0x00000800L,
  POLICY_NOTIFICATION = 0x00001000L
}

[DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
public static extern uint LsaRetrievePrivateData(
  IntPtr PolicyHandle,
  ref LSA_UNICODE_STRING KeyName,
  out IntPtr PrivateData
);

[DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
public static extern uint LsaStorePrivateData(
  IntPtr policyHandle,
  ref LSA_UNICODE_STRING KeyName,
  ref LSA_UNICODE_STRING PrivateData
);

[DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
public static extern uint LsaOpenPolicy(
  ref LSA_UNICODE_STRING SystemName,
  ref LSA_OBJECT_ATTRIBUTES ObjectAttributes,
  uint DesiredAccess,
  out IntPtr PolicyHandle
);

[DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
public static extern uint LsaNtStatusToWinError(
  uint status
);

[DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
public static extern uint LsaClose(
  IntPtr policyHandle
);

[DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
public static extern uint LsaFreeMemory(
  IntPtr buffer
);
"@

Add-Type -MemberDefinition $signature -Name LSAUtil -Namespace LSAUtil
}

  Process{
    foreach($key in $RegistryKey) {
      $regPath = "HKLM:\\SECURITY\Policy\Secrets\" + $key
      $tempRegPath = "HKLM:\\SECURITY\Policy\Secrets\MySecret"
      $myKey = "MySecret"
      if(Test-Path $regPath) {
        Try {
          Get-ChildItem $regPath -ErrorAction Stop | Out-Null
        }
        Catch {
          Write-Error -Message "Access to registry Denied, run as NT AUTHORITY\SYSTEM" -Category PermissionDenied
          Break
        }      

        if(Test-Path $regPath) {
          # Copy Key
          "CurrVal","OldVal","OupdTime","CupdTime","SecDesc" | ForEach-Object {
            $copyFrom = "HKLM:\SECURITY\Policy\Secrets\" + $key + "\" + $_
            $copyTo = "HKLM:\SECURITY\Policy\Secrets\MySecret\" + $_

            if( -not(Test-Path $copyTo) ) {
              mkdir $copyTo | Out-Null
            }
            $item = Get-ItemProperty $copyFrom
            Set-ItemProperty -Path $copyTo -Name '(default)' -Value $item.'(default)'
          }
        }
        # Attributes
        $objectAttributes = New-Object LSAUtil.LSAUtil+LSA_OBJECT_ATTRIBUTES
        $objectAttributes.Length = 0
        $objectAttributes.RootDirectory = [IntPtr]::Zero
        $objectAttributes.Attributes = 0
        $objectAttributes.SecurityDescriptor = [IntPtr]::Zero
        $objectAttributes.SecurityQualityOfService = [IntPtr]::Zero

        # localSystem
        $localsystem = New-Object LSAUtil.LSAUtil+LSA_UNICODE_STRING
        $localsystem.Buffer = [IntPtr]::Zero
        $localsystem.Length = 0
        $localsystem.MaximumLength = 0

        # Secret Name
        $secretName = New-Object LSAUtil.LSAUtil+LSA_UNICODE_STRING
        $secretName.Buffer = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($myKey)
        $secretName.Length = [Uint16]($myKey.Length * [System.Text.UnicodeEncoding]::CharSize)
        $secretName.MaximumLength = [Uint16](($myKey.Length + 1) * [System.Text.UnicodeEncoding]::CharSize)

        # Get LSA PolicyHandle
        $lsaPolicyHandle = [IntPtr]::Zero
        [LSAUtil.LSAUtil+LSA_AccessPolicy]$access = [LSAUtil.LSAUtil+LSA_AccessPolicy]::POLICY_GET_PRIVATE_INFORMATION
        $lsaOpenPolicyHandle = [LSAUtil.LSAUtil]::LSAOpenPolicy([ref]$localSystem, [ref]$objectAttributes, $access, [ref]$lsaPolicyHandle)

        if($lsaOpenPolicyHandle -ne 0) {
          Write-Warning "lsaOpenPolicyHandle Windows Error Code: $lsaOpenPolicyHandle"
          Continue
        }

        # Retrieve Private Data
        $privateData = [IntPtr]::Zero
        $ntsResult = [LSAUtil.LSAUtil]::LsaRetrievePrivateData($lsaPolicyHandle, [ref]$secretName, [ref]$privateData)

        $lsaClose = [LSAUtil.LSAUtil]::LsaClose($lsaPolicyHandle)

        $lsaNtStatusToWinError = [LSAUtil.LSAUtil]::LsaNtStatusToWinError($ntsResult)

        if($lsaNtStatusToWinError -ne 0) {
          Write-Warning "lsaNtsStatusToWinError: $lsaNtStatusToWinError"
        }

        [LSAUtil.LSAUtil+LSA_UNICODE_STRING]$lusSecretData =
        [LSAUtil.LSAUtil+LSA_UNICODE_STRING][System.Runtime.InteropServices.marshal]::PtrToStructure($privateData, [LSAUtil.LSAUtil+LSA_UNICODE_STRING])

        Try {
          [string]$value = [System.Runtime.InteropServices.marshal]::PtrToStringAuto($lusSecretData.Buffer)
          $value = $value.SubString(0, ($lusSecretData.Length / 2))
        }
        Catch {
          $value = ""
        }

        if($key -match "^_SC_") {
          # Get Service Account
          $serviceName = $key -Replace "^_SC_"
          Try {
            # Get Service Account
            $service = Get-WmiObject -Query "SELECT StartName FROM Win32_Service WHERE Name = '$serviceName'" -ErrorAction Stop
            $account = $service.StartName
          }
          Catch {
            $account = ""
          }
        } else {
          $account = ""
        }

        # Return Object
        New-Object PSObject -Property @{
          Name = $key;
          Secret = $value;
          Account = $Account
        } | Select-Object Name, Account, Secret, @{Name="ComputerName";Expression={$env:COMPUTERNAME}}
      } else {
        Write-Error -Message "Path not found: $regPath" -Category ObjectNotFound
      }
    }
  }
  end {
    if(Test-Path $tempRegPath) {
      Remove-Item -Path "HKLM:\\SECURITY\Policy\Secrets\MySecret" -Recurse -Force
    }
  }
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvaac8DCausTv28cACZcx9pX3
# VNagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPKPXkknYBb1bQSd
# Oq7NXERvDfFaMA0GCSqGSIb3DQEBAQUABIIBACxrJ21Qf3GI4AJfBBVYTaTUTrnB
# iiHL4LU4aPK8v1bVM7m/B63OgbEl1BGSBLZRAURW82H69w2JZRcW1FzCB40Rr9k5
# cTI0MUU77/1kfUhPKdkRM8kpBsGtYDTvrCLMKz9B+7AbKrpfulTkBCl/EZJbr0g/
# dkEUsxom/tjqAQWoruOuIbRK0L8wmO9WGaI6kx3tHvr++xUC6a9E57exS5xoACxf
# KQCJ+mPt2qcXH4wqrn5OhqYdcx8xqfRbrp5lVMkIzGg0QSuc1rmDRZjoAiMgujGG
# HUXChVjt7ovzzc2aM+qEr8crMpmdskAq/DRMaRJfeL42hsLA438oa61WqH0=
# SIG # End signature block
