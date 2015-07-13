############################################################# DSC Azure Test Example - LCM Apply Only## This script configures your local machine to apply DSC# configurations 'only' which means not to include # DSC automatically monitoring for drift or # re-applying the configuration automationally.## Set the folder where your files will live$workingdir = split-path $myinvocation.mycommand.pathConfiguration ApplyOnly{    Node $AllNodes.NodeName     {        # Set Local DSC to ApplyOnly        LocalConfigurationManager        {            ConfigurationMode = 'ApplyOnly'
            #CertificateId = $node.Thumbprint         }    }}$ConfigData=    @{ 
    AllNodes = @(     
                    @{  
                        NodeName = 'localhost' 
                        #CertificateFile = Join-Path $workingdir 'publicKey.cer'
                        #Thumbprint = ''
                    }
                )
}ApplyOnly -OutputPath $workingdir -ConfigurationData $ConfigDataSet-DscLocalConfigurationManager -Path $workingdir -ComputerName localhost -Verbose