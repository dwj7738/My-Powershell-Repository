#requires -Version 5

Configuration OM
{
    Import-DscResource -Module xCredSSP
    Import-DscResource -Module xSQLServer
    Import-DscResource -Module xSCOM

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
            ($SystemCenterTechnicalPreviewOperationsManagerDatabaseServer -eq $Node.NodeName) -or 
            ($SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer -eq $Node.NodeName) -or
            ($SystemCenterTechnicalPreviewOperationsManagerReportingServer -eq $Node.NodeName) -or
            ($SystemCenterTechnicalPreviewOperationsManagerWebConsoleServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($SQLServer2014ManagementTools | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            WindowsFeature "NET-Framework-Core"
            {
                Ensure = "Present"
                Name = "NET-Framework-Core"
                Source = $Node.SourcePath + "\WindowsServer.TP\sources\sxs"
            }
        }

        # Install IIS on Web Console Servers
        if($SystemCenterTechnicalPreviewOperationsManagerWebConsoleServers | Where-Object {$_ -eq $Node.NodeName})
        {
            WindowsFeature "Web-WebServer"
            {
                Ensure = "Present"
                Name = "Web-WebServer"
            }

            WindowsFeature "Web-Request-Monitor"
            {
                Ensure = "Present"
                Name = "Web-Request-Monitor"
            }

            WindowsFeature "Web-Windows-Auth"
            {
                Ensure = "Present"
                Name = "Web-Windows-Auth"
            }

            WindowsFeature "Web-Asp-Net"
            {
                Ensure = "Present"
                Name = "Web-Asp-Net"
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

            WindowsFeature "Web-Mgmt-Console"
            {
                Ensure = "Present"
                Name = "Web-Mgmt-Console"
            }

            WindowsFeature "Web-Metabase"
            {
                Ensure = "Present"
                Name = "Web-Metabase"
            }
        }

        # Install SQL Instances
        if(
            ($SystemCenterTechnicalPreviewOperationsManagerDatabaseServer -eq $Node.NodeName) -or 
            ($SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer -eq $Node.NodeName) -or
            ($SystemCenterTechnicalPreviewOperationsManagerReportingServer -eq $Node.NodeName)
        )
        {
            foreach($SQLServer in $Node.SQLServers)
            {
                $SQLInstanceName = $SQLServer.InstanceName

                $Features = ""
                if(
                    (
                        ($SystemCenterTechnicalPreviewOperationsManagerDatabaseServer -eq $Node.NodeName) -and
                        ($SystemCenterTechnicalPreviewOperationsManagerDatabaseInstance -eq $SQLInstanceName)
                    ) -or 
                    (
                        ($SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer -eq $Node.NodeName) -and
                        ($SystemCenterTechnicalPreviewOperationsManagerDatawarehouseInstance -eq $SQLInstanceName)
                    ) -or
                    (
                        ($SystemCenterTechnicalPreviewOperationsManagerReportingServer -eq $Node.NodeName) -and
                        ($SystemCenterTechnicalPreviewOperationsManagerReportingInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "SQLENGINE,"
                }
                if(
                    (
                        ($SystemCenterTechnicalPreviewOperationsManagerDatabaseServer -eq $Node.NodeName) -and
                        ($SystemCenterTechnicalPreviewOperationsManagerDatabaseInstance -eq $SQLInstanceName)
                    ) -or 
                    (
                        ($SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer -eq $Node.NodeName) -and
                        ($SystemCenterTechnicalPreviewOperationsManagerDatawarehouseInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "FULLTEXT,"
                }
                if(
                    (
                        ($SystemCenterTechnicalPreviewOperationsManagerReportingServer -eq $Node.NodeName) -and 
                        ($SystemCenterTechnicalPreviewOperationsManagerReportingInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "RS,"
                }
                if(
                    (
                        ($SystemCenterTechnicalPreviewOperationsManagerReportingServer -eq $Node.NodeName) -and 
                        ($SystemCenterTechnicalPreviewOperationsManagerReportingInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "AS,"
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
        if($SQLServer2014ManagementTools | Where-Object {$_ -eq $Node.NodeName})
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

        # Install Report Viewer 2012 on Web Console Servers and Consoles
        if(
            ($SystemCenterTechnicalPreviewOperationsManagerWebConsoleServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($SystemCenterTechnicalPreviewOperationsManagerConsoles | Where-Object {$_ -eq $Node.NodeName})
        )
        {
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

            if($Node.ReportViewer2012Redistributable)
            {
                $ReportViewer2012Redistributable = (Join-Path -Path $Node.SQLServer2012SystemCLRTypes -ChildPath "ReportViewer.msi.msi")
            }
            else
            {
                $ReportViewer2012Redistributable = "\Prerequisites\RV2012\ReportViewer.msi"
            }
            Package "ReportViewer2012Redistributable"
            {
                DependsOn = "[Package]SQLServer2012SystemCLRTypes"
                Ensure = "Present"
                Name = "Microsoft Report Viewer 2012 Runtime"
                ProductID = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $ReportViewer2012Redistributable)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }
        }

        # Add service accounts to admins on Management Servers
        if($SystemCenterTechnicalPreviewOperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName})
        {
            Group "Administrators"
            {
                GroupName = "Administrators"
                MembersToInclude = @(
                    $Node.SystemCenter2012OperationsManagerActionAccount.UserName,
                    $Node.SystemCenter2012OperationsManagerDASAccount.UserName
                )
                Credential = $Node.InstallerServiceAccount
            }
        }

        # Install first Management Server
        if ($SystemCenterTechnicalPreviewOperationsManagerManagementServers[0] -eq $Node.NodeName)
        {
            # Enable CredSSP - required for ProductKey PS cmdlet
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

            # Create DependsOn for first Management Server
            $DependsOn = @(
                "[xCredSSP]Server",
                "[xCredSSP]Client",
                "[Group]Administrators"
            )

            # Wait for Operations SQL Server
            if ($SystemCenterTechnicalPreviewOperationsManagerManagementServers[0] -eq $SystemCenterTechnicalPreviewOperationsManagerDatabaseServer)
            {
                $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewOperationsManagerDatabaseServer + $SystemCenterTechnicalPreviewOperationsManagerDatabaseInstance))
            }
            else
            {
                WaitForAll "OMDB"
                {
                    NodeName = $SystemCenterTechnicalPreviewOperationsManagerDatabaseServer
                    ResourceName = ("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewOperationsManagerDatabaseServer + $SystemCenterTechnicalPreviewOperationsManagerDatabaseInstance)
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }
                $DependsOn += @("[WaitForAll]OMDB")
            }

            # Wait for Datawarehouse SQL Server, if different from Operations SQL Server
            if (
                ($SystemCenterTechnicalPreviewOperationsManagerDatabaseServer -ne $SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer) -or
                ($SystemCenterTechnicalPreviewOperationsManagerDatabaseInstance -ne $SystemCenterTechnicalPreviewOperationsManagerDatawarehouseInstance)
            )
            {
                if($SystemCenterTechnicalPreviewOperationsManagerManagementServers[0] -eq $SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer)
                {
                    $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer + $SystemCenterTechnicalPreviewOperationsManagerDatawarehouseInstance))
                }
                else
                {
                    WaitForAll "OMDW"
                    {
                        NodeName = $SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer
                        ResourceName = ("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer + $SystemCenterTechnicalPreviewOperationsManagerDatawarehouseInstance)
                        Credential = $Node.InstallerServiceAccount
                        RetryCount = 720
                        RetryIntervalSec = 5
                    }
                    $DependsOn += @("[WaitForAll]OMDW")
                }
            }

            # Install first Management Server
            xSCOMManagementServerSetup "OMMS"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "SystemCenter.TP\OperationsManager.en"
                SetupCredential = $Node.InstallerServiceAccount
                ProductKey = $Node.SystemCenter2012ProductKey
                ManagementGroupName = "OM_Contoso"
                FirstManagementServer = $true
                ActionAccount = $Node.SystemCenter2012OperationsManagerActionAccount
                DASAccount = $Node.SystemCenter2012OperationsManagerDASAccount
                DataReader = $Node.SystemCenter2012OperationsManagerDataReader
                DataWriter = $Node.SystemCenter2012OperationsManagerDataWriter
                SqlServerInstance = ($SystemCenterTechnicalPreviewOperationsManagerDatabaseServer + "\" + $SystemCenterTechnicalPreviewOperationsManagerDatabaseInstance)
                DwSqlServerInstance = ($SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer + "\" + $SystemCenterTechnicalPreviewOperationsManagerDatawarehouseInstance)
            }
        }

        # Wait for first Management Server on other Management Servers
        # and Reporting and Web Console server, if they are not on a Management Server
        if(
            (
                ($SystemCenterTechnicalPreviewOperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName}) -and 
                ($SystemCenterTechnicalPreviewOperationsManagerManagementServers[0] -ne $Node.NodeName)
            ) -or
            (
                ($SystemCenterTechnicalPreviewOperationsManagerReportingServer -eq $Node.NodeName) -and
                (!($SystemCenterTechnicalPreviewOperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName}))
            ) -or
            (
                ($SystemCenterTechnicalPreviewOperationsManagerWebConsoleServers | Where-Object {$_ -eq $Node.NodeName}) -and
                (!($SystemCenterTechnicalPreviewOperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName}))
            )
        )
        {
            WaitForAll "OMMS"
            {
                NodeName = $SystemCenterTechnicalPreviewOperationsManagerManagementServers[0]
                ResourceName = "[xSCOMManagementServerSetup]OMMS"
                Credential = $Node.InstallerServiceAccount
                RetryCount = 1440
                RetryIntervalSec = 5
            }
        }

        # Install other Management Servers
        if(
            ($SystemCenterTechnicalPreviewOperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName}) -and 
            ($SystemCenterTechnicalPreviewOperationsManagerManagementServers[0] -ne $Node.NodeName)
        )
        {
            xSCOMManagementServerSetup "OMMS"
            {
                DependsOn = @(
                    "[Group]Administrators",
                    "[WaitForAll]OMMS"
                )
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "SystemCenter.TP\OperationsManager.en"
                SetupCredential = $Node.InstallerServiceAccount
                ManagementGroupName = "OM_Contoso"
                FirstManagementServer = $false
                ActionAccount = $Node.SystemCenter2012OperationsManagerActionAccount
                DASAccount = $Node.SystemCenter2012OperationsManagerDASAccount
                DataReader = $Node.SystemCenter2012OperationsManagerDataReader
                DataWriter = $Node.SystemCenter2012OperationsManagerDataWriter
                SqlServerInstance = ($SystemCenterTechnicalPreviewOperationsManagerDatabaseServer + "\" + $SystemCenterTechnicalPreviewOperationsManagerDatabaseInstance)
                DwSqlServerInstance = ($SystemCenterTechnicalPreviewOperationsManagerDatawarehouseServer + "\" + $SystemCenterTechnicalPreviewOperationsManagerDatawarehouseInstance)
            }
        }

        # Install Reporting Server
        if($SystemCenterTechnicalPreviewOperationsManagerReportingServer -eq $Node.NodeName)
        {
            # If this is a Management Server, depend on itself
            # else wait for the first Management Server
            if ($SystemCenterTechnicalPreviewOperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName})
            {
                $DependsOn = "[xSCOMManagementServerSetup]OMMS"
            }
            else
            {
                $DependsOn = "[WaitForAll]OMMS"
            }

            xSCOMReportingServerSetup "OMRS"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "SystemCenter.TP\OperationsManager.en"
                SetupCredential = $Node.InstallerServiceAccount
                ManagementServer = $SystemCenterTechnicalPreviewOperationsManagerManagementServers[0]
                SRSInstance = ($SystemCenterTechnicalPreviewOperationsManagerReportingServer + "\" + $SystemCenterTechnicalPreviewOperationsManagerReportingInstance)
                DataReader = $Node.SystemCenter2012OperationsManagerDataReader
            }
        }

        # Install Web Console Servers
        if($SystemCenterTechnicalPreviewOperationsManagerWebConsoleServers | Where-Object {$_ -eq $Node.NodeName})
        {
            $DependsOn = @(
                "[WindowsFeature]NET-Framework-Core",
                "[WindowsFeature]Web-WebServer",
                "[WindowsFeature]Web-Request-Monitor",
                "[WindowsFeature]Web-Windows-Auth",
                "[WindowsFeature]Web-Asp-Net",
                "[WindowsFeature]Web-Asp-Net45",
                "[WindowsFeature]NET-WCF-HTTP-Activation45",
                "[WindowsFeature]Web-Mgmt-Console",
                "[WindowsFeature]Web-Metabase",
                "[Package]SQLServer2012SystemCLRTypes",
                "[Package]ReportViewer2012Redistributable"
            )
            # If this is a Management Server, depend on itself
            # else wait for the first Management Server
            if ($SystemCenterTechnicalPreviewOperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName})
            {
                $DependsOn += @("[xSCOMManagementServerSetup]OMMS")
            }
            else
            {
                $DependsOn += @("[WaitForAll]OMMS")
            }
            xSCOMWebConsoleServerSetup "OMWC"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "SystemCenter.TP\OperationsManager.en"
                SetupCredential = $Node.InstallerServiceAccount
                ManagementServer = $SystemCenterTechnicalPreviewOperationsManagerManagementServers[0]
            }
        }

        # Install Consoles
        if($SystemCenterTechnicalPreviewOperationsManagerConsoles | Where-Object {$_ -eq $Node.NodeName})
        {
            xSCOMConsoleSetup "OMC"
            {
                DependsOn = @(
                    "[Package]SQLServer2012SystemCLRTypes",
                    "[Package]ReportViewer2012Redistributable"
                )
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "SystemCenter.TP\OperationsManager.en"
                SetupCredential = $Node.InstallerServiceAccount
            }
        }
    }
}

$SecurePassword = ConvertTo-SecureString -String "Pass@word1" -AsPlainText -Force
$InstallerServiceAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!Installer", $SecurePassword)
$LocalSystemAccount = New-Object System.Management.Automation.PSCredential ("SYSTEM", $SecurePassword)
$SystemCenter2012OperationsManagerActionAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!om_saa", $SecurePassword)
$SystemCenter2012OperationsManagerDASAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!om_das", $SecurePassword)
$SystemCenter2012OperationsManagerDataReader = New-Object System.Management.Automation.PSCredential ("CONTOSO\!om_dra", $SecurePassword)
$SystemCenter2012OperationsManagerDataWriter = New-Object System.Management.Automation.PSCredential ("CONTOSO\!om_dwa", $SecurePassword)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true

            SourcePath = "\\RD01\Installer"
            InstallerServiceAccount = $InstallerServiceAccount
            LocalSystemAccount = $LocalSystemAccount

            AdminAccount = "CONTOSO\Administrator"

            SystemCenter2012OperationsManagerActionAccount = $SystemCenter2012OperationsManagerActionAccount
            SystemCenter2012OperationsManagerDASAccount = $SystemCenter2012OperationsManagerDASAccount
            SystemCenter2012OperationsManagerDataReader = $SystemCenter2012OperationsManagerDataReader
            SystemCenter2012OperationsManagerDataWriter = $SystemCenter2012OperationsManagerDataWriter
        }
        @{
            NodeName = "OM01.contoso.com"
            Roles = @(
                "System Center Technical Preview Operations Manager Database Server",
                "System Center Technical Preview Operations Manager Datawarehouse Server",
                "System Center Technical Preview Operations Manager Reporting Server",
                "System Center Technical Preview Operations Manager Management Server",
                "System Center Technical Preview Operations Manager Web Console Server",
                "System Center Technical Preview Operations Manager Console",
                "SQL Server 2014 Management Tools"
            )
            SQLServers = @(
                @{
                    Roles = @(
                        "System Center Technical Preview Operations Manager Database Server",
                        "System Center Technical Preview Operations Manager Datawarehouse Server",
                        "System Center Technical Preview Operations Manager Reporting Server"
                    )
                    InstanceName = "MSSQLSERVER"
                }
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

OM -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\OM -Verbose
Start-DscConfiguration -Path .\OM -Verbose -Wait -Force