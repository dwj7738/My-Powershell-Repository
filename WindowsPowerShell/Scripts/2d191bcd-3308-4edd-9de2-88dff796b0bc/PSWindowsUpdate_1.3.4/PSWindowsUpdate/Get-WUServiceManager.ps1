Function Get-WUServiceManager
{
	<#
	.SYNOPSIS
	    Show service manager configuration.

	.DESCRIPTION
	    Use Get-WUServiceManager to available configuration of update services.
                              		
	.EXAMPLE
        Get-WUServiceManager

        Name                  : Windows Update
        ContentValidationCert : {}
        ExpirationDate        : 5254-06-18 21:21:00
        IsManaged             : False
        IsRegisteredWithAU    : False
        IssueDate             : 2003-01-01 00:00:00
        OffersWindowsUpdates  : True
        RedirectUrls          : System.__ComObject
        ServiceID             : 9482f4b4-e343-43b6-b170-9a65bc822c77
        IsScanPackageService  : False
        CanRegisterWithAU     : True
        ServiceUrl            : 
        SetupPrefix           : 
        IsDefaultAUService    : True

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://code.msdn.microsoft.com/PSWindowsUpdate

	.LINK
        Add-WUOfflineSync
        Remove-WUOfflineSync
	#>

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param()
	
	Begin{}
	
	Process
	{
	    if ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"Get Windows Update ServiceManager")) 
		{
			$objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"

	    	Foreach ($objService in $objServiceManager.Services) 
	    	{
	    	    $objService 
	    	}
	    }		

	}
	
	End{}
	
}

