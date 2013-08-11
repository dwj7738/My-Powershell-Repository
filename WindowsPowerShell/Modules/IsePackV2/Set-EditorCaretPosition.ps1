function Set-EditorCaretPosition
{
	param(
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
	[ValidateRange(1,1073741824)]	
	[Alias('StartLine','CaretLine')]
	[Int]
	$Line,
	
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]	
	[ValidateRange(1,1073741824)]	
	[Alias('StartColumn','CaretColumn','CaretCharacter')]
	[Int]
	$Column
	)
	
	process 
	{
		if ($Host.Name -eq "Windows PowerShell ISE Host") {
			$document = $psise.CurrentFile.Editor
		} elseif ($Host.Name -eq "PowerGUIScriptEditorHost") {
			$document = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance.CurrentDocumentWindow.Document
		}
		$document.SetCaretPosition($Line, $Column)
		$document.EnsureVisible($Line)
	}

}