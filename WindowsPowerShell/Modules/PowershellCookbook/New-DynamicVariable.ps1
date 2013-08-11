##############################################################################
##
## New-DynamicVariable
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Creates a variable that supports scripted actions for its getter and setter

.EXAMPLE

PS >.\New-DynamicVariable GLOBAL:WindowTitle `
     -Getter { $host.UI.RawUI.WindowTitle } `
     -Setter { $host.UI.RawUI.WindowTitle = $args[0] }

PS >$windowTitle
Administrator: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
PS >$windowTitle = "Test"
PS >$windowTitle
Test

#>

param(
    ## The name for the dynamic variable
    [Parameter(Mandatory = $true)]
    $Name,

    ## The scriptblock to invoke when getting the value of the variable
    [Parameter(Mandatory = $true)]
    [ScriptBlock] $Getter,

    ## The scriptblock to invoke when setting the value of the variable
    [ScriptBlock] $Setter
)

Set-StrictMode -Version Latest

Add-Type @"
using System;
using System.Collections.ObjectModel;
using System.Management.Automation;

namespace Lee.Holmes
{
    public class DynamicVariable : PSVariable
    {
        public DynamicVariable(
            string name,
            ScriptBlock scriptGetter,
            ScriptBlock scriptSetter)
                : base(name, null, ScopedItemOptions.AllScope)
        {
            getter = scriptGetter;
            setter = scriptSetter;
        }
        private ScriptBlock getter;
        private ScriptBlock setter;

        public override object Value
        {
            get
            {
                if(getter != null)
                {
                    Collection<PSObject> results = getter.Invoke();
                    if(results.Count == 1)
                    {
                        return results[0];
                    }
                    else
                    {
                        PSObject[] returnResults =
                            new PSObject[results.Count];
                        results.CopyTo(returnResults, 0);
                        return returnResults;
                    }
                }
                else { return null; }
            }
            set
            {
                if(setter != null) { setter.Invoke(value); }
            }
        }
    }
}
"@

## If we've already defined the variable, remove it.
if(Test-Path variable:\$name)
{
    Remove-Item variable:\$name -Force
}

## Set the new variable, along with its getter and setter.
$executioncontext.SessionState.PSVariable.Set(
    (New-Object Lee.Holmes.DynamicVariable $name,$getter,$setter))
