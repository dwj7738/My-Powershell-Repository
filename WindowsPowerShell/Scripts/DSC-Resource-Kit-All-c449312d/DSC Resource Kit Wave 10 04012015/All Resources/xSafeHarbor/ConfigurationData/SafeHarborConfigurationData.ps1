<#
    Configuration data for -
         - DHCP Server
         - Corporate Domain Controller
         - Corporate Client
         - SafeHarbor Domain Controller
         - SafeHarbor Management Server
         - SafeHarbor Pull Server
         - SafeHarbor File Server
         - Hyper-V Host
#>

param ([string]$BaseVhdPath, [string]$ADUserSid, [string]$VHDDestinationPath)

$ConfigDataLocation = Split-Path $MyInvocation.MyCommand.Definition
Import-Module $ConfigDataLocation\..\SafeHarborHelper.psm1

$xNetworkingModulePath         = Get-DscResourceModulePath -DscResourceName 'xFirewall'
$xComputerManagementModulePath = Get-DscResourceModulePath -DscResourceName 'xComputer'
$xDhcpServerModulePath         = Get-DscResourceModulePath -DscResourceName 'xDhcpServerReservation'
$xActiveDirectoryModulePath    = Get-DscResourceModulePath -DscResourceName 'xADDomain'
$xDnsServerModulePath          = Get-DscResourceModulePath -DscResourceName 'xDnsServerZoneTransfer'
$xPSDesiredStateConfigurationModulePath = Get-DscResourceModulePath -DscResourceName 'xDSCWebService'

@{
    AllNodes = @(

        # Certificate ID for password encryption
        @{
            NodeName                    = "*"
            CertificateID               = "497258FCCFFFA0F38268BBD970B337D25C871D6D"
        }

        # DHCP Server configuration data
        @{
            NodeName              = "0df6ddb0-a958-406b-9694-9994928fa0d8" 
            MachineName           = "DHCPServer"
            Role                  = "DHCPServer"              
            DHCPAdminCredFile     =  "$ConfigDataLocation\VMData\DHCPSrvCred.clixml"
            IPAddress             = "192.168.10.5"
            InterfaceAlias        = "*Ethernet*"
            PrefixLength          = 24
            ScopeName             = "SafeHarborDemo"
            ScopeId               = "192.168.10.0"
            StartRange            = "192.168.10.7"
            EndRange              = "192.168.10.254"
            SubnetMask            = "255.255.255.0"
            LeaseDurationDays     = "1"
            DNSServerIP           = "192.168.10.2","192.168.10.1"
            IPReservations        = @(
                @{
                    Name          = "CorpDC"
                    Mac           = "00155D8A54A0"
                    IP            = "192.168.10.1"
                }
                @{
                    Name          = "SHDC"
                    Mac           = "00155D8A54A1"
                    IP            = "192.168.10.2"
                }
                @{
                    Name          = "SHMgmtSrv"
                    Mac           = "00155D8A54A2"
                    IP            = "192.168.10.3"
                }
                @{
                    Name          = "SHPullServer"
                    Mac           = "00155D8A54A3"
                    IP            = "192.168.10.4"
                }                
            )
        };

        # Corporate Domain Controller configuration data
        @{
            NodeName              = "41120e02-7e85-4a89-bae3-2e4443424b62"
            MachineName           = "CorpDC"
            Role                  = "CorpDC"
            DomainName            = "corporate.contoso.com"
            SecondaryDNSServer    = "192.168.10.2"
            SecondaryZoneDomain   = "safeharbor.contoso.com"
            DomainCredFile        = "$ConfigDataLocation\VMData\CORPDomainCred.clixml"
            Users = @(
                @{
                    UserName      = "User1"
                    UserCredFile  = "$ConfigDataLocation\VMData\CORPUserCred.clixml"
                }
                @{
                    UserName      = "PAPA"
                    UserCredFile  = "$ConfigDataLocation\VMData\CORPPapaCred.clixml"
                }
                @{
                    UserName      = "DeptHead"
                    UserCredFile  = "$ConfigDataLocation\VMData\CORPDeptHeadCred.clixml"
                }
            )
        };

        # Corporate Domain Client configuration data
        @{
            NodeName              = "3b748ea1-cda5-4a68-aa4d-c88fbf03dd33"
            MachineName           = "CorpClient"
            Role                  = "CorpClient"
            DomainName            = "corporate.contoso.com"
            DomainCredFile        = "$ConfigDataLocation\VMData\CORPDomainCred.clixml"
        };

        # SafeHarbor Domain Controller configuration data
        @{
            NodeName              = "85ec034b-f343-4e26-bb60-6d564e9865e0"
            MachineName           = "SHDC"
            Role                  = "SHDC"
            DomainName            = "safeharbor.contoso.com"
            SecondaryDNSServer    = "192.168.10.1"
            SecondaryZoneDomain   = "corporate.contoso.com"
            DomainCredFile        = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
            Users = @(
                @{
                    UserName      = "MATA"
                    UserCredFile  = "$ConfigDataLocation\VMData\SHMataCred.clixml"
                }
            )
            SourceDomainName      = "safeharbor.contoso.com"         
            TrustDomainName       = "corporate.contoso.com"
            TrustDomainCred       = "$ConfigDataLocation\VMData\CORPDomainCred.clixml"
            TrustDirection        = "Outbound"
            TrustType             = "External"
        };

        # SafeHarbor Pull Server configuration data
        @{
            NodeName              = "85ec034b-f343-4e26-bb60-6d564e986561"
            Role                  = "SHPullServer"
            MachineName           = "SHPullServer"                        
            DomainName            = "safeharbor.contoso.com"
            DomainCredFile        = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
            PullCert              = "9FE0BB64E4790CFFCFEB84C95C136BEB70B5F93B"
            ModulePath            = "$env:PROGRAMFILES\DscService\Modules"
            ConfigurationPath     = "$env:PROGRAMFILES\DscService\Configuration"  
        };

        # SafeHarbor Management Server configuration data
        @{
            NodeName              = "15dde6d1-6a1c-4b15-858a-51d703bfed29"
            MachineName           = "SHMgmtSrv"
            Role                  = "DelegatedAdmin"
            DomainName            = "safeharbor.contoso.com"
            DomainCredFile        = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
            EPName                = "secure"
            RunAsCredFile         = "$ConfigDataLocation\VMData\SHMataCred.clixml"
            SDDL                  = "O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;$ADUserSid)(A;;GA;;;RM)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)"
            StartupScript         = "$env:SystemDrive\Scripts\Startup.ps1"
        };

        # SafeHarbor File Server VM configuration data
        @{
            NodeName              = "8cac052d-d3d4-423e-b088-f93979094d11"
            Role                  = "FileServer"
            MachineName           = "SHFileServer"
            DomainName            = "safeharbor.contoso.com"
            DomainCredFile        = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
            AbsentInRules         = @(
                @{
                    Name          = "CoreNet ICMPv6-In"
                    DisplayName   = "Core Networking - Destination Unreachable (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
		        @{
                    Name          = "CoreNet ICMPv4-In"
                    DisplayName   = "Core Networking - Destination Unreachable Fragmentation Needed (ICMPv4-In)"; 
                    Protocol      = "ICMPv4"
                }
		        @{
                    Name          = "CoreNet DHCP-In"
                    DisplayName   = "Core Networking - Dynamic Host Configuration Protocol (DHCP-In)"; 
                    Protocol      = "UDP"
                }
		        @{
                    Name          = "CoreNet DHCPv6-In"
                    DisplayName   = "Core Networking - Dynamic Host Configuration Protocol for IPv6(DHCPV6-In)"; 
                    Protocol      = "UDP"
                }
		        @{
                    Name          = "CoreNet IGMP-In"
                    DisplayName   = "Core Networking - Internet Group Management Protocol (IGMP-In)"; 
                    Protocol      = "2"
                }
		        @{
                    Name          = "CoreNet TCP-In"
                    DisplayName   = "Core Networking - IPHTTPS (TCP-In)"; 
                    Protocol      = "TCP"
                }
		        @{
                    Name          = "CoreNet IPv6-In"
                    DisplayName   = "Core Networking - IPv6 (IPv6-In)"; 
                    Protocol      = "41"
                }
		        @{
                    Name          = "CoreNet MultiListener-In"
                    DisplayName   = "Core Networking - Multicast Listener Done (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
		        @{
                    Name          = "CoreNet MultiListener-Query-In"
                    DisplayName   = "Core Networking - Multicast Listener Query (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
		        @{
                    Name          = "CoreNet MultiListener-Report-In"
                    DisplayName   = "Core Networking - Multicast Listener Report (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
		        @{
                    Name          = "CoreNet MultiListener-Reportv2-In"
                    DisplayName   = "Core Networking - Multicast Listener Report v2 (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
	            @{
                    Name          = "CoreNet NeighborDisc-Ad-In"
                    DisplayName   = "Core Networking - Neighbor Discovery Advertisement (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
		        @{
                    Name          = "CoreNet NeighborDisc-Sol-In"
                    DisplayName   = "Core Networking - Neighbor Discovery Solicitation (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
		        @{
                    Name          = "CoreNet PacketBig-In"
                    DisplayName   = "Core Networking - Packet Too Big (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
		        @{
                    Name          = "CoreNet Parameter-In"
                    DisplayName   = "Core Networking - Parameter Problem (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
		        @{
                    Name          = "CoreNet Router-Ad-In"
                    DisplayName   = "Core Networking - Router Advertisement (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
		        @{
                    Name          = "CoreNet Router-Sol-In"
                    DisplayName   = "Core Networking - Router Solicitation (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
		        @{
                    Name          = "CoreNet Teredo-In"
                    DisplayName   = "Core Networking - Teredo (UDP-In)"; 
                    Protocol      = "UDP"
                }
		        @{
                    Name          = "CoreNet TimeExceed-In"
                    DisplayName   = "Core Networking - Time Exceeded (ICMPv6-In)"; 
                    Protocol      = "ICMPv6"
                }
            )
            AbsentInFileRules     = @(
                @{
                    Name          = "File DCOM-In"
                    DisplayName   = "File Server Remote Management (DCOM-In)"; 
                    Protocol      = "TCP"
                }
                @{
                    Name          = "File WMI-In"
                    DisplayName   = "File Server Remote Management (WMI-In)"; 
                    Protocol      = "TCP"
                }
            )
            AllowedInRules        = @(
                @{	
                    Name          = "File SMB-In"
                    DisplayName   = "File Server Remote Management (SMB-In)"
                    Port          = "445";
                    Protocol      = "TCP";
                }
                @{
		            Name          = "WSMan HTTP-In"
                    DisplayName   = "Windows Remote Management (HTTP-In)"
                    Port          = "5985";
                    Protocol      = "TCP";
                }
                @{
		            Name          = "WSMan HTTPS-In"
                    DisplayName   = "Windows Remote Management (HTTPS-In)"
                    Port          = "5986";
                    Protocol      = "TCP";
                }
            )
        }

        # Hyper-V Host configuration data
        @{
            NodeName              = "localhost";
            Role                  = "HyperVHost";
            VHDDestinationPath    = "$VHDDestinationPath\{0}.vhd";
            SwitchName            = "Contoso"
            SwitchType            = "Internal" 
            VMState               = "Running"
            BaseVhdPath           = $BaseVhdPath;
            IPAddress             = "192.168.10.6"
            InterfaceAlias        = "*vethernet*"
            PrefixLength          = 24
            RetryintervalSec      = 10
            RetryCount            = 300
            CertificateID         = "497258FCCFFFA0F38268BBD970B337D25C871D6D"

            DHCPServer = @{                       
                MachineName       = "DHCPServer"                      
                MemorySizeofVM    = 1024MB;
                AdminUserCredFile = "$ConfigDataLocation\VMData\DHCPSrvCred.clixml"
                FilesToCopy = @(
                    @{
                        Source = "$ConfigDataLocation\VMData\unattend.xml";
                        Destination = "unattend.xml"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\SHVmSetup.cmd";
                        Destination = "Scripts\SHVmSetup.cmd"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\ConfigureVM.ps1";
                        Destination = "Scripts\ConfigureVM.ps1"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\ImportCerts.ps1";
                        Destination = "Scripts\ImportCerts.ps1"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\DHCPServer\*.mof";
                        Destination = "Windows\System32\Configuration\Pending.mof"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\DSCTestRootAuthority.pfx";
                        Destination = "Scripts\DSCTestRootAuthority.pfx"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\DSCDemo.pfx";
                        Destination = "Scripts\DSCDemo.pfx"
                    } 
                    @{
                        Source = $xNetworkingModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xNetworking"
                    }
                    @{
                        Source = $xComputerManagementModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xComputerManagement"
                    }
                    @{
                        Source = $xDhcpServerModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xDhcpServer"
                    }
                );
            };

            CorpDC = @{                     
                DomainName         = "corporate.contoso.com"
                MachineName        = "CorpDC"                        
                MemorySizeofVM     = 2048MB;
                MACAddress         = "00155D8A54A0" 
                AdminUserCredFile  = "$ConfigDataLocation\VMData\CORPDomainCred.clixml"
                FilesToCopy = @(
                    @{
                        Source = "$ConfigDataLocation\VMData\unattend.xml";
                        Destination = "unattend.xml"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\CorpDC\*.mof";
                        Destination = "Windows\System32\Configuration\Pending.mof"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\SHVmSetup.cmd";
                        Destination = "Scripts\SHVmSetup.cmd"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\ConfigureVM.ps1";
                        Destination = "Scripts\ConfigureVM.ps1"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\ImportCerts.ps1";
                        Destination = "Scripts\ImportCerts.ps1"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\DSCTestRootAuthority.pfx";
                        Destination = "Scripts\DSCTestRootAuthority.pfx"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\DSCDemo.pfx";
                        Destination = "Scripts\DSCDemo.pfx"
                    } 
                    @{
                        Source = $xNetworkingModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xNetworking"
                    }
                    @{
                        Source = $xComputerManagementModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xComputerManagement"
                    }
                    @{
                        Source = $xActiveDirectoryModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xActiveDirectory"
                    }
                    @{
                        Source = $xDnsServerModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xDnsServer"
                    }
                );
            };

            CorpClient = @{                       
                DomainName         = "corporate.contoso.com"
                MachineName        = "CorpClient"                        
                MemorySizeofVM     = 1024MB;
                AdminUserCredFile  = "$ConfigDataLocation\VMData\CORPDomainCred.clixml"
                FilesToCopy = @(
                    @{
                        Source = "$ConfigDataLocation\VMData\unattend.xml";
                        Destination = "unattend.xml"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\CorpClient\*.mof";
                        Destination = "Windows\System32\Configuration\Pending.mof"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\SHVmSetup.cmd";
                        Destination = "Scripts\SHVmSetup.cmd"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\ConfigureVM.ps1";
                        Destination = "Scripts\ConfigureVM.ps1"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\ImportCerts.ps1";
                        Destination = "Scripts\ImportCerts.ps1"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\DSCTestRootAuthority.pfx"; 
                        Destination = "Scripts\DSCTestRootAuthority.pfx"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\DSCDemo.pfx";
                        Destination = "Scripts\DSCDemo.pfx"
                    } 
                    @{
                        Source = $xComputerManagementModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xComputerManagement"
                    }
                );
            };

            SHDC = @{
                MachineName        = "SHDC"                        
                MemorySizeofVM     = 2048MB;
                MACAddress         = "00155D8A54A1" 
                AdminUserCredFile  = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
                FilesToCopy = @(
                    @{
                        Source = "$ConfigDataLocation\VMData\unattend.xml";
                        Destination = "unattend.xml"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\SHDC\*.mof";
                        Destination = "Windows\System32\Configuration\Pending.mof"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\SHVmSetup.cmd";
                        Destination = "Scripts\SHVmSetup.cmd"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\ConfigureVM.ps1";
                        Destination = "Scripts\ConfigureVM.ps1"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\ImportCerts.ps1";
                        Destination = "Scripts\ImportCerts.ps1"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\DSCTestRootAuthority.pfx";
                        Destination = "Scripts\DSCTestRootAuthority.pfx"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\DSCDemo.pfx";
                        Destination = "Scripts\DSCDemo.pfx"
                    } 
                    @{
                        Source = $xNetworkingModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xNetworking"
                    }
                    @{
                        Source = $xComputerManagementModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xComputerManagement"
                    }
                    @{
                        Source = $xActiveDirectoryModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xActiveDirectory"
                    }
                    @{
                        Source = $xDnsServerModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xDnsServer"
                    }
                );
            };

            SHPullServer = @{
                MachineName        = "SHPullServer"                        
                MemorySizeofVM     = 2048MB;
                MACAddress         = "00155D8A54A3" 
                DomainName         = "safeharbor.contoso.com"
                DomainCredFile     = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
                PullCert           = "9FE0BB64E4790CFFCFEB84C95C136BEB70B5F93B"
                AdminUserCredFile  = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
                FilesToCopy = @(
                    @{
                        Source = "$ConfigDataLocation\VMData\unattend.xml";
                        Destination = "unattend.xml"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\SHPullServer\*.mof";
                        Destination = "Windows\System32\Configuration\Pending.mof"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\SHVmSetup.cmd";
                        Destination = "Scripts\SHVmSetup.cmd"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\ConfigureVM.ps1";
                        Destination = "Scripts\ConfigureVM.ps1"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\ImportCerts.ps1";
                        Destination = "Scripts\ImportCerts.ps1"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\DSCTestRootAuthority.pfx";
                        Destination = "Scripts\DSCTestRootAuthority.pfx"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\DSCDemo.pfx";
                        Destination = "Scripts\DSCDemo.pfx"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\PullServer.pfx";
                        Destination = "Scripts\PullServer.pfx"
                    } 
                    @{
                        Source = "$ConfigDataLocation\VMData\SHPullServer\Configuration";
                        Destination = "Program Files\DscService\Configuration"
                    }
                    @{
                        Source = $xComputerManagementModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xComputerManagement"
                    }
                    @{
                        Source = $xPSDesiredStateConfigurationModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xPSDesiredStateConfiguration"
                    }
                );
            };

            SHMgmtSrv = @{
                MachineName        = "SHMgmtSrv"                        
                MemorySizeofVM     = 1024MB;
                MACAddress         = "00155D8A54A2" 
                DomainName         = "safeharbor.contoso.com"
                DomainCredFile     = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
                AdminUserCredFile  = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
                FilesToCopy = @(
                    @{
                        Source = "$ConfigDataLocation\VMData\unattend.xml";
                        Destination = "unattend.xml"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\SHMgmtSrv\*.mof";
                        Destination = "Windows\System32\Configuration\Pending.mof"
                    }
                    @{
                        Source = "$ConfigDataLocation\VMData\SHVmSetup.cmd"; 
                        Destination = "Scripts\SHVmSetup.cmd"
                    }
                    @{ 
                        Source = "$ConfigDataLocation\VMData\ConfigureVM.ps1"; 
                        Destination = "Scripts\ConfigureVM.ps1"
                    }
                    @{ 
                        Source = "$ConfigDataLocation\VMData\ImportCerts.ps1";
                        Destination = "Scripts\ImportCerts.ps1"
                    } 
                    @{ 
                        Source = "$ConfigDataLocation\VMData\DSCTestRootAuthority.pfx"; 
                        Destination = "Scripts\DSCTestRootAuthority.pfx"
                    } 
                    @{ 
                        Source = "$ConfigDataLocation\VMData\DSCDemo.pfx"; 
                        Destination = "Scripts\DSCDemo.pfx"
                    } 
                    @{ 
                        Source = "$ConfigDataLocation\VMData\Permission.csv"; 
                        Destination = "Scripts\Permission.csv"
                    } 
                    @{ 
                        Source = "$ConfigDataLocation\VMData\ProxyFunctions.psm1"; 
                        Destination = "Scripts\ProxyFunctions.psm1"
                    } 
                    @{ 
                        Source = "$ConfigDataLocation\VMData\Startup.ps1"; 
                        Destination = "Scripts\Startup.ps1"
                    } 
                    @{ 
                        Source = $xComputerManagementModulePath; 
                        Destination = "Program Files\WindowsPowerShell\Modules\xComputerManagement"
                    }
                    @{ 
                        Source = $xPSDesiredStateConfigurationModulePath; 
                        Destination = "Program Files\WindowsPowerShell\Modules\xPSDesiredStateConfiguration"
                    }
                );
            };

            SHFileServer = @{
                MachineName        = "SHFileServer"                        
                MemorySizeofVM     = 1024MB;
                DomainName         = "safeharbor.contoso.com"
                DomainCredFile     = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
                AdminUserCredFile  = "$ConfigDataLocation\VMData\SHDomainCred.clixml"
                FilesToCopy = @(
                    @{ 
                        Source = "$ConfigDataLocation\VMData\unattendFS.xml"; 
                        Destination = "unattend.xml"
                    }
                    @{ 
                        Source = "$ConfigDataLocation\VMData\metaconfigFS.mof"; 
                        Destination = "Windows\System32\Configuration\metaconfig.mof"
                    }
                    @{ 
                        Source = "$ConfigDataLocation\VMData\FileServerSetup.cmd"; 
                        Destination = "Scripts\FileServerSetup.cmd"
                    }
                    @{ 
                        Source = "$ConfigDataLocation\VMData\ImportCerts.ps1"; 
                        Destination = "Scripts\ImportCerts.ps1"
                    } 
                    @{ 
                        Source = "$ConfigDataLocation\VMData\ConfigureFSVM.ps1"; 
                        Destination = "Scripts\ConfigureFSVM.ps1"
                    } 
                    @{ 
                        Source = "$ConfigDataLocation\VMData\DSCTestRootAuthority.pfx"; 
                        Destination = "Scripts\DSCTestRootAuthority.pfx"
                    } 
                    @{ 
                        Source = "$ConfigDataLocation\VMData\DSCDemo.pfx"; 
                        Destination = "Scripts\DSCDemo.pfx"
                    } 
                    @{ 
                        Source = $xComputerManagementModulePath; 
                        Destination = "Program Files\WindowsPowerShell\Modules\xComputerManagement"
                    }
                    @{ 
                        Source = $xNetworkingModulePath;
                        Destination = "Program Files\WindowsPowerShell\Modules\xNetworking"
                    }
                );
            };
        }
    );
}
