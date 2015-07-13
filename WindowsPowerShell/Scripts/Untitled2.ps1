' ScriptTemplate.vbs

' *******************************************************************************************

' This script is used for querying the servers from the Active Directory in the Windows
' 2000/2003 Active Directory domain for use as a template to automate the query or any
' configuration change of the servers.

' The script can also be run against a list of the servers from a text file as the input
' parameter during the run. If no input server list is provided, the script will use the 
' server list that it queries from the Active Directory of the machine's domain in which
' the script is run.

' Note: You must privide the server list from the domain of the machine in which the script
' is run to get proper output from the script. Otherwise, you may not get the proper reports
' from the script.

' Version 1.0.0.2

' *******************************************************************************************

Option Explicit

' Define global variables.
Dim strScriptName, strMainReport, strSecReport, strProgramName, strProgram

' Define friendly name for the title of the help dialog box.
strScriptName = "Name of your script"

' Define the main report name.
strMainReport = "Name of main report"

' Define the secondary report name if needed.
strSecReport = "Name of secondary report"

' Define proper name for the help subroutine.
strProgram = "script"
strProgramName = WScript.ScriptName

' Start the checkArguments subroutine.
checkArguments()

' Subroutine to check and obtain the input argument(s).
Private Sub checkArguments()
Dim strCmd, objItem, i, j, customServerList
Dim ExcludeServer, objServer, arrExServers(), strInputFile
	' Get argument(s) when run in a normal cscript.
	With WScript.Arguments
		If .Count > 0 Then
			For i = 0 To WScript.Arguments.Count - 1
				ReDim Preserve arrArguments(i)
				arrArguments(i) = WScript.Arguments(i)
				If i = 0 Then
					If Mid(arrArguments(i),1,1) <> "/" Then
						ShowUsage()
					End If
				End If
			Next
			i = 0
			For Each objItem In arrArguments
				i = i + 1
				Select Case i
					Case 1
						strCmd = LCase(objItem)			
						Select Case strCmd
							Case "/","/?","/h","help","-h","-help"
								ShowUsage()
							Case "/e"
								ExcludeServer = True
							Case "/f"
								customServerList = True
							Case Else
								ShowUsage()
						End Select
					Case 2
						strCmd = Trim(objItem)
						If ExCludeServer = True Then
							If InStr(strCmd,",") > 0 Then
								For Each objServer In Split(strCmd,",")
									ReDim Preserve arrExServers(j)
									arrExServers(j) = UCase(objServer)
									j = j + 1
								Next
							Else
								ReDim Preserve arrExServers(j)
								arrExServers(j) = UCase(strCmd)
							End If
						ElseIf customServerList = True Then
							strInputFile = strCmd
						End If
					Case Else
						ShowUsage()
				End Select
			Next
		End If
		' Make sure that the user supplies the necessary arguments.
		If ExcludeServer = True Or customServerList = True Then
			If i <> 2 Then ShowUsage()
		End If	
	End With
	RuntheScript strInputFile, arrExServers
End Sub

' Sub routine to run the script.
Private Sub RuntheScript(strInputFile, arrExServers)
Dim strStartTime, strFNDate, strDomain, outFileName1, outFileName2
Dim outFileName3, outFileName4, arrServerList, strInRec, strElapsedTime
Dim strRunTime

	' Get the start time.
	strStartTime = Now
	
	' Get the current date for the log file name.
	strFNDate = fndate(Date)
	
	' Get DNS domain name from the current domain for the log files.
	strDomain = getDNSDomain()
	
	' Set the output log file names.
	outFileName1 = strDomain & "_Error_Servers_" & strFNDate & ".xls"
	outFileName2 = strDomain & "_" & strMainReport & "_Servers_" & strFNDate & ".xls"
	outFileName3 = strDomain & "_Offline_Servers_" & strFNDate & ".xls"
	outFileName4 = strDomain & "_Unknown_Servers_" & strFNDate & ".xls"
	
	If Len(strInputFile) > 0 Then
		' Read the server list from the input file if it is provided.
		PrintMsg2 "Processing servers from the input file " & strInputFile & "."
		' Read the server list into the array.
		arrServerList = getServerList(strInputFile, strInRec)
		' Check to see if the input file contains any record.
		If strInRec < 1 Then
			ShowUsageRec(strInputFile)
			WScript.Quit
		End If
	Else
		' Get the server list from the Active Directory and write to a log file.
		arrServerList = getADServerList(strFNDate)
		PrintMsg1 "Processing servers from the Active Directory of " & strDomain & " domain."
	End If
	
	' Process the servers from the dictionary list.
	ProcessServers strInputFile, arrServerList, arrExServers, _
	outFileName1, outFileName2, outFileName3, outFileName4
	
	' Calculate the elapsed time and display the finish message.
	strElapsedTime = DateDiff("s",strStartTime,Now)
	strRunTime = convertTime(strElapsedTime)
	PrintMsg4 "******** The " & strProgram & " has finished ********"
	PrintMsg4 "The " & strProgram & " run time is: " & strRunTime & "."
	
	' Below is a command to run the ShowFinish subroutine to display
	' a finish message with a popup dialog box. Remove the rem character
	' to allow this popup dialog box.
	'ShowFinish strRunTime
	
End Sub

' Sub routine to process the servers from the array list.
Private Sub ProcessServers(strInputFile, arrServerList, arrExServers, _
outFileName1, outFileName2, outFileName3, outFileName4)

' Declare the standard variables for the script template.
Dim objFSO, strLComputer, objServer, strServerData, strComputer, strOU
Dim h, strNLength, SpToAdd, strIPAddress, strPingStatus, strConnection
Dim i, strOSVersion, strDomainRole, strNTBDomain, j, k, l, m, outFile1
Dim outFile2, outFile3, outFile4

' Declare the custom variables for the script's specific purpose.
Dim strVariable_for_Specific_Task

	' Define constant for FSO.
	Const ForWriting = 2
	
	' Instantiate the file system object.
	Set objFSO = CreateObject("Scripting.FileSystemObject")

	' Get the local computer name for the WMIconnection function.
	strLComputer = CreateObject("Wscript.Network").ComputerName
	
	For Each objServer In arrServerList
		strServerData = objServer
		
		' Use the server list from the input file instead if it is provided.
		If Len(strInputFile) > 0 Then
			strComputer = strServerData
		Else
			strComputer = Split(strServerData,vbTab)(1)
			strOU = Split(strServerData,vbTab)(2)
		End If
		
		If Not excludedServer(strComputer, arrExServers) Then
		
			' Count each record for display.
			h = h + 1
			strNLength = Len(h)
			Select Case strNLength
				Case 1
					SpToAdd = 3
				Case 2
					SpToAdd = 2
				Case 3
					SpToAdd = 1
				Case 4
					SpToAdd = 0
			End Select
			
			' Print the process message.
			PrintMsg3 Space(SpToAdd) & h & Space(2) & "Processing server: " & strComputer & ". . ."
			' Clear the variables
			strIPAddress = "" : strPingStatus = "" : strConnection = ""
			PrintMsg4 "Pinging server " & strComputer & ". . ."
			strIPAddress = getPingIP(strComputer, strPingStatus)
    		If strPingStatus = "On line" Then
				' Check for the connection status.
				PrintMsg4 "Checking for connection status on " & strComputer & ". . ."
    			strConnection = WMIConnection(strComputer, strLComputer)
    			If strConnection <> "" Then
    				i = i + 1
    				If Len(strInputFile) > 0 Then
    					If i = 1 Then  ' Write the first line as a header.
    						Set outFile1 = objFSO.OpenTextFile(outFileName1, ForWriting, True)
    						outFile1.WriteLine "No." & vbTab & "Host Name" & vbTab & "IP Address" _
    						& vbTab & "Error Information"
    					End If
						PrintMsg4 "***** Error connecting to " & strComputer & " ***** . . ."
						PrintMsg5 strConnection
						outFile1.WriteLine i & vbTab & strComputer & vbTab & strIPAddress _
						& vbTab & strConnection
    				Else
						If i = 1 Then  ' Write the first line as a header.
							Set outFile1 = objFSO.OpenTextFile(outFileName1, ForWriting, True)
							outFile1.WriteLine "No." & vbTab & "Host Name" & vbTab & "IP Address" _
							& vbTab & "OU Container" & vbTab & "Error Information"
						End If
						PrintMsg4 "***** Error connecting to " & strComputer & " ***** . . ."
						PrintMsg5 strConnection
						outFile1.WriteLine i & vbTab & strComputer & vbTab & strIPAddress & vbTab & _
						strOU & vbTab & strConnection
					End If
				Else
					' Clear the variables.
					strOSVersion = "" : strDomainRole = "" : strNTBDomain = ""
					' Get the OS version and service pack.
					strOSVersion = getOSVersion(strComputer)
					' Query for the server role.
					strDomainRole = getDomainRole(strComputer)
					' Query for NetBIOS domain name using the registry method.
					strNTBDomain = getNetBIOSDomain(strComputer)
					' Get the OU name of the server when the server list is from an input file.
					If Len(strInputFile) > 0 Then
						strOU = getOU(strComputer, strNTBDomain)
					End If
					
					' If any of the variable names is blank, set it to Unknown.
					If strDomainRole = "" Then strDomainRole = "Unknown"
					If strOSVersion = "" Then strOSVersion = "Unknown"
					If strNTBDomain = "" Then strNTBDomain = "Unknown"
					If strOU = "" Then strOU = "Unknown"
					
					' Section that contains specific tasks for which the script is intended.
					' **********************************************************************					
					' Below is the area that contains the variables that accept the returned values
					' from the custom functions to obtain the data or the values resulted from the
					' functions that make configuration change to the server.  These variables are
					' used for logging to the log file.  This area can also contain the subroutines that
					' can make the configuration change to the server without any returned values.
					
					'	AREA FOR CODES TO DO SOMETHING.
					
					' Log your returned value in the main log file below.
					j = j + 1
					If j = 1 Then  ' Write the first line as a header.
						Set outFile2 = objFSO.OpenTextFile(outFileName2, ForWriting, True)
						outFile2.WriteLine "No." & vbTab & "Host Name" & vbTab & "IP Address" & vbTab & _
						"OU Container" & vbTab & "Operating System" & vbTab & "Server Role" & vbTab & _
						"Domain" & vbTab & "Header for specific task"
					End If
					' Write the result to the log file.
					outFile2.WriteLine j & vbTab & strComputer & vbTab & strIPAddress & vbTab & strOU _
					& vbTab & strOSVersion & vbTab & strDomainRole & vbTab & strNTBDomain & vbTab & _
					strVariable_for_Specific_Task
					
					' *************************************************************************
					' End section that contains specific tasks for which the script is intended.
						
				End If
				
			ElseIf strPingStatus = "Off line" Then
			
				' Log the off line servers.
				PrintMsg4 strComputer & " is currently off line."
				l = l + 1
				If l = 1 Then
					Set outFile3 = objFSO.OpenTextFile(outFileName3, ForWriting, True)
					outFile3.WriteLine "No." & vbTab & "Host Name" & vbTab & "IP Address"
				End If
				outFile3.WriteLine l & vbTab & strComputer & vbTab & strIPAddress
				
			Else
				'Log the unknown host servers.
				PrintMsg4 strComputer & " is an unknown host."
				m = m + 1
				If m = 1 Then
					Set outFile4 = objFSO.OpenTextFile(outFileName4, ForWriting, True)
					outFile4.WriteLine "No." & vbTab & "Host Name"
				End If
				outFile4.WriteLine m & vbTab & strComputer				
				
			End If
				
		End If
		
	Next

' Close log files and clean up variables.
If IsObject(outFile1) Then
	outFile1.Close: Set outFile1 = Nothing
ElseIf IsObject(outFile2) Then
	outFile2.Close: Set outFile2 = Nothing
ElseIf IsObject(outFile3) Then
	outFile3.Close: Set outFile3 = Nothing
ElseIf IsObject(outFile4) Then
	outFile4.Close: Set outFile4 = Nothing
End If
Set objFSO = Nothing

End Sub

' Section that contains custom functions and subroutines specific for the script.
' ******************************************************************************

' AREA FOR FUNCTIONS OR SUBROUTINES SPECIFIC FOR THE SCRIPT.

' ************************************************************************
' End section for custom functions and subroutines specific for the script.

' Section with the standard functions and subroutines for the script template.
' ****************************************************************************

' Function to get current date for the log file name.
Private Function fnDate(tDate)
Dim mDate, dDate, yDate
	mDate = Month(tDate)
	If Len(mDate) = 1 Then mDate = "0" & mDate
	dDate = Day(tDate)
	If Len(dDate) = 1 Then dDate = "0" & dDate
	yDate = Year(tDate)
	fnDate = mDate & "-" & dDate & "-" & yDate
Set mDate = Nothing : Set dDate = Nothing
Set yDate = Nothing
End Function

' Function to obtain the DNS domain name.
Private Function getDNSDomain()
Dim objRootDSE, strDN, strSubDomain, strRootDomain
	' Determine DNS domain name from RootDSE object.
	Set objRootDSE = GetObject("LDAP://RootDSE")
	strDN = Split(objRootDSE.Get("defaultNamingContext"),",")
	strSubDomain = Mid(strDN(0),InStr(strDN(0),"=") + 1)
	strRootDomain = Mid(strDN(1),InStr(strDN(1),"=") + 1)
	getDNSDomain = strSubDomain & "." & strRootDomain
Set objRootDSE = Nothing
End Function

' Function to read server list from the file into the array.
Private Function getServerList(ByVal strInputFile, ByRef strInRec)
Dim objFSO, inFile, dicDataList, strData
Const ForReading = 1
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	On Error Resume Next
	Set inFile = objFSO.OpenTextFile(strInputFile, ForReading, False)
	If IsObject(inFile) Then
		Set dicDataList = CreateObject("Scripting.Dictionary")
		Do Until inFile.AtEndOfStream
			strData = Trim(UCase(inFile.ReadLine))
			If Len(strData) > 0 Then
				dicDataList.Add dicDataList.Count, strData
			End If
		Loop
		getServerList = dicDataList.Items
		strInRec = dicDataList.Count
	End If
	Err.Clear
	On Error Goto 0
Set objFSO = Nothing : Set inFile = Nothing
Set dicDataList = Nothing
End Function

' Function to get the server list from the Active Directory.
Private Function getADServerList(strFNDate)
Dim dicData, objRootDSE, strDNSDomain, strDN, strSubDomain, strRootDomain
Dim strDomain, outFileName, objFSO, outFile, objConnection, objCommand
Dim strQuery, objRecordSet, DataList, strOS, strComputer, strComputerDN
Dim strOU, strOSVer, strHostData, i
Const ForWriting = 2
	Set dicData = CreateObject("Scripting.Dictionary")
	Set objRootDSE = GetObject("LDAP://RootDSE")
	strDNSDomain = objRootDSE.Get("defaultNamingContext")
	strDN = Split(strDNSDomain,",")
	strSubDomain = Mid(strDN(0),InStr(strDN(0),"=") + 1)
	strRootDomain = Mid(strDN(1),InStr(strDN(1),"=") + 1)
	strDomain = strSubDomain & "." & strRootDomain
	outFileName = strDomain & "_Domain_Servers_" & strFNDate & ".xls"
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	Set outFile = objFSO.OpenTextFile(outFileName, ForWriting, True)
	Wscript.Echo
	Wscript.Echo Space(3) & "Querying server list from the " & strDomain & " domain. Please wait. . ."
	Wscript.Echo
	Const ADS_SCOPE_SUBTREE = 2
	Set objConnection = CreateObject("ADODB.Connection")
	Set objCommand = CreateObject("ADODB.Command")
	objConnection.Provider = "ADsDSOObject"
	objConnection.Open "Active Directory Provider"
	Set objCommand.ActiveConnection = objConnection
	strQuery = "<LDAP://" & strDNSDomain _
				& ">;(&(objectCategory=Computer));"_
				& "Name,distinguishedName,operatingSystem;Subtree"
	objCommand.CommandText = strQuery
	objCommand.Properties("Page Size") = 1000
	objCommand.Properties("Timeout") = 30
	objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE
	objCommand.Properties("Cache Results") = False
	Set objRecordSet = objCommand.Execute
	' Begining section to sort records using ADO.
	Set DataList = CreateObject("ADODB.Recordset")
	DataList.Fields.Append "strHostName", 200, 255 'adVarChar
	DataList.Fields.Append "strOUName", 200, 255 'adVarChar
	DataList.Fields.Append "strOSVersion", 200, 255 'adVarChar
	DataList.Open
	objRecordSet.MoveFirst
	Do Until objRecordSet.EOF
		strOS = objRecordSet.Fields("operatingSystem").Value
		If InStr(LCase(strOS),"server") > 0 Then
			DataList.AddNew
			strComputer = UCase(objRecordSet.Fields("Name").Value)
			strComputerDN = objRecordSet.Fields("distinguishedName").Value
			strOU = getReverseOU(strComputerDN)
			strOSVer = objRecordSet.Fields("operatingSystem").Value
			DataList("strHostName") = strComputer
			DataList("strOUName") = strOU
			DataList("strOSVersion") = strOSVer
			DataList.Update
   	End If
    	objRecordSet.MoveNext
	Loop
	' Sort the records by OU and then host name.
	DataList.Sort = "strOUName,strHostName"
	DataList.MoveFirst
	Do Until DataList.EOF
		i = i + 1
		strComputer = DataList.Fields.Item("strHostName")
		strOU = DataList.Fields.Item("strOUName")
		strOSVer = DataList.Fields.Item("strOSVersion")
		strHostData = i & vbTab & strComputer & vbTab & strOU & vbTab & strOSVer
		If i = 1 Then outFile.WriteLine "No." & vbTab & "Host Name" _
		& vbTab & "OU Container" & vbTab & "Operating System"
		outFile.WriteLine i & vbTab & strComputer & vbTab & strOU _
		& vbTab & strOSVer
		dicData.Add dicData.Count, strHostData
	DataList.MoveNext
	Loop
	getADServerList = dicData.Items
' Clean up variables.
Set dicData = Nothing: Set objRootDSE = Nothing: Set objFSO = Nothing
Set outFile = Nothing: Set objConnection = Nothing: Set objCommand = Nothing
Set objRecordSet = Nothing: Set DataList = Nothing
End Function

'Function to get the OU in a back slash format.
Private Function getReverseOU(strDN)
Dim strOUNames, arrItem, i, strTemp, strResult
	strOUNames = Mid(strDN, InStr(strDN, "=") + 1)
	strOUNames = Mid(strOUNames, InStr(strOUNames, "=") - 2)
	strOUNames = Left(strOUNames, InStr(UCase(strOUNames), "DC=") - 2)
	arrItem = Split(strOUNames, ",")
	For i = UBound(arrItem) To LBound(arrItem) Step - 1
    	strTemp = Right(arrItem(i), Len(arrItem(i)) - InStr(arrItem(i), "="))
   	strResult = strResult & strTemp & "\"
	Next
	getReverseOU = Left(strResult, Len(strResult) - 1)
End Function

' Function to exclude certain servers.
Private Function excludedServer(ByVal strComputer, ByVal arrExServers)
Dim objItem
	For Each objItem In arrExServers
		If LCase(strComputer) = LCase(objItem) Then
			excludedServer = True
			Exit Function
		End If
	Next
excludedServer = False
End Function

' Function to ping the computer and return the IP with three responses.
Private Function getPingIP(ByVal strComputer, ByRef strPingStatus)
Dim objShell, objList, objRegEX, objExecObject, strText, objItem, i
Dim objIp, colItems
	Set objShell = CreateObject("WScript.Shell")
	Set objList = CreateObject("Scripting.Dictionary")
	Set objRegEX = New RegExp
	objRegEx.Pattern = "\[((\d+\.){3}\d+)\]"
	Set objExecObject = objShell.Exec _
    	("%comspec% /c ping -n 3 -w 1000 " & strComputer)
	Do Until objExecObject.StdOut.AtEndOfStream
		strText = objExecObject.StdOut.ReadLine
		If Len(strText) > 2 Then
    		objList.Add objList.Count, strText
    		If objList.Count = 2 Then Exit Do
    	End If
	Loop
	For Each objItem In objList.Items
		i = i + 1
		If InStr(objItem,"could not find host") > 0 Then
			strPingStatus = "Unknown host"
			getPingIP = "No IP Address"
			Exit Function
		ElseIf InStr(1,objItem,strComputer,1) > 0 Then
			If i = 1 Then
				Set colItems = objRegEX.Execute(objItem)
				For Each objIp In colItems
    				getPingIP = objIp.SubMatches(0)
				Next
			End If
		ElseIf InStr(objItem,"Reply from") > 0 Then
			strPingStatus = "On line"
			Exit Function
		ElseIf InStr(objItem,"Request timed") > 0 Then
			strPingStatus = "Off line"
			Exit Function
		End If
   Next
Set objShell = Nothing: Set objExecObject = Nothing
Set objRegEx = Nothing
End Function

' Function to check for the WMI connection.
Private Function WMIConnection(strComputer, strLComputer)
	If strComputer = strLComputer Then
		Exit Function
	Else
		Const WBEM_FLAG_CONNECT_USE_MAX_WAIT = &H80
		On Error Resume Next
		Dim objSWbemLocator, objWMIService
		Set objSWbemLocator = CreateObject("WbemScripting.SWbemLocator")
		Set objWMIService = objSWbemLocator.ConnectServer _
		(strComputer,"root\CIMV2","","","","",WBEM_FLAG_CONNECT_USE_MAX_WAIT)
		If Err.Number <> 0 Then
			WMIConnection = "Error: " & Hex(Err.Number) & _
			". " & Err.Description
		End If
	End If
	Err.Clear
	On Error Goto 0
Set objSWbemLocator = Nothing: Set objWMIService = Nothing
End Function

' Function to get the OS version and SP level.
Private Function getOSVersion(ByVal strComputer)
Dim objWMIService, colItems, objItem, strOSVer, strSP
	Set objWMIService = GetObject("winmgmts:\\"& strComputer & "\root\cimv2")
	Set colItems = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
	On Error Resume Next
	For Each objItem In colItems
		strOSVer = objItem.Caption
		strSP = "Service Pack " & objItem.ServicePackMajorVersion
		Select Case strOSVer
			Case "Microsoft Windows 2000 Server"
				getOSVersion = "Windows 2000 Server " & strSP
			Case "Microsoft Windows 2000 Advanced Server"
				getOSVersion = "Windows 2000 Advanced Server " & strSP
			Case "Microsoft(R) Windows(R) Server 2003, Enterprise Edition"
				getOSVersion = "Windows 2003 Enterprise Server " & strSP
			Case "Microsoft(R) Windows(R) Server 2003, Standard Edition"
				getOSVersion = "Windows 2003 Standard Server " & strSP
			Case "Microsoft(R) Windows(R) Server 2003, Datacenter Edition"
				getOSVersion = "Windows Server 2003, Datacenter Edition " & strSP
			Case "Microsoft(R) Windows(R) Server 2003, Datacenter " & _
				"Edition for 64-Bit Itanium-based Systems"
				getOSVersion = "Windows Server 2003, 64-Bit Itanium " & _
				"Datacenter Edition " & strSP
			Case "Microsoft(R) Windows(R) Server 2003, Enterprise " & _
				"Edition for 64-Bit Itanium-based Systems"
				getOSVersion = "Windows Server 2003, 64-Bit Itanium " & _
				"Enterprise Edition " & strSP
			Case "Microsoft(R) Windows(R) Server 2003 Enterprise x64 Edition"
				getOSVersion = "Windows Server 2003 Enterprise " & _
				"x64 Edition " & strSP
			Case "Microsoft Windows XP Professional"
				getOSVersion = "Windows XP Professional " & strSP
			Case Else
				getOSVersion = "Unknown OS Type"
		End Select
	Next
	Err.Clear
	On Error Goto 0
Set objWMIService = Nothing: Set colItems = Nothing
End Function

' Function to get the machine's domain role.
Private Function getDomainRole(ByVal strComputer)
Dim objWMIService, colItems, objItem, strRole
	Set objWMIService = GetObject("winmgmts:\\"& strComputer & "\root\cimv2")
	Set colItems = objWMIService.ExecQuery("Select * from Win32_ComputerSystem")
	On Error Resume Next
	For Each objItem In colItems
		Select Case (objItem.DomainRole)
			Case 0
				strRole = "Standalone Workstation"
			Case 1
				strRole = "Member Workstation"
			Case 2
				strRole = "Standalone Server"
			Case 3
				strRole = "Member Server"
			Case 4
				strRole = "Backup DC"
			Case 5
				strRole = "Primary DC"
		End Select
	Next
	getDomainRole = strRole
	Err.Clear
	On Error Goto 0
Set objWMIService = Nothing: Set colItems = Nothing
End Function

' Function to get NetBIOS domain name using the registry data.
Private Function getNetBIOSDomain(ByVal strComputer)
Const HKEY_LOCAL_MACHINE = &H80000002
Dim strKeyPath, strValueName, objRegistry, strValue
	strKeyPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon"
	strValueName = "CachePrimaryDomain"
	On Error Resume Next
	Set objRegistry = GetObject("winmgmts:{impersonationLevel=impersonate}//" & _
		 strComputer & "/root/default:StdRegProv")
	objRegistry.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue
	If Len(strValue) Then
		getNetBIOSDomain = strValue
	End If
	Err.Clear
	On Error Goto 0
Set objRegistry = Nothing
End Function

' Function to get the OU of a computer.
Private Function getOU(ByVal strComputer, ByVal strNTBDomain)
Dim objTrans, strDN
	Const ADS_NAME_INITTYPE_GC = 3
	Const ADS_NAME_TYPE_NT4 = 3
	Const ADS_NAME_TYPE_1779 = 1
	Set objTrans = CreateObject("NameTranslate")
	objTrans.Init ADS_NAME_INITTYPE_GC, ""
	objTrans.Set ADS_NAME_TYPE_NT4, strNTBDomain & "\" _
	& strComputer & "$"
	strDN = objTrans.Get(ADS_NAME_TYPE_1779)
	getOU = getReverseOU(strDN)
Set objTrans = Nothing: Set strDN = Nothing
End Function

' Function to convert seconds into day, hh:mm:ss format.
Private Function convertTime(seconds)
Dim ConvSec, ConvMin, ConvHour, ConvDay, strDay
   ConvSec = seconds Mod 60
   If Len(ConvSec) = 1 Then
		ConvSec = "0" & ConvSec
   End If
   ConvMin = (seconds Mod 3600)\60
   If Len(ConvMin) = 1 Then
		ConvMin = "0" & ConvMin
   End If
   ConvHour =  seconds\3600
   If Len(ConvHour) = 1 Then
		ConvHour = "0" & ConvHour
   End If
   If ConvHour = 24 Then
   	ConvHour = 00
   	convertTime = "1 Day, " & ConvHour & ":" & ConvMin & ":" & ConvSec
   ElseIf ConvHour > 24 Then
   	ConvDay = ConvHour\24
   	ConvHour = ConvHour Mod 24
   	If Len(ConvHour) = 1 Then ConvHour = "0" & ConvHour
   	If ConvDay = 1 Then
   		strDay = " Day, "
   	Else
   		strDay = " Days, "
   	End If
   	convertTime = ConvDay & strDay & ConvHour & ":" & ConvMin & ":" & ConvSec
   Else
   	convertTime = ConvHour & ":" & ConvMin & ":" & ConvSec
   End If
End Function

' Subroutine to display the help message.
Private Sub ShowUsage()
Dim message
	message = "Syntax for " & strProgramName & " is as follows:" & vbcrlf & vbCrLf & _
	"cscript " & strProgramName & " [/f filename] [/e server1,server2,server3,etc]" & vbcrlf & vbcrlf & _
	"/f filename is an optional argument where filename is a text file that" & Space(8) & vbcrlf & _
	"contains a list of the servers that you supply in a column format." & Space(8) & vbcrlf & vbcrlf & _
	"If the file with a list of servers is supplied, the " & strProgram & " will run using" & Space(12) & vbcrlf & _
	"the servers from this list instead of that from the Active Directory" & Space(12) & vbcrlf & _
	"of the current domain." & vbcrlf & vbcrlf & _
	"/e server1,server2,server3 is also an optional argument where server1," & Space(8) & vbcrlf & _
	"server2,server3 after /e are the servers on which you want to exclude" & Space(8) & vbcrlf & _
	"from being processed by the " & strProgram & " when the server list is obtained from" & Space(8) & vbcrlf & _
	"the Active Directory of the current domain by the " & strProgram & "."
	CreateObject("WScript.Shell").Popup Message,180,strScriptName,vbInformation
	WScript.Quit
End Sub

' Subroutine to show that the input file is empty.
Private Sub ShowUsageRec(strInputFile)
Dim message
	message = "The input file " & Chr(34) & strInputFile & Chr(34) & " contains " & _
	"no record of your servers." & Space(8) & vbcrlf & vbCrLf & _
	"Please provide an input file that contains a list of the servers" & Space(8) & vbcrlf & _
	"in a column format."
	CreateObject("WScript.Shell").Popup Message,120,strScriptName,vbCritical
	WScript.Quit
End Sub

' Subroutine to show the finish dialog box.
Private Sub ShowFinish(strRunTime)
Dim Message
	Message = "The " & strProgram & " has finished." & vbLF & vbLF & _
	"The " & strProgram & " run time is: " & strRunTime & "." & Space(8)
	CreateObject("WScript.Shell").Popup Message,,strScriptName,vbInformation
End Sub

' Subroutine to display a screen message 0.
Private Sub PrintMsg0 (ByVal strMessage)
	WScript.StdOut.WriteBlankLines(1)
	WScript.StdOut.WriteLine Space(3) & strMessage
	WScript.StdOut.WriteBlankLines(1)
End Sub

' Subroutine to display a screen message 1.
Private Sub PrintMsg1 (ByVal strMessage)
	WScript.StdOut.WriteLine Space(3) & strMessage
End Sub

' Subroutine to display a screen message 2.
Private Sub PrintMsg2 (ByVal strMessage)
	WScript.StdOut.WriteBlankLines(1)
	WScript.StdOut.WriteLine Space(3) & strMessage
End Sub

' Subroutine to display a screen message 3.
Private Sub PrintMsg3 (ByVal strMessage)
	WScript.StdOut.WriteBlankLines(1)
	WScript.StdOut.WriteLine Space(3) & strMessage
End Sub

' Subroutine to display a screen message 4.
Private Sub PrintMsg4 (ByVal strMessage)
	WScript.StdOut.WriteBlankLines(1)
	WScript.StdOut.WriteLine Space(9) & strMessage
End Sub

' Subroutine to display a screen message 5.
Private Sub PrintMsg5 (ByVal strMessage)
	WScript.StdOut.WriteLine Space(9) & strMessage
End Sub

' Subroutine to display a screen message 6.
Private Sub PrintMsg6 (ByVal Message)
	WScript.StdOut.WriteBlankLines(1)
	WScript.StdOut.WriteLine Space(9) & Message
	WScript.StdOut.WriteBlankLines(1)
End Sub

' ***************************************************************************
' End section with standard functions and subroutines for the script template.

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoQpwCHaTWZN24IBxszxjD//v
# 8DegggpaMIIFIjCCBAqgAwIBAgIQBg4i3l65iHFvsYhyMrxXATANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAN0ZOWCIOEyhtxA/koB0azqKK40Pw3fa8GLif/ZM0cXJWGawkVgxOMbejeJW
# YCqXgEHF2MX/cJY8svCmLlX8M7AdjXYgtAS+C+cEHxrGAMMzj3/9EOu6DjzxIcwL
# l1GKoUwy8X3/GRGk3sBWT5CwKYRJdh9goWy74ltZN+sTKKeDHqpfuvxye6c++PC7
# 86wzm4MwfOIuPE9StFeo/0nKheEukfK9cpthlE5dUHpW0OjmJdX/g0mEdIjm2/Q2
# 50fzQyLQXOuMVIJ4Qk2comMDNRvZZvSPOBwWZ6fAR4tXfZwlpUcLv3wBbIjslhT7
# XasCm73TdBj+ZFDx2tUtpWguP/0CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBS+FASXsrRle2tLXdkVyoT1Dbw7
# QDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAbhjcmv+WCZwWCIYQwiEsH94SesBr0cPqWjEtJrBefqU9zFdB
# u5oc/WytxdCkEj5bxkoN9aJmuDAZnHNHBwIYeUz0vNByZRz6HsPzNPxLxThajJTe
# YOHlSTMI/XzBhJ7VzCb3YFhkD5f9gcJ5n+Z94ebd/1SoIvc9iwC3tTf5x2O7aHPN
# iyoWLTV4+PgDntCy/YDj11+uviI9sUUjAajYPEDvoiWinyT+7RlbStlcEuBwqvqT
# nLaiRsK17rjawW87Nkq/jB8rymUR/fzluIpHmPA4P0NazH4v5f62mpMFqdk0osMU
# QJ/qqACQ+2+/eAw7Gr6igNvlsxQpPfxsPNtUkTCCBTAwggQYoAMCAQICEAQJGBtf
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
# Q0ECEAYOIt5euYhxb7GIcjK8VwEwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFM1kVXIYYQojtwtO
# HFScRxFghCieMA0GCSqGSIb3DQEBAQUABIIBAL2L1GEa8Cvi0jqU2WjhMSJhbh/X
# ANgTZbh0r8945YNgicPaQCky4Ci/AJW1/w+p8gaFFpJXbK1jzoQK9cu8QQQPUNKl
# etFUQcF8TGunZhhx2iDVmuKORKV++QSfNFem1nLdRi/P1T1SPenjhBBcwEX5uIzE
# dLbFfqh7n8FA3RKWAj9HKkQ4zA+EEROg6d2WjfCOP3YNTKZcrWX9Sbl2kaw9w5AT
# 2saDe11nkcFpY1z0uPkqYMyvhlKtMBbjulGw9T+dMf3moOR14w8tB8eXWZLrKNb7
# B+EIXgshSRoiZkOBavPSIaqgOBI/+NNXS9wFyFVmvAuMCYjPjPwkHwb4P9k=
# SIG # End signature block
