#requires -version 5
# Copyright © 2014, Microsoft Corporation. All rights reserved.
#region Helper
Import-Module $PSScriptRoot\..\Library\Helper.psm1
Import-Module $PSScriptRoot\..\Library\JeaDir.psm1
Import-Module $PSScriptRoot\..\Library\JeaAccount.psm1 
Import-Module $PSScriptRoot\..\Library\JeaInitFile.psm1


#endregion

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name
	)

    try
    {
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Start Get [EndPoint]$Name" 
        $endpoint = Get-PSSessionConfiguration -Name $Name -ErrorAction SilentlyContinue -Verbose:0
	
        if ($endpoint)
        {
	        $returnValue = @{
		        Name    = [System.String]$Name
		        Toolkit = [System.String[]]"TODO: GET TOOLKITS"
		        Ensure  = [System.String]'Present'
		        SecurityDescriptorSddl = [System.String]$endpoint.SecurityDescriptorSddl
		        Group = [String[]]$(
                    "TODO: Get Groups"
                )
            }
        }
        else
        {
	        $returnValue = @{
		        Name   = [System.String]$Name
		        Ensure = [System.String]'Absent'
            }
        }
	    $returnValue
    }catch
    {
        write-Debug "ERROR: $($_|fl * -force|out-string)"
        New-TerminatingError -errorId 'GetJeaEndpointFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
    }finally
    {
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Done  Get [EndPoint]$Name" 
    }	
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[System.String[]]
		$Toolkit,

		[System.String]
		$SecurityDescriptorSddl='O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;RM)S:P(AU;FA;GA;;;WD)(AU;SA;GXGW;;;WD)',

		[System.String[]]
		$Group = @('Administrators'),

		[System.Boolean]
		$CleanAll,

		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure = 'Present'
	)
    try
    {    
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Start Set [EndPoint]$Name" 
        if ($CleanAll)
        {
            #region Remove non-default endpoints
            Write-Verbose 'Remove [JeaEndpoints]    *'
            $defaultEndpoints = 'microsoft.powershell','microsoft.powershell.workflow','microsoft.powershell32','microsoft.windows.servermanagerworkflows'
            Get-PSSessionConfiguration -Verbose:0 |where Name -NotIn $defaultEndpoints | % {
                Write-Verbose "Remove [PSEndPoint]      $($_.Name)"
                Unregister-PSSessionConfiguration -NoServiceRestart -Force -Verbose:0 -Name $_.Name
            }
            #endregion
            
            #region Remove the JSA UserAccounts
            Write-Verbose 'Remove [JSAUserAccount]*'
            [ADSI]$Server="WinNT://$($Env:COMPUTERNAME)"
            foreach ($account in (Get-CimInstance -Query 'select * from Win32_UserAccount Where Name Like "JSA-%" AND LocalAccount="TRUE"').Name)
            {
                Write-Verbose "Remove [JSAUserAccount]  $account"
                $server.Delete('user',$account)
            }
            if (Get-CimInstance -Query 'select * from Win32_UserAccount Where Name = "JeaSchTaskAccount" AND LocalAccount="TRUE"')
            {
                Write-Verbose "Remove [JSAUserAccount]JeaSchTaskAccount"
                $server.Delete('user','JeaSchTaskAccount')
            }
            #endregion

            #region remove StartupFiles
            if (test-path (Get-JeaStartupScriptDir))
            {
                Write-Verbose 'Remove [JeaStartupFile]   *'
                Remove-Item (Join-Path (Get-JeaStartupScriptDir) *) -Recurse -Verbose
            }
            #endregion

            #region Remove JeaScheduled Tasks
            write-verbose "Remove [ScheduleTask]RestartWinRM"
            Unregister-ScheduledTask  -TaskPath \Microsoft\Windows\Jea\ -TaskName RestartWinRM -ErrorAction Ignore
            write-verbose "Remove [ScheduleTask]ResetJeaSessionAccountPasswords"
            Unregister-ScheduledTask  -TaskPath \Microsoft\Windows\Jea\ -TaskName ResetJeaSessionAccountPasswords -ErrorAction Ignore
            #endregion

        }
        else
        {
            JeaAccount\Assert-JeaAdminAccount

            $endPointName = $Name
            $endPoint     = Get-PSSessionConfiguration -Name $Name -Verbose:0 -ErrorAction SilentlyContinue
            $account      = "JSA-$Name"
            if ($Ensure -AND !($endPoint))
            {
                #region ACCOUNT
                Write-Verbose "Test   [JeaSessionAccount]$account"
                if (Test-JeaSessionAccount -UserName $account)
                {
                    Write-Verbose "       [JeaSessionAccount]$account = `$true; Reset-JeaSessionAccountPassword"
                    $cred = Reset-JeaSessionAccountPassword -UserName $account
                }else
                {
                    Write-Verbose "New    [JeaSessionAccount]$account"
                    $cred = New-JeaSessionAccount -UserName $account -Description 'PowerShell Session Acount' -Group $group
                }
                #endregion

                #region InitializationFile
                $startupfile = Join-Path (Get-JeaStartupScriptDir) "Initialize-$($Name).ps1"
                Write-Verbose "New    [JeaStartupFile]   $StartupFile -> [Jeatoolkit]$Toolkit"
                New-InitializationFile -Path $StartupFile -Toolkit $Toolkit
                #endregion

                #region EndPoint
                Write-Verbose "New    [JeaEndPoint]      $Name"
                try
                {
                    # Set the following preference so the functions inside Unregister-PSSessionConfig doesn't get these settings
                    $oldDebugPrefernce = $DebugPreference; $oldVerbosePreference = $VerbosePreference
                    $DebugPreference = $VerbosePreference = 'SilentlyContinue'

                    $null = Register-PSSessionConfiguration -Name $Name -StartupScript $startupfile -RunAsCredential $cred -NoServiceRestart -Verbose:0 -Force -SecurityDescriptorSddl $SecurityDescriptorSddl
                    # Reset the following preference to older values 
                    $DebugPreference = $oldDebugPrefernce; $VerbosePreference = $oldVerbosePreference

                    Start-ScheduledTask -TaskName RestartWinRM -TaskPath \Microsoft\Windows\Jea\
                }
                catch
                {
                    write-Debug "ERROR: $($_|fl * -force|out-string)"
                    New-TerminatingError -errorId 'JeaEndpointConfigurationFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
                }            

                #endregion
            }elseif (!($Ensure) -And $EndPoint)
            {
                Write-Verbose "Unregister [JeaEndPoint]      $Name"
                Unregister-PSSessionConfiguration -Name $Name -Force -Verbose:0
                Start-ScheduledTask -TaskName RestartWinRM -TaskPath \Microsoft\Windows\Jea\
                if (Test-JeaSessionAccount -UserName $account)
                {
                    [ADSI]$Server="WinNT://$($Env:COMPUTERNAME)"
                    $server.Delete('user',$account)
                }
            }
        }
    }catch
    {
        write-Debug "ERROR: $($_|fl * -force|out-string)"
        New-TerminatingError -errorId 'SetJeaEndpointFailed' -errorMessage $_.Exception -errorCategory InvalidOperation

    }finally
    {
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Done  Set [EndPoint]$Name" 
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[System.String[]]
		$Toolkit,

		[System.String]
		$SecurityDescriptorSddl,

		[System.String[]]
		$Group,

		[System.Boolean]
		$CleanAll,

		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure = 'Present'
	)

    try
    {
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Start Test [EndPoint]$Name" 

        if ($Cleanall)
        {
            return $false
        }else
        {
            Write-Verbose "Test   [JeaEndPoint]      $name"

            $endPoint = Get-PSSessionConfiguration -Name $Name -Verbose:0 -ErrorAction Stop
            $namePresentMessage = "       [JeaEndPoint]      $name Present"
            Write-Verbose -Message $namePresentMessage
            if ($Ensure -eq 'Absent')
            {
	            return $false
            }
            else
            {
                Write-Verbose 'TEST   SecurityDescriptorSddl'
                if ($SecurityDescriptorSddl -and ($endPoint.SecurityDescriptorSddl -ne $SecurityDescriptorSddl))
                {
                    Write-Verbose '       SecurityDescriptorSddl MISMATCH'
                    return $false
                }
                Write-Verbose '       TODO: Check for Toolkits, StartupScript and UserAccount'
                return $true
	        }
        }
    }catch 
    {
        Write-Verbose "       [JeaEndPoint]      $Name Absent"
        return ($Ensure -eq 'Absent')
    }finally
    {
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Done  Test [EndPoint]$Name" 
    }
}


Export-ModuleMember -Function *-TargetResource

