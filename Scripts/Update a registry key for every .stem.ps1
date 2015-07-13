On Error Resume Next 

' AUTHOR: Mick Grove 
' http://micksmix.wordpress.com 
' 
' Last Updated: 1 - 13 - 2012 
' 
' Tested and works on Windows XP and Windows 7 (x64) 
' Should work fine on Windows 2000 and newer OS' 
' 
' Script name: RegUpdateAllHKCU.vbs 
' Run with cscript to suppress dialogs: cscript.exe RegUpdateAllHKCU.vbs 

Dim objFSO 
Dim WshShell, RegRoot 
Set objFSO = CreateObject("Scripting.FileSystemObject") 
Set WshShell = CreateObject("WScript.shell") 

'============================================== 
' SCRIPT BEGINS HERE 
'============================================== 
' 
'This is where our HKCU is temporarily loaded, and where we need to write to it 
RegRoot = "HKLM\TEMPHIVE" ' You don't really need to change this, but you can if you want 

Call Load_Registry_For_Each_User() 'Loads each user's "HKCU" registry hive 

WScript.Echo vbCrLf & "Processing complete!" 
WScript.Quit(0) 
' | 
' | 
'==================================================================== 

Sub KeysToSet(sRegistryRootToUse) 
'============================================== 
' Change variables here, or add additional keys 
'============================================== 
' 
Dim strRegPathParent01 
Dim strRegPathParent02 

strRegPathParent01 = "Software\Microsoft\Windows\CurrentVersion\Internet Settings" 
strRegPathParent02 = "Software\Microsoft\Internet Explorer\Main" 

WshShell.RegWrite sRegistryRootToUse & "\" & strRegPathParent01 & "\DisablePasswordCaching", "00000001", "REG_DWORD" 
WshShell.RegWrite sRegistryRootToUse & "\" & strRegPathParent02 & "\FormSuggest PW Ask", "no", "REG_SZ" 
' 
' You can add additional registry keys here if you would like 
' 
End Sub 

Sub Load_Registry_For_Each_User() 
Const USERPROFILE = 40 
Const APPDATA = 26 
Const HKEY_LOCAL_MACHINE = &H80000002 

Dim intResultLoad, intResultUnload 
Dim objShell, objUserProfile, objUser 
Dim objDocsAndSettings ' also works on win vista and win7 
Dim strUserProfile, strAppDataFolder, strAppData 
Dim sCurrentUser, sUserSID 
Set objShell = CreateObject("Shell.Application") 

strUserProfile = objShell.Namespace(USERPROFILE).self.path ' Holds path to the user's profile (eg "c:\users\mick" or "c:\documents and settings\mick") 
Set objUserProfile = objFSO.GetFolder(strUserProfile) 
Set objDocsAndSettings = objFSO.GetFolder(objUserProfile.ParentFolder) 'Holds path to parent of profile folder (eg "c:\users" or "c:\documents and settings") 

sCurrentUser = WshShell.ExpandEnvironmentStrings("%USERNAME%") 'Holds name of current logged on user running this script 
WScript.Echo "Updating the logged-on user: " & sCurrentUser & vbcrlf 
'' 
Call KeysToSet("HKCU") 'Update registry settings for the user running the script 
'' 
strAppDataFolder = UCase(objShell.Namespace(APPDATA).self.path) 'this returns the path to the "application data' folder --- used to check if this is a real user profile 

'On Vista and Windows 7, we have to make sure we have the parent path to "%appdata%" 
If Right(strAppDataFolder,8) = "\ROAMING" Then 
strAppDataFolder = Left(strAppDataFolder, Len(strAppDataFolder) - 8) 
ElseIf Right(strAppDataFolder,6) = "\LOCAL" Then 
strAppDataFolder = Left(strAppDataFolder, Len(strAppDataFolder) - 6) 
ElseIf Right(strAppDataFolder,9) = "\LOCALLOW" Then 
strAppDataFolder = Left(strAppDataFolder, Len(strAppDataFolder) - 9) 
End If 

strAppData = objFSO.GetFolder(strAppDataFolder).Name 

For Each objUser In objDocsAndSettings.SubFolders ' Enumerate subfolders of documents and settings folder 
If objFSO.FolderExists(objUser.Path & "\" & strAppData) Then ' Check if application data folder exists in user subfolder 
' 
sUserSID = "" 'empty out this variable 
If ((UCase(objUser.Name) <> "ALL USERS") and _ 
	(		UCase(objUser.Name) <> UCase(sCurrentUser)) and _ 
	(		UCase(objUser.Name) <> "LOCALSERVICE") and _ 
	(		UCase(objUser.Name) <> "NETWORKSERVICE")) then 

WScript.Echo "Preparing to update the user: " & objUser.Name 

'Load user's HKCU into temp area under HKLM 
intResultLoad = WshShell.Run("reg.exe load " & RegRoot & " " & chr(34) & objDocsAndSettings & "\" & objUser.Name & "\NTUSER.DAT" & chr(34), 0, True) 
If intResultLoad <> 0 Then 
' This profile appears to already be loaded...lets update it under the HKEY_USERS hive 
Dim objRegistry, objSubKey 
Dim strKeyPath, strValueName, strValue 
Dim strSubPath, arrSubKeys 

Set objRegistry = GetObject("winmgmts:\\.\root\default:StdRegProv") 
strKeyPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" 
objRegistry.EnumKey HKEY_LOCAL_MACHINE, strKeyPath, arrSubkeys 
sUserSID = "" 

For Each objSubkey In arrSubkeys 
strValueName = "ProfileImagePath" 
strSubPath = strKeyPath & "\" & objSubkey 
objRegistry.GetExpandedStringValue HKEY_LOCAL_MACHINE,strSubPath,strValueName,strValue 
If Right(UCase(strValue),Len(objUser.Name)+1) = "\" & UCase(objUser.Name) Then 
'this is the one we want 
sUserSID = objSubkey 
End If 
Next 

If Len(sUserSID) > 1 Then 
WScript.Echo "  Updating another logged-on user: " & objUser.Name & vbcrlf 
Call KeysToSet("HKEY_USERS\" & sUserSID) 
Else 
WScript.Echo("  *** An error occurred while loading HKCU for this user: " & objUser.Name) 
End If 
Else 
WScript.Echo("  HKCU loaded for this user: " & objUser.Name) 
End If 

'' 
If sUserSID = "" then 'check to see if we just updated this user b/c they are already logged on 
Call KeysToSet(RegRoot) ' update registry settings for this selected user 
End If 
'' 

If sUserSID = "" then 'check to see if we just updated this user b/c they are already logged on 
intResultUnload = WshShell.Run("reg.exe unload " & RegRoot,0, True) 'Unload HKCU from HKLM 
If intResultUnload <> 0 Then 
WScript.Echo("  *** An error occurred while unloading HKCU for this user: " & objUser.Name & vbCrLf) 
Else 
WScript.Echo("  HKCU UN-loaded for this user: " & objUser.Name & vbCrLf) 
End If 
End If 
End If 
Else 
'WScript.Echo "No AppData found for user " & objUser.Name 
End If 
Next 
End Sub 
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnmGUMh+9TsZtriEaR3Ian+oP
# KPigggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGNGq8E80qL5z8dn
# u72SQ7smqjwTMA0GCSqGSIb3DQEBAQUABIIBABDD/Q1VcDOxfLfuzkA4Z7ByaMNc
# DoCWPTTMK/98vVxOfTG1Ba0zzoV8cwdaC2lwGaCQCsJ0zIbda1r+7LeCceeW8ArP
# WQdTu0eQNpNMG6ylSwysJZb/I4tbF5A7nOCOSQsxlWx2wEM4JvYtrZHr4RNTcTaK
# 5KDmQ3RS23OMRkwCuxgX+WL5y2RwFKn2rC3KydmnQA3rNAZGGt2HiCxHgbCTYLm+
# vD+4tBeMk+WVQC75vNbTGJb4boDW0As0Ozha0R0oMHHAqK9+n6YHOcaXZ7a1SG7I
# rnoMhn1JC2xxe1FjBqJydvbx6M0mIz80Ww8sjuTA022/1YGH6k6gGY56+qc=
# SIG # End signature block
