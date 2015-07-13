$assemblylist = "Microsoft.SqlServer.Dac.dll",
                "Microsoft.SqlServer.Smo.dll"
$sqlpsreg110="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps110"
$sqlpsreg100="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps"

configuration DacDeploy
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Ensure,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DatabaseName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SqlServer,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SqlServerVersion,

        [String]$DacPacPath,

        [String]$BacPacPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$NodeName,

        [PSCredential]
        $Credentials,

        [string]$DacPacApplicationName

    )
     
    
    Node 'localhost'
    { 
        xDatabase DeployDac
        {
            Ensure = $Ensure
            SqlServer = $SqlServer
            SqlServerVersion = $SqlServerVersion
            DatabaseName = $DatabaseName
            Credentials = $Credentials
            BacPacPath =  $BacPacPath
        } 
    } 
}

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName="*"
            PSDscAllowPlainTextPassword=$true
        }
        @{
            NodeName="localhost"
        }
    )
}
$password = "Zodiac!99" | ConvertTo-SecureString -asPlainText -Force
$username = "sa" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)

DacDeploy -ConfigurationData $ConfigurationData -Ensure "Absent" -DatabaseName "dbr1" -SqlServer ".\sqlexpress" -SqlServerVersion "2012" -NodeName "localhost" -Credentials $credential -BacPacPath C:\bacpac\Database.bacpac
Start-DscConfiguration  -ComputerName "localhost" -Path .\DacDeploy -Wait -Force -Verbose
