
configuration SQLInstanceRemovalConfiguration
{
    
    Import-DscResource -Module xMySql
    
    node $AllNodes.NodeName
    {
        
        xMySqlServer MySQLInstance
        {
            Ensure = "Absent"
            RootPassword = $global:cred
            ServiceName = "MySQLInstanceServiceName"
        }
    }
}

<# 
Sample use (parameter values need to be changed according to your scenario):
#>

$global:pwd = ConvertTo-SecureString "pass@word1" -AsPlainText -Force
$global:usrName = "administrator"
$global:cred = New-Object -TypeName System.Management.Automation.PSCredential ($global:usrName,$global:pwd)


SQLInstanceRemovalConfiguration -ConfigurationData .\nodedata.psd1



