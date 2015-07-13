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
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUXWmG7jRBQRoFUZDwg/fLIeo
# qD2gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFH8595T6EKeEjTZd
# /zm4jwQZivFyMA0GCSqGSIb3DQEBAQUABIIBAH1QieAHCTr07gfMx+lg7LL3U4Qq
# g6OeGwZbfGRe1YxqpwxToqhqfnptnmrNoGesTwoJOmjSY9qjjOy9IbFmwiaMWEWS
# Ggpmya6yCJPgzDyNH3wfNUYc1bWJx3nxZbW7VoxcvSY2KV2yWNPgxqDJIuaMZkss
# LqR5FIdXnaHlUnzwNrZczKv7ltMJhyNjljEMl5ObNJVev+YO6JKNZ0TV0E177r5i
# 9Zb3o0JYhZm4+DVBEEPepo8H2KGf4eqOE3LssE18ZWuMNj207/Z0HsRCYRIjD6Gq
# cYdmbDcd80hl+R9nm7IcRS0H0hONqZ8I5ELJcz+NWKFxNtsMh+tMv0q97rw=
# SIG # End signature block
