function Test-ScriptCopFixer
{
    [CmdletBinding(DefaultParameterSetName='TestCommandInfo')]
    param(
    [Parameter(ParameterSetName='TestCommandInfo',Mandatory=$true,ValueFromPipeline=$true)]
    [Management.Automation.CommandInfo]
    $CommandInfo
    )
    
    process {
        <# 
        
        Only 3 types of commands can possibly be ScriptCopFixers:
        
        - FunctionInfo
        - CmdletInfo
        - ExternalScriptInfo
        
        #>
        
        
        if ($CommandInfo -isnot [Management.Automation.FunctionInfo] -and
            $CommandInfo -isnot [Management.Automation.CmdletInfo] -and
            $CommandInfo -isnot [Management.Automation.ExternalScriptInfo]
        ) {
            Write-Error "$CommandInfo is not a function, cmdlet, or script" 
            return        
        }
                
        if (-not $commandInfo.Parameters.Rule -and
            $commandInfo.Parameters.Rule.ParameterType -ne [PSObject]) 
        {
            Write-Error "$CommandInfo is missing the -Rule parameter"
            return
        }
        
        if (-not $commandInfo.Parameters.ItemWithProblem -and
            $commandInfo.Parameters.ItemWithProblem.ParameterType -ne [PSObject]) 
        {
            Write-Error "$CommandInfo is missing the -ItemWithProblem parameter"
            return
        }
        
        if (-not $commandInfo.Parameters.Problem -and
            $commandInfo.Parameters.Problem.ParameterType -ne [Management.Automation.ErrorRecord]) 
        {
            Write-Error "$CommandInfo is missing the -Problem parameter"
            return
        }
        
        if (-not $commandInfo.Parameters.NotInteractive -and
            $commandInfo.Parameters.NotInteractive.ParameterType -ne [Switch]) 
        {
            Write-Error "$CommandInfo is missing the -NonInteractive switch"
            return
        }                        
    }
} 

