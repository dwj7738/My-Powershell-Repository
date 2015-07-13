configuration DbBackup
{
    param
    (
        [PSCredential]$Credentials,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DatabaseName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SqlServer,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Path,

        [Parameter(Mandatory)]
        [ValidateSet("DACPAC","BACPAC")]
        [ValidateNotNullOrEmpty()]
        [String]$Type,

        [Parameter(Mandatory)]
        [ValidateSet("2008-R2","2012","2014")]
        [ValidateNotNullOrEmpty()]
        [String]$SqlServerVersion

    )
    Node 'localhost'
    { 
        xDBPackage Backup
        {
            SqlServer = $SqlServer
            SqlServerVersion = $SqlServerVersion
            Credentials = $Credentials
            Type = $Type
            DatabaseName = $DatabaseName
            Path = $Path
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

DbBackup -ConfigurationData $ConfigurationData -DatabaseName "dac_db" -Credentials $credential -Path "c:\dsc\apmauth.dacpac" -SqlServer ".\sqlexpress" -SqlServerVersion "2012" -Type "DACPAC"

Start-DscConfiguration -ComputerName "localhost" -Path ".\DbBackup"  -Wait -Force -Verbose