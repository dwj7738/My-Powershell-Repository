Function Add-WUOfflineSync
{
	<#
	.SYNOPSIS
	    Register offline scaner service.

	.DESCRIPTION
	    Use Add-WUOfflineSync to register Windows Update offline scan file. You may use old wsusscan.cab or wsusscn2.cab from Microsoft Baseline Security Analyzer (MSBA) or System Management Server Inventory Tool for Microsoft Updates (SMS ITMU).
    
	.PARAMETER Path	
		Path to Windows Update offline scan file (wsusscan.cab or wsusscn2.cab).
		
	.EXAMPLE
        Add-WUOfflineSync -Path C:\wsusscan.cab

        Name                  : Offline Sync Service
        ContentValidationCert : {}
        ExpirationDate        : 
        IsManaged             : False
        IsRegisteredWithAU    : False
        IssueDate             : 2011-01-21 18:52:08
        OffersWindowsUpdates  : True
        RedirectUrls          : System.__ComObject
        ServiceID             : 106dd315-adcb-44b6-9876-44725245ffa3
        IsScanPackageService  : True
        CanRegisterWithAU     : False
        ServiceUrl            : 
        SetupPrefix           : 
        IsDefaultAUService    : False

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://code.msdn.microsoft.com/PSWindowsUpdate
	
	.LINK
		http://msdn.microsoft.com/en-us/library/aa387290(v=vs.85).aspx
		http://support.microsoft.com/kb/926464

	.LINK
        Get-WUServiceManager
        Remove-WUOfflineSync
	#>
    
	[CmdletBinding(
        SupportsShouldProcess=$True,
        ConfirmImpact="High"
    )]
    Param
    (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
		$Path
    )

	Begin
	{
		$Name="Offline Sync Service" 
	}
	
    Process
	{
		if(-not (Test-Path $Path))
		{
			Write-Warning "Windows Update offline scan file don't exist in this path: $Path"
			Return
		}
		
        $objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
        Try
        {
            if ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"Register Windows Update offline scan file: $Path")) 
			{
				$objService = $objServiceManager.AddScanPackageService($Name,$Path,1)
			}
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
        $objService	
	}

	End{}
  
}
