Function Get-WUList
{
	<#
	.SYNOPSIS
	    Get list of available updates.

	.DESCRIPTION
	    Use Get-WUList to get list of available or installed updates.
	       
	.PARAMETER KBArticleID
	    More info about specyfic update.

	.PARAMETER IsInstalled
	    Get installed updates. Similar Get-WUHistory.

	.PARAMETER ServiceID
	    Set ServiceID to check updates.
		
	.PARAMETER MicrosoftUpdate
	    Set Microsoft Update as source. Default update config are taken from computer policy.
	
	.PARAMETER StatusOnly
	    Get only list of updates without any more comments on screen. 
		
	.EXAMPLE
        Get-WUList
		Connecting to Windows Server Update Service. Please wait...
		Found 4 updates to install.
		(Status list: D - IsDownloaded, I - IsInstalled, M - IsMandatory, H - IsHidden, U - IsUninstallable, B - IsBeta)

        Status                        LastDeploymentChangeTime      KBArticleIDs                  Title
		------                        ------------------------      ------------                  -----
        ------               		  2011-03-14 00:00:00           KB2488113                     Aktualizacja dla systemu W...
		------                        2011-03-14 00:00:00           KB2484033                     Aktualizacja dla systemu W...
		------                        2011-03-14 00:00:00           KB2495644                     Microsoft Silverlight (KB2...
		------                        2011-03-14 00:00:00           KB2493983                     Aktualizacja dla programu ...

		
	.EXAMPLE
		Get-WUList -IsInstalled | Format-Table * -AutoSize
		Connecting to Windows Server Update Service. Please wait...
		Found 8 installed updates.
		(Status list: D - IsDownloaded, I - IsInstalled, M - IsMandatory, H - IsHidden, U - IsUninstallable, B - IsBeta)

		Status LastDeploymentChangeTime KBArticleIDs Title
		------ ------------------------ ------------ -----
		DI---- 2009-03-25 00:00:00      KB925673     MSXML 6.0 RTM Security Update  (925673)
		DI---- 2009-07-20 00:00:00      KB969856     Security Update for Microsoft Virtual PC 2007 Service Pack 1 (KB969856)
		DI---- 2010-09-10 00:00:00      KB978464     Aktualizacja zabezpiecze� dla programu Microsoft Silverlight (KB978464)
		DI--U- 2010-09-10 00:00:00      KB2202188    Aktualizacja dla pakietu Microsoft Office 2010 (KB2202188), wersja 64-b...
		DI--U- 2010-10-22 00:00:00      KB2345000    Aktualizacja zabezpiecze� dla programu Microsoft Word 2010 (KB2345000),...
		DI--U- 2010-11-19 00:00:00      KB2289161    Aktualizacja zabezpiecze� dla pakietu Microsoft Office 2010 (KB2289161)...
		DI---- 2010-11-25 00:00:00      KB2285068    Microsoft SQL Server 2008 Service Pack 2 (KB2285068)
		DI--U- 2011-01-19 00:00:00      KB2413186    Aktualizacja funkcji walidacji plik�w pakietu Microsoft Office 2010 (KB... 

	.EXAMPLE      
        Get-WUList -KBArticleID KB974332 -ServerSelection 2 -IsInstalled
        
        Connecting to Windows Update. Please wait...

        Title                           : Aktualizacja systemu Windows 7 dla komputerów z p
                                          rocesorami x64 (KB974332)
        AutoSelectOnWebSites            : False
        BundledUpdates                  : System.__ComObject
        CanRequireSource                : False
        Categories                      : System.__ComObject
        Deadline                        : 
        DeltaCompressedContentAvailable : True
        DeltaCompressedContentPreferred : True
        Description                     : Zainstalowanie tej aktualizacji umożliwia rozwiąz
                                          anie problemów z niezgodnością aplikacji w system
                                          ie Windows 7. Aby uzyskać szczegółowe informacje 
                                          dotyczące tej aktualizacji, zobacz artykuł z bazy
                                           wiedzy Knowledge Base KB974332. Po zainstalowani
                                          u tego elementu może być konieczne ponowne urucho
                                          mienie komputera.
        EulaAccepted                    : True

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://code.msdn.microsoft.com/PSWindowsUpdate

	.LINK
		Get-WUHistory
		Get-WUInstall
	#>
    
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]	
    Param
    (
        [String]$KBArticleID,
        [Switch]$IsInstalled,
        [String]$ServiceID,
        [Switch]$MicrosoftUpdate,
		[Switch]$StatusOnly
    )    

	Begin{}
	
	Process
	{
	    if($IsInstalled) 
		{ 
			$IsInstalledStatus = "1"
			$msgShouldProcess = "Check what Windows Update was installed"
		}
	    else 
		{
			$IsInstalledStatus = "0" 
			$msgShouldProcess = "Check what Windows Update needs to be installed"
		}
	    
	    $objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
		$objSession = New-Object -ComObject "Microsoft.Update.Session"
	    $objSearcher = $objSession.CreateUpdateSearcher()
	    
		#check source of updates   
		if($MicrosoftUpdate)
		{
			$objSearcher.ServerSelection = 2
			$serviceName = "Microsoft Update"
		}
		else
		{
	        Foreach ($objService in $objServiceManager.Services) 
	        {
				if($ServiceID)
		    	{
					if($objService.ServiceID -eq $ServiceID)
		            {
		                $objSearcher.ServiceID = $ServiceID
		                $objSearcher.ServerSelection = 3
		                $serviceName = $objService.Name
		            }
				}
				else
				{
					if($objService.IsDefaultAUService -eq $True)
					{
						$serviceName = $objService.Name
					}
		        }
		    }
	    }
		
	    if ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,$msgShouldProcess)) 
		{
			if(!$StatusOnly)
			{
				Write-Host "Connecting to $($serviceName). Please wait..."
		    }
			
			Try
		    {        
		        $objResults = $objSearcher.Search("IsInstalled="+$IsInstalledStatus)
		    }
		    Catch
		    {
		        if($_ -match "HRESULT: 0x80072EE2")
		        {
		            Write-Warning "Probably you don't have connection to Windows Update server"
		        }
				else
				{
					Write-Error $_
				}
				
		        Return
		    }

			If($IsInstalled)
			{
				if(!$StatusOnly)
				{
					Write-Host "Found $($objResults.Updates.Count) installed updates. `n(Status list: D - IsDownloaded, I - IsInstalled, M - IsMandatory, H - IsHidden, U - IsUninstallable, B - IsBeta)"
				}	
			}
			else
			{
				if(!$StatusOnly)
				{
					Write-Host "Found $($objResults.Updates.Count) updates to install."
				}	
			}
		}
		
		$objCollection = @()
	    Foreach($objEntry in $objResults.Updates) 
	    { 
	        $Status = ""
	        if($objEntry.IsDownloaded)    {$Status += "D"} else {$status += "-"}
	        if($objEntry.IsInstalled)     {$Status += "I"} else {$status += "-"}
	        if($objEntry.IsMandatory)     {$Status += "M"} else {$status += "-"}
	        if($objEntry.IsHidden)        {$Status += "H"} else {$status += "-"}
	        if($objEntry.IsUninstallable) {$Status += "U"} else {$status += "-"}
	        if($objEntry.IsBeta)          {$Status += "B"} else {$status += "-"}        
	        
	        $KB = ""
	        if($objEntry.KBArticleIDs -ne "")    {$KB = "KB"+$objEntry.KBArticleIDs}
	        
			$objEntry | Add-Member -MemberType NoteProperty -Name Status -Value $Status	
			$objEntry | Add-Member -MemberType NoteProperty -Name KBArticleID -Value $KB	
			
	        if($KBArticleID)
	        {
	            $objCollection += $objEntry | Where {$_.Title -match "($KBArticleID)"}
	        }
	        else
	        {
	            $objCollection += $objEntry | Select-Object  Status, LastDeploymentChangeTime, KBArticleID, Title
	        }

	    }
		Return $objCollection 
	}
	
	End{}		
}

