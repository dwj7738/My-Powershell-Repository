#To retrieve an update GUID:
#	$Updates = $Wsus.SearchUpdates(‘Windows Server 2003 Service Pack 1’)
#	$Updates | Select Title, KnowledgebaseArticles, @{n="Guid";e={$_.ID.UpdateId.Guid}}

#$UpdateGUID = "e5077be1-da82-4c15-82d1-e4e8ff0a1264" #Windows XP Service Pack 2 
#$UpdateGUID = "77d5adc8-bb43-4701-a5e5-16875e4d155d" #Service Pack 2 for Windows XP Professional, x64 Edition
#$UpdateGUID = "ed9819f2-cfa5-4d60-b86a-60ba1783dc35" #Windows XP Service Pack 1 (Network Install)
#$UpdateGUID = "2824ec1f-3e2f-420e-a60e-06d4a5d807f1" #Windows Server 2003 Service Pack 1

$UpdateGUID = "<UpdateGUID>"

$WsusServer = "wsus.company.com"
$UseSSL = $false
$PortNumber = 80
$TrialRun = $True
$ShowDeclinedUpdates = $True
$Recursive = $True

#E-mail Configuration
$SMTPServer = "smtp.company.com"
$FromAddress = "wsus@company.com"
$Recipients = "wsusadmins@company.com"
$MessageSubject = "Decline updates superseded by" #this will be appended by the update title later on.

$Style = "<Style>" + `
	"BODY{background: linear-gradient(to right, #9A9A9A, #FFFFFF);" + `
	"font-size:12px;font-family:verdana,sans-serif;color:navy;font-weight:normal;}" + `
	"TABLE{background: linear-gradient(to right, #FFFFFF, #C0C0C0);border-width:1px;cellpadding=10;border-style:solid;border-color:navy;border-collapse:collapse;}" + `
	"TH{font-size:12px;border-width:1px;padding:10px;border-style:solid;border-color:navy;}" + `
	"TD{font-size:10px;border-width:1px;padding:10px;border-style:solid;border-color:navy;}" + `
	"</Style>"

Function Get-SupersededUpdates($Update)
{	#http://msdn.microsoft.com/en-us/library/microsoft.updateservices.administration.updaterelationship(v=vs.85).aspx
	Write-Host "Retrieving updates superseded by $($Update.KnowledgebaseArticles): $($Update.Title)"
	$SupersededUpdates = $Update.GetRelatedUpdates(([Microsoft.UpdateServices.Administration.UpdateRelationship]::UpdatesSupersededByThisUpdate))
	If($SupersededUpdates)
	{	Write-Host "$(([array]$SupersededUpdates).Count) update(s) found that are superseded by $($Update.KnowledgebaseArticles): $($Update.Title)"
		ForEach($SupersededUpdate in $SupersededUpdates)
		{	If(-not $SupersededUpdate.IsDeclined)
			{	$SupersededUpdateSummary = $SupersededUpdate.GetSummary($ComputerTargetScope)
				$SupersededUpdateNeededCount = $SupersededUpdateSummary.DownloadedCount + $SupersededUpdateSummary.NotInstalledCount
				Add-Member -InputObject $SupersededUpdate -MemberType NoteProperty -Name "NeededCount" -Value $SupersededUpdateNeededCount
				Add-Member -InputObject $SupersededUpdate -MemberType NoteProperty -Name "SupersededByKB" -Value $Update.KnowledgebaseArticles
				Add-Member -InputObject $SupersededUpdate -MemberType NoteProperty -Name "SupersededByTitle" -Value $Update.Title
				If($SupersededUpdateNeededCount -eq 0)
				{$script:SupersededUpdatesToDecline += $SupersededUpdate}
				Else
				{$script:SupersededUpdatesStillNeeded += $SupersededUpdate}
			}
			Else
			{	If($ShowDeclinedUpdates)
				{	Add-Member -InputObject $SupersededUpdate -MemberType NoteProperty -Name "NeededCount" -Value "~"
					Add-Member -InputObject $SupersededUpdate -MemberType NoteProperty -Name "SupersededByKB" -Value $Update.KnowledgebaseArticles
					Add-Member -InputObject $SupersededUpdate -MemberType NoteProperty -Name "SupersededByTitle" -Value $Update.Title
					$script:DeclinedSupersededUpdates += $SupersededUpdate
				}
			}
			If($Recursive){Get-SupersededUpdates $SupersededUpdate}
		}
	}
}

#Connect to the WSUS 3.0 interface.
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
$Wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WsusServer,$UseSSL,$PortNumber);
$ComputerTargetScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$Update = $Wsus.GetUpdate([guid]$UpdateGUID)
If($Update)
{	$MessageSubject += " $($Update.Title) ($($Update.KnowledgebaseArticles))"
	If($TrialRun){$MessageSubject += " Trial Run"}
	$script:SupersededUpdatesToDecline = @()
	$script:SupersededUpdatesStillNeeded = @()
	If($ShowDeclinedUpdates){$script:DeclinedSupersededUpdates = @()}
	Get-SupersededUpdates $Update
	If($script:SupersededUpdatesToDecline.Count -gt 0)
	{	If($TrialRun)
		{$script:SupersededUpdatesToDecline | %{Write-Host $_.Title would be declined}}
		Else
		{$script:SupersededUpdatesToDecline | %{$_.Decline(); Write-Host $_.Title declined}}
	}
	Else
	{Write-Warning "No updates found that have been superseded by $($Update.Title) ($($Update.KnowledgebaseArticles)) that are NOT needed!"}
	
	$UpdateTable = @{Name="Title";Expression={[string]$_.Title}},`
		@{Name="KB Article";Expression={[string]::join(' | ',$_.KnowledgebaseArticles)}},`
		@{Name="Classification";Expression={[string]$_.UpdateClassificationTitle}},`
		@{Name="Product Title";Expression={[string]::join(' | ',$_.ProductTitles)}},`
		@{Name="Product Family";Expression={[string]::join(' | ',$_.ProductFamilyTitles)}},`
		@{Name="Arrival Date";Expression={(Get-Date -Date $_.ArrivalDate -Format G)}},`
		@{Name="Needed Count";Expression={[string]$_.NeededCount}},`
		@{Name="Superseded By KB";Expression={[string]$_.SupersededByKB}},`
		@{Name="Superseded By Title";Expression={[string]$_.SupersededByTitle}}
	
	$OutputSupersededUpdatesToDecline = ""
	If($script:SupersededUpdatesToDecline.Count -gt 0)
	{	$OutputSupersededUpdatesToDecline = $script:SupersededUpdatesToDecline | Select `
		$UpdateTable | ConvertTo-Html -PreContent "<h4>Updates Declined ($($script:SupersededUpdatesToDecline.Count))</h4>" -Fragment | Out-String
	}

	$OutputSupersededUpdatesStillNeeded = ""
	If($script:SupersededUpdatesStillNeeded.Count -gt 0)
	{	$OutputSupersededUpdatesStillNeeded = $script:SupersededUpdatesStillNeeded | Select `
		$UpdateTable | ConvertTo-Html -PreContent "<h4>Updates Still Needed ($($script:SupersededUpdatesStillNeeded.Count))</h4>" -Fragment | Out-String
	}
	
	If($ShowDeclinedUpdates)
	{	$OutputDeclinedSupersededUpdates = ""
		If($script:DeclinedSupersededUpdates.Count -gt 0)
		{	$OutputDeclinedSupersededUpdates = $script:DeclinedSupersededUpdates | Select `
			$UpdateTable | ConvertTo-Html -PreContent "<h4>Previously Declined Superseded Updates ($($script:DeclinedSupersededUpdates.Count))</h4>" -Fragment | Out-String
		}
	}

	If($OutputSupersededUpdatesToDecline -Or $OutputSupersededUpdatesStillNeeded -Or $OutputDeclinedSupersededUpdates)
	{	$PostContent = ""
		If($OutputSupersededUpdatesToDecline){$PostContent += $OutputSupersededUpdatesToDecline}
		If($OutputSupersededUpdatesStillNeeded){$PostContent += $OutputSupersededUpdatesStillNeeded}
		If($OutputDeclinedSupersededUpdates){$PostContent += $OutputDeclinedSupersededUpdates}
		$MessageBody = (ConvertTo-HTML -head $Style -PreContent "<h3>$MessageSubject.</h3>" -PostContent $PostContent | out-string)
		$MessageBody = $MessageBody.Replace("<table>`r`n</table>", "")
		Send-MailMessage -From $FromAddress -To $Recipients -Subject $MessageSubject -SmtpServer $SmtpServer -BodyAsHtml -Body $MessageBody
	}
}
Else
{Write-Error "Update Guid $UpdateGUID not found!"}