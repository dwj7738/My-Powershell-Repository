#############################################################################
##
## Invoke-Inline
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
#############################################################################

<#

.SYNOPSIS

Demonstrates the Add-Type cmdlet to invoke in-line C#

#>

Set-StrictMode -Version Latest

$inlineType = Add-Type -Name InvokeInline_Inline -PassThru `
    -MemberDefinition @'
    public static int RightShift(int original, int places)
    {
        return original >> places;
    }
'@

$inlineType::RightShift(1024, 3)
