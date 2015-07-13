#requires -Version 5

Configuration SR
{
    Import-DscResource -Module xSQLServer
    Import-DscResource -Module xSCSR

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

        # Install .NET Framework 3.5 on SQL and Web Console nodes
        if(
            ($SystemCenterTechnicalPreviewServiceReportingDatawarehouseServer -eq $Node.NodeName) -or 
            ($SystemCenterTechnicalPreviewServiceReportingAnalysisServer -eq $Node.NodeName) -or
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

        # Install SQL Instances
        if(
            ($SystemCenterTechnicalPreviewServiceReportingDatawarehouseServer -eq $Node.NodeName) -or 
            ($SystemCenterTechnicalPreviewServiceReportingAnalysisServer -eq $Node.NodeName)
        )
        {
            foreach($SQLServer in $Node.SQLServers)
            {
                $SQLInstanceName = $SQLServer.InstanceName

                $Features = ""
                if(
                    (
                        ($SystemCenterTechnicalPreviewServiceReportingDatawarehouseServer -eq $Node.NodeName) -and
                        ($SystemCenterTechnicalPreviewServiceReportingDatawarehouseInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "SQLENGINE,"
                }
                if(
                    (
                        ($SystemCenterTechnicalPreviewServiceReportingAnalysisServer -eq $Node.NodeName) -and 
                        ($SystemCenterTechnicalPreviewServiceReportingAnalysisInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "AS,"
                }
                if(
                    (
                        ($SystemCenterTechnicalPreviewServiceReportingAnalysisServer -eq $Node.NodeName) -and 
                        ($SystemCenterTechnicalPreviewServiceReportingAnalysisInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "IS"
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
                        SQLSvcAccount = $Node.SQLServiceAccount
                        AgtSvcAccount = $Node.SQLServiceAccount
                        ASSvcAccount = $Node.SQLServiceAccount
                        ISSvcAccount = $Node.SQLServiceAccount
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

        # Install prerequisites on Service Reporting server
        if($SystemCenterTechnicalPreviewServiceReportingServer -eq $Node.NodeName)
        {
            WindowsFeature "PowerShell"
            {
                Ensure = "Present"
                Name = "PowerShell"
            }
            
            if($Node.SQLServer2014AnalysisManagementObjects)
            {
                $SQLServer2014AnalysisManagementObjects = (Join-Path -Path $Node.SQLServer2014AnalysisManagementObjects -ChildPath "SQL_AS_AMO.msi")
            }
            else
            {
                $SQLServer2014AnalysisManagementObjects = "\Prerequisites\SQL2014AMO\SQL_AS_AMO.msi"
            }
            Package "SQLServer2014AnalysisManagementObjects"
            {
                Ensure = "Present"
                Name = "Microsoft SQL Server 2014 Analysis Management Objects "
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $SQLServer2014AnalysisManagementObjects)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }

            if($Node.SQLServer2014SystemCLRTypes)
            {
                $SQLServer2014SystemCLRTypes = (Join-Path -Path $Node.SQLServer2014SystemCLRTypes -ChildPath "SQLSysClrTypes.msi")
            }
            else
            {
                $SQLServer2014SystemCLRTypes = "\Prerequisites\SQL2014CLR\SQLSysClrTypes.msi"
            }
            Package "SQLServer2014SystemCLRTypes"
            {
                Ensure = "Present"
                Name = "Microsoft System CLR Types for SQL Server 2014"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $SQLServer2014SystemCLRTypes)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }

            if($Node.SQLServer2014SharedManagementObjects)
            {
                $SQLServer2014SharedManagementObjects = (Join-Path -Path $Node.SQLServer2014SharedManagementObjects -ChildPath "SharedManagementObjects.msi")
            }
            else
            {
                $SQLServer2014SharedManagementObjects = "\Prerequisites\SQL2014SMO\SharedManagementObjects.msi"
            }
            Package "SQLServer2014SharedManagementObjects"
            {
                Ensure = "Present"
                Name = "Microsoft SQL Server 2014 Management Objects  (x64)"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $SQLServer2014SharedManagementObjects)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }

            if($Node.PowerShellExtensionsforSQLServer2014)
            {
                $PowerShellExtensionsforSQLServer2014 = (Join-Path -Path $Node.PowerShellExtensionsforSQLServer2014 -ChildPath "PowerShellTools.msi")
            }
            else
            {
                $PowerShellExtensionsforSQLServer2014 = "\Prerequisites\SQL2014PS\PowerShellTools.msi"
            }
            Package "PowerShellExtensionsforSQLServer2014"
            {
                Ensure = "Present"
                Name = "Windows PowerShell Extensions for SQL Server 2014 "
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $PowerShellExtensionsforSQLServer2014)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }
        }

        # Install Service Reporting server
        if($SystemCenterTechnicalPreviewServiceReportingServer -eq $Node.NodeName)
        {
            # Create DependsOn for Service Reporting server 
            $DependsOn = @(
                "[Package]SQLServer2014AnalysisManagementObjects",
                "[Package]SQLServer2014SystemCLRTypes",
                "[Package]SQLServer2014SharedManagementObjects",
                "[Package]PowerShellExtensionsforSQLServer2014"
            )

            # Wait for Datawarehouse SQL Server
            if ($SystemCenterTechnicalPreviewServiceReportingServer -eq $SystemCenterTechnicalPreviewServiceReportingDatawarehouseServer)
            {
                $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewServiceReportingDatawarehouseServer + $SystemCenterTechnicalPreviewServiceReportingDatawarehouseInstance))
            }
            else
            {
                WaitForAll "SRDW"
                {
                    NodeName = $SystemCenterTechnicalPreviewServiceReportingDatawarehouseServer
                    ResourceName = ("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewServiceReportingDatawarehouseServer + $SystemCenterTechnicalPreviewServiceReportingDatawarehouseInstance)
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }
                $DependsOn += @("[WaitForAll]SRDW")
            }

            # Wait for Analysis SQL Server, if different from Datawarehouse SQL Server
            if (
                ($SystemCenterTechnicalPreviewServiceReportingDatawarehouseServer -ne $SystemCenterTechnicalPreviewServiceReportingAnalysisServer) -or
                ($SystemCenterTechnicalPreviewServiceReportingDatawarehouseInstance -ne $SystemCenterTechnicalPreviewServiceReportingAnalysisInstance)
            )
            {
                if($SystemCenterTechnicalPreviewServiceReportingServer -eq $SystemCenterTechnicalPreviewServiceReportingAnalysisServer)
                {
                    $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewServiceReportingAnalysisServer + $SystemCenterTechnicalPreviewServiceReportingAnalysisInstance))
                }
                else
                {
                    WaitForAll "SRAS"
                    {
                        NodeName = $SystemCenterTechnicalPreviewServiceReportingAnalysisServer
                        ResourceName = ("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewServiceReportingAnalysisServer + $SystemCenterTechnicalPreviewServiceReportingAnalysisInstance)
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn += @("[WaitForAll]SRAS")
                }
            }

            # Install Service Reporting server
            xSCSRServerSetup "SR"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "\SystemCenter.TP\Orchestrator"
                SetupCredential = $Node.InstallerServiceAccount
                DatabaseServer = $SystemCenterTechnicalPreviewServiceReportingDatawarehouseServer
                DatabaseServerInstance = $SystemCenterTechnicalPreviewServiceReportingDatawarehouseInstance
                AnalysisDatabaseServer = $SystemCenterTechnicalPreviewServiceReportingAnalysisServer
                AnalysisDatabaseServerInstance = $SystemCenterTechnicalPreviewServiceReportingAnalysisInstance
            }
        }
    }
}

$SecurePassword = ConvertTo-SecureString -String "Pass@word1" -AsPlainText -Force
$InstallerServiceAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!Installer", $SecurePassword)
$LocalSystemAccount = New-Object System.Management.Automation.PSCredential ("SYSTEM", $SecurePassword)
$SQLServiceAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!sql", $SecurePassword)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true

            SourcePath = "\\RD01\Installer"
            InstallerServiceAccount = $InstallerServiceAccount
            LocalSystemAccount = $LocalSystemAccount

            AdminAccount = "CONTOSO\Administrator"

            SQLServiceAccount = $SQLServiceAccount
        }
        @{
            NodeName = "SRDB.contoso.com"
            Roles = @(
                "System Center Technical Preview Service Reporting Datawarehouse Server",
                "System Center Technical Preview Service Reporting Analysis Server"
            )
            SQLServers = @(
                @{
                Roles = @(
                    "System Center Technical Preview Service Reporting Datawarehouse Server",
                    "System Center Technical Preview Service Reporting Analysis Server"
                )
                    InstanceName = "MSSQLSERVER"
                }
            )
        }
        @{
            NodeName = "SR01.contoso.com"
            Roles = @("System Center Technical Preview Service Reporting Server")
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

SR -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\SR -Verbose
Start-DscConfiguration -Path .\SR -Verbose -Wait -Force