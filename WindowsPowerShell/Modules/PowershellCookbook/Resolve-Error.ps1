#############################################################################
##
## Resolve-Error
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Displays detailed information about an error and its context

#>

param(
    ## The error to resolve
    $ErrorRecord = ($error[0])
)

Set-StrictMode -Off

""
"If this is an error in a script you wrote, use the Set-PsBreakpoint cmdlet"
"to diagnose it."
""

'Error details ($error[0] | Format-List * -Force)'
"-"*80
$errorRecord | Format-List * -Force

'Information about the command that caused this error ' +
    '($error[0].InvocationInfo | Format-List *)'
"-"*80
$errorRecord.InvocationInfo | Format-List *

'Information about the error''s target ' +
    '($error[0].TargetObject | Format-List *)'
"-"*80
$errorRecord.TargetObject | Format-List *

'Exception details ($error[0].Exception | Format-List * -Force)'
"-"*80

$exception = $errorRecord.Exception

for ($i = 0; $exception; $i++, ($exception = $exception.InnerException))
{
    "$i" * 80
    $exception | Format-List * -Force
}