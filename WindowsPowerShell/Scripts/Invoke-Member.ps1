##############################################################################
##
## Invoke-Member
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Enables easy access to methods and properties of pipeline objects.

.EXAMPLE

PS >"Hello","World" | .\Invoke-Member Length
5
5

.EXAMPLE

PS >"Hello","World" | .\Invoke-Member -m ToUpper
HELLO
WORLD

.EXAMPLE

PS >"Hello","World" | .\Invoke-Member Replace l w
Hewwo
Worwd

#>

[CmdletBinding(DefaultParameterSetName= "Member")]
param(

    ## A switch parameter to identify the requested member as a method.
    ## Only required for methods that take no arguments.
    [Parameter(ParameterSetName = "Method")]
    [Alias("M","Me")]
    [switch] $Method,

    ## The name of the member to retrieve
    [Parameter(ParameterSetName = "Method", Position = 0)]
    [Parameter(ParameterSetName = "Member", Position = 0)]
    [string] $Member,

    ## Arguments for the method, if any
    [Parameter(
        ParameterSetName = "Method", Position = 1,
        Mandatory = $false, ValueFromRemainingArguments = $true)]
    [object[]] $ArgumentList = @(),

    ## The object from which to retrieve the member
    [Parameter(ValueFromPipeline = $true)]
    $InputObject
    )

begin
{
    Set-StrictMode -Version Latest
}

process
{
    ## If the user specified a method, invoke it
    ## with any required arguments.
    if($psCmdlet.ParameterSetName -eq "Method")
    {
        $inputObject.$member.Invoke(@($argumentList))
    }
    ## Otherwise, retrieve the property
    else
    {
        $inputObject.$member
    }
}
