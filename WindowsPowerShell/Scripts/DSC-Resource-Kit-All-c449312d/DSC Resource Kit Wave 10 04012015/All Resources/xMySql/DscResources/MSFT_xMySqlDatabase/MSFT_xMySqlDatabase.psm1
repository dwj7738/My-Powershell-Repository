<#
   DSC resource designed to create a database in a MySQL instance, given the parameters supplied as per schema.

   Copyright (c) Microsoft Corporation, 2014
#>

# NOTE: LocalizedData isn't used in this resource as there are no interactive/user visible strings

#constants
$mySqlVersion = "5.6"
$Debug = $true
$MySQLExePath = "$env:ProgramFiles\mySql\Mysql Server 5.6\bin\mysql.exe"


#########################################################################################################################################
# Trace-Message ([string]$Message). If Debug flag is set to true, it writes a verbose message given the input parameter
#########################################################################################################################################

Function Trace-Message
{
    param([string] $Message)

    if($Debug)
    {
        Write-Verbose $Message
    }
}

#########################################################################################################################################
# Set-MySqlPwdEnvVar ([pscredential] $ConnectionCredential). Given the input user password, set the MySQL pwd environment variable
#########################################################################################################################################

function Set-MySqlPwdEnvVar
{
    param
    (
        [pscredential] $ConnectionCredential
    )
    Trace-Message "setting mysqlpassword to: $($ConnectionCredential.GetNetworkCredential().Password)"
    [System.Environment]::SetEnvironmentVariable("MySql_PWD","$($ConnectionCredential.GetNetworkCredential().Password)")
}

#########################################################################################################################################
# Get-TargetResource ([string]$Ensure, [string]Name, [pscredential]$ConnectionCredential): given the database string and the user password
# determine whether the MySQL database is installed and return the result
#########################################################################################################################################

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [string] $Name,
        
        [parameter(Mandatory = $true)]
        [pscredential] $ConnectionCredential
    )
    
    $Ensure = "Absent"

    Set-MySqlPwdEnvVar -ConnectionCredential $ConnectionCredential

    #note: we don't want to check and throw an exception in the case where the current configuration is Absent, and the
    # user calls into Test-DscConfiguration or Get-DscConfiguration. In those cases, we just want to return false but not
    # throw an exception as that is the wrong user experience.
    if ((Test-Path -Path $MySQLExePath))
    {
        $result = `
            &$MySQLExePath `
            "--execute=SELECT IF(EXISTS (SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$Name'), 'Yes','No')" `
                --user=root --silent

        if($result -ieq  "Yes")
        {
            $Ensure = "Present"
        }
    }

    return @{
        Ensure = $Ensure
        Name = $Name
    }
}

#########################################################################################################################################
# Test-TargetResource ([string]$Ensure, [string]Name, [pscredential]$ConnectionCredential): given the database string and the user password
# determine whether the database is installed and return true or false based on the findings
#########################################################################################################################################

function Test-TargetResource 
{
    [OutputType([Boolean])]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [string] $Name,
        
        [parameter(Mandatory = $true)]
        [pscredential] $ConnectionCredential
    )
    
    Trace-Message "Ensure is $Ensure"

    $status = Get-TargetResource @psboundparameters
    
    if($status.Ensure -eq $Ensure)
    {
        return $true
    }
    else
    {
        return $false
    }
}

#########################################################################################################################################
# Set-TargetResource ([string]$Ensure, [string]Name, [pscredential]$ConnectionCredential): given the database string and the user password
# either drop the database or create it, depending on Ensure value
#########################################################################################################################################

function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",

        [parameter(Mandatory = $true)]
        [string] $Name,
        
        [parameter(Mandatory = $true)]
        [pscredential] $ConnectionCredential
    )
    
    if((Test-TargetResource @psboundparameters))
    {
        return
    }
    
    if($Ensure -eq "Present")
    {
        Trace-Message "Creating Database $Name..."
        Set-MySqlPwdEnvVar -ConnectionCredential $ConnectionCredential

        Trace-Message "$MySQLExePath --execute=create database $Name;  --user=root --silent"
        $result = &"$MySQLExePath" "--execute=create database $Name;"  --user=root --silent
    }
    else
    {
        Trace-Message "Dropping Database $Name..."
        Trace-Message "$env:ProgramFiles\mySql\Mysql Server 5.6\bin\mysqladmin.exe" -f drop $Name --user=root --silent
        $result = &"$env:ProgramFiles\mySql\Mysql Server 5.6\bin\mysqladmin.exe" -f drop $Name --user=root --silent
    }
}


Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
