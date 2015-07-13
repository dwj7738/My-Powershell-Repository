#######################################################################################################################
# File:             Add-on.ModuleManagement.psd1                                                                      #
# Author:           Kirk Munro                                                                                        #
# Publisher:        Quest Software, Inc.                                                                              #
# Copyright:        © 2010 Quest Software, Inc. All rights reserved.                                                  #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.ModuleManagement module.                                                      #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this command:         #
#                       Import-Module -Name Add-on.ModuleManagement                                                   #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
#######################################################################################################################

@{

# Script module or binary module file associated with this manifest
ModuleToProcess = 'Add-on.ModuleManagement.psm1'

# Version number of this module.
ModuleVersion = '1.0.0.1'

# ID used to uniquely identify this module
GUID = '{50ed9d45-0514-41c0-8d58-4bbba3313d28}'

# Author of this module
Author = 'Kirk Munro'

# Company or vendor of this module
CompanyName = 'Quest Software, Inc.'

# Copyright statement for this module
Copyright = '© 2011 Quest Software, Inc. All rights reserved.'

# Description of the functionality provided by this module
Description = 'A Script Editor Add-on that provides useful module management capabilities.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Name of the Windows PowerShell host required by this module
<# Commented out due to a bug
PowerShellHostName = 'PowerGUIScriptEditor'
#>

# Minimum version of the Windows PowerShell host required by this module
<# Commented out due to a bug
PowerShellHostVersion = '2.1.1.1202'
#>

# Minimum version of the .NET Framework required by this module
DotNetFrameworkVersion = '2.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '2.0.50727'

# Processor architecture (None, X86, Amd64, IA64) required by this module
ProcessorArchitecture = 'None'

# Modules that must be imported into the global environment prior to importing
# this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to
# importing this module
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @()

# Modules to import as nested modules of the module specified in
# ModuleToProcess
NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
ModuleList = @()

# List of all files packaged with this module
FileList = @(
	'.\Add-on.ModuleManagement.psm1'
	'.\Add-on.ModuleManagement.psd1'
	'.\Resources\NewModule.ico'
	'.\Resources\NewManifest.ico'
	'.\Resources\ConvertToModule.ico'
)

# Private data to pass to the module specified in ModuleToProcess
PrivateData = ''

}

# SIG # Begin signature block
# MIIOhgYJKoZIhvcNAQcCoIIOdzCCDnMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULoWkxJU9C8JXh0zRx/4Q9SbS
# ZFqggguFMIIFczCCBFugAwIBAgIQVDMCUo2yXdJ9VuMdT5/s7jANBgkqhkiG9w0B
# AQUFADCBtDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8w
# HQYDVQQLExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTswOQYDVQQLEzJUZXJtcyBv
# ZiB1c2UgYXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYSAoYykxMDEuMCwG
# A1UEAxMlVmVyaVNpZ24gQ2xhc3MgMyBDb2RlIFNpZ25pbmcgMjAxMCBDQTAeFw0x
# MTAzMDMwMDAwMDBaFw0xNDAzMDIyMzU5NTlaMIG2MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKQ2FsaWZvcm5pYTEUMBIGA1UEBxMLQWxpc28gVmllam8xHTAbBgNVBAoU
# FFF1ZXN0IFNvZnR3YXJlLCBJbmMuMT4wPAYDVQQLEzVEaWdpdGFsIElEIENsYXNz
# IDMgLSBNaWNyb3NvZnQgU29mdHdhcmUgVmFsaWRhdGlvbiB2MjEdMBsGA1UEAxQU
# UXVlc3QgU29mdHdhcmUsIEluYy4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQCZUApfRti5qDWpZJP9X7WliUx3W4I3DEZMNZ7N9XpYrzrvj+RZi8WwgH0Z
# 8ylo0zqMwBcPfMH6BR64005alBJCP27JgrsxOKv5FI9e8cgQCmoQT8/gBByOHhlt
# /hYBatlFB4uxIfvDtIkWrqtVdC92aqtVVP+yCQVRkWiYfo6OfNYcoGTqIIrSTwfS
# XMd21pFnFO1wButj0AcfSoIGcK1UGNpdg3D5cYOs9mv5KTHaIz4JXVL1xAscRwZi
# SqKbM7Xc9VMOM4FJYYt4JrosM7BXIzk3ZGtvyIfXbs4UXxC/5Vr4exO04DsR4Rg7
# RRZGT0RvjU2j40I82xpsoLGhR1qNAgMBAAGjggF7MIIBdzAJBgNVHRMEAjAAMA4G
# A1UdDwEB/wQEAwIHgDBABgNVHR8EOTA3MDWgM6Axhi9odHRwOi8vY3NjMy0yMDEw
# LWNybC52ZXJpc2lnbi5jb20vQ1NDMy0yMDEwLmNybDBEBgNVHSAEPTA7MDkGC2CG
# SAGG+EUBBxcDMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LnZlcmlzaWduLmNv
# bS9ycGEwEwYDVR0lBAwwCgYIKwYBBQUHAwMwcQYIKwYBBQUHAQEEZTBjMCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC52ZXJpc2lnbi5jb20wOwYIKwYBBQUHMAKGL2h0
# dHA6Ly9jc2MzLTIwMTAtYWlhLnZlcmlzaWduLmNvbS9DU0MzLTIwMTAuY2VyMB8G
# A1UdIwQYMBaAFM+Zqep7JvRLyY6P1/AFJu/j0qedMBEGCWCGSAGG+EIBAQQEAwIE
# EDAWBgorBgEEAYI3AgEbBAgwBgEBAAEB/zANBgkqhkiG9w0BAQUFAAOCAQEAVoxv
# js9TBh3o1cyZJMBqt5mHMjGPVsowHCfkzFyBoB85hOqZD7mU570h0Sr4wYUH+tgT
# bDlgsJQzFhBoG23a67VPYy8c1lZeEq9Ix2qimk6BM3855B0rj3wn713wtO9gdDZK
# jgJTP7TG0NBAczIR1f0kpvMe/IdyOuX0cY2AUiCeX7aad/q2BQ2fAhKvWASCqCSF
# fkeF8NOo5PRYOlmls6FtlQ4P66qOX7srE584PAqlDoC/noUL7RCm9ZRABk00j0N6
# wm4GnIeDKzs1sAaarHlYzlmXsPqvjSgU2rR4jHGZ49h3Ry+Qbxk8niK3E2L8LQQ0
# w5ix9FsZ7G357XXZvTCCBgowggTyoAMCAQICEFIA5aolVvwahu2WydRLM8cwDQYJ
# KoZIhvcNAQEFBQAwgcoxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwg
# SW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE6MDgGA1UECxMx
# KGMpIDIwMDYgVmVyaVNpZ24sIEluYy4gLSBGb3IgYXV0aG9yaXplZCB1c2Ugb25s
# eTFFMEMGA1UEAxM8VmVyaVNpZ24gQ2xhc3MgMyBQdWJsaWMgUHJpbWFyeSBDZXJ0
# aWZpY2F0aW9uIEF1dGhvcml0eSAtIEc1MB4XDTEwMDIwODAwMDAwMFoXDTIwMDIw
# NzIzNTk1OVowgbQxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5j
# LjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE7MDkGA1UECxMyVGVy
# bXMgb2YgdXNlIGF0IGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEgKGMpMTAx
# LjAsBgNVBAMTJVZlcmlTaWduIENsYXNzIDMgQ29kZSBTaWduaW5nIDIwMTAgQ0Ew
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD1I0tepdeKuzLp1Ff37+TH
# Jn6tGZj+qJ19lPY2axDXdYEwfwRof8srdR7NHQiM32mUpzejnHuA4Jnh7jdNX847
# FO6G1ND1JzW8JQs4p4xjnRejCKWrsPvNamKCTNUh2hvZ8eOEO4oqT4VbkAFPyad2
# EH8nA3y+rn59wd35BbwbSJxp58CkPDxBAD7fluXF5JRx1lUBxwAmSkA8taEmqQyn
# bYCOkCV7z78/HOsvlvrlh3fGtVayejtUMFMb32I0/x7R9FqTKIXlTBdOflv9pJOZ
# f9/N76R17+8V9kfn+Bly2C40Gqa0p0x+vbtPDD1X8TDWpjaO1oB21xkupc1+NC2J
# AgMBAAGjggH+MIIB+jASBgNVHRMBAf8ECDAGAQH/AgEAMHAGA1UdIARpMGcwZQYL
# YIZIAYb4RQEHFwMwVjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cudmVyaXNpZ24u
# Y29tL2NwczAqBggrBgEFBQcCAjAeGhxodHRwczovL3d3dy52ZXJpc2lnbi5jb20v
# cnBhMA4GA1UdDwEB/wQEAwIBBjBtBggrBgEFBQcBDARhMF+hXaBbMFkwVzBVFglp
# bWFnZS9naWYwITAfMAcGBSsOAwIaBBSP5dMahqyNjmvDz4Bq1EgYLHsZLjAlFiNo
# dHRwOi8vbG9nby52ZXJpc2lnbi5jb20vdnNsb2dvLmdpZjA0BgNVHR8ELTArMCmg
# J6AlhiNodHRwOi8vY3JsLnZlcmlzaWduLmNvbS9wY2EzLWc1LmNybDA0BggrBgEF
# BQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLnZlcmlzaWduLmNvbTAd
# BgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUHAwMwKAYDVR0RBCEwH6QdMBsxGTAX
# BgNVBAMTEFZlcmlTaWduTVBLSS0yLTgwHQYDVR0OBBYEFM+Zqep7JvRLyY6P1/AF
# Ju/j0qedMB8GA1UdIwQYMBaAFH/TZafC3ey78DAJ80M5+gKvMzEzMA0GCSqGSIb3
# DQEBBQUAA4IBAQBWIuY0pMRhy0i5Aa1WqGQP2YyRxLvMDOWteqAif99HOEotbNF/
# cRp87HCpsfBP5A8MU/oVXv50mEkkhYEmHJEUR7BMY4y7oTTUxkXoDYUmcwPQqYxk
# bdxxkuZFBWAVWVE5/FgUa/7UpO15awgMQXLnNyIGCb4j6T9Emh7pYZ3MsZBc/D3S
# jaxCPWU21LQ9QCiPmxDPIybMSyDLkB9djEw0yjzY5TfWb6UgvTTrJtmuDefFmveh
# tCGRM2+G6Fi7JXx0Dlj+dRtjP84xfJuPG5aexVN2hFucrZH6rO2Tul3IIVPCglNj
# rxINUIcRGz1UUpaKLJw9khoImgUux5OlSJHTMYICazCCAmcCAQEwgckwgbQxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMWVmVy
# aVNpZ24gVHJ1c3QgTmV0d29yazE7MDkGA1UECxMyVGVybXMgb2YgdXNlIGF0IGh0
# dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEgKGMpMTAxLjAsBgNVBAMTJVZlcmlT
# aWduIENsYXNzIDMgQ29kZSBTaWduaW5nIDIwMTAgQ0ECEFQzAlKNsl3SfVbjHU+f
# 7O4wCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZI
# hvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcC
# ARUwIwYJKoZIhvcNAQkEMRYEFLBHHIMoE+a3PK/a9v1fXJskI//gMA0GCSqGSIb3
# DQEBAQUABIIBAB8okMWQVmFjQApS1k135o3oddYjGCZ6PxovOLqNrp5DL/DU/zaF
# 1SPqiOnIiM0U4voG3mTwMAxop+c+r72SSjVUYcrdeNTK77uP2Js6pixJOgvy7z2W
# vOafSLIFzR4Yaf7U90DCN0051klcRrRUstWG2s+3/sA3FMfhpONPzHe51/cEJvZI
# O2EgjIyBfZuVO3E+Epaf8HNV8syKWFyu+Q32w51aYpTztKlIoiT8k6ET94l18Lhv
# l0204bKO3QDA/PqlMH0jF9fbe723ToFrbDIwRIbSzjjpgjanI2mRBLgICdY7Aql5
# drK4r3AQ/NTQWEumaKD6jZrOHRGR8pqWT2o=
# SIG # End signature block
