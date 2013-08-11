#Find out how many accounts we should delete ( I'll make this interogate UPS at some point in future
#for now this fudge will do
Param ([int]$limit)

if ($limit -eq 0)
{
	$limit = 999999999
}

$count = 1

write-host "------------- Started -------------"
$output = Get-Date
$output = "Started at " + $output.ToString()
$output | Out-File -FilePath c:\output.txt -append


#Add SharePoint PowerShell SnapIn if not already added
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
	Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
#Add Quest AD PowerShell SnapIn if not already added
if ((Get-PSSnapin "Quest.ActiveRoles.ADManagement" -ErrorAction SilentlyContinue) -eq $null) {
	Add-PSSnapin "Quest.ActiveRoles.ADManagement"
}


#Set my site host location. 
$site = new-object Microsoft.SharePoint.SPSite("http://mysites"); 
$ServiceContext = [Microsoft.SharePoint.SPServiceContext]::GetContext($site); 

#Get UserProfileManager and get all profiles
$ProfileManager = new-object Microsoft.Office.Server.UserProfiles.UserProfileManager($ServiceContext) 
$AllProfiles = $ProfileManager.GetEnumerator() 

#iterate around the profiles
foreach($profile in $AllProfiles) 
{
	#get the associated AD account
	$ADUser = $PROFILE.MultiloginAccounts | Get-QADUser

	#check if the account is diasabled in AD
	if ($ADUser.AccountIsDisabled)
	{
		#delete the profile
		$ProfileManager.RemoveUserProfile($ADUser.NTAccountName)
		$output = $count.ToString() + ": " + $ADUser.NTAccountName
		$output | Out-File -FilePath c:\output.txt -append
		write-host $output

		$count++
		if ($count -gt $limit)
		{
			break
		}
	} 
}

write-host "------------- Finished -------------"
write-host ($count -1) accounts removed
$output = Get-Date
$output = "Finished at " + $output.ToString()
$output | Out-File -FilePath c:\output.txt -append

$site.Dispose()