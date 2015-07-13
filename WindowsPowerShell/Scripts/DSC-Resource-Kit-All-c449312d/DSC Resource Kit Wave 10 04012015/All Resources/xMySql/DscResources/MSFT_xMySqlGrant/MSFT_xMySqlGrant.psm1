#########################################################################################################################################
# xMySqlGrant resource for granting user permission(s) to mySql database
#########################################################################################################################################


#constants
$MySQLExePath = "$env:ProgramFiles\mySql\Mysql Server 5.6\bin\mysql.exe"

# A global variable that contains localized messages of MySqlGrant.
data LocalizedData
{
# culture="en-US"
ConvertFrom-StringData @'
GrantCreated=Grant {0} for user {1} created successfully.
GrantRemoved=Grant {0} for user {1} removed successfully.
InvalidUserName=The name {0} does not exist.
InvalidPermissionType=The permission type {0} cannot be used.
GrantExists=A user with the name {0} exists.
GrantDoesNotExist=A user with the name {0} does not exist.
'@
}

Import-LocalizedData LocalizedData -FileName MSFT_xMySqlGrant.strings.psd1

#########################################################################################################################################
# Set-MySqlPwdEnvironmentVariable ([pscredential] $RootPassword). Given the input root password, set the MySQL password environment variable
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
# Get-TargetResource ([string]$UserName, [string]DatabaseName, [string]Ensure, [string]ConnectionCredential, [string]$PermissionType) : given the username
# determine what grants/permissions are given in which database and tables
#########################################################################################################################################

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
       [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $UserName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName = "*",
      
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",  
       
        [parameter(Mandatory = $true)]
        [pscredential] $ConnectionCredential,


        [ValidateSet("ALL PRIVILEGES", "CREATE", "DROP", "DELETE", "INSERT", "SELECT", "UPDATE", "EXECUTE")]
        [string] $PermissionType = "ALL PRIVILEGES"
    )
    
    $Ensure = "Absent"
    $output = "$env:SystemDrive/ProgramData/MySQL/permissionlog.txt"      
    $grant = $PermissionType
    $grant+= "_priv"
    Set-MySqlPwdEnvironmentVariable -RootPassword $ConnectionCredential 

    if ((Test-Path -Path $MySQLExePath))
    {
        # mysql does not have an individual flag for ALL, it stores it as set of all other flags such as create, drop, execute..
        if ($PermissionType -ne "ALL PRIVILEGES" )
        {
            $result = &"$MySQLExePath" "--execute=select $grant from mysql.user where user = '$UserName' into outfile '$output';" --user=root --silent

            $permission = Get-content $output
            if ($permission -eq $null)
             {
                $msg = "$($LocalizedData.InvalidUserName) -f $UserName"
                Write-Verbose -Message $msg
             }
            else
             {
                if($permission.Contains('Y'))
                {
                    $msg = "$($LocalizedData.GrantExists) -f $PermissionType for user $UserName"
                    Write-Verbose -Message $msg
                    $Ensure = "Present"
                }
                else
                {
                    $msg = "$($LocalizedData.GrantDoesNotExist) -f $PermissionType for user $UserName"
                    Write-Verbose -Message $msg
                }
             }
         }
         else
         {
            #need to check every permission flag
            $allFlags = "CREATE", "DROP", "DELETE", "INSERT", "SELECT", "UPDATE", "EXECUTE"
            foreach( $flag in $allFlags)
            {
                $grant = $flag
                $grant+= "_priv"
                $result = &$MySQLExePath "--execute=select $grant from mysql.user where user = '$UserName' into outfile '$output';" --user=root --silent
                $permission = Get-content $output
                if(($permission -eq $null) -or ($permission.Contains('N')) )
                {
                    $Ensure = "Absent"
                    $msg = "$($LocalizedData.GrantDoesNotExist) -f $flag for user $UserName"
                    Write-Verbose -Message $msg                    
                    break
                }
                else
                {
                    $Ensure = "Present"                    
                    $msg = "$($LocalizedData.GrantExists) -f $flag for user $UserName"
                    Write-Verbose -Message $msg 
                    #mysql fails to save into a file that already exists so deleting it here
                    Remove-Item -Path $output -Force -ErrorAction SilentlyContinue
                }
            
            }
                            
         }#end of all flags check
        
          Remove-Item -Path $output -Force -ErrorAction SilentlyContinue
    }

    return @{
        UserName = $UserName
        DatabaseName = $DatabaseName
        Ensure = $Ensure
        PermissionType = $PermissionType
    }
}

#########################################################################################################################################
# Test-TargetResource ([string]$UserName, [string]DatabaseName, [string]Ensure, [string]ConnectionCredential, [string]$PermissionType) : given the username: determine whether the given user name exists in mysql user list using the root password
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
        $UserName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName = "*",
      
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",  
       
        [parameter(Mandatory = $true)]
        [pscredential] $ConnectionCredential,


        [ValidateSet("ALL PRIVILEGES", "CREATE", "DROP", "DELETE", "INSERT", "SELECT", "UPDATE", "EXECUTE")]
        [string] $PermissionType = "ALL PRIVILEGES"
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
# Set-TargetResource ([string]$UserName, [string]DatabaseName, [string]Ensure, [string]ConnectionCredential, [string]$PermissionType) : given the username: Add the given user name to mysql user list using the root password
#########################################################################################################################################


function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $UserName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DatabaseName = "*",
      
        [ValidateSet("Present", "Absent")]
        [string] $Ensure = "Present",  
       
        [parameter(Mandatory = $true)]
        [pscredential] $ConnectionCredential,

        
        [ValidateSet("ALL PRIVILEGES", "CREATE", "DROP", "DELETE", "INSERT", "SELECT", "UPDATE", "EXECUTE")]
        [string] $PermissionType = "ALL PRIVILEGES"
    )
    
    if((Test-TargetResource @psboundparameters))
    {
        return
    }
            
    Set-MySqlPwdEnvironmentVariable -RootPassword $ConnectionCredential 
    $HostName = "localhost"

    $SqlUser = "`'$UserName`'@"
    $SqlUser+="`'$HostName`'"

    if($Ensure -eq "Present")
    {        
        Write-Verbose "$MySQLExePath grant $PermissionType on $DatabaseName.* To $SqlUser;  --user=root --silent"
                   
        $result = &"$MySQLExePath" "--execute=grant $PermissionType on $DatabaseName.* To $SqlUser;" --user=root --silent

        $serialize = &"$MySQLExePath" "--execute=FLUSH PRIVILEGES;"  --user=root --silent

        $msg = "$($LocalizedData.GrantCreated) -f $UserName"
        Write-Verbose -Message $msg         
    }
    else
    {        
        Write-Verbose "$MySQLExePath revoke $PermissionType on $DatabaseName.* from $SqlUser --user=root --silent"

        $result = &"$MySQLExePath" "--execute=revoke $PermissionType on $DatabaseName.* from $SqlUser;" --user=root --silent
        #save the changes into mysql
        $serialize = &"$MySQLExePath" "--execute=FLUSH PRIVILEGES;" --user=root --silent

        $msg = "$($LocalizedData.GrantRemoved) -f $UserName"
        Write-Verbose -Message $msg   
    }
}

Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
