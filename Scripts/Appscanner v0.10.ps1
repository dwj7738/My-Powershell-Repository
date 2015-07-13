#######################
#Appscanner V0.10
#Author Adam Liquorish
#Creation Date 08/11/11
#Change log:
#    14/11/11 Removed unrequired step
#    02/12/11 Created input choice for domain.local,cached rather than auto determine
#    02/12/11 Added all supported filetypes for applockers ".bat",".cmd",".dll",".exe",".js",".msi",".msp","ocx",".psq",".vbs"
#    09/12/11 Implemented try/catch to capture file not found or access denied errors for outputting files
#
#Syntax
#appscanner -path <path> -user <user> -applockerpolicy <local/path> -outputpath <path> -userstatus <domain,local,cached> -logdirectory <path>
#    
#Example
#appscanner -path "C:\Program Files" -user "adam" -applockerpolicy "local" -outputpath "c:\temp\output.html" -userstatus "local" -logdirectory "c:\temp\"
#######################
######Define Parameters

param(
	[Parameter(Mandatory=$true,
		HelpMessage="Enter Path to be processed.")]
	[ValidateNotNullOrEmpty()]
	[string]$path,
	[Parameter(Mandatory=$true,
		HelpMessage="Enter User to be processed, as either builtin\<user> or <domain>\<user>.")]
	[ValidateNotNullOrEmpty()]
	[string]$user = $(Read-Host -prompt "User"),
	#Uncomment when in production version.
	[Parameter(Mandatory=$true,
	HelpMessage="Enter Applocker XML to be utilised ie c:\applocker.xml, or type local to use effective policy for workstation")]
	[ValidateNotNullOrEmpty()]
	[string]$applockerpolicy = $(Read-Host -prompt "Path to applocker policy xml file, or type local to use effective policy for workstation"),
	[Parameter(Mandatory=$true,
	HelpMessage="Enter Path for ouput ie c:\Temp\output.html.")]
	[ValidateNotNullOrEmpty()]
	[string]$outputpath = $(Read-Host -prompt "Path for Output"),
	[Parameter(Mandatory=$true,
	HelpMessage="Is the user a Domain/Local/Cached User.[Domain,Local,Cached]")]
	[ValidateNotNullOrEmpty()]
	[ValidateSet("Domain","Local","Cached")]
	[string]$UserStatus = $(Read-Host -prompt "Is the user a Domain/Local/Cached User.[Domain,Local,Cached]"),
	[Parameter(Mandatory=$true,
	HelpMessage="Enter Log Directory for ouput ie c:\Temp\")]
	[ValidateNotNullOrEmpty()]
	[string]$logdirectory = $(Read-Host -prompt "Log Directory")
)

######END DEFINE PARAMETERS   
######Define Logger
$logfilename = "$(get-date -format yyyy-MM-dd-hh-mm-ss).txt" 
$logfile = $logdirectory + $logfilename
if ($Host.name -match 'ise') {
	write-host "Warning: Running in Windows Powershell ISE, Transcript logging will not be running" -foregroundcolor red
	$null
	}
else {
	write-host "Running in Powershell Console, Transcript logging will now start" -foregroundcolor blue
	try{
		start-transcript -path $logfile
		}

#catch for if path not found
	catch [System.IO.DirectoryNotFoundException]{
		write-host "Critical: Parent Path to save $logfile not found." -foregroundcolor red
		read-host "Press enter to exit"
		}

	#catch for path access denied
	catch [System.Management.Automation.RuntimeException]{
		write-host "Critical: Write access to $logfile is denied unable to save log file." -foregroundcolor red
		read-host "Press enter key to exit"
		}
	}
###### END Logger
######Define Variables

$ticksymbol = [char]10004
$errorsymbol = [char]10008
$asterisksymbol = [char]10033
$dict = @{}
$t = $null
$hashtable = $null
$u = $null
$Pathvalid = test-path $path
$Pathvalidpolicy = test-path $applockerpolicy
$direct = $null
$inherited = $null
######END DEFINE VARIABLEs
######Define HTML Output
$a = "<style>"
$a = $a +"TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a +"TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
$a = $a +"TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;}"
$a = $a +"</style>"
$header = "<h1>List of Processed Files</h1>"
######END DEFINE HTML OUTPUT
######Testing Privileges
#$currentprincipal=new-object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
#& {
#    if ($currentprincipal.isinrole( [Security.principal.windowsbuiltinrole]::Administrator))
#    {
#        write-host "$ticksymbol Running with administrative privilages" -foregroundcolor blue
#    }
#    else
#    {
#        write-host "$errorsymbol Script is currently not running with administrative privileges, please run as admin" -foregroundcolor red
#        read-host "Press enter to exit" -foregroundcolor red
#        exit
#    }
#  }
######END TESTING PRIV
######Importing Required Modules
try {
	if((get-wmiobject -cl win32_operatingsystem).version -gt "6") {
		write-host "$ticksymbol Win Vista or higher detected, Importing Applocker Module" -foregroundcolor blue
		if((get-module -listavailable|foreach-object {$_.name}) -contains "applocker") {
			import-module applocker
			write-host "Successfully imported applocker module" -foregroundcolor blue
			}
		else {
			write-host "Critical: Applocker module cannot be found try logging in as administrator" -foregroundcolor red
			read-host "Press enter to quit"
			exit
		}
	}
	else {
		"Critical: $errorsymbol Exiting....An operating system lower that Windows Vista has been detected.  Script can only be run on Vista or higher."
		read-host "Press Enter key to exit"
		exit
		}
	}

	catch {
		write-host "Critical: Error encountered loading applocker module" -foregroundcolor red
		read-host "Press Enter key to exit"
		exit
	}

######END IMPORT MODULES
######MAIN
if ($Pathvalid -eq "True")
#If Path Valid
	{
	if ($applockerpolicy -eq "local")
	#Output effective local applied applocker policy
	{
	#Determine whether an applocker policy is in effect on workstation
		if((get-applockerpolicy -effective -xml ) -like "*Rule*")
			{
			write-host "$ticksymbol A valid Applocker Policy is currently applied to this workstation" -foregroundcolor blue
			write-host "Warning: A path is required to save local applied applocker policy for usage" -foregroundcolor red
			$applockerpolicy = read-host "Enter path, ie c:\temp\applockerpolicy.xml" 
			write-host "$asterisksymbol Effective applied Applocker Policy for this workstation has been selected, policy will be output to $applockerpolicy" -foregroundcolor blue
			#Effective Applocker policy output
			try{
				get-applockerpolicy -effective -xml >$applockerpolicy
				}
			#catch for if path not found
			catch [System.IO.DirectoryNotFoundException]{
				write-host "Critical: Parent Path to save $applockerpolicy not found." -foregroundcolor red
				read-host "Press enter to exit"
				}

			#catch for path access denied

			catch [System.Management.Automation.RuntimeException]{
				write-host "Critical: Write access to $applockerpolicy is denied unable to export policy." -foregroundcolor red
				read-host "Press enter key to exit"
				}

			}
		else {
			write-host "Critical: $errorsymbol Exiting....An applocker policy has not been applied to this workstation" -foregroundcolor red
			read-host "Press Enter key to exit"
			exit
		}
	}
	elseif ($Pathvalidpolicy -eq "True") {
		write-host "$ticksymbol Valid XML file supplied for Applocker Policy" -foregroundcolor blue
		}
		else {
		write-host "Critical: $errorsymbol Exiting....Invalid path for applocker policy xml file, File Doesn't exist!" -foreground red
		read-host "Press Enter key to exit"
		exit
		} 
	#Stage 1 Find group membership for user
	$starttime = get-date
	"Stage 1 of 7, Enumerating Groups User is a member of, including inherited groups"
	#Load .Net Assembler
	add-type -AssemblyName System.DirectoryServices.AccountManagement
	$domain = (Get-wmiobject Win32_ComputerSystem).Domain
	$ping = new-object system.net.networkinformation.ping
	#Function for finding group membership for only local or domain not a cached user!!! 
	function groupfind 
		{
		#Create objects to filter based on group name and ContextType--Domain or Machine
		$principal = new-object System.DirectoryServices.AccountManagement.PrincipalContext $ctype,$domain
		$idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName
		$groupPrincipal = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($principal, $idtype, $user)
		#Recursively find what groups the user is a member of
		#Also assigns groups found to a global variable called groupout
		set-variable -name groupout -value $groupprincipal.GetAuthorizationGroups() -scope global
		}
	#END FUNCTION

	#Determine if workstation is part of a domain or just local.
	if($userstatus -eq "Domain")
	{
		try {
			$domainName = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain() | select -ExpandProperty Name
			$isDomain = $domainName -match $domain
			$domain =$domainname
			write-host "Workstation is part of a domain" -foregroundcolor blue
			#Determine if domain controller is contactable if not contactable treat workstation as local and use local account information
			if ($ping.send(([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).pdcroleowner.name).status -eq "Success")
			{
				$ctype = [System.DirectoryServices.AccountManagement.ContextType]::Domain
				write-host "Successfully contacted Domain controller, using Domain account information." -foregroundcolor blue
				#calls function groupfind
				groupfind
			}
			else {
				write-host "Critical: Domain Controller not contactable!" -foregroundcolor red
				read-host "Press Enter key to exit"
				exit
				}
		}
		catch {
			write-host "Critical: Computer is not part of a domain" -foregroundcolor red
			read-host "Press Enter key to exit"
			exit
			}
	}

	elseif($userstatus -eq "Local")
	{
		#Build list of local users
		$computername = "$env:computername"
		$computer = [ADSI]"WinNT://$computername,computer"
		$localuserlist = $computer.psbase.children|where-object {$_.psbase.schemaclassname -eq 'user'}
		$localuserlistfilt = foreach($useritem in $localuserlist){$useritem.name}
		#Check queried user against list to see whether user is local
		if($localuserlistfilt -contains $user) {
			write-host "Verified user is a part of local SAM database" -foregroundcolor blue
			$domain = (Get-wmiobject Win32_ComputerSystem).Name
			$ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
			#Calls function groupfind
			groupfind
			}
		else {
			write-host "Critical: User is not a local user" -foregroundcolor red
			read-host "Press Enter key to exit"
			exit
		}
	}
	elseif($userstatus -eq "Cached") {
		try {
			#Build list of local users
			$computername = "$env:computername"
			$computer = [ADSI]"WinNT://$computername,computer"
			$localuserlist = $computer.psbase.children|where-object {$_.psbase.schemaclassname -eq 'user'}
			$localuserlistfilt = foreach($useritem in $localuserlist){$useritem.name}
			#Check queried user against list to see whether user is local
			if($localuserlistfilt -contains $user) {
				write-host "Critical: User is a part of local SAM database, therefore user is not cached." -foregroundcolor red
				read-host "Press Enter key to exit"
				exit
				}
			else {
				#Check queried user matches logged on user"
				if((gwmi win32_computersystem).username -like "*$user") {
					write-host "Verified user is a cached user" -foregroundcolor blue
					$groupout = [system.security.principal.windowsidentity]::getcurrent().groups|foreach-object {$_.translate([system.security.principal.ntaccount])}
					}
				else {
					write-host "Critical: Logged on user doesn't match queried user, therefore User is not a cached user" -foregroundcolor red
					read-host "Press Enter key to exit"
					exit
				}
			} 
		}
		catch {
			write-host "Critical: User is not cached" -foregroundcolor red
			read-host "Press Enter key to exit"
			exit
		}
	}
	else {
		write-host "Critical: Please use Local,Domain or Cached" -foregroundcolor red
		read-host "Press Enter key to exit"
		exit
		}

	"Stage 1 of 7, Finished Scanning Group Membership"
	"Stage 1 of 7, Outputting Group Membership hierarchy"
	#Add user to variable
	$groupfilter = @($user)
	#Filter group properties down to name string
	$groupfilter += foreach($groupname in $groupout){$groupname.name}
	#Determine direct membership
	$domaincut = $domain -match "\w+[A-Za-z0-9-]+"
	$domaincutvalue = $matches.values
	$query = "ASSOCIATORS OF {Win32_Account.Name='$user',Domain='$domaincutvalue'} WHERE ResultRole=GroupComponent ResultClass=Win32_Account"
	$directmembership = get-wmiobject -query $query
	$directmembershipresults = foreach($directmember in $directmembership){$directmember.name}
	$directmembershipresultsfiltered = $directmembershipresults|select-object -unique
	"#####################################################"
	write-host "#Green is for the username," -foregroundcolor darkgreen -nonewline; write-host "Red is for direct group membership," -foregroundcolor red -nonewline; write-host "Blue is for the inherited group membership" -foregroundcolor blue
	"#User $user group structure looks like the following;"
	foreach ($group in $groupfilter){
		if($directmembershipresultsfiltered -contains $group){
			$direct += @($group)}
		elseif($group -eq $user){
			$null}
		else{$inherited += @($group)}
	}
	#Display user
	write-host "-$user" -foregroundcolor darkgreen
	#Display direct membership
	foreach($member in $direct){
		write-host "->$member" -foregroundcolor red
		}
	foreach($member in $inherited){
		write-host "-->$member" -foregroundcolor blue
		}
	"#####################################################"
	"Stage 1 of 7 Complete"
	#End Stage 1
	#Stage 2 Recurse found items to variable
	$count = 0
	"Stage 2 of 7 $path is populating a variable "
	Get-Childitem $path -recurse -outvariable objects|where-object{write-progress "Stage 2 of 7 Recursing items to variable, Examining $($_.fullname)...." "Found  $count items";"$($_.fullname)"}|foreach-object {$count++}
	"Stage 2 of 7 $path has been populated into a variable"
	#End Stage 2
	#Stage 3 FILTERACL
	"Stage 3 of 7 Processing ACL on files to index"
	$max = $objects.length
	#filter variable
	$filteracl ={$groupfilter -like $_.IdentityReference.value.split("\")[1] -and ($_.FileSystemRights -band 131241 -or $_.FileSystemRights -band 278)}
	#Filter and add to new property
	foreach ($i in $objects){
		$dict[$i.fullname]=@{user="";Permission=""} 
		$t++
		$i.GetAccessControl().Access |where $filteracl|foreach {$dict.($i.Fullname).User+=($_.IdentityReference,",");$dict.($i.Fullname).Permission=$_.FileSystemRights} 
		Write-Progress -activity "Stage 3 of 7 Processing File Permissions to index" -status "$t of $max" -PercentComplete (($t / $objects.count)*100) -CurrentOperation $i.fullname 
		}
	"Stage 3 of 7 Complete"
	#END STAGE 3
	#Stage 4 Remove Duplicate identities
	"Stage 4 of 7 Removing duplicate identities"
	#Zeroise write-progress counter
	$t = $null
	#Remove duplicate identities due to listing of inherited groups in ACL
	foreach ($i in $objects) {
		$t++
		$identarray = $dict[$i.fullname].user;$dict[$i.fullname].user=$null;$splitidentarray = $identarray -split ",";$uniqueidentarray = $splitidentarray|sort-object -unique;$uniqueidentarray -join ","|foreach {$dict.($i.fullname).User+=($_)}
		Write-Progress -activity "Stage 4 of 7 Removing Username/Group Duplicates" -status "$t of $max" -PercentComplete (($t / $objects.count)*100) -CurrentOperation $i.fullname 
		}
	"Stage 4 of 7 Complete"
	#END STAGE 4
	#Stage 5 APPLOCKER
	"Stage 5 of 7 Processing Applocker policy on files"
	#Applocker file extensions list
	$Applockerfileextlist = ".bat",".cmd",".dll",".exe",".js",".msi",".msp","ocx",".psq",".vbs"
	$userpol = $objects|where {$Applockerfileextlist -contains $_.Extension}|convert-path|test-applockerpolicy $applockerpolicy -User $user
	$userobjpol = $userpol|select-object PolicyDecision,FilePath,MatchingRule
	$userobjpolcount = 0
	$userobjpol|foreach {
		$userobjpolcount++
		$dict[$_.FilePath] += @{ PolicyDecision = $_.PolicyDecision;MatchingRule= $_.MatchingRule}
		Write-progress -activity "Stage 5 of 7 Processing AppLockers results:" -status "$userobjpolcount of $($userobjpol.count)" -PercentComplete (($userobjpolcount / $userobjpol.count)*100) -CurrentOperation $_
	}
	"Stage 5 of 7 Complete"
	#END STAGE 5
	#Stage 6
	"Stage 6 0f 7 Preparing format of results for html Report"
	$max2 = $dict.count
	$hashtable = foreach($j in $dict.keys){
		$u++
		New-Object -TypeName PSObject -Property @{Path=$j
			User=$dict.$j.user
			Permission=$dict.$j.Permission
			MatchingRule=$dict.$j.MatchingRule
			PolicyDecision=$dict.$j.PolicyDecision
		}
		Write-Progress -activity "Stage 6 of 7 Processing Dictionary to properties" -status "$u of $max2" -PercentComplete (($u / $max2)*100) -CurrentOperation $_}
	"Stage 6 of 7 Complete, $u files scanned of $max for Applocker scan"
	#END STAGE 6
	#####END MAIN 
	#####RESULTS
	#OUTPUT RESULTS TO FILE
	"Stage 7 of 7 Outputting to file $outputpath"
	try{
		$hashtable|sort-object Path|ConvertTo-Html -head $header -title "ACL List" -body $a|Set-Content $outputpath
	}
	#catch for if path not found
	catch [System.IO.DirectoryNotFoundException]{
		write-host "Critical: Parent Path to save $outputpath not found." -foregroundcolor red
		read-host "Press enter to exit"
	}
	#catch for path access denied
	catch [System.Management.Automation.RuntimeException]{
		write-host "Critical: Write access to $outputpath is denied unable to export results." -foregroundcolor red
		read-host "Press enter key to exit"
		}
	#Display results
	$endtime = get-date
	$totaltime = $endtime - $starttime
	$totaltimehours = $totaltime.hours
	$totaltimeminutes = $totaltime.minutes
	$outputsize = get-item "$outputpath"|foreach {echo($_.length/1mb).tostring("0.00 MB")}
	"Stage 7 of 7, Scanned $max files of $path is complete in $totaltimehours hours and $totaltimeminutes minutes, $outputpath is $outputsize."
	#####END RESULTS
	#####Zeroise variables and unrequired files
	#Stop Logging
	if ($Host.name -match 'ise') {
		$null
		}
	else {
		"Running Log output to $logfile"
		stop-transcript >$null
		}
	#Prompt delete applocker policy
	$delete = read-host -prompt "Would you like the Applocker policy file $applockerpolicy deleted,YES/NO"
	if($delete -eq "yes") {
		del $applockerpolicy
		}
	else {
		write-host "Warning: $asterisksymbol You chose not to delete file $applockerpolicy, Application will now exit....." -foregroundcolor red
		read-host "Press Enter key to exit"
	}
}
#If Path invalid
else
{
	write-host "Critical: $errorsymbol Exiting...Invalid path supplied for processing" -foregroundcolor red
	read-host "Press Enter key to exit"
	exit
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1lRusQRPIwAE3OJgzVPpl2Po
# j7ygggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFD+b6HryR7g4/60I
# p9T22HHPAGAbMA0GCSqGSIb3DQEBAQUABIIBADjHsHXJv/erIuCKR+KTfQS4eKlI
# 6Pi9vro6kbWyKdRawpoHz3B/KI7PEtoPnzBnACnBlXAwDcIrSoGzaMbkBU2ed2n8
# 299n84T3sH4W382j9olpNeUbi4pe+8LdiKTPkcDC5hNEjk/79mdpuc3XVnYsPjrd
# QHLmbGbNPVUAGlocBAGCopCbHhA/v6Ng42RzQ4XiaMN+Ub4fRGlDtDzQg4LrFDEp
# T7xyXpHcKmFQLjMIcrZUyCjRJp+WboilIMZTfCJnMNVYkQiyTf6vkkumIk1hDKmU
# dd8tqQBCR030l+7w4Yg1/o3Or7CH2fLeiN/Pjn/t2V39Ex7LdR3xp/RxH74=
# SIG # End signature block
