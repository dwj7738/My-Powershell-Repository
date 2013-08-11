function Add-CommentHelp {
    <#
    .Synopsis
        Adds comment help to the ISE
    .Description
        Adds comment help to a file in the        
    .Example
        Add-CommentHelp "Adds Comment Help to the ISE" "Adds Comment Help to a File in the Windows PowerShell Integrated Scripting Environment (ISE)" -Example '1', '2', '3'
    #>
    param(
    #The name of the parameter
        
    <#
    A short parameter synopsis
    #>
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        HelpMessage='A short parameter synopsis')]
    [string]
    $Synopsis,

    <#
    A longer parameter description.  
    #>
    [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true,
        HelpMessage='A longer parameter description.',Position='1')]
    [string]
    $Description,

        
    <#
    A related command
    #>
    [Parameter(ValueFromPipelineByPropertyName=$true,
        HelpMessage='A related command',
        Position='2')]
    [Alias('SeeAlso')]
    [string]
    $Link,


    <#
    An example
    #>
    [Parameter(ValueFromPipelineByPropertyName=$true,HelpMessage='A related command',Position='2')]
    [string]
    $Example,


        
    <#
    Any additional notes
    |LinesForInput 10
    #>
    [Parameter(ValueFromPipelineByPropertyName=$true,HelpMessage='Additional notes',Position='3')]
    [string]
    $Notes,
		
	[Parameter(ValueFromPipelineByPropertyName=$true)]
	[Switch]$OutputText
    ) 
	
	process {
	
	    $helptext= "
    <#    
    .SYNOPSIS
        $Synopsis
    .DESCRIPTION
        $Description
    $(if ($example) {
    ".EXAMPLE
        $example"
    })

    $(if ($link) {
    ".LINK
        $link"
    })
    $(if ($notes) {
    ".NOTES
        $notes"
    })
    
".TrimEnd() + "
    #>
"
	   
	    
		if ($OutputText) {
            $helptext
		} else {
            
                Add-TextToCurrentDocument -Text "$helpText"
            		}
		
	
	}
}
