function Add-TextToCurrentDocument
{
	param(
	[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]                                            # allow empty string added by bernd_k
	[string]
	$Text
	)
	
	if ($Host.Name -eq 'PowerGUIScriptEditorHost') {
        # there might be minor problems caused by the difference of column and character
        if ($Text -eq '') {
            $pgse.CurrentDocumentWindow.Document.SelectedText = ''
            # caret moves to start of deleted selection: OK
        } else {
            # for Ise compatibility here too
            $pgse.CurrentDocumentWindow.Document.SelectedText = ''

    	    $l = $pgSE.CurrentDocumentWindow.Document.CaretLine
    	    $c = $pgSE.CurrentDocumentWindow.Document.CaretCharacter	# not CaretColumn
            $lines = $Text | Measure-Object -Line | 
					Select-Object -ExpandProperty Lines
            $lastline = ($Text -split ([Environment]::NewLine))[$lines -1]
            $chars = $lastline.length 	    
    		$pgSE.CurrentDocumentWindow.Document.Insert($text, $l, $c)
            Set-EditorCaretPosition ($l + $lines - 1)  ($c + $chars)
        }	
	} elseif ($Host.Name -eq 'Windows PowerShell ISE Host') {
# 	    $l = $psise.CurrentFile.Editor.CaretLine
# 	    $c = $psise.CurrentFile.Editor.CaretColumn 
        # the value needs to be refreshed before it is accurate   
        $refresh = $psise.CurrentFile        
                   
	    $psise.CurrentFile.Editor.InsertText($text)
        # if something is selected, it will be replaced		
        # Caret ends at end of inserted text
	}
}