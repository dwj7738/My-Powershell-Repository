<#
.SYNOPSIS
    This script is used to deploy and validate SafeHarbor example

.DESCRIPTION
    This script allows you to exercise the SafeHarbor example which sets up a secure environment to run a particular application or service inside of an assume-breached network. This substantially reduces the attack surface of the application or service by configuring a highly customized, application specific environment, by limiting user access and by having “Just Enough” administrative control with full auditing.

.EXAMPLE
    $baseVhdFilePath = "C:\BaseVhd\serverdatacenter_en-us.vhd"
    .\Assert-SafeHarborScenario.ps1 -BaseVhdFilePath $baseVhdFilePath -Validate

.LINK
http://gallery.technet.microsoft.com/scriptcenter/xSafeHarbor-Module-bd705379

http://blogs.msdn.com/b/powershell/archive/2014/07/21/creating-a-secure-environment-using-powershell-desired-state-configuration.aspx

.NOTES
    SafeHarbor scenario uses xMachine synchronization feature (First released with Windows Management Framework 5.0 Experimental July 2014 (KB2969050)) to synchronize Hyper-V Host and Guest VMs.
    Hyper-V Host and BaseVhd must have 'Windows Management Framework 5.0 Experimental July 2014 (KB2969050)' installed to run this example.  
     
    Following steps can be used to make the BaseVhd ready to run the SafeHarbor example:
        1. Mount BaseVhd and copy WMF 5.0 update.
        2. Create a VM using BaseVhd and then install WMF 5.0 on VM.
        3. Run $Env:SystemDrive\Windows\System32\Sysprep\sysprep.exe /generalize /shutdown /oobe

    Run 'Install-Module -Name xActiveDirectory, xComputerManagement, xDhcpServer, xDnsServer, xHyper-V, xNetworking, xPSDesiredStateConfiguration -Force'
    to install the required DSC resources by SafeHarbor example.

    List of DSC resources that should be present on the system:
        - xIPAddress
        - xFirewall
        - xComputer
        - xADDomain
        - xADDomainTrust
        - xADUser
        - xDhcpServerScope
        - xDhcpServerOption
        - xDhcpServerReservation
        - xDnsServerZoneTransfer
        - xDnsServerSecondaryZone
        - xDSCWebService
        - xPSEndpoint
        - xVHD
        - xVhdFile
        - xVMHyperV
        - xVMSwitch   
#>

Param ( 
        # Path to Vhd file that would be used as base image for all the VMs
        [Parameter(Mandatory)]
        [String]$BaseVhdFilePath,

        # Collection of credentials for various user names. If not specified, script will prompt 
        [PSCredential[]]$Credentials,

        # Path where differencing VHDs will be stored 
        [String]$VHDDestinationPath = "$env:SystemDrive\SHVhd",

        # If specified, will run the validation steps at the end of example
        [Switch]$Validate,

        # If specified, pauses the script execution between various stages of example setup 
        [Switch]$PauseBetweenStages        
)

$scriptLocation = $PSScriptRoot

#--------------------------------------------------------------------------#
# Verify prerequisites
#--------------------------------------------------------------------------#
Import-Module $scriptLocation\SafeHarborHelper.psm1

# Verify all the required DSC resources are present on Hyper-V Host.
Test-DscResourcesForSHScenario

# Verify 'Windows Management Framework 5.0 Experimental July 2014 (KB2969050)' update is isntalled on Hyper-V Host.
If($PSVersionTable.BuildVersion -lt '6.4.9789.0') {
    Throw 'Cannot find the required update on Hyper-V Host, please install ''Windows Management Framework 5.0 Experimental July 2014 (KB2969050)'' or higher version of update to run SafeHarbor.'
}

Import-Module $scriptLocation\Configuration\SafeHarborConfiguration.psm1

# Create directory for SafeHarbor Virtual Machines.
mkdir $VHDDestinationPath -ErrorAction SilentlyContinue

# DSC Document location for SafeHarbor VMs
$vmDocLocation = "$scriptLocation\ConfigurationData\VMData"

#--------------------------------------------------------------------------#
# Configure SafeHarbor Scenario
#--------------------------------------------------------------------------#
# Set credential for SafeHarbor users and serialize them into clixml.
Set-SafeHarborUserCreds -Credentials $Credentials

# Install certificates for password encryption
& "$scriptLocation\ConfigurationData\VMData\ImportCerts.ps1"

# Update trusted host settings to trust the SafeHarbor VMs
Set-Item WSMan:\localhost\Client\TrustedHosts * -Force

# Configuration data to setup SafeHarbor VMs and Host machine.
$configData = & "$scriptLocation\ConfigurationData\SafeHarborConfigurationData.ps1" -BaseVhdPath $BaseVhdFilePath -VHDDestinationPath $VHDDestinationPath

# Generate DSC documents for configuring DCHP Server, Corporate Domain Controller, Corporate Client,
# SafeHarbor Domain Controller, SafeHarbor Pull Server, SafeHarbor Management Server and SafeHarbor File Server VMs.
DHCPServer             -ConfigurationData $configData -Role "DHCPServer"   -OutputPath $vmDocLocation\DHCPServer
DomainController       -ConfigurationData $configData -Role "CorpDC"       -OutputPath $vmDocLocation\CorpDC
CorpClient             -ConfigurationData $configData -Role "CorpClient"   -OutputPath $vmDocLocation\CorpClient
DomainController       -ConfigurationData $configData -Role "SHDC"         -OutputPath $vmDocLocation\SHDC
PullServer             -ConfigurationData $configData -Role "SHPullServer" -OutputPath $vmDocLocation\SHPullServer
FileServer             -ConfigurationData $configData -Role "FileServer"   -OutputPath $vmDocLocation\SHPullServer\Configuration
New-DSCCheckSum        -ConfigurationPath $vmDocLocation\SHPullServer\Configuration -OutPath $vmDocLocation\SHPullServer\Configuration -Force

# Configure Hyper-V Host
HyperVHost             -ConfigurationData $configData -Role "HyperVHost"   -OutputPath .  
HyperVHostLCMSettings  -ConfigurationData $configData -Role "HyperVHost"   -OutputPath .  
Set-DscLocalConfigurationManager -Path .\HyperVHostLCMSettings -Verbose -ComputerName localhost
Start-DscConfiguration -Path .\HyperVHost -Wait -Force -Verbose

# Configure DHCPServer to automatically assign an IP address to Corporate and SafeHarbor Domain VMs.
DHCPServerVM           -ConfigurationData $configData -Role "HyperVHost"   -OutputPath . 
Start-DscConfiguration -Path .\DHCPServerVM -Wait -Force -Verbose 

# Configure Corporate Domain Controller using xADDomain resource.
CorpDCVM               -ConfigurationData $configData -Role "HyperVHost"   -OutputPath . 
Start-DscConfiguration -Path .\CorpDCVM -Wait -Force -Verbose

# Corporate Domain Controller configuration is completed but it is still busy updating DNS service.
# Adding sleep so that Domain Controller will be ready to add client to the domain.
Start-Sleep -Seconds 30

# Configure Corporate Client
CorpClientVM           -ConfigurationData $configData -Role "HyperVHost"   -OutputPath . 
Start-DscConfiguration -Path .\CorpClientVM -Wait -Force -Verbose

# Pause script
if($PauseBetweenStages.IsPresent) {
    "`nDONE: Corporate environment is now ready. `nNEXT: Setup SafeHarbor Domain Controller.`n"
    Pause
}

# Configure SafeHarbor Domain Controller using xADDomain resource.
SHDCVM                 -ConfigurationData $configData -Role "HyperVHost"   -OutputPath . 
Start-DscConfiguration -Path .\SHDCVM -Wait -Force -Verbose

# Adding sleep so that Domain Controller will be ready to add client to the domain.
Start-Sleep -Seconds 100

# Pause script
if($PauseBetweenStages.IsPresent) {
    "`nDONE:SafeHarbor Domain Controller is now ready. `nNEXT: Setup SafeHarbor Pull Server.`n"
    Pause
}

# Configure SafeHarbor Pull Server.
SHPullServerVM         -ConfigurationData $configData -Role "HyperVHost"   -OutputPath . 
Start-DscConfiguration -Path .\SHPullServerVM -Wait -Force -Verbose

# Pause script
if($PauseBetweenStages.IsPresent) {
    "`nDONE: Pull Server is now setup in Safeharbor. `nNEXT: Setup SafeHarbor Management Server.`n"
    Pause
}

# Safeharbor Management Server configuration requires PAPA user SID to configure the End Point.
# Get the SID for Corporate\PAPA user.
$domainCredential = Import-CliXml "$scriptLocation\ConfigurationData\VMData\CORPDomainCred.CliXml"
$ADUserSid = Get-ADUserSid -VMName 'CorpDC' -UserName 'PAPA' -VMCredential $domainCredential

# Configure SafeHarbor Management Server by setting up constrained endpoint with RunAs mapped to SafeHarbor\MATA user.
$configData = & "$scriptLocation\ConfigurationData\SafeHarborConfigurationData.ps1" -BaseVhdPath $BaseVhdFilePath -VHDDestinationPath $VHDDestinationPath -ADUserSid $ADUserSid
JeaManagementServer     -ConfigurationData $configData -Role "DelegatedAdmin" -OutputPath $vmDocLocation\SHMgmtSrv 
SHJeaManagementServerVM -ConfigurationData $configData -Role "HyperVHost"     -OutputPath . 
Start-DscConfiguration  -Path .\SHJeaManagementServerVM -Wait -Force -Verbose

# Pause script
if($PauseBetweenStages.IsPresent) {
    "`nDONE: Management Server is now setup in Safeharbor. `nNEXT: Setup SafeHarbor File Server.`n"
    Pause
}

# Configure SafeHarbor File Server, lock down the server by removing built-in Firewall rules, 
# disabling local admin and allowing only specific traffic.
SHFileServerVM         -ConfigurationData $configData -Role "HyperVHost"   -OutputPath . 
Start-DscConfiguration -Path .\SHFileServerVM -Wait -Force -Verbose

# Pause script
if($PauseBetweenStages.IsPresent) {
    "`nDONE: File Server is now setup in Safeharbor. `nNEXT: Validate the SafeHarbor scenario.`n"
    Pause
}

# Delete the MOF files
Remove-Item -Path ".\HyperVHostLCMSettings"   -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path ".\HyperVHost"              -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path ".\DHCPServerVM"            -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path ".\CorpDCVM"                -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path ".\CorpClientVM"            -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path ".\SHDCVM"                  -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path ".\SHPullServerVM"          -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path ".\SHJeaManagementServerVM" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path ".\SHFileServerVM"          -Force -Recurse -ErrorAction SilentlyContinue

#--------------------------------------------------------------------------#
# Validate SafeHarbor Configuration
#--------------------------------------------------------------------------#
if($Validate.IsPresent) {
    $vmCorpClient = "CorpClient"

    Write-Verbose "Validating - Connection with CorpClient." -Verbose
    $resultInfo = @{
        actualResult   = Test-Connection -ComputerName $vmCorpClient -Quiet
        expectedResult = $true
        errorMsg       = 'Failed to connect to CorpClient.'
        successMsg     = 'Validated - Connection successfully established with CorpClient.'
    }
    ValidateResult @resultInfo

    #1. Validate PAPA is allowed to create a SMB Share on SafeHarbor File Server.
    Write-Verbose "Validating - PAPA is allowed to create a SMB Share on SafeHarbor File Server." -Verbose
    $papaCredential = Get-SafeHarborUserCreds -UserName "Corporate\Papa"
    $result = Invoke-Command -ComputerName $vmCorpClient -Authentication Negotiate -Credential $papaCredential -ScriptBlock {
                    Set-Item WSMan:\localhost\Client\TrustedHosts "shmgmtsrv.safeharbor.contoso.com" -Force 
                    $psSession = New-PSSession -ComputerName "shmgmtsrv.safeharbor.contoso.com" -Credential $using:papaCredential -Authentication Negotiate -ConfigurationName secure
                    Invoke-Command -Session $psSession -ScriptBlock { Get-Command 'New-SMBShare' -Source 'ProxyFunctions' }
                }

    $resultInfo = @{
        actualResult   = $result.Name
        expectedResult = 'New-SmbShare' 
        errorMsg       = 'User PAPA is not allowed to create SMB share on SafeHarbor File Server.'
        successMsg     = 'Validated - User PAPA is allowed to create a SMB Share on SafeHarbor File Server.'
    }
    ValidateResult @resultInfo

    #2. Validate PAPA can create a SMB share on SafeHarbor File Server.
    Write-Verbose "Validating - PAPA can create a SMB share on SafeHarbor File Server." -Verbose
    $shareName = 'Share1'
    $result = Invoke-Command -ComputerName $vmCorpClient -Authentication Negotiate -Credential $papaCredential -ScriptBlock {
                    Set-Item WSMan:\localhost\Client\TrustedHosts "shmgmtsrv.safeharbor.contoso.com" -Force 
                    $psSession = New-PSSession -ComputerName "shmgmtsrv.safeharbor.contoso.com" -Credential $using:papaCredential -Authentication Negotiate -ConfigurationName secure
                    Invoke-Command -Session $psSession -ScriptBlock { New-SmbShare -CimSession "shfileserver.safeharbor.contoso.com" -Path 'C:\Program Files' -Name 'Share1' }
                }

    $resultInfo = @{
        actualResult   = $result.Name
        expectedResult = $shareName 
        errorMsg       = "Failed to create $shareName SMBShare."
        successMsg     = "Validated - Successfully created  SMBShare : $shareName."
    }
    ValidateResult @resultInfo

    #3. Validate Share is created on SafeHarbor File Server.
    Write-Verbose "Validating - Share is created on SafeHarbor File Server." -Verbose
    $result = Invoke-Command -ComputerName $vmCorpClient -Authentication Negotiate -Credential $papaCredential -ScriptBlock {
                    Set-Item WSMan:\localhost\Client\TrustedHosts "shmgmtsrv.safeharbor.contoso.com" -Force 
                    $psSession = New-PSSession -ComputerName "shmgmtsrv.safeharbor.contoso.com" -Credential $using:papaCredential -Authentication Negotiate -ConfigurationName secure
                    Invoke-Command -Session $psSession -ScriptBlock { Get-SmbShare -CimSession "shfileserver.safeharbor.contoso.com"-Name 'Share1' }
                }

    $resultInfo = @{
        actualResult   = $result.Name
        expectedResult = $shareName 
        errorMsg       = "Failed to get $shareName SMBShare."
        successMsg     = "Validated - $shareName share is created on SafeHarbor File Server."
    }
    ValidateResult @resultInfo
}
