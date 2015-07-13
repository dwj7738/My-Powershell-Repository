#requires -Version 5

Configuration DPM
{
    Import-DscResource -Module xDismFeature
    Import-DscResource -Module xSqlServer
    Import-DscResource -Module xSCDPM

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
        # Set LCM to reboot if needed since there are several reboots during DPM install
        LocalConfigurationManager
        {
            DebugMode = $true
            RebootNodeIfNeeded = $true
        }

        # Install .NET Framework 3.5 on SQL nodes
        if(
            ($SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer -eq $Node.NodeName) -or 
            ($SystemCenterTechnicalPreviewDataProtectionManagerServers | Where-Object {$_ -eq $Node.NodeName}) -or
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

        # Install SQL Instances
        if(($SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer -eq $Node.NodeName))
        {
            foreach($SQLServer in $Node.SQLServers)
            {
                $SQLInstanceName = $SQLServer.InstanceName

                $Features = "SQLENGINE,RS"
                xSqlServerSetup ($Node.NodeName + $SQLInstanceName)
                {
                    DependsOn = "[WindowsFeature]NET-Framework-Core"
                    SourcePath = $Node.SourcePath
                    SourceFolder = "SQLServer2014.en"
                    SetupCredential = $Node.InstallerServiceAccount
                    InstanceName = $SQLInstanceName
                    Features = $Features
                    SQLSysAdminAccounts = $Node.AdminAccount
                    SQLSvcAccount = $Node.LocalSystemAccount
                    AgtSvcAccount = $Node.LocalSystemAccount
                    RSSvcAccount = $Node.LocalSystemAccount
                }

                xSqlServerFirewall ($Node.NodeName + $SQLInstanceName)
                {
                    DependsOn = ("[xSqlServerSetup]" + $Node.NodeName + $SQLInstanceName)
                    SourcePath = $Node.SourcePath
                    SourceFolder = "SQLServer2014.en"
                    InstanceName = $SQLInstanceName
                    Features = $Features
                }

                # Set SSRS secure connection level on database node
                xSQLServerRSSecureConnectionLevel ($Node.NodeName + $SQLInstanceName)
                {
                    DependsOn = ("[xSqlServerSetup]" + $Node.NodeName + $SQLInstanceName)
                    InstanceName = $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseInstance
                    SecureConnectionLevel = 0
                    SQLAdminCredential = $Node.InstallerServiceAccount
                }
            }
        }

        # Install SQL Management Tools
        if(
            ($SystemCenterTechnicalPreviewDataProtectionManagerServers | Where-Object {$_ -eq $Node.NodeName}) -or
            ($SQLServer2014ManagementTools | Where-Object {$_ -eq $Node.NodeName})
        )
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

        # Install DPM database support on database server if it is seperate from the DPM server
        if(($Node.NodeName -eq $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer) -and (!($SystemCenterTechnicalPreviewDataProtectionManagerServers | Where-Object {$_ -eq $Node.NodeName})))
        {
            xSCDPMDatabaseServerSetup "DPMDB"
            {
                DependsOn = ("[xSqlServerSetup]" + $Node.NodeName + $SQLInstanceName)
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "\SystemCenter.TP\DataProtectionManager"
                SetupCredential = $Node.InstallerServiceAccount
            }
        }

        # DPM servers
        if ($SystemCenterTechnicalPreviewDataProtectionManagerServers | Where-Object {$_ -eq $Node.NodeName})
        {
            # Install Single Instance Storage
            xDismFeature "SIS-Limited"
            {
                Ensure = "Present"
                Name = "SIS-Limited"
            }

            if($Node.NodeName -ne $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer)
            {
                xSCDPMDatabaseServerSetup "DPMDB"
                {
                    Ensure = "Absent"
                    SourcePath = $Node.SourcePath
                    SourceFolder = "\SystemCenter.TP\DataProtectionManager"
                    SetupCredential = $Node.InstallerServiceAccount
                }
            }

            # Wait for DPM database server install, firewall, and config
            WaitForAll "DPMDB"
            {
                NodeName = $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer
                ResourceName = ("[xSqlServerSetup]" + $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer + $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseInstance)
                Credential = $Node.InstallerServiceAccount
                RetryIntervalSec = 5
                RetryCount = 720
            }

            WaitForAll "DPMFW"
            {
                NodeName = $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer
                ResourceName = ("[xSqlServerFirewall]" + $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer + $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseInstance)
                Credential = $Node.InstallerServiceAccount
                RetryIntervalSec = 5
                RetryCount = 720

            }

            WaitForAll "DPMRS"
            {
                NodeName = $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer
                ResourceName = ("[xSQLServerRSSecureConnectionLevel]" + $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer + $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseInstance)
                Credential = $Node.InstallerServiceAccount
                RetryIntervalSec = 5
                RetryCount = 720
            }

            # Wait for all DPM servers before this one
            $DPMDependsOn = @(
                "[WindowsFeature]NET-Framework-Core",
                "[xSCDPMDatabaseServerSetup]DPMDB"
                "[xDismFeature]SIS-Limited",
                "[WaitForAll]DPMDB",
                "[WaitForAll]DPMFW",
                "[WaitForAll]DPMRS"
            )
            $DPMServers = @()
            $ThisDPMServer = $false
            foreach($DPMServer in $SystemCenterTechnicalPreviewDataProtectionManagerServers)
            {
                if(!($ThisDPMServer) -and ($Node.NodeName -ne $DPMServer))
                {
                    $DPMServers += $DPMServer
                }
                else
                {
                    $ThisDPMServer = $true
                }
            }
            if($DPMServers)
            {
                WaitForAll "DPM"
                {
                    NodeName = $DPMServers
                    ResourceName = "[xSCDPMServerSetup]DPM"
                    Credential = $Node.InstallerServiceAccount
                    RetryIntervalSec = 5
                    RetryCount = 720
                }
                $DPMDependsOn += @("[WaitForAll]DPM")
            }

            xSCDPMServerSetup "DPM"
            {
                DependsOn = $DPMDependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SourceFolder = "\SystemCenter.TP\DataProtectionManager"
                SetupCredential = $Node.InstallerServiceAccount
                YukonMachineName = $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer
                YukonInstanceName = $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseInstance
                ReportingMachineName = $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseServer
                ReportingInstanceName = $SystemCenterTechnicalPreviewDataProtectionManagerDatabaseInstance
                YukonMachineCredential = $Node.InstallerServiceAccount
                ReportingMachineCredential = $Node.InstallerServiceAccount
            }
        }
    }
}

$SecurePassword = ConvertTo-SecureString -String "Pass@word1" -AsPlainText -Force
$InstallerServiceAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!Installer", $SecurePassword)
$LocalSystemAccount = New-Object System.Management.Automation.PSCredential ("SYSTEM", $SecurePassword)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            SourcePath = "\\RD01\Installer"
            InstallerServiceAccount = $InstallerServiceAccount
            LocalSystemAccount = $LocalSystemAccount
            PSDscAllowPlainTextPassword = $true
            AdminAccount = "CONTOSO\Administrator"
        }
        @{
            NodeName = "DPMDB.contoso.com"
            Roles = @("System Center Technical Preview Data Protection Manager Database Server")
            SQLServers = @(
                @{
                    Roles = @("System Center Technical Preview Data Protection Manager Database Server")
                    InstanceName = "MSSQLSERVER"
                }
            )
        }
        @{
            NodeName = "DPM01.contoso.com"
            Roles = @("System Center Technical Preview Data Protection Manager Server")
        }
        @{
            NodeName = "DPM02.contoso.com"
            Roles = @("System Center Technical Preview Data Protection Manager Server")
        }
        @{
            NodeName = "DPM03.contoso.com"
            Roles = @("System Center Technical Preview Data Protection Manager Server")
        }
        @{
            NodeName = "RD01.contoso.com"
            Roles = @(
                "System Center Technical Preview Data Protection Manager Console",
                "SQL Server 2014 Management Tools"
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

DPM -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\DPM -Verbose
Start-DscConfiguration -Path .\DPM -Verbose -Wait -Force