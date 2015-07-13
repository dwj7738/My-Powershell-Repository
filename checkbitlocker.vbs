' BitLocker Status Script by William Jackson (w@austin.utexas.edu)
' Useful as an Absolute Manage Custom Information Field (CIF)
' 
cif = ""
' 
Set s = CreateObject("WScript.Shell")
Set e = s.Exec("manage-bde -status")
Set status = e.StdOut
' 
Do While status.AtEndOfStream <> True
line = status.ReadLine
If InStr(line, "Volume ") Then
cif = cif & Mid(line, 8, 2)
ElseIf InStr(line, "Conversion Status:") Then
cif = cif & Mid(line, 26)
ElseIf InStr(line, "Percentage Encrypted:") Then
cif = cif & "," & Mid(line, 26) & "; "
End If
Loop
'
WScript.Echo cif
WScript.Sleep (20000)