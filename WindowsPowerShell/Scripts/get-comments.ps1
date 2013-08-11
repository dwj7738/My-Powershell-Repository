#Requires -version 3.0

<#
  .Synopsis
    Gets all of the comments from a script
  .Description
    Uses the PowerShell 3 Parser to figure out what's a comment
#>
[CmdletBinding()]
param( # The script, or the path to a script file
  [String]$Script 
)

# Convert paths to script contents (otherwise, assume they passed the contents)
if(Test-Path $Script) { 
   $Script = Get-Content $Script -Raw  # Raw saves having to stitch the lines back together.
}
# You have to initialize these to something for the ParseInput call
$ParseError = $null
$Tokens = $null
$null = [System.Management.Automation.Language.Parser]::ParseInput($Script, [ref]$Tokens, [ref]$ParseError)
# All tokens have a "Kind" and "Text" but not all tokens are comments ;)
$Tokens | ? Kind -eq "Comment" | % Text