###########################################################################
##
## Invoke-ScriptThatRequiresSta
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
###########################################################################

<#

.SYNOPSIS

Demonstrates a technique to relaunch a script that requires STA mode.
This is useful only for simple parameter definitions that can be
specified positionally.

#>

param(
    $Parameter1,
    $Parameter2
)

Set-StrictMode -Version Latest

"Current threading mode: " + $host.Runspace.ApartmentState
"Parameter1 is: $parameter1"
"Parameter2 is: $parameter2"

if($host.Runspace.ApartmentState -ne "STA")
{
    "Relaunching"
    $file = $myInvocation.MyCommand.Path
    powershell -NoProfile -Sta -File $file $parameter1 $parameter2
    return
}

"After relaunch - current threading mode: " + $host.Runspace.ApartmentState
