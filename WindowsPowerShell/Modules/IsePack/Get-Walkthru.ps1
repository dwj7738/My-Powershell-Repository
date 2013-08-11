# Some Demo Text
# Some More Demo Text
#.Audio MyAudioFile
#.Video MyVideoFile
#.Question "What Color is the Sky?"
#.Answer {$input -like "*Blue*" }
#.Hint { "Look Outside", "On a Nice Day", "Are you color blind?" }
function Get-Walkthru {
    <#
    .SynsopsiS
        Gets information from a file as a walkthru
        
    #>
    [CmdletBinding(DefaultParameterSetName="Command")]
    param(
    [Parameter(Mandatory=$true,
        ParameterSetName="Command",
        ValueFromPipeline=$true)]
    [Management.Automation.CommandInfo]
    $Command,    
    [Parameter(Mandatory=$true,
        ParameterSetName="File",
        ValueFromPipelineByPropertyName=$true)]    
    [Alias('Fullname')]
    [string]$File,
    
    [Parameter(Mandatory=$true,
        ParameterSetName="Text")]    
    [String]$Text
    )
    
    begin {
        $err = $null
        if (-not ('PSWalkthru.WalkthruData' -as [Type])) {
            Add-Type -UsingNamespace System.Management.Automation -Namespace PSWalkthru -Name WalkthruData -MemberDefinition '
public string SourceFile = String.Empty;','
public string Command = String.Empty;','
public string Explanation = String.Empty;','
public string AudioFile = String.Empty;','
public string VideoFile = String.Empty;','
public string Question = String.Empty;','
public string Answer = String.Empty;','
public string[] Hint;','
public ScriptBlock Script;'
        }
    }
    process {
        if ($psCmdlet.ParameterSetName -eq "File") {
            $realItem = Get-Item $file -ErrorAction SilentlyContinue
            if (-not $realItem) { return } 
            $text = [IO.File]::ReadAllText($realItem.FullName)                        
            $Result = Get-Walkthru -Text $text
            $result | 
                ForEach-Object {
                    $_.SourceFile = $realItem.Fullname
                    $_
                }
            return
        } elseif ($psCmdlet.ParameterSetName -eq "Command") {
            $help = $command | Get-Help 
            
            $c= 1
            $help.Examples.Example | 
                ForEach-Object {
                    $text = $_.code + ($_.remarks | Out-String)                
                    Get-Walkthru -Text $text |
                        ForEach-Object {
                            $_.Command = "$command Walkthru $c"
                            $_
                        }
                    $c++
                }
            return
        }
                                       
        $tokens = [Management.Automation.PSParser]::Tokenize($text, [ref]$err)                
        if ($err.Count) { return } 

        $lastToken = $null
        $isInContent = $false
        $lastResult = New-Object PSWalkthru.WalkthruData

        foreach ($token in $tokens) { 
            if ($token.Type -eq "Newline") { continue }
            if ($token.Type -ne "Comment" -or $token.StartColumn -gt 1) {
                $isInContent = $true
                if (-not $lastToken) { $lastToken = $token } 
            } else {
                if ($lastToken.Type -ne "Comment" -and $lastToken.StartColumn -eq 1) {
                    $chunk = $text.Substring($lastToken.Start, 
                        $token.Start - 1 - $lastToken.Start)
                    $lastResult.Script = [ScriptBlock]::Create($chunk)
                    # mutliparagraph, split up the results if multiparagraph                                                            
                    foreach ($p in $paragraphs) {
                        New-Object PSWalkthru.WalkthruData -Property @{Explanation = $p}
                    }
                    if ($lastIndex -ne -1) {
                        $lastResult.Explanation = $lastResult.Explanation.Substring($lastIndex + 1)
                    }
                    $lastResult                    

                    $null = $paragraphs
                    $lastToken = $null
                    $lastResult = New-Object PSWalkthru.WalkthruData
                    $isInContent = $false                
                }
            }
            if (-not $isInContent) {
                $lines = $token.Content.Trim("<>#")
                $lines = $lines.Split([Environment]::NewLine, 
                    [StringSplitOptions]"RemoveEmptyEntries")
                foreach ($l in $lines) {
                    switch ($l) {
                        {$_ -like ".Audio *" } {
                            $lastResult.AudioFile =
                                $l.Substring(".Audio ".Length)
                        }
                        {$_ -like ".Video *" } {
                            $lastResult.VideoFile =
                                $l.Substring(".Video ".Length)
                        }                        
                        {$_ -like ".Question *" } {
                            $lastResult.Question =
                                $l.Substring(".Question ".Length)
                        }                        
                        {$_ -like ".Answer *" } {
                            $lastResult.Answer =
                                $l.Substring(".Answer ".Length)
                        }
                        {$_ -like ".Hint *" } {
                            $lastResult.Hint =
                                $l.Substring(".Hint ".Length) -split ','
                        }                        
                        default {
                            $lastResult.Explanation += ($l + [Environment]::NewLine)                        
                        }
                    }
                }
            }            
        }
        
        if ($lastToken -and $lastResult) {
            $chunk = $text.Substring($lastToken.Start)
            $lastResult.Script = [ScriptBlock]::Create($chunk)
            $lastResult
        }
    }
}
