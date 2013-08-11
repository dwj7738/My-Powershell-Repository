##############################################################################
##
## Invoke-BinaryProcess
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Invokes a process that emits or consumes binary data.

.EXAMPLE

Invoke-BinaryProcess binaryProcess.exe -RedirectOutput |
       Invoke-BinaryProcess binaryProcess.exe -RedirectInput

#>

param(
    ## The name of the process to invoke
    [string] $ProcessName,

    ## Specifies that input to the process should be treated as
    ## binary
    [Alias("Input")]
    [switch] $RedirectInput,

    ## Specifies that the output of the process should be treated
    ## as binary
    [Alias("Output")]
    [switch] $RedirectOutput,

    ## Specifies the arguments for the process
    [string] $ArgumentList
)

Set-StrictMode -Version Latest

## Prepare to invoke the process
$processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
$processStartInfo.FileName = (Get-Command $processname).Definition
$processStartInfo.WorkingDirectory = (Get-Location).Path
if($argumentList) { $processStartInfo.Arguments = $argumentList }
$processStartInfo.UseShellExecute = $false

## Always redirect the input and output of the process.
## Sometimes we will capture it as binary, other times we will
## just treat it as strings.
$processStartInfo.RedirectStandardOutput = $true
$processStartInfo.RedirectStandardInput = $true

$process = [System.Diagnostics.Process]::Start($processStartInfo)

## If we've been asked to redirect the input, treat it as bytes.
## Otherwise, write any input to the process as strings.
if($redirectInput)
{
    $inputBytes = @($input)
    $process.StandardInput.BaseStream.Write($inputBytes, 0, $inputBytes.Count)
    $process.StandardInput.Close()
}
else
{
    $input | % { $process.StandardInput.WriteLine($_) }
    $process.StandardInput.Close()
}

## If we've been asked to redirect the output, treat it as bytes.
## Otherwise, read any input from the process as strings.
if($redirectOutput)
{
    $byteRead = -1
    do
    {
        $byteRead = $process.StandardOutput.BaseStream.ReadByte()
        if($byteRead -ge 0) { $byteRead }
    } while($byteRead -ge 0)
}
else
{
    $process.StandardOutput.ReadToEnd()
}