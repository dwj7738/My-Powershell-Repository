function Get-ScriptCopFixer
{
    <#
    .Synopsis
        Gets all of the script cop fixers.
    .Description
        Gets all of the script cop fixers, and the relative path to the file defining the rule
    .Example
        Get-ScriptCopFixer
    .Link
        Repair-Command
    #>
    param()
    
    begin {
        # Declare the cache if fixers, if it doesn't exist yet.
        if (-not $script:ScriptCopFixers) {
            $script:ScriptCopFixers = New-Object Collections.ArrayList
        }
    }
    
    process {
        #region Convert Fixers from memory represention to psuedo object
        foreach ($fixer in @($script:ScriptCopFixers)) { 
            if ($fixer) {
                # Use Select-Object to turn it into the property bafe we want, and then add a typename 
                $fixer |
                    Select-Object Name, @{
                        Label='File'
                        Expression={
                            if ($_.Path){ $_.Path.Replace("$psScriptRoot\", "") } else { $_.ScriptBlock.File.Replace("$psScriptRoot\", "") } 
                            
                        }
                    } | 
                    ForEach-Object {
                        $_.psObject.typenames.clear()
                        $null = $_.psObject.typenames.Add('ScriptcopRule')
                        $_
                    } 
            }
        } 
        #endregion
    }
} 
 

