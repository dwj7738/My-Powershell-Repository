'==========================================================================
'
' VBScript Source File -- Created with SAPIEN Technologies PrimalScript 2009
'
' NAME:  Delete Temp Files
'
' AUTHOR: Mohammed Alyafae , 
' DATE  : 9/21/2011
'
' COMMENT: this script delete all user and system temporary files and folder 
' also delete Internet Temporary files 
'==========================================================================

Option Explicit
Dim objShell
Dim objSysEnv,objUserEnv
Dim strUserTemp
Dim strSysTemp
Dim userProfile,TempInternetFiles
Dim OSType

Set objShell=CreateObject("WScript.Shell")

Set objSysEnv=objShell.Environment("System")
Set objUserEnv=objShell.Environment("User")

strUserTemp= objShell.ExpandEnvironmentStrings(objUserEnv("TEMP"))
strSysTemp= objShell.ExpandEnvironmentStrings(objSysEnv("TEMP"))
userProfile = objShell.ExpandEnvironmentStrings("%userprofile%")

DeleteTemp strUserTemp 'delete user temp files

DeleteTemp strSysTemp  'delete system temp files

 'delete Internet Temp files
 'the Internet Temp files path is diffrent according to OS Type
OSType=FindOSType

If OSType="Windows 7" Or OSType="Windows Vista" Then
TempInternetFiles=userProfile & "\AppData\Local\Microsoft\Windows\Temporary Internet Files"
ElseIf  OSType="Windows 2003" Or OSType="Windows XP" Then
TempInternetFiles=userProfile & "\Local Settings\Temporary Internet Files"
End If

DeleteTemp TempInternetFiles
'this is also to delete Content.IE5 in Internet Temp files
TempInternetFiles=TempInternetFiles & "\Content.IE5"
DeleteTemp TempInternetFiles




WScript.Quit


Sub DeleteTemp (strTempPath)
On Error Resume Next

Dim objFSO
Dim objFolder,objDir
Dim objFile
Dim i

Set objFSO=CreateObject("Scripting.FileSystemObject")
Set objFolder=objFSO.GetFolder(strTempPath)

'delete all files
For Each objFile In objFolder.Files
objFile.delete True
Next

'delete all subfolders
For i=0 To 10
	For Each objDir In objFolder.SubFolders
	objDir.Delete True
	Next
Next


'clear all objects

Set objFSO=Nothing
Set objFolder=Nothing
Set objDir=Nothing
Set objFile=Nothing
End Sub

Function FindOSType
    'Defining Variables
    Dim objWMI, objItem, colItems
    Dim OSVersion, OSName
 	Dim ComputerName
 	
 	ComputerName="."
 	
    'Get the WMI object and query results
    Set objWMI = GetObject("winmgmts:\\" & ComputerName & "\root\cimv2")
    Set colItems = objWMI.ExecQuery("Select * from Win32_OperatingSystem",,48)
 
    'Get the OS version number (first two) and OS product type (server or desktop) 
    For Each objItem in colItems
        OSVersion = Left(objItem.Version,3)
                
    Next
 
    
    Select Case OSVersion
        Case "6.1"
        	OSName = "Windows 7"
        Case "6.0" 
            OSName = "Windows Vista"
        Case "5.2" 
            OSName = "Windows 2003"
        Case "5.1" 
            OSName = "Windows XP"
        Case "5.0" 
            OSName = "Windows 2000"
   End Select
 
    'Return the OS name
    FindOSType = OSName
    
    'Clear the memory
    Set colItems = Nothing
    Set objWMI = Nothing
End Function
