#Get-Bitlocker-Info.ps1
#John Puskar, Department of Chemistry, The Ohio State University, 07/23/11
#johnpuskar (gmail)
#build 025
#reference: http://www.buit.org/2010/08/18/howto-bitlocker-status-reporting-in-sccm-2007/
 
#GLOBAL VARS
$scriptogWriteOut = $null
$scriptogWriteOut = $false        #true = write debug output to screen
 
#choose log file path
$logFileName = "bitlocker.txt"
<#$progx86 = ${ENV:\PROGRAMFILES(X86)}
If($progx86 -eq $null -or $progx86 -eq "")
    {$ldClientPath = ${ENV:\PROGRAMFILES} + "\LANDesk\LDClient\"}
Else
    {$ldClientPath = ${ENV:\PROGRAMFILES(X86)} + "\LANDesk\LDClient\"}
$script:gLogFile = $ldClientPath  + $logFileName
#>
$scriptLogFile = "c:\temp\bitlocker.txt"
#Skip if not Vista or higher
$blnSkip = $null
$blnSkip = $true
$objOS = Get-WmiObject Win32_OperatingSystem
If($objOS.BuildNumber -ge 6000)
    {$blnSkip = $false}
 
Function Get-BLAttribute($objBDEDrive,$BLAttrib)
    {
        $strAttribVal = $null
 
        Switch($BLAttrib)
            {
                Default {}
                "ProtectionStatus"
                    {
                        $protectionStatus = $null
                        $protectionStatus = ($objBDEDrive.GetProtectionStatus()).ProtectionStatus
                        $strProtectionStatus = $null
                        Switch ($ProtectionStatus)
                            {
                                0 { $strProtectionStatus = "PROTECTION OFF" }
                                1 { $strProtectionStatus = "PROTECTION ON" }
                                2 { $strProtectionStatus = "PROTECTION UNKNOWN"}
                            }
                        $strAttribVal = $strProtectionStatus
                    }
                "EncryptionMethod"
                    {
                        $encryptionMethod = $null
                        $encryptionMethod = ($objBDEDrive.GetEncryptionMethod()).EncryptionMethod
                        $strEncryptionMethod = $null
                        Switch ($encryptionMethod)
                            {
                                -1 { $strEncryptionMethod = "The volume has been fully or partially encrypted with an unknown algorithm and key size." }
                                0 { $strEncryptionMethod = "The volume is not encrypted." }
                                1 { $strEncryptionMethod = "AES 128 WITH DIFFUSER" }
                                2 { $strEncryptionMethod = "AES 256 WITH DIFFUSER" }
                                3 { $strEncryptionMethod = "AES 128" }
                                4 { $strEncryptionMethod = "AES 256" }
                            }
                        $strAttribVal = $strEncryptionMethod
                    }
                "VolumeKeyProtectorID"
                    {
                        $VolumeKeyProtectorID = $null
                        $VolumeKeyProtectorID = ($objBDEDrive.GetKeyProtectors($i)).VolumeKeyProtectorID
                        If ($VolumeKeyProtectorID -ne $Null)
                            {
                                $KeyProtectorIDTypes = $null
                                Switch ($i)
                                    {
                                        1 {$KeyProtectorIDTypes = "Trusted Platform Module (TPM)"}
                                        2 {$KeyProtectorIDTypes += ",External key"}
                                        3 {$KeyProtectorIDTypes += ",Numeric password"}
                                        4 {$KeyProtectorIDTypes += ",TPM And PIN"}
                                        5 {$KeyProtectorIDTypes += ",TPM And Startup Key"}
                                        6 {$KeyProtectorIDTypes += ",TPM And PIN And Startup Key"}
                                        7 {$KeyProtectorIDTypes += ",Public Key"}
                                        8 {$KeyProtectorIDTypes += ",Passphrase"}
                                        Default {$KeyProtectorIDTypes = "None"}
                                    }
                            }
                        $strAttribVal = $KeyProtectorIDTypes
                    }
                "Version"
                    {
                        $version = $null
                        $version = ($objBDEDrive.GetVersion()).Version
                        $strVersion = $null
                        Switch ($Version)
                            {
                                0 { $strVersion = "UNKNOWN" }
                                1 { $strVersion = "VISTA" }
                                2 { $strVersion = "Windows 7" }
                            }
                        $strAttribVal = $strVersion
                    }
            }
 
        Return $strAttribVal
 
    }
 
Function Get-BLInfo
    {
        $arrAttributes = @()
        $arrAttributes += "label"
        $arrAttributes += "name"
        $arrAttributes += "driveLetter"
        $arrAttributes += "fileSystem"
        $arrAttributes += "capacity"
        $arrAttributes += "deviceID"
        $arrAttributes += "serialNumber"
        $arrAttributes += "bootVolume"
        $arrAttributes += "systemVolume"
 
        $arrBLAttributes = @()
        $arrBLAttributes += "ProtectionStatus"
        $arrBLAttributes += "EncryptionMethod"
        $arrBLAttributes += "VolumeKeyProtectorID"
        $arrBLAttributes += "Version"
 
        $i = 0
        $msgs = @()
 
        $blnBitlockerOn = $null
        $blnBitlockerOn = $false
        $arrEncryptedVols = $null
        $arrEncryptedVols = Get-WmiObject win32_EncryptableVolume -Namespace root\CIMv2\Security\MicrosoftVolumeEncryption -ErrorAction SilentlyContinue
        If($arrEncryptedVols -eq $null -or $arrEncryptedVols -eq "")
            {$blnBitlockerOn = $false}
        Else
            {
                $blnBitlockerOn = $false
                $arrEncryptedVols | % {
                    If($_.ProtectionStatus -eq 1)
                        {$blnBitlockerOn = $true}
                }
            }
 
        #write-host -f red "DEBUG: bitlocker on: $blnbitlockerOn"
        $intBitlockerRollup = $null
        $intBitlockerRollup = 1
 
        $arrLocalVolumes = @()
        $arrLocalVolumes = Get-WmiObject Win32_Volume | where-object {$_.DriveType -eq 3}
        $arrLocalVolumes | % {
            $objVolume = $_
            #gather regular info
            $arrAttributes | % {
                $strAttribute = $null
                $strAttribute = $_
                $strAttribValue = $null
                $strAttribValue = $objVolume.$strAttribute
                #write messages
                $userMsg = $null
                $userMsg = "Volume " + $i + " " + $strAttribute + ": " + $strAttribValue
                If($script:gWriteOut -eq $true){Write-Host -f green $userMsg}
                $LANDeskMsg = $null
                $LANDeskMsg = "Bitlocker Info - Volume" + $i + " - " + $strAttribute + " = " + $strAttribValue
                $msgs += $LANDeskMsg
            }
 
            #bitlocker enabled?
            $blnVolumeBitlocked = $null
            $blnVolumeBitlocked = $false
            If($blnBitlockerOn -eq $true)
                {
                    $objBLVol = $null
                    $objBLVol = $arrEncryptedVols | Where-Object {$_.Driveletter -eq $objVolume.driveLetter}
                    If($objBLVol -eq $null)
                        {
                            $blnVolumeBitlocked = $false
                            #write messages
                            $userMsg = $null
                            $userMsg = "Volume " + $i + " BitlockerEnabled: False"
                            If($script:gWriteOut -eq $true){Write-Host -f green $userMsg}
                            $LANDeskMsg = $null
                            $LANDeskMsg = "Bitlocker Info - Volume" + $i + " - BitlockerEnabled = False"
                            $msgs += $LANDeskMsg
                        }
                    Else
                        {
                            $blnVolumeBitlocked = $true
                            $arrBLAttributes | % {
                                $strBLAttribute = $_
                                $strBLAttributeVal = Get-BLAttribute $objBLVol $strBLattribute
                                #write messages
                                $userMsg = $null
                                $userMsg = "Volume " + $i + " " + $strAttribute + ": " + $strAttribValue
                                If($script:gWriteOut -eq $true){Write-Host -f green $userMsg}
                                $LANDeskMsg = $null
                                $LANDeskMsg = "Bitlocker Info - Volume" + $i + " - BL_" + $strBLAttribute + " = " + $strBLAttributeVal
                                $msgs += $LANDeskMsg
                            }
                        }
                    If($blnVolumeBitlocked -ne $true -and `
                        $objVolume.Label -ne "BDEDrive" -and `
                        $objVolume.Label -ne "System Reserved" -and `
                        $intBitlockerRollup -ne 0)
                        {$intBitlockerRollup = 0}
                }
            Else
                {
                    #write messages
                    $userMsg = $null
                    $userMsg = "Volume " + $i + " BitlockerEnabled: False"
                    If($script:gWriteOut -eq $true){Write-Host -f green $userMsg}
                    $LANDeskMsg = $null
                    $LANDeskMsg = "Bitlocker Info - Volume" + $i + " - BitlockerEnabled = False"
                    $msgs += $LANDeskMsg
                    $intBitlockerRollup = 0
                }
 
            $i++
        }
 
        $strBLRollup = $null
        $strBLRollup = ""
        If($blnBitlockerOn -eq $true)
            {
                If($intBitlockerRollup -eq 0)
                    {$strBLRollup = "Insufficiently Protected"}
                Else
                    {$strBLRollup = "Fully Protected"}
            }
        Else
            {$strBLRollup = "Not Protected"}
 
        #write messages
        $userMsg = $null
        $userMsg = "Bitlocker Rollup: " + $strBLRollup
        If($script:gWriteOut -eq $true){Write-Host -f green $userMsg}
        $LANDeskMsg = $null
        $LANDeskMsg = "Bitlocker Info - Bitlocker Rollup = " + $strBLRollup
        $msgs += $LANDeskMsg
 
        Return $msgs
    }
 
#Get bitlocker info (main loop)
$msgs = $null
If($blnSkip -eq $false)
    {
        $msgs = $null
        $msgs = Get-BLInfo
    }
Else
    {
        If($script:gWriteOut -eq $true){Write-Host -f yellow "Bitlocker is not available on this Operating System."}
        $msgs += "Bitlocker Info - Bitlocker Rollup = NA"
    }
 
#compile messages
If(($msgs -is [array]) -eq $false)
    {[array]$msgs = @($msgs)}
 
#write output
If((Test-Path $scriptLogFile) -eq $true)
    {remove-item $scriptLogFile -force | out-null}
New-Item -ItemType file $scriptLogFile | out-null
$msgs | %{
    $msg = $null
    $msg = $_
    If($gWriteOut -eq $true){Write-host -f yellow $msg}
    Add-Content $scriptLogFile $msg
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUy/z66svyx7LGI0vrGl6rIewv
# 4OqgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFOMVwRcIyNfGxADQ
# CNpXWMS4bEkfMA0GCSqGSIb3DQEBAQUABIIBAAQkTCnf3iJydUJ9iU6Nz0FT4OB7
# +bsmgCtQkHDi1Tml6dBj+ta5WvkJWElTZjluSdj50RRrZkxqy/27/BzOgVjNniWc
# JTZ52lRpMMGZVrV4qJBXfSOySrIILDDZW62PMFeNESmWkNTmnFijerQMLFQj/HHm
# oqNEt6o4Exrmo9UDzRDTWScZ0VEgG2PEDZSmvG7dq1DrKd5MV6B4K6LVJWmrxOdp
# JmPLzLOE6YoZ0xAgmOgqX9aht1PPw+WxqirfadndgtHzimJmgCqexdjoUVagl44N
# s56Ty1pG2nGrKzeAwKNV7mts7grIjC4amsdvcw97ckA/Et8WnUTEGov85dA=
# SIG # End signature block
