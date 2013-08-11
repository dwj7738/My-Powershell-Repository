##############################################################################
##
## Invoke-ElevatedCommand
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Runs the provided script block under an elevated instance of PowerShell as
through it were a member of a regular pipeline.

.EXAMPLE

PS >Get-Process | Invoke-ElevatedCommand.ps1 {
    $input | Where-Object { $_.Handles -gt 500 } } | Sort Handles

#>

param(
    ## The script block to invoke elevated
    [Parameter(Mandatory = $true)]
    [ScriptBlock] $Scriptblock,

    ## Any input to give the elevated process
    [Parameter(ValueFromPipeline = $true)]
    $InputObject,

    ## Switch to enable the user profile
    [switch] $EnableProfile
)

begin
{
    Set-StrictMode -Version Latest
    $inputItems = New-Object System.Collections.ArrayList
}

process
{
    $null = $inputItems.Add($inputObject)
}

end
{
    ## Create some temporary files for streaming input and output
    $outputFile = [IO.Path]::GetTempFileName()
    $inputFile = [IO.Path]::GetTempFileName()

    ## Stream the input into the input file
    $inputItems.ToArray() | Export-CliXml -Depth 1 $inputFile

    ## Start creating the command line for the elevated PowerShell session
    $commandLine = ""
    if(-not $EnableProfile) { $commandLine += "-NoProfile " }

    ## Convert the command into an encoded command for PowerShell
    $commandString = "Set-Location '$($pwd.Path)'; " +
        "`$output = Import-CliXml '$inputFile' | " +
        "& {" + $scriptblock.ToString() + "} 2>&1; " +
        "Export-CliXml -Depth 1 -In `$output '$outputFile'"

    $commandBytes = [System.Text.Encoding]::Unicode.GetBytes($commandString)
    $encodedCommand = [Convert]::ToBase64String($commandBytes)
    $commandLine += "-EncodedCommand $encodedCommand"

    ## Start the new PowerShell process
    $process = Start-Process -FilePath (Get-Command powershell).Definition `
        -ArgumentList $commandLine -Verb RunAs `
        -WindowStyle Hidden `
        -Passthru
    $process.WaitForExit()

    ## Return the output to the user
    if((Get-Item $outputFile).Length -gt 0)
    {
        Import-CliXml $outputFile
    }

    ## Clean up
    Remove-Item $outputFile
    Remove-Item $inputFile
}
