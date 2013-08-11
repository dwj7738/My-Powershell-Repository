# Tags alert with PrincipalName, Severity and MP name in Custom fields.
# Use in OpsMgr Command Shell.
# Original script from Marco Shaw.
# Changed by Stefan Stranger
# Date created 13-09-2008
$alerts = get-alert | where {$_.principalname -ne $null -and $_.resolutionstate -eq "0"}
foreach($alert in $alerts)
{
	$alert.CustomField1 = $alert.PrincipalName 
	$alert.CustomField2 = $alert.Severity 
	if ($alert.IsMonitorAlert -like 'False') 
	{
		$alert.CustomField3 = ((get-rule $alert.monitoringruleid).getmanagementpack()).displayname 
	} 
	else 
	{
		$alert.CustomField3 = ((get-monitor $alert.problemid).getmanagementpack()).displayname 
	} 
	$alert.Update("") 
}