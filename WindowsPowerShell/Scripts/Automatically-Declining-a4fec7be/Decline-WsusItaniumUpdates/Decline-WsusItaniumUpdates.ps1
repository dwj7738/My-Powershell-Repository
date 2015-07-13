Param(
	[string]$WsusServer = ([system.net.dns]::GetHostByName('localhost')).hostname,
	[bool]$UseSSL = $False,
	[int]$PortNumber = 80,
	[bool]$TrialRun = $True,
	[bool]$EmailLog = $True,
	[string]$SMTPServer = "smtp.company.tld",
	[string]$From = "wsusadmins@company.tld",
	[string]$To = "wsusadmins@company.tld",
	[string]$Subject = "WSUS :: Declining Itanium Updates"
)
$script:CurrentErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$Style = "<Style>BODY{font-size:12px;font-family:verdana,sans-serif;color:navy;font-weight:normal;}" + `
			"TABLE{border-width:1px;cellpadding=10;border-style:solid;border-color:navy;border-collapse:collapse;}" + `
			"TH{font-size:12px;border-width:1px;padding:10px;border-style:solid;border-color:navy;}" + `
			"TD{font-size:10px;border-width:1px;padding:10px;border-style:solid;border-color:navy;}</Style>"
If($TrialRun){$Subject += " Trial Run"}
Function SendEmailStatus($From, $To, $Subject, $SMTPServer, $BodyAsHtml, $Body)
{	$SMTPMessage = New-Object System.Net.Mail.MailMessage $From, $To, $Subject, $Body
	$SMTPMessage.IsBodyHTML = $BodyAsHtml
	$SMTPClient = New-Object System.Net.Mail.SMTPClient $SMTPServer
	$SMTPClient.Send($SMTPMessage)
	If($? -eq $False){Write-Warning "$($Error[0].Exception.Message) | $($Error[0].Exception.GetBaseException().Message)"}
	$SMTPMessage.Dispose()
	rv SMTPClient
	rv SMTPMessage
}

#Connect to the WSUS 3.0 interface.
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
$WsusServerAdminProxy = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WsusServer,$UseSSL,$PortNumber);
If($? -eq $False)
{	Write-Warning "Something went wrong connecting to the WSUS interface on $WsusServer server: $($Error[0].Exception.Message)"
	If($EmailLog)
	{	$Body = ConvertTo-Html -head $Style -Body "Something went wrong connecting to the WSUS interface on $WsusServer server: $($Error[0].Exception.Message)" | Out-String
		$Body = $Body.Replace("<table>`r`n</table>", "")
		SendEmailStatus -From $From -To $To -Subject $Subject -SmtpServer $SmtpServer -BodyAsHtml $True -Body $Body
	}
	$ErrorActionPreference = $script:CurrentErrorActionPreference
	Return
}

#$ItaniumUpdates = $WsusServerAdminProxy.SearchUpdates('Itanium') | ?{-not $_.IsDeclined}
#$ItaniumUpdates += $WsusServerAdminProxy.SearchUpdates('ia64') | ?{-not $_.IsDeclined}
#Although the above seems faster it also seaches in the description of the update so use the below just to search the title!
$ItaniumUpdates = $WsusServerAdminProxy.GetUpdates() | ?{-not $_.IsDeclined -and $_.Title -match “ia64|itanium”}
If($ItaniumUpdates)
{
	If($TrialRun -eq $False){$ItaniumUpdates | %{$_.Decline()}}
	$Table = @{Name="Title";Expression={[string]$_.Title}},`
		@{Name="KB Article";Expression={[string]::join(' | ',$_.KnowledgebaseArticles)}},`
		@{Name="Classification";Expression={[string]$_.UpdateClassificationTitle}},`
		@{Name="Product Title";Expression={[string]::join(' | ',$_.ProductTitles)}},`
		@{Name="Product Family";Expression={[string]::join(' | ',$_.ProductFamilyTitles)}}
	$ItaniumUpdates | Select $Table
	If($EmailLog)
	{	$Body = $ItaniumUpdates | Select $Table | ConvertTo-HTML -head $Style
		SendEmailStatus -From $From -To $To -Subject $Subject -SmtpServer $SmtpServer -BodyAsHtml $True -Body $Body
	}
}
Else
{"No Itanium Updates found that needed declining. Come back next 'Patch Tuesday' and you may have better luck."}
$ErrorActionPreference = $script:CurrentErrorActionPreference