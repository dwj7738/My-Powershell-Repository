#requires -version 5
# Copyright © 2014, Microsoft Corporation. All rights reserved.
#region HelperFunctions
Import-Module $PSScriptRoot\..\Library\Helper.psm1
Import-Module $PSScriptRoot\..\Library\JeaDir.psm1
Import-Module $PSScriptRoot\..\Library\JeaProxy.psm1
# Internal function to throw terminating error with specified errroCategory, errorId and errorMessage




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
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Start Get [Toolkit]$Name" 

        $modulePath = (Join-Path (Join-Path (Get-JeaDir) 'Toolkit') "$($name)-ToolKit.psm1")
        Write-Verbose "Importing [JeaToolKit]$modulePath"
        Import-Module $modulePath  -Force  -DisableNameChecking -Verbose:0

        $module = Microsoft.PowerShell.Core\Get-Module -Name "$name-Toolkit"
        Write-Verbose "Module= $module "
	    $returnValue = @{
		    Name = [System.String]"$name-Toolkit"
		    CommandSpecs = [String]$(
                $csvPath = (Join-Path (Join-Path (Get-JeaDir) 'Toolkit') "$($name)-CommandSpecs.csv")
                if (test-path $csvPath)
                {
                    Microsoft.PowerShell.Management\get-content -Path $csvPath -Raw
                }
                )
		    Applications = [System.String[]] $(
                   &$Module{$ExportedApplications}
                )
		    Ensure = [System.String]'Present'

	    }
        Microsoft.PowerShell.Core\remove-module "$Name-Toolkit" -Verbose:0
	    $returnValue
    }catch
    {
        write-Debug "ERROR: $($_|fl * -force|out-string)"
        New-TerminatingError -errorId 'GetToolkitFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
    }finally
    {
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Done  Get [JeaToolkit]$name" 
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

		[String]
		$CommandSpecs,

		[System.String[]]
		$Applications,

		[System.String[]]
		$ScriptDirectory,

		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure = 'Present'
	)

    try
    {       
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Start Set [Toolkit]$Name" 
        Assert-JeaDirectory
        Export-JEAProxy -Name $name -CommandSpecs $CommandSpecs -Applications $Applications
    }
    catch 
    {
        Write-Debug $($_ |fl * -force |Out-String)
        New-TerminatingError -errorId 'JeaToolKitSet' -ErrorMessage $_.Exception -errorCategory OperationStopped
    }finally
    {
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Done  Set [Toolkit]$Name" 
    }
    return $true
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

		[String]
		$CommandSpecs,

		[System.String[]]
		$Applications,

		[System.String[]]
		$ScriptDirectory,

		[ValidateSet('Present','Absent')]
		[System.String]
		$Ensure = 'Present'
	)

    try
    {
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Start Test [JeaToolkit]$name" 

        $toolkit     = Join-Path (Get-JeaToolKitDir) "$($Name)-ToolKit.psm1"
        $CommandSpec = Join-Path (Get-JeaToolKitDir) "$($Name)-CommandSpecs.csv"
        $Exists = ((Test-Path $Toolkit) -AND (Test-Path $CommandSpec))
        if ($Exists) { Write-Verbose "     [JeaToolkit]$name Present"}
        else         { Write-Verbose "     [JeaToolkit]$name Absent"}


        if (($Ensure -eq 'Present' -and !$exists) -or
            ($Ensure -eq 'Absent'  -And  $exists))
        {
           return $false
        }
        if ($Ensure -eq 'Present' -and ($CommandSpecs.Trim() -ne (Get-Content $CommandSpec -Raw).Trim()))
        {
            return $false
        }
        return $true
    }catch
    {
        write-Debug "ERROR: $($_|fl * -force|out-string)"
        New-TerminatingError -errorId 'TestToolkitFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
    }finally
    {
        write-Verbose "$((get-date).GetDateTimeFormats()[112]) Done  Test [JeaToolkit]$name" 
    }	

} #Test-TargetResource


Export-ModuleMember -Function *-TargetResource

