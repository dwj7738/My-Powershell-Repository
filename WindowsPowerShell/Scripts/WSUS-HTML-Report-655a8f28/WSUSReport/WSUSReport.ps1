<#
    WSUS Report
    
    ** Requires WSUS Administrator Console Installed or UpdateServices Module available **        
    
    TO DO:
        - SUSDB Size
        - Computers in Active Directory but not in WSUS (OPTIONAL)
#>

#region User Specified WSUS Information
$WSUSServer = 'DC1'

#Accepted values are "80","443","8530" and "8531"
$Port = 80 
$UseSSL = $False

#Specify when a computer is considered stale
$DaysComputerStale = 30 

#Send email of report
[bool]$SendEmail = $FALSE
#Display HTML file
[bool]$ShowFile = $TRUE
#endregion User Specified WSUS Information

#region User Specified Email Information
$EmailParams = @{
    To = 'user@domain.local'
    From = 'WSUSReport@domain.local'    
    Subject = "$WSUSServer WSUS Report"
    SMTPServer = 'exchange.domain.local'
    BodyAsHtml = $True
}
#endregion User Specified Email Information

#region Helper Functions
Function Set-AlternatingCSSClass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string]$HTMLFragment,
        [Parameter(Mandatory=$True)]
        [string]$CSSEvenClass,
        [Parameter(Mandatory=$True)]
        [string]$CssOddClass
    )
    [xml]$xml = $HTMLFragment
    $table = $xml.SelectSingleNode('table')
    $classname = $CSSOddClass
    foreach ($tr in $table.tr) {
        if ($classname -eq $CSSEvenClass) {
            $classname = $CssOddClass
        } else {
            $classname = $CSSEvenClass
        }
        $class = $xml.CreateAttribute('class')
        $class.value = $classname
        $tr.attributes.append($class) | Out-null
    }
    $xml.innerxml | out-string
}
Function Convert-Size {
    <#
        .SYSNOPSIS
            Converts a size in bytes to its upper most value.
        
        .DESCRIPTION
            Converts a size in bytes to its upper most value.
        
        .PARAMETER Size
            The size in bytes to convert
        
        .NOTES
            Author: Boe Prox
            Date Created: 22AUG2012
        
        .EXAMPLE
        Convert-Size -Size 568956
        555 KB
        
        Description
        -----------
        Converts the byte value 568956 to upper most value of 555 KB
        
        .EXAMPLE
        Get-ChildItem  | ? {! $_.PSIsContainer} | Select -First 5 | Select Name, @{L='Size';E={$_ | Convert-Size}}
        Name                                                           Size                                                          
        ----                                                           ----                                                          
        Data1.cap                                                      14.4 MB                                                       
        Data2.cap                                                      12.5 MB                                                       
        Image.iso                                                      5.72 GB                                                       
        Index.txt                                                      23.9 KB                                                       
        SomeSite.lnk                                                   1.52 KB     
        SomeFile.ini                                                   152 bytes   
        
        Description
        -----------
        Used with Get-ChildItem and custom formatting with Select-Object to list the uppermost size.          
    #>
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias("Length")]
        [int64]$Size
    )
    Begin {
        If (-Not $ConvertSize) {
            Write-Verbose ("Creating signature from Win32API")
            $Signature =  @"
                 [DllImport("Shlwapi.dll", CharSet = CharSet.Auto)]
                 public static extern long StrFormatByteSize( long fileSize, System.Text.StringBuilder buffer, int bufferSize );
"@
            $Global:ConvertSize = Add-Type -Name SizeConverter -MemberDefinition $Signature -PassThru
        }
        Write-Verbose ("Building buffer for string")
        $stringBuilder = New-Object Text.StringBuilder 1024
    }
    Process {
        Write-Verbose ("Converting {0} to upper most size" -f $Size)
        $ConvertSize::StrFormatByteSize( $Size, $stringBuilder, $stringBuilder.Capacity ) | Out-Null
        $stringBuilder.ToString()
    }
}
#endregion Helper Functions

#region Load WSUS Required Assembly
If (-Not (Get-Module -ListAvailable -Name UpdateServices)) {
    #Add-Type "$Env:ProgramFiles\Update Services\Api\Microsoft.UpdateServices.Administration.dll"
    $Null = [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
} Else {
    Import-Module -Name UpdateServices
}
#endregion Load WSUS Required Assembly

#region CSS Layout
$head=@"
    <style> 
        h1 {
            text-align:center;
            border-bottom:1px solid #666666;
            color:#009933;
        }
		TABLE {
			TABLE-LAYOUT: fixed; 
			FONT-SIZE: 100%; 
			WIDTH: 100%
		}
		* {
			margin:0
		}

		.pageholder {
			margin: 0px auto;
		}
					
		td {
			VERTICAL-ALIGN: TOP; 
			FONT-FAMILY: Tahoma
		}
					
		th {
			VERTICAL-ALIGN: TOP; 
			COLOR: #018AC0; 
			TEXT-ALIGN: left;
            background-color:DarkGrey;
            color:Black;
		}
        body {
            text-align:left;
            font-smoothing:always;
            width:100%;
        }
        .odd { background-color:#ffffff; }
        .even { background-color:#dddddd; }               
    </style>
"@
#endregion CSS Layout

#region Initial WSUS Connection
$ErrorActionPreference = 'Stop'
Try {
    $Wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WSUSServer,$UseSSL,$Port)
} Catch {
    Write-warning "$($WSUSServer)<$($Port)>: $($_)"
    Break
}
$ErrorActionPreference = 'Continue'
#endregion Initial WSUS Connection

#region Pre-Stage -- Used in more than one location
$htmlFragment = ''
$WSUSConfig = $Wsus.GetConfiguration()
$WSUSStats = $Wsus.GetStatus()
$TargetGroups = $Wsus.GetComputerTargetGroups()
$EmptyTargetGroups = $TargetGroups | Where {
    $_.GetComputerTargets().Count -eq 0 -AND $_.Name -ne 'Unassigned Computers'
}

#Stale Computers
$computerscope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$computerscope.ToLastReportedStatusTime = (Get-Date).AddDays(-$DaysComputerStale)
$StaleComputers = $wsus.GetComputerTargets($computerscope) | ForEach {
    [pscustomobject]@{
        Computername = $_.FullDomainName
        ID=  $_.Id
        IPAddress = $_.IPAddress
        LastReported = $_.LastReportedStatusTime
        LastSync = $_.LastSyncTime
        TargetGroups = ($_.GetComputerTargetGroups() | Select -Expand Name) -join ', '
    }
}

#Pending Reboots
$updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$updateScope.IncludedInstallationStates = 'InstalledPendingReboot'
$computerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$computerScope.IncludedInstallationStates = 'InstalledPendingReboot'
$GroupRebootHash=@{}
$ComputerPendingReboot = $wsus.GetComputerTargets($computerScope) | ForEach {
    $Update = ($_.GetUpdateInstallationInfoPerUpdate($updateScope) | ForEach {
        $Update = $_.GetUpdate()
        $Update.title
    }) -join ', '
    If ($Update) {
        $TempTargetGroups = ($_.GetComputerTargetGroups() | Select -Expand Name)
        $TempTargetGroups | ForEach {
            $GroupRebootHash[$_]++
        }
        [pscustomobject] @{
            Computername = $_.FullDomainName
            ID = $_.Id
            IPAddress = $_.IPAddress
            TargetGroups = $TempTargetGroups -join ', '
            #Updates = $Update
        }
    }
} | Sort Computername

#Failed Installations
$updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$updateScope.IncludedInstallationStates = 'Failed'
$computerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$computerScope.IncludedInstallationStates = 'Failed'
$GroupFailHash=@{}
$ComputerHash = @{}
$UpdateHash = @{}
$ComputerFailInstall = $wsus.GetComputerTargets($computerScope) | ForEach {
    $Computername = $_.FullDomainName
    $Update = ($_.GetUpdateInstallationInfoPerUpdate($updateScope) | ForEach {
        $Update = $_.GetUpdate()
        $Update.title
        $ComputerHash[$Computername] += ,$Update.title
        $UpdateHash[$Update.title] += ,$Computername
    }) -join ', '
    If ($Update) {
        $TempTargetGroups = ($_.GetComputerTargetGroups() | Select -Expand Name)
        $TempTargetGroups | ForEach {
            $GroupFailHash[$_]++
        }
        [pscustomobject] @{
            Computername = $_.FullDomainName
            ID = $_.Id
            IPAddress = $_.IPAddress
            TargetGroups = $TempTargetGroups -join ', '
            Updates = $Update
        }
    }
} | Sort Computername
#endregion Pre-Stage -- Used in more than one location

#region WSUS SERVER INFORMATION
$Pre = @"
<div style='margin: 0px auto; BACKGROUND-COLOR:Blue;Color:White;font-weight:bold;FONT-SIZE: 16pt;'>
    WSUS Server Information
</div>
"@
    #region WSUS Version
                    $WSUSVersion = [pscustomobject]@{
    Computername = $WSUS.ServerName
    Version = $Wsus.Version
    Port = $Wsus.PortNumber
    ServerProtocolVersion = $Wsus.ServerProtocolVersion
    }
    $Pre += @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            WSUS Information
        </div>

"@
    $Body = $WSUSVersion | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion WSUS Version

    #region WSUS Server Content
    $drive = $WSUSConfig.LocalContentCachePath.Substring(0,2)
    $Data = Get-CIMInstance -ComputerName $WSUSServer -ClassName Win32_LogicalDisk -Filter "DeviceID='$drive'"
    $UsedSpace = $data.Size - $data.Freespace
    $PercentFree = "{0:P}" -f ($Data.Freespace / $Data.Size)
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            WSUS Server Content Drive
        </div>

"@
    $WSUSDrive = [pscustomobject]@{
        LocalContentPath = $WSUSConfig.LocalContentCachePath
        TotalSpace = $data.Size | Convert-Size
        UsedSpace = $UsedSpace | Convert-Size
        FreeSpace = $Data.freespace | Convert-Size
        PercentFree = $PercentFree
    }
    $Body = $WSUSDrive | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion WSUS Server Content

    #region Last Synchronization
    $synch = $wsus.GetSubscription()
    $SynchHistory = $Synch.GetSynchronizationHistory()[0]
    $WSUSSynch = [pscustomobject]@{
        IsAuto = $synch.SynchronizeAutomatically
        SynchTime = $synch.SynchronizeAutomaticallyTimeOfDay
        LastSynch = $synch.LastSynchronizationTime
        Result = $SynchHistory.Result
    }
    If ($SynchHistory.Result -eq 'Failed') {
        $WSUSSynch = $WSUSSynch | Add-Member -MemberType NoteProperty -Name ErrorType -Value $SynchHistory.Error -PassThru |
        Add-Member -MemberType NoteProperty -Name ErrorText -Value $SynchHistory.ErrorText -PassThru
    }
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Last Server Synchronization
        </div>

"@
    $Body = $WSUSSynch | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Last Synchronization

    #region Upstream Server Config
    $WSUSUpdateConfig = [pscustomobject]@{
        SyncFromMU = $WSUSConfig.SyncFromMicrosoftUpdate
        UpstreamServer = $WSUSConfig.UpstreamWsusServerName
        UpstreamServerPort = $WSUSConfig.UpstreamWsusServerPortNumber
        SSLConnection = $WSUSConfig.UpstreamWsusServerUseSsl
    }
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Upstream Server Information
        </div>

"@
    $Body = $WSUSUpdateConfig | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Upstream Server Config

    #region Automatic Approvals
    $Rules = $wsus.GetInstallApprovalRules()
    $ApprovalRules = $Rules | ForEach {
        [pscustomobject]@{
            Name=  $_.Name
            ID = $_.ID
            Enabled = $_.Enabled
            Action = $_.Action
            Categories = ($_.GetCategories() | Select -ExpandProperty Title) -join ', '
            Classifications = ($_.GetUpdateClassifications() | Select -ExpandProperty Title) -join ', '
            TargetGroups = ($_.GetComputerTargetGroups() | Select -ExpandProperty Name) -join ', '
        }
    }
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Automatic Approvals
        </div>

"@
    $Body = $ApprovalRules | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Automatic Approvals

    #region WSUS Child Servers
    $ChildUpdateServers = $wsus.GetChildServers()
    If ($ChildUpdateServers) {
        $ChildServers =  $ChildUpdateServers | ForEach {
            [pscustomobject]@{
                ChildServer = $_.FullDomainName
                Version = $_.Version
                UpstreamServer = $_.UpdateServer.Name
                LastSyncTime = $_.LastSyncTime
                SyncsFromDownStreamServer = $_.SyncsFromDownStreamServer
                LastRollUpTime = $_.LastRollupTime
                IsReplica = $_.IsReplica
            }
        }
    }
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Child Servers
        </div>

"@
    $Body = $ChildServers | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion WSUS Child Servers

    #region Database Information
    $WSUSDB = $WSUS.GetDatabaseConfiguration()
    $DBInfo = [pscustomobject]@{
        DatabaseName = $WSUSDB.databasename
        Server = $WSUSDB.ServerName
        IsDatabaseInternal = $WSUSDB.IsUsingWindowsInternalDatabase
        Authentication = $WSUSDB.authenticationmode
    }
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            WSUS Database
        </div>

"@
    $Body = $DBInfo | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Database Information

#endregion WSUS SERVER INFORMATION

#region CLIENT INFORMATION
$Pre = @"
<div style='margin: 0px auto; BACKGROUND-COLOR:Blue;Color:White;font-weight:bold;FONT-SIZE: 16pt;'>
    WSUS Client Information
</div>
"@
    #region Computer Statistics
    $WSUSComputerStats = [pscustomobject]@{
        TotalComputers = [int]$WSUSStats.ComputerTargetCount    
        "Stale($DaysComputerStale Days)" = ($StaleComputers | Measure-Object).count
        NeedingUpdates = [int]$WSUSStats.ComputerTargetsNeedingUpdatesCount
        FailedInstall = [int]$WSUSStats.ComputerTargetsWithUpdateErrorsCount
        PendingReboot = ($ComputerPendingReboot | Measure-Object).Count
    }

    $Pre += @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Computer Statistics
        </div>

"@
    $Body = $WSUSComputerStats | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Computer Statistics

    #region Operating System
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            By Operating System
        </div>

"@
    $Body = $wsus.GetComputerTargets() | Group OSDescription |
    Select @{L='OperatingSystem';E={$_.Name}}, Count  | 
    ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'Odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post    
    #endregion Operating System

    #region Stale Computers
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Stale Computers ($DaysComputerStale Days)
        </div>

"@
    $Body = $StaleComputers | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Stale Computers

    #region Unassigned Computers
    $Unassigned = ($TargetGroups | Where {
        $_.Name -eq 'Unassigned Computers'
    }).GetComputerTargets() | ForEach {
        [pscustomobject]@{
            Computername = $_.FullDomainName
            OperatingSystem = $_.OSDescription
            ID=  $_.Id
            IPAddress = $_.IPAddress
            LastReported = $_.LastReportedStatusTime
            LastSync = $_.LastSyncTime
        }    
    }
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Unassigned Computers (in Unassigned Target Group)
        </div>

"@
    $Body = $Unassigned | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Unassigned Computers

    #region Failed Update Install
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Failed Update Installations By Computer
        </div>

"@
    $Body = $ComputerFailInstall | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Failed Update Install

    #region Pending Reboot 
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Computers with Pending Reboot
        </div>

"@
    $Body = $ComputerPendingReboot | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Pending Reboot

#endregion CLIENT INFORMATION

#region UPDATE INFORMATION
$Pre = @"
<div style='margin: 0px auto; BACKGROUND-COLOR:Blue;Color:White;font-weight:bold;FONT-SIZE: 16pt;'>
    WSUS Update Information
</div>
"@
    #region Update Statistics
    $WSUSUpdateStats = [pscustomobject]@{
        TotalUpdates = [int]$WSUSStats.UpdateCount    
        Needed = [int]$WSUSStats.UpdatesNeededByComputersCount
        Approved = [int]$WSUSStats.ApprovedUpdateCount
        Declined = [int]$WSUSStats.DeclinedUpdateCount
        ClientInstallError = [int]$WSUSStats.UpdatesWithClientErrorsCount
        UpdatesNeedingFiles = [int]$WSUSStats.ExpiredUpdateCount    
    }
    $Pre += @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Update Statistics
        </div>

"@
    $Body = $WSUSUpdateStats | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Update Statistics

    #region Failed Update Installations
    $FailedUpdateInstall = $UpdateHash.GetEnumerator() | ForEach {
        [pscustomobject]@{
            Update = $_.Name
            Computername = ($_.Value) -join ', '
        }
    }
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Failed Update Installations By Update
        </div>

"@
    $Body = $FailedUpdateInstall | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Failed Update Installations

#endregion UPDATE INFORMATION

#region TARGET GROUP INFORMATION
$Pre = @"
<div style='margin: 0px auto; BACKGROUND-COLOR:Blue;Color:White;font-weight:bold;FONT-SIZE: 16pt;'>
    WSUS Target Group Information
</div>
"@
    #region Target Group Statistics
    $GroupStats = [pscustomobject]@{
        TotalGroups = [int]$TargetGroups.count
        TotalEmptyGroups = [int]$EmptyTargetGroups.Count
    }
    $Pre += @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Target Group Statistics
        </div>

"@
    $Body = $GroupStats | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Target Group Statistics

    #region Empty Groups
    $Pre = @"
        <div style='margin: 0px auto; BACKGROUND-COLOR:LightBlue;Color:Black;font-weight:bold;FONT-SIZE: 14pt;'>
            Empty Target Groups
        </div>

"@
    $Body = $EmptyTargetGroups | Select Name, ID | ConvertTo-Html -Fragment | Out-String | Set-AlternatingCSSClass -CSSEvenClass 'even' -CssOddClass 'odd'
    $Post = "<br>"
    $htmlFragment += $Pre,$Body,$Post
    #endregion Empty Groups

#endregion TARGET GROUP INFORMATION

#region Compile HTML Report
$HTMLParams = @{
    Head = $Head
    Title = "WSUS Report for $WSUSServer"
    PreContent = "<H1><font color='white'>Please view in html!</font><br>$WSUSServer WSUS Report</H1>"
    PostContent = "$($htmlFragment)<i>Report generated on $((Get-Date).ToString())</i>" 
}
$Report = ConvertTo-Html @HTMLParams | Out-String
#endregion Compile HTML Report

If ($ShowFile) {
    $Report | Out-File WSUSReport.html
    Invoke-Item WSUSReport.html
}

#region Send Email
If ($SendEmail) {
    $EmailParams.Body = $Report
    Send-MailMessage @EmailParams
}
#endregion Send Email