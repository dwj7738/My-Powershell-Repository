Function Get-WUInstall
{
	<#
	.SYNOPSIS
	    Download and install updates.

	.DESCRIPTION
	    Use Get-WUInstall to get list of available updates. Next download and install it.

	.PARAMETER Type
	    Set updates category to download: "Driver","Update", "Security", "Critical".

	.PARAMETER DownloadOlny
	    Download updates only and don't install it.
        
	.PARAMETER All
        Accept all hotfix.
	
	.PARAMETER AutoReboot
        AutoReboot if needed.
		
	.PARAMETER ServiceID
	    Set ServiceID to check updates. Overwrite ServerSelection parameter value.
        
	.PARAMETER MicrosoftUpdate
	    Set Microsoft Update as source. Default update config are taken from computer policy.
    
	.EXAMPLE
		Get-WUInstall -WhatIf
		
		Connecting to Windows Update. Please wait...
		Found [3] Updates to Download.
		What if: Performing operation "Aktualizacja systemu Windows 7 (KB974431)[15.75MB]?" on Target "KOMPUTER".
		What if: Performing operation "Aktualizacja zabezpieczeñ systemu Windows 7 (KB975467)[0.14MB]?" on Target "KOMPUTER".
		What if: Performing operation "Aktualizacja zabezpieczeñ systemu Windows 7 (KB974571)[0.04MB]?" on Target "KOMPUTER".
		
		Title                         KB                            Size [MB]                     Status
		-----                         --                            ---------                     ------
		Aktualizacja systemu Windo... KB974431                      15,75                         Rejected
		Aktualizacja zabezpieczeñ ... KB975467                      0,14                          Rejected
		Aktualizacja zabezpieczeñ ... KB974571                      0,04                          Rejected

		Accept [0] Updates to Download.
	
	.EXAMPLE
		Get-WUInstall -ServiceID 3da21691-e39d-4da6-8a4b-b43877bcb1b7
		
		Connecting to Windows Server Update Service. Please wait...
		Found [3] Updates to Download.

		Confirm
		Are you sure you want to perform this action?
		Performing operation "Aktualizacja systemu Windows 7 (KB974431)[15.75MB]?" on Target "KOMPUTER".
		[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): Y

		Confirm
		Are you sure you want to perform this action?
		Performing operation "Aktualizacja zabezpieczeñ systemu Windows 7 (KB975467)[0.14MB]?" on Target "KOMPUTER".
		[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): Y

		Confirm
		Are you sure you want to perform this action?
		Performing operation "Aktualizacja zabezpieczeñ systemu Windows 7 (KB974571)[0.04MB]?" on Target "KOMPUTER".
		[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): Y
		
		Title                         KB                           						Size [MB] Status
		-----                         --                            					--------- ------
		Aktualizacja systemu Windo... KB974431                      				   	    15,75 Accepted
		Aktualizacja zabezpieczeñ ... KB975467                      					     0,14 Accepted
		Aktualizacja zabezpieczeñ ... KB974571                      					     0,04 Accepted

		Accept [3] Updates to Download.
		Downloading. Please wait...
		Aktualizacja systemu Windo... KB974431                                              15,75 Downloaded
		Aktualizacja zabezpieczeñ ... KB975467                                               0,14 Downloaded
		Aktualizacja zabezpieczeñ ... KB974571                                               0,04 Downloaded

		Ready [3] Updates to Install
		Installing. Please wait...
		Aktualizacja systemu Windo... KB974431                                              15,75 Installed
		Aktualizacja zabezpieczeñ ... KB975467                                               0,14 Installed
		Aktualizacja zabezpieczeñ ... KB974571                                               0,04 Installed
		Reboot is required. Do it now ? [Y/N]:Y

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://code.msdn.microsoft.com/PSWindowsUpdate

	.LINK
		Get-WUServiceManager
        Get-WUList
	#>
        
	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="High"
    )]	
    Param
    (
        [Parameter(Position=0)]
        [ValidateSet("Driver","Update", "Security", "Critical")]
        [String]$Type="",
        [String]$ServiceID,
        [Switch]$MicrosoftUpdate,
        [Switch]$DownloadOnly,
        [Switch]$All,
		[Switch]$AutoReboot
    )

	Begin{}
	
	Process
	{
	    
		#check reboot status
		Try
	    {
	        $remoteFlag = $false
	        $objSystemInfo= New-Object -ComObject "Microsoft.Update.SystemInfo"
	        if($objSystemInfo.RebootRequired)
	        {
	            Write-Warning "Reboot is required to continue."
				if($AutoReboot)
				{
					Restart-Computer
				}
	            return
	        }
	    }
	    Catch
	    {
	        $remoteFlag = $true
	        Write-Host "Can't remotly check Reboot Status, Continue..." -foregroundcolor red
	    }
	    
		if($DownloadOnly)
		{
			$NumberOfPass = 2
		}
		else
		{
			$NumberOfPass = 3
		}
		
	    #create session object
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
	    
	    Write-Host "Connecting to $($serviceName). Please wait..."
	    
	    #check updates
	    $objCollection = New-Object -ComObject "Microsoft.Update.UpdateColl"
	    Try
	    {        
	        $objResults = $objSearcher.Search("IsInstalled=0")
	    }
	    Catch
	    {
	        if($_ -match "HRESULT: 0x80072EE2")
	        {
	            Write-Warning "Probably you don't have connection to Windows Update server."
	        }
	        Return
	    }
		
		$FoundUpdatesToDownload = $objResults.Updates.count
	    Write-Host "Found [$FoundUpdatesToDownload] Updates to Download."
	    
	    #set update status    
	    $logCollection = @()
		$NumberOfUpdate = 0
	    foreach($Update in $objResults.Updates)
	    {	
			if($Type -ne "")
		        {
	            switch -exact ($Type)
	            {
	                "Driver"   {$search = "Driver"}
	                "Update"   {$search = "Update"}
	                "Security" {$search = "Security"} 
	                "Critical" {$search = "Critical"}
	            }
	        }
	        else
	        {
	            $search = ""
	        }
			
	        Write-Progress -Activity "[1/$NumberOfPass] Choosing updates..." -Status "Processed updates: $NumberOfUpdate / $FoundUpdatesToDownload" -PercentComplete ([int]($NumberOfUpdate/$FoundUpdatesToDownload * 100))
	        #check category match   
	        if($Update.Categories.Item(0).Name -match $search)
	        {
				#ask for accept
	            if($remoteFlag)
	            {
	                $size = [System.Math]::Round($Update.MaxDownloadSize/1MB,0)
	            }
	            else
	            {
	                $size = [System.Math]::Round($Update.MaxDownloadSize/1MB,2)
	            }
				
				$log = New-Object psobject

				if($Update.KBArticleIDs -ne "")    {$KB = "KB"+$Update.KBArticleIDs} else {$KB = ""}
	            
				$log | Add-Member -MemberType NoteProperty -Name Title -Value $Update.Title
				$log | Add-Member -MemberType NoteProperty -Name KB -Value $KB
				$log | Add-Member -MemberType NoteProperty -Name Size -Value $size
				
				if($All)
				{
	                $log | Add-Member -MemberType NoteProperty -Name Status -Value "Accepted"
	                
	                #accept eula and add to collection
	                if ( $Update.EulaAccepted -eq 0 ) { $Update.AcceptEula() }
	                $objCollection.Add($Update) | out-null   
				}
				else
				{
					if ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"$($Update.Title)[$($size)MB]?")) 
					{
		                $log | Add-Member -MemberType NoteProperty -Name Status -Value "Accepted"
		                
		                #accept eula and add to collection
		                if ( $Update.EulaAccepted -eq 0 ) { $Update.AcceptEula() }
		                $objCollection.Add($Update) | out-null   
					}
					else
					{
						$log | Add-Member -MemberType NoteProperty -Name Status -Value "Rejected"
					}
				}
				
				$logCollection += $log
	        }
			$NumberOfUpdate++
	    }
		$logCollection | Select-Object  Title, KB, @{e={$_.Size};n='Size [MB]'}, Status 
		
		$AcceptUpdatesToDownload = $objCollection.count
	    Write-Host
	    Write-Host "Accept [$AcceptUpdatesToDownload] Updates to Download."
	    $NumberOfUpdate = 0
		
	    if($objCollection.count)
	    {
	        Write-Host "Downloading. Please wait..."
	    }
	    else
	    {
	        return
	    }
	    
	    #download updates    
	    $objCollection2 = New-Object -ComObject "Microsoft.Update.UpdateColl"
	    foreach($Update in $objCollection)
	    {   
	        Write-Progress -Activity "[2/$NumberOfPass] Downloading updates" -Status "[$($NumberOfUpdate)/$($AcceptUpdatesToDownload)] $($Update.Title)" -PercentComplete ([int]($NumberOfUpdate/$AcceptUpdatesToDownload * 100))
			
			$objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
	        $objCollectionTmp.Add($Update) | out-null
	            
	        $Downloader = $objSession.CreateUpdateDownloader() 
	        $Downloader.Updates = $objCollectionTmp
	        try
	        {
	            $DownloadResult = $Downloader.Download()
	        }
	        Catch
	        {
	            if($_ -match "HRESULT: 0x80240044")
	            {
	                Write-Warning "Your security policy don't allow a non-administator identity to perform this task"
	            }
	            return
	        } 
	        
	        switch -exact ($DownloadResult.ResultCode)
	        {
	            0   { $Status = "NotStarted"}
	            1   { $Status = "InProgress"}
	            2   { $Status = "Downloaded"}
	            3   { $Status = "DownloadedWithErrors"}
	            4   { $Status = "Failed"}
	            5   { $Status = "Aborted"}
	        }
	                
	        $log = New-Object psobject
	                        
	        if($Update.KBArticleIDs -ne "")    {$KB = "KB"+$Update.KBArticleIDs} else {$KB = ""}
	        $size = [System.Math]::Round($Update.MaxDownloadSize/1MB,2)
	                        
			$log | Add-Member -MemberType NoteProperty -Name Title -Value $Update.Title
			$log | Add-Member -MemberType NoteProperty -Name KB -Value $KB
			$log | Add-Member -MemberType NoteProperty -Name Size -Value $size
			$log | Add-Member -MemberType NoteProperty -Name Status -Value $Status
	        
	        $log | Select-Object  Title, KB, @{e={$_.Size};n='Size [MB]'}, Status 
	                
	        if($DownloadResult.ResultCode -eq 2)
	        {
	            $objCollection2.Add($Update) | out-null
	        }
			$NumberOfUpdate++
	    }
	    
	    if(!$DownloadOnly)
	    {
	        $needsReboot = $false
	        
			$ReadyUpdatesToInstall = $objCollection.count
	        Write-Host 
	        Write-Host "Ready [$ReadyUpdatesToInstall)] Updates to Install"
			$NumberOfUpdate = 0
			
	        if($objCollection2.count)
	        {
	            Write-Host "Installing. Please wait..."
	        }
	        else
	        {
	            return
	        }
	        
	        #install updates    
	        foreach($Update in $objCollection2)
	        {   
	            Write-Progress -Activity "[3/$NumberOfPass] Installing updates" -Status "[$($NumberOfUpdate)/$($ReadyUpdatesToInstall)] $($Update.Title)" -PercentComplete ([int]($NumberOfUpdate/$ReadyUpdatesToInstall * 100))
				
				$objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
	            $objCollectionTmp.Add($Update) | out-null
	                                
	            $objInstaller = $objSession.CreateUpdateInstaller()
	            $objInstaller.Updates = $objCollectionTmp
	                
	            try
	            {                
	                $InstallResult = $objInstaller.Install()
	            }
	            Catch
	            {
	                if($_ -match "HRESULT: 0x80240044")
	                {
	                    Write-Warning "Your security policy don't allow a non-administator identity to perform this task"
	                }
	                return
	            }
	                    
	            if(!$needsReboot) 
                { 
                    $needsReboot = $installResult.RebootRequired 
                }  
	                     
	            switch -exact ($InstallResult.ResultCode)
	            {
	                0   { $Status = "NotStarted"}
	                1   { $Status = "InProgress"}
	                2   { $Status = "Installed"}
	                3   { $Status = "InstalledWithErrors"}
	                4   { $Status = "Failed"}
	                5   { $Status = "Aborted"}
	            }
	           
	            $log = New-Object psobject 
	                        
	            if($Update.KBArticleIDs -ne "")    {$KB = "KB"+$Update.KBArticleIDs} else {$KB = ""}
	            $size = [System.Math]::Round($Update.MaxDownloadSize/1MB,2)
	                        
				$log | Add-Member -MemberType NoteProperty -Name Title -Value $Update.Title
				$log | Add-Member -MemberType NoteProperty -Name KB -Value $KB
				$log | Add-Member -MemberType NoteProperty -Name Size -Value $size
				$log | Add-Member -MemberType NoteProperty -Name Status -Value $Status
				
	            $log | Select-Object  Title, KB, @{e={$_.Size};n='Size [MB]'}, Status 
				
				$NumberOfUpdate++
	        }
	    
	        if($needsReboot)
	        {
	            if($AutoReboot)
				{
					Restart-Computer
				}
				else
				{
					$Reboot = Read-Host "Reboot is required. Do it now ? [Y/N]"
	            	if($Reboot -eq "Y")
	            	{
	                	Restart-Computer
	            	}
				}	
	        }
	    }
	}
	
	End{}		
}
