<?xml version="1.0" ?> 
<package> 
<job id="LogonHealth" prompt="no"> 
<?job error="false" debug="false" ?> 
<runtime> 
<description>Author: Daniel Belcher (lotek.belcher@gmail.com) 
Modified: 5 / 23 / 2012 
Comments: CM health checking logon framework 

This script serves as a framework for SCCM health and miscellaneous 
configuration checks. Settings can be passed at runtime to override 
the config.xml 

Description: 
This script serves as a framework for SCCM health and miscellaneous 
configuration checks. 

The supplied code is the intellectual property of Daniel Belcher, 
and is free to use for non-profit without request or consent of 
it's author. 
</description> 
<named helpstring="The XML file that is read by this script.  Default is Config.xml" name="Config" required="false" type="string"/> 
<named helpstring="Sets path for log output." name="Log" required="false" type="string"/> 
<named helpstring="Logs to event viewer" name="Events" required="false" type="simple"/> 
<named helpstring="Runs Verbose with errors" name="Debug" required="false" type="simple"/> 
</runtime> 
<object id="oFSO" progid="Scripting.FileSystemObject" events="false" reference="true"/> 
<object id="oWShell" progid="WScript.Shell" events="false" reference="true"/> 
<script id="LogonHealth" language="VBScript"> 

<![CDATA[ 
Option Explicit 

Const logInfo = 1 
Const logWarning = 2 
Const logError = 3 

'Global Objects 
Dim Config, Logging, objWmi, oXMLDom, Args, nArgs 
'Global Bools 
Dim Events, DebugMode, booTerm 
'Global Values 
Dim sArgs, Item, Modified, Version 
DebugMode = False 
Events = False 
booTerm = False 
Modified = "5/23/2012" 
Version = "2.1.3" 
Set Config = New cls_Dict 
Set Logging = New cls_Logging 



If Debugmode Then On Error GoTo 0 Else On Error Resume Next 

Set Args = WScript.Arguments 

For Each Item In Args 
sArgs = sArgs & " " & Item 
Next 

If Instr(1, WScript.FullName, "CScript", 1) = 0 Then 
oWShell.Run "cscript.exe """ & WScript.ScriptFullName & """" & sArgs, 0, False 
WScript.Quit 
End If 

Set nArgs = WScript.Arguments.Named 
If nArgs.Exists("Log") Then 
Logging.Path = nArgs.Item("Log") 
End If 
If nArgs.Exists("Config") Then 
Call Config.Add("config",nArgs.Item("config")) 
End If 
If nArgs.Exists("debug") Then 
Call Config.Add("DebugMode",True) 
End If 
If nArgs.Exists("Events") Then 
Call Config.Add("Events",True) 
End If 

Call Run 
Call Terminate(0) 

'================================================================================= 
'Run Body ======================================================================== 
'================================================================================= 
Sub Run 

If Debugmode Then On Error GoTo 0 Else On Error Resume Next 

Call Log_Header 
Call Load_Configuration 
Call Set_RegValue("HKEY_LOCAL_MACHINE\SOFTWARE\SccmHealth\LastRun",Date & " " & Time,"REG_SZ") 
If Config.Exists("DebugMode") Then 
DebugMode = Config.Key("DebugMode") 
End If 
If Config.Exists("Events") Then 
Logging.LogEvent = Config.Key("Events") 
End If 
If Config.Key("RemoteLogging") Then 
Logging.RemotePath = Config.Key("RemoteLoggingPath") 
Logging.RemoteLog = Config.Key("RemoteLogging") 
End If 
If Not Check_System Then 
Call Config.ItemList("reportcard","failed system check") 
Else 
Call Config.ItemList("reportcard","passed system check") 
End If 
If Not Check_SCCMClient Then 
Call Config.ItemList("reportcard","failed sccm client check") 
Else 
Call Config.ItemList("reportcard","passed sccm client check") 
End If 
If Not Check_CMClientHealth Then 
Call Config.ItemList("reportcard","failed sccm health check") 
Else 
Call Config.ItemList("reportcard","passed sccm health check") 
End If 

End Sub 