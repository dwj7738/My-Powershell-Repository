<#
.SYNOPSIS
       The purpose of this script is to test if a user is in a particular role for a SQL server instance.
.DESCRIPTION
       The purpose of this script is to test if a user is in a particular role for a SQL server instance.
       It can be invoked in many different ways.
       Usage: .\Check-SQLServerUserInRole.ps1 [SQLServerName[\Instance]] [Domain\User] [-PrintList] [-And] [role1 [role2...]]

       ServerName defaults to localhost
       User defaults to current user

       Without any roles specified, the script returns an array of the roles the user is in.
       If you specify the -PrintList option, the script will not return anything, but print a complete list of roles and
       highlight the roles the user is in.
       If you specify one or more roles on the command line, the script will True or False depending on whether the user is
       in one of those roles or not. By default it will return TRue if the user is in role1 OR role2 OR role3 etc.
       You can use the -And switch to test for user in role1 AND role2 AND role3 etc.

       Please see the examples for ways to invoke this script.
.EXAMPLE
C:\> .\CheckSQLServerIsInRole.ps1 
List which roles the currently logged in user is in on a SQL server instance running on localhost.

C:\> .\CheckSQLServerIsInRole.ps1 
sysadmin
dbcreator

C:\> $a = .\CheckSQLServerIsInRole.ps1
C:\> $a -is [Array]
True
C:\> $a
sysadmin
dbcreator

.EXAMPLE
C:\> .\Check-SQLServerUserInRole.ps1 -PrintList 
Print a list of all the database roles the scripts checks and highlight the roles the user is in. Nothing is returned.

C:\> .\Check-SQLServerUserInRole.ps1 -PrintList 
[sysadmin] securityadmin serveradmin setupadmin processdmin diskadmin [dbcreator] bulkadmin

.EXAMPLE
C:\> .\Check-SQLServerUserInRole.ps1 somehost contoso\alfonso sysadmin dbcreator
Check if the user contoso\alfonso is in the sysadmin OR the dbcreator role on a SQL server instance running on the host somehost. Returns True or False.

C:\> .\Check-SQLServerUserInRole.ps1 somehost contoso\alfonso sysadmin dbcreator
True

.EXAMPLE
C:\> .\Check-SQLServerUserInRole.ps1 somehost contoso\alfonso -And diskadmin bulkadmin
Check if the user contoso\alfonso is in the sysadmin AND the bulkadmin role on a SQL server instance running on the host somehost. Returns True or False.

C:\> .\Check-SQLServerUserInRole.ps1 somehost contoso\alfonso -a diskadmin bulkadmin
False

.LINK
http://gallery.technet.microsoft.com/ScriptCenter
.NOTES
  File Name : Check-SQLServerUserInRole.ps1
  Author    : Frode Sivertsen

  Please check out the DownloadScripts script for a convenient way to download a collection of useful scripts:
  http://gallery.technet.microsoft.com/scriptcenter/b9fe96c4-9bf1-4d61-903b-5e6c2a65ec66

#>

param
 
(
	[switch]
	# Signifies that the script will print a list of all the roles it is testing for and highlight the roles the user is in.
	# In this case the script is not returning anything, it just prints to the screen
	$PrintList,
	
	[switch]
	# Only makes sense when you provide roles to test for on the command line. By default it will return True
	# if the user is in one of the roles (one OR the other). With this switch it will return true only if the user is in
	# all roles (role1 AND role2 And role3)
	$And,
	
	[string]
	# The SQL server host and instance we are connecting to. E.g: servername[\instance] Default: localhost
	$ServerString = "localhost",
	
	[string]
	# The SQL server login name we are testing for. e.g: domain\user  Default: current user
	$LoginName = "$env:USERDOMAIN\$env:USERNAME"
)

Function PrintRole {
	param([Microsoft.SqlServer.Management.Smo.Login]$login, [string]$role)

	if ( $login ) {

		if ( $login.IsMember($role) ) {
			# Write-Host -NoNewline -ForegroundColor black -BackgroundColor green "[$role]"
			Write-Host -NoNewline "[$role]"
		} else {
			Write-Host -NoNewline -ForegroundColor gray  $role
		}

		Write-Host -NoNewline " "
	}
}

# Load SQL server SMO
 
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null


$roles = "sysadmin", "securityadmin", "serveradmin", "setupadmin", "processdmin", "diskadmin", "dbcreator", "bulkadmin"

try {
	# Create an SMO connection to the instance
	$s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $ServerString

	$s.Logins | Out-Null     # Throws and exception if we cannot connect to the server

	# Check that login exists


	$login = [Microsoft.SqlServer.Management.Smo.Login] $s.Logins["$LoginName"] 

	if ( ! $login ) {
		Throw "The login $LoginName does not appear to be valid."
	}


	if ( $PrintList ) {

		foreach ($role in $roles) {
			PrintRole $login $role
		}

		Write-Host ""
	} elseif ( $args.Length -gt 0 ) {

		$Result = 0

		if ($And) { $Result = 1 }
		
		foreach ($arg in $args) {
			if ( ! ($roles -contains $arg) ) {
				Throw "$arg is not a valid role!"     # TODO: Give hint for how to see valid roles
			}

			if ($And) {
				$Result = $login.IsMember($arg) -and $Result
			} else {
				$Result = $login.IsMember($arg) -or $Result
			}
		}

		Write-Output $Result
		
	} else {
		$myroles = @()

		foreach ($role in $roles) {
		
			if ($login.IsMember($role)) {
				$myroles += $role
			}
		}
		

		Write-Output $myroles
	}
	
}
catch [Exception] {
	Write-Error -Message $_.Exception.Message -Category InvalidArgument
	exit 1
	#write-host $_.Exception.Message; 
}


