Function New-LocalUser
{
	<#
		.SYNOPSIS
			Create a new user account on the local computer.
		.DESCRIPTION
			This function will create a user account on the local computer.
		.PARAMETER Computer
			The NetBIOS name of the computer that you will create the account on.
		.PARAMETER User
			The user name of the account that will be created.
		.PARAMETER Password
			The password for the account, this must follow password policies enforced
			on the destination computer.
		.PARAMETER Description
			A description of what this account will be used for.
		.NOTES
			You will need to run this with either UAC disabled or from an elevated prompt.
		.EXAMPLE
            New-LocalUser -ComputerName MyComputer -User MyUserAccount -Password MyP@ssw0rd -Description "Account."
                
            Description
            -----------
            Creates a user named MyUserAccount on MyComputer.
		.LINK
			https://code.google.com/p/mod-posh/wiki/ComputerManagement#New-LocalUser
	#>
    [CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$true)]
		[string]$ComputerName = (& hostname),
		[Parameter(Mandatory=$true)]
		[string]$User,
		[Parameter(Mandatory=$true)]
		[string]$Password,
		[string]$Description
		)
    Begin
    {
        }
    Process
    {
        Try
        {
            $objComputer = [ADSI]("WinNT://$($ComputerName)")
            $objUser = $objComputer.Create("User", $User)
            $objUser.SetPassword($password)
            $objUser.SetInfo()
            $objUser.description = $Description
            $objUser.SetInfo()
            Return $?
            }
        Catch
        {
            Return $Error[0].Exception.InnerException.Message.ToString().Trim()
            }
        }
    End
    {
        }
	}
Function Set-Pass
{
	<#
		.SYNOPSIS
			Change the password of an existing user account.
		.DESCRIPTION
			This function will change the password for an existing user account. 
		.PARAMETER ComputerName
			The NetBIOS name of the computer that you will add the account to.
		.PARAMETER UserName
			The user name of the account that will be created.
		.PARAMETER Password
			The password for the account, this must follow password policies enforced
			on the destination computer.
		.NOTES
			You will need to run this with either UAC disabled or from an elevated prompt.
		.EXAMPLE
			Set-Pass -ComputerName MyComputer -UserName MyUserAccount -Password N3wP@ssw0rd
		.LINK
			https://code.google.com/p/mod-posh/wiki/ComputerManagement#Set-Pass
	#>
    [CmdletBinding()]
	Param
        (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName = (& hostname),
        [Parameter(Mandatory=$true)]
        [string]$UserName,
        [Parameter(Mandatory=$true)]
        [string]$Password
        )
    Begin
    {
        }
    Process
    {
        Try
        {
            $User = [adsi]("WinNT://$ComputerName/$UserName, user")
            $User.psbase.invoke("SetPassword", $Password)
                    
            Return "Password updated"
            }
        Catch
        {
            Return $Error[0].Exception.InnerException.Message.ToString().Trim()
            }
        }    
    End
    {
        }
	}	
Function Add-LocalUserToGroup
{
	<#
		.SYNOPSIS
			Add an existing user to a local group.
		.DESCRIPTION
			This function will add an existing user to an existing group.
		.PARAMETER Computer
			The NetBIOS name of the computer that you will add the account to.
		.PARAMETER User
			The user name of the account that will be created.
		.PARAMETER Group
			The name of an existing group to add this user to.
		.NOTES
			You will need to run this with either UAC disabled or from an elevated prompt.
		.EXAMPLE
			Add-LocalUserToGroup -ComputerName MyComputer -User MyUserAccount -Group Administrators
		.LINK
			https://code.google.com/p/mod-posh/wiki/ComputerManagement#Add-LocalUserToGroup
	#>
    [CmdletBinding()]
	Param
		(
		[Parameter(Mandatory=$true)]
		[string]$ComputerName = (& hostname),
		[Parameter(Mandatory=$true)]
		[string]$User,
		[Parameter(Mandatory=$true)]
		[string]$Group
		)
    Begin
    {
        }
    Process
    {
        Try
        {
            $objComputer = [ADSI]("WinNT://$($ComputerName)/$($Group),group")
            $objComputer.add("WinNT://$($ComputerName)/$($User),group")
            Return $?
            }
        Catch
        {
            Return $Error[0].Exception.InnerException.Message.ToString().Trim()
            }
        }
    End
    {
        }
	}
Function New-ScheduledTask
{
	<#
	.SYNOPSIS
		Create a Scheduled Task on a computer.
	.DESCRIPTION
		Create a Scheduled Task on a local or remote computer. 
	.PARAMETER TaskName
		Specifies a name for the task.
	.PARAMETER TaskRun
		Specifies the program or command that the task runs. Type 
		the fully qualified path and file name of an executable file, 
		script file, or batch file. If you omit the path, SchTasks.exe 
		assumes that the file is in the Systemroot\System32 directory. 
	.PARAMETER TaskSchedule
		Specifies the schedule type. Valid values are 
			MINUTE
			HOURLY
			DAILY
			WEEKLY
			MONTHLY
			ONCE
			ONSTART
			ONLOGON
			ONIDLE
	.PARAMETER StartTime
		Specifies the time of day that the task starts in HH:MM:SS 24-hour 
		format. The default value is the current local time when the command 
		completes. The /st parameter is valid with MINUTE, HOURLY, DAILY, 
		WEEKLY, MONTHLY, and ONCE schedules. It is required with a ONCE 
		schedule. 
	.PARAMETER StartDate
		Specifies the date that the task starts in MM/DD/YYYY format. The 
		default value is the current date. The /sd parameter is valid with all 
		schedules, and is required for a ONCE schedule. 
	.PARAMETER TaskUser
		Runs the tasks with the permission of the specified user account. By 
		default, the task runs with the permissions of the user logged on to the 
		computer running SchTasks.
	.PARAMETER Server
		The NetBIOS name of the computer to create the scheduled task on.
	.NOTES
		You will need to run this with either UAC disabled or from an elevated prompt.
		The full syntax of the command can be found here:
			http://technet.microsoft.com/en-us/library/bb490996.aspx
	.EXAMPLE
		New-ScheduledTask -TaskName "Reboot Computer" -TaskRun "shutdown /r" -TaskSchedule ONCE `
        -StartTime "18:00:00" -StartDate "03/16/2011" -TaskUser SYSTEM -Server MyDesktopPC
	.LINK
		https://code.google.com/p/mod-posh/wiki/ComputerManagement#New-ScheduledTask
	#>
    [CmdletBinding()]		
	Param
		(
		[Parameter(Mandatory=$true)]
		[string]$TaskName,
		[Parameter(Mandatory=$true)]
		[string]$TaskRun,
		[Parameter(Mandatory=$true)]
		[string]$TaskSchedule,
		[Parameter(Mandatory=$true)]
		[string]$StartTime,
		[Parameter(Mandatory=$true)]
		[string]$StartDate,
		[Parameter(Mandatory=$true)]
		[string]$TaskUser,
		[Parameter(Mandatory=$true)]
		[string]$Server	
		)
    Begin
    {
        }
    Process
    {
	    schtasks /create /tn $TaskName /tr $TaskRun /sc $TaskSchedule /st $StartTime /sd $StartDate /ru $TaskUser /s $Server
        }
    End
    {
        Return $?
        }
	}
Function Remove-UserFromLocalGroup
{
	<#
		.SYNOPSIS
			Removes a user/group from a local computer group.
		.DESCRIPTION
			Removes a user/group from a local computer group.
		.PARAMETER Computer
			Name of the computer to connect to.
		.PARAMETER User
			Name of the user or group to remove.
		.PARAMETER GroupName
			Name of the group where that the user/group is a member of.
		.NOTES
			You will need to run this with either UAC disabled or from an elevated prompt.
		.EXAMPLE
			Remove-UserFromLocalGroup -ComputerName MyComputer -UserName RandomUser
                
            Description
            -----------
            This example removes a user from the local administrators group.
        .Example
            Remove-UserFromLocalGroup -ComputerName MyComputer -UserName RandomUser -GroupName Users
                
            Description
            -----------
            This example removes a user from the local users group.
		.LINK
			https://code.google.com/p/mod-posh/wiki/ComputerManagement#Remove-UserFromLocalGroup
	#>
    [CmdletBinding()]		
	Param
		(
		[Parameter(Mandatory=$true)]
		[string]$ComputerName = (& hostname),
		[Parameter(Mandatory=$true)]
		[string]$UserName,
		[Parameter(Mandatory=$true)]
		[string]$GroupName="Administrators"
		)
	Begin
    {
        }
    Process
    {
	    $Group = $Computer.psbase.children.find($GroupName)
	    $Group.Remove("WinNT://$Computer/$User")
        }
    End
    {
        Return $?
        }
	}
Function Get-Services
{
	<#
		.SYNOPSIS
			Get a list of services
		.DESCRIPTION
			This function returns a list of services on a given computer. This list can be filtered based on the
			given StartMode  (ie. Running, Stopped) as well as filtered on StartMode (ie. Auto, Manual).
		.PARAMETER State
			Most often this will be either Running or Stopped, but possible values include
				Running
				Stopped
				Paused
		.PARAMETER StartMode
			Most often this will be either Auto or Manual, but possible values include
				Auto
				Manual
				Disabled
		.PARAMETER Computer
			The NetBIOS name of the computer to retrieve services from
		.NOTES
			Depending on how you are setup you may need to provide credentials in order to access remote machines
			You may need to have UAC disabled or run PowerShell as an administrator to see services locally
		.EXAMPLE
			Get-Services |Format-Table -AutoSize

			ExitCode Name                 ProcessId StartMode State   Status
			-------- ----                 --------- --------- -----   ------
					0 atashost                  1380 Auto      Running OK
					0 AudioEndpointBuilder       920 Auto      Running OK
					0 AudioSrv                   880 Auto      Running OK
					0 BFE                       1236 Auto      Running OK
					0 BITS                       964 Auto      Running OK
					0 CcmExec                   2308 Auto      Running OK
					0 CryptSvc                  1088 Auto      Running OK
				
			Description
			-----------
			This example shows the default options in place
		.EXAMPLE
			Get-Services -State "stopped" |Format-Table -AutoSize

			ExitCode Name                           ProcessId StartMode State   Status
			-------- ----                           --------- --------- -----   ------
					0 AppHostSvc                             0 Auto      Stopped OK
					0 clr_optimization_v4.0.30319_32         0 Auto      Stopped OK
					0 clr_optimization_v4.0.30319_64         0 Auto      Stopped OK
					0 MMCSS                                  0 Auto      Stopped OK
					0 Net Driver HPZ12                       0 Auto      Stopped OK
					0 Pml Driver HPZ12                       0 Auto      Stopped OK
					0 sppsvc                                 0 Auto      Stopped OK
				
			Description
			-----------
			This example shows the output when specifying the state parameter
		.EXAMPLE
			Get-Services -State "stopped" -StartMode "disabled" |Format-Table -AutoSize

			ExitCode Name                           ProcessId StartMode State   Status
			-------- ----                           --------- --------- -----   ------
				1077 clr_optimization_v2.0.50727_32         0 Disabled  Stopped OK
				1077 clr_optimization_v2.0.50727_64         0 Disabled  Stopped OK
				1077 CscService                             0 Disabled  Stopped OK
				1077 Mcx2Svc                                0 Disabled  Stopped OK
				1077 MSSQLServerADHelper100                 0 Disabled  Stopped OK
				1077 NetMsmqActivator                       0 Disabled  Stopped OK
				1077 NetPipeActivator                       0 Disabled  Stopped OK
				
			Description
			-----------
			This example shows how to specify a different state and startmode.
		.EXAMPLE
			Get-Services -Computer dpm -Credential "Domain\Administrator" |Format-Table -AutoSize

			ExitCode Name                   ProcessId StartMode State   Status
			-------- ----                   --------- --------- -----   ------
					0 AppHostSvc                  1152 Auto      Running OK
					0 BFE                          564 Auto      Running OK
					0 CryptSvc                    1016 Auto      Running OK
					0 DcomLaunch                   600 Auto      Running OK
					0 Dhcp                         776 Auto      Running OK
					0 Dnscache                    1016 Auto      Running OK
					0 DPMAMService                1184 Auto      Running OK
				
			Description
			-----------
			This example shows how to specify a remote computer and credentials to authenticate with.
		.LINK
			https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-Services
	#>
    [CmdletBinding()]		
	Param
		(
		[string]$Computer = (& hostname),
		$Credential,
		[string]$State = "Running",
		[string]$StartMode = "Auto"
		)
    Begin
    {
        }
    Process
    {
        If ($Computer -eq (& hostname))
	    {		
		    $Services = Get-WmiObject win32_service -filter "State = '$State' and StartMode = '$StartMode'"
	        }
        Else
	    {
		    If ($Credential -eq $null)
			{
				$Credential = Get-Credential
			    }
		    $Services = Get-WmiObject win32_service -filter "State = '$State' and StartMode = '$StartMode'" `
					    -ComputerName $Computer -Credential $Credential
	        }
        }
    End
    {
	    Return $Services
        }
	}
Function Get-NonStandardServiceAccounts
{
	<#
		.SYNOPSIS
			Return a list of services using Non-Standard accounts.
		.DESCRIPTION
			This function returns a list of services from local or remote coputers that have non-standard
			user accounts for logon credentials.
		.PARAMETER Computer
			The NetBIOS name of the computer to pull services from.
		.PARAMETER Credentials
			The DOMAIN\USERNAME of an account with permissions to access services.
		.PARAMETER Filter
			This is a pipe (|) seperated list of accounts to filter out of the returned services list.
		.EXAMPLE
			Get-NonStandardServiceAccounts

			StartName                         Name                             DisplayName
			---------                         ----                             -----------
			.\Jeff Patton                     MyService                        My Test Service
				
			Description
			-----------
			This example shows no parameters provided
		.EXAMPLE
			Get-NonStandardServiceAccounts -Computer dpm -Credentials $Credentials

			StartName                         Name                             DisplayName
			---------                         ----                             -----------
			.\MICROSOFT$DPM$Acct              MSSQL$MS$DPM2007$                SQL Server (MS$DPM2007$)
			.\MICROSOFT$DPM$Acct              MSSQL$MSDPM2010                  SQL Server (MSDPM2010)
			NT AUTHORITY\NETWORK SERVICE      MSSQLServerADHelper100           SQL Active Directory Helper S...
			NT AUTHORITY\NETWORK SERVICE      ReportServer$MSDPM2010           SQL Server Reporting Services...
			.\MICROSOFT$DPM$Acct              SQLAgent$MS$DPM2007$             SQL Server Agent (MS$DPM2007$)
			.\MICROSOFT$DPM$Acct              SQLAgent$MSDPM2010               SQL Server Agent (MSDPM2010)
				
			Description
			-----------
			This example shows all parameters in use
		.EXAMPLE
			Get-NonStandardServiceAccounts -Computer dpm -Credentials $Credentials `
			-Filter "localsystem|NT Authority\LocalService|NT Authority\NetworkService|NT AUTHORITY\NETWORK SERVICE"

			StartName                         Name                             DisplayName
			---------                         ----                             -----------
			.\MICROSOFT$DPM$Acct              MSSQL$MS$DPM2007$                SQL Server (MS$DPM2007$)
			.\MICROSOFT$DPM$Acct              MSSQL$MSDPM2010                  SQL Server (MSDPM2010)
			.\MICROSOFT$DPM$Acct              SQLAgent$MS$DPM2007$             SQL Server Agent (MS$DPM2007$)
			.\MICROSOFT$DPM$Acct              SQLAgent$MSDPM2010               SQL Server Agent (MSDPM2010)
				
			Description
			-----------
			This example uses the Filter parameter to filter out NT AUTHORITY\NETWORK SERVICE account from the
			preceeding example. 
				
			The back-tick (`) was used for readability purposes only.
		.NOTES
			Powershell may need to be run elevated to run this script.
			UAC may need to be disabled to run this script.
		.LINK
			https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-NonStandardServiceAccounts
	#>
    [CmdletBinding()]		
	Param
		(
		[string]$Computer = (& hostname),
		$Credentials,
		[string]$Filter = "localsystem|NT Authority\LocalService|NT Authority\NetworkService"
		)
    Begin
    {	
	    $Filter = $Filter.Replace("\","\\")
        }
	Process
    {
	    If ($Computer -eq (& hostname))
        {
		    $Services = Get-WmiObject win32_service |Select-Object __Server, StartName, Name, DisplayName
		    }
	    Else
        {
		    $Result = Test-Connection -Count 1 -Computer $Computer -ErrorAction SilentlyContinue
				
		    If ($result -ne $null)
		    {
			    $Services = Get-WmiObject win32_service -ComputerName $Computer -Credential $Credentials `
						    |Select-Object __Server, StartName, Name, DisplayName
			    }
		    Else
            {
			    #	Should do something with unreachable computers here.
			    }
		    }

	    $Suspect = $Services |Where-Object {$_.StartName -notmatch $Filter}
        }
    End
    {
	    Return $Suspect
        }
	}
Function Remove-LocalUser
{
    <#
        .SYNOPSIS
            Delete a user account from the local computer.
        .DESCRIPTION
            This function will delete a user account from the local computer
        .PARAMETER ComputerName
            The NetBIOS name of the computer the account is found on
        .PARAMETER UserName
            The username to delete
        .EXAMPLE
            Remove-LocalUser -ComputerName Desktop -UserName TestAcct
                
            Description
            -----------
            Basic syntax of the command.
        .NOTES
            The user context the script is run under must be able to delete accounts on the remote computer
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Remove-LocalUser
    #>
    [CmdletBinding()]        
    Param
        (
        [Parameter(Mandatory=$true)]
        $ComputerName = (& hostname),
        [Parameter(Mandatory=$true)]
        $UserName
        )
    Begin
    {
        $isAlive = Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction SilentlyContinue
        }
    Process
    {
        if ($isAlive -ne $null)
        {
            $ADSI = [adsi]"WinNT://$ComputerName"
            $Users = $ADSI.psbase.children |Where-Object {$_.psBase.schemaClassName -eq "User"} |Select-Object -ExpandProperty Name
            foreach ($User in $Users)
            { 
                if ($User -eq $UserName)
                {
                    $ADSI.Delete("user", $UserName)
                    $Return = "Deleted"
                    }
                else
                {
                    $Return = "User not found"
                    }
                }
            }
        else
        {
            $Return = "$ComputerName not available"
            }
        }
    End
    {
        Return $Return
        }
    }
Function Get-LocalUserAccounts
{
    <#
        .SYNOPSIS
            Return a list of local user accounts.
        .DESCRIPTION
            This function returns the Name and SID of any local user accounts that are found
            on the remote computer.
        .PARAMETER ComputerName
            The NetBIOS name of the remote computer
        .EXAMPLE
            Get-LocalUserAccounts -ComputerName Desktop-PC01

            Name                                                      SID                                                                                  
            ----                                                      ---                                                                                  
            Administrator                                             S-1-5-21-1168524473-3979117187-4153115970-500
            Guest                                                     S-1-5-21-1168524473-3979117187-4153115970-501
                
            Description
            -----------
            This example shows the basic usage
        .EXAMPLE
            Get-LocalUserAccounts -ComputerName citadel -Credentials $Credentials

            Name                                                      SID
            ----                                                      ---
            Administrator                                             S-1-5-21-1168524473-3979117187-4153115970-500
            Guest                                                     S-1-5-21-1168524473-3979117187-4153115970-501
                
            Description
            -----------
            This example shows using the optional Credentials variable to pass administrator credentials
        .NOTES
            You will need to provide credentials when running this against computers in a diffrent domain.
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-LocalUserAccounts
    #>
    [CmdletBinding()]        
    Param
        (
        [string]$ComputerName = (& hostname),
        [System.Management.Automation.PSCredential]$Credentials
        )
    Begin
    {
        $Filter = "LocalAccount=True"
        $ScriptBlock = "Get-WmiObject Win32_UserAccount -Filter $Filter"
        $isAlive = Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction SilentlyContinue
        }
    Process
    {        
        if ($isAlive -ne $null)
        {
            $ScriptBlock += " -ComputerName $ComputerName"
            if ($Credentials)
            {
                if ($isAlive.__SERVER.ToString() -eq $ComputerName)
                {
                    }
                else
                {
                    $ScriptBlock += " -Credential `$Credentials"
                    }
                }
            }
        else
        {
            Return "Unable to connect to $ComputerName"
            }
        }
    End
    {
        Return Invoke-Expression $ScriptBlock |Select-Object Name, SID
        }
    }
Function Get-PendingUpdates
{
    <#
        .SYNOPSIS
            Retrieves the updates waiting to be installed from WSUS
        .DESCRIPTION
            Retrieves the updates waiting to be installed from WSUS
        .PARAMETER ComputerName
            Computer or computers to find updates for.
        .EXAMPLE
            Get-PendingUpdates 
            Description
            -----------
            Retrieves the updates that are available to install on the local system
        .NOTES
            Author: Boe Prox
            Date Created: 05Mar2011
            RPC Dynamic Ports need to be enabled on inbound remote servers.
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-PendingUpdates
    #> 
    [CmdletBinding()]
    Param
        (
        [Parameter(ValueFromPipeline = $True)]
        [string]$ComputerName
        )        
    Begin 
    {
        }
    Process 
    {
        ForEach ($Computer in $ComputerName) 
        {
            If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) 
            {
                Try 
                {
                    $Updates =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$Computer))
                    $Searcher = $Updates.CreateUpdateSearcher() 
                    $searchresult = $Searcher.Search("IsInstalled=0")     
                    }
                Catch 
                {
                    Write-Warning "$($Error[0])"
                    Break
                    }
                }
            }
        }
    End 
    {
        Return $SearchResult.Updates
        }
    }
Function Get-ServiceTag
{
    <#
        .SYNOPSIS
            Get the serial number (Dell ServiceTag) from Win32_BIOS
        .DESCRIPTION
            This function grabs the SerialNumber property from Win32_BIOS for the 
            provided ComputerName
        .PARAMETER ComputerName
            The NetBIOS name of the computer.
        .EXAMPLE
            Get-ServiceTag -ComputerName Desktop-01

            SerialNumber
            ------------
            1AB2CD3

            Description
            -----------
            An example showing the only parameter.
        .NOTES
            This space intentionally left blank.
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-ServiceTag
    #>
    [CmdletBinding()]    
    Param
        (
        $ComputerName
        )
    Begin
    {
        $ErrorActionPreference = "SilentlyContinue"
        }
    Process
    {
        Try
        {
            $null = Test-Connection -ComputerName $ComputerName -Count 1 -quiet
            $Return = New-Object PSObject -Property @{
                ComputerName = $ComputerName
                SerialNumber = (Get-WmiObject -Class Win32_BIOS -ComputerName $ComputerName -Credential $Credentials).SerialNumber 
                }
            }
        Catch
        {
            $Return = New-Object PSObject -Property @{
                ComputerName = $ComputerName
                SerialNumber = "Offline"
                }
            }
        }
    End
    {
        Return $Return
        }
    }
Function Backup-EventLogs
{
    <#
        .SYNOPSIS
            Backup Eventlogs from remote computer
        .DESCRIPTION
            This function copies event log files from a remote computer to a backup location.
        .PARAMETER ComputerName
            The NetBIOS name of the computer to connect to.
        .PARAMETER LogPath
            The path to the logs you wish to backup. The default logpath "C:\Windows\system32\winevt\Logs"
            is used if left blank.
        .PARAMETER BackupPath
            The location to copy the logs to.
        .EXAMPLE
            Backup-EventLogs -ComputerName dc1
        .NOTES
            May need to be a user with rights to access various logs, such as security on remote computer.
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Backup-EventLogs
    #>
    [CmdletBinding()]
    Param
        (
        [string]$ComputerName,
        [string]$LogPath = "C:\Windows\system32\winevt\Logs",
        [string]$BackupPath = "C:\Logs"
        )
    Begin
    {
        $EventLogs = "\\$($Computername)\$($LogPath.Replace(":","$"))"
        If ((Test-Path $BackupPath) -ne $True)
        {
            New-Item $BackupPath -Type Directory |Out-Null
            }
        }
    Process
    {
        Try
        {
            Copy-Item $EventLogs -Destination $BackupPath -Recurse
            }
        Catch
        {
            Return $Error
            }
        }
    End
    {
        Return $?
        }
    }
Function Export-EventLogs
{
    <#
        .SYNOPSIS
            Export Eventlogs from remote computer
        .DESCRIPTION
            This function backs up all logs on a Windows computer that have events written in them. This
            log is stored as a .csv file in the current directory, where the filename is the ComputerName+
            Logname+Date+Time the backup was created.
        .PARAMETER ComputerName
            The NetBIOS name of the computer to connect to.
        .EXAMPLE
            Export-EventLogs -ComputerName dc1
        .NOTES
            May need to be a user with rights to access various logs, such as security on remote computer.
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Export-EventLogs
    #>
    [CmdletBinding()]
    Param
        (
        [string]$ComputerName
        )
    Begin
    {
        $EventLogs = Get-WinEvent -ListLog * -ComputerName $ComputerName
        }
    Process
    {
        Foreach ($EventLog in $EventLogs)
        {
            If ($EventLog.RecordCount -gt 0)
            {
                $LogName = ($EventLog.LogName).Replace("/","-")
                $BackupFilename = "$($ComputerName)-$($LogName)-"+(Get-Date -format "yyy-MM-dd HH-MM-ss").ToString()+".csv"
                Get-WinEvent -LogName $EventLog.LogName -ComputerName $ComputerName |Export-Csv -Path ".\$($BackupFilename)"
                }
            }
        }
    End
    {
        Return $?
        }
    }
Function Get-SiSReport
{
    <#
        .SYNOPSIS
            Get the overall SIS usage information.
        .DESCRIPTION
            This function uses the sisadmin command to get the usage
            information for a SIS enabled drive.
        .PARAMETER SisDisk
            The drive letter of a disk that has SiS enabled
        .EXAMPLE
            Get-SiSReport -SisDisk o

            LinkFiles             : 20004
            Used                  : 442378481664
            Disk                  : o
            InaccessibleLinkFiles : 0
            CommonStoreFiles      : 6678
            SpaceSaved            : 7708860 KB
            Free                  : 0
            
            Description
            -----------
            This example shows the basic usage of the command

        .NOTES
            This function will return nothing if the drive being analyzed does not have SiS enabled
            This function will return a message if the sisadmin command returns any error
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-SiSReport
    #>
    [CmdletBinding()]
    Param
        (
        $SisDisk = "c:"
        )
    Begin
    {
        If ($SisDisk.Contains(":") -eq $False)
        {
            $SisDisk += ":"
            }
        $SisAdmin = "& sisadmin /v $($SisDisk)"
        Try
        {
            $SisResult = Invoke-Expression $SisAdmin
            }
        Catch
        {
            Return "Single Instance Storage is not available on this computer"
            }
        }
    Process
    {
        If ($SisResult.Count)
        {
            $ThisDisk = Get-PSDrive $SisDisk
            $SisReport = New-Object -TypeName PSObject -Property @{
                "Disk" = $SisDisk
                "Used (GB)" = [math]::round(($ThisDisk.Used /1024 /1024 /1024),2)
                "Free (GB)" = [math]::round(($ThisDisk.Free /1024 /1024 /1024),2)
                "Common Store Files" = ($SisResult[($SisResult.Count)-4]).TrimStart("Common store files:")
                "Link Files" = ($SisResult[($SisResult.Count)-3]).TrimStart("Link files:")
                "Inaccessible Link Files" = ($SisResult[($SisResult.Count)-2]).TrimStart("Inaccessible link files:")
                "Space Saved (GB)" = [math]::round(((($SisResult[($SisResult.Count)-1]).TrimStart("Space saved:")).TrimEnd(" KB")/1024 /1024),2)
                }
            }
        }
    End
    {
        Return $SisReport
        }
    }
Function Get-PaperCutLogs
{
    <#
        .SYNOPSIS
            Get PaperCut logs from all print servers
        .DESCRIPTION
            Return the PaperCut logs from all print servers.
        .PARAMETER PrintServers
            The FQDN of the print servers
        .EXAMPLE
            Get-PaperCutLogs |Export-Csv -Path .\PrintLog.csv
            
            Description
            -----------
            This example shows the basic usage of the command. The output is piped into
            a spreadsheet on the local computer for further analysis.
        .NOTES
            You must have downlaoded and installed the latest version of PaperCut Print Logger
            for this to work.
            
            http://www.papercut.com/products/free_software/print_logger/#
            
            The resulting data will encompass all months that the servers have been logging data  
            for, currently this goes back about 3 years. The CSV output can be opened in Excel  
            and you can generate graphs based on which printer is used the most, how much paper  
            is consumed by each printer and so on.  
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-PaperCutLogs
    #>
    [CmdletBinding()]
    Param
        (
        $PrintServers = @("ps1.company.com","ps2.company.com")
        )    
    Begin
    {
        # Location of the monthly PaperCut logs
        $PcutLogLocation = "c$\Program Files (x86)\PaperCut Print Logger\logs\csv\monthly"
        # Column headings in the CSV
        $PcutHeader = "Time","User","Pages","Copies","Printer","Document Name","Client","Paper Size","Language","Height","Width","Duplex","Grayscale","Size"
        # Need it set to stop in order for the try/catch to work
        $ErrorActionPreference = "Stop"
        # Define an empty array to hold all the log entries
        $PcutReport = @()
        }
    Process
    {
        foreach ($PrintServer in $PrintServers)
        {
            # Get each log file from the server
            Try
            {
                $PcutLogs = Get-ChildItem "\\$($PrintServer)\$($PcutLogLocation)"
                }
            Catch
            {
                # This runs only if we're trying to pull logs from an x86 print server
                $PcutLogs = Get-ChildItem "\\$($PrintServer)\c$\Program Files\PaperCut Print Logger\logs\csv\monthly"
                }
                
            Foreach ($PcutLog in $PcutLogs)
            {
                # Import the csv into a variable, skip 1 skips the first line of the PaperCut CSV
                # which has information not related to the log itself
                $ThisReport = Import-Csv $PcutLog.FullName -Header $PcutHeader |Select-Object -Skip 1
                
                # Add this log to the array
                $PcutReport += $ThisReport |Where-Object {$_.Time -ne "Time"}
                }
            }
        }
    End
    {
        # Display the result, this can be piped into Export-CSV to generate a large 
        # spreadsheet suitable for analysis
        Return $PcutReport
        }
    }
Function Set-ShutdownMethod
{
    <#
        .SYNOPSIS
            Execute the Win32Shutdown method on a remote computer
        .DESCRIPTION
            This function executes the Win32Shutdown method on a remote computer. This
            can be either an IP, NetBIOS name or FQDN. Use the ShutdownMethod param to
            specify the type of shutdown.
        .PARAMETER ComputerName
            The IP, NetBIOS or FQDN of the remote computer.
        .PARAMETER ShutdownMethod
            Win32Shutdown accepts one of the following in32's
                0 = Logoff (Default)
                1 = Shutdown 
                2 = Reboot
                4 = Force Logoff (Doesn't work)
                8 = PowerOff
            
            For more information see the following MSDN article
            http://msdn.microsoft.com/en-us/library/aa376868(VS.85).aspx
        .EXAMPLE
            Set-ShutdownMethod -ComputerName Desktop-pc01
            
            Description
            -----------
            This is the default syntax for this command
        .EXAMPLE
            Set-ShutdownMethod -ComputerName Desktop-pc01 -ShutdownMethod 0
            
            Description
            -----------
            This is the only syntax for this command
        .EXAMPLE
            Get-WmiObject -Class Win32_ServerSession -ComputerName $ComputerName | Set-ShutdownMethod
            
            Description
            -----------
            An example showing how to pipe information into the function.
        .NOTES
            You will need proper credentials on the remote machine for this to work.
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Set-ShutdownMethod
    #>
    [CmdletBinding()]
    PARAM
        (
        [parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string]$ComputerName,
        $Credentials = (Get-Credential),
        [int32]$ShutdownMethod = 0
        )
    Begin
    {
        }
    Process
    {
        Try
        {
            $ReturnValue = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName -Credential $Credentials).InvokeMethod("Win32Shutdown",0)
            }
        Catch
        {
            $ReturnValue = $Error[0]
            }
        }
    End
    {
        if ($ReturnValue -ne 0)
        {
            Return "An error occurred, most likely there is nobody logged into $($ComputerName)"
            }
        else
        {
            Return "Success"
            }
        }
    }
Function Get-PrinterLogs
{
    <#
        .SYNOPSIS
            Get a log of all printing from a given server.
        .DESCRIPTION
            This function will return a log of all the printing that has occurred on
            a given print server.
        .PARAMETER LogName
            The default log for printing on Windows Server 2008 R2 is specified.
        .PARAMETER ComputerName
            The name of your print server.
        .EXAMPLE
            Get-PrinterLogs -ComputerName ps

            Size     : 96060
            Time     : 8/16/2011 5:01:09 PM
            User     : MyAccount
            Job      : 62
            Client   : \\10.133.5.143
            Port     : Desktop-PC01.company.com
            Printer  : HP-Laser
            Pages    : 1
            Document : Microsoft Office Outlook - Memo Style

            Description
            -----------
            This example shows the basic usage of the command.
        .EXAMPLE
            Get-PrinterLogs -ComputerName ps |Export-Csv -Path .\PrintLogs.csv
            
            Description
            -----------
            This is the syntax that I would see being used the most.
        .NOTES
            The following log will need to be enabled before logs can be generated by the server:
            "Microsoft-Windows-PrintService/Operational"
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-PrinterLogs
    #>
    [CmdletBinding()]
    Param
        (
        $LogName = "Microsoft-Windows-PrintService/Operational",
        [Parameter(Mandatory=$true)]
        $ComputerName
        )    
    Begin
    {
        $ErrorActionPreference = "Stop"
        $PrintJobs = Get-WinEvent -ComputerName $ComputerName -LogName $LogName -Credential $Credentials |Where-Object {$_.Id -eq 307}
        $PrintLogs = @()
        }
    Process
    {
        foreach ($PrintJob in $PrintJobs)
        {
            $Client = $PrintJob.Properties[3].Value
            if($Client.IndexOf("\\") -gt -1)
            {
                $Lookup = "nslookup $($Client.Substring(2,($Client.Length)-2)) |Select-String 'Name:'"
                }
            else
            {
                $Lookup = "nslookup $($Client) |Select-String 'Name:'"
                }
            
            Try
            {
                [string]$Return = Invoke-Expression $Lookup |Out-Null
                $Client = $Return.Substring($Return.IndexOf(" "),(($Return.Length) - $Return.IndexOf(" "))).Trim()
                }
            Catch
            {
                $Client = $PrintJob.Properties[3].Value
                }
            $PrintLog = New-Object -TypeName PSObject -Property @{
                Time = $PrintJob.TimeCreated
                Job = $PrintJob.Properties[0].Value
                Document = $PrintJob.Properties[1].Value
                User = $PrintJob.Properties[2].Value
                Client = $Client
                Printer = $PrintJob.Properties[4].Value
                Port = $PrintJob.Properties[5].Value
                Size = $PrintJob.Properties[6].Value
                Pages = $PrintJob.Properties[7].Value
                }
            $PrintLogs += $PrintLog
            }
        }
    End
    {
        Return $PrintLogs
        }
    }
Function Get-OpenSessions
{
    <#
        .SYNOPSIS
            Return a list of open sessions
        .DESCRIPTION
            This function returns a list of open session on a given server. The output is 
            similar to that of the Manage Open Sessions dialog in the Share and Storage
            Management console.
        .PARAMETER ComputerName
            This is the FQDN or NetBIOS name of the computer
        .EXAMPLE
            Get-OpenSessions -ComputerName fs

            User          Computer         ConnectTime     IdleTime
            ----          --------         -----------     --------
            user1         10.10.1.62              1615            1
            user2         10.10.1.156             7529           17

            Description
            -----------
            This example shows the basic usage of the command.
        .NOTES
            FunctionName : Get-OpenSessions
            Created by   : Jeff Patton
            Date Coded   : 09/26/2011 11:35:40
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-OpenSessions
    #>
    [CmdletBinding()]
    Param
        (
        $ComputerName = (hostname)
        )
    Begin
    {
        $ServerSessions = @()
        $Server = [adsi]"WinNT://$($ComputerName)/LanmanServer"
        $Sessions = $Server.PSBase.Invoke("Sessions")
        }
    Process
    {
        foreach ($Session in $Sessions)
        {
            Try
            {
                $UserSession = New-Object -TypeName PSobject -Property @{
                    User = $Session.GetType().InvokeMember("User","GetProperty",$null,$Session,$null)
                    Computer = $Session.GetType().InvokeMember("Computer","GetProperty",$null,$Session,$null)
                    ConnectTime = $Session.GetType().InvokeMember("ConnectTime","GetProperty",$null,$Session,$null)
                    IdelTime = $Session.GetType().InvokeMember("IdleTime","GetProperty",$null,$Session,$null)
                    }
                }
            Catch
            {
                }
            $ServerSessions += $UserSession
            }
        }
    End
    {
        Return $ServerSessions
        }
    }
Function Get-OpenFiles
{
    <#
        .SYNOPSIS
            Get a list of files open on the server
        .DESCRIPTION
            This function returns a list of files open on a given server. The output is
            similar to that of the Manage Open Files from the Share and Storage Management
            console.
        .PARAMETER ComputerName
            The NetBIOS or FQDN of the computer
        .EXAMPLE
            Get-OpenFiles -ComputerName fs

            User          Path                              LockCount
            ----          ----                              ---------
            User1         F:\Users\User1\Documents\Data\...         0
            User2         P:\Public                                 0

            Description
            -----------
            This example shows the basic usage of this command.
        .NOTES
            FunctionName : Get-OpenFiles
            Created by   : Jeff Patton
            Date Coded   : 09/26/2011 13:01:38
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-OpenFiles
    #>
    [CmdletBinding()]
    Param
        (
        $ComputerName = (hostname)
        )
    Begin
    {
        $OpenFiles = @()
        $Server = [adsi]"WinNT://$($ComputerName)/LanmanServer"
        $Resources = $Server.PSBase.Invoke("Resources")
        }
    Process
    {
        foreach ($Resource in $Resources)
        {
            Try
            {
                $UserResource = New-Object -TypeName PSobject -Property @{
                    User = $Resource.GetType().InvokeMember("User","GetProperty",$null,$Resource,$null)
                    Path = $Resource.GetType().InvokeMember("Path","GetProperty",$null,$Resource,$null)
                    LockCount = $Resource.GetType().InvokeMember("LockCount","GetProperty",$null,$Resource,$null)
                    }
                }
            Catch
            {
                }
            $OpenFiles += $UserResource
            }
        }
    End
    {
        Return $OpenFiles
        }
    }
Function Get-RDPLoginEvents
{
    <#
        .SYNOPSIS
            Return Remote Desktop login attempts
        .DESCRIPTION
            This function returns login attempts from the Microsoft Windows TerminalServices RemoteConnectionManager 
            log. The specific events are logged as EventID 1149, and they are logged whether or not the user actually
            gets to the desktop.
        .PARAMETER ComputerName
            This is the NetBIOS name of the computer to pull events from.
        .PARAMETER Credentials
            A user account with the ability to retreive these events.
        .EXAMPLE
            Get-RDPLoginEvents -Credentials $Credentials |Export-Csv -Path C:\logfiles\RDP-Attempts.csv
            
            Description
            -----------
            This example show piping the output of the function to Export-Csv to create a file suitable for import
            into Excel, or some other spreadsheet software.
        .EXAMPLE
            Get-RDPLoginEvents -Credentials $Credentials -ComputerName MyPC |Format-Table

            SourceNetworkAddress        Domain           TimeCreated                User
            --------------------        ------           -----------                ----
            192.168.1.1                 MyPC...          4/30/2011 8:20:02 AM       Administrator...
            192.168.1.1                 MyPC...          4/28/2011 4:53:01 PM       Administrator...
            192.168.1.1                 MyPC...          4/21/2011 2:01:42 PM       Administrator...
            192.168.1.1                 MyPC...          4/19/2011 11:42:59 AM      Administrator...
            192.168.1.1                 MyPC...          4/19/2011 10:30:52 AM      Administrator...

            Description
            -----------
            This example shows piping the output to Format-Table
        .NOTES
            The Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational needs to be enabled
            The user account supplied in $Credentials needs to have permission to view this log
            No output is returned if the log is empty.
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-RDPLoginEvents
    #>
    [cmdletbinding()]    
    Param
        (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        $ComputerName,
        $Credentials,
        $EventID = 1149,
        $LogName = 'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational'
        )
    Begin
    {
        $LoginAttempts = @()
        }
    Process
    {
        Foreach ($Computer in $ComputerName)
        {
            Write-Verbose "Checking $($Computer)"
            try
            {
                if (Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue)
                {
                    $Events = Get-WinEvent -LogName $LogName -ComputerName $ComputerName -Credential $Credentials  -ErrorAction SilentlyContinue `
                        |Where-Object {$_.ID -eq $EventID}
                    if ($Events.Count -ne $null)
                    {
                        foreach ($Event in $Events)
                        {
                            $LoginAttempt = New-Object -TypeName PSObject -Property @{
                                ComputerName = $Computer
                                User = $Event.Properties[0].Value
                                Domain = $Event.Properties[1].Value
                                SourceNetworkAddress = [net.ipaddress]$Event.Properties[2].Value
                                TimeCreated = $Event.TimeCreated
                                }
                            $LoginAttempts += $LoginAttempt
                            }
                        }
                    }
                }
            catch
            {
                }
            }
        }
    End
    {
        Return $LoginAttempts
        }
    }
Function Get-InvalidLogonAttempts
{
    <#
        .SYNOPSIS
            Return a list of invalid logon attempts.
        .DESCRIPTION
            This function queries the security log of a given computer and 
            retrieves Event ID 4625, failed logon attempt.
        .PARAMETER ComputerName
            The name of the computer to pull logs from 
        .PARAMETER LogName
            The name of the Event Log.
        
            You will notice that I have set the LogName to Security, since
            this particular script was designed to find a specific entry.
            This can be modified to suit your needs.
        .PARAMETER EventID
            The Event ID to return.
        
            You will notice that I have set the EventID to 4625, since
            this particular script was designed to find those particular
            entries. This can be modified to suit your needs.
        .EXAMPLE
            Get-InvalidLogonAttempts -ComputerName Desktop-pc1 -LogName 'Security' -EventID 4625
        
            Message        MachineName    TimeCreated   IpAddress         LogonType TargetUserNam IpPort
                                                                                    e
            -------        -----------    -----------   ---------         --------- ------------- ------
            An account ... Desktop-pc1... 10/26/2011... ##.###.###...            10 Daniel        62581
            An account ... Desktop-pc1... 10/26/2011... ##.###.###...            10 Daniel        11369
            An account ... Desktop-pc1... 10/26/2011... ##.###.###...            10 Daniel        47575
            An account ... Desktop-pc1... 10/26/2011... ##.###.###...            10 Daniel        51144

            Description
            -----------
            This is the basic syntax of the command, the output is returned to stdin.
        .EXAMPLE
            Get-InvalidLogonAttempts |Export-Csv -Path .\InvalidLoginAttempts.csv
        
            Description
            -----------
            This example shows redirecting the output through the Export-CSV command to get
            a csv file.
        .NOTES
            ScriptName : Get-InvalidLogonAttempts
            Created By : jspatton
            Date Coded : 10/26/2011 11:20:58
            ScriptName is used to register events for this script
            LogName is used to determine which classic log to write to
 
            ErrorCodes
                100 = Success
                101 = Error
                102 = Warning
                104 = Information
        
            If you adjust theh script to look for event id's other than 4625, you will
            want to examine the Event Properties. This is similar to viewing the 
            "Friendly" view of an event in the event log. Below are all the properties
            for Event ID 4625.
    
            00  SubjectUserSid S-1-5-18 
            01  SubjectUserName NODE1$ 
            02  SubjectDomainName SOECS 
            03  SubjectLogonId 0x3e7 
            04  TargetUserSid S-1-0-0 
            05  TargetUserName Daniel 
            06  TargetDomainName NODE1 
            07  Status 0xc000006d 
            08  FailureReason %%2313 
            09  SubStatus 0xc0000064 
            10  LogonType 10 
            11  LogonProcessName User32  
            12  AuthenticationPackageName Negotiate 
            13  WorkstationName NODE1 
            14  TransmittedServices - 
            15  LmPackageName - 
            16  KeyLength 0 
            17  ProcessId 0x3278 
            18  ProcessName C:\Windows\System32\winlogon.exe 
            19  IpAddress ##.###.###.### 
            20  IpPort 51144 
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-InvalidLogonAttempts
    #>
    [cmdletBinding()]
    Param
        (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        $ComputerName,
        $LogName = "Security",
        $EventID = 4625
        )
    Begin
    {        
        $Report = @()
        Write-Verbose "Get all $($EventID) events from the $($LogName) Log on $($ComputerName)"
        $Events = Get-WinEvent -ComputerName $ComputerName -LogName $LogName -Credential $Credentials |Where-Object {$_.Id -eq $EventID}
        Write-Verbose "Filter the list of events to only events that happened today"
        $Events = $Events |Where-Object {(Get-Date($_.TimeCreated) -Format "yyy-MM-dd") -eq (Get-Date -Format "yyy-MM-dd")}
        }
    Process
    {
        Write-Verbose "Loop through each event that is returned from Get-WinEvent"
        foreach ($Event in $EventID4625)
        {
            Write-Verbose "Create an object to hold the data I'm collecting"
            $ThisEvent = New-Object -TypeName PSObject -Property @{
                TimeCreated = $Event.TimeCreated
                MachineName = $Event.MachineName
                TargetUserName = $Event.Properties[5].Value
                LogonType = $Event.Properties[10].Value
                IpAddress = [net.ipaddress]$Event.Properties[19].Value
                IpPort = $Event.Properties[20].Value
                Message = $Event.Message
                }
            $Report += $ThisEvent
            }
        }
    End
    {
        Return $Report
        }
    }
Function Get-UpTime
{
    <#
        .SYNOPSIS
            Get uptime of one or more computers
        .DESCRIPTION
            This script uses Win32_ComputerSystem to determine how long your system has been running.
        .PARAMETER ComputerName
            One or more computer names
        .EXAMPLE
            Get-UpTime -ComputerName ".", "server01" |Sort-Object -Property Days -Descending

            ComputerName Days Hours Minutes
            ------------ ---- ----- -------
            server01       39    18      25
            Desktop01       0     1      38

            Description
            -----------
            This example shows using the function with an array of computer names, and sorting the output
            descending order by days.
        .EXAMPLE
            $Servers | foreach {Get-UpTime $_.Properties.name} |Sort-Object -Property Days -Descending

            ComputerName    Days Hours Minutes
            ------------    ---- ----- -------
            server01         144    22      58
            server02         144    22      16
            server03         144    23       9
            server04         139    22      42

            Description
            -----------
            This example shows passing in computer computer names from an object.
        .NOTES
            FunctionName : Get-UpTime
            Created by   : jspatton
            Date Coded   : 10/19/2011 11:22:34
        .LINK
            https://code.google.com/p/mod-posh/wiki/ComputerManagement#Get-UpTime
        .LINK
            http://msdn.microsoft.com/en-us/library/aa394591(VS.85).aspx  
    #>
    [CmdletBinding()]
    Param
        (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $ComputerName = "."
        )
    Begin
    {       
        $Report = @()
        }
    Process
    {
        foreach ($Computer in $ComputerName) 
        {
            if ($Computer -eq ".")
            {
                Write-Verbose "Change the dot to a hostname"
                $Computer = (& hostname)
                }
            Write-Verbose "Make sure that $($Computer) is online with a single ping."
            Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue |Out-Null
            
            if ($?)
            {
                Write-Verbose "Try to connect to $($Computer) fail silently."
                try
                {
                    Write-Verbose "Convert the WMI value for LastBootUpTime into a date, and subtract it from now to get uptime"
                    $Uptime = (Get-Date) - ([System.Management.ManagementDateTimeconverter]::ToDateTime((Get-WMIObject -class Win32_OperatingSystem -ComputerName $Computer).LastBootUpTime))
                    $ComputerUpTime = New-Object -TypeName PSObject -Property @{
                        ComputerName = $Computer
                        Days = $Uptime.Days
                        Hours = $Uptime.Hours
                        Minutes = $uptime.Minutes
                        }
                    $Report += $ComputerUpTime
                    }
                catch
                {
                    Write-Verbose $Error[0].Exception
                    }
                }
            else
            {
                Write-Verbose "Unable to connect to $($Computer)"
                }
            }
        }
    End
    {
        Return $Report
        }
    }