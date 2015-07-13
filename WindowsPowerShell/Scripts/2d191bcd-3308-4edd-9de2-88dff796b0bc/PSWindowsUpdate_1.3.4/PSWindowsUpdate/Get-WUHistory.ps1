Function Get-WUHistory
{
	<#
	.SYNOPSIS
	    Get list of updates history.

	.DESCRIPTION
	    Use function Get-WUHistory to get list of installed updates on current machine.
	       
	.PARAMETER HotFix
	    More info about specyfic update or group of updates.
      		
	.EXAMPLE
        Get-WUHistory | Format-Table * -AutoSize

		KBArticle   Date                Title
		---------   ----                -----
		            2011-04-16 10:14:54 Network Monitor 3.4
		(KB2466146) 2011-04-16 10:11:32 Aktualizacja zabezpieczeñ dla programu Microsoft Excel 2010, wersja 64-bitowa (KB246...
		(KB982305)  2011-04-16 10:11:00 Microsoft Visual Studio 2010 Tools for Office Runtime x64 (KB982305)
		(KB2467175) 2011-04-16 10:09:14 Aktualizacja zabezpieczeñ pakietu redystrybucyjnego programu Microsoft Visual C++ 20...
		(KB982726)  2011-04-16 10:05:50 Aktualizacja definicji dla pakietu Microsoft Office 2010 (KB982726), wersja 64-bitowa
		(KB2519975) 2011-04-16 10:05:16 Aktualizacja zabezpieczeñ programu Microsoft PowerPoint 2010 (KB2519975), wersja 64-...
		(KB2508272) 2011-04-16 10:04:51 Zbiorcza aktualizacja zabezpieczeñ funkcji Killbit formantów ActiveX w systemie Wind...
		(KB2467173) 2011-04-16 10:03:53 Aktualizacja zabezpieczeñ pakietu redystrybucyjnego programu Microsoft Visual C++ 20...        
		
	.EXAMPLE  
		Get-WUHistory -HotFix KB2416400

		KBArticle           : (KB2416400)
		Operation           : 1
		ResultCode          : 2
		HResult             : 0
		Date                : 2011-01-21 13:03:36
		UpdateIdentity      : System.__ComObject
		Title               : Zbiorcza aktualizacja zabezpieczeñ programu Internet Explorer 8 dla systemu Windows 7 x64 (KB2416
		                      400)
		Description         : Stwierdzono wystêpowanie problemów dotycz¹cych zabezpieczeñ, które mog¹ umo¿liwiæ osobie atakuj¹c
		                      ej uzyskanie dostêpu do komputera z programem Microsoft Internet Explorer i przejêcie nad nim kon
		                      troli. U¿ytkownik mo¿e ochroniæ swój komputer, instaluj¹c tê aktualizacjê z firmy Microsoft. Po z
		                      ainstalowaniu tego elementu mo¿e byæ konieczne ponowne uruchomienie komputera.
		UnmappedResultCode  : 0
		ClientApplicationID : AutomaticUpdates
		ServerSelection     : 1
		ServiceID           :
		UninstallationSteps : System.__ComObject
		UninstallationNotes : Tê aktualizacjê oprogramowania mo¿na usun¹æ, wybieraj¹c opcjê Wyœwietl zainstalowane aktualizacje
		                       w aplecie Programy i funkcje w Panelu sterowania.
		SupportUrl          : http://support.microsoft.com/?kbid=2416400
		Categories          : System.__ComObject

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://code.msdn.microsoft.com/PSWindowsUpdate

	.LINK
		Get-WUList
		
	#>
	
	[CmdletBinding(
        SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param
	(
		[String]$HotFix
	)

	Begin{}
	
	Process
	{
    	if ($pscmdlet.ShouldProcess($Env:COMPUTERNAME,"Get updates history")) 
		{
			$objSession = New-Object -ComObject "Microsoft.Update.Session"

	    	$objSearcher = $objSession.CreateUpdateSearcher()
	    	$count = $objSearcher.GetTotalHistoryCount()

	    	if($count -gt 0)
	    	{
	        	$objHistory = $objSearcher.QueryHistory(0, $count)

				if($HotFix -eq "")
				{
					$objHistory | Select-Object @{e={($_.Title.Replace(',', '').Split(' ') | Where-Object{$_ -like "(KB*)*"}).Replace('{}', '')};n='KBArticle'}, Date, Title
				}
				else
				{
					$objHistory | Where-Object{$_.Title -match $HotFix} | Select-Object @{e={($_.Title.Replace(',', '').Split(' ') | Where-Object{$_ -like "(KB*)*"}).Replace('{}', '')};n='KBArticle'}, *
				}
	    	}
	    	else
	    	{
	    	    Write-Host "Probably your history was cleared. Alternative please run 'Get-WUList -IsInstalled'"
	    	}
		}
	
	}

	End{}	
}
