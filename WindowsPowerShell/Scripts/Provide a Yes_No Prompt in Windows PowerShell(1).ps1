# --------------------------------- Meta Information for Microsoft Script Explorer for Windows PowerShell V1.0 ---------------------------------
# Title: Provide a Yes/No Prompt in Windows PowerShell
# Author: The Scripting Community
# Description: Sample script that displays a yes-no message box using Windows PowerShell.<br />
# Date Published: 10-Aug-2009 12:57:23 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/1a386b01-b1b8-4ac2-926c-a4986ac94fed
# ------------------------------------------------------------------

# Script name: YesNoPrompt.ps1
# Created on: 2007-01-07
# Author: Kent Finkle
# Purpose: How Can I Give a User a Yes/No Prompt in Powershell?
 
$a = new-object -comobject wscript.shell
$intAnswer = $a.popup("Do you want to delete these files?", `
0,"Delete Files",4)
If ($intAnswer -eq 6) {
    $a.popup("You answered yes.")
} else {
    $a.popup("You answered no.")
}
 
#Button Types 
#
#Value  Description  
#0 Show OK button.
#1 Show OK and Cancel buttons.
#2 Show Abort, Retry, and Ignore buttons.
#3 Show Yes, No, and Cancel buttons.
#4 Show Yes and No buttons.
#5 Show Retry and Cancel buttons.
