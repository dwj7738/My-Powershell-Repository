function Out-Default {
    [CmdletBinding()]    
    param(
        
    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    $InputObject
    )
    
    begin {
        $global:lastOutputCollection = New-Object Collections.ArrayList
        try {
             $outBuffer = $null
             if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
             {
                 $PSBoundParameters['OutBuffer'] = 1
             }
             $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Out-Default', [System.Management.Automation.CommandTypes]::Cmdlet)
             $scriptCmd = {& $wrappedCmd @PSBoundParameters }
             $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
             $steppablePipeline.Begin($true)
         } catch {
             throw
         }

    }
    
    process {
        try {
             $steppablePipeline.Process($_)
             $null = $global:lastOutputCollection.Add($_)
             $global:lastOutputItem = $_
        } catch {
             throw
        }
                     

    }
    
    end {
        if ($global:lastOutputCollection.Count) {
        $global:LastOutput = $global:lastOutputCollection        
        }
        
        try {
             $steppablePipeline.End()
        } catch {
             throw
        }

    }
}

