<#
    Configuration creates Azure SQL Database Server Firewall Rule
#>
configuration CreateSqlDatabaseServerFirewallRule 
{
    param
    (
        $workingDirectory,
        $ruleName,
        $serverName,
        $startIPAddress,
        $endIPAddress,
        $azureSubscriptionName,
        $azurePublishSettingsFile
    )
    
    Import-DscResource -Name MSFT_xAzureSqlDatabaseServerFirewallRule	   
	

    # Verify working directory    if ((test-path $workingDirectory) -eq $false)     {        Write-Warning 'The working directory does not exist.  Exiting script.'        Exit    }

    node localhost 
    {
	    xAzureSqlDatabaseServerFirewallRule firewallRule
        {
		    RuleName = $ruleName		
            ServerName = $serverName    
		    StartIPAddress = $startIPAddress
		    EndIPAddress = $endIPAddress
            AzureSubscriptionName = $azureSubscriptionName            AzurePublishSettingsFile = $azurePublishSettingsFile
	    }
        
        #LocalConfigurationManager 
        #{ 
            #CertificateId = $node.Thumbprint 
        #} 
    }
}

$script:configData = 
@{  
    AllNodes = @(       
                    @{    
                        NodeName = "localhost"  
                        Role = "TestHost"  
                        #CertificateFile = Join-Path $workingdir 'publicKey.cer'
                        #Thumbprint = ''   
                    };  
                );      
}  

#Sample use (please change values of parameters according to your scenario): $workingDirectory = 'C:\test'
$azureSubscriptionName = 'Visual Studio Ultimate with MSDN'
$azurePublishSettingsFile = Join-Path $workingDirectory 'visual.publishsettings'
$ruleName = "ruleName"
$serverName = "serverName"
$startIPAddress = "111.111.111.111"
$endIPAddress = "111.111.111.111"

CreateSqlDatabaseServerFirewallRule -configurationData $script:configData -workingDirectory $workingDirectory `
                  -azureSubscriptionName $azureSubscriptionName -azurePublishSettingsFile $azurePublishSettingsFile `
                  -ruleName $ruleName -serverName $serverName -startIPAddress $startIPAddress -endIPAddress $endIPAddress