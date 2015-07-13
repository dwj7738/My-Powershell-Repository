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
            ($SystemCenter2012R2ServiceReportingDatawarehouseServer -eq $Node.NodeName) -or 
            ($SystemCenter2012R2ServiceReportingAnalysisServer -eq $Node.NodeName) -or
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

        # Install SQL Instances
        if(
            ($SystemCenter2012R2ServiceReportingDatawarehouseServer -eq $Node.NodeName) -or 
            ($SystemCenter2012R2ServiceReportingAnalysisServer -eq $Node.NodeName)
        )
        {
            foreach($SQLServer in $Node.SQLServers)
            {
                $SQLInstanceName = $SQLServer.InstanceName

                $Features = ""
                if(
                    (
                        ($SystemCenter2012R2ServiceReportingDatawarehouseServer -eq $Node.NodeName) -and
                        ($SystemCenter2012R2ServiceReportingDatawarehouseInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "SQLENGINE,"
                }
                if(
                    (
                        ($SystemCenter2012R2ServiceReportingAnalysisServer -eq $Node.NodeName) -and 
                        ($SystemCenter2012R2ServiceReportingAnalysisInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "AS,"
                }
                if(
                    (
                        ($SystemCenter2012R2ServiceReportingAnalysisServer -eq $Node.NodeName) -and 
                        ($SystemCenter2012R2ServiceReportingAnalysisInstance -eq $SQLInstanceName)
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

        # Install prerequisites on Service Reporting server
        if($SystemCenter2012R2ServiceReportingServer -eq $Node.NodeName)
        {
            WindowsFeature "PowerShell"
            {
                Ensure = "Present"
                Name = "PowerShell"
            }
            
            if($Node.SQLServer2012AnalysisManagementObjects)
            {
                $SQLServer2012AnalysisManagementObjects = (Join-Path -Path $Node.SQLServer2012AnalysisManagementObjects -ChildPath "SQL_AS_AMO.msi")
            }
            else
            {
                $SQLServer2012AnalysisManagementObjects = "\Prerequisites\SQL2012AMO\SQL_AS_AMO.msi"
            }
            Package "SQLServer2012AnalysisManagementObjects"
            {
                Ensure = "Present"
                Name = "Microsoft SQL Server 2012 Analysis Management Objects "
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $SQLServer2012AnalysisManagementObjects)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }

            if($Node.SQLServer2012SystemCLRTypes)
            {
                $SQLServer2012SystemCLRTypes = (Join-Path -Path $Node.SQLServer2012SystemCLRTypes -ChildPath "SQLSysClrTypes.msi")
            }
            else
            {
                $SQLServer2012SystemCLRTypes = "\Prerequisites\SQL2012CLR\SQLSysClrTypes.msi"
            }
            Package "SQLServer2012SystemCLRTypes"
            {
                Ensure = "Present"
                Name = "Microsoft System CLR Types for SQL Server 2012 (x64)"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $SQLServer2012SystemCLRTypes)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }

            if($Node.SQLServer2012SharedManagementObjects)
            {
                $SQLServer2012SharedManagementObjects = (Join-Path -Path $Node.SQLServer2012SharedManagementObjects -ChildPath "SharedManagementObjects.msi")
            }
            else
            {
                $SQLServer2012SharedManagementObjects = "\Prerequisites\SQL2012SMO\SharedManagementObjects.msi"
            }
            Package "SQLServer2012SharedManagementObjects"
            {
                Ensure = "Present"
                Name = "Microsoft SQL Server 2012 Management Objects  (x64)"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $SQLServer2012SharedManagementObjects)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }

            if($Node.PowerShellExtensionsforSQLServer2012)
            {
                $PowerShellExtensionsforSQLServer2012 = (Join-Path -Path $Node.PowerShellExtensionsforSQLServer2012 -ChildPath "PowerShellTools.msi")
            }
            else
            {
                $PowerShellExtensionsforSQLServer2012 = "\Prerequisites\SQL2012PS\PowerShellTools.msi"
            }
            Package "PowerShellExtensionsforSQLServer2012"
            {
                Ensure = "Present"
                Name = "Windows PowerShell Extensions for SQL Server 2012 "
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $PowerShellExtensionsforSQLServer2012)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }
        }

        # Install Service Reporting server
        if($SystemCenter2012R2ServiceReportingServer -eq $Node.NodeName)
        {
            # Create DependsOn for Service Reporting server 
            $DependsOn = @(
                "[Package]SQLServer2012AnalysisManagementObjects",
                "[Package]SQLServer2012SystemCLRTypes",
                "[Package]SQLServer2012SharedManagementObjects",
                "[Package]PowerShellExtensionsforSQLServer2012"
            )

            # Wait for Datawarehouse SQL Server
            if ($SystemCenter2012R2ServiceReportingServer -eq $SystemCenter2012R2ServiceReportingDatawarehouseServer)
            {
                $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenter2012R2ServiceReportingDatawarehouseServer + $SystemCenter2012R2ServiceReportingDatawarehouseInstance))
            }
            else
            {
                WaitForAll "SRDW"
                {
                    NodeName = $SystemCenter2012R2ServiceReportingDatawarehouseServer
                    ResourceName = ("[xSqlServerFirewall]" + $SystemCenter2012R2ServiceReportingDatawarehouseServer + $SystemCenter2012R2ServiceReportingDatawarehouseInstance)
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }
                $DependsOn += @("[WaitForAll]SRDW")
            }

            # Wait for Analysis SQL Server, if different from Datawarehouse SQL Server
            if (
                ($SystemCenter2012R2ServiceReportingDatawarehouseServer -ne $SystemCenter2012R2ServiceReportingAnalysisServer) -or
                ($SystemCenter2012R2ServiceReportingDatawarehouseInstance -ne $SystemCenter2012R2ServiceReportingAnalysisInstance)
            )
            {
                if($SystemCenter2012R2ServiceReportingServer -eq $SystemCenter2012R2ServiceReportingAnalysisServer)
                {
                    $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenter2012R2ServiceReportingAnalysisServer + $SystemCenter2012R2ServiceReportingAnalysisInstance))
                }
                else
                {
                    WaitForAll "SRAS"
                    {
                        NodeName = $SystemCenter2012R2ServiceReportingAnalysisServer
                        ResourceName = ("[xSqlServerFirewall]" + $SystemCenter2012R2ServiceReportingAnalysisServer + $SystemCenter2012R2ServiceReportingAnalysisInstance)
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
                SetupCredential = $Node.InstallerServiceAccount
                DatabaseServer = $SystemCenter2012R2ServiceReportingDatawarehouseServer
                DatabaseServerInstance = $SystemCenter2012R2ServiceReportingDatawarehouseInstance
                AnalysisDatabaseServer = $SystemCenter2012R2ServiceReportingAnalysisServer
                AnalysisDatabaseServerInstance = $SystemCenter2012R2ServiceReportingAnalysisInstance
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
                "System Center 2012 R2 Service Reporting Datawarehouse Server",
                "System Center 2012 R2 Service Reporting Analysis Server"
            )
            SQLServers = @(
                @{
                Roles = @(
                    "System Center 2012 R2 Service Reporting Datawarehouse Server",
                    "System Center 2012 R2 Service Reporting Analysis Server"
                )
                    InstanceName = "MSSQLSERVER"
                }
            )
        }
        @{
            NodeName = "SR01.contoso.com"
            Roles = @("System Center 2012 R2 Service Reporting Server")
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