
# DHCP Server Configuration
Configuration DHCPServer
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Import-DscResource -ModuleName xNetworking, xComputerManagement, xDhcpServer

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        User Administrator
        {
            Ensure           = 'Present' 
            UserName         = 'Administrator'
            Password         = (Import-Clixml $Node.DHCPAdminCredFile)
        }
        
        xIPAddress DHCPNetwork
        {
            IPAddress        = $Node.IPAddress
            InterfaceAlias   = $Node.InterfaceAlias
            SubnetMask       = $Node.PrefixLength
            DependsOn        = '[User]Administrator'
        }

        xComputer MachineName
        {
            Name             = $Node.MachineName
            DependsOn        = '[xIPAddress]DHCPNetwork'
        }

        WindowsFeature DHCP
        {
            Ensure           = 'Present'
            Name             = 'DHCP'
            DependsOn        = '[xComputer]MachineName'
        }

        xDhcpServerScope Scope
        {
            Ensure           = 'Present'
            Name             = $Node.ScopeName
            IPStartRange     = $Node.StartRange
            IPEndRange       = $Node.EndRange
            SubnetMask       = $Node.SubnetMask
            LeaseDuration    = $Node.LeaseDurationDays
            State            = 'Active'
            DependsOn        = '[WindowsFeature]DHCP'
        }

        xDhcpServerOption DNSIP
        {
            Ensure             = 'Present'
            ScopeID            = $Node.ScopeId
            DnsServerIPAddress = $Node.DNSServerIP
            DependsOn          = '[xDhcpServerScope]Scope'
        }

        foreach($Reservation in $Node.IPReservations)
        {
            xDhcpServerReservation $Reservation.Name
            {
                Ensure           = 'Present'
                ClientMACAddress = $Reservation.MAC
                ScopeID          = $Node.ScopeID
                IPAddress        = $Reservation.IP
                DependsOn        = '[xDhcpServerScope]Scope'
            }
        }

        # Resource for xMachine synchronization
        Log "CompletionIndicator_$($Node.MachineName)"
        {
            Message          = 'Completed'
            DependsOn        = '[xDhcpServerScope]Scope'
        }
    }
}

# Domain Controller Configuration
Configuration DomainController
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Import-DscResource -ModuleName xComputerManagement, xActiveDirectory, xDnsServer

    Node $AllNodes.Where({$_.Role -eq $Role}).NodeName
    {
        # When VM is promoted as Domain Controller, local Administrator also
        # gets promoted to Domain\Administrator.
        # Reset .\Administrator password.
        User Administrator
        {
            Ensure           = 'Present' 
            UserName         = 'Administrator'
            Password         = (Import-Clixml $Node.DomainCredFile)
        }

        xComputer MachineName
        {
            Name             = $Node.MachineName
            DependsOn        = '[User]Administrator'
        }

        WindowsFeature ADDS
        {
            Ensure           = 'Present'
            Name             = 'AD-Domain-Services'
            DependsOn        = '[xComputer]MachineName'
        }

        xADDomain Forest
        {
            DomainName                    = $Node.DomainName
            DomainAdministratorCredential = (Import-Clixml $Node.DomainCredFile)
            SafemodeAdministratorPassword = (Import-Clixml $Node.DomainCredFile)
            DependsOn                     = '[WindowsFeature]ADDS'
        }  
                
        xDnsServerZoneTransfer Setting
        {
            Name             = $Node.DomainName
            Type             = 'Specific'
            SecondaryServer  = $Node.SecondaryDNSServer
            DependsOn        = '[xADDomain]Forest'
        }

        xDnsServerSecondaryZone SafeHarbor
        {
            Name             = $Node.SecondaryZoneDomain
            MasterServers    = $Node.SecondaryDNSServer
            Ensure           = 'Present'
            DependsOn        = '[xADDomain]Forest'
        }

        if($Node.TrustDomainName)
        {
            xADDomainTrust TrustDomain
            {
                Ensure                              = 'Present'
                SourceDomainName                    = $Node.SourceDomainName
                TargetDomainName                    = $NOde.TrustDomainName
                TargetDomainAdministratorCredential = Import-CliXMl ($Node.TrustDomainCred)
                TrustDirection                      = $Node.TrustDirection
                TrustType                           = $Node.TrustType
                DependsOn                           = '[xDnsServerZoneTransfer]Setting'
            }
        }

        foreach($User in $Node.Users)
        {
            xADUser $User.UserName
            {
                Ensure                        = 'Present'
                UserName                      = $User.UserName
                Password                      = (Import-Clixml $User.UserCredFile)
                DomainName                    = $Node.DomainName
                DomainAdministratorCredential = (Import-Clixml $Node.DomainCredFile)
                DependsOn                     = '[xDnsServerZoneTransfer]Setting'
            }
        }

        # Resource for xMachine synchronization
        Log "CompletionIndicator_$($Node.MachineName)"
        {
            Message          = "Completed"
            DependsOn        = "[xDnsServerZoneTransfer]Setting"
        }
    }
}

# Corporate Client Configuration
Configuration CorpClient
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Import-DscResource -ModuleName xComputerManagement

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        Group Administrator
        {
            Ensure           = 'Present'
            GroupName        = 'Administrators'
            MembersToInclude = @('Corporate\PAPA','Corporate\DeptHead')
            Credential       = (Import-CliXML $Node.DomainCredFile)            
        }

        Group RemoteDesktop
        {
            Ensure           = 'Present'
            GroupName        = 'Remote Desktop Users'
            Members          = @('Corporate\User1','Corporate\PAPA','Corporate\DeptHead')
            Credential       = (Import-CliXML $Node.DomainCredFile)
        }

        xComputer NameAndDomain
        {
            Name             = $Node.MachineName
            DomainName       = $Node.DomainName
            Credential       = (Import-CliXML $Node.DomainCredFile)
            DependsOn        = '[Group]Administrator'
        }


        # Resource for xMachine synchronization
        Log "CompletionIndicator_$($Node.MachineName)"
        {
            Message          = 'Completed'
            DependsOn        = '[xComputer]NameAndDomain'
        }
    }
}

# SafeHarbor Pull Server Configuration
Configuration PullServer
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Import-DscResource -ModuleName xComputerManagement, xPSDesiredStateConfiguration

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        User Administrator
        {
            Ensure           = 'Present' 
            UserName         = 'Administrator'
            Disabled         = $true
        }

        WindowsFeature DSCService
        {
            Ensure           = 'Present'
            Name             = 'DSC-Service'
            DependsOn        = '[User]Administrator'
        }

        xDSCWebService ODataEP
        {
            Ensure                = 'Present' 
            EndpointName          = 'PSDSCPullServer'
            CertificateThumbPrint = $Node.PullCert
            ModulePath            = $Node.ModulePath
            ConfigurationPath     = $Node.ConfigurationPath
            DependsOn             = '[WindowsFeature]DSCService'
        }

        xComputer NameAndDomain
        {
            Name             = $Node.MachineName
            DomainName       = $Node.DomainName
            Credential       = (Import-CliXML $Node.DomainCredFile)
            DependsOn        = "[xDSCWebService]ODataEP"
        }

        # Resource for xMachine synchronization
        Log "CompletionIndicator_$($Node.MachineName)"
        {
            Message          = 'Completed'
            DependsOn        = '[xComputer]NameAndDomain'
        }
    }
}

# SafeHarbor File Server Configuration
Configuration FileServer
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Import-DscResource -ModuleName xComputerManagement, xNetworking

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        xComputer NameAndDomain
        {
            Name             = $Node.MachineName
            DomainName       = $Node.DomainName
            Credential       = (Import-CliXML $Node.DomainCredFile)
        }

        # Remove all built-in firewall rules
        foreach ($rule in $Node.AbsentInRules)
        {
            xFirewall $rule.Name
            {
                Ensure       = 'Present';
                Access       = 'NotConfigured'
                Name         = $rule.DisplayName;
                Direction    = 'Inbound';
                State        = 'Disabled';
                Protocol     = $rule.Protocol;
                DependsOn    = '[xComputer]NameAndDomain'
            }
        }

        xFirewall HttpsForPullServer
        {
            Ensure           = 'Present'
            Access           = 'Allow'
            Name             = 'DSC HTTPS'
            RemotePort       = '8080';
            Protocol         = 'TCP';
            Direction        = 'Outbound';
            State            = 'Enabled';
            DependsOn        = '[xComputer]NameAndDomain'
        }

        WindowsFeature FileServer
        {
            Ensure           = 'Present'
            Name             = 'File-Services'
            DependsOn        = '[xComputer]NameAndDomain'
        }

        WindowsFeature WebServer
        {
            Ensure           = 'Absent'
            Name             = 'Web-Server'
            DependsOn        = '[xComputer]NameAndDomain'
        }

        # Remove all built-in File firewall rules
        foreach ($rule in $Node.AbsentInFileRules)
        {
            xFirewall $rule.Name
            {
                Ensure       = 'Present';
                Name         = $rule.DisplayName;
                Access       = 'NotConfigured'
                Direction    = 'Inbound';
                State        = 'Disabled';
                Protocol     = $rule.Protocol;
                DependsOn    = '[WindowsFeature]FileServer'
            }
        }
                        
        # Open selective ports & protocols
        foreach ($rule in $Node.AllowedInRules)
        {
            xFirewall $rule.Name
            {
                Ensure       = 'Present';
                Access       = 'Allow';
                Name         = $rule.DisplayName;
                LocalPort    = $rule.Port;
                Protocol     = $rule.Protocol;
                State        = 'Enabled';
                Direction    = 'Inbound';
                DependsOn    = '[WindowsFeature]FileServer' 
            }
        }

        Group MATA
        {
            GroupName        = 'Administrators'
            Ensure           = 'Present'
            MembersToInclude = @('safeharbor\MATA')
            Credential       = (Import-Clixml $Node.DomainCredFile)
            DependsOn        = '[xComputer]NameAndDomain'
        }

        User Administrator
        {
            Ensure           = 'Present' 
            UserName         = 'Administrator'
            Disabled         = $true
        }

        # Resource for xMachine synchronization
        Log "CompletionIndicator_$($Node.MachineName)"
        {
            Message          = 'Completed'
            DependsOn        = '[User]Administrator'
        }
    }
}

# SafeHarbor Management Server Configuration
Configuration JeaManagementServer
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Import-DscResource -ModuleName xComputerManagement, xPSDesiredStateConfiguration

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        xComputer NameAndDomain
        {
            Name             = $Node.MachineName
            DomainName       = $Node.DomainName
            Credential       = (Import-CliXML $Node.DomainCredFile)
        }

        xPSEndpoint Secure
        {
            Ensure                 = 'Present'
            Name                   = $Node.EPName
            RunAsCredential        = (Import-CliXml $Node.RunAsCredFile)
            SecurityDescriptorSDDL = $Node.SDDL
            StartupScript          = $Node.StartupScript
            DependsOn              = '[xComputer]NameAndDomain' 
        }

        User Administrator
        {
            Ensure           = 'Present' 
            UserName         = 'Administrator'
            Disabled         = $true
            DependsOn        = '[xPSEndpoint]Secure'
        }

        # Resource for xMachine synchronization
        Log "CompletionIndicator_$($Node.MachineName)"
        {
            Message          = 'Completed'
            DependsOn        = '[User]Administrator'
        }
    }
}

# Configuration to setup Virtual Machine
Configuration VirtualMachine
{
    Param(
            [Parameter(Mandatory)]
            [Hashtable]$VMConfig,

            [Switch]$SkipVhdFileCopy)

    Import-DscResource -ModuleName xHyper-V, xNetworking

    xVHD VHD
    {
        ParentPath           = $Node.BaseVhdPath
        Name                 = $VMConfig.MachineName
        Path                 = Split-Path $Node.VHDDestinationPath
    }

    if(-not $SkipVhdFileCopy.IsPresent) {
        xVhdFile CopyToVhd
        {
            VhdPath          = $Node.VHDDestinationPath -f $VMConfig.MachineName
            FileDirectory    = $VMConfig.FilesToCopy | % {
                                        MSFT_xFileDirectory {
                                            SourcePath      =  $_.Source 
                                            DestinationPath =  $_.Destination
                                        }
            }
            DependsOn        =  '[xVHD]VHD'
        }
    }

    xIPAddress HostNetwork
    {
        IPAddress            = $Node.IPAddress
        InterfaceAlias       = $Node.InterfaceAlias
        SubnetMask           = $Node.PrefixLength
    }
 
    xVMHyperV VirtualMachine
    {
        Name                 = $VMConfig.MachineName
        VhDPath              = $Node.VHDDestinationPath -f $VMConfig.MachineName
        SwitchName           = $Node.SwitchName
        State                = $Node.VMState
        StartupMemory        = $VMConfig.MemorySizeofVM
        MACAddress           = $VMConfig.MACAddress 
        DependsOn            = '[xVhdFile]CopyToVhd'            
    }

    WaitForAll WaitForVM
    {
        ResourceName         = "[Log]CompletionIndicator_$($VMConfig.MachineName)"
        NodeName             = @($VMConfig.MachineName)
        RetryintervalSec     = $Node.RetryintervalSec
        RetryCount           = $Node.RetryCount
        Credential           = (Import-Clixml $VMConfig.AdminUserCredFile)
        DependsOn            = @('[xVMHyperV]VirtualMachine')
    }
}

# Hyper-V Host Configuration
Configuration HyperVHost
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Import-DscResource -ModuleName xHyper-V

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        # Ensure HyperV feature is present
        WindowsFeature HyperV
        {
            Ensure              = 'Present'
            Name                = 'Hyper-V'
        }

        xVMSwitch VirtualSwitch
        {
            Ensure              = 'Present'
            Name                = $Node.SwitchName 
            Type                = $Node.SwitchType  
        }
    }
}

# Configuration to setup Host LocalConfigurationManager.
Configuration HyperVHostLCMSettings
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
       LocalConfigurationManager
       {
            CertificateID = $Node.CertificateID
       }
    }
}

# Host configuration to setup DHCP Server
Configuration DHCPServerVM
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        VirtualMachine DHCPServer
        {
            VMConfig         = $Node.DHCPServer
        }
    }
}

# Host configuration to setup Corporate Domain Controller
Configuration CorpDCVM
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        VirtualMachine CorpDC
        {
            VMConfig         = $Node.CorpDC
        }
    }
}

# Host configuration to setup Corporate Client
Configuration CorpClientVM
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        VirtualMachine CorpClient
        {
            VMConfig         = $Node.CorpClient
        }
    }
}

# Host configuration to setup SafeHarbor Domain Controller
Configuration SHDCVM
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        VirtualMachine SHDC
        {
            VMConfig         = $Node.SHDC
        }
    }
}

# Host configuration to setup SafeHarbor Pull Server
Configuration SHPullServerVM
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        VirtualMachine SHPullServer
        {
            VMConfig         = $Node.SHPullServer
        }
    }
}

# Host configuration to setup SafeHarbor Management Server
Configuration SHJeaManagementServerVM
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        VirtualMachine SHMgmtSrv
        {
            VMConfig         = $Node.SHMgmtSrv
        }
    }
}

# Host configuration to setup SafeHarbor File Server
Configuration SHFileServerVM
{
    Param(
            [Parameter(Mandatory)]
            [string]$Role)

    Node $AllNodes.Where{$_.Role -eq $Role}.NodeName
    {
        VirtualMachine SHFileServer
        {
            VMConfig         = $Node.SHFileServer
        }
    }
}