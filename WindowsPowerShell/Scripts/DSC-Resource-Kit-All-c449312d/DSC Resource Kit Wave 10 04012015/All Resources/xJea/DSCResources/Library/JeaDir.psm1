# Copyright © 2014, Microsoft Corporation. All rights reserved.

function Get-JeaDir              { Join-Path $env:ProgramFiles 'Jea' }
function Get-JeaToolKitDir       { Join-Path (Get-JeaDir) 'Toolkit'}
function Get-JeaUtilDir          { Join-Path (Get-JeaDir) 'Util'}
function Get-JeaStartupScriptDir { Join-Path (Get-JeaDir) 'StartupScript'}
function Get-JeaActivityDir      { Join-Path (Get-JeaDir) 'Activity'}
function Get-JeaMotdDir          { Join-Path (Get-JeaDir) 'Motd'}
function Assert-JeaDirectory
{
    $ToolkitDir       = Get-JeaToolKitDir
    $UtilDir          = Get-JeaUtilDir
    $StartupScriptDir = Get-JeaStartupScriptDir
    $ActivityDir      = Get-JeaActivityDir
    $MotdDir          = Get-JeaMotdDir
    foreach ($dir in $ToolKitDir, $UtilDir, $StartupScriptDir, $ActivityDir, $MotdDir)
    {
        if (!(Test-Path $Dir))
        {
            Write-Verbose -Message "New  [JeaDirectory]$Dir"
            mkdir $Dir -Force
        }
    }
    $SafeProxyfile = Join-path $UtilDir 'SafeProxy.psm1'
    if (!(test-path $SafeProxyfile))
    {
        $sourcePS1 = Resolve-Path (Join-Path $PSScriptRoot '..\..\Util\SafeProxy.psm1')
        Copy-Item $sourcePS1 -Destination $SafeProxyfile -Verbose
    }
    $initfile = Join-path $UtilDir 'Initialize-Toolkit.ps1'
    if (!(test-path $initfile))
    {
        $sourcePS1 = Resolve-Path (Join-Path $PSScriptRoot '..\..\Util\Initialize-ToolKit.ps1')
        Copy-Item $sourcePS1 -Destination $initfile -Verbose
    }
}


