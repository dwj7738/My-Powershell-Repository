#requires -version 2.0

# -----------------------------------------------------------------------------
# Script: Convert-AliasDefinition.ps1
# Version: 1.0
# Author: Jeffery Hicks
#    http://jdhitsolutions.com/blog
#    http://twitter.com/JeffHicks
# Date: 4/7/2011
# Keywords: ISE, Alias, Command
# Comments:
# These functions are intended to be used with the PowerShell ISE
# and will not work in any other PowerShell host. 
#
# "Those who forget to script are doomed to repeat their work."
#
#  ****************************************************************
#  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
#  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
#  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
#  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
#  ****************************************************************
# -----------------------------------------------------------------------------


Function Convert-AliasDefinition {

[cmdletBinding(DefaultParameterSetName="ToDefinition")]

Param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a string to convert")]
[string]$Text,
[Parameter(ParameterSetName="ToAlias")]
[switch]$ToAlias,
[Parameter(ParameterSetName="ToDefinition")]
[switch]$ToDefinition
)

#make sure we are using the ISE
if ($host.name -match "ISE") 
{
    Try
    {
        #get alias if it exists otherwise throw an exception that 
        #will be caught
        if ($ToAlias)
        {
            #get alias by definition and convert to name
            $alias=get-alias -definition $Text -ErrorAction Stop
            #there might be multiples so use the first one found
            if ($alias -is [array])
            {
                $replace=$alias[0].name
            }
            else
            {
                $replace=$alias.name
            }
        }
        else
        {
            #get alias by name and convert to definition
            
            #if the text is ?, this is a special character so
            #we'll just assume it is Where-Object
            if ($Text -eq "?")
            {
                $Replace="Where-Object"
            }
            else
            {
                $alias=get-alias -name $Text -ErrorAction Stop
                $replace=$alias.definition
            }
        } #Else ToDefinition
        
    } #close Try

    Catch
    {
        Write-Host "Nothing for for $text" -ForegroundColor Cyan   
    }

    Finally 
    {

        #make changes if an alias was found
        If ($replace)
        {
            #Insert the replacment
            $psise.currentfile.editor.insertText($replace)
        }
    }
} #if ISE
else
{
    Write-Warning "You must be using the PowerShell ISE"
}

} #end function

