function Get-MySharePermissions
{
	param([string]$computername,[string]$sharename)
	$ShareSec = Get-WmiObject -Class Win32_LogicalShareSecuritySetting -ComputerName $computername
	ForEach ($ShareS in ($ShareSec | Where {$_.Name -eq $sharename}))
	{
		$SecurityDescriptor = $ShareS.GetSecurityDescriptor()
		$myCol = @()
		ForEach ($DACL in $SecurityDescriptor.Descriptor.DACL)
		{
			$myObj = "" | Select Domain, ID, AccessMask, AceTypeload
			$myObj.Domain = $DACL.Trustee.Domain
			$myObj.ID = $DACL.Trustee.Name
			Switch ($DACL.AccessMask)
			{
				2032127 {$AccessMask = "FullControl"}
				1179785 {$AccessMask = "Read"}
				1180063 {$AccessMask = "Read, Write"}
				1179817 {$AccessMask = "ReadAndExecute"}
				-1610612736 {$AccessMask = "ReadAndExecuteExtended"}
				1245631 {$AccessMask = "ReadAndExecute, Modify, Write"}
				1180095 {$AccessMask = "ReadAndExecute, Write"}
				268435456 {$AccessMask = "FullControl (Sub Only)"}
				default {$AccessMask = $DACL.AccessMask}
			}
			$myObj.AccessMask = $AccessMask
			Switch ($DACL.AceType)
			{
				0 {$AceType = "Allow"}
				1 {$AceType = "Deny"}
				2 {$AceType = "Audit"}
			}
			$myObj.AceType = $AceType
			Clear-Variable AccessMask -ErrorAction SilentlyContinue
			Clear-Variable AceType -ErrorAction SilentlyContinue
			$myCol += $myObj
		}
	}
	Return $myCol
}