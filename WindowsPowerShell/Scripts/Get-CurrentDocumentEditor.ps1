function Get-CurrentDocumentEditor
{
	param()
	
	process {
		if ($Host.Name -eq 'PowerGUIScriptEditorHost') {
			[Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance.CurrentDocumentWindow.Document
		} elseif ($Host.Name -eq 'Windows PowerShell ISE Host') {
			$psise.CurrentFile.Editor
		}		
	}
}