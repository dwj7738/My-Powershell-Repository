Function Get-WUList
{
	<#
	.SYNOPSIS
	    Get list of available updates meeting the criteria.

	.DESCRIPTION
	    Use Get-WUList to get list of available or installed updates meeting specific criteria.
		There are two types of filtering update: Pre search criteria, Post search criteria.
		- Pre search works on server side, like example: ( IsInstalled = 0 and IsHidden = 0 and CategoryIds contains '0fa1201d-4330-4fa8-8ae9-b877473b6441' )
		- Post search work on client side after downloading the pre-filtered list of updates, like example $KBArticleID -match $Update.KBArticleIDs

		Status list:
        D - IsDownloaded, I - IsInstalled, M - IsMandatory, H - IsHidden, U - IsUninstallable, B - IsBeta
		
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
		Pre search criteria. Finds updates that are marked as hidden on the destination computer.
	
	.PARAMETER IsNotHidden
		Pre search criteria. Finds updates that are not marked as hidden on the destination computer. Overwrite IsHidden param.
			
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
		
	.PARAMETER ComputerName	
	    Specify the name of the computer to the remote connection.

	.PARAMETER Debuger	
	    Debug mode.

	.EXAMPLE
		Get list of available updates from Microsoft Update Server.
	
		PS C:\> Get-WUList -MicrosoftUpdate

		ComputerName Status KB          Size Title
		------------ ------ --          ---- -----
		KOMPUTER     ------ KB976002  102 KB Aktualizacja firmy Microsoft z ekranem wybierania przegl¹darki dla u¿ytkowników...
		KOMPUTER     ------ KB971033    1 MB Aktualizacja dla systemu Windows 7 dla systemów opartych na procesorach x64 (KB...
		KOMPUTER     ------ KB2533552   9 MB Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2533552)
		KOMPUTER     ------ KB982861   37 MB Windows Internet Explorer 9 dla systemu Windows 7 - wersja dla systemów opartyc...
		KOMPUTER     D----- KB982670   48 MB Program Microsoft .NET Framework 4 Client Profile w systemie Windows 7 dla syst...
		KOMPUTER     ---H-- KB890830    1 MB Narzêdzie Windows do usuwania z³oœliwego oprogramowania dla komputerów z proces...

	.EXAMPLE
		Get information about updates from Microsoft Update Server that are installed on remote machine G1. Updates type are software, from specific category, have specific UUID and Revision Name.
		
		PS C:\> $UpdateIDs = "40336e0a-7b9b-45a0-89e9-9bd3ce0c3137","61bfe3ec-a1dc-4eab-9481-0d8fd7319ae8","0c737c40-b687-45bc-8
		deb-83db8209b258"
		PS C:\> Get-WUList -MicrosoftUpdate -IsInstalled -Type "Software" -CategoryIDs "E6CF1350-C01B-414D-A61F-263D14D133B4" -U
		pdateID $UpdateIDs -RevisionNumber 101 -ComputerName G1 -Verbose
		VERBOSE: Connecting to Microsoft Update server. Please wait...
		VERBOSE: Found [2] Updates in pre search criteria
		VERBOSE: Found [2] Updates in post search criteria

		ComputerName Status KB          Size Title
		------------ ------ --          ---- -----
		G1           DI--U- KB2345886 605 KB Aktualizacja dla systemu Windows 7 dla systemów opartych na procesorach x64 (KB...
		G1           DI--U- KB2641690  67 KB Aktualizacja systemu Windows 7 dla komputerów z procesorami x64 (KB2641690)

	.EXAMPLE
		Hide updates contains "Internet Explorer 9" in title and are in "Update Rollups" category.
		
		PS C:\> $UpdatesList = Get-WUList -ServiceID "9482f4b4-e343-43b6-b170-9a65bc822c77" -Title "Internet Explorer 9" -Catego
		ry "Update Rollups"
		PS C:\> $UpdatesList.IsHidden = $true
		PS C:\> Get-WUList -ServiceID "9482f4b4-e343-43b6-b170-9a65bc822c77" -Title "Internet Explorer 9" -Category "Update Roll
		ups" -IsHidden

		ComputerName Status KB          Size Title
		------------ ------ --          ---- -----
		KOMPUTER     ---H-- KB982861   37 MB Windows Internet Explorer 9 dla systemu Windows 7 - wersja dla systemów opartyc...

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
		Get-WUInstall
	#>

	[OutputType('PSWindowsUpdate.WUList')]
	[CmdletBinding(
		SupportsShouldProcess=$True,
		ConfirmImpact="High"
	)]	
	Param
	(
		#Pre search criteria
		[ValidateSet("Driver", "Software")]
		[String]$Type="",
		[String[]]$UpdateID,
		[Int]$RevisionNumber,
		[String[]]$CategoryIDs,
		[Switch]$IsInstalled,
		[Switch]$IsHidden,
		[Switch]$IsNotHidden,
		[String]$Criteria,
		[Switch]$ShowSearchCriteria,		
		
		#Post search criteria
		[String[]]$Category="",
		[String[]]$KBArticleID,
		[String]$Title,
		[Alias("Silent")]
		[Switch]$IgnoreUserInput,
		[Switch]$IgnoreRebootRequired,
		
		#Connection options
		[String]$ServiceID,
		[Switch]$WindowsUpdate,
		[Switch]$MicrosoftUpdate,
		
		#Mode options
		[Switch]$Debuger,
		[parameter(ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true)]
		[String[]]$ComputerName
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
		Write-Debug "STAGE 0: Prepare environment"
		######################################
		# Start STAGE 0: Prepare environment #
		######################################
		
		Write-Debug "Check if ComputerName in set"
		If($ComputerName -eq $null)
		{
			Write-Debug "Set ComputerName to localhost"
			[String[]]$ComputerName = $env:COMPUTERNAME
		} #End If $ComputerName -eq $null
		
		####################################			
		# End STAGE 0: Prepare environment #
		####################################
		
		$UpdateCollection = @()
		Foreach($Computer in $ComputerName)
		{
			If(Test-Connection -ComputerName $Computer -Quiet)
			{
				Write-Debug "STAGE 1: Get updates list"
				###################################
				# Start STAGE 1: Get updates list #
				###################################			

				If($Computer -eq $env:COMPUTERNAME)
				{
					Write-Debug "Create Microsoft.Update.ServiceManager object"
					$objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager" #Support local instance only
					Write-Debug "Create Microsoft.Update.Session object for $Computer"
					$objSession = New-Object -ComObject "Microsoft.Update.Session" #Support local instance only
				} #End If $Computer -eq $env:COMPUTERNAME
				Else
				{
					Write-Debug "Create Microsoft.Update.Session object for $Computer"
					$objSession =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$Computer))
				} #End Else $Computer -eq $env:COMPUTERNAME
				
				Write-Debug "Create Microsoft.Update.Session.Searcher object for $Computer"
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
				ElseIf($Computer -eq $env:COMPUTERNAME) #Support local instance only
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
				} #End Else $MicrosoftUpdate If $Computer -eq $env:COMPUTERNAME
				ElseIf($ServiceID)
				{
					$objSearcher.ServiceID = $ServiceID
					$objSearcher.ServerSelection = 3
					$serviceName = $ServiceID
				}
				Else #End Else $Computer -eq $env:COMPUTERNAME If $ServiceID
				{
					$serviceName = "default (for $Computer) Windows Update"
				} #End Else $ServiceID
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
						
						If($IsNotHidden) 
						{
							Write-Debug "Set pre search criteria: IsHidden = 0"
							$search += " and IsHidden = 0"	
						} #End If $IsNotHidden
						ElseIf($IsHidden) 
						{
							Write-Debug "Set pre search criteria: IsHidden = 1"
							$search += " and IsHidden = 1"	
						} #End ElseIf $IsHidden

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
					Return
				} #End Catch

				$NumberOfUpdate = 1
				$PreFoundUpdatesToDownload = $objResults.Updates.count
				Write-Verbose "Found [$PreFoundUpdatesToDownload] Updates in pre search criteria"				
				
				If($PreFoundUpdatesToDownload -eq 0)
				{
					Continue
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
								$UpdateAccess = $false
							} #End If !($UpdateCategories -match $Category)
							Else
							{
								$UpdateAccess = $true
								Break
							} #End Else !($UpdateCategories -match $Category)
						} #End Foreach $Cat in $Category	
					} #End If $Category -ne ""
					
					If($KBArticleID -ne $null)
					{
						Write-Debug "Set post search criteria: KBArticleIDs = '$([string]::join(", ", $KBArticleID))'"
						If(!($KBArticleID -match $Update.KBArticleIDs))
						{
							$UpdateAccess = $false
						} #End If !($KBArticleID -match $Update.KBArticleIDs)								
					} #End If $KBArticleID -ne $null

					If($Title)
					{
						Write-Debug "Set post search criteria: Title = '$Title'"
						If($Update.Title -notmatch $Title)
						{
							$UpdateAccess = $false
						} #End If $Update.Title -notmatch $Title
					} #End If $Title
					
					If($IgnoreUserInput)
					{
						Write-Debug "Set post search criteria: CanRequestUserInput"
						If($Update.InstallationBehavior.CanRequestUserInput -eq $true)
						{
							$UpdateAccess = $false
						} #End If $Update.InstallationBehavior.CanRequestUserInput -eq $true
					} #End If $IgnoreUserInput

					If($IgnoreRebootRequired) 
					{
						Write-Debug "Set post search criteria: RebootBehavior"
						If($Update.InstallationBehavior.RebootBehavior -ne 0)
						{
							$UpdateAccess = $false
						} #End If $Update.InstallationBehavior.RebootBehavior -ne 0	
					} #End If $IgnoreRebootRequired

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
						
						$Status = ""
				        If($Update.IsDownloaded)    {$Status += "D"} else {$status += "-"}
				        If($Update.IsInstalled)     {$Status += "I"} else {$status += "-"}
				        If($Update.IsMandatory)     {$Status += "M"} else {$status += "-"}
				        If($Update.IsHidden)        {$Status += "H"} else {$status += "-"}
				        If($Update.IsUninstallable) {$Status += "U"} else {$status += "-"}
				        If($Update.IsBeta)          {$Status += "B"} else {$status += "-"} 
		
						Add-Member -InputObject $Update -MemberType NoteProperty -Name ComputerName -Value $Computer
						Add-Member -InputObject $Update -MemberType NoteProperty -Name KB -Value $KB
						Add-Member -InputObject $Update -MemberType NoteProperty -Name Size -Value $size
						Add-Member -InputObject $Update -MemberType NoteProperty -Name Status -Value $Status
						
						$Update.PSTypeNames.Clear()
						$Update.PSTypeNames.Add('PSWindowsUpdate.WUList')
						$UpdateCollection += $Update
					} #End If $UpdateAccess -eq $true
					
					$NumberOfUpdate++
				} #End Foreach $Update in $objResults.Updates				
				Write-Progress -Activity "Post search updates for $Computer" -Status "Completed" -Completed
				
				$FoundUpdatesToDownload = $UpdateCollection.count
				Write-Verbose "Found [$FoundUpdatesToDownload] Updates in post search criteria"
				
				#################################
				# End STAGE 1: Get updates list #
				#################################
				
			} #End If Test-Connection -ComputerName $Computer -Quiet
		} #End Foreach $Computer in $ComputerName
		
		Return $UpdateCollection
		
	} #End Process
	
	End{}		
} #In The End :)