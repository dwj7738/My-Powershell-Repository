function Select-TextInEditor
{
	param(
	[Parameter(Mandatory=$true,ParameterSetName='Region',ValueFromPipelineByPropertyName=$true)]
	[int]$StartLine,
	
	[Parameter(Mandatory=$true,ParameterSetName='Region',ValueFromPipelineByPropertyName=$true)]	
	[int]$StartColumn,
	
	[Parameter(Mandatory=$true,ParameterSetName='Region',ValueFromPipelineByPropertyName=$true)]	
	[int]$EndLine,
	
	[Parameter(Mandatory=$true,ParameterSetName='Region',ValueFromPipelineByPropertyName=$true)]	
	[int]$EndColumn,
    
    [Parameter(ParameterSetName='All',Mandatory=$true)]
    [Switch]$All
	)
	
	process {        
		$document = Get-CurrentDocument -Editor
        if ($psCmdlet.ParameterSetName -eq 'All') {
            if ($Host.Name -eq "Windows PowerShell ISE Host") {
				$document.Select(1,1,$document.LineCount, $document.GetLineLength($document.LineCount) + 1)
			} elseif ($Host.Name -eq "PowerGUIScriptEditorHost") {
				$document.Select(1,1,$document.Lines.Count, @($document.Lines[-1]).Length)
			}
			
        } else {                
			$document.Select($StartLine, $StartColumn, $EndLine, $EndColumn)
			$document.EnsureVisible($EndLine)
        }
	}
}
