Function Remove-WUOfflineSync
{
    <#
	.SYNOPSIS
	    Unregister offline scaner service.

	.DESCRIPTION
	    Use Remove-WUOfflineSync to unregister Windows Update offline scan file (wsusscan.cab or wsusscn2.cab) from current machine.
                              		
	.EXAMPLE
        Remove-WUOfflineSync

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://code.msdn.microsoft.com/PSWindowsUpdate

	.LINK
        Get-WUServiceManager
        Add-WUOfflineSync
	#>

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="High"
    )]
    Param()
	
	Begin{}
	
	Process
	{
	    $objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
	    $State = 1
	    Foreach ($objService in $objServiceManager.Services) 
	    {
	        if($objService.Name -eq "Offline Sync Service")
	        {
	           	if ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"Unregister Windows Update offline scan file")) 
				{
					Try
					{
						$objServiceManager.RemoveService($objService.ServiceID)
					}
					catch
					{
			            if($_ -match "HRESULT: 0x80070005")
			            {
			                Write-Warning "Your security policy don't allow a non-administator identity to perform this task"
			            }
						else
						{
							Write-Error $_
						}
						
			            Return
					}
	            }
				Get-WUServiceManager
	            $State = 0;    
	        }
	   
	    }
	    
	    if($State)
	    {
	        Write-Warning "Offline Sync Service don't exist on current machine."
	    }
	}
	
	End{}
}