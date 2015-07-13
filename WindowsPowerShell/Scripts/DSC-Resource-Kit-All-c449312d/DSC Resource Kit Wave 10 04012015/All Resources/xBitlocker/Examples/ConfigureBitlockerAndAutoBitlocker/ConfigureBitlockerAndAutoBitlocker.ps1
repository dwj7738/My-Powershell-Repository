Configuration ConfigureBitlockerAndAutoBitlocker
{
    Import-DscResource -Module xBitlocker

    Node 'E15-1'
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

        #This example sets up AutoBitlocker for any drive of type Fixed with a RecoveryPasswordProtector only.
        xBLAutoBitlocker AutoBitlocker
        {
            DriveType                 = 'Fixed'
            PrimaryProtector          = 'RecoveryPasswordProtector'
            RecoveryPasswordProtector = $true
            UsedSpaceOnly             = $true

            DependsOn                 = '[xBLBitlocker]Bitlocker' #Don't enable AutoBL until the OS drive has been encrypted
        }
    }
}

ConfigureBitlockerAndAutoBitlocker

#Start-DscConfiguration -Verbose -Wait -Path .\ConfigureBitlockerAndAutoBitlocker -ComputerName "E15-1"