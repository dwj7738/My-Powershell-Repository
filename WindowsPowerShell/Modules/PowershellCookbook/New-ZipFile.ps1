##############################################################################
##
## New-ZipFile
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Create a Zip file from any files piped in. Requires that
you have the SharpZipLib installed, which is available from
http://www.icsharpcode.net/OpenSource/SharpZipLib/

.EXAMPLE

dir *.ps1 | New-ZipFile scripts.zip d:\bin\ICSharpCode.SharpZipLib.dll
Copies all PS1 files in the current directory to scripts.zip

.EXAMPLE

"readme.txt" | New-ZipFile docs.zip d:\bin\ICSharpCode.SharpZipLib.dll
Copies readme.txt to docs.zip

#>

param(
    ## The name of the zip archive to create
    $ZipName = $(throw "Specify a zip file name"),

    ## The path to ICSharpCode.SharpZipLib.dll
    $LibPath = $(throw "Specify the path to SharpZipLib.dll")
)

Set-StrictMode -Version Latest

## Load the Zip library
[void] [Reflection.Assembly]::LoadFile($libPath)
$namespace = "ICSharpCode.SharpZipLib.Zip.{0}"

## Create the Zip File
$zipName = $executionContext.SessionState.`
    Path.GetUnresolvedProviderPathFromPSPath($zipName)
$zipFile =
    New-Object ($namespace -f "ZipOutputStream") ([IO.File]::Create($zipName))
$zipFullName = (Resolve-Path $zipName).Path

[byte[]] $buffer = New-Object byte[] 4096

## Go through each file in the input, adding it to the Zip file
## specified
foreach($file in $input)
{
    ## Skip the current file if it is the zip file itself
    if($file.FullName -eq $zipFullName)
    {
        continue
    }

    ## Convert the path to a relative path, if it is under the
    ## current location
    $replacePath = [Regex]::Escape( (Get-Location).Path + "\" )
    $zipName = ([string] $file) -replace $replacePath,""

    ## Create the zip entry, and add it to the file
    $zipEntry = New-Object ($namespace -f "ZipEntry") $zipName
    $zipFile.PutNextEntry($zipEntry)

    $fileStream = [IO.File]::OpenRead($file.FullName)
    [ICSharpCode.SharpZipLib.Core.StreamUtils]::Copy(
        $fileStream, $zipFile, $buffer)
    $fileStream.Close()
}

## Close the file
$zipFile.Close()
