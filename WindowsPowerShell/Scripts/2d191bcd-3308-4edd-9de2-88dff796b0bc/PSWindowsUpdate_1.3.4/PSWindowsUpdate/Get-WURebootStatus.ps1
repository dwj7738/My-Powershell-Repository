Function Get-WURebootStatus
{
    <#
	.SYNOPSIS
	    Show Windows Update Reboot status.

	.DESCRIPTION
	    Use Get-WURebootStatus to check if reboot is needed.
		
	.PARAMETER StatusOnly
	    Get only status True/False without any more comments on screen. 
	
	.EXAMPLE
        Get-WURebootStatus
        
        Reboot is NOT required

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://code.msdn.microsoft.com/PSWindowsUpdate

	.LINK
        Get-WUInstallerStatus
	#>    

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[Switch]$StatusOnly
	)
	
	Begin{}
	
	Process
	{
        if ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"Check that Windows update needs to restart system to install next updates")) 
		{	
		    $objSystemInfo= New-Object -ComObject "Microsoft.Update.SystemInfo"
		    if(!$StatusOnly)
			{
				Write-Host "Reboot status: "
		    }
			
			Return $objSystemInfo.RebootRequired
		}
	}
	
	End{}				
}