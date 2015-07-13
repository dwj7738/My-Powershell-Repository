Function Get-WUUninstall
{
    <#
	.SYNOPSIS
	    Uninstall update.

	.DESCRIPTION
	    Use Get-WUUninstall to uninstall update.
                              		
	.PARAM HotFixID	
		Update ID that will be uninstalled.
	
	.EXAMPLE
        Get-WUUninstall -HotFixID KB958830

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://code.msdn.microsoft.com/PSWindowsUpdate

	.LINK
        Get-WUInstall
        Get-WUList
	#>
	
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="High"
    )]
    Param
    (
        [parameter(Mandatory=$true)]
		[String]$HotFixID
    )

	Begin{}
	
	Process
	{
	    if ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"Uninstall update $HotFixID")) 
		{	    
			if($HotFixID)
		    {
		        $HotFixID = $HotFixID -replace "KB", ""

		        wusa /uninstall /kb:$HotFixID
		    }
		    else
		    {
		        wmic qfe list
		    }
		}
	}
	
	End{}	
}