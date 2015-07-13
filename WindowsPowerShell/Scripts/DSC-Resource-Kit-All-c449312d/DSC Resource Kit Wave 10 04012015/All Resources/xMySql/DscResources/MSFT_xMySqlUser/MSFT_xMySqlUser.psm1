#########################################################################################################################################
# xMySqlUSer module for creating/removing users from MySql Server
#########################################################################################################################################


#constants
$MySQLExePath = "$env:ProgramFiles\mySql\Mysql Server 5.6\bin\mysql.exe"

# A global variable that contains localized messages of MySqlUser.
data LocalizedData
{
# culture="en-US"
ConvertFrom-StringData @'
UserCreated=User {0} created successfully.
UserRemoved=User {0} removed successfully.
InvalidUserName=The name {0} cannot be used. Names may not consist entirely of periods and/or spaces, or contain these characters: {1}
UserExists=A user with the name {0} exists.
UserDoesNotExist=A user with the name {0} does not exist.
'@
}

Import-LocalizedData LocalizedData -FileName MSFT_xMySqlUser.strings.psd1

#########################################################################################################################################
# Set-MySqlPwdEnvVar ([pscredential] $RootPassword). Given the input root password, set the MySQL password environment variable
#########################################################################################################################################

function Set-MySqlPwdEnvironmentVariable
{
    param
    (
        [pscredential] $RootPassword
    )
    Write-Verbose "Setting MySql Server root password to: $($RootPassword.GetNetworkCredential().Password)"
    [System.Environment]::SetEnvironmentVariable("MySql_PWD","$($RootPassword.GetNetworkCredential().Password)")
}


#########################################################################################################################################
# Get-TargetResource ([string]$Name, [string]Ensure, [string]Credential, [string]ConnectionCredential) : given the username
# determine whether the user exists in MySQL database and return the result
#########################################################################################################################################

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,
      
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",
       
        [pscredential] $Credential,

        [parameter(Mandatory = $true)]
        [pscredential] $ConnectionCredential       
    )
    
    $Ensure = "Absent"

    ValidateUserName -UserName $Name   

    Set-MySqlPwdEnvironmentVariable -RootPassword $ConnectionCredential

    if ((Test-Path -Path $MySQLExePath))
    {
        $result = `
            &$MySQLExePath `
            "--execute=SELECT IF(EXISTS (SELECT USER FROM MYSQL.USER  WHERE USER = '$Name'), 'Yes','No')" `
                --user=root --silent

        if($result -ieq  "Yes")
        {
             $msg = "$($LocalizedData.UserExists) -f $Name"
             Write-Verbose -Message $msg          
             $Ensure = "Present"
        }
        else
        {
           $msg = "$($LocalizedData.UserDoesNotExist) -f $Name"
           Write-Verbose -Message $msg          
        }
    }

    return @{
        Name = $Name
        Ensure = $Ensure
        
    }
}

#########################################################################################################################################
# Test-TargetResource ([string]$Name, [string]Ensure, [pscredential]$Credential, [pscredential]$ConnectionCredential): determine whether the given user name exists in mysql user list using the root password
#########################################################################################################################################

function Test-TargetResource 
{
    [OutputType([Boolean])]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,
      
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",
       
        [pscredential] $Credential,

        [parameter(Mandatory = $true)]
        [pscredential] $ConnectionCredential
    )
    
    Write-Verbose "Ensure is $Ensure"

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
# Set-TargetResource ([string]$Name, [string]Ensure, [pscredential]$Credential, [pscredential]$ConnectionCredential): Add the given user name to mysql user list using the root password
#########################################################################################################################################


function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",
        
        [parameter(Mandatory = $true)]
        [pscredential] $Credential,

        [parameter(Mandatory = $true)]
        [pscredential] $ConnectionCredential
       
    )
    
    if((Test-TargetResource @psboundparameters))
    {
        return
    }
    
    Set-MySqlPwdEnvironmentVariable -RootPassword $ConnectionCredential 
    $HostName = "localhost"
    $SqlUser = "`'$Name`'@"
    $SqlUser+="`'$HostName`'"

    if($Ensure -eq "Present")
    {        
        $psw = "$($Credential.GetNetworkCredential().Password)"
        Write-Verbose "$MySQLExePath create user $SqlUser identified by $psw;  --user=root --silent"
                   
        $result = &"$MySQLExePath" "--execute=create user $SqlUser identified by `'$psw`'"  --user=root --silent
        $msg = "$($LocalizedData.UserCreated) -f $Name"
        Write-Verbose -Message $msg       
    }
    else
    {        
        Write-Verbose "$MySQLExePath drop $SqlUser --user=root --silent"
        $result = &"$MySQLExePath" "--execute=DROP user $SqlUser"  --user=root --silent

        $msg = "$($LocalizedData.UserRemoved) -f $Name"
        Write-Verbose -Message $msg  
    }
}

#########################################################################################################################################
# Throw-InvalidDataException ([string]$errorId, [string]$errorMessage): generate an error record and throw given the input parameters
#########################################################################################################################################

function Throw-InvalidDataException
{
    param(
        [parameter(Mandatory = $true)]
        [System.String] 
        $errorId,
        [parameter(Mandatory = $true)]
        [System.String]
        $errorMessage
    )
    
    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidData
    $exception = New-Object System.InvalidOperationException $errorMessage 
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
}

#########################################################################################################################################
# Validates the User name for invalid charecters.
#########################################################################################################################################
function ValidateUserName
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $UserName
    )

    # Check if the name consists of only periods and/or white spaces.
    $wrongName = $true;
    for($i = 0; $i -lt $UserName.Length; $i++)
    {
        if(-not [Char]::IsWhiteSpace($UserName, $i) -and $UserName[$i] -ne '.')
        {
            $wrongName = $false;
            break;
        }
    }

    $invalidChars = @('\','/','"','[',']',':','|','<','>','+','=',';',',','?','*','@')

    if($wrongName)
    {
        ThrowInvalidArgumentError -ErrorId "UserNameHasOnlyWhiteSpacesAndDots" -ErrorMessage ($LocalizedData.InvalidUserName -f $UserName, [string]::Join(" ", $invalidChars))
    }

    if($UserName.IndexOfAny($invalidChars) -ne -1)
    {
        ThrowInvalidArgumentError -ErrorId "UserNameHasInvalidCharachter" -ErrorMessage ($LocalizedData.InvalidUserName -f $UserName, [string]::Join(" ", $invalidChars))
    }
}

#########################################################################################################################################
# Throws an argument error.
#########################################################################################################################################
function ThrowInvalidArgumentError
{
    [CmdletBinding()]
    param
    (
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorMessage
    )

    $errorCategory=[System.Management.Automation.ErrorCategory]::InvalidArgument
    $exception = New-Object System.ArgumentException $ErrorMessage;
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $ErrorId, $errorCategory, $null
    throw $errorRecord
}

Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
