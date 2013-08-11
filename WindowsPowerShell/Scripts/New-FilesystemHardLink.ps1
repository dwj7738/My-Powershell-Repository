##############################################################################
##
## New-FileSystemHardLink
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Create a new hard link, which allows you to create a new name by which you
can access an existing file. Windows only deletes the actual file once
you delete all hard links that point to it.

.EXAMPLE

PS >"Hello" > test.txt
PS >dir test* | select name

Name
----
test.txt

PS >.\New-FilesystemHardLink.ps1 test.txt test2.txt
PS >type test2.txt
Hello
PS >dir test* | select name

Name
----
test.txt
test2.txt

#>

param(
    ## The existing file that you want the new name to point to
    [string] $Path,

    ## The new filename you want to create
    [string] $Destination
)

Set-StrictMode -Version Latest

## Ensure that the provided names are absolute paths
$filename = $executionContext.SessionState.`
    Path.GetUnresolvedProviderPathFromPSPath($destination)
$existingFilename = Resolve-Path $path

## Prepare the parameter types and parameters for the CreateHardLink function
$parameterTypes = [string], [string], [IntPtr]
$parameters = [string] $filename, [string] $existingFilename, [IntPtr]::Zero

## Call the CreateHardLink method in the Kernel32 DLL
$currentDirectory = Split-Path $myInvocation.MyCommand.Path
$invokeWindowsApiCommand = Join-Path $currentDirectory Invoke-WindowsApi.ps1
$result = & $invokeWindowsApiCommand "kernel32" `
    ([bool]) "CreateHardLink" $parameterTypes $parameters

## Provide an error message if the call fails
if(-not $result)
{
    $message = "Could not create hard link of $filename to " +
        "existing file $existingFilename"
    Write-Error $message
}
