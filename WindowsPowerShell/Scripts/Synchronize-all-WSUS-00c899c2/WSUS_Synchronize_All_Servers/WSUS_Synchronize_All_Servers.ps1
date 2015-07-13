#Upstream WSUS server to synchronize and retrieve downstream servers to synchronize
$WsusUpstreamServer = "wsus.company.com"
$UseSSL = $false
$PortNumber = 80
$TrialRun = $true
$SleepTimer = 5

#E-mail Configuration
$SMTPServer = "smtp.company.com"
$FromAddress = "wsus@company.com"
$Recipients = "wsusadmins@company.com"
$MessageSubject = "WSUS Synchronization."

#HTML variables referenced during the script for output formatting
$sHTMLCellStyle = "`r`n<td style=`"font-family: Verdana, sans-serif; font-size: 11px; color: navy`">"
$sHTMLHeadingStyle = "`r`n<th style=`"font-family: Verdana, sans-serif; font-size: 12px; color: navy`">"
$sHtmlTableStyle = "`r`n<table border=`"1`", cellpadding=`"10`", cellspacing=`"0`", TABLE BORDER WIDTH=`"75%`">"
$sHTMLParagraphStyle = "`r`n<p style=`"font-family: Verdana, sans-serif; font-size: 12px; color: navy`">"

$script:MessageBody = "$sHtmlTableStyle <tr>$sHTMLHeadingStyle WSUS Server</th>$sHTMLHeadingStyle Parent WSUS Server</th>$sHTMLHeadingStyle WSUS Version</th>$sHTMLHeadingStyle Start</th>$sHTMLHeadingStyle Finish</th></tr>"
$script:ProcessedServers = @()

Function SendEmailStatus
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

Function PerformSynchronization($WsusServer, $ParentWsusServer)
{
	$errorActionPreference = "SilentlyContinue"
	$Start = Get-Date
	Write-Host "-------------------------"
	Write-Host "Upstream Server: $ParentWsusServer"
	Write-Host "Downstream Server: $WsusServer"
	If($script:ProcessedServers -Contains $WsusServer)
	{	Write-Host "$WsusServer appears to have already been processed. Skipping..."}
	Else
	{	Write-Host "Started processing $WsusServer at $Start"
		$script:ProcessedServers += $WsusServer
		$Error.Clear()
	  $WsusServerAdminProxy = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WsusServer,$UseSSL,$PortNumber);
		If ($? -eq $False)
		{
			$sTemp = $sHTMLCellStyle.Replace("<td", "<td colspan=9"); $sTemp = $sTemp.Replace("navy", "red")
			switch ($UseSSL)
			{
				$true {$script:MessageBody += "`r`n<tr>$sHTMLCellStyle $WsusServer</td>$sHTMLCellStyle $ParentWsusServer</td>$sTemp <b> Something went wrong connecting to the WSUS interface on $WsusServer using Port $PortNumber with SSL: <br> `r`n $Error</b></td></tr>"}
				$false {$script:MessageBody += "`r`n<tr>$sHTMLCellStyle $WsusServer</td>$sHTMLCellStyle $ParentWsusServer</td>$sTemp <b> Something went wrong connecting to the WSUS interface on $WsusServer using Port $PortNumber without SSL: <br> `r`n $Error</b></td></tr>"}
			}
			Write-Warning "Something went wrong connecting to the WSUS interface on $WsusServer server"
		}
		Else
		{
			Write-Host "Connected to the AdminProxy on $WsusServer"
			$Subscription = $WsusServerAdminProxy.GetSubscription();
			Write-Host "Connected to Subscription on $WsusServer"
			Write-Host "Calling PerformSynchronization on $WsusServer"
			If ($TrialRun)
			{$Finish = Get-Date; $script:MessageBody += "`r`n<tr>$sHTMLCellStyle $WsusServer</td>$sHTMLCellStyle $ParentWsusServer</td>$sHTMLCellStyle " + $WsusServerAdminProxy.Version + "</td>$sHTMLCellStyle $Start</td>$sHTMLCellStyle $Finish</td></tr>"}
			Else
			{$Subscription.StartSynchronization()
			Sleep $SleepTimer
			Write-Host "$WsusServer SynchronizationPhase is" $Subscription.GetSynchronizationProgress().Phase.ToString()
				While ($Subscription.GetSynchronizationProgress().Phase.ToString() -ne "NotProcessing")
				{
				Write-Host "$WsusServer SynchronizationPhase is" $Subscription.GetSynchronizationProgress().Phase.ToString()
				Sleep $SleepTimer
				}
			Write-Host "$WsusServer SynchronizationPhase is" $Subscription.GetSynchronizationProgress().Phase.ToString()
			$Finish = Get-Date; $script:MessageBody += "`r`n<tr>$sHTMLCellStyle $WsusServer</td>$sHTMLCellStyle $ParentWsusServer</td>$sHTMLCellStyle " + $WsusServerAdminProxy.Version + "</td>$sHTMLCellStyle $Start</td>$sHTMLCellStyle $Finish</td></tr>"}
			Write-Host "Finished processing $WsusServer at $Finish"
			$WsusDownstreamServers = $WsusServerAdminProxy.GetDownstreamServers()
			If ($WsusDownstreamServers.Count -gt 0)
			{
				Write-Host "-------------------------"
				Write-Host "Synchronizing downstream servers..."
				$WsusDownstreamServers | %{$WsusDownstreamServer = ($_.FullDomainName).ToLower(); PerformSynchronization $WsusDownstreamServer $WsusServer}
			}
		}
	}
}

#Connect to the WSUS 3.0 interface.
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
$errorActionPreference = "Continue"
$Error.Clear()
$WsusUpstreamServerAdminProxy = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($WsusUpstreamServer,$UseSSL,$PortNumber);
If ($? -eq $False)
{
	$MessageBody = ""
	$sHTMLCellStyle = $sHTMLCellStyle.Replace("navy", "red")
 	switch ($UseSSL)
	{
		$true {$MessageBody = "$sHtmlTableStyle `r`n<tr>$sHTMLCellStyle <b> Something went wrong connecting to the WSUS interface on $WsusServer using Port $PortNumber with SSL: <br> `r`n $Error</b></td></tr></table>"}
		$false {$MessageBody = "$sHtmlTableStyle `r`n<tr>$sHTMLCellStyle <b> Something went wrong connecting to the WSUS interface on $WsusServer using Port $PortNumber without SSL: <br> `r`n $Error</b></td></tr></table>"}
	}
	Write-Warning "Something went wrong connecting to the WSUS interface on $WsusUpstreamServer upstream server"
	SendEmailStatus
	Exit
}
Else
{
	Write-Host "-------------------------"
	Write-Host "Connected to upstream WSUS server $WsusUpstreamServer"
	PerformSynchronization $WsusUpstreamServer "--"
	$MessageBody += "</table>"
	SendEmailStatus
}