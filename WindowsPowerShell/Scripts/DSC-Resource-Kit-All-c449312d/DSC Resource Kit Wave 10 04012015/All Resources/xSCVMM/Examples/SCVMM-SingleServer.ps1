#requires -Version 5

Configuration VMM
{
    Import-DscResource -Module xSQLServer
    Import-DscResource -Module xSCVMM

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
            ($SystemCenter2012R2VirtualMachineManagerDatabaseServer -eq $Node.NodeName) -or 
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
            ($SystemCenter2012R2VirtualMachineManagerDatabaseServer -eq $Node.NodeName)
        )
        {
            foreach($SQLServer in $Node.SQLServers)
            {
                $SQLInstanceName = $SQLServer.InstanceName

                $Features = ""
                if(
                    (
                        ($SystemCenter2012R2VirtualMachineManagerDatabaseServer -eq $Node.NodeName) -and
                        ($SystemCenter2012R2VirtualMachineManagerDatabaseInstance -eq $SQLInstanceName)
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

        # Install prerequisites on Management Servers
        if(
            ($SystemCenter2012R2VirtualMachineManagerManagementServers | Where-Object {$_ -eq $Node.NodeName})
        )
        {
            if($Node.SQLServer2012NativeClient)
            {
                $SQLServer2012NativeClient = (Join-Path -Path $Node.SQLServer2012NativeClient -ChildPath "SQLNCli.msi")
            }
            else
            {
                $SQLServer2012NativeClient = "\Prerequisites\SQL2012NC\SQLNCli.msi"
            }
            Package "SQLServer2012NativeClient"
            {
                Ensure = "Present"
                Name = "Microsoft SQL Server 2012 Native Client "
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $SQLServer2012NativeClient)
                Arguments = "IACCEPTSQLNCLILICENSETERMS=YES ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }

            if($Node.SQLServer2012CommandLineUtilities)
            {
                $SQLServer2012CommandLineUtilities = (Join-Path -Path $Node.SQLServer2012CommandLineUtilities -ChildPath "SQLCmdLnUtils.msi")
            }
            else
            {
                $SQLServer2012CommandLineUtilities = "\Prerequisites\SQL2012CLU\SQLCmdLnUtils.msi"
            }
            Package "SQLServer2012CommandLineUtilities"
            {
                Ensure = "Present"
                Name = "Microsoft SQL Server 2012 Command Line Utilities "
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $SQLServer2012CommandLineUtilities)
                Arguments = "ALLUSERS=2"
                Credential = $Node.InstallerServiceAccount
            }

            if($Node.WindowsDeploymentTools81)
            {
                $WindowsDeploymentTools81 = (Join-Path -Path $Node.WindowsDeploymentTools81 -ChildPath "adksetup.exe")
            }
            else
            {
                $WindowsDeploymentTools81 = "\Prerequisites\ADK81\adksetup.exe"
            }
            Package "WindowsDeploymentTools81"
            {
                Ensure = "Present"
                Name = "Windows Deployment Tools"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $WindowsDeploymentTools81)
                Arguments = "/quiet /features OptionId.DeploymentTools"
                Credential = $Node.InstallerServiceAccount
            }

            if($Node.WindowsPreinstallationEnvironment81)
            {
                $WindowsPreinstallationEnvironment81 = (Join-Path -Path $Node.WindowsPreinstallationEnvironment81 -ChildPath "adksetup.exe")
            }
            else
            {
                $WindowsPreinstallationEnvironment81 = "\Prerequisites\ADK81\adksetup.exe"
            }
            Package "WindowsPreinstallationEnvironment81"
            {
                Ensure = "Present"
                Name = "Windows PE x86 x64"
                ProductId = ""
                Path = (Join-Path -Path $Node.SourcePath -ChildPath $WindowsPreinstallationEnvironment81)
                Arguments = "/quiet /features OptionId.WindowsPreinstallationEnvironment"
                Credential = $Node.InstallerServiceAccount
            }
        }

        # Add service accounts to admins on Management Servers
        if($SystemCenter2012R2VirtualMachineManagerManagementServers | Where-Object {$_ -eq $Node.NodeName})
        {
            Group "Administrators"
            {
                GroupName = "Administrators"
                MembersToInclude = @(
                    $Node.SystemCenter2012VirtualMachineManagerServiceAccount.UserName
                )
                Credential = $Node.InstallerServiceAccount
            }
        }

        # Install first Management Server
        if ($SystemCenter2012R2VirtualMachineManagerManagementServers[0] -eq $Node.NodeName)
        {
            # Create DependsOn for first Management Server
            $DependsOn = @(
                "[Package]SQLServer2012NativeClient",
                "[Package]SQLServer2012CommandLineUtilities",
                "[Package]WindowsDeploymentTools81",
                "[Package]WindowsPreinstallationEnvironment81",
                "[Group]Administrators"
            )

            # Wait for VMM SQL Server
            if ($SystemCenter2012R2VirtualMachineManagerManagementServers[0] -eq $SystemCenter2012R2VirtualMachineManagerDatabaseServer)
            {
                $DependsOn += @(("[xSqlServerFirewall]" + $SystemCenter2012R2VirtualMachineManagerDatabaseServer + $SystemCenter2012R2VirtualMachineManagerDatabaseInstance))
            }
            else
            {
                WaitForAll "VMMDB"
                {
                    NodeName = $SystemCenter2012R2VirtualMachineManagerDatabaseServer
                    ResourceName = ("[xSqlServerFirewall]" + $SystemCenter2012R2VirtualMachineManagerDatabaseServer + $SystemCenter2012R2VirtualMachineManagerDatabaseInstance)
                    Credential = $Node.InstallerServiceAccount
                    RetryCount = 720
                    RetryIntervalSec = 5
                }
                $DependsOn += @("[WaitForAll]VMMDB")
            }

            # Install first Management Server
            xSCVMMManagementServerSetup "VMMMS"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
                ProductKey = $Node.SystemCenter2012ProductKey
                vmmService = $Node.SystemCenter2012VirtualMachineManagerServiceAccount
                SqlMachineName = $SystemCenter2012R2VirtualMachineManagerDatabaseServer
                SqlInstanceName = $SystemCenter2012R2VirtualMachineManagerDatabaseInstance
            }
            
            # Install Update Rollup for Console
            xSCVMMConsoleUpdate "VMMMS"
            {
                DependsOn = "[xSCVMMManagementServerSetup]VMMMS"
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            # Install Update Rollup for Management Server
            xSCVMMManagementServerUpdate "VMMMS"
            {
                DependsOn = "[xSCVMMConsoleUpdate]VMMMS"
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }
        }

        # Install Consoles
        if($SystemCenter2012R2VirtualMachineManagerConsoles | Where-Object {$_ -eq $Node.NodeName})
        {
            xSCVMMConsoleSetup "VMMC"
            {
                Ensure = "Present"
                SourcePath = $Node.SourcePath
                SetupCredential = $Node.InstallerServiceAccount
            }

            # Install Update Rollup for Console
            xSCVMMConsoleUpdate "VMMC"
            {
                DependsOn = "[xSCVMMConsoleSetup]VMMC"
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
$SystemCenter2012VirtualMachineManagerServiceAccount = New-Object System.Management.Automation.PSCredential ("CONTOSO\!vmm", $SecurePassword)

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true

            SourcePath = "\\RD01\Installer"
            InstallerServiceAccount = $InstallerServiceAccount
            LocalSystemAccount = $LocalSystemAccount

            AdminAccount = "CONTOSO\Administrator"

            SystemCenter2012VirtualMachineManagerServiceAccount = $SystemCenter2012VirtualMachineManagerServiceAccount
        }
        @{
            NodeName = "VMM01.contoso.com"
            Roles = @(
                "System Center 2012 R2 Virtual Machine Manager Database Server",
                "System Center 2012 R2 Virtual Machine Manager Management Server",
                "System Center 2012 R2 Virtual Machine Manager Console",
                "SQL Server 2012 Management Tools"
            )
            SQLServers = @(
                @{
                    Roles = @(
                        "System Center 2012 R2 Virtual Machine Manager Database Server"
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

VMM -ConfigurationData $ConfigurationData
Set-DscLocalConfigurationManager -Path .\VMM -Verbose
Start-DscConfiguration -Path .\VMM -Verbose -Wait -Force