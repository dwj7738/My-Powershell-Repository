##############################################################################
##
## Add-RelativePathCapture
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Adds a new Out-Default command wrapper that captures relative path
navigation without having to explicitly call 'Set-Location'

.EXAMPLE

PS C:\Users\Lee\Documents>..
PS C:\Users\Lee>...
PS C:\>

.NOTES

This commands builds on New-CommandWrapper, also included in the Windows
PowerShell Cookbook.

#>

Set-StrictMode -Version Latest

New-CommandWrapper Out-Default `
    -Process {
        if(($_ -is [System.Management.Automation.ErrorRecord]) -and
            ($_.FullyQualifiedErrorId -eq "CommandNotFoundException"))
        {
            ## Intercept all CommandNotFound exceptions, where the actual
            ## command consisted solely of dots.
            $command = $_.TargetObject
            if($command -match '^(\.)+$')
            {
                ## Count the number of dots, and go that many levels (minus
                ## one) up the directory hierarchy.
                $newLocation = "..\" * ($command.Length - 1)
                if($newLocation) { Set-Location $newLocation }

                ## Handle the error
                $error.RemoveAt(0)
                $_ = $null
            }
        }
    }
