# ------------------------------------------------------------------
# Title: Create an RTF document with Windows Powershell WITHOUT WORD
# Author: Sean Kearney
# Description: This script will create an RTF document on your workstation using Windows Powershell.   It is a very simple conceptual script that can be expanded for many purposes.In this sample script it will leverage four static variables as an example to populate a welcome letter for a new u
# Date Published: 19-Feb-2012 8:36:58 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Create-an-RTF-document-333dfe26
# Tags: RTF Document Powershell MailMerge
# ------------------------------------------------------------------

param (
[string]$Filename
)
# Save script as NEWRTF.PS1
#
# Execute with ./NEWRTF.PS1 -filename somefilename.rtf
#		

# Note for this basic example, there is no error checking
# The full path name INCLUDING RTF extension must be supplied
# for the filename
#
# For Example C:\Folder\Filename.RTF
#

# Four static variables for an example

$Firstname="John"
$Lastname="Smith"

# For an RTF file, you must "escape" the Backslash with an extra Backslash

$Accountname="CONTOSO\\jsmith"
$Password="LousyPass123"

# Header of the RTF file

$Header+="{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1033{\fonttbl{\f0\fnil\fcharset0 Consolas;}}`r`n"
$Header+="{\*\generator Riched20 6.2.8102}\viewkind4\uc1 `r`n"
$Header+="\pard\sl276\slmult1\f0\fs22\lang9 \par`r`n"

# Content of the message

$Message+="Hello $Firstname $Lastname and Welcome to ABC\par`r`n"
$Message+="Corporation.\par`r`n"
$Message+="\par`r`n"
$Message+="Your User ID is $Accountname\par`r`n"
$Message+="Your Temporary Password is $Password\par`r`n"
$Message+="\par`r`n"
$Message+="Do not share this information and remember,\par`r`n"
$Message+="We are watching....\par`r`n"
$Message+="`r`n"

# Footer in the RTF File

$Footer="}`r`n"

# Build the content together

$Content=$Header+$Message+$Footer

# Create the file

ADD-CONTENT -path $Filename -value $Content -force
