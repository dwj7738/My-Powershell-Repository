Function Get-WUInstall_OldMode
{
	<#
	.SYNOPSIS
	    Download and install updates in mode from PSWindowsUpdate ver. 1.0. 

	.DESCRIPTION
	    Use Get-WUInstall to get list of available updates, next download and install it. All is executed in mode from old module version .

	.PARAMETER Type
	    Set updates category to download: "Driver","Update", "Security", "Critical".

	.PARAMETER DownloadOlny
	    Download updates only and don't install it.
        
	.PARAMETER All
        Accept all hotfix.
        
	.PARAMETER ServiceID
	    Set ServiceID to check updates. Overwrite ServerSelection parameter value.
        
	.PARAMETER MicrosoftUpdate
	    Set Microsoft Update as source. Default update config are taken from computer policy.
                              		
	.EXAMPLE
		Get-WUInstall
		
		Connecting to Windows Server Update Service. Please wait...
		Found [3] Updates to Download.
		Y - Yes, YY - Yes to rest, N - No, NN - No to rest
		Accept: Update for Windows Server 2008 R2 x64 Edition (KB2506014)? (1.79MB) [Y/YY/N/NN]: y
		Accept: Security Update for Windows Server 2008 R2 x64 Edition (KB2508429)? (0.58MB) [Y/YY/N/NN]: y
		Accept: Security Update for Windows Server 2008 R2 x64 Edition (KB2506212)? (1.23MB) [Y/YY/N/NN]: y

		Title                         KB                                                Size [MB] Status
		-----                         --                                                --------- ------
		Update for Windows Server ... KB2506014                                              1,79 Accepted
		Security Update for Window... KB2508429                                              0,58 Accepted
		Security Update for Window... KB2506212                                              1,23 Accepted

		Accept [3] Updates to Download.
		Downloading. Please wait...
		Update for Windows Server ... KB2506014                                              1,79 Downloaded
		Security Update for Window... KB2508429                                              0,58 Downloaded
		Security Update for Window... KB2506212                                              1,23 Downloaded

		Ready [3] Updates to Install
		Installing. Please wait...
		Update for Windows Server ... KB2506014                                              1,79 Installed
		Security Update for Window... KB2508429                                              0,58 Installed
		Security Update for Window... KB2506212                                              1,23 Installed
		
		Reboot is required. Do it now ? [Y/N]: Y

	.EXAMPLE
        Get-WUInstall -ServiceID 3da21691-e39d-4da6-8a4b-b43877bcb1b7 -All

        Connecting to Windows Server Update Service. Please wait...
        Found [2] Updates to Download

        Title                KB                              Size [MB] Status              
        -----                --                              --------- ------              
        Aktualizacja dla ... KB971033                             1,19 Accepted            
        Aktualizacja firm... KB976002                             0,10 Accepted  

        Accept [2] Updates to Download
        Downloading. Please wait...
        Aktualizacja dla ... KB971033                             1,19 Downloaded          
        Aktualizacja firm... KB976002                             0,10 Downloaded          

        Ready [2] Updates to Install
        Installing. Please wait...
        Aktualizacja dla ... KB971033                             1,19 Installed           
        Aktualizacja firm... KB976002                             0,10 Installed  
        
        Reboot is required. Do it now ? [Y/N]: Y
	
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
        ConfirmImpact="Low"
    )]	
    Param
    (
        [Parameter(Position=0)]
        [ValidateSet("Driver","Update", "Security", "Critical")]
        [String]$Type="",
        [String]$ServiceID,
        [Switch]$MicrosoftUpdate,
        [Switch]$DownloadOnly,
        [Switch]$All
    )

	Begin{}
	
	Process
	{
	    
	    if ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"Check and install updates")) 
		{	
		
			#check reboot status
			Try
		    {
		        $remoteFlag = $false
		        $objSystemInfo= New-Object -ComObject "Microsoft.Update.SystemInfo"
		        if($objSystemInfo.RebootRequired)
		        {
		            Write-Warning "Reboot is required to continue."
		            return
		        }
		    }
		    Catch
		    {
		        $remoteFlag = $true
		        Write-Host "Can't remotly check Reboot Status, Continue..." -foregroundcolor red
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
		   
		    Write-Host "Found [$($objResults.Updates.count)] Updates to Download."
		    if(!$All)
		    {
		        Write-Host "Y - Yes, YY - Yes to rest, N - No, NN - No to rest "
		    }
		    
		    #set update status    
		    $logCollection = @()
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
						
		            if($all)
		            {
		                #yes to all
		                $Download = "YY"
		            }
		            elseif($none)
		            {
		                #no to all
		                $Download = "NN"
		            }
		            else
		            {
		                $Download = Read-Host "Accept: $($Update.Title)? ($($size)MB) [Y/YY/N/NN]"
		                if($Download -eq "YY")
		                {
		                    $all = $true
		                }
		                if($Download -eq "NN")
		                {
		                    $none = $true
		                }                    
		            }                
		            
					$log = New-Object psobject

		            if($Update.KBArticleIDs -ne "")    {$KB = "KB"+$Update.KBArticleIDs} else {$KB = ""}
		            
					$log | Add-Member -MemberType NoteProperty -Name Title -Value $Update.Title
					$log | Add-Member -MemberType NoteProperty -Name KB -Value $KB
					$log | Add-Member -MemberType NoteProperty -Name Size -Value $size

		            if($Download -match "Y")
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
		            $logCollection += $log

		        }  
		    }
		    $logCollection | Select-Object  Title, KB, @{e={$_.Size};n='Size [MB]'}, Status 
		        
		    Write-Host
		    Write-Host "Accept [$($objCollection.count)] Updates to Download."
		    
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
		    }
		    
		    if(!$DownloadOnly)
		    {
		        $needsReboot = $false
		        
		        Write-Host 
		        Write-Host "Ready [$($objCollection.count)] Updates to Install"
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
		        }
		    
		        if($needsReboot)
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
