<#
.SYNOPSIS
  Author:......Vidrine
  Date:........2012/04/08
.DESCRIPTION
  Script connects to a SQL database and runs a query against the specified table. Depending on table record values, 
  an Active Directory user object will have it's password reset.  Once, the account is reset the SQL record is updated.
  This SQL update is to prevent resetting the user object's password, again, and to store the password for use.
.NOTES
  Requirements:
  .. Microsoft ActiveDirectory cmdlets
  .. Microsoft SQL cmdlets
  
  Additionally:
  The script must be ran as account that has access to the database and access to 'reset passwords' within ActiveDirectory.
#>

##====================================================================================
## Load snapins and modules
##====================================================================================
add-pssnapin SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue
add-pssnapin SqlServerProviderSnapin100 -ErrorAction SilentlyContinue
Import-Module activeDirectory -ErrorAction SilentlyContinue

##====================================================================================
## Variables: SQL Connection
##====================================================================================
$sqlServerInstance = 'SERVER\INSTANCE' # ex. '.\SQLEXPRESS'
$sqlDatabase = 'DatabaseName'
$sqlTable = 'TableName'

##====================================================================================
## Variables: Password Creation/Reset Configuration
##====================================================================================
## File contains a list of 5-character words, 1 per line.
$word = Get-Content "C:\..\5CharacterDictionary.txt"
## List of allowed special characters for use
$special ='!','@','#','$','%','^','&','*','(',')','-','_','+','='
## Length of the random number
$nmbr = 4

##====================================================================================
## Variables: Log
##====================================================================================
$logFile = (Get-Date -Format yyyyMMdd) + '_LogFile.csv'
$logPath = 'C:\..\Logs'
$log = Join-Path -ChildPath $logFile -Path $logPath

##====================================================================================
## Functions
##====================================================================================
function Get-Timestamp {
	Get-Date -Format u
}

function Write-Log {
	param(
		[string] $Path,
		[string] $Value
	)

	$Value | Out-File $Path -Append
}

function Create-Password {
	## Generate random 4 digit integer.
	$NewString = ""
	1..$nmbr | ForEach { $NewString = $NewString + (Get-Random -Minimum 0 -Maximum 9) }

	## Select random 5-character word from wordlist
	$lowerWord = Get-Random $word

	## Normalize the selected word. Convert all to lowerCase and then convert third character to UPPERcase
	$firstLetters = $lowerWord.Substring(0,2)
	$upperLetters = $lowerWord.Substring(2,1).toUpper()
	$lastLetters = $lowerWord.Substring(3,2)
	$NewWord = $firstLetters + $upperLetters + $lastLetters

	## Select random special character from wordlist
	$NewSpecial = Get-Random $special

	## Combine selected word, random number, and special character to generate password
	$NewPassword = ($NewWord + $NewSpecial + $NewString)

	## Returns the newly created random string to the function
	return $NewPassword
}

Function Reset-Password {
	param (
		[string]$emailAddress,
		[string]$password
	)

	## Convert the password to secure string
	$password_secure = ConvertTo-SecureString $password -AsPlainText -Force

	## Query for the user based on email address; Resets the user account password with value from database
	try
	{
		Get-ADUser -Filter {emailAddress -like $emailAddress} | Set-ADAccountPassword -Reset -NewPassword $password_secure
		$Value = (get-timestamp)+"`tSUCCESS`tReset Password`tPassword reset completed for end user ($emailAddress)."
		Write-Log -Path $log -Value $Value
	}
	catch
	{
		$Value = (get-timestamp)+"`tERROR`tReset Password`tUnable to reset password ($emailAddress). $_"
		Write-Log -Path $log -Value $Value
	}
}

function Get-Username {
	param (
		[string]$emailAddress
	)

	try
	{
		$user = Get-ADUser -Filter {emailAddress -like $emailAddress}
		$Value = (get-timestamp)+"`tSUCCESS`tQuery Username`tDirectory lookup for username was successful ($emailAddress)."
		Write-Log -Path $log -Value $Value

		return $user.sAMAccountName
	}
	catch
	{
		$Value = (get-timestamp)+"`tERROR`tQuery Username`tDirectory lookup failed ($emailAddress). $_"
		Write-Log -Path $log -Value $Value
	}
}

function SQL-Select {
	<#
.EXAMPLE
$results = SQL-Select -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -selectWhat '*'
.EXAMPLE
$results = SQL-Select -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -selectWhat '*' -where "id='64'"
#>

	param(
		[string]$server,
		[string]$database,
		[string]$table,
		[string]$selectWhat,
		[string]$where

	)

	## SELECT statement with a WHERE clause
	if ($where){
		$sqlQuery = @"
SELECT $selectWhat 
FROM $table 
WHERE $where
"@
	}

	## General SELECT statement
	else {
		$sqlQuery = @"
SELECT $selectWhat 
FROM $table
"@
	}

	try
	{
		$results = Invoke-SQLcmd -ServerInstance $server -Database $database -Query $sqlQuery
		$Value = (get-timestamp)+"`tSUCCESS`tSQL Select`tDatabase query was successful (WHERE: $where)."
		Write-Log -Path $log -Value $Value

		return $results
	}
	catch
	{
		$Value = (get-timestamp)+"`tERROR`tSQL Select`tDatabase query failed (WHERE: $where). $_"
		Write-Log -Path $log -Value $Value
	}
}

function SQL-Update {
	<#
.EXAMPLE
SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID
#>
	param(
		[string]$server,
		[string]$database,
		[string]$table,
		[string]$dataField,
		[string]$dataValue,
		[string]$updateID
	)

	$sqlQuery = @"
UPDATE $database.$table 
SET $dataField='$dataValue' 
WHERE id=$updateID
"@

	try
	{
		Invoke-SQLcmd -ServerInstance $server -Database $database -Query $sqlQuery
		$Value = (get-timestamp)+"`tSUCCESS`tSQL Update`tUpdated database record, ID $updateID ($dataField > $dataValue)."
		Write-Log -Path $log -Value $Value
	}
	catch
	{
		$Value = (get-timestamp)+"`tERROR`tSQL Update`tUnable to update database record, ID $updateID ($dataField > $dataValue). $_"
		Write-Log -Path $log -Value $Value
	}
}

function Check-Status {
	$results = $NULL
	$results = SQL-Select -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -selectWhat 'id,email,pword,pwordSet,status' -where "(pwordSet IS Null OR pwordSet='') AND status='CheckedIn'"
	$results | ForEach {
		if ($_.pword.GetType().name -eq 'DBNull')
		{
			## Generate a new password for the end-user
			$password = Create-Password

			$sqlDataID = $_.id

			## Configure SQL statement to UPDATE the end-user 'pword'
			$sqlDataField = 'pword'
			$sqlDataValue = $password
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID

			## Reset the end-user's password
			Reset-Password -emailAddress $_.email -password $password

			## Configure SQL statement to UPDATE the end-user 'pwordSet'
			$sqlDataField = 'pwordSet'
			$sqlDataValue = 'Yes'
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID

			## Configure SQL statement to UPDATE the end-user 'samaccountname'
			$sqlDataField = 'samaccountname'
			$sqlDataValue = Get-Username -emailAddress $_.email
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID
		}
		elseif($_.pword -eq '')
		{
			## Generate a new password for the end-user
			$password = Create-Password

			$sqlDataID = $_.id

			## Configure SQL statement to UPDATE the end-user 'pword'
			$sqlDataField = 'pword'
			$sqlDataValue = $password
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID

			## Reset the end-user's password
			Reset-Password -emailAddress $_.email -password $password

			## Configure SQL statement to UPDATE the end-user 'pwordSet'
			$sqlDataField = 'pwordSet'
			$sqlDataValue = 'Yes'
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID

			## Configure SQL statement to UPDATE the end-user 'samaccountname'
			$sqlDataField = 'samaccountname'
			$sqlDataValue = Get-Username -emailAddress $_.email
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID
		}
		else 
		{
			Reset-Password -emailAddress $_.email -password $_.pword

			$sqlDataID = $_.id

			## Configure SQL statement to UPDATE the end-user 'pwordSet'
			$sqlDataField = 'pwordSet'
			$sqlDataValue = 'Yes'
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID

			## Configure SQL statement to UPDATE the end-user 'samaccountname'
			$sqlDataField = 'samaccountname'
			$sqlDataValue = Get-Username -emailAddress $_.email
			SQL-Update -server $sqlServerInstance -database $sqlDatabase -table $sqlTable -dataField $sqlDataField -dataValue $sqlDataValue -updateID $sqlDataID
		}
	}
	return $results
}

##====================================================================================
## Main script begins here
##====================================================================================
Check-Status