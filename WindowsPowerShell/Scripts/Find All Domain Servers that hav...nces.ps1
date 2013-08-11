param
(
	[string]$domain = "<default domainName>"
)

## ==================================================================================
## Title       : Find All Servers in a Domain With SQL
## Description : Get a listing of all servers in a domain, test the connection
##               then check the registry for MS SQL Server Info.
##				 Output(ServerName, InstanceName, Version and Edition).
##				 Assumes that instances of MS SQL Server can be found under:
##				 HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names
## Author      : C.Perry
## Date        : 10/2/2012
## Input       : -domain <fully.qualified.domainname>	
## Output      : List of SQL Server names
## Usage	   : PS> . FindAllServersWithSQL.ps1 -domain dev.construction.enet
## Notes	   :
## Tag		   : SQL Server, test-connection, ping, AD, WMI
## Change log  :
## ==================================================================================
# INITIALIZATION SECTION
cls

# Domain context
#$domain = $null
#$domain="<domainName>"

# Initialize variables and files
$dom = $null
$ErrorActionPreference = "Continue"
$found = $null
$InstNameskey = "SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names"
$RegInstNameKey = $null
$MSSQLkey = "SOFTWARE\Microsoft\Microsoft SQL Server"
$notfound = $null
#Output file goes into directory you execute from
$outfile = "$domain" + "_Servers_out.csv" 
$reg = $null
$regInstance = $null
$regInstanceData = $null
$regKey = $null
$root = $null
$SetupVersionKey = $null
$SQLServerkey = $null
$sbky = $null
$sub = $null
$type = [Microsoft.Win32.RegistryHive]::LocalMachine
"Server, Instance, Version, Edition" | Out-File $outfile
# Domain Initalization
# create the domain context object
$context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$domain)
# get the domain object
$dom = [system.directoryservices.activedirectory.domain]::GetDomain($context)
# Debug line #$dom 
# go to the root of the Domain
$root = $dom.GetDirectoryEntry()
#create the AD Directory Searcher object
$searcher = new-object System.DirectoryServices.DirectorySearcher($root)
#filter for all servers that do not start with "wde"
$filter = "(&(objectClass=Computer)(operatingSystem=Windows Server*) (!cn=wde*))"
$searcher.filter = $filter
# By default, an Active Directory search returns only 1000 items.
# If your domain includes 1001 items, then that last item will not be returned.
# The way to get around that issue is to assign a value to the PageSize property. 
# When you do that, your search script will return (in this case) the first 1,000 items, 
# pause for a split second, then return the next 1,000. 
# This process will continue until all the items meeting the search criteria have been returned.
$searcher.pageSize=1000
$colProplist = "name"
foreach ($j in $colPropList){$searcher.PropertiesToLoad.Add($j)}
# get all matching computers
$colResults = $searcher.FindAll()

# PROCESS Section
# interate through all found servers
foreach ($objResult in $colResults)
{	#Begin ForEach
	$objItem = $objResult.Properties
	[string]$Server = $objItem.name
	Try
	{
		IF (test-connection -computername $Server -count 1 -TimeToLive 4 -erroraction continue -quiet)
		{			#IfConnectionFound   	
			$found = $Server + " is pingable"
			#echo $found
			$InstanceNameskey = "SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names"
			$MSSQLkey = "SOFTWARE\Microsoft\Microsoft SQL Server"
			$type = [Microsoft.Win32.RegistryHive]::LocalMachine
			$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Server)
			$SQLServerkey = $null
			$SQLServerkey = $regKey.OpenSubKey($MSSQLkey)
			# Check to see if MS SQL Server is installed
			IF ($SQLServerkey)
			{				#Begin IF $SQLSERVERKEY	
				#DEBUG Write to Host "Sub Keys"
				#Write-Host
				#Write-Host "Sub Keys for $MSSQLkey"
				#Write-Host "--------"
				#Foreach($sbky in $SQLServerkey.GetSubKeyNames()){$sbky}
				$Instkey = $null
				$Instkey = $regKey.OpenSubKey($InstanceNameskey)
				# Check to see in chargeable Instances of MS SQL Server are installed
				IF ($Instkey)
				{
					#DEBUG Write-Host "Values" of SubKeys
					#Write-Host
					#Write-Host "Sub Keys for $InstanceNameskey"
					#Write-Host "------"
					#Foreach($sub in $Instkey.GetSubKeyNames()){$sub}
					foreach ($regInstance in $Instkey.GetSubKeyNames()) 
					{
						$RegInstNameKey = $null
						$SetupKey = $null
						$SetupKey = "$InstanceNameskey\$regInstance"
						$RegInstNameKey = $regKey.OpenSubKey($SetupKey)
						#Open Instance Names Key and get all SQL Instances
						foreach ($SetupInstance in $RegInstNameKey.GetValueNames()) 
						{
							$version = $null 
							$edition = $null
							$regInstanceData = $null
							$SetupVersionKey = $null
							$VersionInfo = $null
							$versionKey = $null
							$regInstanceData = $RegInstNameKey.GetValue($SetupInstance) 
							$SetupVersionKey = "$MSSQLkey\$regInstanceData\Setup"
							#Open the SQL Instance Setup Key and get the version and edition
							$versionKey = $regKey.OpenSubKey($SetupVersionKey)
							$version = $versionKey.GetValue('PatchLevel') 
							$edition = $versionKey.GetValue('Edition') 
							# Write the version and edition info to output file
							$VersionInfo = $Server + ',' + $regInstanceData + ',' + $version + ',' + $edition 
							$versionInfo | Out-File $outfile -Append 
						}#end foreach $SetupInstance
					}#end foreach $regInstance
				}#end If $instKey
				ELSE
				{					#Begin No Instance Found
					$found = $found + " but no chargable instance found."
					echo $found
				}#End No Instance Found
			}#end If $SQLServerKey
		}#end If Connectionfound
		ELSE
		{			#ELSE Connection Not Found
			$notfound = $Server + " not pingable"
			echo $notfound
		}
	}#endTry
	Catch
	{
		$exceptionType = $_.Exception.GetType()
		if ($exceptionType -match 'System.Management.Automation.MethodInvocation')
		{			#IfExc
			#Attempt to access an non existant computer
			$Wha = $Server + " - " +$_.Exception.Message
			write-host -backgroundcolor red -foregroundcolor Black $Wha 
		}#endIfExc
		if ($exceptionType -match 'System.UnauthorizedAccessException')
		{			#IfEx
			$UnauthorizedExceptionType = $Server + " Access denied - insufficent privileges"
			# write-host "Exception: $exceptionType"
			write-host -backgroundcolor red "UnauthorizedException: $UnauthorizedExceptionType"
		}#endIfEx
		if ($exceptionType -match 'System.Management.Automation.RuntimeException')
		{			#IfExc
			# Attempt to access an non existant array, output is suppressed
			write-host -backgroundcolor cyan -foregroundcolor black "$Server - A runtime exception occured: " $_.Exception.Message; 
		}#endIfExc
	}#end Catch
}#end ForEach servers in domain
#number of servers
$colResults.count