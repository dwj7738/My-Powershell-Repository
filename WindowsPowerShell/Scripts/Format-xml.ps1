#========================================================================
# Created with: SAPIEN Technologies, Inc., PowerShell Studio 2012 v3.0.3
# Created on:   11-May-12 3:27 PM
# Created by:   David Johnson
# Organization: 
# Filename:     
#========================================================================


function Format-Xml  {
    param($PathXML, $Indent=2, $Destination="$env:temp\out.xml", [switch]$Open)
    $xml = New-Object XML
    $xml.Load($PathXML)
    $StringWriter = New-Object System.IO.StringWriter
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter
    $xmlWriter.Formatting = "indented"
    $xmlWriter.Indentation = $Indent
    $xml.WriteContentTo($XmlWriter)
    $XmlWriter.Flush()
    $StringWriter.Flush()
    Set-Content -Value ($StringWriter.ToString()) -Path $Destination
    if ($Open) { notepad $Destination }
} 
# Examples
# PS> Format-Xml -PathXML C:\Windows\Ultimate.xml -Open -Indent 1
# PS> Format-Xml -PathXML C:\Windows\Ultimate.xml -Open -Indent 5 
#