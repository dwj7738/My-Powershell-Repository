##############################################################################
##
## Format-String
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Replaces text in a string based on named replacement tags

.EXAMPLE

Format-String "Hello {NAME}" @{ NAME = 'PowerShell' }
Hello PowerShell

.EXAMPLE

Format-String "Your score is {SCORE:P}" @{ SCORE = 0.85 }
Your score is 85.00 %

#>

param(
    ## The string to format. Any portions in the form of {NAME}
    ## will be automatically replaced by the corresponding value
    ## from  the supplied hashtable.
    $String,

    ## The named replacements to use in the string
    [hashtable] $Replacements
)

Set-StrictMode -Version Latest

$currentIndex = 0
$replacementList = @()

## Go through each key in the hashtable
foreach($key in $replacements.Keys)
{
    ## Convert the key into a number, so that it can be used by
    ## String.Format
    $inputPattern = '{(.*)' + $key + '(.*)}'
    $replacementPattern = '{${1}' + $currentIndex + '${2}}'
    $string = $string -replace $inputPattern,$replacementPattern
    $replacementList += $replacements[$key]

    $currentIndex++
}

## Now use String.Format to replace the numbers in the
## format string.
$string -f $replacementList
