function Register-ScriptCopFixer
{
    <#
    .Synopsis
        Registers a new scriptcop fixer 
    .Description
        Registers a new scriptcop fixer.  
        
        A fixer (or Repair Rule) will help automatically repair issues when encountered.
    .Example
        Register-ScriptCopFixer -File .\Repair-Issue.ps1
    .Link
        Get-ScriptCopFixer
    #>
    [CmdletBinding(DefaultParameterSetName='Command')]
    param(
    # The fixer command
    [Parameter(ParameterSetName='Command',
        Mandatory=$true,
        ValueFromPipeline=$true)]
    [Management.Automation.CommandInfo]
    $Fixer,
    
    # A file containing a fixer command
    [Parameter(ParameterSetName='File',
        Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
    [Alias('FullName')]
    [String]
    $File
    )
    
    begin {
        # Declare the fixer structure, if it doesn't exist yet.
        if (-not $script:ScriptCopFixers) {
            $script:ScriptCopFixers = New-Object Collections.ArrayList
        }
    }
    
    process {
        if ($psCmdlet.ParameterSetName -eq 'Command') {
            #region Register a command
            #see if already registered
            $fixerIndex = $scriptCopFixers.IndexOf($Fixer)
            if ($fixerIndex -ne -1) { return } 
            # register it
            $Fixer | 
                Test-ScriptCopFixer -ErrorVariable Issues | 
                Out-Null
                
            if ($Issues) { return }
            
            $null = $scriptCopFixers.Add($fixer)            
            Write-Debug ($scriptCopFixers | Out-String)
            #endregion
        } elseif ($psCmdlet.ParameterSetName -eq 'File') {
            #region Get a Command Reference to Register
            # Get a command from the file
            
            $command = Get-Item $File | 
                Select-Object -ExpandProperty Fullname | 
                Get-Command
            if (-not $command) { return }
            # Register recursively 
            $command | Register-ScriptCopFixer
            #endregion
        } 
    
    }
} 
 

