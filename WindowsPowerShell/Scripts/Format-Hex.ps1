##############################################################################
##
## Format-Hex
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Outputs a file or pipelined input as a hexadecimal display. To determine the
offset of a character in the input, add the number at the far-left of the row
with the the number at the top of the column for that character.

.EXAMPLE

"Hello World" | Format-Hex

            0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F

00000000   48 00 65 00 6C 00 6C 00 6F 00 20 00 57 00 6F 00  H.e.l.l.o. .W.o.
00000010   72 00 6C 00 64 00                                r.l.d.

.EXAMPLE

Format-Hex c:\temp\example.bmp

#>

[CmdletBinding(DefaultParameterSetName = "ByPath")]
param(
    ## The file to read the content from
    [Parameter(ParameterSetName = "ByPath", Position = 0)]
    [string] $Path,

    ## The input (bytes or strings) to format as hexadecimal
    [Parameter(
        ParameterSetName = "ByInput", Position = 0,
        ValueFromPipeline = $true)]
    [Object] $InputObject
)

begin
{
    Set-StrictMode -Version Latest

    ## Create the array to hold the content. If the user specified the
    ## -Path parameter, read the bytes from the path.
    [byte[]] $inputBytes = $null
    if($Path) { $inputBytes = [IO.File]::ReadAllBytes((Resolve-Path $Path)) }

    ## Store our header, and formatting information
    $counter = 0
    $header = "            0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F"
    $nextLine = "{0}   " -f  [Convert]::ToString(
        $counter, 16).ToUpper().PadLeft(8, '0')
    $asciiEnd = ""

    ## Output the header
    "`r`n$header`r`n"
}

process
{
    ## If they specified the -InputObject parameter, retrieve the bytes
    ## from that input
    if(Test-Path variable:\InputObject)
    {
        ## If it's an actual byte, add it to the inputBytes array.
        if($InputObject -is [Byte])
        {
            $inputBytes = $InputObject
        }
        else
        {
            ## Otherwise, convert it to a string and extract the bytes
            ## from that.
            $inputString = [string] $InputObject
            $inputBytes = [Text.Encoding]::Unicode.GetBytes($inputString)
        }
    }

    ## Now go through the input bytes
    foreach($byte in $inputBytes)
    {
        ## Display each byte, in 2-digit hexidecimal, and add that to the
        ## left-hand side.
        $nextLine += "{0:X2} " -f $byte

        ## If the character is printable, add its ascii representation to
        ## the right-hand side.  Otherwise, add a dot to the right hand side.
        if(($byte -ge 0x20) -and ($byte -le 0xFE))
        {
            $asciiEnd += [char] $byte
        }
        else
        {
            $asciiEnd += "."
        }

        $counter++;

        ## If we've hit the end of a line, combine the right half with the
        ## left half, and start a new line.
        if(($counter % 16) -eq 0)
        {

            "$nextLine $asciiEnd"
            $nextLine = "{0}   " -f [Convert]::ToString(
                $counter, 16).ToUpper().PadLeft(8, '0')
            $asciiEnd = "";
        }
    }
}

end
{
    ## At the end of the file, we might not have had the chance to output
    ## the end of the line yet.  Only do this if we didn't exit on the 16-byte
    ## boundary, though.
    if(($counter % 16) -ne 0)
    {
        while(($counter % 16) -ne 0)
        {
            $nextLine += "   "
            $asciiEnd += " "
            $counter++;
        }
        "$nextLine $asciiEnd"
    }

    ""
}