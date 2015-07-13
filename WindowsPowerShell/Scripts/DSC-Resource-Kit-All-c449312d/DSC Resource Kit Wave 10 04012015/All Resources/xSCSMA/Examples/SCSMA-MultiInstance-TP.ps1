#requires -Version 5

Configuration SMA
{
    Import-DscResource -Module xSQLServer
    Import-DscResource -Module xSCSMA

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
            ($SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseServer -eq $Node.NodeName) -or
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
            ($SystemCenterTechnicalPreviewServiceManagementAutomationWebServiceServers  | Where-Object {$_ -eq $Node.NodeName})
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

            WindowsFeature "Web-Url-Auth"
            {
                Ensure = "Present"
                Name = "Web-Url-Auth"
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
        }

        # Install SQL Instances
        if(
            ($SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseServer -eq $Node.NodeName)
        )
        {
            foreach($SQLServer in $Node.SQLServers)
            {
                $SQLInstanceName = $SQLServer.InstanceName

                $Features = ""
                if(
                    (
                        ($SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseServer -eq $Node.NodeName) -and
                        ($SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseInstance -eq $SQLInstanceName)
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

        # Install SMA PowerShell on all SMA roles
        if(
            ($SystemCenterTechnicalPreviewServiceManagementAutomationWebServiceServers  | Where-Object {$_ -eq $Node.NodeName}) -or
            ($SystemCenterTechnicalPreviewServiceManagementAutomationRunbookWorkerServers  | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            xSCSMAPowerShellSetup "SMAPS"
            {
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "\SystemCenter.TP\Orchestrator"
                SetupCredential = $Node.InstallerServiceAccount
            }
        }

        # Install first Web Service Server
        if ($SystemCenterTechnicalPreviewServiceManagementAutomationWebServiceServers[0] -eq $Node.NodeName)
        {
            # Create DependsOn for first Web Service Server
            $DependsOn = @()

            # Wait for Operations SQL Server
            if ($SystemCenterTechnicalPreviewServiceManagementAutomationWebServiceServers[0] -eq $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseServer)
            {
                $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseServer + $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseInstance))
            }
            else
            {
                WaitForAll "SMADB"
                {
                    NodeName = $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseServer
                    ResourceName = ("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseServer + $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseInstance)
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }
                $DependsOn += @("[WaitForAll]SMADB")
            }

            # Install first Web Service Server
            xSCSMAWebServiceServerSetup "SMAWS"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "\SystemCenter.TP\Orchestrator"
                SetupCredential = $Node.InstallerServiceAccount
                FirstWebServiceServer = $true
                ApPool = $Node.SMAServiceAccount
                AdminGroupMembers = $Node.AdminAccount
                SqlServer = $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseServer
                SqlInstance = $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseInstance
                RunbookWorkerServers = $SystemCenterTechnicalPreviewServiceManagementAutomationRunbookWorkerServers
            }
        }

        # Wait for first Web Service server on other Web Service servers and Runbook Worker server
        if(
            (
                ($SystemCenterTechnicalPreviewServiceManagementAutomationWebServiceServers | Where-Object {$_ -eq $Node.NodeName}) -or
                ($SystemCenterTechnicalPreviewServiceManagementAutomationRunbookWorkerServers | Where-Object {$_ -eq $Node.NodeName})
            ) -and
            (!($SystemCenterTechnicalPreviewServiceManagementAutomationWebServiceServers[0] -eq $Node.NodeName))
        )
        {
            WaitForAll "SMAWS"
            {
                NodeName = $SystemCenterTechnicalPreviewServiceManagementAutomationWebServiceServers[0]
                ResourceName = "[xSCSMAWebServiceServerSetup]SMAWS"
                RetryIntervalSec = 5
                RetryCount = 720
                Credential = $Node.InstallerServiceAccount
            }
        }
        
        # Install additional Web Service servers
        if(
            ($SystemCenterTechnicalPreviewServiceManagementAutomationWebServiceServers | Where-Object {$_ -eq $Node.NodeName}) -and
            (!($SystemCenterTechnicalPreviewServiceManagementAutomationWebServiceServers[0] -eq $Node.NodeName))
        )
        {
            xSCSMAWebServiceServerSetup "SMAWS"
            {
                DependsOn = "[WaitForAll]SMAWS"
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "\SystemCenter.TP\Orchestrator"
                SetupCredential = $Node.InstallerServiceAccount
                FirstWebServiceServer = $false
                ApPool = $Node.SMAServiceAccount
                AdminGroupMembers = $Node.AdminAccount
                SqlServer = $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseServer
                SqlInstance = $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseInstance
            }
        }

        # Install Runbook Worker servers
        if($SystemCenterTechnicalPreviewServiceManagementAutomationRunbookWorkerServers | Where-Object {$_ -eq $Node.NodeName})
        {
            # If this is the first Web Service server, depend on that
            # otherwise wait for that
            if($SystemCenterTechnicalPreviewServiceManagementAutomationWebServiceServers[0] -eq $Node.NodeName)
            {
                $DependsOn = "[xSCSMAWebServiceServerSetup]SMAWS"
            }
            else
            {
                $DependsOn = "[WaitForAll]SMAWS"
            }

            xSCSMARunbookWorkerServerSetup "SMARW"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "\SystemCenter.TP\Orchestrator"
                SetupCredential = $Node.InstallerServiceAccount
                Service = $Node.SMAServiceAccount
                SqlServer = $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseServer
                SqlInstance = $SystemCenterTechnicalPreviewServiceManagementAutomationDatabaseInstance
            }
        }
    }
}

$SecurePassword = ConvertTo-SecureString -String "Pass@word1" -AsPlainText -Force
$InstallerServiceAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!Installer", $SecurePassword)
$LocalSystemAccount = New-Object System.Management.Automation.PSCredential ("SYSTEM", $SecurePassword)
$SMAServiceAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!sma", $SecurePassword)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true

            SourcePath = "\\RD01\Installer"
            InstallerServiceAccount = $InstallerServiceAccount
            LocalSystemAccount = $LocalSystemAccount
            SMAServiceAccount = $SMAServiceAccount

            AdminAccount = "CONTOSO\Administrator"
        }
        @{
            NodeName = "SMADB.contoso.com"
            Roles = @("System Center Technical Preview Service Management Automation Database Server")
            SQLServers = @(
                @{
                    Roles = @("System Center Technical Preview Service Management Automation Database Server")
                    InstanceName = "MSSQLSERVER"
                }
            )
        }
        @{
            NodeName = "SMA01.contoso.com"
            Roles = @("System Center Technical Preview Service Management Automation Web Service Server")
        }
        @{
            NodeName = "SMA02.contoso.com"
            Roles = @("System Center Technical Preview Service Management Automation Web Service Server")
        }
        @{
            NodeName = "SMA03.contoso.com"
            Roles = @("System Center Technical Preview Service Management Automation Runbook Worker Server")
        }
        @{
            NodeName = "SMA04.contoso.com"
            Roles = @("System Center Technical Preview Service Management Automation Runbook Worker Server")
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

SMA -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\SMA -Verbose
Start-DscConfiguration -Path .\SMA -Verbose -Wait -Force