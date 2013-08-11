function Save-Function
{
    <#
    .Synopsis
        Saves one or more functions into automatically named files (i.e. Invoke-MyFunction.ps1)
    .Description
        Saves functions into automatically named files.
         
    #>
    param(    
    # A script block.  When provided an external script, 
    # Save-Function will determine if that script contains functions or not
    [Parameter(ParameterSetName='ScriptBlock',
        Mandatory=$true,
        ValueFromPipeline=$true)]
    [ScriptBlock]
    $ScriptBlock,
    
    # The root directory to store the new file in
    [String]
    $Root = $Pwd
    ) 
    
    process {
        $tokens = [Management.Automation.PSParser]::Tokenize($ScriptBlock, [ref]$null)        
        if (-not $tokens) { return } 
        for ($i = 0; $i -lt $tokens.Count; $i++) {
            if ($tokens[$i].Content -eq "function" -and 
                $tokens[$i].Type -eq "Keyword") {
                    $functionName = $tokens[$i + 1].Content
                break
            }
        }
        if ($functionName) {
            $NewfileName = Join-Path $root "$functionName.ps1"
            $scriptBlock | Set-Content $NewfileName 
        }
    }   
}
