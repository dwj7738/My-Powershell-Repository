#requires -version 2.0

# -----------------------------------------------------------------------------
# Script: New-CommentHelp.ps1
# Version: 1.0
# Author: Jeffery Hicks
#    http://jdhitsolutions.com/blog
#    http://twitter.com/JeffHicks
# Date: 3/28/2011
# Keywords: ISE, Help, Read-Host
# Comments:
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

Function New-CommentHelp {

Param()

#define beginning of comment based string

$comment=@"
<#
.SYNOPSIS
{0}
.DESCRIPTION
{1}

"@

#prompt for command name (default to script name)
$name=Read-Host "What is the name of your function or command?"

#prompt for synopsis
$Synopsis=Read-Host "Enter a synopsis"
#prompt for description
$description=Read-Host "Enter a description. You can expand and edit later"

#Create comment based help string
$help=$comment -f $synopsis,$description

#test if command is loaded and if so get parameters
#ignore common: 
$common="VERBOSE|DEBUG|ERRORACTION|WARNINGACTION|ERRORVARIABLE|WARNINGVARIABLE|OUTVARIABLE|OUTBUFFER"
Try 
{
    $command=get-command -Name $name -ErrorAction Stop
    $params=$command.parameters.keys | where {$_ -notmatch $common} 
}
Catch
{
    #otherwise prompt
    $scriptname=Read-Host "If your command is a script file, enter the full file name with extension. Otherwise leave blank"
    if ($scriptname)
    {
        Try 
        {
            $command=get-command -Name $scriptname -ErrorAction Stop
            $params=$command.parameters.keys | where {$_ -notmatch $common} 
        }
        Catch
        {
            Write-Warning "Failed to find $scriptname"
            Return 
        }

    } #if $scriptname
    else
    {
        #prompt for a comma separated list of parameter names
        $EnterParams=Read-Host "Enter a comma separated list of parameter names"
        $Params=$EnterParams.Split(",")
    }
}

#get parameters from help or prompt for comma separated list
 Foreach ($param in $params) {
    #prompt for a description for each parameter
    $paramDesc=Read-host "Enter a short description for parameter $($Param.ToUpper())"
    #define a new line
#this must be left justified to avoid a parsing error
$paramHelp=@"
.PARAMETER $Param
$paramDesc

"@
       
        
    #append the parameter to the help comment
    $help+=$paramHelp
    } #foreach
    
Do
{
    #prompt for an example command
    $example=Read-Host "Enter an example command. You do not need to include a prompt. Leave blank to continue"
    if ($example)
    {
    
    #prompt for an example description
    $exampleDesc=Read-Host "Enter a brief description of this example"
    
#this must be left justified to avoid a parsing error    
$exHelp=@"
.EXAMPLE
PS C:\> $example
$exampleDesc

"@    
    
    #add the example to the help comment
    $help+=$exHelp
    } #if $example
    
} While ($example)


#Prompt for version #
$version=Read-Host "Enter a version number"

#Prompt for date
$resp=Read-Host "Enter a last updated date or press Enter for the current date."
if ($resp)
{
    $verDate=$resp
}
else
{
    #use current date
    $verDate=(Get-Date).ToShortDateString()
}

#construct a Notes section
$NoteHere=@"
.NOTES
NAME        :  {0}
VERSION     :  {1}   
LAST UPDATED:  {2}
AUTHOR      :  {3}\{4}

"@

#insert the values
$Notes=$NoteHere -f $Name,$version,$verDate,$env:userdomain,$env:username

#add the section to help
$help+=$Notes

#prompt for URL Link
$url=Read-Host "Enter a URL link. This is optional"
if ($url)
{
$urlLink=@"
.LINK
$url

"@

#add the section to help
$help+=$urlLink
}

#prompt for comma separated list of links
$links=Read-Host "Enter a comma separated list of Link references or leave blank for none"
if ($links)
{
#define a here string
$linkHelp=@"
.LINK

"@

#add each link
Foreach ($link in $links.Split(",")) {
    #insert the link and a new line return
    $linkHelp+="$link `n"
}
#add the section to help
$help+=$linkHelp

}

#Inputs
$inputHelp=@"
.INPUTS
{0}

"@

$Inputs=Read-Host "Enter a description for any inputs. Leave blank for NONE."
if ($inputs)
{
    #insert the input value and append to the help comment
    $help+=($inputHelp -f $inputs)    
}
else
{
   #use None as the value and insert into the help comment
   $help+=($inputHelp -f "None")    
}

#outputs
$outputHelp=@"
.OUTPUTS
{0}

"@
$Outputs=Read-Host "Enter a description for any outputs. Leave blank for NONE."
if ($Outputs)
{
    #insert the output value and append to the help comment
    $help+=($outputHelp -f $Outputs)    
}
else
{
   #use None as the value and insert into the help comment
   $help+=($outputHelp -f "None")    
}

#close the help comment
$help+="#>"

#if ISE insert into current file
if ($psise)
{
    $psise.CurrentFile.Editor.InsertText($help) | Out-Null
}
else
{
    #else write to the pipeline
    $help
}

} #end function