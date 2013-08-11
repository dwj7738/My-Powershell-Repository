####################################################################
#
#Script will list all selected workstations and currently logged on user.
#Results will be output to a file.  A query can be placed on a previous search.
#Currently script only works when run directly from a DC
#Author:  Adam Liquorish
#Date: 15/10/2011
####################################################################

$username = read-host "Enter username to query corresponding computer"
$infromfile = read-host "Would you like to just find a user-computer in an existing file.YES/NO"
if($infromfile -eq "No")
{
	$path = read-host "Enter path to save all files ie.c:\Temp\"
	$LDAPPath = read-host "Specify LDAP path ie ou=test,dc=domain,dc=com"
	$pathcomputers = $path + "computers.txt"
	$pathcompuserfull = $path + "compuserlistfull.txt"
	$pathresults = $path + "results.txt"

	#Get computers from a defined LDAP Path
	$dict = @()
	$computers = foreach(comp in (get-adcomputer -filter * -searchbase "$LDAPPath")){$comp.name}
	$computers>$pathcomputers
	write-host "List of computers scanned has been ouput to $pathcomputers"

	#Use list of computers to conduct a WMI lookup of logged on users
	foreach($comp in $computers)
	{
		$cs - gwmi win32_computersystem -comp $comp
		$dict += @{$cs.username=$cs.name}
	}
	$dict>$pathcompuserfull
	write-host "user to computerlist has been ouput to $pathcompuserfull"

	#Lookup user to computer list and find specified user
	$results = foreach($user in $dict)
	{
		if($user.keys -like "*$username")
		{
			new-object -typename psobject -property @{user=$user.keys;computer=$user.values}
		}
	}
	$results>$pathresults
	write-host "Results output to $pathresults"
	write-host "Results found are.." -foregroundcolor blue
	$results
}
else
{
	#Input user to computer list from a file and lookup specified user.
	$inpath = read-host "enter input folder path for file. Folder must contain a file called compuserlistfull.txt"
	$pathcompuserfullin = $inpath + "compuserlistfull.txt"
	$dict = @()
	$dict = get-content $pathcompuserfullin
	$results = foreach($user in $dict)
	{
		if($user -like "*$username*")
		{
			new-object -typename psobject -property @{user=$user}
		}
	}
	$results
}