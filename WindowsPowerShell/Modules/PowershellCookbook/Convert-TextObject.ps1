##############################################################################
##
## Convert-TextObject
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Convert a simple string into a custom PowerShell object.

.EXAMPLE

"Hello World" | Convert-TextObject
Generates an Object with "P1=Hello" and "P2=World"

.EXAMPLE

"Hello World" | Convert-TextObject -Delimiter "ll"
Generates an Object with "P1=He" and "P2=o World"

.EXAMPLE

"Hello World" | Convert-TextObject -Pattern "He(ll.*o)r(ld)"
Generates an Object with "P1=llo Wo" and "P2=ld"

.EXAMPLE

"Hello World" | Convert-TextObject -PropertyName FirstWord,SecondWord
Generates an Object with "FirstWord=Hello" and "SecondWord=World

.EXAMPLE

"123 456" | Convert-TextObject -PropertyType $([string],[int])
Generates an Object with "Property1=123" and "Property2=456"
The second property is an integer, as opposed to a string

.EXAMPLE

PS >$ipAddress = (ipconfig | Convert-TextObject -Delim ": ")[2].P2
PS >$ipAddress
192.168.1.104

#>

[CmdletBinding(DefaultParameterSetName = "ByDelimiter")]
param(
    ## If specified, gives the .NET Regular Expression with which to
    ## split the string. The script generates properties for the
    ## resulting object out of the elements resulting from this split.
    ## If not specified, defaults to splitting on the maximum amount
    ## of whitespace: "\s+", as long as Pattern is not
    ## specified either.
    [Parameter(ParameterSetName = "ByDelimiter", Position = 0)]
    [string] $Delimiter = "\s+",

    ## If specified, gives the .NET Regular Expression with which to
    ## parse the string. The script generates properties for the
    ## resulting object out of the groups captured by this regular
    ## expression.
    [Parameter(Mandatory = $true,
        ParameterSetName = "ByPattern",
        Position = 0)]
    [string] $Pattern,

    ## If specified, the script will pair the names from this object
    ## definition with the elements from the parsed string.  If not
    ## specified (or the generated object contains more properties
    ## than you specify,) the script uses property names in the
    ## pattern of P1,P2,...,PN
    [Parameter(Position = 1)]
    [Alias("PN")]
    [string[]] $PropertyName = @(),

    ## If specified, the script will pair the types from this list with
    ## the properties from the parsed string.  If not specified (or the
    ## generated object contains more properties than you specify,) the
    ## script sets the properties to be of type [string]
    [Parameter(Position = 2)]
    [Alias("PT")]
    [type[]] $PropertyType = @(),

    ## The input object to process
    [Parameter(ValueFromPipeline = $true)]
    [string] $InputObject
)

begin {
    Set-StrictMode -Version Latest
}

process {
    $returnObject = New-Object PSObject

    $matches = $null
    $matchCount = 0

    if($PSBoundParameters["Pattern"])
    {
        ## Verify that the input contains the pattern
        ## Populates the matches variable by default
        if(-not ($InputObject -match $pattern))
        {
            return
        }

        $matchCount = $matches.Count
    $startIndex = 1
    }
    else
    {
        ## Verify that the input contains the delimiter
        if(-not ($InputObject -match $delimiter))
        {
            return
        }

        ## If so, split the input on that delimiter
        $matches = $InputObject -split $delimiter
        $matchCount = $matches.Length
        $startIndex = 0
    }

    ## Go through all of the matches, and add them as notes to the output
    ## object.
    for($counter = $startIndex; $counter -lt $matchCount; $counter++)
    {
        $currentPropertyName = "P$($counter - $startIndex + 1)"
        $currentPropertyType = [string]

        ## Get the property name
        if($counter -lt $propertyName.Length)
        {
            if($propertyName[$counter])
            {
                $currentPropertyName = $propertyName[$counter - 1]
            }
        }

        ## Get the property value
        if($counter -lt $propertyType.Length)
        {
            if($propertyType[$counter])
            {
                $currentPropertyType = $propertyType[$counter - 1]
            }
        }

        Add-Member -InputObject $returnObject NoteProperty `
            -Name $currentPropertyName `
            -Value ($matches[$counter].Trim() -as $currentPropertyType)
    }

    $returnObject
}
