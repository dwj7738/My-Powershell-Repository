##############################################################################
##
## Search-Registry
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Search the registry for keys or properties that match a specific value.

.EXAMPLE

PS >Set-Location HKCU:\Software\Microsoft\
PS >Search-Registry Run

#>

param(
    ## The text to search for
    [Parameter(Mandatory = $true)]
    [string] $Pattern
)

Set-StrictMode -Off

## Helper function to create a new object that represents
## a registry match from this script
function New-RegistryMatch
{
    param( $matchType, $keyName, $propertyName, $line )

    $registryMatch = New-Object PsObject -Property @{
        MatchType = $matchType;
        KeyName = $keyName;
        PropertyName = $propertyName;
        Line = $line
    }

    $registryMatch
}

## Go through each item in the registry
foreach($item in Get-ChildItem -Recurse -ErrorAction SilentlyContinue)
{
    ## Check if the key name matches
    if($item.Name -match $pattern)
    {
        New-RegistryMatch "Key" $item.Name $null $item.Name
    }

    ## Check if a key property matches
    foreach($property in (Get-ItemProperty $item.PsPath).PsObject.Properties)
    {
        ## Skip the property if it was one PowerShell added
        if(($property.Name -eq "PSPath") -or
            ($property.Name -eq "PSChildName"))
        {
            continue
        }

        ## Search the text of the property
        $propertyText = "$($property.Name)=$($property.Value)"
        if($propertyText -match $pattern)
        {
            New-RegistryMatch "Property" $item.Name `
                property.Name $propertyText
        }
    }
}
