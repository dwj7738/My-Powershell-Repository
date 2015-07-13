###########################################################################” 
# 
# NAME: Set-OutlookSignature.ps1 
# 
# AUTHOR: Jan Egil Ring 
# Modifications by Darren Kattan 
# 
# COMMENT: Script to create an Outlook signature based on user information from Active Directory. 
# Adjust the variables in the “Custom variables”-section 
# Create an Outlook-signature from Microsoft Word (logo, fonts etc) and copy this signature to \\domain\NETLOGON\sig_files\$CompanyName\$CompanyName.docx 
#     This script supports the following keywords: 
#     DisplayName 
#     Title 
#     Email 
# 
#    See the following blog-posts for more information:  
#    http://blog.powershell.no/2010/01/09/outlook-signature-based-on-user-information-from-active-directory 
#    http://www.immense.net/deploying-unified-email-signature-template-outlook 
# 
# Tested on Office 2003, 2007 and 2010 
# 
# You have a royalty-free right to use, modify, reproduce, and 
# distribute this script file in any way you find useful, provided that 
# you agree that the creator, owner above has no warranty, obligations, 
# or liability for such use. 
# 
# VERSION HISTORY: 
# 1.0 09.01.2010 – Initial release 
# 1.1 11.09.2010 – Modified by Darren Kattan 
#    - Removed bookmarks. Now uses simple find and replace for DisplayName, Title, and Email. 
#    - Email address is generated as a link 
#    - Signature is generated from a single .docx file 
#    - Removed version numbers for script to run. Script runs at boot up when it sees a change in the “Date Modified” property of your signature template. 
# 
# 
###########################################################################” 
 
 ###########################################################################"
#
# NAME: Set-OutlookSignature.ps1
#
# AUTHOR: Jan Egil Ring
# Modifications by Darren Kattan
#
# COMMENT: Script to create an Outlook signature based on user information from Active Directory.
#          Adjust the variables in the "Custom variables"-section
#          Create an Outlook-signature from Microsoft Word (logo, fonts etc) and copy this signature to \\domain
#Custom variables 
$CompanyName = ‘Technical Support for Me’ 
$DomainName = ‘techsupport4me.ca’ 
 
$SigSource = “\\$DomainName\netlogon\sig_files\$CompanyName” 
$ForceSignatureNew = ’1'  #When the signature are forced the signature are enforced as default signature for new messages the next time the script runs. 0 = no force, 1 = force 
$ForceSignatureReplyForward = ’1' #When the signature are forced the signature are enforced as default signature for reply/forward messages the next time the script runs. 0 = no force, 1 = force 
 
#Environment variables 
$AppData=(Get-Item env:appdata).value 
$SigPath = ‘\Microsoft\Signatures’ 
$LocalSignaturePath = $AppData+$SigPath 
$RemoteSignaturePathFull = $SigSource+’\'+$CompanyName+’.docx’ 
\NETLOGON\sig_files\$CompanyName\$CompanyName.docx
#		   This script supports the following keywords:
#		   	DisplayName
#			Title
#			Email
#          See the following blog-post for more information: #          http://blog.crayon.no/blogs/janegil/archive/2010/01/09/outlook-signature-based-on-user-information-from-active-directory.aspx
#
#          Tested on Office 2003,2007 and 2010
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the creator, owner above has no warranty, obligations,
# or liability for such use.
#
# VERSION HISTORY:
# 1.0 09.01.2010 - Initial release
# 1.1 11.09.2010 - Modified by Darren Kattan
#	- Removed bookmarks. Now uses simple find and replace for DisplayName, Title, and Email.
#	- Email address is generated as a link
#	- Signature is generated from a single .docx file
#	- Removed version numbers for script to run. Script runs at boot up when it sees a change in the "Date #      Modified" property of your signature template.
# 1.11 11.15.2010 - Revised by Darren Kattan
#   - Fixed glitch with text signatures
#
#
###########################################################################"
#Custom variables
#$CompanyName = 'NAME HERE'
$CompanyName = ‘Technical Support for Me’ 
$DomainName = ‘techsupport4me.ca’ 
# $DomainName = 'DOMAIN HERE'
$SigSource = "\\$DomainName\netlogon\sig_files\$CompanyName"
$ForceSignatureNew = '1' #When the signature are forced the signature are enforced as default signature for new 
messages the next time the script runs. 0 = no force, 1 = force
$ForceSignatureReplyForward = '1' #When the signature are forced the signature are enforced as default signature 
for reply/forward messages the next time the script runs. 0 = no force, 1 = force
#Environment variables
$AppData=(Get-Item env:appdata).value
$SigPath = '\Microsoft\Signatures'
$LocalSignaturePath = $AppData+$SigPath
$RemoteSignaturePathFull = $SigSource+'\'+$CompanyName+'.docx'
#Get Active Directory information for current user
$UserName = $env:username
$Filter = "(&(objectCategory=User)(samAccountName=$UserName))"
$Searcher = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.Filter = $Filter
$ADUserPath = $Searcher.FindOne()
$ADUser = $ADUserPath.GetDirectoryEntry()
$ADDisplayName = $ADUser.DisplayName
$ADEmailAddress = $ADUser.mail
$ADTitle = $ADUser.title
$ADTelePhoneNumber = $ADUser.TelephoneNumber
#Setting registry information for the current user
$CompanyRegPath = "HKCU:\Software\"+$CompanyName
if (Test-Path $CompanyRegPath)
{}
else
{New-Item -path "HKCU:\Software" -name $CompanyName}
if (Test-Path $CompanyRegPath'\Outlook Signature Settings')
{}
else
{New-Item -path $CompanyRegPath -name "Outlook Signature Settings"}
$SigVersion = (gci $RemoteSignaturePathFull).LastWriteTime  #When was the last time the signature was written
$ForcedSignatureNew = (Get-ItemProperty $CompanyRegPath'\Outlook Signature Settings').ForcedSignatureNew
$ForcedSignatureReplyForward = (Get-ItemProperty $CompanyRegPath'\Outlook Signature 
Settings').ForcedSignatureReplyForward
$SignatureVersion = (Get-ItemProperty $CompanyRegPath'\Outlook Signature Settings').SignatureVersion
Set-ItemProperty $CompanyRegPath'\Outlook Signature Settings' -name SignatureSourceFiles -Value $SigSource
$SignatureSourceFiles = (Get-ItemProperty $CompanyRegPath'\Outlook Signature Settings').SignatureSourceFiles
#Forcing signature for new messages if enabled
if ($ForcedSignatureNew -eq '1')
{
#Set company signature as default for New messages
$MSWord = New-Object -com word.application
$EmailOptions = $MSWord.EmailOptions
$EmailSignature = $EmailOptions.EmailSignature
$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries
$EmailSignature.NewMessageSignature=$CompanyName
$MSWord.Quit()
}
#Forcing signature for reply/forward messages if enabled
if ($ForcedSignatureReplyForward -eq '1')
{
#Set company signature as default for Reply/Forward messages
$MSWord = New-Object -com word.application
$EmailOptions = $MSWord.EmailOptions
$EmailSignature = $EmailOptions.EmailSignature
$EmailSignatureEntries = $EmailSignature.EmailSignatureEntries
$EmailSignature.ReplyMessageSignature=$CompanyName
$MSWord.Quit()
}
#Copying signature sourcefiles and creating signature if signature-version are different from local version
if ($SignatureVersion -eq $SigVersion){}
else
{
	#Copy signature templates from domain to local Signature-folder
	Copy-Item "$SignatureSourceFiles\*" $LocalSignaturePath -Recurse -Force
	$ReplaceAll = 2
	$FindContinue = 1
	$MatchCase = $False
	$MatchWholeWord = $True
	$MatchWildcards = $False
	$MatchSoundsLike = $False
	$MatchAllWordForms = $False
	$Forward = $True
	$Wrap = $FindContinue
	$Format = $False
	#Insert variables from Active Directory to rtf signature-file
	$MSWord = New-Object -com word.application
	$fullPath = $LocalSignaturePath+'\'+$CompanyName+'.docx'
	$MSWord.Documents.Open($fullPath)
	$FindText = "DisplayName"
	$ReplaceText = $ADDisplayName.ToString()
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, 
$MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	$FindText = "Title"
	$ReplaceText = $ADTitle.ToString()
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, 
$MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	$FindText = "Telephone"
	$ReplaceText = $ADTitle.ToString()
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, 
$MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	$FindText = "Fax"
	$ReplaceText = $ADTitle.ToString()
	$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, 
$MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	$MSWord.Selection.Find.Execute("Email")
	$MSWord.ActiveDocument.Hyperlinks.Add($MSWord.Selection.Range, "mailto:"+$ADEmailAddress.ToString(), 
$missing, $missing, $ADEmailAddress.ToString())
	$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatHTML");
	$path = $LocalSignaturePath+'\'+$CompanyName+".htm"
	$MSWord.ActiveDocument.saveas([ref]$path, [ref]$saveFormat)
	$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatRTF");
	$path = $LocalSignaturePath+'\'+$CompanyName+".rtf"
	$MSWord.ActiveDocument.SaveAs([ref] $path, [ref]$saveFormat)
	$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatText");
	$path = $LocalSignaturePath+'\'+$CompanyName+".txt"
	$MSWord.ActiveDocument.SaveAs([ref] $path, [ref]$SaveFormat)
	$MSWord.ActiveDocument.Close()
	$MSWord.Quit()
}
#Stamp registry-values for Outlook Signature Settings if they doesn`t match the initial script variables. Note 
that these will apply after the second script run when changes are made in the "Custom variables"-section.
if ($ForcedSignatureNew -eq $ForceSignatureNew){}
else
{Set-ItemProperty $CompanyRegPath'\Outlook Signature Settings' -name ForcedSignatureNew -Value $ForceSignatureNew}
if ($ForcedSignatureReplyForward -eq $ForceSignatureReplyForward){}
else
{Set-ItemProperty $CompanyRegPath'\Outlook Signature Settings' -name ForcedSignatureReplyForward -Value 
$ForceSignatureReplyForward}
if ($SignatureVersion -eq $SigVersion){}
else
{Set-ItemProperty $CompanyRegPath'\Outlook Signature Settings' -name SignatureVersion -Value $SigVersion}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUS4uO2Eq+x9OyLHiJzIXM/rC0
# ReugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFBoVQ9EzHD0JPSfZ
# IcNvSPkwOEIyMA0GCSqGSIb3DQEBAQUABIIBABfztjYizRA4NtRAK4ot7m6fn2wD
# BG+1d7s7WzPgamoIGFD7bF1E2Nm0lIHhQltI4NxejYW/n8kr1EnFrd+6whHIKAX/
# 2vbc6fEx5/CYcAywPwOhtiHGmMaY7mTRsFf/aqjhYurklNWTGhgOpxeu9K6Jvz8F
# n1uPo0k7S1hWySMOopxud+Ko41wOOesWKbXd467mDjbYJTIaLSwTX8k2SRZohAqI
# lV6f8d+53d16GRk1zUzeyvMgDDunPNT9fZo0LuSgEdiSMUapId2iUqB2NeL/Kk0h
# XqoZeZmGI7JeEsKAGmBDzRX+2ORbViS+F7veMKgmIW91Ub0ut1uD7b27Ug4=
# SIG # End signature block
