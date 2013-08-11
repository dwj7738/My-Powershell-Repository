#requires -version 2.0

<#
 -----------------------------------------------------------------------------
 Script: Sign-ISEScript.ps1
 Version: 1.0
 Author: Jeffery Hicks
    http://jdhitsolutions.com/blog
    http://twitter.com/JeffHicks
    http://www.ScriptingGeek.com
 Date: 8/4/2011
 Keywords:
 Comments: This must be run in the PowerShell ISE

 "Those who forget to script are doomed to repeat their work."

  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
 -----------------------------------------------------------------------------
 #>
 
Function Write-Signature {

Param()

Set-StrictMode -Version Latest

#get the certificate
$cert=get-childitem -Path cert:\currentuser\my -CodeSigningCert
if ($cert) {

#save the file if necessary
if (!$psise.currentfile.IsSaved) {
 $psise.CurrentFile.Save()
}

#if the file is encoded as BigEndian, resave as Unicode
if ($psise.currentfile.encoding.encodingname -match "Big-Endian") {
    $psise.CurrentFile.Save([Text.Encoding]::Unicode) | Out-Null
}

#save the filepath for the current file so it can be re-opened later
$filepath=$psise.CurrentFile.FullPath

#sign the file
Try {
  Set-AuthenticodeSignature -FilePath $filepath -Certificate $cert -errorAction Stop
  #close the file
  $psise.CurrentPowerShellTab.Files.remove($psise.currentfile) | Out-Null             
  
  #reopen the file
  $psise.CurrentPowerShellTab.Files.add($filepath)  | out-null             
}
Catch {
  Write-Warning ("Script signing failed. {0}" -f $_.Exception.message)
}

} #if code cert found 

else {
    Write-Warning "No code signing certificate found."
}
} #end function


