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