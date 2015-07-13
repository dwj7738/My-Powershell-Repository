###################
# Configuration script to create my sql user. It assumes that mySql is installed on local machine with root user $RootUser and root password $global:pwd
###################

configuration CreateMySQLUserConfiguration
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )
    
    Import-DscResource -Module xMySql
    $mySQLUserCredential = New-Object -TypeName System.Management.Automation.PSCredential ($Name,$global:pwd)
    node ("localhost")
    {                  
        xMySqlUser NewMySqlUser1
        {
            Name = $Name
            Credential = $mySQLUserCredential
            Ensure = "Present"
            ConnectionCredential = $global:MySQLRootCredential
            
        }
    }
}


$global:pwd = ConvertTo-SecureString "pass@word1" -AsPlainText -Force
$global:RootUser = "root"
$global:MySQLRootCredential = New-Object -TypeName System.Management.Automation.PSCredential ($global:RootUser,$global:pwd)

#Create localhost.mof
CreateMySQLUserConfiguration -output "$env:temp\CreateMySQLUserConfiguration"

