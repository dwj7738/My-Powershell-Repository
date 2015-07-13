############################################################# DSC Azure Test Example - SETUP SUBSCRIPTION## Before running this script, do the following:#   * Open PowerShell and run Get-AzurePublishSettingsFile#   * Download the .publishsettings file in to $workingdir## Set the folder where your files will live$workingdir = split-path $myinvocation.mycommand.pathConfiguration CreateAzureSubscription{    Import-DscResource -Module xAzure    Node $AllNodes.NodeName    {        # Setup Azure PreRequisite Resources        xAzureSubscription MSDN        {            Ensure = 'Present'            AzureSubscriptionName = 'Visual Studio Ultimate with MSDN'            AzurePublishSettingsFile = Join-Path $workingdir 'NAME-DATE-credentials.publishsettings'        }    }}$ConfigData=    @{ 
    AllNodes = @(     
                    @{  
                        NodeName = 'localhost'
                    }
                )
}# Create MOFCreateAzureSubscription -OutputPath $workingdir -ConfigurationData $ConfigData# Apply MOFStart-DscConfiguration -ComputerName 'localhost' -wait -force -verbose -path $workingdir