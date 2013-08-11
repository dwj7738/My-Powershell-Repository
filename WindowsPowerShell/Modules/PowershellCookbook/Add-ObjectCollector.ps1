##############################################################################
##
## Add-ObjectCollector
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Adds a new Out-Default command wrapper to store up to 500 elements from
the previous command. This wrapper stores output in the $ll variable.

.EXAMPLE

PS >Get-Command $pshome\powershell.exe

CommandType     Name                          Definition
-----------     ----                          ----------
Application     powershell.exe                C:\Windows\System32\Windo...

PS >$ll.Definition
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe

.NOTES

This command builds on New-CommandWrapper, also included in the Windows
PowerShell Cookbook.

#>

Set-StrictMode -Version Latest

New-CommandWrapper Out-Default `
    -Begin {
        $cachedOutput = New-Object System.Collections.ArrayList
    } `
    -Process {
        ## If we get an input object, add it to our list of objects
        if($_ -ne $null) { $null = $cachedOutput.Add($_) }
        while($cachedOutput.Count -gt 500) { $cachedOutput.RemoveAt(0) }
    } `
    -End {
        ## Be sure we got objects that were not just errors (
        ## so that we don't wipe out the saved output when we get errors
        ## trying to work with it.)
        ## Also don't caputre formatting information, as those objects
        ## can't be worked with.
        $uniqueOutput = $cachedOutput | Foreach-Object {
            $_.GetType().FullName } | Select -Unique
        $containsInterestingTypes = ($uniqueOutput -notcontains `
            "System.Management.Automation.ErrorRecord") -and
            ($uniqueOutput -notlike `
                "Microsoft.PowerShell.Commands.Internal.Format.*")

        ## If we actually had output, and it was interesting information,
        ## save the output into the $ll variable
        if(($cachedOutput.Count -gt 0) -and $containsInterestingTypes)
        {
            $GLOBAL:ll = $cachedOutput | % { $_ }
        }
    }
