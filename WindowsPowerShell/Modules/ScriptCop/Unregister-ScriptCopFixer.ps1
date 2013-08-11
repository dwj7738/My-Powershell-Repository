function Unregister-ScriptCopFixer
{
    <#
    .Synopsis
        Unregisters a ScriptCop Fixer
    .Description
        Unregisters a ScriptCop fixer.  ScriptCop fixers (or Repair Rules) are commands to help automatically correct encountered issues.
    .Example
        Unregister-ScriptCopFixer -Name AFixer
    .Example
        # Unregisters all fixers
        Get-ScriptCopFixer | Unregister-ScriptCopFixer
    .Link
        Register-ScriptCopFixer
    .#>
    [CmdletBinding(DefaultParameterSetName='Name')]
    param(
    # Unregisters a fixer of a particular name
    [Parameter(ParameterSetName='Name',Mandatory=$true)]
    [string]$Name,
    
    # Unregisters a fixer command
    [Parameter(ParameterSetName='Command',ValueFromPipeline=$true,Mandatory=$true)]
    [Management.Automation.CommandInfo]$Command
    )
    
    begin {
        if (-not $script:ScriptCopFixers) {
            $script:ScriptCopFixers = New-Object Collections.ArrayList
        }
    }
    
    process {
        if ($psCmdlet.ParameterSetName -eq 'Name') {
            #region Remove Fixer by name
            if ($script:ScriptCopFixers) {
                $script:ScriptCopFixers |                     
                    Where-Object { 
                        $_.Name -eq $Name
                    } |                    
                    Unregister-ScriptCopFixer                     
            }
            #endregion            
        } elseif ($psCmdlet.ParameterSetName -eq 'Command') {
            #region Remove Fixer by commnad
            $null= $script:ScriptCopFixers.Remove($Command)                    
            Write-Debug ($scriptCopFixers | Out-String)
            #endregion
        }
        
        
    }
} 

