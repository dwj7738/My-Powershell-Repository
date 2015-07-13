# Sample configuration to Publish Configuration Archive to Storage

Configuration PublishToStorage
{
    Import-DscResource -Module xAzure

    xAzureVMDscConfiguration Publish
    {
        StorageAccountName          = 'dscazext'
        Ensure                      = 'Present'
        ContainerName               = 'windows-powershell-dsc'
        ConfigurationPath           = Join-Path $pwd Test.ps1
        AzureSubscriptionName       = 'Internal'
        AzurePublishSettingsPath    = Join-Path $pwd Internal.PublishSettings
    }
}

PublishToStorage

Start-DscConfiguration -Wait -Force -Verbose -Path .\PublishToStorage