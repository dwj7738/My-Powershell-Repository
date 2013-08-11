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