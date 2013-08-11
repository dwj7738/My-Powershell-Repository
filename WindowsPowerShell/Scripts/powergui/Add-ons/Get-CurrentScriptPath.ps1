function Get-CurrentScriptPath
{
	param()
	
	process {
		if ($Host.Name -eq 'PowerGUIScriptEditorHost') {
			[Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance.CurrentDocumentWindow.Document.Path
		} elseif ($Host.Name -eq 'Windows PowerShell ISE Host') {
			$psise.CurrentFile.FullPath
		}		
	}
}