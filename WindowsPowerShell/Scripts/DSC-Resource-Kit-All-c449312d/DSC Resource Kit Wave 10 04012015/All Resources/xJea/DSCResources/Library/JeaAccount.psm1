# Copyright © 2014, Microsoft Corporation. All rights reserved.
Import-Module $PSScriptRoot\..\Library\Helper.psm1
Import-Module $PSScriptRoot\..\Library\JeaDir.psm1

<#
.Synopsis
   Creates a random password.
.DESCRIPTION
   Creates a random password by generating a array of characters and passing it to Get-Random
.EXAMPLE
PS> New-RandomPassword
g0dIDojsRGcV
.EXAMPLE
PS> New-RandomPassword -Length 3
dyN
.EXAMPLE
PS> New-RandomPassword -Length 30 -UseSpecialCharacters
r5Lhs1K9n*joZl$u^NDO&TkWvPCf2c
#>
function New-RandomPassword
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # Length of the password
        [Parameter(Mandatory=$False, Position=0)]
        [ValidateRange(12, 127)]
        $Length=12,

        # Includes the characters !@#$%^&*-+ in the password
        [switch]$UseSpecialCharacters
    )

    [char[]]$allowedCharacters = ([Char]'a'..[char]'z') + ([char]'A'..[char]'Z') + ([byte][char]'0'..[byte][char]'9')
    if ($UseSpecialCharacters)
    {
        foreach ($c in '!','@','#','$','%','^','&','*','-','+')
        {
            $allowedCharacters += [char]$c
        }
    }

    $characters = 1..$Length | % {
        $characterIndex = Get-Random -Minimum 0 -Maximum $allowedCharacters.Count
        $allowedCharacters[$characterIndex]
    }

    return (-join $characters)
}

Set-Alias New-RandomString New-RandomPassword

<#
.Synopsis
   Create a User Account with a random name
.DESCRIPTION
   
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function New-JeaSessionAccount
{
    [CmdletBinding(DefaultParameterSetName='UserNamePrefix')]
    Param
    (
        #********************************************************************************
        # A random username is generated.  This parameter gives you the opportunity to
        # to prefix that name with a string to help identify the account
        [Parameter(Mandatory=$false, ParameterSetName='UserNamePrefix')]
        [ValidateLength(0,12)]
        $UserNamePrefix = 'JSA-',

        [Parameter(Mandatory=$true, ParameterSetName='UserName')]
        $UserName,

        [string]
        $ComputerName = $Env:COMPUTERNAME,

        [string]
        $Description = "JEA Service Account created by $($env:UserDomain + '\' + $ENV:Username) at $(Get-Date)",

        [string[]]
        $Group='Administrators'
    )

    if (!($PSCmdlet.ParameterSetName -eq 'UserName'))
    {
        $MaxWindowsUserLength = 20
        $Templength = $MaxWindowsUserLength - $UserNamePrefix.Length
        $UserName = $UserNamePrefix + (New-RandomString -Length $TempLength)
    }

    $Computer = [ADSI]"WinNT://$COMPUTERNAME,Computer"

    Write-Verbose "New    [JeaSessionAccount]$UserName"
    $User = $Computer.Create('User', $UserName)
    $password = New-RandomPassword -Length 127 -UseSpecialCharacters
    $cred = new-object pscredential $username, (convertto-securestring $password -asplaintext -force)

    $null = $(
      $User.SetPassword($password)
      $User.SetInfo()
      $User.FullName = 'Jea Session Account'
      $User.SetInfo()
      $User.Description = $Description
      $User.SetInfo()
      $User.UserFlags = 64 # ADS_UF_PASSWD_CANT_CHANGE http://msdn.microsoft.com/en-us/library/aa772300(v=vs.85).aspx
      $User.SetInfo()
    )
    
    foreach ($item in $group)
    {
        Write-Verbose "       [JeaSessionAccount]$UserName ADD [Group]$item"
        $gobj = [ADSI]"WinNT://$COMPUTERNAME/$item,group" 
        $null = $gobj.add("WinNT://$ComputerName/$UserName") 
    }
    return $cred  
}

function Remove-JeaAccount
{
    Param
    (

        [Parameter(Mandatory=$true)]
        $UserName,

        [string]
        $ComputerName = $Env:COMPUTERNAME
    )

    $Computer = [ADSI]"WinNT://$COMPUTERNAME,Computer"
    $computer.delete('user',$userName)
}


function Test-JeaSessionAccount
{
    [CmdletBinding()]
    [OutputType([Boolean])]
        Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        $UserName,

        $ComputerName = $Env:COMPUTERNAME

    )

    $oldDebugPrefernce = $DebugPreference; $oldVerbosePreference = $VerbosePreference
    $DebugPreference = $VerbosePreference = 'SilentlyContinue'
    $user = Get-CimInstance -Query "select * from Win32_UserAccount Where Name=""$UserName"" AND LocalAccount=""TRUE""" -ComputerName $ComputerName -Verbose:0
    $DebugPreference = $oldDebugPrefernce; $VerbosePreference = $oldVerbosePreference
    return [Boolean]$user
}


function Reset-JeaSessionAccountPassword
{
    [CmdletBinding()]
    Param
    (
        #********************************************************************************
        # A random username is generated.  This parameter gives you the opportunity to
        # to prefix that name with a string to help identify the account
        [Parameter(Mandatory=$true, Position=0)]
        $UserName,

        $ComputerName = $Env:COMPUTERNAME

    )

    $user = [ADSI]"WinNT://$computerName/$username,user" 
    $password = New-RandomPassword -Length 127 -UseSpecialCharacters
    $null = $user.setpassword($password)  
    $null = $user.SetInfo() 
    $cred = new-object pscredential $username, (convertto-securestring $password -asplaintext -force)
    return $cred
}

function Assert-JeaAdminAccount
{
    $cred = $null
    if (!(Test-JeaSessionAccount -UserName JeaSchTaskAccount))
    {
        Write-Verbose 'New    [JeaScheduledTaskAccount]'
        $cred = New-JeaSessionAccount -UserName JeaSchTaskAccount -Group Administrators -Description "This is a special Jea account to run the ResetJeaSessionAccountPasswords Scheduled task"
    }
    Assert-ScheduledScripts
    Assert-ScheduledTasks $cred
}

$ResetScript = @'
    #This resets the passwords for all the RUnas
    [char[]]$pwChars = ([Char]'a'..[char]'z') + ([char]'A'..[char]'Z') + ([byte][char]'0'..[byte][char]'9')
    foreach ($c in '!','@','#','$','%','^','&','*','-','+')
    {
        $pwChars += [char]$c
    }

    $endpoint = Get-PSSessionConfiguration |where {$_.RunAsUser -like 'JSA-*'}
    if ($endpoint)
    {
        foreach ($ep in $endpoint)
        {
            $user = [ADSI]"WinNT://$($env:computerName)/$($ep.RunAsUser),user" 
            $password =  (( $pwChars |Get-Random -Count 127 | % {[char]$_}) -join '')
            $null = $user.setpassword($password)  
            $null = $user.SetInfo() 
            $cred = new-object pscredential ($ep.RunAsUser), (convertto-securestring $password -asplaintext -force)
            Set-PSSessionConfiguration -Name $($ep.Name) -RunAsCredential $cred -Force
        }
        Restart-Service Winrm -Force
    }
'@

$RestartWinRM = @'
#requires -Version 5
<#
If you restart the WinRM service while DSC is running, it puts WinRM in a bad state
so this script waits for DSC to finish it's work and then restarts WinRM
#>
While ((Get-DscLocalConfigurationManager).LocalConfigurationManagerState -ne 'Ready')
{
    Start-Sleep -Seconds 2
}
start-sleep -seconds 20
Restart-Service winrm -Force
'@

function Assert-ScheduledScripts
{
    $UtilDir = Get-JeaUtilDir
    if (!(Test-Path $UtilDir))
    {
        Write-Verbose "New    [JeaDirectory]$utildir"
        mkdir -Force -Path $UtilDir
    }

    $ResetPS1 = Join-Path $UtilDir 'ScheduledPasswordReset.ps1'
    if (!(Test-Path $ResetPs1) -or 
        (cat $resetPS1 -Delimiter "None") -ne $resetscript)
    {
        Write-Verbose 'Reset  [JeaScheduledPasswordResetScript]'
        $resetScript > $ResetPS1
    }
    
    $RestartWinRMPS1 = Join-Path $UtilDir 'RestartWinrm.ps1'
    if (!(Test-Path $restartWinRMPS1) -or 
        (Get-Content $restartWinRMPS1 -Delimiter 'None') -ne $RestartWinRM)
    {
        Write-Verbose 'Reset  [JeaScheduledPasswordreStartWinRMScript]'
        $RestartWinRM > $restartWinRMPS1
    }
}

function Assert-ScheduledTasks
{
param(
[Parameter()]
$cred
)

    $UtilDir = Get-JeaUtilDir
    $wd = "`"$UtilDir`""
    $ResetPS1 = Join-Path $UtilDir 'ScheduledPasswordReset.ps1'
    $file = "`"$ResetPS1`""
    $cmdPath = (get-command Powershell.exe).Source
    $Arguments = "-nologo -executionPolicy ByPass -NoProfile -NonInteractive -file $file -WorkingDirectory $wd -WindowStyle hidden" 
    $s = Get-ScheduledTask -TaskPath \Microsoft\Windows\Jea\ -TaskName ResetJeaSessionAccountPasswords -ErrorAction SilentlyContinue
    Write-Verbose "Test   [JEAScheduledTask]ResetJeaSessionAccountPasswords $([Bool]$s)"
    if (!($s) -or
        $s.Actions.Count -ne 1  -or
        $s.Actions[0].Execute   -ne $cmdPath -or
        $s.Actions[0].Arguments -ne $Arguments)
    {
        if ($s) {Unregister-ScheduledTask -TaskPath \Microsoft\Windows\Jea\ -TaskName ResetJeaSessionAccountPasswords -ErrorAction SilentlyContinue }
        $action = New-ScheduledTaskAction -Execute $cmdPath -Argument $arguments
        $trigger = New-ScheduledTaskTrigger -Daily -At 1:00
        if (!$Cred)
        {
            Write-Verbose 'Register [JEAScheduledTask]ResetJeaSessionAccountPasswords'
            $cred = Reset-JeaSessionAccountPassword -UserName JeaSchTaskAccount
        }
        $setting = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -StartWhenAvailable    
        Write-Verbose 'Register [JEAScheduledTask]ResetJeaSessionAccountPasswords'
        Register-ScheduledTask -TaskName ResetJeaSessionAccountPasswords -Action $action `
            -TaskPath \Microsoft\Windows\Jea\  -Description 'Reset Jea Session Account Passwords' `
            -Settings $setting `
            -Trigger $trigger `
            -User $cred.UserName -Password $cred.GetNetworkCredential().Password
        
    }


    $RestartWinRMPS1 = Join-Path $UtilDir 'RestartWinrm.ps1'
    $file = "`"$RestartWinrmPS1`""
    $Arguments = "-nologo -executionPolicy ByPass -NoProfile -NonInteractive -file $file -WorkingDirectory $wd -WindowStyle hidden" 
    $s = Get-ScheduledTask -TaskPath \Microsoft\Windows\Jea\ -TaskName RestartWinRM -ErrorAction SilentlyContinue
    Write-Verbose "Test   [JEAScheduledTask]RestartWinRM $([Bool]$s)"
    if (!($s) -or
        $s.Actions.Count -ne 1  -or
        $s.Actions[0].Execute   -ne $cmdPath -or
        $s.Actions[0].Arguments -ne $Arguments)
    {
        if ($s) {Unregister-ScheduledTask -TaskPath \Microsoft\Windows\Jea\ -TaskName RestartWinRM -ErrorAction SilentlyContinue }
        $action = New-ScheduledTaskAction -Execute $cmdPath -Argument $arguments
        if (!$Cred)
        {
            Write-Verbose 'Register [JEAScheduledTask]JeaSchTaskAccount'
            $cred = Reset-JeaSessionAccountPassword -UserName JeaSchTaskAccount
        }
        $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew            
        Write-Verbose 'Register [JEAScheduledTask]RestartWinRM'
        Register-ScheduledTask -TaskName RestartWinRM -Action $action `
            -TaskPath \Microsoft\Windows\Jea\  -Description 'Restart WinRM after current DSC cycle is complete' `
            -Settings $settings `
            -User $cred.UserName -Password $cred.GetNetworkCredential().Password
        
    }
}
