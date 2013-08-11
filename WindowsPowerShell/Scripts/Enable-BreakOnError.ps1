#############################################################################
##
## Enable-BreakOnError
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Creates a breakpoint that only fires when PowerShell encounters an error

.EXAMPLE

PS >Enable-BreakOnError

ID Script           Line Command         Variable        Action
-- ------           ---- -------         --------        ------
 0                       Out-Default                     ...

PS >1/0
Entering debug mode. Use h or ? for help.

Hit Command breakpoint on 'Out-Default'


PS >$error
Attempted to divide by zero.

#>

Set-StrictMode -Version Latest

## Store the current number of errors seen in the session so far
$GLOBAL:EnableBreakOnErrorLastErrorCount = $error.Count

Set-PSBreakpoint -Command Out-Default -Action {

    ## If we're generating output, and the error count has increased,
    ## break into the debugger.
    if($error.Count -ne $EnableBreakOnErrorLastErrorCount)
    {
        $GLOBAL:EnableBreakOnErrorLastErrorCount = $error.Count
        break
    }
}
