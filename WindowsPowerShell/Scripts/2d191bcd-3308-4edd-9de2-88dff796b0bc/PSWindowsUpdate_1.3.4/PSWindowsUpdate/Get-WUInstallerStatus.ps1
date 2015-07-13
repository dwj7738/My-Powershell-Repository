Function Get-WUInstallerStatus
{
    <#
	.SYNOPSIS
	    Show Windows Update Installer status.

	.DESCRIPTION
	    Use Get-WUInstallerStatus to show Windows Update Installer status.
                              		
	.EXAMPLE
        Get-WUInstallerStatus
        
        Installer is ready.

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://code.msdn.microsoft.com/PSWindowsUpdate

	.LINK
        Get-WURebootStatus
	#>
	
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param()
	
	Begin{}
	
	Process
	{
        if ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"Check that Windows Installer is ready to install next updates")) 
		{	    
			$objInstaller=New-Object -ComObject "Microsoft.Update.Installer"
		    if($objInstaller.IsBusy)
		    {
		        Write-Host "Installer is busy."
		    }
		    else
		    {
		        Write-Host "Installer is ready."
		    }
		}
	}
	
	End{}	
}