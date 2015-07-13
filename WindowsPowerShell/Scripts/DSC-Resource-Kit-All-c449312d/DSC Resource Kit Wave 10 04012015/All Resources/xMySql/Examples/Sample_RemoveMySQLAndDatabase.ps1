configuration SQLRemoveInstanceAndDatabaseInstallationConfiguration
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $MySQLInstancePackagePath,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $MySQLInstancePackageName
    )
    
    Import-DscResource -Module xMySql

    node $AllNodes.NodeName
    {
        xMySqlDatabase MySQLDatabase
        {
            Ensure = "Absent"
            Name = "TestDB"
            ConnectionCredential = $global:cred
        }
        
        xMySqlServer MySQLInstance
        {
            Ensure = "Absent"
            ServiceName = "MySQLInstanceServiceName"
            RootPassword = $global:cred
            DependsOn = "[xMySqlDatabase]MySQLDatabase"
        }

        xPackage mySqlInstaller
        {
                    
            Path = $MySQLInstancePackagePath
            ProductId = $Node.PackageProductID 
            Name = $MySQLInstancePackageName
            Ensure = "Absent"
            DependsOn = "[xMySqlInstance]MySQLInstance"
        }
    }
}

<# 
Sample use (parameter values need to be changed according to your scenario):
#>

$global:pwd = ConvertTo-SecureString "pass@word1" -AsPlainText -Force
$global:usrName = "administrator"
$global:cred = New-Object -TypeName System.Management.Automation.PSCredential ($global:usrName,$global:pwd)


SQLRemoveInstanceAndDatabaseInstallationConfiguration `
    -MySQLInstancePackagePath "http://dev.mysql.com/get/Downloads/MySQLInstaller/mysql-installer-community-5.6.17.0.msi" `
    -MySQLInstancePackageName "MySQL Installer" -ConfigurationData .\nodedata.psd1



