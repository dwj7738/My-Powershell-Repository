Configuration ConfigureBitlockerOnOSDrive
{
    Import-DscResource -Module xBitlocker

    Node "E15-1"
    {
        #First install the required Bitlocker features
        WindowsFeature BitlockerFeature
        {
            Name                 = 'Bitlocker'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true
        }

        WindowsFeature BitlockerToolsFeature
        {
            Name                 = 'RSAT-Feature-Tools-Bitlocker'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true
        }

		#This example enables Bitlocker on the Operating System drive using both a RecoveryPasswordProtector and a StartupKeyProtector
        xBLBitlocker Bitlocker
        {
            MountPoint                = 'C:'
            PrimaryProtector          = 'RecoveryPasswordProtector'
            StartupKeyProtector       = $true
            StartupKeyPath            = 'A:'
            RecoveryPasswordProtector = $true
            AllowImmediateReboot      = $true
            UsedSpaceOnly             = $true

            DependsOn                 = '[WindowsFeature]BitlockerFeature','[WindowsFeature]BitlockerToolsFeature'
        }
    }
}

ConfigureBitlockerOnOSDrive

#Start-DscConfiguration -Verbose -Wait -Path .\ConfigureBitlockerOnOSDrive -ComputerName "E15-1"