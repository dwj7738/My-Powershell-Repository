cls

configuration Demo3
{
    Import-DscResource -module xjea

    xJeaToolKit FileSystem
    {
        Name = 'FileSystem'
            CommandSpecs = @"
Module,name,Parameter,ValidateSet,ValidatePattern
,Get-ChildItem
,Get-Item
,Copy-Item
,Move-Item
,Rename-Item
,Remove-Item
,Copy-ItemProperty
,Clear-ItemProperty
,Move-ItemProperty
,New-ItemProperty
,Remove-ItemProperty
,Rename-ItemProperty
,Set-ItemProperty
,Get-Location
,Pop-Location
,Push-Location
,Set-Location
,Convert-Path
,Join-Path
,Resolve-Path
,Split-Path
,Test-Path
,Get-PSDrive
,New-PSDrive
,out-file
"@
        Ensure = 'Present'        
    }
    
    xJeaEndPoint Demo3EP
    {
        Name      = 'Demo3EP'
        ToolKit   = 'FileSystem'
        Ensure    = 'Present'
        DependsOn = '[xJeaToolKit]FileSystem'
    }
}

Demo3 -OutputPath C:\JeaDemo

Start-DscConfiguration -Path C:\JeaDemo -ComputerName localhost -Verbose -wait

start-sleep -Seconds 30 #Wait for WINRM to restart

# This endpoint allows you to navigate the filesystem but not see the CONTENTS
# of any of the files

$s = New-PSSession -cn . -ConfigurationName Demo3EP
Invoke-command $s {dir 'C:\Program Files\Jea\Activity\ActivityLog.csv'} 
Invoke-Command $s {get-content 'C:\Program Files\Jea\Activity\ActivityLog.csv'}
# Enter-pssession $s

Remove-PSSession $s
#EOF