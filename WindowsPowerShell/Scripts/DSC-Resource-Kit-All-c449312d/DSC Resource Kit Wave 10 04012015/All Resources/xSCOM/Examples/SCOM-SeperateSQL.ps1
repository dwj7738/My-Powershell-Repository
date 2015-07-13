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
            ($SystemCenter2012R2OperationsManagerDatabaseServer -eq $Node.NodeName) -or 
            ($SystemCenter2012R2OperationsManagerDatawarehouseServer -eq $Node.NodeName) -or
            ($SystemCenter2012R2OperationsManagerReportingServer -eq $Node.NodeName) -or
            ($SystemCenter2012R2OperationsManagerWebConsoleServers | Where-Object {$_ -eq $Node.NodeName}) -or
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

        # Install IIS on Web Console Servers
        if($SystemCenter2012R2OperationsManagerWebConsoleServers | Where-Object {$_ -eq $Node.NodeName})
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
            ($SystemCenter2012R2OperationsManagerDatabaseServer -eq $Node.NodeName) -or 
            ($SystemCenter2012R2OperationsManagerDatawarehouseServer -eq $Node.NodeName) -or
            ($SystemCenter2012R2OperationsManagerReportingServer -eq $Node.NodeName)
        )
        {
            foreach($SQLServer in $Node.SQLServers)
            {
                $SQLInstanceName = $SQLServer.InstanceName

                $Features = ""
                if(
                    (
                        ($SystemCenter2012R2OperationsManagerDatabaseServer -eq $Node.NodeName) -and
                        ($SystemCenter2012R2OperationsManagerDatabaseInstance -eq $SQLInstanceName)
                    ) -or 
                    (
                        ($SystemCenter2012R2OperationsManagerDatawarehouseServer -eq $Node.NodeName) -and
                        ($SystemCenter2012R2OperationsManagerDatawarehouseInstance -eq $SQLInstanceName)
                    ) -or
                    (
                        ($SystemCenter2012R2OperationsManagerReportingServer -eq $Node.NodeName) -and
                        ($SystemCenter2012R2OperationsManagerReportingInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "SQLENGINE,"
                }
                if(
                    (
                        ($SystemCenter2012R2OperationsManagerDatabaseServer -eq $Node.NodeName) -and
                        ($SystemCenter2012R2OperationsManagerDatabaseInstance -eq $SQLInstanceName)
                    ) -or 
                    (
                        ($SystemCenter2012R2OperationsManagerDatawarehouseServer -eq $Node.NodeName) -and
                        ($SystemCenter2012R2OperationsManagerDatawarehouseInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "FULLTEXT,"
                }
                if(
                    (
                        ($SystemCenter2012R2OperationsManagerReportingServer -eq $Node.NodeName) -and 
                        ($SystemCenter2012R2OperationsManagerReportingInstance -eq $SQLInstanceName)
                    )
                )
                {
                    $Features += "RS,"
                }
                if(
                    (
                        ($SystemCenter2012R2OperationsManagerReportingServer -eq $Node.NodeName) -and 
                        ($SystemCenter2012R2OperationsManagerReportingInstance -eq $SQLInstanceName)
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
                        SetupCredential = $Node.InstallerServiceAccount
                        InstanceName = $SQLInstanceName
                        Features = $Features
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

        # Install Report Viewer 2012 on Web Console Servers and Consoles
        if(
            ($SystemCenter2012R2OperationsManagerWebConsoleServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($SystemCenter2012R2OperationsManagerConsoles | Where-Object {$_ -eq $Node.NodeName})
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
        if($SystemCenter2012R2OperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName})
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
        if ($SystemCenter2012R2OperationsManagerManagementServers[0] -eq $Node.NodeName)
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
            if ($SystemCenter2012R2OperationsManagerManagementServers[0] -eq $SystemCenter2012R2OperationsManagerDatabaseServer)
            {
                $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenter2012R2OperationsManagerDatabaseServer + $SystemCenter2012R2OperationsManagerDatabaseInstance))
            }
            else
            {
                WaitForAll "OMDB"
                {
                    NodeName = $SystemCenter2012R2OperationsManagerDatabaseServer
                    ResourceName = ("[xSqlServerFirewall]" + $SystemCenter2012R2OperationsManagerDatabaseServer + $SystemCenter2012R2OperationsManagerDatabaseInstance)
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }
                $DependsOn += @("[WaitForAll]OMDB")
            }

            # Wait for Datawarehouse SQL Server, if different from Operations SQL Server
            if (
                ($SystemCenter2012R2OperationsManagerDatabaseServer -ne $SystemCenter2012R2OperationsManagerDatawarehouseServer) -or
                ($SystemCenter2012R2OperationsManagerDatabaseInstance -ne $SystemCenter2012R2OperationsManagerDatawarehouseInstance)
            )
            {
                if($SystemCenter2012R2OperationsManagerManagementServers[0] -eq $SystemCenter2012R2OperationsManagerDatawarehouseServer)
                {
                    $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenter2012R2OperationsManagerDatawarehouseServer + $SystemCenter2012R2OperationsManagerDatawarehouseInstance))
                }
                else
                {
                    WaitForAll "OMDW"
                    {
                        NodeName = $SystemCenter2012R2OperationsManagerDatawarehouseServer
                        ResourceName = ("[xSqlServerFirewall]" + $SystemCenter2012R2OperationsManagerDatawarehouseServer + $SystemCenter2012R2OperationsManagerDatawarehouseInstance)
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
                SetupCredential = $Node.InstallerServiceAccount
                ProductKey = $Node.SystemCenter2012ProductKey
                ManagementGroupName = "OM_Contoso"
                FirstManagementServer = $true
                ActionAccount = $Node.SystemCenter2012OperationsManagerActionAccount
                DASAccount = $Node.SystemCenter2012OperationsManagerDASAccount
                DataReader = $Node.SystemCenter2012OperationsManagerDataReader
                DataWriter = $Node.SystemCenter2012OperationsManagerDataWriter
                SqlServerInstance = ($SystemCenter2012R2OperationsManagerDatabaseServer + "\" + $SystemCenter2012R2OperationsManagerDatabaseInstance)
                DwSqlServerInstance = ($SystemCenter2012R2OperationsManagerDatawarehouseServer + "\" + $SystemCenter2012R2OperationsManagerDatawarehouseInstance)
            }
        }

        # Wait for first Management Server on other Management Servers
        # and Reporting and Web Console server, if they are not on a Management Server
        if(
            (
                ($SystemCenter2012R2OperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName}) -and 
                ($SystemCenter2012R2OperationsManagerManagementServers[0] -ne $Node.NodeName)
            ) -or
            (
                ($SystemCenter2012R2OperationsManagerReportingServer -eq $Node.NodeName) -and
                (!($SystemCenter2012R2OperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName}))
            ) -or
            (
                ($SystemCenter2012R2OperationsManagerWebConsoleServers | Where-Object {$_ -eq $Node.NodeName}) -and
                (!($SystemCenter2012R2OperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName}))
            )
        )
        {
            WaitForAll "OMMS"
            {
                NodeName = $SystemCenter2012R2OperationsManagerManagementServers[0]
                ResourceName = "[xSCOMManagementServerSetup]OMMS"
                Credential = $Node.InstallerServiceAccount
                RetryCount = 1440
                RetryIntervalSec = 5
            }
        }

        # Install other Management Servers
        if(
            ($SystemCenter2012R2OperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName}) -and 
            ($SystemCenter2012R2OperationsManagerManagementServers[0] -ne $Node.NodeName)
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
                SetupCredential = $Node.InstallerServiceAccount
                ManagementGroupName = "OM_Contoso"
                FirstManagementServer = $false
                ActionAccount = $Node.SystemCenter2012OperationsManagerActionAccount
                DASAccount = $Node.SystemCenter2012OperationsManagerDASAccount
                DataReader = $Node.SystemCenter2012OperationsManagerDataReader
                DataWriter = $Node.SystemCenter2012OperationsManagerDataWriter
                SqlServerInstance = ($SystemCenter2012R2OperationsManagerDatabaseServer + "\" + $SystemCenter2012R2OperationsManagerDatabaseInstance)
                DwSqlServerInstance = ($SystemCenter2012R2OperationsManagerDatawarehouseServer + "\" + $SystemCenter2012R2OperationsManagerDatawarehouseInstance)
            }
        }

        # Install Reporting Server
        if($SystemCenter2012R2OperationsManagerReportingServer -eq $Node.NodeName)
        {
            # If this is a Management Server, depend on itself
            # else wait for the first Management Server
            if ($SystemCenter2012R2OperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName})
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
                SetupCredential = $Node.InstallerServiceAccount
                ManagementServer = $SystemCenter2012R2OperationsManagerManagementServers[0]
                SRSInstance = ($SystemCenter2012R2OperationsManagerReportingServer + "\" + $SystemCenter2012R2OperationsManagerReportingInstance)
                DataReader = $Node.SystemCenter2012OperationsManagerDataReader
            }
        }

        # Install Web Console Servers
        if($SystemCenter2012R2OperationsManagerWebConsoleServers | Where-Object {$_ -eq $Node.NodeName})
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
            if ($SystemCenter2012R2OperationsManagerManagementServers | Where-Object {$_ -eq $Node.NodeName})
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
                SetupCredential = $Node.InstallerServiceAccount
                ManagementServer = $SystemCenter2012R2OperationsManagerManagementServers[0]
            }
        }

        # Install Consoles
        if($SystemCenter2012R2OperationsManagerConsoles | Where-Object {$_ -eq $Node.NodeName})
        {
            xSCOMConsoleSetup "OMC"
            {
                DependsOn = @(
                    "[Package]SQLServer2012SystemCLRTypes",
                    "[Package]ReportViewer2012Redistributable"
                )
                Ensure = "Present"
                SourcePath = $Node.SourcePath
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
            NodeName = "OMDB.contoso.com"
            Roles = @(
                "System Center 2012 R2 Operations Manager Database Server"
                "System Center 2012 R2 Operations Manager Datawarehouse Server",
                "System Center 2012 R2 Operations Manager Reporting Server"
            )
            SQLServers = @(
                @{
                    Roles = @(
                        "System Center 2012 R2 Operations Manager Database Server"
                        "System Center 2012 R2 Operations Manager Datawarehouse Server",
                        "System Center 2012 R2 Operations Manager Reporting Server"
                    )
                    InstanceName = "MSSQLSERVER"
                }
            )
        }
        @{
            NodeName = "OM01.contoso.com"
            Roles = @(
                "System Center 2012 R2 Operations Manager Management Server",
                "System Center 2012 R2 Operations Manager Web Console Server",
                "System Center 2012 R2 Operations Manager Console",
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

OM -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\OM -Verbose
Start-DscConfiguration -Path .\OM -Verbose -Wait -Force