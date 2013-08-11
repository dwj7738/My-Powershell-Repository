# ========================================================
#
#	Title:				Snippet Manager Updater
#	Author:			(C) 2010 by Denniver Reining / www.bitspace.de
#	Version:       1.0.0.0002
#
# ========================================================

#region Hide Console
$script:showWindowAsync = Add-Type –memberDefinition @”
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru
 $null = $showWindowAsync::ShowWindowAsync((Get-Process –id $pid).MainWindowHandle, 2)
#endregion


#region #### VARIABLES #####
$snipmanUPpath= "$env:APPDATA\SnippetManager"
$snipmanUPupdatePath = "$env:APPDATA\SnippetManager\Updates"
if (!( [system.io.directory]::exists($snipmanUPupdatePath))) { md $snipmanUPupdatePath }
$updateURL = "http://www.boxtools.de/snipman/SnippetManager_setup.msi"
$Updatefile = "$env:APPDATA\SnippetManager\Updates\SnippetManager_setup.msi"
$scriptpath = Split-Path -parent $MyInvocation.MyCommand.Definition
$windowico = "$scriptpath\Resources\ico\snippet1.ico"
#endregion

#region ScriptForm Designer

#region Constructor

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

#endregion

#region Post-Constructor Custom Code

#endregion

#region Form Creation
#Warning: It is recommended that changes inside this region be handled using the ScriptForm Designer.
#When working with the ScriptForm designer this region and any changes within may be overwritten.
#~~< form1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$form1 = New-Object System.Windows.Forms.Form
$form1.ClientSize = New-Object System.Drawing.Size(342, 189)
$form1.MaximumSize = New-Object System.Drawing.Size(358, 227)
$form1.MinimumSize = New-Object System.Drawing.Size(358, 227)
$form1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form1.Icon = New-Object System.Drawing.Icon("$windowico")
$form1.Text = "SnippetManager Updater"
#~~< RichTextBox1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RichTextBox1 = New-Object System.Windows.Forms.RichTextBox
$RichTextBox1.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$RichTextBox1.Location = New-Object System.Drawing.Point(14, 15)
$RichTextBox1.ReadOnly = $true
$RichTextBox1.Size = New-Object System.Drawing.Size(315, 99)
$RichTextBox1.Font = New-Object System.Drawing.Font("Segoe UI", 8.0, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
$RichTextBox1.TabIndex = 2
$RichTextBox1.Text = ""
#~~< Button2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Location = New-Object System.Drawing.Point(55, 148)
$Button2.Size = New-Object System.Drawing.Size(90, 23)
$Button2.TabIndex = 1
$Button2.Text = "Retry"
$Button2.UseVisualStyleBackColor = $true
#~~< Button1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Location = New-Object System.Drawing.Point(183, 148)
$Button1.Size = New-Object System.Drawing.Size(90, 23)
$Button1.TabIndex = 0
$Button1.Text = "Cancel"
$Button1.UseVisualStyleBackColor = $true

$form1.Controls.Add($RichTextBox1)
$form1.Controls.Add($Button2)
$form1.Controls.Add($Button1)

#endregion

#region Custom Code
$Button1.add_Click({$form1.close()})
$Button2.add_Click({FNdownloadupdate})
$form1.add_shown({FNdownloadupdate})
$form1.topmost = $true
#endregion

#region Event Loop

function Main{
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form1.ShowDialog()
}

#endregion

#endregion

#region Event Handlers

function FNdownloadupdate {
	$RichTextBox1.text = ""
	$RichTextBox1.SelectionColor = "black"
	$RichTextBox1.selectedtext = "Starting download..."
	$RichTextBox1.selectedtext = "`n (this window may become unresponsive for a little while)"
	$RichTextBox1.SelectionColor = "#855306"
	$RichTextBox1.selectedtext = "`n`r> After the installation you should restart PowerGUI. <"
	$form1.refresh()
	if ( [system.io.file]::exists($Updatefile) ){ Remove-Item "$Updatefile"  } 
	try {
		[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
		$object = New-Object Microsoft.VisualBasic.Devices.Network
		$down = $object.DownloadFile($updateURL, $Updatefile,"","",$true, 40, $true, 'throwexception')
		}
	catch { 
		[void] [Windows.Forms.MessageBox]::Show($error, "SnippetManager Download - Error", [Windows.Forms.MessageBoxButtons]::ok, [Windows.Forms.MessageBoxIcon]::Warning)
		$date = Get-Date
		foreach ($err in $error) {
			Add-Content "$snipmanUPpath\SnippetManagerErrors.log" "$date :$err"
		}
		return
	}
	[void][System.Diagnostics.Process]::Start($Updatefile) 
	$form1.close()
}

Main # This call must remain below all other event functions

#endregion