Param(
	$WsusServer = ([system.net.dns]::GetHostByName('localhost')).hostname,
	[switch]$Recursive,
	[bool]$TrialRun = $False,
	[string]$SmtpServer = "smtp.company.com",
	[string]$From = "wsus@company.com",
	[string]$To = "wsus@company.com",
	[string]$Subject = "WSUS Server Cleanup.",
	[switch]$EmailLog
)
Begin
{	$script:CurrentErrorActionPreference = $ErrorActionPreference
	$script:Output = @()
	$script:ProcessedServers = @()
	$WsusAssembly = [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
	If($WsusAssembly -eq $Null)
	{	throw "Loading Microsoft.UpdateServices.Administration failed. Are you running this on a machine with the WSUS 3.0 SP2 Administration Console installed? http://technet.microsoft.com/en-us/library/dd939875(v=ws.10).aspx"}

	$ErrorActionPreference = "SilentlyContinue"
	If($EmailLog)
	{	If($Recursive)
		{	$Table = @{Name="Parent Wsus Server";expression={$_.ParentWsusServer}},@{Name="Wsus Server";expression={$_.WsusServer}},@{Name="Port Number";expression={$_.PortNumber}},@{Name="Using SSL";expression={$_.UsingSSL}},@{Name="Version";expression={$_.Version}},@{Name="Start";expression={$_.Start}},@{Name="Finish";expression={$_.Finish}}
		}
		Else
		{	$Table = @{Name="Wsus Server";expression={$_.WsusServer}},@{Name="Port Number";expression={$_.PortNumber}},@{Name="Using SSL";expression={$_.UsingSSL}},@{Name="Version";expression={$_.Version}},@{Name="Start";expression={$_.Start}},@{Name="Finish";expression={$_.Finish}}
		}
		If($TrialRun -eq $False)
		{	$Table += @{Name="Superseded Updates Declined";expression={$_.SupersededUpdatesDeclined}},@{Name="Expired Updates Declined";expression={$_.ExpiredUpdatesDeclined}},@{Name="Obsolete Updates Deleted";expression={$_.ObsoleteUpdatesDeleted}},@{Name="Updates Compressed";expression={$_.UpdatesCompressed}},@{Name="Obsolete Computers Deleted";expression={$_.ObsoleteComputersDeleted}},@{Name="Disk Space Freed (MB)";expression={$_.DiskSpaceFreed}}
		}
		$Style = "<Style>BODY{font-size:12px;font-family:verdana,sans-serif;color:navy;font-weight:normal;}" + `
		"TABLE{border-width:1px;cellpadding=10;border-style:solid;border-color:navy;border-collapse:collapse;}" + `
		"TH{font-size:12px;border-width:1px;padding:10px;border-style:solid;border-color:navy;}" + `
		"TD{font-size:10px;border-width:1px;padding:10px;border-style:solid;border-color:navy;}</Style>"
		Function SendEmailStatus($From, $To, $Subject, $SmtpServer, $BodyAsHtml, $Body)
		{	$SmtpMessage = New-Object System.Net.Mail.MailMessage $From, $To, $Subject, $Body
			$SmtpMessage.IsBodyHTML = $BodyAsHtml
			$SmtpClient = New-Object System.Net.Mail.SmtpClient $SmtpServer
			$SmtpClient.Send($SmtpMessage)
			If($? -eq $False){Write-Warning "$($Error[0].Exception.Message) | $($Error[0].Exception.GetBaseException().Message)"}
			$SmtpMessage.Dispose()
			rv SmtpClient
			rv SmtpMessage
		}
	}

	$CleanupScope = New-Object Microsoft.UpdateServices.Administration.CleanupScope
	$CleanupScope | Get-Member -MemberType Property | %{$CleanupScope."$($_.Name)" = $True}
	#$CleanupScope.CleanupObsoleteComputers = $CleanupScope.CleanupObsoleteUpdates = $CleanupScope.CleanupUnneededContentFiles = $CleanupScope.CompressUpdates = $CleanupScope.DeclineExpiredUpdates = $CleanupScope.DeclineSupersededUpdates = $true
	
	function Get-HKLMValue
	{	Param(
  		[string]$computername=".",
  		[string]$key = "SOFTWARE\Microsoft\Update Services\Server\Setup",
  		[string]$value,
  		[switch]$REG_SZ,
  		[switch]$REG_DWORD
  	)
		$HKLM = 2147483650
		$reg = [wmiclass]"\\$computername\root\default:StdRegprov"
		If($REG_SZ)
		{	$Result = $reg.GetStringValue($HKLM,$key,$value)
			If($Result.ReturnValue -eq 0){$Result.sValue}
		}
		If($REG_DWORD)
		{	$Result = $reg.GetDwordValue($HKLM,$key,$value)
			If($Result.ReturnValue -eq 0){$Result.uValue}
		}
	}
	
	Function Cleanup-WsusServer
	{	Param(
			$WsusServer,
			$ParentWsusServer
		)
		Write-Progress -Activity "Processing server: $WsusServer" -Status "Started at $((get-date).DateTime)" -ID 2 -ParentID 1
		Write-Progress -Activity "Retrieving PortNumber value from the registry via StdRegprov ..." -Status "Started at $((get-date).DateTime)" -ID 3 -ParentID 2
		$PortNumber = Get-HKLMValue -Computername $WsusServer -value PortNumber -REG_DWORD
		Write-Progress -Activity "Retrieving UsingSSL value from the registry via StdRegprov ..." -Status "Started at $((get-date).DateTime)" -ID 3 -ParentID 2
		$UsingSSL = If((Get-HKLMValue -Computername $WsusServer -value UsingSSL -REG_DWORD) -eq 1){$True}Else{$False}
		If($UsingSSL)
		{ Write-Progress -Activity "Retrieving ServerCertificateName value from the registry via StdRegprov ..." -Status "Started at $((get-date).DateTime)" -ID 3 -ParentID 2
			$ServerCertificateName = Get-HKLMValue -Computername $WsusServer -value ServerCertificateName -REG_SZ
			If($ServerCertificateName){$WsusServer = $ServerCertificateName}
		}
		If($script:ProcessedServers -Contains $WsusServer)
		{	Write-Warning "$WsusServer appears to have already been processed. You may have a circular loop in your hierarchy."}
		Else
		{	$script:ProcessedServers += $WsusServer
			$Object = New-Object psobject
			If($Recursive)
			{	If(!$ParentWsusServer){$ParentWsusServer = "--"}
				$Object | Add-Member NoteProperty ParentWsusServer $ParentWsusServer
			}
			$Object | Add-Member NoteProperty WsusServer $WsusServer -PassThru | Add-Member NoteProperty PortNumber $PortNumber -PassThru | 
				Add-Member NoteProperty UsingSSL $UsingSSL -PassThru | Add-Member NoteProperty Version "" -PassThru |
				Add-Member NoteProperty Start (get-date).DateTime -PassThru | Add-Member NoteProperty Finish ""
			If($TrialRun -eq $False)
			{	$Object | Add-Member NoteProperty SupersededUpdatesDeclined "" -PassThru | Add-Member NoteProperty ExpiredUpdatesDeclined "" -PassThru |
				Add-Member NoteProperty ObsoleteUpdatesDeleted "" -PassThru | Add-Member NoteProperty UpdatesCompressed "" -PassThru |
				Add-Member NoteProperty ObsoleteComputersDeleted "" -PassThru | Add-Member NoteProperty DiskSpaceFreed  ""
			}
			Write-Progress -Activity "Connecting to UpdateServices AdminProxy..." -Status "Started at $((get-date).DateTime)" -ID 3 -ParentID 2
			$WsusServerAdminProxy = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WsusServer,$UsingSSL,$PortNumber)
			If ($? -eq $False)
			{	$Object.Version = $Error[0]
				Write-Warning "Failed to connect to $WsusServer $($Error[0])"
				$Object.Finish = (get-date).DateTime
				$Object
				If($EmailLog){$script:Output += $Object}
			}
			Else
			{	$Object.Version = $WsusServerAdminProxy.Version
				If($TrialRun -eq $False)
				{	Write-Progress -Activity "Connecting to the CleanupManager..." -Status "Started at $((get-date).DateTime)" -ID 3 -ParentID 2
					$CleanupManager = $WsusServerAdminProxy.GetCleanupManager()
					Write-Progress -Activity "Calling PerformCleanup on $WsusServer" -Status "Started at $((get-date).DateTime)" -ID 3 -ParentID 2
					$CleanupResults = $CleanupManager.PerformCleanup($CleanupScope)
					$Object.SupersededUpdatesDeclined = $CleanupResults.SupersededUpdatesDeclined
					$Object.ExpiredUpdatesDeclined = $CleanupResults.ExpiredUpdatesDeclined
					$Object.ObsoleteUpdatesDeleted = $CleanupResults.ObsoleteUpdatesDeleted
					$Object.UpdatesCompressed = $CleanupResults.UpdatesCompressed
					$Object.ObsoleteComputersDeleted = $CleanupResults.ObsoleteComputersDeleted
					$Object.DiskSpaceFreed = ([math]::truncate($CleanupResults.DiskSpaceFreed/1MB))
				}
				$Object.Finish = (get-date).DateTime
				$Object
				If($EmailLog){$script:Output += $Object}
				If($Recursive)
				{	Write-Progress -Activity "Retrieving Downstream Servers on $WsusServer..." -Status "Started at $((get-date).DateTime)" -ID 3 -ParentID 2
					$WsusDownstreamServers = $WsusServerAdminProxy.GetDownstreamServers()
					If($WsusDownstreamServers){$WsusDownstreamServers | %{Cleanup-WsusServer -WsusServer $_.FullDomainName -ParentWsusServer $WsusServer}}
				}
			}
		}
	}
	Write-Progress -Activity "WSUS Server Cleanup." -Status "Started at $((get-date).DateTime)" -ID 1

}
Process
{	If($WsusServer)
	{	ForEach($Server in $WsusServer){Cleanup-WsusServer $Server}
	}
	Else
	{	Cleanup-WsusServer $_
	}
}
End
{	If($EmailLog){SendEmailStatus -From $From -To $To -Subject $Subject -SmtpServer $SmtpServer -BodyAsHtml $True -Body ($Output | Select $Table | ConvertTo-HTML -head $Style)}
	$ErrorActionPreference = $script:CurrentErrorActionPreference
}