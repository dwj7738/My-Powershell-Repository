Function Get-WUInstall
{
	<#
	.SYNOPSIS
		Download and install updates.

	.DESCRIPTION
		Use Get-WUInstall to get list of available updates, next download and install it. 
		There are two types of filtering update: Pre search criteria, Post search criteria.
		- Pre search works on server side, like example: ( IsInstalled = 0 and IsHidden = 0 and CategoryIds contains '0fa1201d-4330-4fa8-8ae9-b877473b6441' )
		- Post search work on client side after downloading the pre-filtered list of updates, like example $KBArticleID -match $Update.KBArticleIDs
		
		Update occurs in four stages: 1. Search for updates, 2. Choose updates, 3. Download updates, 4. Install updates.
		
	.PARAMETER Type
		Pre search criteria. Finds updates of a specific type, such as 'Driver' and 'Software'. Default value contains all updates.

	.PARAMETER UpdateID
		Pre search criteria. Finds updates of a specific UUID (or sets of UUIDs), such as '12345678-9abc-def0-1234-56789abcdef0'.

	.PARAMETER RevisionNumber
		Pre search criteria. Finds updates of a specific RevisionNumber, such as '100'. This criterion must be combined with the UpdateID param.

	.PARAMETER CategoryIDs
		Pre search criteria. Finds updates that belong to a specified category (or sets of UUIDs), such as '0fa1201d-4330-4fa8-8ae9-b877473b6441'.

	.PARAMETER IsInstalled
		Pre search criteria. Finds updates that are installed on the destination computer.

	.PARAMETER IsHidden
		Pre search criteria. Finds updates that are marked as hidden on the destination computer. Default search criteria is only not hidden upadates.
	
	.PARAMETER WithHidden
		Pre search criteria. Finds updates that are both hidden and not on the destination computer. Overwrite IsHidden param. Default search criteria is only not hidden upadates.
		
	.PARAMETER Criteria
		Pre search criteria. Set own string that specifies the search criteria.

	.PARAMETER ShowSearchCriteria
		Show choosen search criteria. Only works for pre search criteria.
		
	.PARAMETER Category
		Post search criteria. Finds updates that contain a specified category name (or sets of categories name), such as 'Updates', 'Security Updates', 'Critical Updates', etc...
		
	.PARAMETER KBArticleID
		Post search criteria. Finds updates that contain a KBArticleID (or sets of KBArticleIDs), such as 'KB982861'.
	
	.PARAMETER Title
		Post search criteria. Finds updates that match part of title, such as ''

	.PARAMETER NotCategory
		Post search criteria. Finds updates that not contain a specified category name (or sets of categories name), such as 'Updates', 'Security Updates', 'Critical Updates', etc...
		
	.PARAMETER NotKBArticleID
		Post search criteria. Finds updates that not contain a KBArticleID (or sets of KBArticleIDs), such as 'KB982861'.
	
	.PARAMETER NotTitle
		Post search criteria. Finds updates that not match part of title.
		
	.PARAMETER IgnoreUserInput
		Post search criteria. Finds updates that the installation or uninstallation of an update can't prompt for user input.
	
	.PARAMETER IgnoreRebootRequired
		Post search criteria. Finds updates that specifies the restart behavior that not occurs when you install or uninstall the update.
	
	.PARAMETER ServiceID
		Set ServiceIS to change the default source of Windows Updates. It overwrite ServerSelection parameter value.

	.PARAMETER WindowsUpdate
		Set Windows Update Server as source. Default update config are taken from computer policy.
		
	.PARAMETER MicrosoftUpdate
		Set Microsoft Update Server as source. Default update config are taken from computer policy.
		
	.PARAMETER ListOnly
		Show list of updates only without downloading and installing. Works similar like Get-WUList.
	
	.PARAMETER DownloadOnly
		Show list and download approved updates but do not install it. 
	
	.PARAMETER AcceptAll
		Do not ask for confirmation updates. Install all available updates.
	
	.PARAMETER AutoReboot
		Do not ask for rebbot if it needed.
	
	.PARAMETER IgnoreReboot
		Do not ask for reboot if it needed, but do not reboot automaticaly. 

	.PARAMETER Debuger	
	    Debug mode.

	.EXAMPLE
		Get info about updates that are not require user interaction to install.
	
		PS C:\> Get-WUInstall -MicrosoftUpdate -IgnoreUserInput -WhatIf -Verbose
		VERBOSE: Connecting to Microsoft Update server. Please wait...
		VERBOSE: Found [39] Updates in pre search criteria
		VERBOSE: Found [5] Updates in post search criteria to Download
		What if: Performing operation "Aktualizacja firmy Microsoft z ekranem wybierania przegl¹darki dla u¿ytkowników systemu W
		indows 7 dla systemów opartych na procesorach x64 w Europejskim Obszarze Gospodarczym (KB976002)[1 MB]?" on Target "KOMP
		UTER".
		What if: Performing operation "Aktualizacja dla systemu Windows 7 dla systemów opartych na procesorach x64 (KB971033)[1
		MB]?" on Target "KOMPUTER".
		What if: Performing operation "Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2533552)[1 MB]?" on Ta
		rget "KOMPUTER".
		What if: Performing operation "Program Microsoft .NET Framework 4 Client Profile w systemie Windows 7 dla systemów opart
		ych na procesorach x64 (KB982670)[1 MB]?" on Target "KOMPUTER".
		What if: Performing operation "Narzêdzie Windows do usuwania z³oœliwego oprogramowania dla komputerów z procesorem x64 -
		 grudzieñ 2011 (KB890830)[1 MB]?" on Target "KOMPUTER".

		X Status     KB          Size Title
		- ------     --          ---- -----
		2 Rejected   KB890830    1 MB Aktualizacja firmy Microsoft z ekranem wybierania przegl¹darki dla u¿ytkowników system...
		2 Rejected   KB890830    1 MB Aktualizacja dla systemu Windows 7 dla systemów opartych na procesorach x64 (KB971033)
		2 Rejected   KB890830    1 MB Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2533552)
		2 Rejected   KB890830    1 MB Program Microsoft .NET Framework 4 Client Profile w systemie Windows 7 dla systemów op...
		2 Rejected   KB890830    1 MB Narzêdzie Windows do usuwania z³oœliwego oprogramowania dla komputerów z procesorem x6...
		VERBOSE: Accept [0] Updates to Download
	
	.EXAMPLE
		Get updates from specific source with title contains ".NET Framework 4". Everything automatic accept and install.
	
		PS C:\> Get-WUInstall -ServiceID 9482f4b4-e343-43b6-b170-9a65bc822c77 -Title ".NET Framework 4" -AcceptAll

		X Status     KB          Size Title
		- ------     --          ---- -----
		2 Accepted   KB982670   48 MB Program Microsoft .NET Framework 4 Client Profile w systemie Windows 7 dla systemów op...
		3 Downloaded KB982670   48 MB Program Microsoft .NET Framework 4 Client Profile w systemie Windows 7 dla systemów op...
		4 Installed  KB982670   48 MB Program Microsoft .NET Framework 4 Client Profile w systemie Windows 7 dla systemów op...

	.EXAMPLE
		Get updates with specyfic KBArticleID. Check if type are "Software" and automatic install all.
		
		PS C:\> $KBList = "KB890830","KB2533552","KB2539636"
		PS C:\> Get-WUInstall -Type "Software" -KBArticleID $KBList -AcceptAll

		X Status     KB          Size Title
		- ------     --          ---- -----
		2 Accepted   KB2533552   9 MB Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2533552)
		2 Accepted   KB2539636   4 MB Aktualizacja zabezpieczeñ dla programu Microsoft .NET Framework 4 w systemach Windows ...
		2 Accepted   KB890830    1 MB Narzêdzie Windows do usuwania z³oœliwego oprogramowania dla komputerów z procesorem x6...
		3 Downloaded KB2533552   9 MB Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2533552)
		3 Downloaded KB2539636   4 MB Aktualizacja zabezpieczeñ dla programu Microsoft .NET Framework 4 w systemach Windows ...
		3 Downloaded KB890830    1 MB Narzêdzie Windows do usuwania z³oœliwego oprogramowania dla komputerów z procesorem x6...	
		4 Installed  KB2533552   9 MB Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2533552)
		4 Installed  KB2539636   4 MB Aktualizacja zabezpieczeñ dla programu Microsoft .NET Framework 4 w systemach Windows ...
		4 Installed  KB890830    1 MB Narzêdzie Windows do usuwania z³oœliwego oprogramowania dla komputerów z procesorem x6...
	
	.EXAMPLE
		Get list of updates without language packs and updatets that's not hidden.

		PS C:\> Get-WUInstall -NotCategory "Language packs" -ListOnly

		X Status KB          Size Title
		- ------ --          ---- -----
		1 ------ KB2640148   8 MB Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2640148)
		1 ------ KB2600217  32 MB Aktualizacja dla programu Microsoft .NET Framework 4 w systemach Windows XP, Se...
		1 ------ KB2679255   6 MB Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2679255)
		1 ------ KB915597    3 MB Definition Update for Windows Defender - KB915597 (Definition 1.125.146.0)
		
	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc
		http://msdn.microsoft.com/en-us/library/windows/desktop/aa386526(v=vs.85).aspx
		http://msdn.microsoft.com/en-us/library/windows/desktop/aa386099(v=vs.85).aspx
		http://msdn.microsoft.com/en-us/library/ff357803(VS.85).aspx

	.LINK
		Get-WUServiceManager
		Get-WUList
	#>
	[OutputType('PSWindowsUpdate.WUInstall')]
	[CmdletBinding(
		SupportsShouldProcess=$True,
		ConfirmImpact="High"
	)]	
	Param
	(
		#Pre search criteria
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateSet("Driver", "Software")]
		[String]$Type="",
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]]$UpdateID,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Int]$RevisionNumber,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]]$CategoryIDs,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Switch]$IsInstalled,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Switch]$IsHidden,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Switch]$WithHidden,
		[String]$Criteria,
		[Switch]$ShowSearchCriteria,
		
		#Post search criteria
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]]$Category="",
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]]$KBArticleID,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[String]$Title,
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]]$NotCategory="",
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[String[]]$NotKBArticleID,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[String]$NotTitle,
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Alias("Silent")]
		[Switch]$IgnoreUserInput,
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[Switch]$IgnoreRebootRequired,
		
		#Connection options
		[String]$ServiceID,
		[Switch]$WindowsUpdate,
		[Switch]$MicrosoftUpdate,
		
		#Mode options
		[Switch]$ListOnly,
		[Switch]$DownloadOnly,
		[Alias("All")]
		[Switch]$AcceptAll,
		[Switch]$AutoReboot,
		[Switch]$IgnoreReboot,
		[Switch]$Debuger
	)

	Begin
	{
		If($PSBoundParameters['Debuger'])
		{
			$DebugPreference = "Continue"
		} #End If $PSBoundParameters['Debuger'] 
	}

	Process
	{
		#region	STAGE 0	
		######################################
		# Start STAGE 0: Prepare environment #
		######################################
		
		Write-Debug "STAGE 0: Prepare environment"
		If($IsInstalled)
		{
			$ListOnly = $true
			Write-Debug "Change to ListOnly mode"
		} #End If $IsInstalled

		Write-Debug "Check reboot status only for local instance"
		Try
		{
			$objSystemInfo = New-Object -ComObject "Microsoft.Update.SystemInfo"	
			If($objSystemInfo.RebootRequired)
			{
				Write-Warning "Reboot is required to continue"
				If($AutoReboot)
				{
					Restart-Computer -Force
				} #End If $AutoReboot

				If(!$ListOnly)
				{
					Return
				} #End If !$ListOnly	
				
			} #End If $objSystemInfo.RebootRequired
		} #End Try
		Catch
		{
			Write-Warning "Support local instance only, Continue..."
		} #End Catch
		
		Write-Debug "Set number of stage"
		If($ListOnly)
		{
			$NumberOfStage = 2
		} #End $ListOnly
		ElseIf($DownloadOnly)
		{
			$NumberOfStage = 3
		} #End Else $ListOnly If $DownloadOnly
		Else
		{
			$NumberOfStage = 4
		} #End Else $DownloadOnly
		
		####################################			
		# End STAGE 0: Prepare environment #
		####################################
		#endregion
		
		#region	STAGE 1
		###################################
		# Start STAGE 1: Get updates list #
		###################################			
		
		Write-Debug "STAGE 1: Get updates list"
		Write-Debug "Create Microsoft.Update.ServiceManager object"
		$objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager" 
		
		Write-Debug "Create Microsoft.Update.Session object"
		$objSession = New-Object -ComObject "Microsoft.Update.Session" 
		
		Write-Debug "Create Microsoft.Update.Session.Searcher object"
		$objSearcher = $objSession.CreateUpdateSearcher()

		If($WindowsUpdate)
		{
			Write-Debug "Set source of updates to Windows Update"
			$objSearcher.ServerSelection = 2
			$serviceName = "Windows Update"
		} #End If $WindowsUpdate
		ElseIf($MicrosoftUpdate)
		{
			Write-Debug "Set source of updates to Microsoft Update"
			$objSearcher.ServerSelection = 3
			$objSearcher.ServiceID = "7971f918-a847-4430-9279-4a52d1efe18d"
			$serviceName = "Microsoft Update"
		} #End Else $WindowsUpdate If $MicrosoftUpdate
		Else
		{
			Foreach ($objService in $objServiceManager.Services) 
			{
				If($ServiceID)
				{
					If($objService.ServiceID -eq $ServiceID)
					{
						$objSearcher.ServiceID = $ServiceID
						$objSearcher.ServerSelection = 3
						$serviceName = $objService.Name
						Break
					} #End If $objService.ServiceID -eq $ServiceID
				} #End If $ServiceID
				Else
				{
					If($objService.IsDefaultAUService -eq $True)
					{
						$serviceName = $objService.Name
						Break
					} #End If $objService.IsDefaultAUService -eq $True
				} #End Else $ServiceID
			} #End Foreach $objService in $objServiceManager.Services
		} #End Else $MicrosoftUpdate
		Write-Debug "Set source of updates to $serviceName"
		
		Write-Verbose "Connecting to $serviceName server. Please wait..."
		Try
		{
			$search = ""
			
			If($Criteria)
			{
				$search = $Criteria
			} #End If $Criteria
			Else
			{
				If($IsInstalled) 
				{
					$search = "IsInstalled = 1"
					Write-Debug "Set pre search criteria: IsInstalled = 1"
				} #End If $IsInstalled
				Else
				{
					$search = "IsInstalled = 0"	
					Write-Debug "Set pre search criteria: IsInstalled = 0"
				} #End Else $IsInstalled
				
				If($Type -ne "")
				{
					Write-Debug "Set pre search criteria: Type = $Type"
					$search += " and Type = '$Type'"
				} #End If $Type -ne ""					
				
				If($UpdateID)
				{
					Write-Debug "Set pre search criteria: UpdateID = '$([string]::join(", ", $UpdateID))'"
					$tmp = $search
					$search = ""
					$LoopCount = 0
					Foreach($ID in $UpdateID)
					{
						If($LoopCount -gt 0)
						{
							$search += " or "
						} #End If $LoopCount -gt 0
						If($RevisionNumber)
						{
							Write-Debug "Set pre search criteria: RevisionNumber = '$RevisionNumber'"	
							$search += "($tmp and UpdateID = '$ID' and RevisionNumber = $RevisionNumber)"
						} #End If $RevisionNumber
						Else
						{
							$search += "($tmp and UpdateID = '$ID')"
						} #End Else $RevisionNumber
						$LoopCount++
					} #End Foreach $ID in $UpdateID
				} #End If $UpdateID

				If($CategoryIDs)
				{
					Write-Debug "Set pre search criteria: CategoryIDs = '$([string]::join(", ", $CategoryIDs))'"
					$tmp = $search
					$search = ""
					$LoopCount =0
					Foreach($ID in $CategoryIDs)
					{
						If($LoopCount -gt 0)
						{
							$search += " or "
						} #End If $LoopCount -gt 0
						$search += "($tmp and CategoryIDs contains '$ID')"
						$LoopCount++
					} #End Foreach $ID in $CategoryIDs
				} #End If $CategoryIDs
				
				If($IsHidden) 
				{
					Write-Debug "Set pre search criteria: IsHidden = 1"
					$search += " and IsHidden = 1"	
				} #End If $IsNotHidden
				ElseIf($WithHidden) 
				{
					Write-Debug "Set pre search criteria: IsHidden = 1 and IsHidden = 0 (clear IsHidden criteria)"
				} #End ElseIf $WithHidden
				Else
				{
					Write-Debug "Set pre search criteria: IsHidden = 0"
					$search += " and IsHidden = 0"	
				} #End Else $WithHidden
				
				#Don't know why every update have RebootRequired=false which is not always true
				If($IgnoreRebootRequired) 
				{
					Write-Debug "Set pre search criteria: RebootRequired = 0"
					$search += " and RebootRequired = 0"	
				} #End If $IgnoreRebootRequired
			} #End Else $Criteria
			
			Write-Debug "Search criteria is: $search"
			
			If($ShowSearchCriteria)
			{
				Write-Output $search
			} #End If $ShowSearchCriteria
			
			$objResults = $objSearcher.Search($search)
		} #End Try
		Catch
		{
			If($_ -match "HRESULT: 0x80072EE2")
			{
				Write-Warning "Probably you don't have connection to Windows Update server"
			} #End If $_ -match "HRESULT: 0x80072EE2"
			Else
			{
				Write-Error $_ -ErrorAction Stop
			} #End Else $_ -match "HRESULT: 0x80072EE2"
			Return
		} #End Catch

		$objCollectionUpdate = New-Object -ComObject "Microsoft.Update.UpdateColl" 
		
		$NumberOfUpdate = 1
		$UpdateCollection = @()
		$UpdatesExtraDataCollection = @{}
		$PreFoundUpdatesToDownload = $objResults.Updates.count
		Write-Verbose "Found [$PreFoundUpdatesToDownload] Updates in pre search criteria"	
		
		If($PreFoundUpdatesToDownload -eq 0)
		{
			Write-Warning "Don't found any Updates in pre search criteria"
			Return
		} #End If $PreFoundUpdatesToDownload -eq 0
		
		Foreach($Update in $objResults.Updates)
		{	
			$UpdateAccess = $true
			Write-Progress -Activity "Post search updates for $Computer" -Status "[$NumberOfUpdate/$PreFoundUpdatesToDownload] $($Update.Title) $size" -PercentComplete ([int]($NumberOfUpdate/$PreFoundUpdatesToDownload * 100))
			Write-Debug "Set post search criteria: $($Update.Title)"
			
			If($Category -ne "")
			{
				$UpdateCategories = $Update.Categories | Select-Object Name
				Write-Debug "Set post search criteria: Categories = '$([string]::join(", ", $Category))'"	
				Foreach($Cat in $Category)
				{
					If(!($UpdateCategories -match $Cat))
					{
						Write-Debug "UpdateAccess: false"
						$UpdateAccess = $false
					} #End If !($UpdateCategories -match $Cat)
					Else
					{
						$UpdateAccess = $true
						Break
					} #End Else !($UpdateCategories -match $Cat)
				} #End Foreach $Cat in $Category	
			} #End If $Category -ne ""

			If($NotCategory -ne "" -and $UpdateAccess -eq $true)
			{
				$UpdateCategories = $Update.Categories | Select-Object Name
				Write-Debug "Set post search criteria: NotCategories = '$([string]::join(", ", $NotCategory))'"	
				Foreach($Cat in $NotCategory)
				{
					If($UpdateCategories -match $Cat)
					{
						Write-Debug "UpdateAccess: false"
						$UpdateAccess = $false
						Break
					} #End If $UpdateCategories -match $Cat
				} #End Foreach $Cat in $NotCategory	
			} #End If $NotCategory -ne "" -and $UpdateAccess -eq $true					
			
			If($KBArticleID -ne $null -and $UpdateAccess -eq $true)
			{
				Write-Debug "Set post search criteria: KBArticleIDs = '$([string]::join(", ", $KBArticleID))'"
				If(!($KBArticleID -match $Update.KBArticleIDs -and "" -ne $Update.KBArticleIDs))
				{
					Write-Debug "UpdateAccess: false"
					$UpdateAccess = $false
				} #End If !($KBArticleID -match $Update.KBArticleIDs)								
			} #End If $KBArticleID -ne $null -and $UpdateAccess -eq $true

			If($NotKBArticleID -ne $null -and $UpdateAccess -eq $true)
			{
				Write-Debug "Set post search criteria: NotKBArticleIDs = '$([string]::join(", ", $NotKBArticleID))'"
				If($NotKBArticleID -match $Update.KBArticleIDs -and "" -ne $Update.KBArticleIDs)
				{
					Write-Debug "UpdateAccess: false"
					$UpdateAccess = $false
				} #End If$NotKBArticleID -match $Update.KBArticleIDs -and "" -ne $Update.KBArticleIDs					
			} #End If $NotKBArticleID -ne $null -and $UpdateAccess -eq $true
			
			If($Title -and $UpdateAccess -eq $true)
			{
				Write-Debug "Set post search criteria: Title = '$Title'"
				If($Update.Title -notmatch $Title)
				{
					Write-Debug "UpdateAccess: false"
					$UpdateAccess = $false
				} #End If $Update.Title -notmatch $Title
			} #End If $Title -and $UpdateAccess -eq $true

			If($NotTitle -and $UpdateAccess -eq $true)
			{
				Write-Debug "Set post search criteria: NotTitle = '$NotTitle'"
				If($Update.Title -match $NotTitle)
				{
					Write-Debug "UpdateAccess: false"
					$UpdateAccess = $false
				} #End If $Update.Title -notmatch $NotTitle
			} #End If $NotTitle -and $UpdateAccess -eq $true
			
			If($IgnoreUserInput -and $UpdateAccess -eq $true)
			{
				Write-Debug "Set post search criteria: CanRequestUserInput"
				If($Update.InstallationBehavior.CanRequestUserInput -eq $true)
				{
					Write-Debug "UpdateAccess: false"
					$UpdateAccess = $false
				} #End If $Update.InstallationBehavior.CanRequestUserInput -eq $true
			} #End If $IgnoreUserInput -and $UpdateAccess -eq $true

			If($IgnoreRebootRequired -and $UpdateAccess -eq $true) 
			{
				Write-Debug "Set post search criteria: RebootBehavior"
				If($Update.InstallationBehavior.RebootBehavior -ne 0)
				{
					Write-Debug "UpdateAccess: false"
					$UpdateAccess = $false
				} #End If $Update.InstallationBehavior.RebootBehavior -ne 0	
			} #End If $IgnoreRebootRequired -and $UpdateAccess -eq $true

			If($UpdateAccess -eq $true)
			{
				Write-Debug "Convert size"
				Switch($Update.MaxDownloadSize)
				{
					{[System.Math]::Round($_/1KB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1KB,0))+" KB"; break }
					{[System.Math]::Round($_/1MB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1MB,0))+" MB"; break }  
					{[System.Math]::Round($_/1GB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1GB,0))+" GB"; break }    
					{[System.Math]::Round($_/1TB,0) -lt 1024} { $size = [String]([System.Math]::Round($_/1TB,0))+" TB"; break }
					default { $size = $_+"B" }
				} #End Switch
			
				Write-Debug "Convert KBArticleIDs"
				If($Update.KBArticleIDs -ne "")    
				{
					$KB = "KB"+$Update.KBArticleIDs
				} #End If $Update.KBArticleIDs -ne ""
				Else 
				{
					$KB = ""
				} #End Else $Update.KBArticleIDs -ne ""
				
				If($ListOnly)
				{
					$Status = ""
					If($Update.IsDownloaded)    {$Status += "D"} else {$status += "-"}
					If($Update.IsInstalled)     {$Status += "I"} else {$status += "-"}
					If($Update.IsMandatory)     {$Status += "M"} else {$status += "-"}
					If($Update.IsHidden)        {$Status += "H"} else {$status += "-"}
					If($Update.IsUninstallable) {$Status += "U"} else {$status += "-"}
					If($Update.IsBeta)          {$Status += "B"} else {$status += "-"} 
	
					Add-Member -InputObject $Update -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME
					Add-Member -InputObject $Update -MemberType NoteProperty -Name KB -Value $KB
					Add-Member -InputObject $Update -MemberType NoteProperty -Name Size -Value $size
					Add-Member -InputObject $Update -MemberType NoteProperty -Name Status -Value $Status
					Add-Member -InputObject $Update -MemberType NoteProperty -Name X -Value 1
					
					$Update.PSTypeNames.Clear()
					$Update.PSTypeNames.Add('PSWindowsUpdate.WUInstall')
					$UpdateCollection += $Update
				} #End If $ListOnly
				Else
				{
					$objCollectionUpdate.Add($Update) | Out-Null
					$UpdatesExtraDataCollection.Add($Update.Identity.UpdateID,@{KB = $KB; Size = $size})
				} #End Else $ListOnly
			} #End If $UpdateAccess -eq $true
			
			$NumberOfUpdate++
		} #End Foreach $Update in $objResults.Updates				
		Write-Progress -Activity "[1/$NumberOfStage] Post search updates" -Status "Completed" -Completed
		
		If($ListOnly)
		{
			$FoundUpdatesToDownload = $UpdateCollection.count
		} #End If $ListOnly
		Else
		{
			$FoundUpdatesToDownload = $objCollectionUpdate.count				
		} #End Else $ListOnly
		Write-Verbose "Found [$FoundUpdatesToDownload] Updates in post search criteria"
		
		If($FoundUpdatesToDownload -eq 0)
		{
			Write-Warning "Don't found any Updates in post search criteria"
			Return
		} #End If $FoundUpdatesToDownload -eq 0
		
		If($ListOnly)
		{
			Write-Debug "Return only list of updates"
			Return $UpdateCollection				
		} #End If $ListOnly

		#################################
		# End STAGE 1: Get updates list #
		#################################
		#endregion
		

		If(!$ListOnly) 
		{
			#region	STAGE 2
			#################################
			# Start STAGE 2: Choose updates #
			#################################
			
			Write-Debug "STAGE 2: Choose updates"			
			$NumberOfUpdate = 1
			$logCollection = @()
			
			$objCollectionChoose = New-Object -ComObject "Microsoft.Update.UpdateColl"

			Foreach($Update in $objCollectionUpdate)
			{	
				$size = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].Size
				Write-Progress -Activity "[2/$NumberOfStage] Choose updates" -Status "[$NumberOfUpdate/$FoundUpdatesToDownload] $($Update.Title) $size" -PercentComplete ([int]($NumberOfUpdate/$FoundUpdatesToDownload * 100))
				Write-Debug "Show update to accept: $($Update.Title)"
				
				If($AcceptAll)
				{
					$Status = "Accepted"

					If($Update.EulaAccepted -eq 0)
					{ 
						Write-Debug "Accept Eula"
						$Update.AcceptEula() 
					} #End If $Update.EulaAccepted -eq 0
			
					Write-Debug "Add update to collection"
					$objCollectionChoose.Add($Update) | Out-Null
				} #End If $AcceptAll
				Else
				{
					If($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"$($Update.Title)[$size]?")) 
					{
						$Status = "Accepted"
						
						If($Update.EulaAccepted -eq 0)
						{ 
							Write-Debug "Accept Eula"
							$Update.AcceptEula() 
						} #End If $Update.EulaAccepted -eq 0
				
						Write-Debug "Add update to collection"
						$objCollectionChoose.Add($Update) | Out-Null 
					} #End If $pscmdlet.ShouldProcess($Env:COMPUTERNAME,"$($Update.Title)[$size]?")
					Else
					{
						$Status = "Rejected"
					} #End Else $pscmdlet.ShouldProcess($Env:COMPUTERNAME,"$($Update.Title)[$size]?")
				} #End Else $AcceptAll
				
				Write-Debug "Add to log collection"
				$log = New-Object PSObject -Property @{
					Title = $Update.Title
					KB = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].KB
					Size = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].Size
					Status = $Status
					X = 2
				} #End PSObject Property
				
				$log.PSTypeNames.Clear()
				$log.PSTypeNames.Add('PSWindowsUpdate.WUInstall')
				
				$logCollection += $log
				
				$NumberOfUpdate++
			} #End Foreach $Update in $objCollectionUpdate
			Write-Progress -Activity "[2/$NumberOfStage] Choose updates" -Status "Completed" -Completed
			
			Write-Debug "Show log collection"
			$logCollection
			
			
			$AcceptUpdatesToDownload = $objCollectionChoose.count
			Write-Verbose "Accept [$AcceptUpdatesToDownload] Updates to Download"
			
			If($AcceptUpdatesToDownload -eq 0)
			{
				Write-Warning "Don't found any accept Updates to Download"
				Return
			} #End If $AcceptUpdatesToDownload -eq 0	
				
			###############################
			# End STAGE 2: Choose updates #
			###############################
			#endregion
			
			#region STAGE 3
			###################################
			# Start STAGE 3: Download updates #
			###################################
			
			Write-Debug "STAGE 3: Download updates"
			$NumberOfUpdate = 1
			$objCollectionDownload = New-Object -ComObject "Microsoft.Update.UpdateColl" 

			Foreach($Update in $objCollectionChoose)
			{
				Write-Progress -Activity "[3/$NumberOfStage] Downloading updates" -Status "[$NumberOfUpdate/$AcceptUpdatesToDownload] $($Update.Title) $size" -PercentComplete ([int]($NumberOfUpdate/$AcceptUpdatesToDownload * 100))
				Write-Debug "Show update to download: $($Update.Title)"
				
				Write-Debug "Send update to download collection"
				$objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
				$objCollectionTmp.Add($Update) | Out-Null
					
				$Downloader = $objSession.CreateUpdateDownloader() 
				$Downloader.Updates = $objCollectionTmp
				Try
				{
					Write-Debug "Try download update"
					$DownloadResult = $Downloader.Download()
				} #End Try
				Catch
				{
					If($_ -match "HRESULT: 0x80240044")
					{
						Write-Warning "Your security policy don't allow a non-administator identity to perform this task"
					} #End If $_ -match "HRESULT: 0x80240044"
					
					Return
				} #End Catch 
				
				Write-Debug "Check ResultCode"
				Switch -exact ($DownloadResult.ResultCode)
				{
					0   { $Status = "NotStarted" }
					1   { $Status = "InProgress" }
					2   { $Status = "Downloaded" }
					3   { $Status = "DownloadedWithErrors" }
					4   { $Status = "Failed" }
					5   { $Status = "Aborted" }
				} #End Switch
				
				Write-Debug "Add to log collection"
				$log = New-Object PSObject -Property @{
					Title = $Update.Title
					KB = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].KB
					Size = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].Size
					Status = $Status
					X = 3
				} #End PSObject Property
				
				$log.PSTypeNames.Clear()
				$log.PSTypeNames.Add('PSWindowsUpdate.WUInstall')
				
				$log
				
				If($DownloadResult.ResultCode -eq 2)
				{
					Write-Debug "Downloaded then send update to next stage"
					$objCollectionDownload.Add($Update) | Out-Null
				} #End If $DownloadResult.ResultCode -eq 2
				
				$NumberOfUpdate++
				
			} #End Foreach $Update in $objCollectionChoose
			Write-Progress -Activity "[3/$NumberOfStage] Downloading updates" -Status "Completed" -Completed

			$ReadyUpdatesToInstall = $objCollectionDownload.count
			Write-Verbose "Downloaded [$ReadyUpdatesToInstall] Updates to Install"
		
			If($ReadyUpdatesToInstall -eq 0)
			{
				Write-Warning "Don't found any downloaded Updates to Install"
				Return
			} #End If $ReadyUpdatesToInstall -eq 0
		

			#################################
			# End STAGE 3: Download updates #
			#################################
			#endregion
			
			If(!$DownloadOnly)
			{
				#region	STAGE 4
				##################################
				# Start STAGE 4: Install updates #
				##################################
				
				Write-Debug "STAGE 4: Install updates"
				$NeedsReboot = $false
				$NumberOfUpdate = 1
				
				#install updates	
				Foreach($Update in $objCollectionDownload)
				{   
					Write-Progress -Activity "[4/$NumberOfStage] Installing updates" -Status "[$NumberOfUpdate/$ReadyUpdatesToInstall] $($Update.Title)" -PercentComplete ([int]($NumberOfUpdate/$ReadyUpdatesToInstall * 100))
					Write-Debug "Show update to install: $($Update.Title)"
					
					Write-Debug "Send update to install collection"
					$objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
					$objCollectionTmp.Add($Update) | Out-Null
					
					$objInstaller = $objSession.CreateUpdateInstaller()
					$objInstaller.Updates = $objCollectionTmp
						
					Try
					{
						Write-Debug "Try install update"
						$InstallResult = $objInstaller.Install()
					} #End Try
					Catch
					{
						If($_ -match "HRESULT: 0x80240044")
						{
							Write-Warning "Your security policy don't allow a non-administator identity to perform this task"
						} #End If $_ -match "HRESULT: 0x80240044"
						
						Return
					} #End Catch
					
					If(!$NeedsReboot) 
					{ 
						Write-Debug "Set instalation status RebootRequired"
						$NeedsReboot = $installResult.RebootRequired 
					} #End If !$NeedsReboot
					
					Switch -exact ($InstallResult.ResultCode)
					{
						0   { $Status = "NotStarted"}
						1   { $Status = "InProgress"}
						2   { $Status = "Installed"}
						3   { $Status = "InstalledWithErrors"}
						4   { $Status = "Failed"}
						5   { $Status = "Aborted"}
					} #End Switch
				   
					Write-Debug "Add to log collection"
					$log = New-Object PSObject -Property @{
						Title = $Update.Title
						KB = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].KB
						Size = $UpdatesExtraDataCollection[$Update.Identity.UpdateID].Size
						Status = $Status
						X = 4
					} #End PSObject Property
					
					$log.PSTypeNames.Clear()
					$log.PSTypeNames.Add('PSWindowsUpdate.WUInstall')
					
					$log
				
					$NumberOfUpdate++
				} #End Foreach $Update in $objCollectionDownload
				Write-Progress -Activity "[4/$NumberOfStage] Installing updates" -Status "Completed" -Completed
				
				If($NeedsReboot)
				{
					If($AutoReboot)
					{
						Restart-Computer -Force
					} #End If $AutoReboot
					ElseIf($IgnoreReboot)
					{
						Return "Reboot is required, but do it manually."
					} #End Else $AutoReboot If $IgnoreReboot
					Else
					{
						$Reboot = Read-Host "Reboot is required. Do it now ? [Y/N]"
						If($Reboot -eq "Y")
						{
							Restart-Computer -Force
						} #End If $Reboot -eq "Y"
						
					} #End Else $IgnoreReboot	
					
				} #End If $NeedsReboot

				################################
				# End STAGE 4: Install updates #
				################################
				#endregion
			} #End If !$DownloadOnly
		} #End !$ListOnly
	} #End Process
	
	End{}		
} #In The End :)
