function Get-FunctionFromScript {
    <#
    .Synopsis 
        Gets the functions declared within a script block or a file
    .Description
        Gets the functions exactly as they are written within a script or file
    .Example
        Get-FunctionFromScript {
            function foo() {
                "foo"
            }
            function bar() {
                "bar"
            }
        }
    .Link
        http://powershellpipeworks.com/AboutCommandServices.aspx#CommandServiceSecurity
    #>
    [CmdletBinding(DefaultParameterSetName='File')]
    [OutputType([ScriptBlock], [PSObject])]
    param(
    # The script block containing functions
    [Parameter(Mandatory=$true,
        ParameterSetName="ScriptBlock",
        ValueFromPipelineByPropertyName=$true)]    
    [ScriptBlock]
    $ScriptBlock,
    
    # A file containing functions
    [Parameter(Mandatory=$true,
        ParameterSetName="File",
        ValueFromPipelineByPropertyName=$true)]           
    [Alias('FullName')]
    [String]
    $File,
    
    # If set, outputs the command metadatas
    [switch]
    $OutputMetaData
    )
    
    process {
        if ($psCmdlet.ParameterSetName -eq "File") {
            $realFile = Get-Item $File
            if (-not $realFile) {
                $realFile = Get-Item -LiteralPath $File -ErrorAction SilentlyContinue
                if (-not $realFile) { 
                    return
                }
            }
            $text = [IO.File]::ReadAllText($realFile.Fullname)
            $scriptBlock = [ScriptBlock]::Create($text)
            if ($scriptBlock) {
                $functionsInScript = 
                    Get-FunctionFromScript -ScriptBlock $scriptBlock -OutputMetaData:$OutputMetaData                    
                if ($OutputMetaData) 
                {
                    $functionsInScript | 
                        Add-Member NoteProperty File $realFile.FullName -PassThru
                }
            } 
        } elseif ($psCmdlet.ParameterSetName -eq "ScriptBlock") {            
            $text = $scriptBlock.ToString()
            $tokens = [Management.Automation.PSParser]::Tokenize($scriptBlock, [ref]$null)            
            for ($i = 0; $i -lt $tokens.Count; $i++) {
                if ($tokens[$i].Content -eq "function" -and
                    $tokens[$i].Type -eq "Keyword") {
                    $groupDepth = 0
                    $functionName = $tokens[$i + 1].Content
                    $ii = $i
                    $done = $false
                    while (-not $done) {
                        while ($tokens[$ii] -and $tokens[$ii].Type -ne 'GroupStart') { $ii++ }
                        $groupDepth++
                        while ($groupDepth -and $tokens[$ii]) {
                            $ii++
                            if ($tokens[$ii].Type -eq 'GroupStart') { $groupDepth++ } 
                            if ($tokens[$ii].Type -eq 'GroupEnd') { $groupDepth-- }
                        }
                        if (-not $tokens[$ii]) { break } 
                        if ($tokens[$ii].Content -eq "}") { 
                            $done = $true
                        }
                    }
                    if (-not $tokens[$ii] -or 
                        ($tokens[$ii].Start + $tokens[$ii].Length) -ge $Text.Length) {
                        $chunk = $text.Substring($tokens[$i].Start)
                    } else {
                        $chunk = $text.Substring($tokens[$i].Start, 
                            $tokens[$ii].Start + $tokens[$ii].Length - $tokens[$i].Start)
                    }        
                    if ($OutputMetaData) {
                        New-Object PSObject -Property @{
                            Name = $functionName
                            Definition = [ScriptBlock]::Create($chunk)
                        }                        
                    } else {
                        [ScriptBlock]::Create($chunk)
                    }
                }
            }        
        }        
    }
}
