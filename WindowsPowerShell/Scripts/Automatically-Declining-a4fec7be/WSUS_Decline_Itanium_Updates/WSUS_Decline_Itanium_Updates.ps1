$WsusServer = "wsus.company.com"
$UseSSL = $false
$PortNumber = 80
$TrialRun = $true

#E-mail Configuration
$SMTPServer = "smtp.company.com"
$FromAddress = "wsus@company.com"
$Recipients = "wsusadmins@company.com"
$MessageSubject = "WSUS :: Declining Itanium Updates"

Function SendEmailStatus($MessageSubject, $MessageBody)
{
	$SMTPMessage = New-Object System.Net.Mail.MailMessage $FromAddress, $Recipients, $MessageSubject, $MessageBody
	$SMTPMessage.IsBodyHTML = $true
	#Send the message via the local SMTP Server
	$SMTPClient = New-Object System.Net.Mail.SMTPClient $SMTPServer
	$SMTPClient.Send($SMTPMessage)
	$SMTPMessage.Dispose()
	rv SMTPClient
	rv SMTPMessage
}

#Connect to the WSUS 3.0 interface.
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
$WsusServerAdminProxy = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WsusServer,$UseSSL,$PortNumber);

#$itanium = $WsusServerAdminProxy.SearchUpdates('Itanium') | ?{-not $_.IsDeclined}
#$itanium += $WsusServerAdminProxy.SearchUpdates('ia64') | ?{-not $_.IsDeclined}
#Although the above seems faster it also seaches in the description of the update so use the below just to search the title!
$itanium = $WsusServerAdminProxy.GetUpdates() | ?{-not $_.IsDeclined -and $_.Title -match “ia64|itanium”}
If ($TrialRun)
{$MessageSubject += " Trial Run"}
Else
{$itanium | %{$_.Decline()}}

$Style = "<Style>BODY{font-size:11px;font-family:verdana,sans-serif;color:navy;font-weight:normal;}" + `
	"TABLE{border-width:1px;cellpadding=10;border-style:solid;border-color:navy;border-collapse:collapse;}" + `
	"TH{font-size:12px;border-width:1px;padding:10px;border-style:solid;border-color:navy;}" + `
	"TD{font-size:10px;border-width:1px;padding:10px;border-style:solid;border-color:navy;}</Style>"

If ($itanium.Count -gt 0)
{
	$MessageBody = $itanium | Select `
	@{Name="Title";Expression={[string]$_.Title}},`
	@{Name="KB Article";Expression={[string]::join(' | ',$_.KnowledgebaseArticles)}},`
	@{Name="Classification";Expression={[string]$_.UpdateClassificationTitle}},`
	@{Name="Product Title";Expression={[string]::join(' | ',$_.ProductTitles)}},`
	@{Name="Product Family";Expression={[string]::join(' | ',$_.ProductFamilyTitles)}},`
	@{Name="Uninstallation Supported";Expression={[string]$_.UninstallationBehavior.IsSupported}} | ConvertTo-HTML -head $Style
	SendEmailStatus $MessageSubject $MessageBody
}