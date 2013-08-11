#requires -version 2.0

<#
 -----------------------------------------------------------------------------
 Script: Print-ISEFile.ps1
 Version: 1.0
 Author: Jeffery Hicks
    http://jdhitsolutions.com/blog
    http://twitter.com/JeffHicks
    http://www.ScriptingGeek.com
 Date: 9/8/2011
 Keywords: ISE, Print
 Comments: This function is intended to be used in the ISE to print the current script file
 to the default printer.

 "Those who forget to script are doomed to repeat their work."

  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
 -----------------------------------------------------------------------------
 #>
 
Function Send-ToPrinter {

Param([string]$path=$PSISE.CurrentFile.FullPath)

Start-Process -filepath Notepad.exe -ArgumentList "/p",$path -WindowStyle Hidden

<#
this is an alternative way using the default printer
  get-content -Path $path | out-printer
#>

} #end function

