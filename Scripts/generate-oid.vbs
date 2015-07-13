' oidgen.vbs 
'  
' THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED  
' OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR  
' FITNESS FOR A PARTICULAR PURPOSE. 
' 
' Copyright (c) Microsoft Corporation. All rights reserved 
' 
' This script is not supported under any Microsoft standard support program or service.  
' The script is provided AS IS without warranty of any kind. Microsoft further disclaims all 
' implied warranties including, without limitation, any implied warranties of merchantability 
' or of fitness for a particular purpose. The entire risk arising out of the use or performance 
' of the scripts and documentation remains with you. In no event shall Microsoft, its authors, 
' or anyone else involved in the creation, production, or delivery of the script be liable for  
' any damages whatsoever (including, without limitation, damages for loss of business profits,  
' business interruption, loss of business information, or other pecuniary loss) arising out of  
' the use of or inability to use the script or documentation, even if Microsoft has been advised  
' of the possibility of such damages. 
' ---------------------------------------------------------------------- 
Function GenerateOID() 
    'Initializing Variables 
    Dim guidString, oidPrefix 
    Dim guidPart0, guidPart1, guidPart2, guidPart3, guidPart4, guidPart5, guidPart6 
    Dim oidPart0, oidPart1, oidPart2, oidPart3, oidPart4, oidPart5, oidPart6 
    On Error Resume Next 
    'Generate GUID 
    Set TypeLib = CreateObject("Scriptlet.TypeLib") 
    guidString = TypeLib.Guid 
    'If no network card is available on the machine then generating GUID can result with an error. 
    If Err.Number <> 0 Then 
        Wscript.Echo "ERROR: Guid could not be generated, please ensure machine has a network card." 
        Err.Clear 
        WScript.Quit 
    End If 
    'Stop Error Resume Next 
    On Error GoTo 0 
    'The Microsoft OID Prefix used for the automated OID Generator 
    oidPrefix = "1.2.840.113556.1.8000.2554" 
    'Split GUID into 6 hexadecimal numbers 
    guidPart0 = Trim(Mid(guidString, 2, 4)) 
    guidPart1 = Trim(Mid(guidString, 6, 4)) 
    guidPart2 = Trim(Mid(guidString, 11, 4)) 
    guidPart3 = Trim(Mid(guidString, 16, 4)) 
    guidPart4 = Trim(Mid(guidString, 21, 4)) 
    guidPart5 = Trim(Mid(guidString, 26, 6)) 
    guidPart6 = Trim(Mid(guidString, 32, 6)) 
    'Convert the hexadecimal to decimal 
    oidPart0 = CLng("&H" & guidPart0) 
    oidPart1 = CLng("&H" & guidPart1) 
    oidPart2 = CLng("&H" & guidPart2) 
    oidPart3 = CLng("&H" & guidPart3) 
    oidPart4 = CLng("&H" & guidPart4) 
    oidPart5 = CLng("&H" & guidPart5) 
    oidPart6 = CLng("&H" & guidPart6) 
    'Concatenate all the generated OIDs together with the assigned Microsoft prefix and return 
    GenerateOID = oidPrefix & "." & oidPart0 & "." & oidPart1 & "." & oidPart2 & "." & oidPart3 & _ 
        "." & oidPart4 & "." & oidPart5 & "." & oidPart6 
End Function 
'Output the resulted OID with best practice info 
Wscript.Echo "Your root OID is: " & VBCRLF & GenerateOID & VBCRLF & VBCRLF & VBCRLF & _ 
    "This prefix should be used to name your schema attributes and classes. For example: " & _ 
    "if your prefix is ""Microsoft"", you should name schema elements like ""microsoft-Employee-ShoeSize"". " & _ 
    "For more information on the prefix, view the Schema Naming Rules in the server " & _  
    "Application Specification (http://www.microsoft.com/windowsserver2003/partners/isvs/appspec.mspx)." & _ 
    VBCRLF & VBCRLF & _ 
    "You can create subsequent OIDs for new schema classes and attributes by appending a .X to the OID where X may " & _ 
    "be any number that you choose.  A common schema extension scheme generally uses the following structure:" & VBCRLF & _ 
    "If your assigned OID was: 1.2.840.113556.1.8000.2554.999999" & VBCRLF & VBCRLF & _ 
    "then classes could be under: 1.2.840.113556.1.8000.2554.999999.1 " & VBCRLF & _  
    "which makes the first class OID: 1.2.840.113556.1.8000.2554.999999.1.1" & VBCRLF & _ 
    "the second class OID: 1.2.840.113556.1.8000.2554.999999.1.2     etc..." & VBCRLF & VBCRLF & _ 
    "Using this example attributes could be under: 1.2.840.113556.1.8000.2554.999999.2 " & VBCRLF & _ 
    "which makes the first attribute OID: 1.2.840.113556.1.8000.2554.999999.2.1 " & VBCRLF & _ 
    "the second attribute OID: 1.2.840.113556.1.8000.2554.999999.2.2     etc..." & VBCRLF & VBCRLF & _ 
     "Here are some other useful links regarding AD schema:" & VBCRLF & _ 
    "Understanding AD Schema" & VBCRLF & _ 
    "http://technet2.microsoft.com/WindowsServer/en/Library/b7b5b74f-e6df-42f6-a928-e52979a512011033.mspx " & _ 
    VBCRLF & VBCRLF & _ 
    "Developer documentation on AD Schema:" & VBCRLF & _ 
    "http://msdn2.microsoft.com/en-us/library/ms675085.aspx " & VBCRLF & VBCRLF & _ 
    "Extending the Schema" & VBCRLF & _ 
    "http://msdn2.microsoft.com/en-us/library/ms676900.aspx " & VBCRLF & VBCRLF & _ 
    "Step-by-Step Guide to Using Active Directory Schema and Display Specifiers " & VBCRLF & _ 
    "http://www.microsoft.com/technet/prodtechnol/windows2000serv/technologies/activedirectory/howto/adschema.mspx " & _ 
    VBCRLF & VBCRLF & _ 
    "Troubleshooting AD Schema " & VBCR & _ 
    "http://technet2.microsoft.com/WindowsServer/en/Library/6008f7bf-80de-4fc0-ae3e-51eda0d7ab651033.mspx  " & _ 
    VBCRLF & VBCRLF 
'' SIG '' Begin signature block
'' SIG '' MIINFgYJKoZIhvcNAQcCoIINBzCCDQMCAQExCzAJBgUr
'' SIG '' DgMCGgUAMGcGCisGAQQBgjcCAQSgWTBXMDIGCisGAQQB
'' SIG '' gjcCAR4wJAIBAQQQTvApFpkntU2P5azhDxfrqwIBAAIB
'' SIG '' AAIBAAIBAAIBADAhMAkGBSsOAwIaBQAEFFQj4EbFuELC
'' SIG '' MxRY1MB5DrUh9DVzoIIKWjCCBSIwggQKoAMCAQICEALq
'' SIG '' UCMY8xpTBaBPvax53DkwDQYJKoZIhvcNAQELBQAwcjEL
'' SIG '' MAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
'' SIG '' YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8G
'' SIG '' A1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENv
'' SIG '' ZGUgU2lnbmluZyBDQTAeFw0xNDA3MTcwMDAwMDBaFw0x
'' SIG '' NTA3MjIxMjAwMDBaMGkxCzAJBgNVBAYTAkNBMQswCQYD
'' SIG '' VQQIEwJPTjERMA8GA1UEBxMISGFtaWx0b24xHDAaBgNV
'' SIG '' BAoTE0RhdmlkIFdheW5lIEpvaG5zb24xHDAaBgNVBAMT
'' SIG '' E0RhdmlkIFdheW5lIEpvaG5zb24wggEiMA0GCSqGSIb3
'' SIG '' DQEBAQUAA4IBDwAwggEKAoIBAQDN/k/utTKBsVB56CtG
'' SIG '' 9hoDte3tLFvLoMAB/eumdSSM0L1xWu9O0mb0yYJq2mbA
'' SIG '' p/X1PovSoQtJ1KQOIQL/29TAnqhqtTtH9334sLMYUxt2
'' SIG '' eCfJhJeXknXEYHm/tY2iiN6B5G1/s8aji0mkUkD5918o
'' SIG '' DAH63A/0COL7MfKNpU1LDyRMtnNM+e3tVc1paih6qNfJ
'' SIG '' VcQ6v2BfnyggCS+e8410gTz5m/7DY/FYKMV0uhFAAuXN
'' SIG '' 7W/giXzT9lPb1aMuWHlD/WzcKtml5FtPsWSIqWyaJ2cD
'' SIG '' fmyLG4AguXm9mqmqQYCa4HbPHMPFiomb8mcdqk+4cvR0
'' SIG '' /i1DiNJdCtMN9XRfAgMBAAGjggG7MIIBtzAfBgNVHSME
'' SIG '' GDAWgBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAdBgNVHQ4E
'' SIG '' FgQU5zCCqBp2SLMAcfJ7iXJCRrBQ1JQwDgYDVR0PAQH/
'' SIG '' BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1Ud
'' SIG '' HwRwMG4wNaAzoDGGL2h0dHA6Ly9jcmwzLmRpZ2ljZXJ0
'' SIG '' LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMDWgM6Ax
'' SIG '' hi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1h
'' SIG '' c3N1cmVkLWNzLWcxLmNybDBCBgNVHSAEOzA5MDcGCWCG
'' SIG '' SAGG/WwDATAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3
'' SIG '' dy5kaWdpY2VydC5jb20vQ1BTMIGEBggrBgEFBQcBAQR4
'' SIG '' MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2lj
'' SIG '' ZXJ0LmNvbTBOBggrBgEFBQcwAoZCaHR0cDovL2NhY2Vy
'' SIG '' dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3Vy
'' SIG '' ZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQC
'' SIG '' MAAwDQYJKoZIhvcNAQELBQADggEBAFZZAZjhCkcNjuum
'' SIG '' paMvbTaEDSFs9wHbhgX53/YL8kRb0riptGatwOpUXo/B
'' SIG '' T8QuSm8LMMbZdi/6Y8q5WM1LPl7mHvVGvWDCHYW8o1KJ
'' SIG '' eGeOo4Tqzkw5dfLcWqDaRhPSV6PEi2R4m8M/ex9/qWkZ
'' SIG '' temsoDOUd7kNMUkNTRagyed2Ebzqk+tP7RfRPMzceITh
'' SIG '' 9ZcNQgz7tCt5y9j7rC1FcwqcDbp0MxqGX1bZZ1dseBIF
'' SIG '' 8mfRtceKHXGGcCqZFjygOG1gBviJoOfnYBhDqqFB4eI5
'' SIG '' tiCoo5tY8+wUXCVDAMGtkHG3NrbUG0o/+8WVy+O9FRt1
'' SIG '' oy1jVpEWkUAJMzmo4aUwggUwMIIEGKADAgECAhAECRgb
'' SIG '' X9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJ
'' SIG '' BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
'' SIG '' GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
'' SIG '' BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAe
'' SIG '' Fw0xMzEwMjIxMjAwMDBaFw0yODEwMjIxMjAwMDBaMHIx
'' SIG '' CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJ
'' SIG '' bmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAv
'' SIG '' BgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBD
'' SIG '' b2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUA
'' SIG '' A4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7
'' SIG '' RZmxOttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnX
'' SIG '' tqrwnIal2CWsDnkoOn7p0WfTxvspJ8fTeyOU5JEjlpB3
'' SIG '' gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6Ygs
'' SIG '' IJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8
'' SIG '' y5Kh5TsxHM/q8grkV7tKtel05iv+bMt+dDk2DZDv5LVO
'' SIG '' pKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0xY4P
'' SIG '' waLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp
'' SIG '' /RnfJZPRAgMBAAGjggHNMIIByTASBgNVHRMBAf8ECDAG
'' SIG '' AQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAK
'' SIG '' BggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYB
'' SIG '' BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBD
'' SIG '' BggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNl
'' SIG '' cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNy
'' SIG '' dDCBgQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQu
'' SIG '' ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9v
'' SIG '' dENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNl
'' SIG '' cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNy
'' SIG '' bDBPBgNVHSAESDBGMDgGCmCGSAGG/WwAAgQwKjAoBggr
'' SIG '' BgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29t
'' SIG '' L0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoK
'' SIG '' o6XqcQPAYPkt9mV1DlgwHwYDVR0jBBgwFoAUReuir/SS
'' SIG '' y4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQADggEB
'' SIG '' AD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9
'' SIG '' wz0PxK+L/e8q3yBVN7Dh9tGSdQ9RtG6ljlriXiSBThCk
'' SIG '' 7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEbBw6RFfu6
'' SIG '' r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6
'' SIG '' aGivm6dcIFzZcbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUI
'' SIG '' QjKyNookAv4vcn4c10lFluhZHen6dGRrsutmQ9qzsIzV
'' SIG '' 6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdi
'' SIG '' bqFT+hKUGIUukpHqaGxEMrJmoecYpJpkUe8xggIoMIIC
'' SIG '' JAIBATCBhjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
'' SIG '' RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
'' SIG '' cnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
'' SIG '' c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBAhAC6lAjGPMa
'' SIG '' UwWgT72sedw5MAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3
'' SIG '' AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgor
'' SIG '' BgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEE
'' SIG '' AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRJWL+dgt37ZC4+
'' SIG '' IF+sBu0qjHaMNzANBgkqhkiG9w0BAQEFAASCAQC7S//5
'' SIG '' PXSK8NyLEpBKfdKRsd4ZnKPEcasIYQ51FDOSHJg4Aqbe
'' SIG '' u4ODVuG+7octqXTX4qFymSua1G8hzTMNLx2Ixwn8Rh6m
'' SIG '' H+FcdvYF8zhGXhwqRuTNGyaIuI8fjeOI4D4ndsO3AEOk
'' SIG '' 51kPKwWMhYGMEJk6gmgJlBXb3D2nvoJNjgAwd4xekgQb
'' SIG '' AHSNf3HG4PiucHZ7h4abs0jxHgPG5UhiP3CGrs4v0QTQ
'' SIG '' dEr0gTfp8315EPuUI/mRjAqk2j45cqdftxIa/Gx0g1tI
'' SIG '' MAUnNQr51htJAFHqz6uRj/LMdRJtZUqaHsgRn+x8jUXD
'' SIG '' Fk2s0Wr76EuvxsAvcmI9IlZcXQvj
'' SIG '' End signature block
