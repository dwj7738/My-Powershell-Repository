# ========================================================
#
#	Title:				Snippet Manager ShippedSnippets Remover
#	Author:			(C) 2011 by Denniver Reining / www.bitspace.de
#	
# ========================================================


#region Hide Console
$script:showWindowAsync = Add-Type –memberDefinition @”
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru
 $null = $showWindowAsync::ShowWindowAsync((Get-Process –id $pid).MainWindowHandle, 2)
#endregion


$PGinstallpath = Get-Process -Id $PID | Select-Object -ExpandProperty Path | Split-Path -Parent   
if (!($PGinstallpath -match "GUI")){ 
	if (Test-Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\PowerGUI\") {
		$PGinstallpath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\PowerGUI\").ApplicationBase  
	}
	else { $PGinstallpath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\PowerGUI_Pro\").ApplicationBase }
} 
$shippedSnippetsPath = $PGinstallpath+"\snippets" -replace "\\\\","\"

$shipsnipdir = Get-ChildItem $shippedSnippetsPath
foreach ($element in $shipsnipdir) {
	Remove-Item $element.fullname -recurse -force 
}	

