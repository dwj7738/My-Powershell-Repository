$BitLockDrive = get-wmiobject -ComputerName "." -namespace root\CIMv2\Security\MicrosoftVolumeEncryption `
        -class Win32_EncryptableVolume `
        | select DriveLetter, IsVolumeInitializedforProtection
foreach( $drive in $BitLockDrive) {
#$Write-Output ($drive.DriveLetter)
If (($drive.DriveLetter -eq "C:" ) -and ($drive.IsVolumeInitializedforProtection -like "False") )
    {
   # This Drive is Not Encrypted
    $drive.DriveLetter
    $drive.lockstatus
    $drive.IsVolumeInitializedForProtection
    }
}


     