function Get-EditorCaretPosition
{
	param()
	
	process 
	{
        $document = Get-CurrentDocument -Editor 
		if ($Host.Name -eq "Windows PowerShell ISE Host") {
			New-Object PSObject -Property @{
				CaretLine = $document.CaretLine
				CaretColumn = $document.CaretColumn
			} 			
		} elseif ($Host.Name -eq "PowerGUIScriptEditorHost") {
			$pgse = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
			# In PowerGUI, the Selection can throw this information off
			if ($document.SelectedText) {
				$lines = $document.SelectedText | 
					Measure-Object -Line | 
					Select-Object -ExpandProperty Lines					
				$lines--
				if (-not $lines) {
					New-Object PSObject -Property @{
						CaretLine = $document.CaretLine
						CaretColumn = $document.CaretCharacter - 
							$document.SelectedText.Length
					}
				} else {
					$lineCount = $lines
					$firstLine = $document.SelectedText -split ([Environment]::NewLine) |
						Select-Object -First 1 
					$lineNumber = $document.CaretLine - $lineCount -1 
					$lineInDoc = $document.Lines[$lineNumber + 1]
					$col = $lineInDoc.IndexOf($firstLine)
					New-Object PSObject @{
						CaretLine = $lineNumber
						CaretColumn = $col
					}
				}
			} else {
				New-Object PSObject -Property @{
					CaretLine = $document.CaretLine
					CaretColumn = $document.CaretCharacter
				}
			}
		}
	}

}