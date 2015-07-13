Function Get-WURebootStatus
{
    <#
	.SYNOPSIS
	    Show Windows Update Reboot status.

	.DESCRIPTION
	    Use Get-WURebootStatus to check if reboot is needed.
		
	.PARAMETER Silent
	    Get only status True/False without any more comments on screen. 
	
	.EXAMPLE
        Check whether restart is necessary. If yes, ask to do this or don't.
		
		PS C:\> Get-WURebootStatus
		Reboot is required. Do it now ? [Y/N]: Y
		
	.EXAMPLE
		Silent check whether restart is necessary. It return only status True or False without restart machine.
	
        PS C:\> Get-WURebootStatus -Silent
		True
		
	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc

	.LINK
        Get-WUInstallerStatus
	#>    

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param
	(
		[Alias("StatusOnly")]
		[Switch]$Silent
	)
	
	Begin{}
	
	Process
	{
        If ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"Check that Windows update needs to restart system to install next updates")) 
		{	
		    $objSystemInfo= New-Object -ComObject "Microsoft.Update.SystemInfo"
			
			Switch($objSystemInfo.RebootRequired)
			{
				$true	{
					If($Silent) 
					{
						Return $true
					} #End If $Silent
					Else 
					{
						$Reboot = Read-Host "Reboot is required. Do it now ? [Y/N]"
						If($Reboot -eq "Y")
						{
							Restart-Computer
						} #End If $Reboot -eq "Y"
					} #End Else $Silent
				} #Ens Switch $true
				
				$false	{ If($Silent) {Return $false} Else {Write-Output "Reboot is not Required."}}
			} #End Switch $objSystemInfo.RebootRequired

		} #End If $pscmdlet.ShouldProcess($Env:COMPUTERNAME,"Check that Windows update needs to restart system to install next updates")
	} #End Process
	
	End{}				
} #In The End :)