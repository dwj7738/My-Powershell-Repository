# Copyright © 2014, Microsoft Corporation. All rights reserved.
#InitializeToolKit
param(
    [ValidateNotNullOrEmpty()]
    $ToolkitName
)

ipmo (Join-Path $env:ProgramFiles 'Jea\Util\SafeProxy.psm1') -DisableNameChecking

function Write-ActivityRecord
{
    $JeaDir         = Join-Path $env:ProgramFiles 'Jea' 
    $JeaActivityDir = Join-Path $JeaDir 'Activity'
    $Logfile        = Join-Path $JeaActivityDir 'ActivityLog.csv'

    $WinRMInfo = winrm enum shell |Select-String "ProcessID = $pid" -Context 5,0
    $winRMID   = (($WinRMInfo.Context.PreContext |Select-String 'ShellID = ').Line.trim() -split ' = ')[1]
    $record    = new-Object PSObject -Property @{
        host          = hostname
        Datetime      = Get-Date;
        PID           = $PID;
        RunSpaceID    = $ExecutionContext.Host.Runspace.InstanceId.Guid;
        Toolkit       = ($ToolkitName -join ';');
        WinRMShellID  = $WinRMID;
        }

    
    $record | Export-Csv $Logfile -Append
}

#region Show Message Of The Day (MOTD)
function Show-Motd
{
    $motd = (Join-Path $env:ProgramFiles 'Jea\motd.txt')
    if (Test-Path $motd)
    {
        Write-Host (Get-Content $motd -raw)
    }
    foreach ($t in $toolkitName)
    {
        $motd = (Join-Path $env:ProgramFiles "Jea\Motd\$t.txt")
        if (Test-Path $motd)
        {
            Write-Host (Get-Content $motd -raw)
        }
    }
}
#endregion

function Import-Toolkit
{
    param($ToolkitName)

    foreach ($t in $ToolkitName)
    {
        $path = (Join-Path $env:ProgramFiles "Jea\toolkit\$($t).psm1")
        if (Test-Path $path)
        {
            Import-Module $path -Force -DisableNameChecking
        }
        else
        {
            Write-host -ForegroundColor "Import-Toolkit [ToolKit]$path NotFound"
        }
    }
}

function Approve-Command
{
    param([string[]]$name)

    foreach ($n in $name)
    {
        $approvedCommand.$n = 1
    }
}

function Approve-RemoteSessionCommand
{
    $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateRestricted('RemoteServer')
    foreach ($f in $iss.Commands.Where({$_.CommandType -eq 'Function'}))
    {
        Set-Content "function:\$($f.Name)" -Value $f.definition
        Approve-Command $f.name 
    }
}


function Approve-ExportedApplication
{
    $apps = @()
    foreach ($m in Get-Module)
    {
        foreach ($a in &$m{$ExportedApplications})
        {
            if ($a)
            {
                $apps += $(Get-command $a).Definition
            }
        }
    }
    $ExecutionContext.SessionState.Applications.Clear()
    foreach ($a in $apps)
    {
        $ExecutionContext.SessionState.Applications.Add($a)
    }
}

function Block-UnauthorizedCommands 
{
    param(
    )

    Get-Command | % {
        $cmd = $_
        if ($approvedCommand.$($cmd.Name) )
        {
            # If a proxy for a command exists, we need to remove the name from the list 
            # so that we can hide the underlying command
            $approvedCommand.Remove($($cmd.Name))
        }
        else
        {
            $cmd.Visibility = 'Private'
        }
        
    }
    
    #Certain commands are particularly dangerous so make sure that they are not exposed.
    foreach ($c in 'Invoke-Expression','Import-module')
    {
        (Get-Command $c).Visibility = 'Private'
    }
}


function Enable-CommandLogging
{
    param($Module)

    Get-Module $Module | % { $_.LogPipelineExecutionDetails = $true }
}

$approvedCommand = @{}

Write-ActivityRecord
Show-Motd
Import-Toolkit $ToolkitName
Enable-CommandLogging $ToolkitName
Approve-RemoteSessionCommand
Approve-Command -name `
    'whoami',
    'Get-Alias',
    'Get-History',
    'Get-Member',
    'Get-Module', 
    'Group-Object',
    'Format-Table', 
    'Format-List',
    'Measure-Object',
    'New-Object', # This needs to be constrained
    'Select-Object',
    'Sort-Object',
    'Tabexpansion2',
    'Where-Object'
Approve-Command -name $((Get-Module  $ToolkitName ).Exportedfunctions.Values.name)
Block-UnauthorizedCommands 
Approve-ExportedApplication

$ExecutionContext.SessionState.Scripts.Clear()    
$global:PSModuleAutoloadingPreference = 'None'
$ExecutionContext.SessionState.LanguageMode='NoLanguage'