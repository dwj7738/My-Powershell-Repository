##############################################################################
##
## Move-LockedFile
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Registers a locked file to be moved at the next system restart.

.EXAMPLE

Move-LockedFile c:\temp\locked.txt c:\temp\locked.txt.bak

#>

param(
    ## The current location of the file to move
    $Path,

    ## The target location of the file
    $Destination
)

Set-StrictMode -Version Latest

## Convert the the path and destination to fully qualified paths
$path = (Resolve-Path $path).Path
$destination = $executionContext.SessionState.`
    Path.GetUnresolvedProviderPathFromPSPath($destination)

## Define a new .NET type that calls into the Windows API to
## move a locked file.
$MOVEFILE_DELAY_UNTIL_REBOOT = 0x00000004
$memberDefinition = @'
[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Auto)]
public static extern bool MoveFileEx(
    string lpExistingFileName, string lpNewFileName, int dwFlags);
'@
$type = Add-Type -Name MoveFileUtils `
    -MemberDefinition $memberDefinition -PassThru

## Move the file
$type::MoveFileEx($path, $destination, $MOVEFILE_DELAY_UNTIL_REBOOT)
