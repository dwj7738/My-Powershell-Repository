#requires -Version 5

Configuration SPF
{
    Import-DscResource -Module xSQLServer
    Import-DscResource -Module xSCVMM
    Import-DscResource -Module xSCSPF

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

        # Install .NET Framework 3.5 on SQL nodes
        if(
            ($SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseServer -eq $Node.NodeName) -or
            ($SQLServer2012ManagementTools | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            WindowsFeature "NET-Framework-Core"
            {
                Ensure = "Present"
                Name = "NET-Framework-Core"
                Source = $Node.SourcePath + "\WindowsServer.TP\sources\sxs"
            }
        }

        # Install IIS on Web Service servers
        if(
            ($SystemCenterTechnicalPreviewServiceProviderFoundationServers  | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            WindowsFeature "Web-WebServer"
            {
                Ensure = "Present"
                Name = "Web-WebServer"
            }

            WindowsFeature "Web-Basic-Auth"
            {
                Ensure = "Present"
                Name = "Web-Basic-Auth"
            }

            WindowsFeature "Web-Windows-Auth"
            {
                Ensure = "Present"
                Name = "Web-Windows-Auth"
            }

            WindowsFeature "Web-Asp-Net45"
            {
                Ensure = "Present"
                Name = "Web-Asp-Net45"
            }

            WindowsFeature "NET-WCF-HTTP-Activation45"
            {
                Ensure = "Present"
                Name = "NET-WCF-HTTP-Activation45"
            }

            WindowsFeature "ManagementOData"
            {
                Ensure = "Present"
                Name = "ManagementOData"
            }

            WindowsFeature "Web-Request-Monitor"
            {
                Ensure = "Present"
                Name = "Web-Request-Monitor"
            }

            WindowsFeature "Web-Http-Tracing"
            {
                Ensure = "Present"
                Name = "Web-Http-Tracing"
            }

            WindowsFeature "Web-Scripting-Tools"
            {
                Ensure = "Present"
                Name = "Web-Scripting-Tools"
            }
        }

        # Install SQL Instances
        if(
            ($SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseServer -eq $Node.NodeName)
        )
        {
            foreach($SQLServer in $Node.SQLServers)
            {
                $SQLInstanceName = $SQLServer.InstanceName

                $Features = ""
                if(
                    (
                        ($SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseServer -eq $Node.NodeName) -and
                        ($SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseInstance -eq $SQLInstanceName)
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
                        SourceFolder = "SQLServer2014.en"
                        SetupCredential = $Node.InstallerServiceAccount
                        InstanceName = $SQLInstanceName
                        Features = $Features
                        SQLSysAdminAccounts = $Node.AdminAccount
                    }

                    xSqlServerFirewall ($Node.NodeName + $SQLInstanceName)
                    {
                        DependsOn = ("[xSqlServerSetup]" + $Node.NodeName + $SQLInstanceName)
                        SourcePath = $Node.SourcePath
                        SourceFolder = "SQLServer2014.en"
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
                SourceFolder = "SQLServer2014.en"
                SetupCredential = $Node.InstallerServiceAccount
                InstanceName = "NULL"
                Features = "SSMS,ADV_SSMS"
            }
        }

        # Install SPF prerequisites
        if($SystemCenterTechnicalPreviewServiceProviderFoundationServers | Where-Object {$_ -eq $Node.NodeName})
        {
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

            if($Node.WCFDataServices50)
            {
                $WCFDataServices50 = (Join-Path -Path $Node.WCFDataServices50 -ChildPath "WCFDataServices.exe")
            }
            else
            {
                $WCFDataServices50 = "\Prerequisites\WCF50\WCFDataServices.exe"
            }
            Package "WCFDataServices50"
            {
                Ensure = "Present"
                Name = "WCF Data Services 5.0 (for OData v3) Primary Components"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $WCFDataServices50)
                Arguments = "/q"
                Credential = $Node.InstallerServiceAccount
            }

            xSCVMMConsoleSetup "VMMC"
            {
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "\SystemCenter.TP\VirtualMachineManager"
                SetupCredential = $Node.InstallerServiceAccount
            }
        }

        # Create DependsOn for SPF Server
        $DependsOn = @(
            "[Package]ASPNETMVC4",
            "[Package]WCFDataServices50",
            "[xSCVMMConsoleSetup]VMMC"
        )

        # Install first Server
        if ($SystemCenterTechnicalPreviewServiceProviderFoundationServers[0] -eq $Node.NodeName)
        {
            # Wait for  SQL Server
            if ($SystemCenterTechnicalPreviewServiceProviderFoundationServers[0] -eq $SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseServer)
            {
                $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseServer + $SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseInstance))
            }
            else
            {
                WaitForAll "SPFDB"
                {
                    NodeName = $SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseServer
                    ResourceName = ("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseServer + $SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseInstance)
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }
                $DependsOn += @("[WaitForAll]SPFDB")
            }

            # Install first Web Service Server
            xSCSPFServerSetup "SPF"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "\SystemCenter.TP\Orchestrator"
                SetupCredential = $Node.InstallerServiceAccount
                DatabaseServer = $SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseServer
                SCVMM = $Node.SPFServiceAccount
                SCAdmin = $Node.SPFServiceAccount
                SCProvider = $Node.SPFServiceAccount
                SCUsage = $Node.SPFServiceAccount
                VMMSecurityGroupUsers = $Node.AdminAccount
                AdminSecurityGroupUsers = $Node.AdminAccount
                ProviderSecurityGroupUsers = $Node.AdminAccount
                UsageSecurityGroupUsers = $Node.AdminAccount
            }
        }

        # Wait for first server
        if(
            ($SystemCenterTechnicalPreviewServiceProviderFoundationServers | Where-Object {$_ -eq $Node.NodeName}) -and
            (!($SystemCenterTechnicalPreviewServiceProviderFoundationServers[0] -eq $Node.NodeName))
        )
        {
            WaitForAll "SPF"
            {
                NodeName = $SystemCenterTechnicalPreviewServiceProviderFoundationServers[0]
                ResourceName = "[xSCSPFServerSetup]SPF"
                RetryIntervalSec = 5
                RetryCount = 720
                Credential = $Node.InstallerServiceAccount
            }
            $DependsOn += @("[WaitForAll]SPF")
        }
        
        # Install additional servers
        if(
            ($SystemCenterTechnicalPreviewServiceProviderFoundationServers | Where-Object {$_ -eq $Node.NodeName}) -and
            (!($SystemCenterTechnicalPreviewServiceProviderFoundationServers[0] -eq $Node.NodeName))
        )
        {
            xSCSPFServerSetup "SPF"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "\SystemCenter.TP\Orchestrator"
                SetupCredential = $Node.InstallerServiceAccount
                DatabaseServer = $SystemCenterTechnicalPreviewServiceProviderFoundationDatabaseServer
                SCVMM = $Node.SPFServiceAccount
                SCAdmin = $Node.SPFServiceAccount
                SCProvider = $Node.SPFServiceAccount
                SCUsage = $Node.SPFServiceAccount
                VMMSecurityGroupUsers = $Node.AdminAccount
                AdminSecurityGroupUsers = $Node.AdminAccount
                ProviderSecurityGroupUsers = $Node.AdminAccount
                UsageSecurityGroupUsers = $Node.AdminAccount
            }
        }
    }
}

$SecurePassword = ConvertTo-SecureString -String "Pass@word1" -AsPlainText -Force
$InstallerServiceAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!Installer", $SecurePassword)
$LocalSystemAccount = New-Object System.Management.Automation.PSCredential ("SYSTEM", $SecurePassword)
$SPFServiceAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!spf", $SecurePassword)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true

            SourcePath = "\\RD01\Installer"
            InstallerServiceAccount = $InstallerServiceAccount
            LocalSystemAccount = $LocalSystemAccount
            SPFServiceAccount = $SPFServiceAccount

            AdminAccount = "CONTOSO\Administrator"
        }
        @{
            NodeName = "SPFDB.contoso.com"
            Roles = @("System Center Technical Preview Service Provider Foundation Database Server")
            SQLServers = @(
                @{
                    Roles = @("System Center Technical Preview Service Provider Foundation Database Server")
                    InstanceName = "MSSQLSERVER"
                }
            )
        }
        @{
            NodeName = "SPF01.contoso.com"
            Roles = @("System Center Technical Preview Service Provider Foundation Server")
        }
        @{
            NodeName = "RD01.contoso.com"
            Roles = @("SQL Server 2012 Management Tools")
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

SPF -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\SPF -Verbose
Start-DscConfiguration -Path .\SPF -Verbose -Wait -Force