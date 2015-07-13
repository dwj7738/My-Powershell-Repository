# Requires a certificate to have been set up that can  be used to encrypt and decrypt credentials.
Param(
[Parameter(Position=0, Mandatory=$True, HelpMessage='Specify the NodeName for the install e.g. TESTSVR01')]
[String] $NodeName
)

# Get the certificate that will be used to encrypt and decrypt credentials.
# For more detail on credential handling in DSC, See Get-EncryptionCertificate in CredentialSample.ps1 on
# http://blogs.msdn.com/b/powershell/archive/2014/01/31/want-to-secure-credentials-in-windows-powershell-desired-state-configuration.aspx
$certificate = dir cert:\LocalMachine\My | where {$_.Subject -eq "CN=<something>" -and $_.PrivateKey.KeyExchangeAlgorithm -and $_.Verify()}

$ConfigData =
@{
    AllNodes = @(
        @{
            NodeName="*"
            Thumbprint = $certificate.Thumbprint
         }

       @{
            NodeName = $NodeName
        }
    )
}

Configuration OuSample
{
    Param
    (
              [Parameter(Mandatory)]
              [PSCredential] $DomainAdminAccount
    )

    Import-DscResource -Module xOu

    Node $NodeName
    {

        WindowsFeature InstallRSAT-AD-PowerShell
        {            
            Ensure = "Present"
            Name = "RSAT-AD-PowerShell"
        }

        xADOrganizationalUnit MyOu
        {
            Ensure = "Present"
            Name = "MyOu"
            Path = (Get-ADDomain).DistinguishedName
            Credential = $DomainAdminAccount
            ProtectedFromAccidentalDeletion = "Yes"
            Description = "This is a sample OU"
            DependsOn = "[WindowsFeature]InstallRSAT-AD-PowerShell"
        }

        LocalConfigurationManager 
        { 
             CertificateId = $node.Thumbprint 
        } 
    }
}
  
     
$MofPath = ".\Mof"
if (!(Test-Path $MofPath))
{
    New-Item $MofPath -ItemType Directory
}

$LogPath = "c:\DSCLogs"
if (!(Test-Path $LogPath))
{
    New-Item $LogPath -ItemType Directory
}

$domainName = (gwmi Win32_NTDomain).DomainName[1].ToLower()
$domainAdminAccount = New-Object System.Management.Automation.PSCredential("$domainName\Administrator", (ConvertTo-SecureString "<password>" -AsPlainText -Force))

OuSample -ConfigurationData $ConfigData -OutputPath .\Mof -DomainAdminAccount $domainAdminAccount

Set-DscLocalConfigurationManager .\Mof

Start-DscConfiguration -Path .\Mof -ComputerName $env:COMPUTERNAME -Wait -Debug

