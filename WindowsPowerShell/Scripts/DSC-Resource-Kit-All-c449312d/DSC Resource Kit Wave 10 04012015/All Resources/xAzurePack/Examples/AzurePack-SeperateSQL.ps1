#requires -Version 5

Configuration AzurePack
{
    Import-DscResource -Module xSQLServer
    Import-DscResource -Module xCredSSP
    Import-DscResource -Module xAzurePack

    # Set role and instance variables
    $Roles = $AllNodes.Roles | Sort-Object -Unique
    foreach($Role in $Roles)
    {
        $Servers = @($AllNodes.Where{$_.Roles | Where-Object {$_ -eq $Role}}.NodeName)
        Set-Variable -Name ($Role.Replace(" ","").Replace(".","") + "s") -Value $Servers
        if($Servers.Count -eq 1)
        {
            Set-Variable -Name ($Role.Replace(" ","").Replace(".","")) -Value $Servers[0]
            if(
                $Role.Contains("Database") -or
                $Role.Contains("Datawarehouse") -or
                $Role.Contains("Reporting") -or
                $Role.Contains("Analysis") -or 
                $Role.Contains("Integration")
            )
            {
                $Instance = $AllNodes.Where{$_.NodeName -eq $Servers[0]}.SQLServers.Where{$_.Roles | Where-Object {$_ -eq $Role}}.InstanceName
                Set-Variable -Name ($Role.Replace(" ","").Replace(".","").Replace("Server","Instance")) -Value $Instance
            }
        }
    }

    Node $AllNodes.NodeName
    {
        # Set LCM to reboot if needed
        LocalConfigurationManager
        {
            DebugMode = $true
            RebootNodeIfNeeded = $true
        }

        # Enable CredSSP
        if(
            ($WindowsAzurePack2013AdminAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantPublicAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013SQLServerExtensionServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013MySQLExtensionServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013AdminSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013AdminAuthenticationServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantAuthenticationSiteServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {            
            xCredSSP "Server"
            {
                Ensure = "Present"
                Role = "Server"
            }

            xCredSSP "Client"
            {
                Ensure = "Present"
                Role = "Client"
                DelegateComputers = $Node.NodeName
            }
        }

        # Install .NET Framework 3.5 on SQL nodes
        if(
            ($WindowsAzurePack2013DatabaseServer -eq $Node.NodeName) -or
            ($WindowsAzurePack2013AdminAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantPublicAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013SQLServerExtensionServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013MySQLExtensionServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013AdminSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013AdminAuthenticationServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantAuthenticationSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($SQLServer2012ManagementTools | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            WindowsFeature "NET-Framework-Core"
            {
                Ensure = "Present"
                Name = "NET-Framework-Core"
                Source = $Node.SourcePath + "\WindowsServer2012R2\sources\sxs"
            }
        }

        # Install IIS
        if(
            ($WindowsAzurePack2013AdminAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantPublicAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013SQLServerExtensionServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013MySQLExtensionServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013AdminSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013AdminAuthenticationServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantAuthenticationSiteServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            WindowsFeature "Web-WebServer"
            {
                Ensure = "Present"
                Name = "Web-WebServer"
            }

            WindowsFeature "Web-Default-Doc"
            {
                Ensure = "Present"
                Name = "Web-Default-Doc"
            }

            WindowsFeature "Web-Static-Content"
            {
                Ensure = "Present"
                Name = "Web-Static-Content"
            }

            WindowsFeature "Web-Stat-Compression"
            {
                Ensure = "Present"
                Name = "Web-Stat-Compression"
            }

            WindowsFeature "Web-Filtering"
            {
                Ensure = "Present"
                Name = "Web-Filtering"
            }

            WindowsFeature "Web-Dyn-Compression"
            {
                Ensure = "Present"
                Name = "Web-Dyn-Compression"
            }

            WindowsFeature "Web-Windows-Auth"
            {
                Ensure = "Present"
                Name = "Web-Windows-Auth"
            }

            WindowsFeature "NET-Framework-45-ASPNET"
            {
                Ensure = "Present"
                Name = "NET-Framework-45-ASPNET"
            }
       
            WindowsFeature "Web-Net-Ext45"
            {
                Ensure = "Present"
                Name = "Web-Net-Ext45"
            }

            WindowsFeature "Web-ISAPI-Ext"
            {
                Ensure = "Present"
                Name = "Web-ISAPI-Ext"
            }

            WindowsFeature "Web-ISAPI-Filter"
            {
                Ensure = "Present"
                Name = "Web-ISAPI-Filter"
            }

            WindowsFeature "Web-Asp-Net45"
            {
                Ensure = "Present"
                Name = "Web-Asp-Net45"
            }

            WindowsFeature "Web-Metabase"
            {
                Ensure = "Present"
                Name = "Web-Metabase"
            }

            WindowsFeature "PowerShell"
            {
                Ensure = "Present"
                Name = "PowerShell"
            }

            WindowsFeature "PowerShell-V2"
            {
                Ensure = "Present"
                Name = "PowerShell-V2"
            }

            WindowsFeature "WAS-Process-Model"
            {
                Ensure = "Present"
                Name = "WAS-Process-Model"
            }

            WindowsFeature "WAS-NET-Environment"
            {
                Ensure = "Present"
                Name = "WAS-NET-Environment"
            }

            WindowsFeature "WAS-Config-APIs"
            {
                Ensure = "Present"
                Name = "WAS-Config-APIs"
            }
        }
        if(
            ($WindowsAzurePack2013AdminSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013AdminAuthenticationServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantAuthenticationSiteServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {

            WindowsFeature "Web-Mgmt-Console"
            {
                Ensure = "Present"
                Name = "Web-Mgmt-Console"
            }
        }
        if(
            ($WindowsAzurePack2013TenantSiteServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {

            WindowsFeature "Web-Basic-Auth"
            {
                Ensure = "Present"
                Name = "Web-Basic-Auth"
            }
        }

        # Install SQL Instances
        if(
            ($WindowsAzurePack2013DatabaseServer -eq $Node.NodeName)
        )
        {
            foreach($SQLServer in $Node.SQLServers)
            {
                $SQLInstanceName = $SQLServer.InstanceName

                $Features = ""
                if(
                    (
                        ($WindowsAzurePack2013DatabaseServer -eq $Node.NodeName) -and
                        ($WindowsAzurePack2013DatabaseInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "SQLENGINE"
                }
                $Features = $Features.Trim(",")

                if($Features -ne "")
                {
                    xSqlServerSetup ($Node.NodeName + $SQLInstanceName)
                    {
                        DependsOn = "[WindowsFeature]NET-Framework-Core"
                        SourcePath = $Node.SourcePath
                        SetupCredential = $Node.InstallerServiceAccount
                        InstanceName = $SQLInstanceName
                        Features = $Features
                        SQLSysAdminAccounts = $Node.AdminAccount
                        SecurityMode = "SQL"
                        SAPwd = $Node.SQLSA
                    }

                    xSqlServerFirewall ($Node.NodeName + $SQLInstanceName)
                    {
                        DependsOn = ("[xSqlServerSetup]" + $Node.NodeName + $SQLInstanceName)
                        SourcePath = $Node.SourcePath
                        InstanceName = $SQLInstanceName
                        Features = $Features
                    }
                }
            }
        }

        # Install SQL Management Tools
        if($SQLServer2012ManagementTools | Where-Object {$_ -eq $Node.NodeName})
        {
            xSqlServerSetup "SQLMT"
            {
                DependsOn = "[WindowsFeature]NET-Framework-Core"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
                InstanceName = "NULL"
                Features = "SSMS,ADV_SSMS"
            }
        }

        # Install ASP.NET Web Pages 2 and ASP.NET MVC 4
        if(
            ($WindowsAzurePack2013AdminAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantPublicAPIServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013SQLServerExtensionServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013MySQLExtensionServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013AdminSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013AdminAuthenticationServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantAuthenticationSiteServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            # Install ASP.NET Web Pages 2
            if($Node.ASPNETWebPages2)
            {
                $ASPNETWebPages2 = (Join-Path -Path $Node.ASPNETWebPages2 -ChildPath "AspNetWebPages2Setup.exe")
            }
            else
            {
                $ASPNETWebPages2 = "\Prerequisites\ASPNETWebPages2\AspNetWebPages2Setup.exe"
            }
            Package "ASPNETWebPages2"
            {
                Ensure = "Present"
                Name = "Microsoft ASP.NET Web Pages 2 Runtime"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $ASPNETWebPages2)
                Arguments = "/q"
                Credential = $Node.InstallerServiceAccount
            }
            
            # Install ASP.NET MVC 4
            if($Node.ASPNETMVC4)
            {
                $ASPNETMVC4 = (Join-Path -Path $Node.ASPNETMVC4 -ChildPath "AspNetMVC4Setup.exe")
            }
            else
            {
                $ASPNETMVC4 = "\Prerequisites\ASPNETMVC4\AspNetMVC4Setup.exe"
            }
            Package "ASPNETMVC4"
            {
                Ensure = "Present"
                Name = "Microsoft ASP.NET MVC 4 Runtime"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $ASPNETMVC4)
                Arguments = "/q"
                Credential = $Node.InstallerServiceAccount
            }
        }

        # Install MySQL Connector Net 6.5.4
        if(
            ($WindowsAzurePack2013MySQLExtensionServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            # Install MySQL Connector Net 6.5.4
            if($Node.MySQLConnectorNet654)
            {
                $MySQLConnectorNet654 = (Join-Path -Path $Node.ASPNETWebPages2 -ChildPath "mysql-connector-net-6.5.4.msi")
            }
            else
            {
                $MySQLConnectorNet654 = "\Prerequisites\MySQLConnectorNet654\mysql-connector-net-6.5.4.msi"
            }
            Package "MySQLConnectorNet654"
            {
                Ensure = "Present"
                Name = "MySQL Connector Net 6.5.4"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $MySQLConnectorNet654)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }
        }

        # Install URL Rewrite 2
        if(
            ($WindowsAzurePack2013AdminSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013AdminAuthenticationServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantSiteServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($WindowsAzurePack2013TenantAuthenticationSiteServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            # Install URL Rewrite 2
            if($Node.URLRewrite2)
            {
                $URLRewrite2 = (Join-Path -Path $Node.ASPNETWebPages2 -ChildPath "rewrite_amd64_en-US.msi")
            }
            else
            {
                $URLRewrite2 = "\Prerequisites\URLRewrite2\rewrite_amd64_en-US.msi"
            }
            Package "URLRewrite2"
            {
                Ensure = "Present"
                Name = "IIS URL Rewrite Module 2"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $URLRewrite2)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }
        }

        # Install and initialize Azure Pack Admin API
        if(
            ($WindowsAzurePack2013AdminAPIServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xAzurePackSetup "AdminAPIInstall"
            {
                Role = "Admin API"
                Action = "Install"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            $DependsOn = @()

            if(
                ($WindowsAzurePack2013AdminAPIServers[0] -eq $Node.NodeName)
            )
            {
                # Wait for Azure Pack Database Server
                if ($WindowsAzurePack2013AdminAPIServers[0] -eq $WindowsAzurePack2013DatabaseServer)
                {
                    $DependsOn = @(("[xSqlServerFirewall]" + $WindowsAzurePack2013DatabaseServer + $WindowsAzurePack2013DatabaseInstance))
                }
                else
                {
                    WaitForAll "WAPDB"
                    {
                        NodeName = $WindowsAzurePack2013DatabaseServer
                        ResourceName = ("[xSqlServerFirewall]" + $WindowsAzurePack2013DatabaseServer + $WindowsAzurePack2013DatabaseInstance)
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn = @("[WaitForAll]WAPDB")
                }

                $DependsOn += @(
                    "[xCredSSP]Client",
                    "[xCredSSP]Server",
                    "[xAzurePackSetup]AdminAPIInstall"
                )

                xAzurePackSetup "AdminAPIInitialize"
                {
                    DependsOn = $DependsOn
                    Role = "Admin API"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }

                if($Node.AzurePackAdminAPIFQDN)
                {
                    if ($Node.AzurePackAdminAPIPort)
                    {
                        $AzurePackAdminAPIPort = $Node.AzurePackAdminAPIPort
                    }
                    else
                    {
                        $AzurePackAdminAPIPort = 30004
                    }

                    xAzurePackDatabaseSetting "AntaresGeoMasterUri"
                    {
                        DependsOn = "[xAzurePackSetup]AdminAPIInitialize"
                        Namespace = "AdminSite"
                        Name = "Microsoft.Azure.Portal.Configuration.AppManagementConfiguration.AntaresGeoMasterUri"
                        Value = ("https://" + $Node.AzurePackAdminAPIFQDN + ":" + $AzurePackAdminAPIPort + "/services/webspaces/")
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }

                    xAzurePackDatabaseSetting "RdfeAdminManagementServiceUri"
                    {
                        DependsOn = "[xAzurePackSetup]AdminAPIInitialize"
                        Namespace = "AdminSite"
                        Name = "Microsoft.Azure.Portal.Configuration.AppManagementConfiguration.RdfeAdminManagementServiceUri"
                        Value = ("https://" + $Node.AzurePackAdminAPIFQDN + ":" + $AzurePackAdminAPIPort + "/")
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }

                    xAzurePackDatabaseSetting "RdfeAdminUri"
                    {
                        DependsOn = "[xAzurePackSetup]AdminAPIInitialize"
                        Namespace = "AdminSite"
                        Name = "Microsoft.Azure.Portal.Configuration.OnPremPortalConfiguration.RdfeAdminUri"
                        Value = ("https://" + $Node.AzurePackAdminAPIFQDN + ":" + $AzurePackAdminAPIPort + "/")
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }

                    xAzurePackDatabaseSetting "RdfeProvisioningUri"
                    {
                        DependsOn = "[xAzurePackSetup]AdminAPIInitialize"
                        Namespace = "AdminSite"
                        Name = "Microsoft.Azure.Portal.Configuration.OnPremPortalConfiguration.RdfeProvisioningUri"
                        Value = ("https://" + $Node.AzurePackAdminAPIFQDN + ":" + $AzurePackAdminAPIPort + "/")
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }
                }
            }
            else
            {
                WaitForAll "AdminAPIInitialize"
                {
                    NodeName = $WindowsAzurePack2013AdminAPIServers[0]
                    ResourceName = "[xAzurePackSetup]AdminAPIInitialize"
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }

                xAzurePackSetup "AdminAPIInitialize"
                {
                    DependsOn = @(
                        "[xCredSSP]Client",
                        "[xCredSSP]Server",
                        "[xAzurePackSetup]AdminAPIInstall",
                        "[WaitForAll]AdminAPIInitialize"
                    )
                    Role = "Admin API"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
        }

        # Install and initialize Azure Pack Tenant API
        if(
            ($WindowsAzurePack2013TenantAPIServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xAzurePackSetup "TenantAPIInstall"
            {
                Role = "Tenant API"
                Action = "Install"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            $DependsOn = @()

            if(
                ($WindowsAzurePack2013TenantAPIServers[0] -eq $Node.NodeName)
            )
            {
                # Wait for Admin API
                if ($WindowsAzurePack2013TenantAPIServers[0] -eq $WindowsAzurePack2013AdminAPIServers[0])
                {
                    $DependsOn = @("[xAzurePackSetup]AdminAPIInitialize")
                }
                else
                {
                    WaitForAll "AdminAPI"
                    {
                        NodeName = $WindowsAzurePack2013AdminAPIServers[0]
                        ResourceName = ("[xAzurePackSetup]AdminAPIInitialize")
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn = @("[WaitForAll]AdminAPI")
                }

                $DependsOn += @(
                    "[xCredSSP]Client",
                    "[xCredSSP]Server",
                    "[xAzurePackSetup]TenantAPIInstall"
                )

                xAzurePackSetup "TenantAPIInitialize"
                {
                    DependsOn = $DependsOn
                    Role = "Tenant API"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }

                if($Node.AzurePackTenantAPIFQDN)
                {
                    if ($Node.AzurePackTenantAPIPort)
                    {
                        $AzurePackTenantAPIPort = $Node.AzurePackTenantAPIPort
                    }
                    else
                    {
                        $AzurePackTenantAPIPort = 30005
                    }

                    xAzurePackDatabaseSetting "AdminSite-RdfeUnifiedManagementServiceUri"
                    {
                        DependsOn = "[xAzurePackSetup]TenantAPIInitialize"
                        Namespace = "AdminSite"
                        Name = "Microsoft.Azure.Portal.Configuration.AppManagementConfiguration.RdfeUnifiedManagementServiceUri"
                        Value = ("https://" + $Node.AzurePackTenantAPIFQDN + ":" + $AzurePackTenantAPIPort + "/")
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }

                    xAzurePackDatabaseSetting "TenantSite-RdfeUnifiedManagementServiceUri"
                    {
                        DependsOn = "[xAzurePackSetup]TenantAPIInitialize"
                        Namespace = "TenantSite"
                        Name = "Microsoft.Azure.Portal.Configuration.AppManagementConfiguration.RdfeUnifiedManagementServiceUri"
                        Value = ("https://" + $Node.AzurePackTenantAPIFQDN + ":" + $AzurePackTenantAPIPort + "/")
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }
                }
            }
            else
            {
                WaitForAll "TenantAPIInitialize"
                {
                    NodeName = $WindowsAzurePack2013TenantAPIServers[0]
                    ResourceName = "[xAzurePackSetup]TenantAPIInitialize"
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }

                xAzurePackSetup "TenantAPIInitialize"
                {
                    DependsOn = @(
                        "[xCredSSP]Client",
                        "[xCredSSP]Server",
                        "[xAzurePackSetup]TenantAPIInstall",
                        "[WaitForAll]TenantAPIInitialize"
                    )
                    Role = "Tenant API"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
        }

        # Install and initialize Azure Pack Tenant Public API
        if(
            ($WindowsAzurePack2013TenantPublicAPIServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xAzurePackSetup "TenantPublicAPIInstall"
            {
                Role = "Tenant Public API"
                Action = "Install"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            $DependsOn = @()

            if(
                ($WindowsAzurePack2013TenantPublicAPIServers[0] -eq $Node.NodeName)
            )
            {
                # Wait for Tenant API
                if ($WindowsAzurePack2013TenantPublicAPIServers[0] -eq $WindowsAzurePack2013TenantAPIServers[0])
                {
                    $DependsOn = @("[xAzurePackSetup]TenantAPIInitialize")
                }
                else
                {
                    WaitForAll "TenantAPI"
                    {
                        NodeName = $WindowsAzurePack2013TenantAPIServers[0]
                        ResourceName = ("[xAzurePackSetup]TenantAPIInitialize")
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn = @("[WaitForAll]TenantAPI")
                }

                $DependsOn += @(
                    "[xCredSSP]Client",
                    "[xCredSSP]Server",
                    "[xAzurePackSetup]TenantPublicAPIInstall"
                )

                xAzurePackSetup "TenantPublicAPIInitialize"
                {
                    DependsOn = $DependsOn
                    Role = "Tenant Public API"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }

                if($Node.AzurePackTenantPublicAPIFQDN)
                {
                    if ($Node.AzurePackTenantPublicAPIPort)
                    {
                        $AzurePackTenantPublicAPIPort = $Node.AzurePackTenantPublicAPIPort
                    }
                    else
                    {
                        $AzurePackTenantPublicAPIPort = 30006
                    }

                    xAzurePackDatabaseSetting "PublicRdfeProvisioningUri"
                    {
                        DependsOn = "[xAzurePackSetup]TenantPublicAPIInitialize"
                        Namespace = "TenantSite"
                        Name = "Microsoft.WindowsAzure.Server.Configuration.TenantPortalConfiguration.PublicRdfeProvisioningUri"
                        Value = ("https://" + $Node.AzurePackTenantPublicAPIFQDN + ":" + $AzurePackTenantPublicAPIPort + "/")
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }
                }
            }
            else
            {
                WaitForAll "TenantPublicAPIInitialize"
                {
                    NodeName = $WindowsAzurePack2013TenantPublicAPIServers[0]
                    ResourceName = "[xAzurePackSetup]TenantPublicAPIInitialize"
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }

                xAzurePackSetup "TenantPublicAPIInitialize"
                {
                    DependsOn = @(
                        "[xCredSSP]Client",
                        "[xCredSSP]Server",
                        "[xAzurePackSetup]TenantPublicAPIInstall",
                        "[WaitForAll]TenantPublicAPIInitialize"
                    )
                    Role = "Tenant Public API"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
        }

        # Install and initialize Azure Pack SQL Server Extension
        if(
            ($WindowsAzurePack2013SQLServerExtensionServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xAzurePackSetup "SQLServerExtensionInstall"
            {
                Role = "SQL Server Extension"
                Action = "Install"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            $DependsOn = @()

            if(
                ($WindowsAzurePack2013SQLServerExtensionServers[0] -eq $Node.NodeName)
            )
            {
                # Wait for Admin API
                if ($WindowsAzurePack2013SQLServerExtensionServers[0] -eq $WindowsAzurePack2013AdminAPIServers[0])
                {
                    $DependsOn = @("[xAzurePackSetup]AdminAPIInitialize")
                }
                else
                {
                    WaitForAll "AdminAPI"
                    {
                        NodeName = $WindowsAzurePack2013AdminAPIServers[0]
                        ResourceName = ("[xAzurePackSetup]AdminAPIInitialize")
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn = @("[WaitForAll]AdminAPI")
                }

                $DependsOn += @(
                    "[xCredSSP]Client",
                    "[xCredSSP]Server",
                    "[xAzurePackSetup]SQLServerExtensionInstall"
                )

                xAzurePackSetup "SQLServerExtensionInitialize"
                {
                    DependsOn = $DependsOn
                    Role = "SQL Server Extension"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
            else
            {
                WaitForAll "SQLServerExtensionInitialize"
                {
                    NodeName = $WindowsAzurePack2013SQLServerExtensionServers[0]
                    ResourceName = "[xAzurePackSetup]SQLServerExtensionInitialize"
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }

                xAzurePackSetup "SQLServerExtensionInitialize"
                {
                    DependsOn = @(
                        "[xCredSSP]Client",
                        "[xCredSSP]Server",
                        "[xAzurePackSetup]SQLServerExtensionInstall",
                        "[WaitForAll]SQLServerExtensionInitialize"
                    )
                    Role = "SQL Server Extension"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
        }

        # Install and initialize Azure Pack MySQL Extension
        if(
            ($WindowsAzurePack2013MySQLExtensionServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xAzurePackSetup "MySQLExtensionInstall"
            {
                Role = "MySQL Extension"
                Action = "Install"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            $DependsOn = @()

            if(
                ($WindowsAzurePack2013MySQLExtensionServers[0] -eq $Node.NodeName)
            )
            {
                # Wait for Admin API
                if ($WindowsAzurePack2013MySQLExtensionServers[0] -eq $WindowsAzurePack2013AdminAPIServers[0])
                {
                    $DependsOn = @("[xAzurePackSetup]AdminAPIInitialize")
                }
                else
                {
                    WaitForAll "AdminAPI"
                    {
                        NodeName = $WindowsAzurePack2013AdminAPIServers[0]
                        ResourceName = ("[xAzurePackSetup]AdminAPIInitialize")
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn = @("[WaitForAll]AdminAPI")
                }

                $DependsOn += @(
                    "[xCredSSP]Client",
                    "[xCredSSP]Server",
                    "[xAzurePackSetup]MySQLExtensionInstall"
                )

                xAzurePackSetup "MySQLExtensionInitialize"
                {
                    DependsOn = $DependsOn
                    Role = "MySQL Extension"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
            else
            {
                WaitForAll "MySQLExtensionInitialize"
                {
                    NodeName = $WindowsAzurePack2013MySQLExtensionServers[0]
                    ResourceName = "[xAzurePackSetup]MySQLExtensionInitialize"
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }

                xAzurePackSetup "MySQLExtensionInitialize"
                {
                    DependsOn = @(
                        "[xCredSSP]Client",
                        "[xCredSSP]Server",
                        "[xAzurePackSetup]MySQLExtensionInstall",
                        "[WaitForAll]MySQLExtensionInitialize"
                    )
                    Role = "MySQL Extension"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
        }

        # Install and initialize Azure Pack Admin Site
        if(
            ($WindowsAzurePack2013AdminSiteServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xAzurePackSetup "AdminSiteInstall"
            {
                Role = "Admin Site"
                Action = "Install"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            $DependsOn = @()

            if(
                ($WindowsAzurePack2013AdminSiteServers[0] -eq $Node.NodeName)
            )
            {
                # Wait for Admin API
                if ($WindowsAzurePack2013AdminSiteServers[0] -eq $WindowsAzurePack2013AdminAPIServers[0])
                {
                    $DependsOn = @("[xAzurePackSetup]AdminAPIInitialize")
                }
                else
                {
                    WaitForAll "AdminAPI"
                    {
                        NodeName = $WindowsAzurePack2013AdminAPIServers[0]
                        ResourceName = ("[xAzurePackSetup]AdminAPIInitialize")
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn = @("[WaitForAll]AdminAPI")
                }

                $DependsOn += @(
                    "[xCredSSP]Client",
                    "[xCredSSP]Server",
                    "[xAzurePackSetup]AdminSiteInstall"
                )

                xAzurePackSetup "AdminSiteInitialize"
                {
                    DependsOn = $DependsOn
                    Role = "Admin Site"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }

                if($Node.AzurePackAdminSiteFQDN)
                {
                    xAzurePackFQDN "AdminSite"
                    {
                        DependsOn = "[xAzurePackSetup]AdminSiteInitialize"
                        Namespace = "AdminSite"
                        FullyQualifiedDomainName = $Node.AzurePackAdminSiteFQDN
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }

                    xAzurePackIdentityProvider "AdminSite"
                    {
                        DependsOn = "[xAzurePackSetup]AdminSiteInitialize"
                        Target = "Windows"
                        FullyQualifiedDomainName = $Node.AzurePackAdminSiteFQDN
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }
                }
            }
            else
            {
                WaitForAll "AdminSiteInitialize"
                {
                    NodeName = $WindowsAzurePack2013AdminSiteServers[0]
                    ResourceName = "[xAzurePackSetup]AdminSiteInitialize"
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }

                xAzurePackSetup "AdminSiteInitialize"
                {
                    DependsOn = @(
                        "[xCredSSP]Client",
                        "[xCredSSP]Server",
                        "[xAzurePackSetup]AdminSiteInstall",
                        "[WaitForAll]AdminSiteInitialize"
                    )
                    Role = "Admin Site"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
        }

        # Install and initialize Azure Pack Admin Authentication Site
        if(
            ($WindowsAzurePack2013AdminAuthenticationSiteServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xAzurePackSetup "AdminAuthenticationSiteInstall"
            {
                Role = "Admin Authentication Site"
                Action = "Install"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            $DependsOn = @()

            if(
                ($WindowsAzurePack2013AdminAuthenticationSiteServers[0] -eq $Node.NodeName)
            )
            {
                # Wait for Admin API
                if ($WindowsAzurePack2013AdminAuthenticationSiteServers[0] -eq $WindowsAzurePack2013AdminAPIServers[0])
                {
                    $DependsOn = @("[xAzurePackSetup]AdminAPIInitialize")
                }
                else
                {
                    WaitForAll "AdminAPI"
                    {
                        NodeName = $WindowsAzurePack2013AdminAPIServers[0]
                        ResourceName = ("[xAzurePackSetup]AdminAPIInitialize")
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn = @("[WaitForAll]AdminAPI")
                }

                $DependsOn += @(
                    "[xCredSSP]Client",
                    "[xCredSSP]Server",
                    "[xAzurePackSetup]AdminAuthenticationSiteInstall"
                )

                xAzurePackSetup "AdminAuthenticationSiteInitialize"
                {
                    DependsOn = $DependsOn
                    Role = "Admin Authentication Site"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }

                if($Node.AzurePackAdmin)
                {
                    xAzurePackAdmin "Admins"
                    {
                        DependsOn = "[xAzurePackSetup]AdminAuthenticationSiteInitialize"
                        Principal = $Node.AzurePackAdmin
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }
                }

                if($Node.AzurePackWindowsAuthSiteFQDN)
                {
                    xAzurePackFQDN "AdminAuthenticationSite"
                    {
                        DependsOn = "[xAzurePackSetup]AdminAuthenticationSiteInitialize"
                        Namespace = "WindowsAuthSite"
                        FullyQualifiedDomainName = $Node.AzurePackWindowsAuthSiteFQDN
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }

                    xAzurePackRelyingParty "AdminAuthenticationSite"
                    {
                        DependsOn = "[xAzurePackSetup]AdminAuthenticationSiteInitialize"
                        Target = "Admin"
                        FullyQualifiedDomainName = $Node.AzurePackWindowsAuthSiteFQDN
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }
                }
            }
            else
            {
                WaitForAll "AdminAuthenticationSiteInitialize"
                {
                    NodeName = $WindowsAzurePack2013AdminAuthenticationSiteServers[0]
                    ResourceName = "[xAzurePackSetup]AdminAuthenticationSiteInitialize"
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }

                xAzurePackSetup "AdminAuthenticationSiteInitialize"
                {
                    DependsOn = @(
                        "[xCredSSP]Client",
                        "[xCredSSP]Server",
                        "[xAzurePackSetup]AdminAuthenticationSiteInstall",
                        "[WaitForAll]AdminAuthenticationSiteInitialize"
                    )
                    Role = "Admin Authentication Site"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
        }

        # Install and initialize Azure Pack Tenant Site
        if(
            ($WindowsAzurePack2013TenantSiteServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xAzurePackSetup "TenantSiteInstall"
            {
                Role = "Tenant Site"
                Action = "Install"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            $DependsOn = @()

            if(
                ($WindowsAzurePack2013TenantSiteServers[0] -eq $Node.NodeName)
            )
            {
                # Wait for Tenant Public API
                if ($WindowsAzurePack2013TenantSiteServers[0] -eq $WindowsAzurePack2013TenantPublicAPIServers[0])
                {
                    $DependsOn = @("[xAzurePackSetup]TenantPublicAPIInitialize")
                }
                else
                {
                    WaitForAll "AdminAPI"
                    {
                        NodeName = $WindowsAzurePack2013TenantPublicAPIServers[0]
                        ResourceName = ("[xAzurePackSetup]TenantPublicAPIInitialize")
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn = @("[WaitForAll]AdminAPI")
                }

                $DependsOn += @(
                    "[xCredSSP]Client",
                    "[xCredSSP]Server",
                    "[xAzurePackSetup]TenantSiteInstall"
                )

                xAzurePackSetup "TenantSiteInitialize"
                {
                    DependsOn = $DependsOn
                    Role = "Tenant Site"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }

                if($Node.AzurePackTenantSiteFQDN)
                {
                    xAzurePackFQDN "TenantSite"
                    {
                        DependsOn = "[xAzurePackSetup]TenantSiteInitialize"
                        Namespace = "TenantSite"
                        FullyQualifiedDomainName = $Node.AzurePackTenantSiteFQDN
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }

                    xAzurePackIdentityProvider "TenantSite"
                    {
                        DependsOn = "[xAzurePackSetup]TenantSiteInitialize"
                        Target = "Membership"
                        FullyQualifiedDomainName = $Node.AzurePackTenantSiteFQDN
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }
                }
            }
            else
            {
                WaitForAll "TenantSiteInitialize"
                {
                    NodeName = $WindowsAzurePack2013TenantSiteServers[0]
                    ResourceName = "[xAzurePackSetup]TenantSiteInitialize"
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }

                xAzurePackSetup "TenantSiteInitialize"
                {
                    DependsOn = @(
                        "[xCredSSP]Client",
                        "[xCredSSP]Server",
                        "[xAzurePackSetup]TenantSiteInstall",
                        "[WaitForAll]TenantSiteInitialize"
                    )
                    Role = "Tenant Site"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
        }

        # Install and initialize Azure Pack Tenant Authentication Site
        if(
            ($WindowsAzurePack2013TenantAuthenticationSiteServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xAzurePackSetup "TenantAuthenticationSiteInstall"
            {
                Role = "Tenant Authentication Site"
                Action = "Install"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            $DependsOn = @()

            if(
                ($WindowsAzurePack2013TenantAuthenticationSiteServers[0] -eq $Node.NodeName)
            )
            {
                # Wait for Tenant Public API
                if ($WindowsAzurePack2013TenantAuthenticationSiteServers[0] -eq $WindowsAzurePack2013TenantPublicAPIServers[0])
                {
                    $DependsOn = @("[xAzurePackSetup]TenantPublicAPIInitialize")
                }
                else
                {
                    WaitForAll "AdminAPI"
                    {
                        NodeName = $WindowsAzurePack2013TenantPublicAPIServers[0]
                        ResourceName = ("[xAzurePackSetup]TenantPublicAPIInitialize")
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn = @("[WaitForAll]AdminAPI")
                }

                $DependsOn += @(
                    "[xCredSSP]Client",
                    "[xCredSSP]Server",
                    "[xAzurePackSetup]TenantAuthenticationSiteInstall"
                )

                xAzurePackSetup "TenantAuthenticationSiteInitialize"
                {
                    DependsOn = $DependsOn
                    Role = "Tenant Authentication Site"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }

                if($Node.AzurePackAuthSiteFQDN)
                {
                    xAzurePackFQDN "TenantAuthenticationSite"
                    {
                        DependsOn = "[xAzurePackSetup]TenantAuthenticationSiteInitialize"
                        Namespace = "AuthSite"
                        FullyQualifiedDomainName = $Node.AzurePackAuthSiteFQDN
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }

                    xAzurePackRelyingParty "TenantAuthenticationSite"
                    {
                        DependsOn = "[xAzurePackSetup]TenantAuthenticationSiteInitialize"
                        Target = "Tenant"
                        FullyQualifiedDomainName = $Node.AzurePackAuthSiteFQDN
                        AzurePackAdminCredential = $Node.InstallerServiceAccount
                        SQLServer = $WindowsAzurePack2013DatabaseServer
                        SQLInstance = $WindowsAzurePack2013DatabaseInstance
                    }
                }
            }
            else
            {
                WaitForAll "TenantAuthenticationSiteInitialize"
                {
                    NodeName = $WindowsAzurePack2013TenantAuthenticationSiteServers[0]
                    ResourceName = "[xAzurePackSetup]TenantAuthenticationSiteInitialize"
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }

                xAzurePackSetup "TenantAuthenticationSiteInitialize"
                {
                    DependsOn = @(
                        "[xCredSSP]Client",
                        "[xCredSSP]Server",
                        "[xAzurePackSetup]TenantAuthenticationSiteInstall",
                        "[WaitForAll]TenantAuthenticationSiteInitialize"
                    )
                    Role = "Tenant Authentication Site"
                    Action = "Initialize"
                    SourcePath = $Node.SourcePath
                    SetupCredential = $Node.InstallerServiceAccount
                    SQLServer = $WindowsAzurePack2013DatabaseServer
                    SQLInstance = $WindowsAzurePack2013DatabaseInstance
                }
            }
        }

        # Create variables and DependsOn/WaitFor for Resource Provider name/port configuration
        if(
            $Node.AzurePackAdminAPIFQDN -or
            $Node.AzurePackAdminAPIPort -or
            $Node.AzurePackSQLServerExtensionFQDN -or
            $Node.AzurePackSQLServerExtensionPort -or
            $Node.AzurePackMySQLExtensionFQDN -or
            $Node.AzurePackMySQLExtensionPort
        )
        {
            # Set AdminAuthenticationSite
            if($Node.AzurePackWindowsAuthSiteFQDN)
            {
                $Res = "[xAzurePackSetup]AdminAuthenticationSiteInitialize"
                $AdminAuthenticationSite = "https://" + $Node.AzurePackWindowsAuthSiteFQDN + ":"
            }
            else
            {
                $Res = "[xAzurePackRelyingParty]AdminAuthenticationSite"
                $AdminAuthenticationSite = "https://" + $WindowsAzurePack2013AdminAuthenticationSiteServers[0] + ":"
            }
            if($Node.AzurePackWindowsAuthSitePort)
            {
                $AdminAuthenticationSite = $AdminAuthenticationSite + $Node.AzurePackWindowsAuthSitePort + "/"
            }
            else
            {
                $AdminAuthenticationSite = $AdminAuthenticationSite + "30072/"
            }
            # Set AdminUri
            if($Node.AzurePackAdminAPIFQDN)
            {
                $AdminUri = "https://" + $Node.AzurePackAdminAPIFQDN + ":"
            }
            else
            {
                $AdminUri = "https://" + $WindowsAzurePack2013AdminAPIServers[0] + ":"
            }
            if($Node.AzurePackAdminAPIPort)
            {
                $AdminUri = $AdminUri + $Node.AzurePackAdminAPIPort + "/"
            }
            else
            {
                $AdminUri = $AdminUri + "30004/"
            }

            $DependsOn = @()
            if(

                (($Node.AzurePackAdminAPIFQDN -or $Node.AzurePackAdminAPIPort) -and ($WindowsAzurePack2013AdminAPIServers[0] -eq $Node.NodeName)) -or
                (($Node.AzurePackSQLServerExtensionFQDN -or $Node.AzurePackSQLServerExtensionPort) -and ($WindowsAzurePack2013SQLServerExtensionServers[0] -eq $Node.NodeName)) -or
                (($Node.AzurePackMySQLExtensionFQDN -or $Node.AzurePackMySQLExtensionPort) -and ($WindowsAzurePack2013MySQLExtensionServers[0] -eq $Node.NodeName))

            )
            {
                # Wait for Admin Authentication Site
                if ($Node.NodeName -eq $WindowsAzurePack2013AdminAuthenticationSiteServers[0])
                {
                    $DependsOn = @($Res)
                }
                else
                {
                    WaitForAll "WAPAAS"
                    {
                        NodeName = $WindowsAzurePack2013AdminAuthenticationSiteServers[0]
                        ResourceName = $Res
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn = @("[WaitForAll]WAPAAS")
                }
            }
        }

        # Set resource provider name - default providers
        if(($Node.AzurePackAdminAPIFQDN -or $Node.AzurePackAdminAPIPort) -and ($WindowsAzurePack2013AdminAPIServers[0] -eq $Node.NodeName))
        {
            if($Node.AzurePackAdminAPIFQDN)
            {
                $AzurePackAdminAPI = $Node.AzurePackAdminAPIFQDN
            }
            else
            {
                $AzurePackAdminAPI = $Node.NodeName.Split(".")[0]
            }
            
            if ($Node.AzurePackMarketplacePort)
            {
                $AzurePackMarketplacePort = $Node.AzurePackMarketplacePort
            }
            else
            {
                $AzurePackMarketplacePort = 30018
            }

            xAzurePackResourceProvider "marketplace"
            {
                DependsOn = $DependsOn
                AuthenticationSite = $AdminAuthenticationSite
                AdminUri = $AdminUri
                Name = "marketplace"
                AzurePackAdminCredential = $Node.InstallerServiceAccount
                Enabled = $true
                PassthroughEnabled = $true
                AllowAnonymousAccess = $true
                AllowMultipleInstances = $false
                AdminForwardingAddress = "https://" + $AzurePackAdminAPI + ":" + $AzurePackMarketplacePort + "/"
                TenantForwardingAddress = "https://" + $AzurePackAdminAPI + ":" + $AzurePackMarketplacePort + "/subscriptions"
            }

            if ($Node.AzurePackMonitoringPort)
            {
                $AzurePackMonitoringPort = $Node.AzurePackMonitoringPort
            }
            else
            {
                $AzurePackMonitoringPort = 30020
            }

            xAzurePackResourceProvider "monitoring"
            {
                DependsOn = $DependsOn
                AuthenticationSite = $AdminAuthenticationSite
                AdminUri = $AdminUri
                Name = "monitoring"
                AzurePackAdminCredential = $Node.InstallerServiceAccount
                Enabled = $true
                PassthroughEnabled = $true
                AllowAnonymousAccess = $true
                AllowMultipleInstances = $false
                AdminForwardingAddress = "https://" + $AzurePackAdminAPI + ":" + $AzurePackMonitoringPort + "/"
                TenantForwardingAddress = "https://" + $AzurePackAdminAPI + ":" + $AzurePackMonitoringPort + "/"
            }

            if ($Node.AzurePackUsageServicePort)
            {
                $AzurePackUsageServicePort = $Node.AzurePackUsageServicePort
            }
            else
            {
                $AzurePackUsageServicePort = 30022
            }

            xAzurePackResourceProvider "usageservice"
            {
                DependsOn = $DependsOn
                AuthenticationSite = $AdminAuthenticationSite
                AdminUri = $AdminUri
                Name = "usageservice"
                AzurePackAdminCredential = $Node.InstallerServiceAccount
                Enabled = $true
                PassthroughEnabled = $true
                AllowAnonymousAccess = $false
                AllowMultipleInstances = $false
                AdminForwardingAddress = "https://" + $AzurePackAdminAPI + ":" + $AzurePackUsageServicePort + "/"
                TenantForwardingAddress = "https://" + $AzurePackAdminAPI + ":" + $AzurePackUsageServicePort + "/"
            }
        }

        # Set resource provider name - SQL Server
        if(($Node.AzurePackSQLServerExtensionFQDN -or $Node.AzurePackSQLServerExtensionPort) -and ($WindowsAzurePack2013SQLServerExtensionServers[0] -eq $Node.NodeName))
        {
            if($Node.AzurePackSQLServerExtensionFQDN)
            {
                $AzurePackSQLServerExtension = $Node.AzurePackSQLServerExtensionFQDN
            }
            else
            {
                $AzurePackSQLServerExtension = $Node.NodeName.Split(".")[0]
            }
            
            if ($Node.AzurePackSQLServerExtensionPort)
            {
                $AzurePackSQLServerExtensionPort = $Node.AzurePackSQLServerExtensionPort
            }
            else
            {
                $AzurePackSQLServerExtensionPort = 30010
            }

            xAzurePackResourceProvider "sqlservers"
            {
                DependsOn = $DependsOn
                AuthenticationSite = $AdminAuthenticationSite
                AdminUri = $AdminUri
                Name = "sqlservers"
                AzurePackAdminCredential = $Node.InstallerServiceAccount
                Enabled = $true
                PassthroughEnabled = $true
                AllowAnonymousAccess = $false
                AllowMultipleInstances = $false
                AdminForwardingAddress = "https://" + $AzurePackSQLServerExtension + ":" + $AzurePackSQLServerExtensionPort + "/"
                TenantForwardingAddress = "https://" + $AzurePackSQLServerExtension + ":" + $AzurePackSQLServerExtensionPort + "/subscriptions"
                UsageForwardingAddress = "https://" + $AzurePackSQLServerExtension + ":" + $AzurePackSQLServerExtensionPort + "/"
                NotificationForwardingAddress = "https://" + $AzurePackSQLServerExtension + ":" + $AzurePackSQLServerExtensionPort + "/"
            }
        }

        # Set resource provider name - MySQL
        if(($Node.AzurePackMySQLExtensionFQDN -or $Node.AzurePackMySQLExtensionPort) -and ($WindowsAzurePack2013MySQLExtensionServers[0] -eq $Node.NodeName))
        {
            if($Node.AzurePackMySQLExtensionFQDN)
            {
                $AzurePackMySQLExtension = $Node.AzurePackMySQLExtensionFQDN
            }
            else
            {
                $AzurePackMySQLExtension = $Node.NodeName.Split(".")[0]
            }
            
            if ($Node.AzurePackMySQLExtensionPort)
            {
                $AzurePackMySQLExtensionPort = $Node.AzurePackMySQLExtensionPort
            }
            else
            {
                $AzurePackMySQLExtensionPort = 30012
            }

            xAzurePackResourceProvider "mysqlservers"
            {
                DependsOn = $DependsOn
                AuthenticationSite = $AdminAuthenticationSite
                AdminUri = $AdminUri
                Name = "mysqlservers"
                AzurePackAdminCredential = $Node.InstallerServiceAccount
                Enabled = $true
                PassthroughEnabled = $true
                AllowAnonymousAccess = $false
                AllowMultipleInstances = $false
                AdminForwardingAddress = "https://" + $AzurePackMySQLExtension + ":" + $AzurePackMySQLExtensionPort + "/"
                TenantForwardingAddress = "https://" + $AzurePackMySQLExtension + ":" + $AzurePackMySQLExtensionPort + "/subscriptions"
                UsageForwardingAddress = "https://" + $AzurePackMySQLExtension + ":" + $AzurePackMySQLExtensionPort + "/"
                NotificationForwardingAddress = "https://" + $AzurePackMySQLExtension + ":" + $AzurePackMySQLExtensionPort + "/"
            }
        }
    }
}

$SecurePassword = ConvertTo-SecureString -String "Pass@word1" -AsPlainText -Force
$InstallerServiceAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!Installer", $SecurePassword)
$SQLSA = New-Object System.Management.Automation.PSCredential ("sa", $SecurePassword)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true

            SourcePath = "\\RD01\Installer"
            InstallerServiceAccount = $InstallerServiceAccount

            AdminAccount = "CONTOSO\Administrator"
            SQLSA = $SQLSA
            AzurePackAdmin = "CONTOSO\Administrator"

            AzurePackAdminAPIFQDN = "adminapi.contoso.com"
            AzurePackTenantAPIFQDN = "tenantapi.contoso.com"
            AzurePackTenantPublicAPIFQDN = "tenantpublicapi.contoso.com"

            AzurePackSQLServerExtensionFQDN = "sqlserver.contoso.com"
            AzurePackMySQLExtensionFQDN = "mysql.contoso.com"

            AzurePackAdminSiteFQDN = "admin.contoso.com"
            AzurePackWindowsAuthSiteFQDN = "adminauth.contoso.com"
            AzurePackTenantSiteFQDN = "tenant.contoso.com"
            AzurePackAuthSiteFQDN = "tenantauth.contoso.com"
        }
        @{
            NodeName = "WAPDB.contoso.com"
            Roles = @("Windows Azure Pack 2013 Database Server")
            SQLServers = @(
                @{
                    Roles = @("Windows Azure Pack 2013 Database Server")
                    InstanceName = "MSSQLSERVER"
                }
            )
        }
        @{
            NodeName = "WAPA01.contoso.com"
            Roles = @(
                "Windows Azure Pack 2013 Admin API Server",
                "Windows Azure Pack 2013 Tenant API Server",
                "Windows Azure Pack 2013 SQL Server Extension Server",
                "Windows Azure Pack 2013 MySQL Extension Server",
                "Windows Azure Pack 2013 Admin Site Server",
                "Windows Azure Pack 2013 Admin Authentication Site Server"
            )
        }
        @{
            NodeName = "WAPA02.contoso.com"
            Roles = @(
                "Windows Azure Pack 2013 Admin API Server",
                "Windows Azure Pack 2013 Tenant API Server",
                "Windows Azure Pack 2013 SQL Server Extension Server",
                "Windows Azure Pack 2013 MySQL Extension Server",
                "Windows Azure Pack 2013 Admin Site Server",
                "Windows Azure Pack 2013 Admin Authentication Site Server"
            )
        }
        @{
            NodeName = "WAP01.contoso.com"
            Roles = @(
                "Windows Azure Pack 2013 Tenant Public API Server",
                "Windows Azure Pack 2013 Tenant Site Server",
                "Windows Azure Pack 2013 Tenant Authentication Site Server"
            )
        }
        @{
            NodeName = "WAP02.contoso.com"
            Roles = @(
                "Windows Azure Pack 2013 Tenant Public API Server"
                "Windows Azure Pack 2013 Tenant Site Server",
                "Windows Azure Pack 2013 Tenant Authentication Site Server"
            )
        }
        @{
            NodeName = "RD01.contoso.com"
            Roles = @(
                "SQL Server 2012 Management Tools"
            )
        }
    )
}

foreach($Node in $ConfigurationData.AllNodes)
{
    if($Node.NodeName -ne "*")
    {
        Start-Process -FilePath "robocopy.exe" -ArgumentList ("`"C:\Program Files\WindowsPowerShell\Modules`" `"\\" + $Node.NodeName + "\c$\Program Files\WindowsPowerShell\Modules`" /e /purge /xf") -NoNewWindow -Wait
    }
}

AzurePack -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\AzurePack -Verbose
Start-DscConfiguration -Path .\AzurePack -Verbose -Wait -Force