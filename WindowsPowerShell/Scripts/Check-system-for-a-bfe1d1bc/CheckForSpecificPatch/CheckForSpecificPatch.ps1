$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

$servers = Get-Content servers.txt
$KBPatch = 'KB2858725'
#$KBPatch = 'KB2978092'

#write-host $KBPatch $LogFile $Installed

Foreach ($server in $servers)
{
	if (!(get-hotfix -id $KBPatch -computername $server -ErrorAction 0))	
		{ 
		write-host -ForegroundColor "green" "$server - $KBPatch - not installed"
		} Else {
		write-host -ForegroundColor "red" "$server - $KBPatch - installed"
		}
}