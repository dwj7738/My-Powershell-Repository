###################
# Configuration script to grant full access to given my sql database for given my sql user. 
# It assumes that mySql is installed on local machine with root user $RootUser and root password $global:pwd
###################

configuration MySQLGrantConfiguration
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $UserName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $DatabaseName
    )
    
    Import-DscResource -Module xMySql
    
    node ("localhost")
    {                  
        xMySqlGrant mySQLGrant
        {
            UserName = $UserName
            DatabaseName = $DatabaseName
            PermissionType = "ALL PRIVILEGES"
            Ensure = "Present"               
            ConnectionCredential = $global:MySQLRootCredential
            
        }
    }
}


$global:pwd = ConvertTo-SecureString "pass@word1" -AsPlainText -Force
$global:RootUser = "root"
$global:MySQLRootCredential = New-Object -TypeName System.Management.Automation.PSCredential ($global:RootUser,$global:pwd)

#Create localhost.mof
CreateMySQLUserConfiguration -output "$env:temp\MySQLGrantConfiguration"

