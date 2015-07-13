
# ========================================================
#
#	Title:				Snippet Manager 
#	Author:			(C) 2011 by Denniver Reining / www.bitspace.de
	 $version = 1.01
#	internal: 1.0.0.0010
#  todo : 
# ========================================================

#region Hide Console
$script:showWindowAsync = Add-Type –memberDefinition @”
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru
 $null = $showWindowAsync::ShowWindowAsync((Get-Process –id $pid).MainWindowHandle, 2)
#endregion

#region Variables 

# paths and files
	$snipmanUPpath= "$env:APPDATA\SnippetManager"
	$snipmanSettings = "$snipmanUPpath\settings.xml"
	$PGinstallpath = Get-Process -Id $PID | Select-Object -ExpandProperty Path | Split-Path -Parent   
	if (!($PGinstallpath -match "GUI")){ 
		if (Test-Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\PowerGUI\") {
			$PGinstallpath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\PowerGUI\").ApplicationBase  
		}
		else { $PGinstallpath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellSnapIns\PowerGUI_Pro\").ApplicationBase }
	} 
	$snippetDefaultPath = $([System.Environment]::GetFolderPath('MyDocuments'))+"\WindowsPowerShell\snippets"
	$shippedSnippetsPath = $PGinstallpath+"\snippets" -replace "\\\\","\"
	$lastSnippetDir = $snippetDefaultPath
	$scriptpath = Split-Path -parent $MyInvocation.MyCommand.Definition
	$updateScript = "$scriptpath\Snipman_updater.ps1"
	$Updatefile = "$snipmanUPpath\version.txt" 
	$moverScript ="`"$scriptpath\Snipman_rm.ps1`""
	$snipmanResetSettingsFile = "$scriptpath\reset.txt"
	
# etc
	$windowtitle = "SnippetManager for PowerGUI"
	$updatecheckURL = "http://www.boxtools.de/snipman/version.txt"
	$updateDldUrl = "http://www.powergui.org/entry.jspa?categoryID=389&externalID=3041"
	
# gfx
	$meicopath = "$scriptpath\Resources\ico\"
	$boximg = "$meicopath\box.jpg"
	$windowico = "$meicopath\windowicon.ico"
	$logopath = "$meicopath\logoII_129x72_s.jpg"
	$menuebackpath = "$meicopath\menubar.jpg"	
	$folderico = "$meicopath\folder.ico"
	$folderPGpathico = "$meicopath\folderPGpath.ico"
	$rootico = "$meicopath\root.ico"
	$rootROico = "$meicopath\root-readonly.ico"
	$rootroot = "$meicopath\rootroot.ico"
	$rootNA = "$meicopath\root-NA.ico"
	$rootPGpath = "$meicopath\root-PGuse.ico"
	$snippetico = "$meicopath\snippet.ico"
	$snippetNotActiveico = "$meicopath\snippet-NotActive.ico"
	$foundsnippet = "$meicopath\foundsnippet.ico"
	$searchico = "$meicopath\searchB.ico"
	$searchnoresultsico = "$meicopath\search-nores.ico"
	$conIco0 = "$meicopath\0.ico"
	$conIco1 = "$meicopath\1.ico"
	$conIco2 = "$meicopath\2.ico"
	$conIco3 = "$meicopath\3.ico"
	$conIco4 = "$meicopath\4.ico"
	$conIco5 = "$meicopath\5.ico"
	$conIco6 = "$meicopath\6.ico"
	$conIco7 = "$meicopath\7.ico"
	$conIco8 = "$meicopath\8.ico"
	$conIco9 = "$meicopath\9.ico"
	$conIco10 = "$meicopath\10.ico"
	$Bwhite = "$meicopath\barwhite.jpg"
	$Byellow = "$meicopath\baryellow.jpg"
	$Bred = "$meicopath\barred.jpg"
	$Bgreen= "$meicopath\bargreen.jpg"
	$helpfile = "$scriptpath\SnippetManager Readme_v1.0.1.pdf"
	
# decl. + switches
	$script:cancel = 0 
	$script:changed = 0 
	$script:saved = 0
	$script:firstbuild = 1
	$script:firstbuild1 = 1
	$script:firstbuild2 = 1
	$script:subnodetooltips = 1
	$script:FullTextIndexing = 1

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
#~~< Form1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Form1 = New-Object System.Windows.Forms.Form
$Form1.AutoValidate = [System.Windows.Forms.AutoValidate]::EnablePreventFocusChange
$Form1.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Zoom
$Form1.CausesValidation = $false
$Form1.ClientSize = New-Object System.Drawing.Size(867, 707)
$Form1.Font = New-Object System.Drawing.Font("Segoe UI", 8.25, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
$Form1.MinimumSize = New-Object System.Drawing.Size(700, 500)
$Form1.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Show
$Form1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form1.Text = "$windowtitle"
$Form1.TopMost = $true
$Form1.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))))
#~~< HideLabelRE >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$HideLabelRE = New-Object System.Windows.Forms.Label
$HideLabelRE.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right))
$HideLabelRE.Location = New-Object System.Drawing.Point(855, 57)
$HideLabelRE.Size = New-Object System.Drawing.Size(12, 622)
$HideLabelRE.TabIndex = 105
$HideLabelRE.Text = ""
#~~< HideLabelLI >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$HideLabelLI = New-Object System.Windows.Forms.Label
$HideLabelLI.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left))
$HideLabelLI.Location = New-Object System.Drawing.Point(4, 29)
$HideLabelLI.MinimumSize = New-Object System.Drawing.Size(8, 0)
$HideLabelLI.Size = New-Object System.Drawing.Size(8, 651)
$HideLabelLI.TabIndex = 1
$HideLabelLI.Text = ""
#~~< HideLabelUN >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$HideLabelUN = New-Object System.Windows.Forms.Label
$HideLabelUN.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$HideLabelUN.Location = New-Object System.Drawing.Point(8, 673)
$HideLabelUN.MinimumSize = New-Object System.Drawing.Size(0, 5)
$HideLabelUN.Size = New-Object System.Drawing.Size(850, 5)
$HideLabelUN.TabIndex = 1
$HideLabelUN.Text = ""
#~~< HideLabelOB >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$HideLabelOB = New-Object System.Windows.Forms.Label
$HideLabelOB.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$HideLabelOB.Location = New-Object System.Drawing.Point(191, 33)
$HideLabelOB.Size = New-Object System.Drawing.Size(668, 25)
$HideLabelOB.TabIndex = 99
$HideLabelOB.Text = ""
#~~< ProgressBar1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ProgressBar1 = New-Object System.Windows.Forms.ProgressBar
$ProgressBar1.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right))
$ProgressBar1.Location = New-Object System.Drawing.Point(709, 689)
$ProgressBar1.Maximum = 2000
$ProgressBar1.Size = New-Object System.Drawing.Size(143, 15)
$ProgressBar1.Step = 5
$ProgressBar1.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$ProgressBar1.TabIndex = 99
$ProgressBar1.Text = ""
$ProgressBar1.Visible = $false
#~~< Statusbar >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Statusbar = New-Object System.Windows.Forms.Label
$Statusbar.Dock = [System.Windows.Forms.DockStyle]::Bottom
$Statusbar.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$Statusbar.Location = New-Object System.Drawing.Point(0, 686)
$Statusbar.Size = New-Object System.Drawing.Size(867, 21)
$Statusbar.TabIndex = 4
$Statusbar.Text = ""
$Statusbar.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$Statusbar.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](24)))), ([System.Int32](([System.Byte](24)))), ([System.Int32](([System.Byte](24)))))
#~~< TabControl1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TabControl1 = New-Object System.Windows.Forms.TabControl
$TabControl1.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$TabControl1.Appearance = [System.Windows.Forms.TabAppearance]::FlatButtons
$TabControl1.Location = New-Object System.Drawing.Point(9, 33)
$TabControl1.SelectedIndex = 0
$TabControl1.Size = New-Object System.Drawing.Size(849, 643)
$TabControl1.TabIndex = 5
$TabControl1.TabStop = $false
$TabControl1.Text = ""
#~~< TabPage1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TabPage1 = New-Object System.Windows.Forms.TabPage
$TabPage1.Location = New-Object System.Drawing.Point(4, 26)
$TabPage1.Padding = New-Object System.Windows.Forms.Padding(3)
$TabPage1.Size = New-Object System.Drawing.Size(841, 613)
$TabPage1.TabIndex = 0
$TabPage1.Text = "Snippet Creator"
$TabPage1.BackColor = [System.Drawing.Color]::White
#~~< SplitContainer1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SplitContainer1 = New-Object System.Windows.Forms.SplitContainer
$SplitContainer1.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$SplitContainer1.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$SplitContainer1.Location = New-Object System.Drawing.Point(3, 4)
$SplitContainer1.Panel1.Text = ""
$SplitContainer1.Panel2.Text = ""
$SplitContainer1.Size = New-Object System.Drawing.Size(834, 603)
$SplitContainer1.SplitterDistance = 274
$SplitContainer1.TabIndex = 0
$SplitContainer1.TabStop = $false
$SplitContainer1.Text = ""
#~~< SplitContainer1.Panel1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SplitContainer1.Panel1.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))))
#~~< BNsearchsnippet >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNsearchsnippet = New-Object System.Windows.Forms.Button
$BNsearchsnippet.Location = New-Object System.Drawing.Point(69, 7)
$BNsearchsnippet.Size = New-Object System.Drawing.Size(50, 23)
$BNsearchsnippet.TabIndex = 99
$BNsearchsnippet.Text = "Search"
$BNsearchsnippet.UseVisualStyleBackColor = $true
$BNsearchsnippet.add_Click({FNsearchsnippet($BNsearchsnippet)})
#~~< BNaddlocation >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNaddlocation = New-Object System.Windows.Forms.Button
$BNaddlocation.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right))
$BNaddlocation.Location = New-Object System.Drawing.Point(171, 8)
$BNaddlocation.Size = New-Object System.Drawing.Size(84, 23)
$BNaddlocation.TabIndex = 1
$BNaddlocation.TabStop = $false
$BNaddlocation.Text = "Add Location"
$BNaddlocation.UseVisualStyleBackColor = $true
$BNaddlocation.add_Click({FNaddSnippetLocation($BNaddlocation)})
#~~< TreeView1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TreeView1 = New-Object System.Windows.Forms.TreeView
$TreeView1.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$TreeView1.Font = New-Object System.Drawing.Font("Segoe UI", 8.0)
$TreeView1.HideSelection = $false
$TreeView1.HotTracking = $true
$TreeView1.ImageIndex = 0
$TreeView1.Indent = 14
$TreeView1.ItemHeight = 17
$TreeView1.Location = New-Object System.Drawing.Point(13, 37)
$TreeView1.Margin = New-Object System.Windows.Forms.Padding(10)
$TreeView1.MinimumSize = New-Object System.Drawing.Size(0, 180)
$TreeView1.SelectedImageIndex = 0
$TreeView1.Size = New-Object System.Drawing.Size(241, 551)
$TreeView1.TabIndex = 1
$TreeView1.Text = ""
$TreeView1.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](252)))), ([System.Int32](([System.Byte](252)))), ([System.Int32](([System.Byte](253)))))
#~~< components >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$components = New-Object System.ComponentModel.Container
#~~< TreeViewContextMenu >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TreeViewContextMenu = New-Object System.Windows.Forms.ContextMenuStrip($components)
$TreeViewContextMenu.Size = New-Object System.Drawing.Size(214, 126)
$TreeViewContextMenu.Text = ""
$TreeViewContextMenu.BackColor = [System.Drawing.Color]::White
#~~< TVFileCutToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFileCutToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFileCutToolStripMenuItem.Size = New-Object System.Drawing.Size(213, 22)
$TVFileCutToolStripMenuItem.Text = "Cut"
$TVFileCutToolStripMenuItem.add_Click({FNtreenodeCut($TVFileCutToolStripMenuItem)})
#~~< TVFileCopyToolStripMenuItem2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFileCopyToolStripMenuItem2 = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFileCopyToolStripMenuItem2.Size = New-Object System.Drawing.Size(213, 22)
$TVFileCopyToolStripMenuItem2.Text = "Copy"
$TVFileCopyToolStripMenuItem2.add_Click({FNtreenodeCopy($TVFileCopyToolStripMenuItem2)})
#~~< ToolStripSeparator8 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator8 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator8.Size = New-Object System.Drawing.Size(210, 6)
#~~< TVFileDeleteToolStripMenuItem1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFileDeleteToolStripMenuItem1 = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFileDeleteToolStripMenuItem1.Size = New-Object System.Drawing.Size(213, 22)
$TVFileDeleteToolStripMenuItem1.Text = "Delete"
$TVFileDeleteToolStripMenuItem1.add_Click({FNdelete($TVFileDeleteToolStripMenuItem1)})
#~~< TVFileRenameToolStripMenuItem1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFileRenameToolStripMenuItem1 = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFileRenameToolStripMenuItem1.Size = New-Object System.Drawing.Size(213, 22)
$TVFileRenameToolStripMenuItem1.Text = "Rename"
$TVFileRenameToolStripMenuItem1.add_Click({FNRename($TVFileRenameToolStripMenuItem1)})
#~~< ToolStripSeparator3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator3 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator3.Size = New-Object System.Drawing.Size(210, 6)
#~~< TVFileLocateInWindowsExplorerToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFileLocateInWindowsExplorerToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFileLocateInWindowsExplorerToolStripMenuItem.Size = New-Object System.Drawing.Size(213, 22)
$TVFileLocateInWindowsExplorerToolStripMenuItem.Text = "Show in Windows Explorer"
$TVFileLocateInWindowsExplorerToolStripMenuItem.add_Click({FNlocInExplorer($TVFileLocateInWindowsExplorerToolStripMenuItem)})
$TreeViewContextMenu.Items.AddRange([System.Windows.Forms.ToolStripItem[]](@($TVFileCutToolStripMenuItem, $TVFileCopyToolStripMenuItem2, $ToolStripSeparator8, $TVFileDeleteToolStripMenuItem1, $TVFileRenameToolStripMenuItem1, $ToolStripSeparator3, $TVFileLocateInWindowsExplorerToolStripMenuItem)))
$TreeView1.ContextMenuStrip = $TreeViewContextMenu
$TreeView1.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](14)))), ([System.Int32](([System.Byte](17)))), ([System.Int32](([System.Byte](19)))))
#~~< ImageList1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ImageList1 = New-Object System.Windows.Forms.ImageList($components)
$ImageList1.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit
$ImageList1.ImageSize = New-Object System.Drawing.Size(16, 16)
$ImageList1.TransparentColor = [System.Drawing.Color]::Transparent
$TreeView1.ImageList = $ImageList1
$TreeView1.add_NodeMouseDoubleClick({FNtreedoubleclick($TreeView1)})
$TreeView1.add_PreviewKeyDown({FNkeyshortcutsTreevw($TreeView1)})
$TreeView1.add_MouseDown({FNtree1click($TreeView1)})
#~~< BNbuildtree >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNbuildtree = New-Object System.Windows.Forms.Button
$BNbuildtree.Location = New-Object System.Drawing.Point(13, 7)
$BNbuildtree.Size = New-Object System.Drawing.Size(54, 23)
$BNbuildtree.TabIndex = 0
$BNbuildtree.TabStop = $false
$BNbuildtree.Text = "Refresh"
$BNbuildtree.UseVisualStyleBackColor = $true
$SplitContainer1.Panel1.Controls.Add($BNsearchsnippet)
$SplitContainer1.Panel1.Controls.Add($BNaddlocation)
$SplitContainer1.Panel1.Controls.Add($TreeView1)
$SplitContainer1.Panel1.Controls.Add($BNbuildtree)
#~~< SplitContainer1.Panel2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SplitContainer1.Panel2.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))))
#~~< BNsaveAs >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNsaveAs = New-Object System.Windows.Forms.Button
$BNsaveAs.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right))
$BNsaveAs.Location = New-Object System.Drawing.Point(455, 292)
$BNsaveAs.Size = New-Object System.Drawing.Size(60, 23)
$BNsaveAs.TabIndex = 98
$BNsaveAs.Text = "Save As"
$BNsaveAs.UseVisualStyleBackColor = $true
$BNsaveAs.Cursor = [System.Windows.Forms.Cursors]::Default
#~~< TBclipboard >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TBclipboard = New-Object System.Windows.Forms.TextBox
$TBclipboard.Location = New-Object System.Drawing.Point(15, 151)
$TBclipboard.Size = New-Object System.Drawing.Size(63, 22)
$TBclipboard.TabIndex = 97
$TBclipboard.TabStop = $false
$TBclipboard.Text = ""
$TBclipboard.Visible = $false
#~~< BNsearch >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNsearch = New-Object System.Windows.Forms.Button
$BNsearch.Location = New-Object System.Drawing.Point(114, 292)
$BNsearch.Size = New-Object System.Drawing.Size(50, 23)
$BNsearch.TabIndex = 15
$BNsearch.Text = "Search"
$BNsearch.UseVisualStyleBackColor = $true
#~~< BNnewSnippet >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNnewSnippet = New-Object System.Windows.Forms.Button
$BNnewSnippet.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right))
$BNnewSnippet.Location = New-Object System.Drawing.Point(326, 292)
$BNnewSnippet.Size = New-Object System.Drawing.Size(60, 23)
$BNnewSnippet.TabIndex = 13
$BNnewSnippet.Text = "New"
$BNnewSnippet.UseVisualStyleBackColor = $true
$BNnewSnippet.add_Click({FNnewSnippet($BNnewSnippet)})
#~~< Label5 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label5 = New-Object System.Windows.Forms.Label
$Label5.Location = New-Object System.Drawing.Point(13, 117)
$Label5.Size = New-Object System.Drawing.Size(82, 18)
$Label5.TabIndex = 12
$Label5.Text = "Placeholder:"
$Label5.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$Label5.BackColor = [System.Drawing.Color]::Transparent
#~~< Label4 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label4 = New-Object System.Windows.Forms.Label
$Label4.Location = New-Object System.Drawing.Point(13, 87)
$Label4.Size = New-Object System.Drawing.Size(82, 18)
$Label4.TabIndex = 11
$Label4.Text = "Description:"
$Label4.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$Label4.BackColor = [System.Drawing.Color]::Transparent
#~~< Label3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label3 = New-Object System.Windows.Forms.Label
$Label3.Location = New-Object System.Drawing.Point(13, 57)
$Label3.Size = New-Object System.Drawing.Size(82, 18)
$Label3.TabIndex = 10
$Label3.Text = "Author:"
$Label3.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$Label3.BackColor = [System.Drawing.Color]::Transparent
#~~< Label2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label2 = New-Object System.Windows.Forms.Label
$Label2.Location = New-Object System.Drawing.Point(13, 27)
$Label2.Size = New-Object System.Drawing.Size(82, 18)
$Label2.TabIndex = 9
$Label2.Text = "Snippet Name:"
$Label2.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$Label2.BackColor = [System.Drawing.Color]::Transparent
#~~< BNsave >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNsave = New-Object System.Windows.Forms.Button
$BNsave.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right))
$BNsave.Location = New-Object System.Drawing.Point(391, 292)
$BNsave.Size = New-Object System.Drawing.Size(60, 23)
$BNsave.TabIndex = 5
$BNsave.Text = "Save"
$BNsave.UseVisualStyleBackColor = $true
$BNsave.Cursor = [System.Windows.Forms.Cursors]::Default
#~~< TBsnippetDescription >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TBsnippetDescription = New-Object System.Windows.Forms.TextBox
$TBsnippetDescription.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$TBsnippetDescription.Font = New-Object System.Drawing.Font("Segoe UI", 8.0)
$TBsnippetDescription.ImeMode = [System.Windows.Forms.ImeMode]::Off
$TBsnippetDescription.Location = New-Object System.Drawing.Point(99, 85)
$TBsnippetDescription.Size = New-Object System.Drawing.Size(418, 22)
$TBsnippetDescription.TabIndex = 4
$TBsnippetDescription.Text = ""
$TBsnippetDescription.WordWrap = $false
#~~< TextboxesContextMenu >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextboxesContextMenu = New-Object System.Windows.Forms.ContextMenuStrip($components)
$TextboxesContextMenu.Size = New-Object System.Drawing.Size(61, 4)
$TextboxesContextMenu.Text = ""
$TextboxesContextMenu.BackColor = [System.Drawing.Color]::White
$TBsnippetDescription.ContextMenuStrip = $TextboxesContextMenu
$TBsnippetDescription.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](3)))), ([System.Int32](([System.Byte](50)))), ([System.Int32](([System.Byte](71)))))
$TBsnippetDescription.add_TextChanged({FNtextchanged($TBsnippetDescription)})
#~~< LVplaceholders >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LVplaceholders = New-Object System.Windows.Forms.ListView
$LVplaceholders.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$LVplaceholders.FullRowSelect = $true
$LVplaceholders.Location = New-Object System.Drawing.Point(99, 115)
$LVplaceholders.Size = New-Object System.Drawing.Size(418, 153)
$LVplaceholders.TabIndex = 7
$LVplaceholders.Text = "ListView1"
$LVplaceholders.UseCompatibleStateImageBehavior = $false
$LVplaceholders.View = [System.Windows.Forms.View]::Details
#~~< SpName >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SpName = New-Object System.Windows.Forms.ColumnHeader
$SpName.Text = "Name"
$SpName.Width = 82
#~~< DefaultValue >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$DefaultValue = New-Object System.Windows.Forms.ColumnHeader
$DefaultValue.Text = "Default Value"
$DefaultValue.Width = 90
#~~< Tooltip >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Tooltip = New-Object System.Windows.Forms.ColumnHeader
$Tooltip.Text = "Tooltip"
$Tooltip.Width = 233
$LVplaceholders.Columns.AddRange([System.Windows.Forms.ColumnHeader[]](@($SpName, $DefaultValue, $Tooltip)))
#~~< PlaceholderContextmenu >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PlaceholderContextmenu = New-Object System.Windows.Forms.ContextMenuStrip($components)
$PlaceholderContextmenu.Size = New-Object System.Drawing.Size(268, 76)
$PlaceholderContextmenu.Text = ""
$PlaceholderContextmenu.BackColor = [System.Drawing.Color]::White
#~~< CreateNewToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$CreateNewToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$CreateNewToolStripMenuItem.Size = New-Object System.Drawing.Size(267, 22)
$CreateNewToolStripMenuItem.Text = "Create placeholder manually"
#~~< DeleteToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$DeleteToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$DeleteToolStripMenuItem.Size = New-Object System.Drawing.Size(267, 22)
$DeleteToolStripMenuItem.Text = "Delete placeholder"
$DeleteToolStripMenuItem.add_Click({FNdeletePlaceholder($DeleteToolStripMenuItem)})
#~~< ToolStripSeparator10 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator10 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator10.Size = New-Object System.Drawing.Size(264, 6)
#~~< CopyPlaceholderNamenameToClipboardToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~
$CopyPlaceholderNamenameToClipboardToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$CopyPlaceholderNamenameToClipboardToolStripMenuItem.Size = New-Object System.Drawing.Size(267, 22)
$CopyPlaceholderNamenameToClipboardToolStripMenuItem.Text = "Copy placeholder name to clipboard"
$CopyPlaceholderNamenameToClipboardToolStripMenuItem.add_Click({FNcopyPLHname($CopyPlaceholderNamenameToClipboardToolStripMenuItem)})
$PlaceholderContextmenu.Items.AddRange([System.Windows.Forms.ToolStripItem[]](@($CreateNewToolStripMenuItem, $DeleteToolStripMenuItem, $ToolStripSeparator10, $CopyPlaceholderNamenameToClipboardToolStripMenuItem)))
$LVplaceholders.ContextMenuStrip = $PlaceholderContextmenu
$LVplaceholders.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](3)))), ([System.Int32](([System.Byte](50)))), ([System.Int32](([System.Byte](71)))))
$LVplaceholders.add_MouseDoubleClick({FNeditPLH($LVplaceholders)})
$LVplaceholders.add_PreviewKeyDown({FNkeyshortcutsPLHs($LVplaceholders)})
#~~< TBsnippetAuthor >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TBsnippetAuthor = New-Object System.Windows.Forms.TextBox
$TBsnippetAuthor.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$TBsnippetAuthor.Font = New-Object System.Drawing.Font("Segoe UI", 8.0)
$TBsnippetAuthor.ImeMode = [System.Windows.Forms.ImeMode]::Off
$TBsnippetAuthor.Location = New-Object System.Drawing.Point(99, 55)
$TBsnippetAuthor.Size = New-Object System.Drawing.Size(312, 22)
$TBsnippetAuthor.TabIndex = 3
$TBsnippetAuthor.Text = ""
$TBsnippetAuthor.WordWrap = $false
$TBsnippetAuthor.ContextMenuStrip = $TextboxesContextMenu
$TBsnippetAuthor.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](3)))), ([System.Int32](([System.Byte](50)))), ([System.Int32](([System.Byte](71)))))
$TBsnippetAuthor.add_TextChanged({FNtextchanged($TBsnippetAuthor)})
#~~< TBSnippetTitle >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TBSnippetTitle = New-Object System.Windows.Forms.TextBox
$TBSnippetTitle.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$TBSnippetTitle.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$TBSnippetTitle.ImeMode = [System.Windows.Forms.ImeMode]::Off
$TBSnippetTitle.Location = New-Object System.Drawing.Point(99, 25)
$TBSnippetTitle.Size = New-Object System.Drawing.Size(312, 22)
$TBSnippetTitle.TabIndex = 2
$TBSnippetTitle.Text = ""
$TBSnippetTitle.WordWrap = $false
$TBSnippetTitle.ContextMenuStrip = $TextboxesContextMenu
$TBSnippetTitle.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](3)))), ([System.Int32](([System.Byte](50)))), ([System.Int32](([System.Byte](71)))))
$TBSnippetTitle.add_TextChanged({FNtextchanged($TBSnippetTitle)})
#~~< PictureBox1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PictureBox1 = New-Object System.Windows.Forms.PictureBox
$PictureBox1.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right))
$PictureBox1.Location = New-Object System.Drawing.Point(418, 6)
$PictureBox1.Size = New-Object System.Drawing.Size(129, 72)
$PictureBox1.TabIndex = 3
$PictureBox1.TabStop = $false
$PictureBox1.Text = ""
$PictureBox1.BackColor = [System.Drawing.Color]::Transparent
#~~< RichTextBox1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RichTextBox1 = New-Object System.Windows.Forms.RichTextBox
$RichTextBox1.AcceptsTab = $true
$RichTextBox1.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$RichTextBox1.CausesValidation = $false
$RichTextBox1.DetectUrls = $false
$RichTextBox1.Font = New-Object System.Drawing.Font("Segoe UI", 9.0, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
$RichTextBox1.HideSelection = $false
$RichTextBox1.Location = New-Object System.Drawing.Point(9, 323)
$RichTextBox1.Size = New-Object System.Drawing.Size(507, 264)
$RichTextBox1.TabIndex = 5
$RichTextBox1.Text = ""
$RichTextBox1.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](252)))), ([System.Int32](([System.Byte](252)))), ([System.Int32](([System.Byte](253)))))
#~~< RichTextBoxContextMenu >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RichTextBoxContextMenu = New-Object System.Windows.Forms.ContextMenuStrip($components)
$RichTextBoxContextMenu.Size = New-Object System.Drawing.Size(288, 148)
$RichTextBoxContextMenu.Text = ""
$RichTextBoxContextMenu.BackColor = [System.Drawing.Color]::White
#~~< RTBCopyToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RTBCopyToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$RTBCopyToolStripMenuItem.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$RTBCopyToolStripMenuItem.Size = New-Object System.Drawing.Size(287, 22)
$RTBCopyToolStripMenuItem.Text = "Copy"
$RTBCopyToolStripMenuItem.add_Click({FNcopy($RTBCopyToolStripMenuItem)})
#~~< RTBPasteToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RTBPasteToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$RTBPasteToolStripMenuItem.Font = New-Object System.Drawing.Font("Segoe UI", 8.25, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
$RTBPasteToolStripMenuItem.Size = New-Object System.Drawing.Size(287, 22)
$RTBPasteToolStripMenuItem.Text = "Paste"
$RTBPasteToolStripMenuItem.add_Click({FNpaste($RTBPasteToolStripMenuItem)})
#~~< ToolStripSeparator1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator1 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator1.Size = New-Object System.Drawing.Size(284, 6)
#~~< CreatePlaceholderFromSelectionToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~
$CreatePlaceholderFromSelectionToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$CreatePlaceholderFromSelectionToolStripMenuItem.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$CreatePlaceholderFromSelectionToolStripMenuItem.Size = New-Object System.Drawing.Size(287, 22)
$CreatePlaceholderFromSelectionToolStripMenuItem.Text = "Auto-create placeholder from selection"
$CreatePlaceholderFromSelectionToolStripMenuItem.add_Click({FNautoCreatePlaceholder($CreatePlaceholderFromSelectionToolStripMenuItem)})
#~~< CreatePlaceholderFromSelectionWithNewNameToolStripMenuItem >~~~~~~~~~~~~~~~~
$CreatePlaceholderFromSelectionWithNewNameToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$CreatePlaceholderFromSelectionWithNewNameToolStripMenuItem.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$CreatePlaceholderFromSelectionWithNewNameToolStripMenuItem.Size = New-Object System.Drawing.Size(287, 22)
$CreatePlaceholderFromSelectionWithNewNameToolStripMenuItem.Text = "Create custom placeholder from selection"
$CreatePlaceholderFromSelectionWithNewNameToolStripMenuItem.add_Click({FNhalfautocreatePlaceholder($CreatePlaceholderFromSelectionWithNewNameToolStripMenuItem)})
#~~< ToolStripSeparator11 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator11 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator11.Size = New-Object System.Drawing.Size(284, 6)
#~~< PlaceSelectedMarkerToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PlaceSelectedMarkerToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$PlaceSelectedMarkerToolStripMenuItem.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$PlaceSelectedMarkerToolStripMenuItem.Size = New-Object System.Drawing.Size(287, 22)
$PlaceSelectedMarkerToolStripMenuItem.Text = ""
$PlaceSelectedMarkerToolStripMenuItem.add_Click({FNplaceSelectedMarker($PlaceSelectedMarkerToolStripMenuItem)})
#~~< PlaceEndMarkerToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PlaceEndMarkerToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$PlaceEndMarkerToolStripMenuItem.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$PlaceEndMarkerToolStripMenuItem.Size = New-Object System.Drawing.Size(287, 22)
$PlaceEndMarkerToolStripMenuItem.Text = ""
$PlaceEndMarkerToolStripMenuItem.add_Click({FNPlaceEndMarker($PlaceEndMarkerToolStripMenuItem)})
$RichTextBoxContextMenu.Items.AddRange([System.Windows.Forms.ToolStripItem[]](@($RTBCopyToolStripMenuItem, $RTBPasteToolStripMenuItem, $ToolStripSeparator1, $CreatePlaceholderFromSelectionToolStripMenuItem, $CreatePlaceholderFromSelectionWithNewNameToolStripMenuItem, $ToolStripSeparator11, $PlaceSelectedMarkerToolStripMenuItem, $PlaceEndMarkerToolStripMenuItem)))
$RichTextBox1.ContextMenuStrip = $RichTextBoxContextMenu
$RichTextBox1.add_PreviewKeyDown({FNrtbPreKeyDown($RichTextBox1)})
#~~< LBLzoom >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LBLzoom = New-Object System.Windows.Forms.Label
$LBLzoom.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right))
$LBLzoom.Font = New-Object System.Drawing.Font("Tahoma", 7.25)
$LBLzoom.Location = New-Object System.Drawing.Point(517, 392)
$LBLzoom.Size = New-Object System.Drawing.Size(35, 16)
$LBLzoom.TabIndex = 0
$LBLzoom.Text = "Zoom"
$LBLzoom.BackColor = [System.Drawing.Color]::Transparent
#~~< Zoombar >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Zoombar = New-Object System.Windows.Forms.TrackBar
$Zoombar.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right))
$Zoombar.LargeChange = 1
$Zoombar.Location = New-Object System.Drawing.Point(518, 316)
$Zoombar.Maximum = 15
$Zoombar.Minimum = 7
$Zoombar.Orientation = [System.Windows.Forms.Orientation]::Vertical
$Zoombar.Size = New-Object System.Drawing.Size(45, 80)
$Zoombar.TabIndex = 0
$Zoombar.TabStop = $false
$Zoombar.Text = "TrackBar2"
$Zoombar.Value = 11
$Zoombar.add_ValueChanged({FNresizeFont($Zoombar)})
#~~< BNundo >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNundo = New-Object System.Windows.Forms.Button
$BNundo.Location = New-Object System.Drawing.Point(10, 292)
$BNundo.Size = New-Object System.Drawing.Size(48, 23)
$BNundo.TabIndex = 0
$BNundo.TabStop = $false
$BNundo.Text = "Undo"
$BNundo.UseVisualStyleBackColor = $true
$BNundo.add_Click({FNundo($BNundo)})
#~~< BNredo >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNredo = New-Object System.Windows.Forms.Button
$BNredo.Location = New-Object System.Drawing.Point(62, 292)
$BNredo.Size = New-Object System.Drawing.Size(48, 23)
$BNredo.TabIndex = 0
$BNredo.TabStop = $false
$BNredo.Text = "Redo"
$BNredo.UseVisualStyleBackColor = $true
$BNredo.add_Click({FNredo($BNredo)})
$SplitContainer1.Panel2.Controls.Add($BNsaveAs)
$SplitContainer1.Panel2.Controls.Add($TBclipboard)
$SplitContainer1.Panel2.Controls.Add($BNsearch)
$SplitContainer1.Panel2.Controls.Add($BNnewSnippet)
$SplitContainer1.Panel2.Controls.Add($Label5)
$SplitContainer1.Panel2.Controls.Add($Label4)
$SplitContainer1.Panel2.Controls.Add($Label3)
$SplitContainer1.Panel2.Controls.Add($Label2)
$SplitContainer1.Panel2.Controls.Add($BNsave)
$SplitContainer1.Panel2.Controls.Add($TBsnippetDescription)
$SplitContainer1.Panel2.Controls.Add($LVplaceholders)
$SplitContainer1.Panel2.Controls.Add($TBsnippetAuthor)
$SplitContainer1.Panel2.Controls.Add($TBSnippetTitle)
$SplitContainer1.Panel2.Controls.Add($PictureBox1)
$SplitContainer1.Panel2.Controls.Add($RichTextBox1)
$SplitContainer1.Panel2.Controls.Add($LBLzoom)
$SplitContainer1.Panel2.Controls.Add($Zoombar)
$SplitContainer1.Panel2.Controls.Add($BNundo)
$SplitContainer1.Panel2.Controls.Add($BNredo)
$TabPage1.Controls.Add($SplitContainer1)
#~~< TabPage2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TabPage2 = New-Object System.Windows.Forms.TabPage
$TabPage2.Location = New-Object System.Drawing.Point(4, 26)
$TabPage2.Padding = New-Object System.Windows.Forms.Padding(3)
$TabPage2.Size = New-Object System.Drawing.Size(841, 613)
$TabPage2.TabIndex = 1
$TabPage2.Text = "Store Room"
$TabPage2.BackColor = [System.Drawing.Color]::White
#~~< SplitContainer2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SplitContainer2 = New-Object System.Windows.Forms.SplitContainer
$SplitContainer2.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$SplitContainer2.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$SplitContainer2.Location = New-Object System.Drawing.Point(3, 4)
$SplitContainer2.Panel1.Text = ""
$SplitContainer2.Panel2.Text = ""
$SplitContainer2.Size = New-Object System.Drawing.Size(834, 603)
$SplitContainer2.SplitterDistance = 406
$SplitContainer2.TabIndex = 1
$SplitContainer2.TabStop = $false
$SplitContainer2.Text = ""
#~~< SplitContainer2.Panel1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SplitContainer2.Panel1.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))))
#~~< BNTree2Expandall >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNTree2Expandall = New-Object System.Windows.Forms.Button
$BNTree2Expandall.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right))
$BNTree2Expandall.Location = New-Object System.Drawing.Point(314, 86)
$BNTree2Expandall.Size = New-Object System.Drawing.Size(71, 23)
$BNTree2Expandall.TabIndex = 7
$BNTree2Expandall.TabStop = $false
$BNTree2Expandall.Text = "Expand All"
$BNTree2Expandall.UseVisualStyleBackColor = $true
#~~< BNstoreSelected >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNstoreSelected = New-Object System.Windows.Forms.Button
$BNstoreSelected.Location = New-Object System.Drawing.Point(71, 86)
$BNstoreSelected.Size = New-Object System.Drawing.Size(118, 23)
$BNstoreSelected.TabIndex = 2
$BNstoreSelected.Text = "Deactivate Selected"
$BNstoreSelected.UseVisualStyleBackColor = $true
$BNstoreSelected.add_Click({FNmoveToStorage($BNstoreSelected)})
#~~< Label6 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label6 = New-Object System.Windows.Forms.Label
$Label6.Anchor = [System.Windows.Forms.AnchorStyles]::Top
$Label6.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$Label6.Location = New-Object System.Drawing.Point(146, 17)
$Label6.Size = New-Object System.Drawing.Size(100, 23)
$Label6.TabIndex = 1
$Label6.Text = "Active Snippets"
$Label6.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$Label6.BackColor = [System.Drawing.Color]::White
#~~< StoreTree1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$StoreTree1 = New-Object System.Windows.Forms.TreeView
$StoreTree1.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$StoreTree1.CheckBoxes = $true
$StoreTree1.Font = New-Object System.Drawing.Font("Segoe UI", 8.0)
$StoreTree1.HideSelection = $false
$StoreTree1.HotTracking = $true
$StoreTree1.ImageIndex = 0
$StoreTree1.Indent = 14
$StoreTree1.ItemHeight = 18
$StoreTree1.Location = New-Object System.Drawing.Point(13, 118)
$StoreTree1.Margin = New-Object System.Windows.Forms.Padding(10)
$StoreTree1.MinimumSize = New-Object System.Drawing.Size(0, 180)
$StoreTree1.SelectedImageIndex = 0
$StoreTree1.Size = New-Object System.Drawing.Size(373, 470)
$StoreTree1.TabIndex = 0
$StoreTree1.TabStop = $false
$StoreTree1.Text = ""
$StoreTree1.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](251)))), ([System.Int32](([System.Byte](252)))), ([System.Int32](([System.Byte](255)))))
$StoreTree1.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](14)))), ([System.Int32](([System.Byte](17)))), ([System.Int32](([System.Byte](19)))))
$StoreTree1.ImageList = $ImageList1
#~~< BNstoreTree1refresh >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNstoreTree1refresh = New-Object System.Windows.Forms.Button
$BNstoreTree1refresh.Location = New-Object System.Drawing.Point(13, 86)
$BNstoreTree1refresh.Size = New-Object System.Drawing.Size(54, 23)
$BNstoreTree1refresh.TabIndex = 0
$BNstoreTree1refresh.TabStop = $false
$BNstoreTree1refresh.Text = "Refresh"
$BNstoreTree1refresh.UseVisualStyleBackColor = $true
$SplitContainer2.Panel1.Controls.Add($BNTree2Expandall)
$SplitContainer2.Panel1.Controls.Add($BNstoreSelected)
$SplitContainer2.Panel1.Controls.Add($Label6)
$SplitContainer2.Panel1.Controls.Add($StoreTree1)
$SplitContainer2.Panel1.Controls.Add($BNstoreTree1refresh)
#~~< SplitContainer2.Panel2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SplitContainer2.Panel2.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))))
#~~< BNTree3Expandall >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNTree3Expandall = New-Object System.Windows.Forms.Button
$BNTree3Expandall.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right))
$BNTree3Expandall.Location = New-Object System.Drawing.Point(332, 86)
$BNTree3Expandall.Size = New-Object System.Drawing.Size(71, 23)
$BNTree3Expandall.TabIndex = 6
$BNTree3Expandall.TabStop = $false
$BNTree3Expandall.Text = "Expand All"
$BNTree3Expandall.UseVisualStyleBackColor = $true
#~~< BNactivateSelected >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNactivateSelected = New-Object System.Windows.Forms.Button
$BNactivateSelected.Location = New-Object System.Drawing.Point(78, 86)
$BNactivateSelected.Size = New-Object System.Drawing.Size(102, 23)
$BNactivateSelected.TabIndex = 3
$BNactivateSelected.Text = "Activate Selected"
$BNactivateSelected.UseVisualStyleBackColor = $true
$BNactivateSelected.add_Click({FNmoveToActive($BNactivateSelected)})
#~~< Label7 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label7 = New-Object System.Windows.Forms.Label
$Label7.Anchor = [System.Windows.Forms.AnchorStyles]::Top
$Label7.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$Label7.Location = New-Object System.Drawing.Point(146, 17)
$Label7.Size = New-Object System.Drawing.Size(125, 23)
$Label7.TabIndex = 5
$Label7.Text = "Deactivated Snippets"
$Label7.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$Label7.BackColor = [System.Drawing.Color]::White
$Label7.ForeColor = [System.Drawing.SystemColors]::ControlText
#~~< BNstoreTree2refresh >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNstoreTree2refresh = New-Object System.Windows.Forms.Button
$BNstoreTree2refresh.Location = New-Object System.Drawing.Point(19, 86)
$BNstoreTree2refresh.Size = New-Object System.Drawing.Size(54, 23)
$BNstoreTree2refresh.TabIndex = 1
$BNstoreTree2refresh.TabStop = $false
$BNstoreTree2refresh.Text = "Refresh"
$BNstoreTree2refresh.UseVisualStyleBackColor = $true
#~~< StoreTree2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$StoreTree2 = New-Object System.Windows.Forms.TreeView
$StoreTree2.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$StoreTree2.CheckBoxes = $true
$StoreTree2.Font = New-Object System.Drawing.Font("Segoe UI", 8.0)
$StoreTree2.HideSelection = $false
$StoreTree2.HotTracking = $true
$StoreTree2.ImageIndex = 0
$StoreTree2.Indent = 14
$StoreTree2.ItemHeight = 18
$StoreTree2.Location = New-Object System.Drawing.Point(20, 118)
$StoreTree2.Margin = New-Object System.Windows.Forms.Padding(10)
$StoreTree2.MinimumSize = New-Object System.Drawing.Size(0, 180)
$StoreTree2.SelectedImageIndex = 0
$StoreTree2.Size = New-Object System.Drawing.Size(385, 470)
$StoreTree2.TabIndex = 4
$StoreTree2.TabStop = $false
$StoreTree2.Text = ""
$StoreTree2.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](251)))), ([System.Int32](([System.Byte](252)))), ([System.Int32](([System.Byte](255)))))
$StoreTree2.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](14)))), ([System.Int32](([System.Byte](17)))), ([System.Int32](([System.Byte](19)))))
$StoreTree2.ImageList = $ImageList1
#~~< PictureBox2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PictureBox2 = New-Object System.Windows.Forms.PictureBox
$PictureBox2.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right))
$PictureBox2.Location = New-Object System.Drawing.Point(286, 6)
$PictureBox2.Size = New-Object System.Drawing.Size(129, 72)
$PictureBox2.TabIndex = 3
$PictureBox2.TabStop = $false
$PictureBox2.Text = ""
$SplitContainer2.Panel2.Controls.Add($BNTree3Expandall)
$SplitContainer2.Panel2.Controls.Add($BNactivateSelected)
$SplitContainer2.Panel2.Controls.Add($Label7)
$SplitContainer2.Panel2.Controls.Add($BNstoreTree2refresh)
$SplitContainer2.Panel2.Controls.Add($StoreTree2)
$SplitContainer2.Panel2.Controls.Add($PictureBox2)
$SplitContainer2.add_VisibleChanged({FNstorageRefresh($SplitContainer2)})
$TabPage2.Controls.Add($SplitContainer2)
$TabControl1.Controls.Add($TabPage1)
$TabControl1.Controls.Add($TabPage2)
$TabControl1.ImageList = $ImageList1
$TabControl1.add_Click({FNtabSwitch($TabControl1)})
#~~< MenuStrip1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$MenuStrip1 = New-Object System.Windows.Forms.MenuStrip
$MenuStrip1.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch
$MenuStrip1.GripStyle = [System.Windows.Forms.ToolStripGripStyle]::Visible
$MenuStrip1.Location = New-Object System.Drawing.Point(0, 0)
$MenuStrip1.Size = New-Object System.Drawing.Size(867, 24)
$MenuStrip1.TabIndex = 0
$MenuStrip1.Text = "MenuStrip1"
$MenuStrip1.BackColor = [System.Drawing.Color]::LightGray
#~~< AdvancedToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$AdvancedToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$AdvancedToolStripMenuItem.Size = New-Object System.Drawing.Size(61, 20)
$AdvancedToolStripMenuItem.Text = "Options"
$AdvancedToolStripMenuItem.BackColor = [System.Drawing.Color]::LightGray
#~~< TooltipToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TooltipToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$TooltipToolStripMenuItem.Size = New-Object System.Drawing.Size(270, 22)
$TooltipToolStripMenuItem.Text = "Tooltips"
#~~< ToolTipsInMainExplorer >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolTipsInMainExplorer = New-Object System.Windows.Forms.ToolStripMenuItem
$ToolTipsInMainExplorer.Checked = $true
$ToolTipsInMainExplorer.CheckOnClick = $true
$ToolTipsInMainExplorer.CheckState = [System.Windows.Forms.CheckState]::Checked
$ToolTipsInMainExplorer.Size = New-Object System.Drawing.Size(403, 22)
$ToolTipsInMainExplorer.Text = "Show Snippet Description as Tooltip in Main Snippet Explorer"
$ToolTipsInMainExplorer.add_Click({FNshowNodeToolTips($ToolTipsInMainExplorer)})
#~~< ToolTipsInStorageExplorer >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolTipsInStorageExplorer = New-Object System.Windows.Forms.ToolStripMenuItem
$ToolTipsInStorageExplorer.Checked = $true
$ToolTipsInStorageExplorer.CheckOnClick = $true
$ToolTipsInStorageExplorer.CheckState = [System.Windows.Forms.CheckState]::Checked
$ToolTipsInStorageExplorer.Size = New-Object System.Drawing.Size(403, 22)
$ToolTipsInStorageExplorer.Text = "Show Snippet Code as Tooltip in Store Room Snippets Explorer"
$ToolTipsInStorageExplorer.add_Click({FNshowNodeCODEToolTips($ToolTipsInStorageExplorer)})
$TooltipToolStripMenuItem.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]](@($ToolTipsInMainExplorer, $ToolTipsInStorageExplorer)))
#~~< SaveWindowsizeOnExitToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SaveWindowsizeOnExitToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$SaveWindowsizeOnExitToolStripMenuItem.CheckOnClick = $true
$SaveWindowsizeOnExitToolStripMenuItem.Size = New-Object System.Drawing.Size(270, 22)
$SaveWindowsizeOnExitToolStripMenuItem.Text = "Remember Window size and location"
#~~< CheckForUpdatesOnStartToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$CheckForUpdatesOnStartToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$CheckForUpdatesOnStartToolStripMenuItem.Checked = $true
$CheckForUpdatesOnStartToolStripMenuItem.CheckOnClick = $true
$CheckForUpdatesOnStartToolStripMenuItem.CheckState = [System.Windows.Forms.CheckState]::Checked
$CheckForUpdatesOnStartToolStripMenuItem.Size = New-Object System.Drawing.Size(270, 22)
$CheckForUpdatesOnStartToolStripMenuItem.Text = "Check for Updates on startup"
$CheckForUpdatesOnStartToolStripMenuItem.add_Click({FNSetcheckUpdOnStart($CheckForUpdatesOnStartToolStripMenuItem)})
#~~< ToolStripSeparator18 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator18 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator18.Size = New-Object System.Drawing.Size(267, 6)
#~~< AutoAuthorToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$AutoAuthorToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$AutoAuthorToolStripMenuItem.Size = New-Object System.Drawing.Size(270, 22)
$AutoAuthorToolStripMenuItem.Text = "Auto Author"
#~~< PutInStandardTextAsAuthorToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PutInStandardTextAsAuthorToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$PutInStandardTextAsAuthorToolStripMenuItem.CheckOnClick = $true
$PutInStandardTextAsAuthorToolStripMenuItem.Size = New-Object System.Drawing.Size(248, 22)
$PutInStandardTextAsAuthorToolStripMenuItem.Text = "Use standard text for Author field"
$PutInStandardTextAsAuthorToolStripMenuItem.add_Click({FNautoAuthor($PutInStandardTextAsAuthorToolStripMenuItem)})
#~~< SetStandardTextForAuthorFieldToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SetStandardTextForAuthorFieldToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$SetStandardTextForAuthorFieldToolStripMenuItem.Size = New-Object System.Drawing.Size(248, 22)
$SetStandardTextForAuthorFieldToolStripMenuItem.Text = "Set standard text for Author field"
$SetStandardTextForAuthorFieldToolStripMenuItem.add_Click({FNsetStandardAuthor($SetStandardTextForAuthorFieldToolStripMenuItem)})
$AutoAuthorToolStripMenuItem.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]](@($PutInStandardTextAsAuthorToolStripMenuItem, $SetStandardTextForAuthorFieldToolStripMenuItem)))
#~~< AddNetworkLocationToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$AddNetworkLocationToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$AddNetworkLocationToolStripMenuItem.Size = New-Object System.Drawing.Size(270, 22)
$AddNetworkLocationToolStripMenuItem.Text = "Add network Location manually"
$AdvancedToolStripMenuItem.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]](@($TooltipToolStripMenuItem, $SaveWindowsizeOnExitToolStripMenuItem, $CheckForUpdatesOnStartToolStripMenuItem, $ToolStripSeparator18, $AutoAuthorToolStripMenuItem, $AddNetworkLocationToolStripMenuItem)))
$AdvancedToolStripMenuItem.ForeColor = [System.Drawing.Color]::Black
#~~< HelpToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$HelpToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$HelpToolStripMenuItem.Size = New-Object System.Drawing.Size(44, 20)
$HelpToolStripMenuItem.Text = "Help"
#~~< HelpFileToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$HelpFileToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$HelpFileToolStripMenuItem.Size = New-Object System.Drawing.Size(346, 22)
$HelpFileToolStripMenuItem.Text = "Show Help"
$HelpFileToolStripMenuItem.add_Click({FNshowHelpWin($HelpFileToolStripMenuItem)})
#~~< VideoTutorialwebToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$VideoTutorialwebToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$VideoTutorialwebToolStripMenuItem.Size = New-Object System.Drawing.Size(346, 22)
$VideoTutorialwebToolStripMenuItem.Text = "Video Tutorial (web)"
#~~< ToolStripSeparator12 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator12 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator12.Size = New-Object System.Drawing.Size(343, 6)
#~~< BytecookiewebToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BytecookiewebToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$BytecookiewebToolStripMenuItem.Size = New-Object System.Drawing.Size(346, 22)
$BytecookiewebToolStripMenuItem.Text = "Bytecookie (web)"
#~~< PowerGUIForumToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PowerGUIForumToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$PowerGUIForumToolStripMenuItem.Size = New-Object System.Drawing.Size(346, 22)
$PowerGUIForumToolStripMenuItem.Text = "PowerGUI Forum (web)"
#~~< ToolStripSeparator13 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator13 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator13.Size = New-Object System.Drawing.Size(343, 6)
#~~< ContactMeToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ContactMeToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$ContactMeToolStripMenuItem.Size = New-Object System.Drawing.Size(346, 22)
$ContactMeToolStripMenuItem.Text = "Contact Developer (about a problem or suggestion)"
#~~< CheckForUpdatesToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$CheckForUpdatesToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$CheckForUpdatesToolStripMenuItem.Size = New-Object System.Drawing.Size(346, 22)
$CheckForUpdatesToolStripMenuItem.Text = "Check for Updates..."
#~~< ToolStripSeparator19 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator19 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator19.Size = New-Object System.Drawing.Size(343, 6)
#~~< ResetallSettingstoDefaultValuesToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~
$ResetallSettingstoDefaultValuesToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$ResetallSettingstoDefaultValuesToolStripMenuItem.Size = New-Object System.Drawing.Size(346, 22)
$ResetallSettingstoDefaultValuesToolStripMenuItem.Text = "Reset all Settings to Default Values"
#~~< ToolStripSeparator14 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator14 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator14.Size = New-Object System.Drawing.Size(343, 6)
#~~< AboutToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$AboutToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$AboutToolStripMenuItem.Size = New-Object System.Drawing.Size(346, 22)
$AboutToolStripMenuItem.Text = "About"
$AboutToolStripMenuItem.add_Click({FNshowAbout($AboutToolStripMenuItem)})
$HelpToolStripMenuItem.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]](@($HelpFileToolStripMenuItem, $VideoTutorialwebToolStripMenuItem, $ToolStripSeparator12, $BytecookiewebToolStripMenuItem, $PowerGUIForumToolStripMenuItem, $ToolStripSeparator13, $ContactMeToolStripMenuItem, $CheckForUpdatesToolStripMenuItem, $ToolStripSeparator19, $ResetallSettingstoDefaultValuesToolStripMenuItem, $ToolStripSeparator14, $AboutToolStripMenuItem)))
$HelpToolStripMenuItem.ForeColor = [System.Drawing.Color]::Black
$MenuStrip1.Items.AddRange([System.Windows.Forms.ToolStripItem[]](@($AdvancedToolStripMenuItem, $HelpToolStripMenuItem)))
#~~< Label1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label1 = New-Object System.Windows.Forms.Label
$Label1.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$Label1.FlatStyle = [System.Windows.Forms.FlatStyle]::Popup
$Label1.Location = New-Object System.Drawing.Point(-5, 0)
$Label1.Size = New-Object System.Drawing.Size(877, 25)
$Label1.TabIndex = 2
$Label1.Text = "Label1"
$Label1.BackColor = [System.Drawing.Color]::Black
$Label1.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](50)))), ([System.Int32](([System.Byte](50)))), ([System.Int32](([System.Byte](50)))))
#~~< Label8 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label8 = New-Object System.Windows.Forms.Label
$Label8.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$Label8.FlatStyle = [System.Windows.Forms.FlatStyle]::Popup
$Label8.Location = New-Object System.Drawing.Point(-5, 685)
$Label8.Size = New-Object System.Drawing.Size(877, 25)
$Label8.TabIndex = 102
$Label8.Text = "Label8"
$Label8.BackColor = [System.Drawing.Color]::DimGray
$Label8.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](50)))), ([System.Int32](([System.Byte](50)))), ([System.Int32](([System.Byte](50)))))
$Form1.Controls.Add($HideLabelRE)
$Form1.Controls.Add($HideLabelLI)
$Form1.Controls.Add($HideLabelUN)
$Form1.Controls.Add($HideLabelOB)
$Form1.Controls.Add($ProgressBar1)
$Form1.Controls.Add($Statusbar)
$Form1.Controls.Add($TabControl1)
$Form1.Controls.Add($MenuStrip1)
$Form1.Controls.Add($Label1)
$Form1.Controls.Add($Label8)
$Form1.add_Load({FNonFormLoad($Form1)})
#~~< RootContextMenu >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RootContextMenu = New-Object System.Windows.Forms.ContextMenuStrip($components)
$RootContextMenu.Size = New-Object System.Drawing.Size(214, 104)
$RootContextMenu.Text = ""
$RootContextMenu.BackColor = [System.Drawing.Color]::White
#~~< RootContextMenuNewFolder >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RootContextMenuNewFolder = New-Object System.Windows.Forms.ToolStripMenuItem
$RootContextMenuNewFolder.Size = New-Object System.Drawing.Size(213, 22)
$RootContextMenuNewFolder.Text = "New Folder"
$RootContextMenuNewFolder.add_Click({FNnewFolder($RootContextMenuNewFolder)})
#~~< RootContextMenuPaste >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RootContextMenuPaste = New-Object System.Windows.Forms.ToolStripMenuItem
$RootContextMenuPaste.Size = New-Object System.Drawing.Size(213, 22)
$RootContextMenuPaste.Text = "Paste"
$RootContextMenuPaste.add_Click({FNtreenodePaste($RootContextMenuPaste)})
#~~< ToolStripSeparator17 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator17 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator17.Size = New-Object System.Drawing.Size(210, 6)
#~~< RootContextMenuLocateInExplorer >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RootContextMenuLocateInExplorer = New-Object System.Windows.Forms.ToolStripMenuItem
$RootContextMenuLocateInExplorer.Size = New-Object System.Drawing.Size(213, 22)
$RootContextMenuLocateInExplorer.Text = "Show in Windows Explorer"
$RootContextMenuLocateInExplorer.add_Click({FNlocInExplorer($RootContextMenuLocateInExplorer)})
#~~< ToolStripSeparator15 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator15 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator15.Size = New-Object System.Drawing.Size(210, 6)
#~~< RootContextMenuRemoveSnippetLOcation >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RootContextMenuRemoveSnippetLOcation = New-Object System.Windows.Forms.ToolStripMenuItem
$RootContextMenuRemoveSnippetLOcation.Size = New-Object System.Drawing.Size(213, 22)
$RootContextMenuRemoveSnippetLOcation.Text = "Remove Snippet Location"
$RootContextMenuRemoveSnippetLOcation.add_Click({FNremoveSnippetLocation($RootContextMenuRemoveSnippetLOcation)})
$RootContextMenu.Items.AddRange([System.Windows.Forms.ToolStripItem[]](@($RootContextMenuNewFolder, $RootContextMenuPaste, $ToolStripSeparator17, $RootContextMenuLocateInExplorer, $ToolStripSeparator15, $RootContextMenuRemoveSnippetLOcation)))
#~~< SaveFileDialog1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SaveFileDialog1 = New-Object System.Windows.Forms.SaveFileDialog
$SaveFileDialog1.DefaultExt = "snippet"
$SaveFileDialog1.Filter = "Snippets|*.snippet|Alle Dateien|*.*"
$SaveFileDialog1.InitialDirectory = "$snippetDefaultPath"
#~~< FolderContextMenu >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$FolderContextMenu = New-Object System.Windows.Forms.ContextMenuStrip($components)
$FolderContextMenu.Size = New-Object System.Drawing.Size(214, 176)
$FolderContextMenu.Text = ""
$FolderContextMenu.BackColor = [System.Drawing.Color]::White
#~~< NewFolderToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$NewFolderToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$NewFolderToolStripMenuItem.Size = New-Object System.Drawing.Size(213, 22)
$NewFolderToolStripMenuItem.Text = "New Folder"
$NewFolderToolStripMenuItem.add_Click({FNnewFolder($NewFolderToolStripMenuItem)})
#~~< ToolStripSeparator6 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator6 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator6.Size = New-Object System.Drawing.Size(210, 6)
#~~< TVFolderCutToolStripMenuItem1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFolderCutToolStripMenuItem1 = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFolderCutToolStripMenuItem1.Size = New-Object System.Drawing.Size(213, 22)
$TVFolderCutToolStripMenuItem1.Text = "Cut"
$TVFolderCutToolStripMenuItem1.add_Click({FNtreenodeCut($TVFolderCutToolStripMenuItem1)})
#~~< TVFolderTVFileCopyToolStripMenuItem1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFolderTVFileCopyToolStripMenuItem1 = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFolderTVFileCopyToolStripMenuItem1.Size = New-Object System.Drawing.Size(213, 22)
$TVFolderTVFileCopyToolStripMenuItem1.Text = "Copy"
$TVFolderTVFileCopyToolStripMenuItem1.add_Click({FNtreenodeCopy($TVFolderTVFileCopyToolStripMenuItem1)})
#~~< TVFolderPasteToolStripMenuItem1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFolderPasteToolStripMenuItem1 = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFolderPasteToolStripMenuItem1.Size = New-Object System.Drawing.Size(213, 22)
$TVFolderPasteToolStripMenuItem1.Text = "Paste"
$TVFolderPasteToolStripMenuItem1.add_Click({FNtreenodePaste($TVFolderPasteToolStripMenuItem1)})
#~~< ToolStripSeparator5 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator5 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator5.Size = New-Object System.Drawing.Size(210, 6)
#~~< TVFolderDeleteToolStripMenuItem2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFolderDeleteToolStripMenuItem2 = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFolderDeleteToolStripMenuItem2.Size = New-Object System.Drawing.Size(213, 22)
$TVFolderDeleteToolStripMenuItem2.Text = "Delete"
$TVFolderDeleteToolStripMenuItem2.add_Click({FNdelete($TVFolderDeleteToolStripMenuItem2)})
#~~< TVFolderRenameToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFolderRenameToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFolderRenameToolStripMenuItem.Size = New-Object System.Drawing.Size(213, 22)
$TVFolderRenameToolStripMenuItem.Text = "Rename"
$TVFolderRenameToolStripMenuItem.add_Click({FNRename($TVFolderRenameToolStripMenuItem)})
#~~< ToolStripSeparator7 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolStripSeparator7 = New-Object System.Windows.Forms.ToolStripSeparator
$ToolStripSeparator7.Size = New-Object System.Drawing.Size(210, 6)
#~~< TVFolderShowInWindowsExplorerToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TVFolderShowInWindowsExplorerToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$TVFolderShowInWindowsExplorerToolStripMenuItem.Size = New-Object System.Drawing.Size(213, 22)
$TVFolderShowInWindowsExplorerToolStripMenuItem.Text = "Show in Windows Explorer"
$TVFolderShowInWindowsExplorerToolStripMenuItem.add_Click({FNlocInExplorer($TVFolderShowInWindowsExplorerToolStripMenuItem)})
$FolderContextMenu.Items.AddRange([System.Windows.Forms.ToolStripItem[]](@($NewFolderToolStripMenuItem, $ToolStripSeparator6, $TVFolderCutToolStripMenuItem1, $TVFolderTVFileCopyToolStripMenuItem1, $TVFolderPasteToolStripMenuItem1, $ToolStripSeparator5, $TVFolderDeleteToolStripMenuItem2, $TVFolderRenameToolStripMenuItem, $ToolStripSeparator7, $TVFolderShowInWindowsExplorerToolStripMenuItem)))

#endregion

#region Custom Code

#endregion
##################################################################################################################################################################################################
##################################################################################################################################################################################################
#region Custom Code 
##################################################################################################################################################################################################
##################################################################################################################################################################################################
#region ----Form manual addandums----
$statusbarBaseColor = "#F6F6F6"
$Statusbar.BackColor = $statusbarBaseColor

$Form1.Icon = New-Object System.Drawing.Icon("$windowico")
$form1.add_closing({FNFormclose })
$form1.add_shown({ FnFormshown })
$TV_AfterCheck = { 
	if ($_.Node.Checked)	{ FNstoreNodechecked $_.Node true }
	else	{ FNstoreNodechecked $_.Node false	}
}
$StoreTree1.add_AfterCheck($TV_AfterCheck)
$StoreTree2.add_AfterCheck($TV_AfterCheck)
$BNbuildtree.add_Click({FNbuildtree 1})
$BNstoreTree1refresh.add_Click({FNbuildtree 2})
$BNstoreTree2refresh.add_Click({FNbuildtree 3})
$picturebox1.image = [System.Drawing.Image]::Fromfile("$logopath")  
$picturebox2.image = [System.Drawing.Image]::Fromfile("$logopath") 
$MenuStrip1.BackgroundImage = [System.Drawing.Image]::Fromfile("$menuebackpath")
$Bwhite =  [System.Drawing.Image]::Fromfile("$Bwhite")
$Byellow =  [System.Drawing.Image]::Fromfile("$Byellow")
$Bred =  [System.Drawing.Image]::Fromfile("$Bred")
$Bgreen= [System.Drawing.Image]::Fromfile("$Bgreen")
$Statusbar.BackgroundImage = $Bwhite
$statusbarForeColorStandard = "#061B27"
$Statusbar.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Stretch

$PictureBox1.add_doubleClick({FNshowAbout})
$PictureBox2.add_doubleClick({FNshowAbout})
$lvplaceholders.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$PlaceSelectedMarkerToolStripMenuItem.Text = 'Place $Selected$ marker'
$PlaceEndMarkerToolStripMenuItem.Text = 'Place $End$ marker'
$LVplaceholders.add_MouseClick({FNHighlightPLHS($LVplaceholders)})
$BNsearch.add_Click({FNsearch($BNsearch)})
$BNTree3Expandall.add_Click({FNTreeExpandall 2})
$BNTree2Expandall.add_Click({FNTreeExpandall 1})
$CreateNewToolStripMenuItem.add_Click({FNmanualPlaceholder($CreateNewToolStripMenuItem)})
$PowerGUIForumToolStripMenuItem.add_Click({FNloadURL("http://www.powergui.org/forum.jspa?forumID=118")})
$VideoTutorialwebToolStripMenuItem.add_Click({FNloadURL("http://bytecookie.wordpress.com/2010/11/25/snipvidtut/")})
$BytecookiewebToolStripMenuItem.add_Click({FNloadURL("http://bytecookie.wordpress.com")})
$ContactMeToolStripMenuItem.add_Click({FNmailto})
$CheckForUpdatesToolStripMenuItem.add_Click({FNcheckForUpdates 1})
$ToolTipsInMainExplorer.Checked = $true
$AddNetworkLocationToolStripMenuItem.add_Click({FNaddSnippetLocation NetManual})
$ResetallSettingstoDefaultValuesToolStripMenuItem.add_Click({FNresetsettings 1})

$image1 = [System.Drawing.Image]::FromFile("$folderico")
$image2 = [System.Drawing.Image]::FromFile("$snippetico")
$image3 = [System.Drawing.Image]::FromFile("$snippetNotActiveico")
$image4 = [System.Drawing.Image]::FromFile("$rootico")
$image5 = [System.Drawing.Image]::FromFile("$rootNA")
$image6 = [System.Drawing.Image]::FromFile("$searchico")
$image7 = [System.Drawing.Image]::FromFile("$foundsnippet")
$image8 = [System.Drawing.Image]::FromFile("$searchnoresultsico")
$image9 = [System.Drawing.Image]::FromFile("$rootROico")
$image10 = [System.Drawing.Image]::FromFile("$rootroot")
$image11 = [System.Drawing.Image]::FromFile("$rootPGpath")
$image12 = [System.Drawing.Image]::FromFile("$folderPGpathico")
$ImageList1.Images.Add("folder",$image2)
$ImageList1.Images.Add("file",$image1)
$ImageList1.Images.Add("folderb",$image3)
$ImageList1.Images.Add("root",$image4)
$ImageList1.Images.Add("rootNA",$image5)
$ImageList1.Images.Add("search",$image6)
$ImageList1.Images.Add("search",$image7)
$ImageList1.Images.Add("search-noresult",$image8)
$ImageList1.Images.Add("root-readonly",$image9)
$ImageList1.Images.Add("root-root",$image10)
$ImageList1.Images.Add("rootPGuse",$image11)
$ImageList1.Images.Add("folderPGuse",$image12)
$RichTextBox1.SelectionTabs = (10,20,30,40,50,60,70,80,90,100) 
$RichTextBox1.add_TextChanged({FNtextchanged($RichTextBox1)})
$RichTextBox1.autowordselection = $false
$treeview1.ShowNodeToolTips = $true
#$StoreTree1.ShowNodeToolTips = $true
#$StoreTree2.ShowNodeToolTips = $true
$TVFileCutToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco2")  
$TVFolderCutToolStripMenuItem1.image =  [System.Drawing.Image]::Fromfile("$conIco2")  
$TVFileCopyToolStripMenuItem2.image =  [System.Drawing.Image]::Fromfile("$conIco3")  
$CopyPlaceholderNamenameToClipboardToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco3")  
$RTBCopyToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco3")  
$TVFolderTVFileCopyToolStripMenuItem1.image =  [System.Drawing.Image]::Fromfile("$conIco3")
$TVFolderPasteToolStripMenuItem1.image =  [System.Drawing.Image]::Fromfile("$conIco4")  
$RTBPasteToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco4")  
$TVFileDeleteToolStripMenuItem1.image =  [System.Drawing.Image]::Fromfile("$conIco5")  
$TVFolderDeleteToolStripMenuItem2.image =  [System.Drawing.Image]::Fromfile("$conIco5")  
$DeleteToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco5")   #delete PLH
$TVFileRenameToolStripMenuItem1.image =  [System.Drawing.Image]::Fromfile("$conIco6")  
$TVFolderRenameToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco6")  
$TVFileLocateInWindowsExplorerToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco0")  
$TVFolderShowInWindowsExplorerToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco0")  
$CreateNewToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco7")   #manual PLH
$CreatePlaceholderFromSelectionToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco8")  
$NewFolderToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco1")  
$PlaceSelectedMarkerToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco9")  
$PlaceEndMarkerToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco9")  
$CreatePlaceholderFromSelectionWithNewNameToolStripMenuItem.image =  [System.Drawing.Image]::Fromfile("$conIco10")  
$RootContextMenuNewFolder.image =  [System.Drawing.Image]::Fromfile("$conIco1")
$RootContextMenuPaste.image =  [System.Drawing.Image]::Fromfile("$conIco4")
$RootContextMenuLocateInExplorer.image =  [System.Drawing.Image]::Fromfile("$conIco0")
$RootContextMenuRemoveSnippetLOcation.image =  [System.Drawing.Image]::Fromfile("$conIco5")
$RootContextMenuNewFolder.ToolTipText = ""
$RootContextMenuPaste.ToolTipText = "(Ctrl+V)"
$RootContextMenuLocateInExplorer.ToolTipText = ""
$RootContextMenuRemoveSnippetLOcation.ToolTipText = "Removes this folder and all its subfolders from the snippet explorer. (They will not be deleted.)"
$BNsaveAs.add_Click({FNSaveSnippet("2")})
$BNsave.add_Click({FNSaveSnippet("1")})
$SaveFileDialog1.RestoreDirectory = $true
$savefiledialog1.overwritePrompt = $false
$SaveFileDialog1.ShowHelp = $true
$TVFileCutToolStripMenuItem.ToolTipText = "(Ctrl+X)"
$TVFileCopyToolStripMenuItem2.ToolTipText = "(Ctrl+C)"
$TVFileDeleteToolStripMenuItem1.ToolTipText = "(Del)"
$TVFileRenameToolStripMenuItem1.ToolTipText = "(Ctrl+R) This renames only the filename of the snippet. The filename does not appear in the Script Editors snippet menu."
$CreateNewToolStripMenuItem.ToolTipText = "(Ctrl+N) Creates a new placeholder. You have to manually add `$<placeholders name>`$ to all instances in the snippet."
$DeleteToolStripMenuItem.ToolTipText = "(Del) Removes the selected placeholder and replaces all instances of it in the snippet with its default value."
$CopyPlaceholderNamenameToClipboardToolStripMenuItem.ToolTipText = "(Ctrl+C) Copies the $<name>$ - name of the placeholder to the clipboard,so you can easily paste new instances to the snippet."
$TVFolderTVFileCopyToolStripMenuItem1.ToolTipText = "(Ctrl+C) "
$TVFolderCutToolStripMenuItem1.ToolTipText = "(Ctrl+X) "
$TVFolderPasteToolStripMenuItem1.ToolTipText = "(Ctrl+V) "
$TVFolderDeleteToolStripMenuItem2.ToolTipText = "(Del)"
$TVFolderRenameToolStripMenuItem.ToolTipText = "(Ctrl+R) "
$PlaceEndMarkerToolStripMenuItem.ToolTipText = "This marks the place where the cursor sits,after you inserted the snippet in your script."
$CreatePlaceholderFromSelectionToolStripMenuItem.ToolTipText = "(F5) This creates a placeholder and automatically replaces all instances of the selected text with `$<selected text>`$"
$CreatePlaceholderFromSelectionWithNewNameToolStripMenuItem.ToolTipText = "(F6) Creates a placeholder with a given name and automatically replaces all instances of the selected text with `$<given name>`$"
$PlaceSelectedMarkerToolStripMenuItem.ToolTipText = "When you select a text in your script and then insert the snippet,this marker will be replaced by the selected text. "
$TreeviewUeberrootContextMenu = New-Object System.Windows.Forms.ContextMenuStrip($components)

#region Form: Standard InputDialog
#~~< InputDialog form  >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Dialog = New-Object System.Windows.Forms.Form
$Dialog.CausesValidation = $true
$Dialog.TopMost = $true
$Dialog.Icon = New-Object System.Drawing.Icon("$windowico")
$Dialog.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$Dialog.ClientSize = New-Object System.Drawing.Size(300, 31)
$Dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedToolWindow
$Dialog.MaximizeBox = $false
$Dialog.MinimizeBox = $false
$Dialog.StartPosition = 0 
$Dialog.KeyPreview = $True
$Dialog.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
{$script:Dialogresult = "ok";$Dialog.Close()}})
$Dialog.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
{$script:Dialogresult = "cancel";$Dialog.Close()}})
#~~< InputBox >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$InputBox = New-Object System.Windows.Forms.TextBox
$InputBox.Location = New-Object System.Drawing.Point(0, 1)
$InputBox.Multiline = $true
$InputBox.Size = New-Object System.Drawing.Size(300, 34)
$InputBox.TabIndex = 0
$InputBox.Text = ""
$InputBox.ForeColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](3)))), ([System.Int32](([System.Byte](50)))), ([System.Int32](([System.Byte](71)))))
$Dialog.Controls.Add($InputBox)
#endregion

#region SearchSnippet Window
#~~< SearchSnipWin >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnipWin = New-Object System.Windows.Forms.Form
$SearchSnipWin.Icon = New-Object System.Drawing.Icon("$windowico")
$SearchSnipWin.ClientSize = New-Object System.Drawing.Size(455, 259)
$SearchSnipWin.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$SearchSnipWin.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedToolWindow
$SearchSnipWin.KeyPreview = $True
$SearchSnipWin.Add_KeyDown({FNchecksearchoptions})
$SearchSnipWin.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
{$script:SearchSnipWinDialogresult = "cancel";$SearchSnipWin.Close()}})
$SearchSnipWin.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
{$script:SearchSnipWinDialogresult = "ok";$SearchSnipWin.Close()}})
$SearchSnipWin.MaximizeBox = $false
$SearchSnipWin.MinimizeBox = $false
# $SearchSnipWin.add_closing({ $script:SearchSnipWinDialogresult = "cancel" })
$SearchSnipWin.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
$SearchSnipWin.Text = "Search Snippets"
$SearchSnipWin.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))), ([System.Int32](([System.Byte](239)))))
#~~< SearchSnippetOptionCase >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetOptionCase = New-Object System.Windows.Forms.CheckBox
$SearchSnippetOptionCase.Location = New-Object System.Drawing.Point(251, 163)
$SearchSnippetOptionCase.Size = New-Object System.Drawing.Size(181, 24)
$SearchSnippetOptionCase.TabIndex = 14
$SearchSnippetOptionCase.Text = "Case Sensitive"
$SearchSnippetOptionCase.UseVisualStyleBackColor = $true
#~~< SearchSnippetOptionAllLoc >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetOptionAllLoc = New-Object System.Windows.Forms.CheckBox
$SearchSnippetOptionAllLoc.Location = New-Object System.Drawing.Point(251, 115)
$SearchSnippetOptionAllLoc.Size = New-Object System.Drawing.Size(181, 24)
$SearchSnippetOptionAllLoc.TabIndex = 11
$SearchSnippetOptionAllLoc.Text = "All Snippet Locations"
$SearchSnippetOptionAllLoc.UseVisualStyleBackColor = $true
$SearchSnippetOptionAllLoc.add_CheckedChanged({
	if ($SearchSnippetOptionAllLoc.Checked -eq $false) {$SearchSnippetOptionSelectedDir.Checked = $true}
	if ($SearchSnippetOptionAllLoc.Checked -eq $true) {$SearchSnippetOptionSelectedDir.Checked = $false}
})
#~~< SearchSnippetOptionSelectedDir >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetOptionSelectedDir = New-Object System.Windows.Forms.CheckBox
$SearchSnippetOptionSelectedDir.Location = New-Object System.Drawing.Point(251, 91)
$SearchSnippetOptionSelectedDir.Size = New-Object System.Drawing.Size(194, 24)
$SearchSnippetOptionSelectedDir.TabIndex = 10
$SearchSnippetOptionSelectedDir.Checked = $true
$SearchSnippetOptionSelectedDir.Text = "Selected Folder (and subfolders)"
$SearchSnippetOptionSelectedDir.UseVisualStyleBackColor = $true
$SearchSnippetOptionSelectedDir.add_CheckedChanged({ 
	if ($SearchSnippetOptionSelectedDir.Checked -eq $false) {$SearchSnippetOptionAllLoc.Checked = $true}
	if ($SearchSnippetOptionSelectedDir.Checked -eq $true) {$SearchSnippetOptionAllLoc.Checked = $false}
})
#~~< SearchSnippetLabel3 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetLabel3 = New-Object System.Windows.Forms.Label
$SearchSnippetLabel3.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$SearchSnippetLabel3.Location = New-Object System.Drawing.Point(237, 71)
$SearchSnippetLabel3.Size = New-Object System.Drawing.Size(68, 18)
$SearchSnippetLabel3.TabIndex = 9
$SearchSnippetLabel3.Text = "Search in:"
#~~< SearchSnippetLabel2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetLabel2 = New-Object System.Windows.Forms.Label
$SearchSnippetLabel2.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$SearchSnippetLabel2.Location = New-Object System.Drawing.Point(14, 11)
$SearchSnippetLabel2.Size = New-Object System.Drawing.Size(85, 18)
$SearchSnippetLabel2.TabIndex = 8
$SearchSnippetLabel2.Text = "Search Text:"
$SearchSnippetLabel2.add_Click({Label2Click($SearchSnippetLabel2)})
#~~< SearchSnippetLabel1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetLabel1 = New-Object System.Windows.Forms.Label
$SearchSnippetLabel1.Font = New-Object System.Drawing.Font("Segoe UI", 9.0)
$SearchSnippetLabel1.Location = New-Object System.Drawing.Point(17, 71)
$SearchSnippetLabel1.Size = New-Object System.Drawing.Size(68, 18)
$SearchSnippetLabel1.TabIndex = 7
$SearchSnippetLabel1.Text = "Include:"
#~~< SearchSnippetOptionCode >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetOptionCode = New-Object System.Windows.Forms.CheckBox
$SearchSnippetOptionCode.Location = New-Object System.Drawing.Point(30, 163)
$SearchSnippetOptionCode.Size = New-Object System.Drawing.Size(104, 24)
$SearchSnippetOptionCode.TabIndex = 6
$SearchSnippetOptionCode.Text = "Snippet Code"
$SearchSnippetOptionCode.UseVisualStyleBackColor = $true
$SearchSnippetOptionCode.Add_Click({FNchecksearchoptions})
#~~< SearchSnippetOptionDescription >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetOptionDescription = New-Object System.Windows.Forms.CheckBox
$SearchSnippetOptionDescription.Checked = $true
$SearchSnippetOptionDescription.CheckState = [System.Windows.Forms.CheckState]::Checked
$SearchSnippetOptionDescription.Location = New-Object System.Drawing.Point(30, 139)
$SearchSnippetOptionDescription.Size = New-Object System.Drawing.Size(137, 24)
$SearchSnippetOptionDescription.TabIndex = 5
$SearchSnippetOptionDescription.Text = "Snippet Description"
$SearchSnippetOptionDescription.UseVisualStyleBackColor = $true
$SearchSnippetOptionDescription.Add_Click({FNchecksearchoptions})
#~~< SearchSnippetOptionAuthor >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetOptionAuthor = New-Object System.Windows.Forms.CheckBox
$SearchSnippetOptionAuthor.Location = New-Object System.Drawing.Point(30, 115)
$SearchSnippetOptionAuthor.Size = New-Object System.Drawing.Size(119, 24)
$SearchSnippetOptionAuthor.TabIndex = 4
$SearchSnippetOptionAuthor.Text = "Snippet Author"
$SearchSnippetOptionAuthor.UseVisualStyleBackColor = $true
$SearchSnippetOptionAuthor.Add_Click({FNchecksearchoptions})
#~~< SearchSnippetOptionFilename >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetOptionFilename = New-Object System.Windows.Forms.CheckBox
$SearchSnippetOptionFilename.Checked = $true
$SearchSnippetOptionFilename.CheckState = [System.Windows.Forms.CheckState]::Checked
$SearchSnippetOptionFilename.Location = New-Object System.Drawing.Point(30, 91)
$SearchSnippetOptionFilename.Size = New-Object System.Drawing.Size(172, 24)
$SearchSnippetOptionFilename.TabIndex = 3
$SearchSnippetOptionFilename.Text = "Filename and Snippet Name"
$SearchSnippetOptionFilename.UseVisualStyleBackColor = $true
$SearchSnippetOptionFilename.Add_Click({FNchecksearchoptions})
#~~< BNcancelsearchsnippet >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNcancelsearchsnippet = New-Object System.Windows.Forms.Button
$BNcancelsearchsnippet.Location = New-Object System.Drawing.Point(231, 210)
$BNcancelsearchsnippet.Size = New-Object System.Drawing.Size(120, 23)
$BNcancelsearchsnippet.TabIndex = 2
$BNcancelsearchsnippet.Text = "Cancel"
$BNcancelsearchsnippet.UseVisualStyleBackColor = $true
$BNcancelsearchsnippet.add_Click({$SearchSnipWinDialogresult = "Cancel";$SearchSnipWin.Close()})
#~~< BNsearchsnippet >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$BNsearchsnippet = New-Object System.Windows.Forms.Button
$BNsearchsnippet.Location = New-Object System.Drawing.Point(95, 210)
$BNsearchsnippet.Size = New-Object System.Drawing.Size(121, 23)
$BNsearchsnippet.TabIndex = 1
$BNsearchsnippet.Text = "Search"
$BNsearchsnippet.UseVisualStyleBackColor = $true
$BNsearchsnippet.add_Click({$SearchSnipWinDialogresult = "Ok";$SearchSnipWin.Close()})
$BNsearchsnippet.enabled = $false
#~~< SearchSnippetInputBox >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnippetInputBox = New-Object System.Windows.Forms.TextBox
$SearchSnippetInputBox.Location = New-Object System.Drawing.Point(15, 34)
$SearchSnippetInputBox.Multiline = $false
$SearchSnippetInputBox.Size = New-Object System.Drawing.Size(426, 22)
$SearchSnippetInputBox.TabIndex = 0
$SearchSnippetInputBox.Text = ""
#~~< GroupBox1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$GroupBox1 = New-Object System.Windows.Forms.GroupBox
$GroupBox1.Location = New-Object System.Drawing.Point(15, 73)
$GroupBox1.Size = New-Object System.Drawing.Size(195, 122)
$GroupBox1.TabIndex = 12
$GroupBox1.TabStop = $false
$GroupBox1.Text = ""
#~~< GroupBox2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$GroupBox2 = New-Object System.Windows.Forms.GroupBox
$GroupBox2.Location = New-Object System.Drawing.Point(236, 73)
$GroupBox2.Size = New-Object System.Drawing.Size(205, 76)
$GroupBox2.TabIndex = 13
$GroupBox2.TabStop = $false
$GroupBox2.Text = ""
$SearchSnipWin.Controls.Add($SearchSnippetOptionCase)
$SearchSnipWin.Controls.Add($SearchSnippetOptionAllLoc)
$SearchSnipWin.Controls.Add($SearchSnippetOptionSelectedDir)
$SearchSnipWin.Controls.Add($SearchSnippetLabel3)
$SearchSnipWin.Controls.Add($SearchSnippetLabel2)
$SearchSnipWin.Controls.Add($SearchSnippetLabel1)
$SearchSnipWin.Controls.Add($SearchSnippetOptionCode)
$SearchSnipWin.Controls.Add($SearchSnippetOptionDescription)
$SearchSnipWin.Controls.Add($SearchSnippetOptionAuthor)
$SearchSnipWin.Controls.Add($SearchSnippetOptionFilename)
$SearchSnipWin.Controls.Add($BNcancelsearchsnippet)
$SearchSnipWin.Controls.Add($BNsearchsnippet)
$SearchSnipWin.Controls.Add($SearchSnippetInputBox)
$SearchSnipWin.Controls.Add($GroupBox1)
$SearchSnipWin.Controls.Add($GroupBox2)

#endregion

#~~< $SearchSnipContextmenu >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchSnipContextmenu = New-Object System.Windows.Forms.ContextMenuStrip($components)
$SearchSnipContextmenu.Size = New-Object System.Drawing.Size(268, 76)
$SearchSnipContextmenu.Text = ""
$SearchSnipContextmenu.BackColor = [System.Drawing.Color]::White
#~~< ToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchResultContextMenuLocateInExplorer = New-Object System.Windows.Forms.ToolStripMenuItem
$SearchResultContextMenuLocateInExplorer.Size = New-Object System.Drawing.Size(213, 22)
$SearchResultContextMenuLocateInExplorer.Text = "Show in Windows Explorer"
$SearchResultContextMenuLocateInExplorer.add_Click({FNlocInExplorer($RootContextMenuLocateInExplorer)})
#~~< StripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$SearchResultContextMenuLocateInTreeview = New-Object System.Windows.Forms.ToolStripMenuItem
$SearchResultContextMenuLocateInTreeview.Size = New-Object System.Drawing.Size(267, 22)
$SearchResultContextMenuLocateInTreeview.Text = "Locate in Location Tree"
$SearchResultContextMenuLocateInTreeview.add_Click({FNlocInTreeview($RootContextMenuLocateInExplorer)})

$SearchSnipContextmenu.Items.AddRange([System.Windows.Forms.ToolStripItem[]](@($SearchResultContextMenuLocateInTreeview, $SearchResultContextMenuLocateInExplorer)))


#region Form: Aboutwindow
#~~< aboutwin >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$aboutwin = New-Object System.Windows.Forms.Form
$aboutwin.Icon = New-Object System.Drawing.Icon("$windowico")
$aboutwin.ClientSize = New-Object System.Drawing.Size(310, 357)
$aboutwin.Font = New-Object System.Drawing.Font("Segoe UI", 8.25)
$aboutwin.MaximizeBox = $false
$aboutwin.MaximumSize = New-Object System.Drawing.Size(326, 395)
$aboutwin.MinimizeBox = $false
$aboutwin.MinimumSize = New-Object System.Drawing.Size(326, 395)
$aboutwin.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide
$aboutwin.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$aboutwin.Text = "about"
$aboutwin.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](234)))), ([System.Int32](([System.Byte](234)))), ([System.Int32](([System.Byte](234)))))
#~~< LinkLabel2 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LinkLabel2 = New-Object System.Windows.Forms.LinkLabel
$LinkLabel2.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
$LinkLabel2.LinkBehavior = [System.Windows.Forms.LinkBehavior]::NeverUnderline
$LinkLabel2.Location = New-Object System.Drawing.Point(76, 213)
$LinkLabel2.Size = New-Object System.Drawing.Size(181, 16)
$LinkLabel2.TabIndex = 3
$LinkLabel2.TabStop = $true
$LinkLabel2.Text = "Website (german): www.bitspace.de"
$LinkLabel2.add_LinkClicked({FNloadURL("http://www.bitspace.de")})
$LinkLabel2.ActiveLinkColor = [System.Drawing.Color]::Black
$LinkLabel2.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](231)))), ([System.Int32](([System.Byte](231)))), ([System.Int32](([System.Byte](231)))))
$LinkLabel2.LinkColor = [System.Drawing.Color]::Black
#~~< LinkLabel1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LinkLabel1 = New-Object System.Windows.Forms.LinkLabel
$LinkLabel1.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
$LinkLabel1.LinkBehavior = [System.Windows.Forms.LinkBehavior]::NeverUnderline
$LinkLabel1.Location = New-Object System.Drawing.Point(65, 195)
$LinkLabel1.Size = New-Object System.Drawing.Size(205, 18)
$LinkLabel1.TabIndex = 2
$LinkLabel1.TabStop = $true
$LinkLabel1.Text = "Blog (english): bytecookie.wordpress.com"
$LinkLabel1.add_LinkClicked({FNloadURL("http://bytecookie.wordpress.com")})
$LinkLabel1.ActiveLinkColor = [System.Drawing.Color]::Black
$LinkLabel1.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](231)))), ([System.Int32](([System.Byte](231)))), ([System.Int32](([System.Byte](231)))))
$LinkLabel1.LinkColor = [System.Drawing.Color]::Black
#~~< Label1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$versionlabel = New-Object System.Windows.Forms.Label
$versionlabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.25, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
$versionlabel.Location = New-Object System.Drawing.Point(146, 155)
$versionlabel.Size = New-Object System.Drawing.Size(42, 15)
$versionlabel.TabIndex = 1
$versionlabel.Text = $version
$versionlabel.BackColor = [System.Drawing.Color]::FromArgb(([System.Int32](([System.Byte](231)))), ([System.Int32](([System.Byte](231)))), ([System.Int32](([System.Byte](231)))))
#~~< aboutbox >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$aboutbox = New-Object System.Windows.Forms.PictureBox
$aboutbox.Location = New-Object System.Drawing.Point(0, 0)
$aboutbox.Size = New-Object System.Drawing.Size(309, 355)
$aboutbox.TabIndex = 0
$aboutbox.TabStop = $false
$aboutbox.Text = ""
$aboutbox.image = [System.Drawing.Image]::Fromfile("$boximg")  
$aboutwin.Controls.Add($LinkLabel2)
$aboutwin.Controls.Add($LinkLabel1)
$aboutwin.Controls.Add($versionlabel)
$aboutwin.Controls.Add($aboutbox)

#endregion
#~~ Timer ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$component = New-Object System.ComponentModel.Container
$Timer1 = New-Object System.Windows.Forms.Timer($component)
$Timer1.Interval = 10000
$Timer1.add_Tick({FNcheckVersionFile($Timer1)})


#endregion


#endregion

#region Event Loop

function Main{
		[System.Windows.Forms.Application]::EnableVisualStyles()
		$Form1.ShowDialog()
}

#endregion

#endregion

#region Event Handlers
#################################################################################################
#################################################################################################
#region --- General GUI Functions and Event Handler ######
#################################################################################################
#################################################################################################

function FNermes ($message)  {  
		[void] [Windows.Forms.MessageBox]::Show("$message", "SnippetManager Addon - Error", [Windows.Forms.MessageBoxButtons]::ok, [Windows.Forms.MessageBoxIcon]::Warning)
}


#trap  {
#    Write-Debug $error
#	 $date = Get-Date
#		foreach ($err in $error) {
#			Add-Content "$snipmanUPpath\SnippetManagerErrors.log" "$date :$err"
#		}
#}

function FNFormclose( $object ){ 
	if ( $script:reset -ne 1 ) {FNwritesettings}
    # Write-Debug "cancel $cancel   changed $changed   saved $saved"
  	if (($changed -eq 1) -and ($saved -ne 1) ) { 
	FNasktosave
	}
	# get-job | stop-job 
	if ( $startUpdater -eq "true" ) {
		$psi = New-Object System.Diagnostics.ProcessStartInfo "powershell.exe"
		$psi.Arguments = "$updateScript"
		$psi.UseShellExecute = $False
		$psi.CreateNoWindow = $true
		$psi.WorkingDirectory = Get-Location;
		[void][System.Diagnostics.Process]::Start($psi) 
	}
}

function FNstatusbar ($bartext,$warn) { 
	if ($warn -eq 1) { $Statusbar.BackgroundImage = $Bgreen  } #Green
	elseif ($warn -eq 2) {$Statusbar.BackgroundImage =$Byellow } # yellow
	elseif ($warn -eq 3) {$Statusbar.BackgroundImage =$Bred} # red
	else { $Statusbar.BackColor = $statusbarBaseColor ; $Statusbar.ForeColor = $statusbarForeColorStandard ; $Statusbar.BackgroundImage = $Bwhite	} #Silver
	$StatusBar.Text = " >   "+$bartext
}

function FNonFormLoad( $object ){
	if ( !([system.io.directory]::exists($snipmanUPpath))){ md $snipmanUPpath  }  # make Snipman userprofile folder			
	if ( !([system.io.directory]::exists($snippetDefaultPath))){ md $snippetDefaultPath  }  # make snippets userprofile folder
	if ( [system.io.file]::exists($snipmanResetSettingsFile) ){ 
		Remove-Item $snipmanResetSettingsFile -force
		FNresetsettings 
		FNreadsettings 
	} 
	elseif ( [system.io.file]::exists($snipmanSettings) ){ FNreadsettings } 
	else {   # make Snipmansettingsfile
		$askautoupdatecheck = [Windows.Forms.MessageBox]::Show("Would you like to let SnippetManager check for available updates each time it runs?`n`r- No data will be sent from your computer.`n`r- You can turn off the update check in the options menu at any time.", "SnippetManager", [Windows.Forms.MessageBoxButtons]::yesno, [Windows.Forms.MessageBoxIcon]::Question)
		if( $askautoupdatecheck -eq [System.Windows.Forms.DialogResult]::YES )
			{$CheckForUpdatesOnStartToolStripMenuItem.Checked = $true}
		else { $CheckForUpdatesOnStartToolStripMenuItem.Checked = $false }
		FNwritesettings 1
	}			
  	if ( (FNcheckWriteAccess $snippetDefaultPath)  -eq 2 ) {
		FNermes "You have no write access to the Snippet Path in your user profile ($snippetDefaultPath)`n`rThis shouldn't happen.`n`rYou may continue, but you won't be able to save changes."
	}
	$Form1.TopMost = $true
}

function FnFormshown { 
		FnCheckShippedSnippets
		if ($CheckForUpdatesOnStartToolStripMenuItem.Checked -eq $true) { FNcheckForUpdates }
		FNstatusbar "Loading snippet locations (On network locations this could take a moment)..." 1
		$form1.Refresh()
		FNbuildtree 1
}

function FnCheckShippedSnippets {
	 if ( $settingsXML.SnipMan.AskToMoveShippedSnippets -ne "yes") {return}
	 if ($dirdata = Get-ChildItem $shippedSnippetsPath -include "*.snippet" -recurse ) {
			$askmove = [Windows.Forms.MessageBox]::Show("Snippets have been found in PowerGUIs installation folder. `n`rIn order to be able to edit or activate/deactivate them with Snippet Manager, they need to be moved to the snippet folder in your user profile.`n`r`n`rYou have the following options:`n`r------------------------------------`n`r`n`rClick `"Yes`" to move them. They will show up in PowerGUI and you can edit them. (Recommended)`n`r`n`rClick `"No`" to leave them there. They will show up in PowerGUI but you can not edit them. You won't be asked again.`n`r`n`rClick `"Cancel`" to be asked again later.`n`r`n`r", "SnippetManager", [Windows.Forms.MessageBoxButtons]::YesNoCancel, [Windows.Forms.MessageBoxIcon]::Question, [Windows.Forms.MessageBoxDefaultButton]::Button1 )
			if( $askmove -eq [System.Windows.Forms.DialogResult]::YES ) { 	
					# copy
					$shipsnipdir = Get-ChildItem $shippedSnippetsPath
					foreach ($element in $shipsnipdir) {
						if ($element.PSiscontainer) { 
							$targetfullpath = ($snippetDefaultPath+"\"+$element.basename)
							if ([system.io.directory]::exists("$targetfullpath")) { $targetfullpath = ($snippetDefaultPath+"\"+$element.basename+" (moved from PG folder)") }
							Copy-Item $element.fullname $targetfullpath -recurse
						}
						else { 
							$targetfullpath = ($snippetDefaultPath+"\"+$element.basename+".snippet")
							if ( [system.io.file]::exists("$targetfullpath") ) { $targetfullpath = ($snippetDefaultPath+"\"+$element.basename+" (moved from PG folder).snippet") }
							Copy-Item $element.fullname $targetfullpath 
						}
					}	
					# delete 
					FNelevateprocess "$env:windir\system32\WindowsPowerShell\v1.0\powershell.exe" '-noprofile' '-windowstyle hidden' '-STA' '-File' $moverScript
			}
			if( $askmove -eq [System.Windows.Forms.DialogResult]::NO ) {
					$info = [Windows.Forms.MessageBox]::Show("You decided to leave the snippets in the PowerGUI instalation folder. This folder will be added as a location to the snippets explorer, in addtion to the standard snippet folder in the user profile.`n`r`n`rIt's highly recommended to read the Snippet Manager help file about how the two snippet folders interact.", "SnippetManager", [Windows.Forms.MessageBoxButtons]::ok, [Windows.Forms.MessageBoxIcon]::Information)
			 		FNaddSnippetLocation auto $shippedSnippetsPath
					$settingsXML.SnipMan.AskToMoveShippedSnippets = "no"
							
			}
	}
}

function FNelevateprocess {
    $file, [string]$arguments = $args;
    $psi = New-Object System.Diagnostics.ProcessStartInfo $file;
    $psi.Arguments = $arguments;
	 if ([System.Environment]::OSVersion.Version.Major -gt 5) {
     $psi.Verb = "runas";
	 }	
	$psi.CreateNoWindow = $true
    $psi.WorkingDirectory = Get-Location;
    [void][System.Diagnostics.Process]::Start($psi);
}
 

function FNcheckForUpdates ($manual){
	if ($manual -eq 1){
		Fnstatusbar "Checking for updates..." 1
	}
   if ($UpdCheckActive  -eq "true") {return} 
	$script:ticks = 0
	$form1.Refresh()
	if ( [system.io.file]::exists($Updatefile) ){ Remove-Item "$Updatefile"  } 
	$script:UpdCheckActive  = "true"
	$Timer1.start()
	start-job -argumentlist $updatecheckURL, $Updatefile -ScriptBlock {(New-Object System.Net.WebClient).DownloadFile($args[0],$args[1])} -name SMversionChck
}

function FNcheckVersionFile {
	$script:ticks += 1 
	if ( [system.io.file]::exists($Updatefile) ){ 
			$script:UpdCheckActive  = "false"
			$Timer1.stop() 
			$webversion = [double](Get-Content $Updatefile)
			if ($webversion -eq 0) { $Timer1.start(); return }
			if ($webversion -gt $version) { 
			     $form1.topmost = $false
				  if ($helpwinactive -eq "true") { $SnippetManagerHelp.topmost = $false }
					Fnstatusbar "Newer version available." 1 
					$askdownload = [Windows.Forms.MessageBox]::Show("There is a new version of SnippetManager available.`n`rWould you like to install the update?", "SnippetManager", [Windows.Forms.MessageBoxButtons]::yesno, [Windows.Forms.MessageBoxIcon]::Question)
					if( $askdownload -eq [System.Windows.Forms.DialogResult]::YES ) { 
						 $script:startUpdater = "true"
						 $aboutwin.close()
						 $form1.close()
					}
					else {$form1.topmost = $true}
			}
			else {Fnstatusbar "You have the latest version of Snippet Manager." 1 }
	}					
		
	elseif ($ticks -ge 18 ) {	
		fnstatusbar "Update check failed." 2
		$script:UpdCheckActive  = "false"
		$Timer1.stop() 
		$errmess = receive-job SMversionChck
		$date = Get-Date
		foreach ($err in $error) {
			Add-Content "$snipmanUPpath\SnippetManagerErrors.log" "$date :$err"
		}
	}
}

function FNSetcheckUpdOnStart( $object ){
		if ( $checkUpdOnStart -eq 1){ 
			$script:checkUpdOnStart = 0	}
		else { $script:checkUpdOnStart = 1 	}
}

function FNcheckWriteAccess ($checkWApath) {
	 if ( New-Item "$checkWApath\testfile.txt" -Type File -erroraction silentlycontinue) { 
			Remove-Item "$checkWApath\testfile.txt"
			return 1
  	}
	else {   #no access
		return 2
	}

}

function FNautoAuthor( $object ){
		 if ( $autoAuthor -eq 1){ 
			$script:autoAuthor = 0	
		}
		else { 
			if ( !($autoAuthorText)) { FNsetStandardAuthor }
			$script:autoAuthor = 1 
		}
}

function FNsetStandardAuthor( $object ){
		$Pos = [System.Windows.Forms.Cursor]::Position
		if (!($autoAuthorText)){ $Inputbox.Text = ""}
			else { $Inputbox.Text = $autoAuthorText } 
		$dialog.text = "Please enter the standard text for the Author field:"
		$dialog.left = ( $pos.x-60)      
		$dialog.top = ($pos.y)   
		$script:Dialogresult = ""
		$Dialog.ShowDialog() 
		if ($Dialogresult -eq "ok"){
			if ( ($Inputbox.Text).trim() ) {
				$script:autoAuthorText = $Inputbox.Text 
				$settingsXML.SnipMan.AutoAuthorText = $autoAuthorText 
			}
		}
}

function FNreadsettings {
	 $script:settingsXML = [xml](Get-Content $snipmanSettings )
	
	if ( $settingsXML.SnipMan.Tooltips -eq "true"  ) {
		$ToolTipsInMainExplorer.Checked = $true }
	else { $ToolTipsInMainExplorer.Checked = $false }
		
	if ( $settingsXML.SnipMan.UpdateCheck -eq "true"   ) {
		$CheckForUpdatesOnStartToolStripMenuItem.Checked = $true }
	else { $CheckForUpdatesOnStartToolStripMenuItem.Checked = $false }
	
	if ( $settingsXML.SnipMan.AutoAuthor -eq "true"  ) {
		$PutInStandardTextAsAuthorToolStripMenuItem.Checked = $true 
		$script:autoAuthor = 1 
		$script:autoAuthorText = $settingsXML.SnipMan.AutoAuthorText
		$TBsnippetAuthor.Text = $autoAuthorText
		$script:changed = 0
		}
	else { 
		$PutInStandardTextAsAuthorToolStripMenuItem.Checked = $false
		
	if ($settingsXML.SnipMan.AutoAuthorText) {
			$script:autoAuthorText = $settingsXML.SnipMan.AutoAuthorText}
		}
		
	if (!($settingsXML.SnipMan.StorageTooltips )) { FNwritesettings 1 }
	
	if ( $settingsXML.SnipMan.StorageTooltips -eq "true"  ) {
			$ToolTipsInStorageExplorer.Checked = $true ; FNshowNodeCODEToolTips}
	else { $ToolTipsInStorageExplorer.Checked = $false ; FNshowNodeCODEToolTips}
	
	if ($settingsXML.SnipMan.SaveWinSize-eq "true"  ) {
			$SaveWindowsizeOnExitToolStripMenuItem.Checked =$true
			if ($settingsXML.SnipMan.Winsize) {
				 if ($settingsXML.SnipMan.Winsize -eq "Maximized") {
					$Form1.WindowState = "Maximized"			 			
				}
				else {
						$winsiz = $settingsXML.SnipMan.Winsize -split ","
						$Form1.Width = $winsiz[0]
						$Form1.Height =$winsiz[1]  
						if ( [INT]$winsiz[2] -lt 0  ) { $Form1.left = 0 }
						else {$Form1.left = $winsiz[2] }
						if ( $winsiz[3] -lt 0  ) { $Form1.top = 0 }
						else {$Form1.top = $winsiz[3] }
				 }
			}
		}
	if (!($settingsXML.SnipMan.Version )) { FNwritesettings 1 }
		
}

function FNresetsettings ($ask) {
	if ($ask -eq 1){
		$ask = [Windows.Forms.MessageBox]::Show("Do you want to reset all Snippet Manager settings and locations to default?", "SnippetManager", [Windows.Forms.MessageBoxButtons]::yesno, [Windows.Forms.MessageBoxIcon]::Question)
		if( $ask -eq [System.Windows.Forms.DialogResult]::NO ) { return "cancel" }
	}
	if ( [system.io.file]::exists($snipmanSettings) ){ Remove-Item $snipmanSettings } 
	$script:settingsXML = [xml]'<?xml version="1.0" encoding="utf-8"?><SnipMan><Version></Version><UpdateCheck></UpdateCheck><Tooltips></Tooltips><StorageTooltips></StorageTooltips><AskToMoveShippedSnippets></AskToMoveShippedSnippets><SaveWinSize></SaveWinSize><Winsize></Winsize><AutoAuthor></AutoAuthor><AutoAuthorText></AutoAuthorText><SnippetLocations></SnippetLocations></SnipMan>'
	# Default Snippetpath - Eintrag erzeugen
	$element = $settingsXML.CreateElement("SnipLoc") 
	$element.psbase.InnerText = $snippetDefaultPath 
	$settingsXML.SnipMan.SelectSingleNode("SnippetLocations").AppendChild($element)
	$settingsXML.SnipMan.AskToMoveShippedSnippets = "yes"
	$settingsXML.SnipMan.UpdateCheck = "true"
	$settingsXML.SnipMan.Tooltips = "true"
	$settingsXML.SnipMan.StorageTooltips = "false"
	$settingsXML.SnipMan.AutoAuthor ="false"
	$settingsXML.SnipMan.SaveWinSize ="true"
	$settingsXML.save("$snipmanSettings")
	if ($ask -eq 1){
		$info = [Windows.Forms.MessageBox]::Show("Done.`n`rPlease restart Snippet Manager.", "SnippetManager", [Windows.Forms.MessageBoxButtons]::ok, [Windows.Forms.MessageBoxIcon]::Information)
		$script:reset = 1	
	}
}

function FNwritesettings ($new) {
	if ($new -eq 1) {
		if ( [system.io.file]::exists($snipmanSettings) ){ Remove-Item $snipmanSettings } 
		$script:settingsXML = [xml]'<?xml version="1.0" encoding="utf-8"?><SnipMan><Version></Version><UpdateCheck></UpdateCheck><Tooltips></Tooltips><StorageTooltips></StorageTooltips><AskToMoveShippedSnippets></AskToMoveShippedSnippets><SaveWinSize></SaveWinSize><Winsize></Winsize><AutoAuthor></AutoAuthor><AutoAuthorText></AutoAuthorText><SnippetLocations></SnippetLocations></SnipMan>'
		# Default Snippetpath - Eintrag erzeugen
			$element = $settingsXML.CreateElement("SnipLoc") 
			$element.psbase.InnerText = $snippetDefaultPath 
			$settingsXML.SnipMan.SelectSingleNode("SnippetLocations").AppendChild($element)
		$settingsXML.SnipMan.AskToMoveShippedSnippets = "yes"
	}
	$settingsXML.SnipMan.Version = "$version"
	
	if ( $CheckForUpdatesOnStartToolStripMenuItem.Checked -eq $true ) {
		$settingsXML.SnipMan.UpdateCheck = "true"}
	else {
		$settingsXML.SnipMan.UpdateCheck = "false"}
	
	if ( $ToolTipsInMainExplorer.Checked -eq $true ) {
		$settingsXML.SnipMan.Tooltips = "true"}
	else {
		$settingsXML.SnipMan.Tooltips = "false"}
		
		if ( $ToolTipsInStorageExplorer.Checked -eq $true  ) {
		$settingsXML.SnipMan.StorageTooltips = "true"}
	else {
		$settingsXML.SnipMan.StorageTooltips = "false"}	
		
	 if ( $PutInStandardTextAsAuthorToolStripMenuItem.Checked -eq $true   ) {
		$settingsXML.SnipMan.AutoAuthor ="true"
		if ( $autoAuthorText ) {$settingsXML.SnipMan.AutoAuthorText = $autoAuthorText}
		}
	else { 
		$settingsXML.SnipMan.AutoAuthor ="false" }
	
	 if ( $SaveWindowsizeOnExitToolStripMenuItem.Checked -eq $true   ) {
		$settingsXML.SnipMan.SaveWinSize ="true"
		if ($Form1.WindowState -eq "Maximized") {
			$settingsXML.SnipMan.Winsize = "Maximized"
		}
		else {
			$settingsXML.SnipMan.Winsize = ""+$Form1.Width+","+$Form1.Height+","+$form1.left+","+$form1.top
		}
	 }
	 else { 
		$settingsXML.SnipMan.SaveWinSize ="false" }
		

	$settingsXML.save("$snipmanSettings")
}

function FNshowHelpWin ( $object ){
  [void][System.Diagnostics.Process]::Start($helpfile)
#		$script:helpwinactive = "true"
#		#~~< SnippetManagerHelp >~
#		$script:SnippetManagerHelp = New-Object System.Windows.Forms.Form
#		$SnippetManagerHelp.Icon = New-Object System.Drawing.Icon("$windowico")
#		$SnippetManagerHelp.CausesValidation = $true
#		$SnippetManagerHelp.topmost = $true
#		$SnippetManagerHelp.ClientSize = New-Object System.Drawing.Size(651, 609)
#		$SnippetManagerHelp.Text = "SnippetManager Help"
#		$SnippetManagerHelp.add_closing({$script:helpwinactive = "false"})
#		#~~< RTBhelp >~~~
#		$RTBhelp = New-Object System.Windows.Forms.RichTextBox
#		$RTBhelp.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
#		$RTBhelp.Location = New-Object System.Drawing.Point(10, 33)
#		$RTBhelp.Size = New-Object System.Drawing.Size(624, 564)
#		$RTBhelp.TabIndex = 0
#		$RTBhelp.Text = ""
#		$RTBhelp.ReadOnly  = $true
#		$SnippetManagerHelp.Controls.Add($RTBhelp)
#		$RTBhelp.loadfile($helpfile)
#		$SnippetManagerHelp.show()
}

function FNhelpwinonclose {$script:helpwinactive = "false"}

function FNshowAbout( $object ){
	$aboutwin.topmost = $true
	$aboutwin.ShowDialog() 
}

function FNloadURL ($url) {
 	$form1.topmost = $false
	(New-Object -com Shell.Application).Open($url)    
}

function FNmailto {
	$form1.topmost = $false
	(New-Object -com Shell.Application).Open("mailto:snipman@gmx.net")    
}

function FNasktosave ($cancelopt) {
		if ($cancelopt -ne "cc") {
			$asksave = [Windows.Forms.MessageBox]::Show("Do you want to save the changes you made?", "SnippetManager", [Windows.Forms.MessageBoxButtons]::yesno, [Windows.Forms.MessageBoxIcon]::Question)
		}
		else {
			$asksave = [Windows.Forms.MessageBox]::Show("Do you want to save the changes you made?", "SnippetManager", [Windows.Forms.MessageBoxButtons]::yesnocancel, [Windows.Forms.MessageBoxIcon]::Question)
		}
		
		if( $asksave -eq [System.Windows.Forms.DialogResult]::YES ) { 
		   if (FNSaveSnippet -ne "OK") { return "cancel" }
		}
		if( $asksave -eq [System.Windows.Forms.DialogResult]::Cancel ) { return "cancel" }
		
		return "ok"
}

function FNtextchanged ($object){ 
    $script:changed = 1
	 $script:saved = 0
	 $Form1.TopMost = $true
	 # $Statusbar.BackColor = $statusbarBaseColor
	 $Statusbar.BackgroundImage = $Bwhite
	 $Statusbar.ForeColor = $statusbarForeColorStandard
	 $script:UNDOautocreate = 0  
}

function FNrtbPreKeyDown {
		$RichTextBox1.SelectionColor = "#1E1E33"
		$RichTextBox1.SelectionBackColor = "#FBFBFD"
		if (($_.Keydata -eq "F5"))   { FNautoCreatePlaceholder }
		if (($_.Keydata -eq "F6"))   { FNhalfautocreatePlaceholder }
}

function FNnewSnippet( $object ){
		if (($changed -eq 1) -and ($saved -ne 1) ) { 
			if ( (FNasktosave "cc") -eq "cancel") {return}
		}
		FNcleartextbox
		$LVplaceholders.Items.clear()
		$TBSnippetTitle.Text = ""
		$TBsnippetDescription.Text = ""
		if ( $autoAuthor -eq 1) { $TBsnippetAuthor.Text = $autoAuthorText }
		 else { $TBsnippetAuthor.Text = ""  } 		
		$script:changed = 0
		$script:snippetloaded = 0
}

function FNshowNodeToolTips {
	if ( $subnodetooltips -eq 1){ 
			$script:subnodetooltips = 0
			FNbuildtree 1
		}
		else { $script:subnodetooltips = 1 
			FNbuildtree 1
		}
}


function FNshowNodeCODEToolTips( $object ){
  if ( $ToolTipsInStorageExplorer.Checked -eq $true   ) {  
  		$StoreTree1.ShowNodeToolTips = $true
		$StoreTree2.ShowNodeToolTips = $true
	}
  else {   
		$StoreTree1.ShowNodeToolTips = $false
		$StoreTree2.ShowNodeToolTips = $false
  }
	
}



function FNkeyshortcutsTreevw( $object ){
		Write-Debug $_.Keydata
	if (($_.Keydata -eq "Return"))   { FNgetmanualNode; FNtreeDoubleclick ; return}
	if (($_.Keydata -eq "F5"))   { FNbuildtree 1 ; return}
	if (($_.Keydata -eq "F, Control"))   { FNsearchsnippet ; return}
	
	FNgetmanualNode
	if ($expltype2.contains("searchresult") ) {return}
	
 	if ($_.KeyData -eq "Delete") { FNgetmanualNode; FNdelete }
 	if (($_.Keydata -eq "X, Control"))   { FNgetmanualNode; FNtreenodeCut }
	if (($_.Keydata -eq "C, Control"))   { FNgetmanualNode; FNtreenodeCopy }
	if (($_.Keydata -eq "V, Control"))   { FNgetmanualNode; FNtreenodePaste }
	if (($_.Keydata -eq "R, Control"))   { FNgetmanualNode; FNRename }

}

function FNkeyshortcutsPLHs( $object ){
 	if ($_.KeyCode -eq "Delete") { FNdeletePlaceholder }
	if (($_.Keydata -eq "N, Control"))   { FNmanualPlaceholder }
	if (($_.Keydata -eq "C, Control"))   { FNcopyPLHname }
}

function FNkeyshortcutsForm( $object ){
#	Write-Debug $_.Keydata
}

#endregion


#region ---  Treeview functions #######

function FNgetmanualNode {
	      $nodeobject =  $treeView1.SelectedNode
			$script:explname = $nodeobject.text
			$script:explpath =  $nodeobject.name
			$script:expltype =  $nodeobject.tag[0]
			# Write-Host $nodeobject.name
			if ($nodeobject.tag[1]) {$script:expltype2 =  $nodeobject.tag[1]}
			if ($nodeobject.tag[2]) {$script:explAccessType =  $nodeobject.tag[2] }
			
			$script:explobj =  $nodeobject
}

function FNtree1click {   
	$nodeobject  = $treeview1.HitTest($_.X, $_.Y).node	
	 # $nodecount = ($nodeobject.GetNodeCount("True"))   # zählt die Subnodes einer Node
	$treeView1.SelectedNode = $nodeobject
	if ($nodeobject) {
			$script:explname = $nodeobject.text
			$script:explpath =  $nodeobject.name
			$script:expltype =  $nodeobject.tag[0]
			$script:explobj =  $nodeobject
			if ($nodeobject.tag[2]) {$script:explAccessType =  $nodeobject.tag[2] }
		}
	else {$script:expltype = "none" }
}

function TreeView1AfterSelect( $object ){
}

function FNexpandNode ($root,$nodename) {  
	foreach ($n in $root.Nodes) {
		if ($n.name -eq $nodename ) { 
			$n.ensurevisible()
			$TreeView1.SelectedNode = $n
			$TreeView1.Select()
		}
		if ($n.Nodes.Count -ne 0)  { FNexpandNode $n $nodename }
	}
}

function FNlocInExplorer  {
		if ($expltype -eq "none") {return}
		$Form1.TopMost = $false
		[Diagnostics.Process]::Start('explorer.exe','/select,'+"`"$explpath`"")
}


function FNlocInTreeview  { 
	FNexpandNode $rootnode $explpath
}

function FNdelete( $object ){ 
		if ($expltype -eq "none") {return}
		if ($explAccessType -eq "RO") { FNstatusbar "You have currently no write permissions in this path.." 2
			return}
		if ($expltype -eq "root" ) {
			Fnstatusbar "You can't delete the snippet root directory." 2
		return}
		if ($expltype -eq "Dir" ) {
			if ( $NAsnippets = dir $explpath -recurse -filter *.NAsnippet ) {
				foreach ($file in $NAsnippets) { $NAsnippetcollection = $NAsnippetcollection+$file.name+", "  }
				$askmess = "Are you sure you want to delete the directory`n`r`"$explname`" and everything thats in it permanently?`n`r`n`rBe aware that you have the following deactivated(!) snippets in this directory: `n`r`n`r $NAsnippetcollection"
			}
			else{
				$askmess = "Are you sure you want to delete the directory`n`r`"$explname`" and everything thats in it permanently?"
			}
		}
		elseif ($expltype -eq "File") { $askmess = "Are you sure you want to delete the file `"$explname.snippet`"permanently?"}
			else {return}
		$askdel = [Windows.Forms.MessageBox]::Show($askmess, "SnippetManager", [Windows.Forms.MessageBoxButtons]::yesno, [Windows.Forms.MessageBoxIcon]::Question, [Windows.Forms.MessageBoxDefaultButton]::Button2 )
		if( $askdel -eq [System.Windows.Forms.DialogResult]::YES ) { 	
			if ( $expltype -eq "Dir"  ) {Remove-Item $explpath -recurse }
			 else { Remove-Item $explpath }
		}
		 else { return }				
		 # remove treenode
		 $treeView1.get_Nodes().Remove($treeView1.get_SelectedNode())
		 FNstatusbar "Ready."
}


function FNnewFolder( $object ){ 
		if ($expltype -eq "none") {return}
		if ($explAccessType -eq "RO") { FNstatusbar "You have currently no write permissions in this path.." 2
			return}
		$Pos = [System.Windows.Forms.Cursor]::Position
		$Inputbox.Text = ""
		$dialog.text = "Please enter a name for the new folder:"
		$dialog.left = ( $pos.x-60)      
		$dialog.top = ($pos.y)   
		$script:Dialogresult = ""
		$Dialog.ShowDialog() 
		if ($Dialogresult -eq "ok"){
			if ((FNcheckforforbiddenchars $Inputbox.Text 1) -eq 1) {
				FNstatusbar "$filters are not allowed in a folder name." 2
				return
			}
			if ( $Inputbox.Text.Trim() -eq "" ) {FNstatusbar "Ready." ; return} 
			if ( [system.io.directory]::exists(("$explpath\"+$Inputbox.Text)) ) {
				FNstatusbar "A Folder with that name already exist in this path!" 2
				return
			} 
			md ("$explpath\"+$Inputbox.Text)
			$newpath = "$explpath\"+$Inputbox.Text
			#add Treenode
			$subnode = New-Object System.Windows.Forms.TreeNode
			$subnode.text = $Inputbox.Text        																					
			$subnode.name  = $newpath
			$subnode.tag = "Dir", "Dir"
			$subnode.ImageIndex = 1
			$subnode.SelectedImageIndex = 1
			 $subnode.ContextMenuStrip = $FolderContextMenu
			[void]$explobj.Nodes.Add($subnode)
			# FNbuildtree 1
			FNstatusbar "Ready."
			FNexpandNode $rootnode $newpath
		}
}

function FNRename( $object ){ 
		if ($expltype -eq "none") {return}
		if ($explAccessType -eq "RO") { FNstatusbar "You have currently no write permissions in this path.." 2
			return}
		if ($expltype -eq "root" ) {
			Fnstatusbar "You can't rename the snippet root directory." 2
			return}
		$Pos = [System.Windows.Forms.Cursor]::Position
		$Inputbox.Text = $explname
		$dialog.text = "Please enter a new name:"
		$dialog.left = ( $pos.x-60)      
		$dialog.top = ($pos.y-100)   
		$script:Dialogresult = ""
		$Dialog.ShowDialog() 
		if ($Dialogresult -eq "ok"){
			if ((FNcheckforforbiddenchars $Inputbox.Text 1) -eq 1) {
				FNstatusbar "$filters are not allowed in a folder or filename." 2
				return
			}
			if ($expltype -eq "Dir") { ### Dir?
					$newname = ((Split-Path "$explpath")+"\"+$Inputbox.Text)
					if ( ($explpath -eq $newname.Trim()) -or ($Inputbox.Text.Trim() -eq "") ) {FNstatusbar "Ready." ; return} 
					if ( [system.io.directory]::exists("$newname") ) {
						FNstatusbar "A Folder with that name already exist in this path!" 2
						return
					} 
					Rename-Item  $explpath $newname
			}
			if ($expltype -eq "File") {  ### File?
					$newname = ((Split-Path "$explpath")+"\"+$Inputbox.Text+".snippet")
					if ( ($explpath -eq $newname.Trim()) -or ($Inputbox.Text.Trim() -eq "") ) {FNstatusbar "Ready." ; return} 
					if ( [system.io.file]::exists("$newname") ) {
						FNstatusbar "A snippet with that name already exist in this path!" 2
						return
					} 
					Rename-Item  $explpath $newname
			}			
			
			#$treeView1.get_Nodes().Remove($treeView1.get_SelectedNode())
			FNstatusbar "Ready."
			FNbuildtree 1
			FNexpandNode $rootnode $newname
			
		}
}

function FNtreenodeCut( $object ){
		if ($expltype -eq "none") {return}
		if ($explAccessType -eq "RO") { FNstatusbar "You have currently no write permissions in this path.." 2
			return}
		if ($expltype -eq "root" ) {
			Fnstatusbar "You can't cut the snippet root directory." 2
		return}	
		#unmark old cut object
		if ($treepasteCUTobjectIndicator -eq 1) { 
			$treepasteobject.NodeFont = New-Object System.Drawing.Font("Segoe UI", 8.25, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
			$treepasteobject.Forecolor = "Black"
		}
		#mark cut object
		$explobj.NodeFont = New-Object System.Drawing.Font("Segoe UI", 8.25, [System.Drawing.FontStyle]::Italic, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
		$explobj.Forecolor = "#858585"
		$script:treepasteobject = $explobj
		$script:treepasteCUTobjectIndicator = 1
		$script:treepasteCopyObjectIndicator = 0
		FNstatusbar "Ready."
}

function FNtreenodeCopy( $object ){
		if ($expltype -eq "none") {return}
		if ($expltype -eq "root" ) {
			Fnstatusbar "You can't copy the snippet root directory." 2
		return}	
		#unmark old cut object
		if ($treepasteCUTobjectIndicator -eq 1) { 
			$treepasteobject.NodeFont = New-Object System.Drawing.Font("Segoe UI", 8.25, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
			$treepasteobject.Forecolor = "Black"
			$script:treepasteCUTobjectIndicator = 0
		}
		$script:treepasteCopyObject = $explobj
		$script:treepasteCopyObjectIndicator = 1
		FNstatusbar "Ready."
}

function FNtreenodePaste( $object ){ 
		if (($expltype -ne "Dir" ) -and ($expltype -ne "root" )) { FNstatusbar "You need to select a target directory to paste an object." ; return }
		if ($explAccessType -eq "RO") { FNstatusbar "You have currently no write permissions in this path.." 2
			return}
		if (($treepasteCUTobjectIndicator -ne 1) -and ($treepasteCopyObjectIndicator -ne 1)) {
			FNstatusbar "Nothing to paste." 
			return }	
		$treetargetobj = $explobj ###
		$treetragetpath = $treetargetobj.name ###
		if ($treetargetobj -eq $treepasteobject) { FNstatusbar "You can't paste an object into itself." 2
			return}
		if ($treetargetobj -eq $treepasteCopyObject) { FNstatusbar "You can't copy an object into itself." 2
			return}
			
		#~~~~~~~~~~~~~ CUT and paste?
		if ($treepasteCUTobjectIndicator -eq 1) {	 
			$pasteobjSourceFullpath= $treepasteobject.name
			
			if ( $treepasteobject.tag[0] -eq "File"){  #~~~~~~~ File ?
				$treetargetFullpath = ($treetargetobj.name+"\"+$treepasteobject.text+".snippet")   
				while ( [system.io.file]::exists("$treetargetFullpath") ) { $c1++
					 $treetargetFullpath = ($treetargetobj.name+"\"+$treepasteobject.text+"($c1).snippet")   
					 $exists = 1
				 }
				}
				else {  #~~~~~~~Dir?
				if ( $treetragetpath.contains($pasteobjSourceFullpath)  ) { Fnstatusbar "The target directory can't be a subdirectory of the source directory." 2 ;return}
				$treetargetFullpath = ($treetargetobj.name+"\"+$treepasteobject.text) 
				while ( [system.io.directory]::exists("$treetargetFullpath") ) { $c2++
					$treetargetFullpath = ($treetargetobj.name+"\"+$treepasteobject.text+"($c2)") 
					$exists = 1
				 } 
				}
		   if ($exists -eq 1) { Move-Item $pasteobjSourceFullpath $treetargetFullpath }
			else { Move-Item $pasteobjSourceFullpath $treetragetpath}				
			
			FNstatusbar "Ready."
		}
		
		#~~~~~~~~~~~~~ COPY and paste?
		if ($treepasteCopyObjectIndicator -eq 1) { 	
			$pasteobjSourceFullpath= $treepasteCopyObject.name
			
			if ( $treepasteCopyObject.tag[0] -eq "File"){   #~~~~~~~ File? 
				$treetargetFullpath = ($treetargetobj.name+"\"+$treepasteCopyObject.text+".snippet")   
				while( [system.io.file]::exists("$treetargetFullpath") ) {  $c4++
					$exists = 1
					$treetargetFullpath = ($treetargetobj.name+"\"+$treepasteCopyObject.text+"($c4)") 
				}
				if ($exists -eq 1) { Copy-Item $pasteobjSourceFullpath $treetargetFullpath }
				else { Copy-Item $pasteobjSourceFullpath $treetragetpath }
				FNstatusbar "Ready."
			}
			else { 	    #~~~~~~~Dir?
				if ( $treetragetpath.contains($pasteobjSourceFullpath)  ) { Fnstatusbar "The target directory can't be a subdirectory of the source directory." 2 ;return}
				$treetargetFullpath = ($treetargetobj.name+"\"+$treepasteCopyObject.text) 
				while ( [system.io.directory]::exists("$treetargetFullpath") ) { $c3++
					$exists = 1
					$treetargetFullpath = ($treetargetobj.name+"\"+$treepasteCopyObject.text+"($c3)")
				} 
			   if ($exists -eq 1) { Copy-Item $pasteobjSourceFullpath $treetargetFullpath -recurse }
				else { Copy-Item $pasteobjSourceFullpath $treetragetpath -recurse }
			 FNstatusbar "Ready."	
			}
		}		

		FNbuildtree 1
		FNexpandNode $rootnode $treetargetFullpath
		$script:treepasteCUTobjectIndicator = 0
}

function FNExpColl  { ######  NIU at the moment -> EXPANDALL-Button?
  			  if ($BNExpandAll) {
                $root.Collapse()
      		    $btnControl.text="Expand All"
          		$blnExpandAll=$False }
       		else {
					$root.ExpandAll()
					$BNControl.text="Collapse All"
					$blnExpandAll=$True }  
        #select the top node
        $treeview1.TopNode=$root
        $form1.Refresh()
 }

function FNremoveSnippetLocation {
		if  ($expltype -ne "root" ) { return }
		if  ($explname -eq "PG Snippetpath" ) { Fnstatusbar "You can't remove the PG Snippetpath." 2  ; return }
		# remove xmlnode
		$node = $settingsXML.SelectSingleNode("//SnipLoc[.='$explpath']")
		[Void]$node.ParentNode.RemoveChild($node)
		# remove treeviewnode
		foreach ($n in $rootnode.Nodes) {
			if ($n.name -eq $explpath ) { 
				 $treeview1.Nodes.remove($n)
			}
		}
		FNstatusbar "Ready."
}

function FNaddSnippetLocation ($mode,$path) {
		$script:breakcurrentbuild = 0
		if ( $mode -eq "NetManual") {  
			$Pos = [System.Windows.Forms.Cursor]::Position
			$Inputbox.Text = ""
			$dialog.text = "Please enter the network path:"
			$dialog.left = ( $pos.x-60)      
			$dialog.top = ($pos.y-100)   
			$script:Dialogresult = ""
			$Dialog.ShowDialog() 
			if ($Dialogresult -eq "ok"){
				$newloc = $Inputbox.Text
				FNstatusbar "Mapping Network Path (This could take a moment)..." 1
				$form1.refresh()
				Invoke-Expression "net use `"$newloc`""
				if ( [system.io.directory]::exists("$newloc")) {	FNstatusbar "Path mapped. Loading Snippets now.. (This could take a moment)..." 1;  $form1.refresh() }
				else { fnstatusbar "Can't access network path." 3 ; return }
				}
					
		}
		elseif ($mode -eq "auto") {
			$newloc = $path
		}
		else {
			$Form1.TopMost = $false
			$getfolder = New-Object -com shell.application
			$foldername = $getfolder.BrowseForFolder(0,"Please choose a folder.`n`rTo remove it later, right click on the node and choose `"Remove Snippet Location`".`n`rTo add a network path manually, choose the menu entry in the options menu.",0,"")
			$Form1.TopMost = $true
			$newloc = $foldername.Self.Path
		}
	if (!($newloc)) { return }
		FNstatusbar "Adding new location (This could take a moment)..." 1
		$progressbar1.visible = $true
		$progressbar1.value = 0
		$form1.refresh()
		# add xmlnode
		$element = $settingsXML.CreateElement("SnipLoc") 
		$element.psbase.InnerText = $newloc 
		$settingsXML.SnipMan.SelectSingleNode("SnippetLocations").AppendChild($element)
		# add treeviewnode
		$subrootnode = New-Object System.Windows.Forms.TreeNode
		$pathsplit = $newloc.split("\")
		if ( $pathsplit.length -gt 3 ) { 
				if ( $newloc.startswith("\\") -eq $true  ) { 
					$subrootnode.text = "\\"+$pathsplit[2]+"\...\"+$pathsplit[-2]+"\"+$pathsplit[-1] 
				}
				else { $subrootnode.text = (Split-Path $newloc -Qualifier)+"\...\"+$pathsplit[-2]+"\"+$pathsplit[-1] 
				}
			}
		else {$subrootnode.text = $newloc
		}	
		
		$subrootnode.name = $newloc
		$subrootnode.ToolTipText = $newloc
		if ( [system.io.directory]::exists("$newloc")) { 
		
			if ( (FNcheckWriteAccess $newloc)  -eq 2 ) {
				$subrootnode.ToolTipText = $newloc+" (The current user has no write access to this path.)"
				$subrootnode.tag = "root", "root0","RO"
				$subrootnode.ContextMenuStrip = $RootContextMenu
				$subrootnode.ImageIndex = 8
				$subrootnode.SelectedImageIndex = 8
				[void]$rootnode.Nodes.Add($subrootnode)		
				$script:dirobjcount = 0
				FNaddsubnodes $newloc $subrootnode 1
			}
			else {
				$subrootnode.ToolTipText = $newloc
				$subrootnode.tag = "root", "root0","RW"
				$subrootnode.ImageIndex = 3
				$subrootnode.SelectedImageIndex = 3
				$subrootnode.ContextMenuStrip = $RootContextMenu
				[void]$rootnode.Nodes.Add($subrootnode)	
				$script:dirobjcount = 0
				FNaddsubnodes $newloc $subrootnode
			}
			$script:creatorTree =  1
		}
		$TreeView1.SelectedNode = $subrootnode
		$TreeView1.Select()
		FNstatusbar "Ready."
		$progressbar1.visible = $false
}

function FNsearchsnippet( $object ){
		$script:sa = 0;$script:sb = 0;$script:sc = 0;$script:sd = 0;
		$script:az=0;$script:bz=0;$script:cz=0;$script:dz=0;
		$script:SearchSnipWinDialogresult = ""
		$SearchSnipWin.topmost = $true
		if (	($SearchSnippetOptionDescription.Checked -eq $false) -and ($SearchSnippetOptionFilename.Checked -eq $false) -and ($SearchSnippetOptionCode.Checked -eq $false) -and ($SearchSnippetOptionAuthor.Checked -eq $false)	) { $BNsearchsnippet.enabled = $false ; return }
  			 else {$BNsearchsnippet.enabled = $true}
		$SearchSnipWin.ShowDialog() 
		if ($SearchSnipWinDialogresult -ne "Ok"){ return}
		if ($searchRootNode) { $treeview1.Nodes.remove($searchRootNode)}
		if ( (($SearchSnippetInputBox.Text).trim()).length -gt 10 ) {
				$script:searchTxtShort = ((($SearchSnippetInputBox.Text).trim()).substring(0,10))+"..."
		}
		else { $script:searchTxtShort = ($SearchSnippetInputBox.Text).trim()	}
		
		# Add searchRootNode
			$script:searchRootNode = New-Object System.Windows.Forms.TreeNode
			$searchRootNode.text = "Search Results for `"$searchTxtShort`""
			$searchRootNode.tag = "root", "searchroot"
			$searchRootNode.ImageIndex = 5
			$searchRootNode.SelectedImageIndex = 5
			$searchRootNode.ContextMenuStrip = $TreeviewUeberrootContextMenu
			[void]$treeview1.Nodes.Add($searchRootNode)	
			$searchRootNode.ensurevisible()
			FNstatusbar ("Searching...") 1
			$form1.refresh()

		### Add Option Nodes
				if ($SearchSnippetOptionFilename.Checked -eq $true) {
						$script:sa = 1
						$script:searchFilenameNode = New-Object System.Windows.Forms.TreeNode
						$searchFilenameNode.text = "Name"
						$searchFilenameNode.tag = "root", "searchOption"
						$searchFilenameNode.ImageIndex = 5
						$searchFilenameNode.SelectedImageIndex = 5
						$searchFilenameNode.ContextMenuStrip = $TreeviewUeberrootContextMenu 
						[void]$searchRootNode.Nodes.Add($searchFilenameNode)
				}
				if ($SearchSnippetOptionAuthor.Checked -eq $true) {
						$script:sb = 1
						$script:searchAuthorNode = New-Object System.Windows.Forms.TreeNode
						$searchAuthorNode.text = "Author"
						$searchAuthorNode.tag = "root", "searchOption"
						$searchAuthorNode.ImageIndex = 5
						$searchAuthorNode.SelectedImageIndex = 5
						$searchAuthorNode.ContextMenuStrip = $TreeviewUeberrootContextMenu
						[void]$searchRootNode.Nodes.Add($searchAuthorNode)
				}
				if ($SearchSnippetOptionDescription.Checked -eq $true) {
						$script:sc = 1
						$script:searchDescriptionNode = New-Object System.Windows.Forms.TreeNode
						$searchDescriptionNode.text = "Description"
						$searchDescriptionNode.tag = "root", "searchOption"
						$searchDescriptionNode.ImageIndex = 5
						$searchDescriptionNode.SelectedImageIndex = 5
						$searchDescriptionNode.ContextMenuStrip = $TreeviewUeberrootContextMenu
						[void]$searchRootNode.Nodes.Add($searchDescriptionNode)
				}
				if ($SearchSnippetOptionCode.Checked -eq $true) {
						$script:sd = 1
						$script:searchCodeNode = New-Object System.Windows.Forms.TreeNode
						$searchCodeNode.text = "Code"
						$searchCodeNode.tag = "root", "searchOption"
						$searchCodeNode.ImageIndex = 5
						$searchCodeNode.SelectedImageIndex = 5
						$searchCodeNode.ContextMenuStrip = $TreeviewUeberrootContextMenu
						[void]$searchRootNode.Nodes.Add($searchCodeNode)
				}

			#$treeview1.refresh()
			$searchRootNode.Expand()
			$form1.refresh()
			$searchRootNode.ensurevisible()
		### Selected Folder	
		if ($SearchSnippetOptionSelectedDir.Checked -eq $true) { 
			if (($expltype -eq "DirRO")-or ($expltype -eq "Dir")-or ($expltype -eq "Root")) { FNsearchsubnodes $explobj }
			else { FNstatusbar "No Folder or Root selected." 2 ; return}
		}
		else {
		### All Locations
				foreach ($locnode in $rootnode.nodes) {
				  FNsearchsubnodes $locnode
				}
		}
		if (!($searchFilenameNode.nodes) -and ($sa -eq 1 )) {$searchFilenameNode.ImageIndex = 7;	$searchFilenameNode.SelectedImageIndex = 7}
		if (!($searchAuthorNode.nodes) -and ($sb -eq 1 )) {$searchAuthorNode.ImageIndex = 7;	$searchAuthorNode.SelectedImageIndex = 7}
		if (!($searchDescriptionNode.nodes) -and ($sc -eq 1 )) {$searchDescriptionNode.ImageIndex = 7;	$searchDescriptionNode.SelectedImageIndex = 7}
		if (!($searchCodeNode.nodes) -and ($sd -eq 1 )) {$searchCodeNode.ImageIndex = 7;	$searchCodeNode.SelectedImageIndex = 7}
		#$searchRootNode.Expand()
		$searchRootNode.ensurevisible()
		FNstatusbar ("Ready.")
}

function FNsearchsubnodes ( $searchnode ) {
	$script:breakcurrentbuild = 0
	 $searchTxt = [regex]::escape($SearchSnippetInputBox.Text) # puts escape chars in front of all special chars, which otherwise would cause a crash
	 if ($SearchSnippetOptionCase.Checked -eq $false) {$regexoptions = "IgnoreCase" }
	 	else {$regexoptions = "None" }
	 foreach ($locsubnode in $searchnode.nodes) { 
			if ( $locsubnode.tag[0] -eq "File") { 
			# Match Names
			 	 if ( $sa -eq 1 ) { # Write-Debug  $searchTxt $locsubnode.tag[1] $locsubnode.text 
					if  (([regex]::match($locsubnode.tag[3] ,$searchTxt,$regexoptions).success) -or ([regex]::match($locsubnode.text ,$searchTxt,$regexoptions).success)) { 
						$script:az++
						$subnode = New-Object System.Windows.Forms.TreeNode
						$subnode.text = $locsubnode.text 
						$subnode.name = $locsubnode.name
						$subnode.tag = "File", "searchresultname"
						$subnode.ToolTipText = $locsubnode.name
						$subnode.ImageIndex =6
						$subnode.SelectedImageIndex = 6
						$subnode.ContextMenuStrip = $SearchSnipContextmenu #$TreeviewUeberrootContextMenu
						[void]$searchFilenameNode.Nodes.Add($subnode)
					}
			  }
			# Match Author
			 	 if ( $sb -eq 1 ) {
					if ([regex]::match($locsubnode.tag[4] ,$searchTxt,$regexoptions).success) {
						$script:bz++
						$subnode = New-Object System.Windows.Forms.TreeNode
						$subnode.text = $locsubnode.text 
						$subnode.name = $locsubnode.name
						$subnode.tag = "File", "searchresultauthor"
						$subnode.ToolTipText = $locsubnode.name
						$subnode.ImageIndex =6
						$subnode.SelectedImageIndex = 6
						$subnode.ContextMenuStrip = $SearchSnipContextmenu
						[void]$searchAuthorNode.Nodes.Add($subnode)				
					}
			  }				
			# Match Description
			 	 if ( $sc -eq 1 ) {
					if ([regex]::match($locsubnode.tag[6] ,$searchTxt,$regexoptions).success) {
						$script:cz++
						$subnode = New-Object System.Windows.Forms.TreeNode
						$subnode.text = $locsubnode.text 
						$subnode.name = $locsubnode.name
						$subnode.tag = "File", "searchresultdescription"
						$subnode.ToolTipText = $locsubnode.name
						$subnode.ImageIndex =6
						$subnode.SelectedImageIndex = 6
						$subnode.ContextMenuStrip = $SearchSnipContextmenu
						[void]$searchDescriptionNode.Nodes.Add($subnode)
					}
			  }			
			# Match Code
			 	 if ( $sd -eq 1 ) {
					if ([regex]::match($locsubnode.tag[5] ,$searchTxt,$regexoptions).success) {
						$script:dz++
						$subnode = New-Object System.Windows.Forms.TreeNode
						$subnode.text = $locsubnode.text 
						$subnode.name = $locsubnode.name
						$subnode.tag = "File", "searchresultcode"
						$subnode.ToolTipText = $locsubnode.name
						$subnode.ImageIndex =6
						$subnode.SelectedImageIndex = 6
						$subnode.ContextMenuStrip = $SearchSnipContextmenu
						[void]$searchCodeNode.Nodes.Add($subnode)
					}
			  }			
		  }
	 if ($locsubnode.nodes) {FNsearchsubnodes $locsubnode}	
	}
	if ($az -ne 0) {$searchFilenameNode.text = "Name ($az)"}
	if ($dz -ne 0) {$searchCodeNode.text = "Code ($dz)"	}
	if ($cz -ne 0) {$searchDescriptionNode.text = "Description ($cz)"	}
	if ($bz -ne 0) {$searchAuthorNode.text = "Author ($bz)"}			
							
}

function FNchecksearchoptions {
	if (	($SearchSnippetOptionDescription.Checked -eq $false) -and ($SearchSnippetOptionFilename.Checked -eq $false) -and ($SearchSnippetOptionCode.Checked -eq $false) -and ($SearchSnippetOptionAuthor.Checked -eq $false)	) { $BNsearchsnippet.enabled = $false ; return }
   else {$BNsearchsnippet.enabled = $true}
	}
	
function FNbuildtree ($treeIndex) {
 		$script:breakcurrentbuild = 0
		$progressbar1.visible = $true
		$progressbar1.value = 0
		$progressbar1.refresh()
		$locpathnum = 0
		if ($treeIndex -eq 1) {
			if ($firstbuild -eq 0) { $treeview1.Nodes.remove($rootnode)}  # clear nodes
			$script:firstbuild = 0
			$script:rootnode = New-Object System.Windows.Forms.TreeNode
			$rootnode.text = "Snippets"
			$rootnode.tag = "root", "root0"
			$rootnode.ImageIndex = 9
			$rootnode.SelectedImageIndex = 9 #9
			$rootnode.ContextMenuStrip = $TreeviewUeberrootContextMenu
			[void]$treeview1.Nodes.Add($rootnode)	#			
			# add snippet locations
		foreach ($locpath in $settingsXML.SnipMan.SnippetLocations.SnipLoc ) {		
					$locpathnum++
					if ($locpath.startswith("\\") -eq $true) {
						FNstatusbar "Mapping Network Path (This could take a moment)..." 1
						$form1.refresh()
						Invoke-Expression "net use `"$locpath`""
						FNstatusbar "Path mapped. Loading Snippets now.. (This could take a moment)..." 1 ;  $form1.refresh()
					}
					if ($locpath -eq $snippetDefaultPath){ 
							$subrootnode = New-Object System.Windows.Forms.TreeNode
							$subrootnode.text = "PG Snippetpath"
							$subrootnode.name = $locpath
							$subrootnode.ToolTipText ="$locpath  (Snippets in this path will appear in the PowerGUI snippet menu.)"
							$subrootnode.tag = "root", "rootPG","RW"
							[void]$rootnode.Nodes.Add($subrootnode)	
							$treeview1.refresh()
							$rootnode.Expand() 
							$subrootnode.ContextMenuStrip = $RootContextMenu
							$subrootnode.ImageIndex = 10
							$subrootnode.SelectedImageIndex = 10
							$script:dirobjcount = 0
							$script:ispgpath = 1
							FNaddsubnodes $locpath $subrootnode
							$script:ispgpath = 0
							$script:creatorTree =  1
							$defaultpathnode = $subrootnode
					}
					else {                    
							$subrootnode = New-Object System.Windows.Forms.TreeNode
							$pathsplit = $locpath.split("\")
							if ( $pathsplit.length -gt 3 ) { 
								if ( $locpath.startswith("\\") -eq $true  ) { 
									$subrootnode.text = "\\"+$pathsplit[2]+"\...\"+$pathsplit[-2]+"\"+$pathsplit[-1] 
								}
								else { $subrootnode.text = (Split-Path $locpath -Qualifier)+"\...\"+$pathsplit[-2]+"\"+$pathsplit[-1] 
								}
							}
							else {$subrootnode.text = $locpath
							}	
							$subrootnode.name = $locpath
							if ( (FNcheckWriteAccess $locpath)  -eq 2 ) {
								$subrootnode.ToolTipText = $locpath+" (The current user has no write access to this path.)"
								$subrootnode.tag = "root", "root0","RO"
								$subrootnode.ContextMenuStrip = $RootContextMenu
								$currentRootIsReadOnly = 1
							}
							else {
								$subrootnode.ToolTipText = $locpath
								$subrootnode.tag = "root", "root0","RW"
								$subrootnode.ContextMenuStrip = $RootContextMenu
								$currentRootIsReadOnly = 0
							}
							
							[void]$rootnode.Nodes.Add($subrootnode)	
							$treeview1.refresh()
							$rootnode.Expand() 
							
							# Add Icons and Subnodes if available
							if ( [system.io.directory]::exists("$locpath")) { 
								if ( $currentRootIsReadOnly -eq 1) {
										$subrootnode.ImageIndex = 8
										$subrootnode.SelectedImageIndex = 8
										$script:dirobjcount = 0
										FNaddsubnodes $locpath $subrootnode 1
								}
								else {
									$subrootnode.ImageIndex = 3
									$subrootnode.SelectedImageIndex = 3
									$script:dirobjcount = 0
									FNaddsubnodes $locpath $subrootnode
								}
								$script:creatorTree =  1
							}
							else { 
								$subrootnode.ImageIndex = 4
								$subrootnode.SelectedImageIndex = 4
								$subrootnode.ToolTipText = "Path: > $locpath < could not be found."
							}
					}
			}		
			$rootnode.Expand() 
			if ($locpathnum -eq 1 ) { $defaultpathnode.Expand() }
			$script:creatorTree =  0
		}	
		elseif ($treeIndex -eq 2){
			if ($firstbuild1 -eq 0) { $StoreTree1.Nodes.remove($rootnode1)}  # clear nodes
			$script:firstbuild1 = 0
			$script:rootnode1 = New-Object System.Windows.Forms.TreeNode
			$rootnode1.text = "Snippets"
			$rootnode1.tag = "root", "root1"
			$rootnode1.ImageIndex = 9
			$rootnode1.SelectedImageIndex = 9
			$rootnode1.ContextMenuStrip = $TreeviewUeberrootContextMenu
			[void]$StoreTree1.Nodes.Add($rootnode1)	
			# add snippet locations
			$locpath = $snippetDefaultPath
					$subrootnode = New-Object System.Windows.Forms.TreeNode
					$subrootnode.text = "PG Snippetpath"
					$subrootnode.name = $locpath
					$subrootnode.ToolTipText = $locpath
					$subrootnode.tag = "root", "root2"
					[void]$rootnode1.Nodes.Add($subrootnode)	
					$StoreTree1.refresh()
					$rootnode1.Expand() 
					$subrootnode.ContextMenuStrip =  $TreeviewUeberrootContextMenu
					if ( [system.io.directory]::exists("$locpath")) { 
						$subrootnode.ImageIndex = 10
						$subrootnode.SelectedImageIndex = 10
						FNaddStoreSubnodes $locpath $subrootnode $treeIndex
						$script:creatorTree =  1
					}
					else { 
						$subrootnode.ImageIndex = 4
						$subrootnode.SelectedImageIndex = 4
						$subrootnode.ToolTipText = "Path: > $locpath < could not be found."
					}	
			$rootnode1.Expand() 
			$subrootnode.Expand() 
			$script:creatorTree =  0
		}
		elseif ($treeIndex -eq 3) {
			if ($firstbuild2 -eq 0) { $StoreTree2.Nodes.remove($rootnode2)}  # clear nodes
			$script:firstbuild2 = 0
			$script:rootnode2 = New-Object System.Windows.Forms.TreeNode
			$rootnode2.text = "Snippets"
			$rootnode2.tag = "root", "root2"
			$rootnode2.ImageIndex = 9
			$rootnode2.SelectedImageIndex = 9
			$rootnode2.ContextMenuStrip = $TreeviewUeberrootContextMenu
			[void]$StoreTree2.Nodes.Add($rootnode2)	
			# add snippet locations
			$locpath = $snippetDefaultPath		
					$subrootnode = New-Object System.Windows.Forms.TreeNode
					$subrootnode.text = "PG Snippetpath"
					$subrootnode.name = $locpath
					$subrootnode.ToolTipText = $locpath
					$subrootnode.tag = "root", "root0"
					[void]$rootnode2.Nodes.Add($subrootnode)	
					$StoreTree2.refresh()
					$rootnode2.Expand() 
					$subrootnode.ContextMenuStrip =  $TreeviewUeberrootContextMenu
					if ( [system.io.directory]::exists("$locpath")) { 
						$subrootnode.ImageIndex = 10
						$subrootnode.SelectedImageIndex = 10
						FNaddStoreSubnodes $locpath $subrootnode $treeIndex
						$script:creatorTree =  1
					}
					else { 
						$subrootnode.ImageIndex = 4
						$subrootnode.SelectedImageIndex = 4
						$subrootnode.ToolTipText = "Path: > $locpath < could not be found."
					}
			$rootnode2.Expand() 
			$subrootnode.Expand() 
			$script:creatorTree =  0
	 }
	 $script:treepasteCUTobjectIndicator = 0
	 FNstatusbar "Ready." 
	$progressbar1.visible = $false

}

function FNaddsubnodes ($subdir, $parent,$readonly) {
			if (($dontAddlongPath -eq 1)-and($breakcurrentbuild -eq 1)) {return}
			$dirdata = dir $subdir
			foreach ( $obj in $dirdata ) { 
			if (($dontAddlongPath -eq 1)-and($breakcurrentbuild -eq 1)) {return}
			$script:dirobjcount++
			if (($dirobjcount -gt 5000) -and ( $dontAskManyObjects -ne 1)) {
					$askmess = "The current path has more than 5000 objects.`n`rIt could take some time to add the complete path. Also, very lare directories slow down file operations. (It's recommended to add only the folders with snippets in it.)`n`r`n`rDo you want to continue?"
					$askcont = [Windows.Forms.MessageBox]::Show($askmess, "SnippetManager", [Windows.Forms.MessageBoxButtons]::yesno, [Windows.Forms.MessageBoxIcon]::Question, [Windows.Forms.MessageBoxDefaultButton]::Button2 )
					if( $askcont -eq [System.Windows.Forms.DialogResult]::NO ) {  $script:dontAddlongPath = 1 ; $script:breakcurrentbuild = 1 ;return }
					else {$script:dontAskManyObjects = 1 }
			}
			$progressBar1.PerformStep() ; $progressBar1.Update()
			if  ($progressBar1.Value -eq $progressBar1.maximum) { $progressBar1.Value = 0 } 
						if ($obj.PSiscontainer) {																																		#### Dirs
								$subnode = New-Object System.Windows.Forms.TreeNode
								$subnode.text = $obj.basename
								$subnode.name  = $obj.FullName																								# Save fullpathname in node-name for later
								if ( $readonly -eq 1) {	$subnode.tag = "Dir","Dir","RO" }
								 else  {	$subnode.tag = "Dir","Dir","RW" }
						   	$subnode.ContextMenuStrip = $FolderContextMenu 
								if ($ispgpath -eq 1) {
									$subnode.ImageIndex = 11
									$subnode.SelectedImageIndex = 11
								}
								else{
									$subnode.ImageIndex = 1
									$subnode.SelectedImageIndex = 1
								}
								[void]$parent.Nodes.Add($subnode)
								if ( (Get-ChildItem $obj.PSpath) -and ( $readonly -eq 1) ) { FNaddsubnodes $obj.PSpath $subnode 1}	
								if ( (Get-ChildItem $obj.PSpath) -and ( $readonly -ne 1) ) { FNaddsubnodes $obj.PSpath $subnode 0}				# for all Dirs which are not empty look for Subdirs and files
						}
						else {                                      																															 #### Files
								if ( $obj.Extension -eq ".snippet" ) {																									 # Filter non *.snippet files
									$subnode = New-Object System.Windows.Forms.TreeNode
									$subnode.text = $obj.basename          																						# Add Name without Extension
									$subnode.name  = $obj.FullName																								# Save fullpathname in node-name for later
									if ( ($subnodetooltips -eq 1) -or ($FullTextIndexing -eq  1)  ) { $snippetXmlData = [xml](Get-Content $subnode.name ) }
									if ($subnodetooltips -eq 1) {
										$subnode.ToolTipText  = $snippetXmlData.CodeSnippets.CodeSnippet.Header.Description								
									}
									else {$subnode.ToolTipText  = ""  }
									if ( $readonly -eq 1) {	$nodetagtext = "RO"}
								 		else  {	$nodetagtext = "RW" }
									if ($FullTextIndexing -eq  1) {
										$subnode.tag = "File","File",$nodetagtext,$snippetXmlData.CodeSnippets.CodeSnippet.Header.Title,$snippetXmlData.CodeSnippets.CodeSnippet.Header.Author,($snippetXmlData.CodeSnippets.CodeSnippet.Snippet.Code.get_FirstChild().get_Data()),($snippetXmlData.CodeSnippets.CodeSnippet.Header.Description)
									}
									else {
										$subnode.tag = "File","nocode",$nodetagtext
									}
									$subnode.ImageIndex =0
									$subnode.SelectedImageIndex = 0
									[void]$parent.Nodes.Add($subnode)
								} 
						}			
				}
	 }
	    	  	 	
function FNaddStoreSubnodes ($subdir, $parent,$treeInd) {
			$dirdata = dir $subdir
			foreach ( $obj in $dirdata ) { 
					if (($obj.PSiscontainer) -and (Get-ChildItem $obj.PSpath)) {								#### Dirs
							$subnode = New-Object System.Windows.Forms.TreeNode
							$subnode.text = $obj.basename
							$subnode.name  = $obj.FullName																								# Save fullpathname in node-name for later
							$subnode.tag = "Dir","Dir","RW" 
					   	$subnode.ContextMenuStrip =  $TreeviewUeberrootContextMenu
							$subnode.ImageIndex = 11
							$subnode.SelectedImageIndex = 11
							[void]$parent.Nodes.Add($subnode)
							FNaddStoreSubnodes $obj.PSpath $subnode $treeInd
					}
					#
					 #### Files
					if ( ( $obj.Extension -eq ".snippet" ) -and ($treeInd -eq 2)) {																									 # Filter non *.snippet files
								$subnode = New-Object System.Windows.Forms.TreeNode
								$subnode.text = $obj.basename          																						# Add Name without Extension
								$subnode.name  = $obj.FullName																								# Save fullpathname in node-name for later
								$subnode.ContextMenuStrip =  $TreeviewUeberrootContextMenu
								if ( ($subnodetooltips -eq 1) -or ($FullTextIndexing -eq  1)  ) { $snippetXmlData = [xml](Get-Content $subnode.name ) }
								if ($subnodetooltips -eq 1) {
									$subnode.ToolTipText  = ($snippetXmlData.CodeSnippets.CodeSnippet.Snippet.Code.get_FirstChild().get_Data())								
								}
								else {$subnode.ToolTipText  = ""  }
							
								$subnode.tag = "File","nocode"
								
								$subnode.ImageIndex =0
								$subnode.SelectedImageIndex = 0
								[void]$parent.Nodes.Add($subnode)
					} 
						
			          #### Files
				if (( $obj.Extension -eq ".NAsnippet" ) -and ($treeInd -eq 3)) {				
						$subnode = New-Object System.Windows.Forms.TreeNode
						$subnode.text = $obj.basename          																						# Add Name without Extension
						$subnode.name  = $obj.FullName																								# Save fullpathname in node-name for later
						$subnode.ContextMenuStrip =  $TreeviewUeberrootContextMenu
						if ( ($subnodetooltips -eq 1) -or ($FullTextIndexing -eq  1)  ) { $snippetXmlData = [xml](Get-Content $subnode.name ) }
						if ($subnodetooltips -eq 1) {
									$subnode.ToolTipText  = ($snippetXmlData.CodeSnippets.CodeSnippet.Snippet.Code.get_FirstChild().get_Data())								
						}
						else {$subnode.ToolTipText  = ""  }
							
						$subnode.tag = "File","nocode"
						$subnode.ImageIndex =2
						$subnode.SelectedImageIndex = 2
						[void]$parent.Nodes.Add($subnode)
				} 
				
		}
				FNstatusbar "Ready."
	 }
					
function FNtreeDoubleclick( $object ){
		$Form1.TopMost = $true
		if (( $expltype -eq "dirRO") -or ( $expltype -eq "dir") -or ( $expltype -eq "root")) { return }   #Dir? Then back
		### Ask before overwrite
		if (($changed -eq 1) -and ($saved -ne 1) ) { 
			if ( (FNasktosave "cc") -eq "cancel") {return}
		}
	#	 Write-Debug $nodeobject.text"  "$nodeobject.level     ############debug
   
	#### Load Code
	 $snippetXmlData = [xml](Get-Content $explobj.name )
	 $script:code = $snippetXmlData.CodeSnippets.CodeSnippet.Snippet.Code.get_FirstChild().get_Data()
	 
	### Load Variables
	 ## Header
	 $TBSnippetTitle.Text = $snippetXmlData.CodeSnippets.CodeSnippet.Header.Title
	 $TBsnippetDescription.Text = $snippetXmlData.CodeSnippets.CodeSnippet.Header.Description
	 $TBsnippetAuthor.Text = $snippetXmlData.CodeSnippets.CodeSnippet.Header.Author
	 
	 ## Placeholders
	 $LVplaceholders.Items.clear()
	 $declarations =  $snippetXmlData.CodeSnippets.CodeSnippet.Snippet.Declarations.Literal
	if ($declarations) {
		foreach ($literal in $declarations) { 
			$ID = $literal.ID
			$Default = $literal.Default
			$Tooltip = $literal.Tooltip
			$ListViewItem = New-Object System.Windows.Forms.ListViewItem([System.String[]](@($ID, $Default,$Tooltip)), -1)
			$LVplaceholders.Items.AddRange([System.Windows.Forms.ListViewItem[]](@($ListViewItem)))
			# Write-Debug " >>> $ID, $Default,$Tooltip"
		}
	 }
	 
	 FNsyntaxcoloring $code
	 if ($explobj.tag[1] -eq "searchresultcode") { FNHighlighttext $SearchSnippetInputBox.Text 0 0 } # Highlight Searchtext in code when snippet opened from searchresultnode
	 FNstatusbar ("Snippet: '"+$explpath+"' loaded.")
	 $script:changed = 0
	 $script:saved = 0
	 $script:snippetloaded = 1
	 $script:loadedsnipfullpath = $explobj.name
	 $script:lastSnippetDir = Split-Path $loadedsnipfullpath
}


#endregion


#region --- Snippet/Textbox Functions ######

function FNcheckforforbiddenchars ($inputstring,$dircheck) {  
	 if ($dircheck -eq 1) {
	 		$script:filters =  "\","/",":","`"","*","?","<",">","|","'"
	 	 }
	  else {   
	 		$script:filters =  "!","`"","%","&","/","\","(",")","=",".",",","`'","=","[","]","{","}","?","*","+","#",";"
	 }
	 $parser = $inputstring.getEnumerator()
	 foreach ($char in $parser) {
			foreach ($filter in $filters){
				if ($char -eq $filter) {
				return 1
				}
			}
	}
   return 0
}

function FNcleartextbox( $object ){
	$RichTextBox1.text = "" #Clear()
}

function FNredo( $object ){
	$RichTextBox1.redo()
	$script:changed = 1
	$script:saved = 0
}

function FNundo( $object ){
		if ( $UNDOautocreate -eq 1 ) {
			FNsyntaxcoloring $undotextbox
			$undoListviewItem.remove()
			$script:UNDOautocreate = 0
		}
		else { $RichTextBox1.undo() }

		$script:changed = 1
		$script:saved = 0
}

function FNresizeFont( $object ){
	$RichTextBox1.ZoomFactor = ($Zoombar.Value / 10)
}

function FNpaste( $object ){
 	$RichTextBox1.Paste()
 	$reparsetext = $RichTextBox1.text
	FNsyntaxcoloring $reparsetext
	FNstatusbar "Ready."
}

function FNPasteGeneral( $object ){
	$object.Paste()
	FNstatusbar "Ready."
}

function FNcopy {
	$RichTextBox1.Copy()
}

function FNsyntaxcoloring ($content) { 

			$richtextbox1.visible = $false
			FNcleartextbox 
			$RichTextBox1.selectedtext =$content 
			$RichTextBox1.deselectall()
						
			$RichTextBox1.ZoomFactor 
			FNresizeFont
			
		 do  {  
			$erg = $RichTextBox1.find("$",$erg,"none") 
			$RichTextBox1.SelectionColor = "#68441E"
			$erg = $erg +1
		} while ( ($erg -gt 0) -and ($erg -lt ($RichTextBox1.TextLength)) )
		$RichTextBox1.deselectall() ; $erg = 0
				
		$blue = "Function","If","Else","Foreach","-","="
		foreach ($word in $blue) {
			do  {  
				$erg = $RichTextBox1.find($word,$erg,"none") 
				$RichTextBox1.SelectionColor = "#0000FF"
				$erg = $erg +1
			} while ( ($erg -gt 0) -and ($erg -lt ($RichTextBox1.TextLength)) )
		}
		$RichTextBox1.deselectall(); $erg = 0
				
		$brackets = "(","{",")","}"
		foreach ($word in $brackets) {
			do  {  
				$erg = $RichTextBox1.find($word,$erg,"none") 
				$RichTextBox1.SelectionColor = "#B50000"
				$erg = $erg +1
			} while ( ($erg -gt 0) -and ($erg -lt ($RichTextBox1.TextLength)) )
		}
		$RichTextBox1.deselectall(); $erg = 0
		
		foreach ($placeholder in $LVplaceholders.items) { 
		$findPLH = "$"+$placeholder.Subitems[0].text+"$"
			do  {  
				$erg = $RichTextBox1.find($findPLH,$erg,"none") 
				$RichTextBox1.SelectionColor = "#B84D00"
				$erg = $erg +1
			} while ( ($erg -gt 0) -and ($erg -lt ($RichTextBox1.TextLength)) )
		}
		$RichTextBox1.deselectall(); $erg = 0
		
		$green = "`$End`$","`$Selected`$"
		foreach ($word in $green) {
			do  {  
				$erg = $RichTextBox1.find($word,$erg,"none") 
				$RichTextBox1.SelectionColor = "#852500"
				$erg = $erg +1
			} while ( ($erg -gt 0) -and ($erg -lt ($RichTextBox1.TextLength)) )
		}
		$RichTextBox1.deselectall(); $erg = 0

		# Remarks 
		 do  {  
			$erg = $RichTextBox1.find("#",$erg,"none")  
			if ($erg -eq -1) { break }
			$pos2 = $RichTextBox1.find("`r",($erg+1),"none") 
			if ($pos2 -eq -1) {
				$RichTextBox1.select($erg,($RichTextBox1.TextLength)) 
			}
			else {
				$RichTextBox1.select($erg,($pos2-$erg)) 
			}
			$RichTextBox1.SelectionColor = "#006500"
			$erg = $erg +1
			$RichTextBox1.deselectall()
		} while ( ($erg -gt 0) -and ($erg -lt ($RichTextBox1.TextLength)) )

		$RichTextBox1.deselectall() ; $erg = 0
		 do  {  
			$erg = $RichTextBox1.find("<#",$erg,"none")  
			if ($erg -eq -1) { break }
			$pos2 = $RichTextBox1.find("#>",($erg+1),"none") 
			$RichTextBox1.select($erg,($pos2-$erg)) 
			$RichTextBox1.SelectionColor = "#006500"
			$erg = $erg +1
			$RichTextBox1.deselectall()
		} while ( ($erg -gt 0) -and ($erg -lt ($RichTextBox1.TextLength)) )
		
		
	$RichTextBox1.deselectall()
	$richtextbox1.visible = $true
		
}
	 	 
function FNautoCreatePlaceholder( $object,$manualname ){
   $script:undotextbox = $richtextbox1.text # save textbox for undo
	
	$selectedtext = $RichTextBox1.selectedtext.Trim()
	
	if (  ($RichTextBox1.selectedtext -replace "\s","")  -eq "" ) { FNstatusbar "You need to select a text to create a placeholder out of it." 2 ; return }  # filter for tabs,spaces, creturns
	if ($manualname) { $newPLHname = $manualname -replace "\`$","" }
	 else { $newPLHname = ($RichTextBox1.selectedtext -replace "\`$","") -replace "\s","" }  # filter for $ ,tabs,spaces, creturns
	if ((FNcheckdoublePLH $newPLHname) -eq "exist" ) {FNhalfautocreatePlaceholder ; return }  # check if PLHname already exists
	 
	$newPLHdefault = (($RichTextBox1.selectedtext.Trim() -replace "\t","") -replace "\n","") # filter for tabs, creturns
	$newPLHinSnippetReplacement = '$'+$newPLHname+'$'
	# Write-Debug "newPLHname <$newPLHname> `n  newPLHdefault <$newPLHdefault> `n newPLHinSnippetReplacement <$newPLHinSnippetReplacement> "
	
	## add to listview
	$ListViewItem = New-Object System.Windows.Forms.ListViewItem([System.String[]](@($newPLHname, $newPLHdefault,$emptyitem)), -1)
	$LVplaceholders.Items.AddRange([System.Windows.Forms.ListViewItem[]](@($ListViewItem)))
	$script:undoListviewItem = $ListViewItem
	
	## replace text in snippet with $xyz$ and pass it to highligting
	$replacetext = ($RichTextBox1.text).replace($selectedtext,$newPLHinSnippetReplacement)

	FNsyntaxcoloring $replacetext		
	FNHighlighttext $newPLHinSnippetReplacement 0 1
	#Write-Debug ">>>$replacetext<<<<"
	FNstatusbar ("Placeholder created. Every created instance of  $"+$newPLHname+"$  has been marked, please review them.") 1
   $script:changed = 1
	$script:UNDOautocreate = 1  # undo is available
}

function FNhalfautocreatePlaceholder( $object ){
		$Pos = [System.Windows.Forms.Cursor]::Position
		$Inputbox.Text = ""
		$dialog.text = "Please enter a name for the new placeholder:"
		$dialog.left = ( $pos.x-160)      
		$dialog.top = ($pos.y)   
		$script:Dialogresult = ""
		$Dialog.ShowDialog() 
		if ($Dialogresult -eq "ok"){
				$manualPLHname = $Inputbox.Text.Trim() -replace "\s",""
				if ($manualPLHname -eq "") { 
					Fnstatusbar "The name of the placeholder can not be empty." 2 
					return
				}
				if ((FNcheckdoublePLH $manualPLHname) -eq "exist" ) {FNhalfautocreatePlaceholder ; return }  # check if PLHname already exists
				FNautoCreatePlaceholder "" $manualPLHname	
		}
}

function FNmanualPlaceholder {
		$Pos = [System.Windows.Forms.Cursor]::Position
		$Inputbox.Text = ""
		$dialog.text = "Please enter a NAME for the new placeholder:"
		$dialog.left = ( $pos.x-160)      
		$dialog.top = ($pos.y)   
		$script:Dialogresult = ""
		$Dialog.ShowDialog() 
		if ($Dialogresult -eq "ok"){
			$manualPLHname = $Inputbox.Text.Trim() -replace "\s",""
			if ($manualPLHname -eq "") { 
				Fnstatusbar "The name of the placeholder can not be empty." 2 
				return
			}
			if ((FNcheckdoublePLH $manualPLHname) -eq "exist" ) {FNmanualPlaceholder ; return }  # check if PLHname already exists
			$dialog.text = "Please enter a DEFAULT VALUE for the new placeholder:"
			$script:Dialogresult = ""
			$Inputbox.Text = ""
			$Dialog.ShowDialog() 
			if ($Dialogresult -eq "ok"){ $manualPLHdefaultV = $Inputbox.Text }
			if (($Inputbox.Text  -eq "") -or ($Dialogresult -ne "ok")) { $manualPLHdefaultV ="Enter a default value"	}
		
			$ListViewItem = New-Object System.Windows.Forms.ListViewItem([System.String[]](@($manualPLHname,$manualPLHdefaultV," ")), -1)
			$LVplaceholders.Items.AddRange([System.Windows.Forms.ListViewItem[]](@($ListViewItem)))
			$TBclipboard.Text = ("$"+$manualPLHname+"$")
			$TBclipboard.selectall()
			$TBclipboard.copy()
			$TBclipboard.Text = ""
			FNHighlighttext $manualPLHdefaultV 0 0 
			FNstatusbar "Placeholder created and copied to the clipboard. Paste it to every line in the snippet where you want the placeholder to appear later." 1		
			$script:changed = 1
			$script:saved = 0		
	}		
}

function FNcheckdoublePLH ($PLHname){
	foreach ($placeholder in $LVplaceholders.items) {
		if (($placeholder.Subitems[0].text).equals($PLHname)) {
		FNstatusbar "A Placholder with that name already exist. Please choose another one. (placeholder names are case sensitive)" 2
		return "exist"	 
		}
	}
}

function FNdeletePlaceholder {
		if (-not $LVplaceholders.SelectedItems[0]) { return }
		
		$delitemPlhName = $LVplaceholders.SelectedItems[0].text
		$delitemDefaultVal = $LVplaceholders.SelectedItems[0].subitems[1].text
		FNHighlighttext ('$'+$delitemPlhName+'$') 0 1
		$messtext = "Are you sure you want to delete the placeholder: `""+$delitemPlhName+"`"?`n`r`n`rEvery instance of `"`$"+$delitemPlhName+"`$`" in the snippet will be`n`rreplaced with `""+$delitemDefaultVal+"`".`n`r`n`rThis can only be undone by creating a new placeholder."
		$ask = [Windows.Forms.MessageBox]::Show($messtext,"SnippetManager",[Windows.Forms.MessageBoxButtons]::yesno, [Windows.Forms.MessageBoxIcon]::Question)
		
		if( $ask -eq [System.Windows.Forms.DialogResult]::YES ) {   
		   $LVplaceholders.SelectedItems[0].remove()
			$delitemPlhName = '$'+$delitemPlhName+'$'
			# $replacetext =[regex]::replace($RichTextBox1.text,$delitemPlhName,$delitemDefaultVal)
			$replacetext = ($RichTextBox1.text).replace($delitemPlhName,$delitemDefaultVal)
			FNsyntaxcoloring $replacetext		
			FNHighlighttext $delitemDefaultVal 0 1
			FNstatusbar "Placeholder removed." 1
			$script:changed = 1
	}	
}

function FNcopyPLHname( $object ){
	$TBclipboard.Text = ("$"+$LVplaceholders.SelectedItems[0].text+"$")
	$TBclipboard.selectall()
	$TBclipboard.copy()
	$TBclipboard.Text = ""
}

function FNeditPLH  {
			  $hti = $LVplaceholders.HitTest($_.X, $_.Y).Subitem
			  $itemindex = $LVplaceholders.HitTest($_.X, $_.Y).Item.SubItems.IndexOf($hti)  # Get Subitem IndexNO
			  $Inputbox.text = $hti.Text   # Get Subitem Text
			  $oldPLHname = $hti.Text
			  
			  $Pos = [System.Windows.Forms.Cursor]::Position
			  $dialog.text = "Placeholder edit (ENTER to accept / ESC to cancel)"
			  $dialog.left = ( $pos.x -50)      # Dialogbox positionieren
			  $dialog.top = ($pos.y)   
			  $script:Dialogresult = ""
			  $Dialog.ShowDialog() 
			  if ($Dialogresult -eq "ok"){
					if ( $itemindex -eq 0  ){    # if PLH name change
						$newPlhName = (($Inputbox.Text).Trim()) -replace "\s",""
						if ($newPlhName -eq "") { 
							Fnstatusbar "The name of the placeholder can not be empty." 2 
							return
						}
						if ( $newPlhName -eq $LVplaceholders.HitTest($_.X, $_.Y).Subitem.Text ) { return } 
						if ((FNcheckdoublePLH $newPlhName) -eq "exist" ) {FNeditPLH ; return }  # check if PLHname already exists
						$LVplaceholders.HitTest($_.X, $_.Y).Subitem.Text = $newPlhName
						$newPlhName = '$'+$newPlhName+'$'
						$oldPLHname = '$'+$oldPLHname+'$'
						$replacetext = ($RichTextBox1.text).replace($oldPLHname,$newPlhName)
						FNsyntaxcoloring $replacetext		
						FNHighlighttext $newPlhName 0 1
					}
					else { $LVplaceholders.HitTest($_.X, $_.Y).Subitem.Text = $Inputbox.Text }
					$script:changed = 1
					$script:saved = 0
			  }
			 FNstatusbar "Ready." 
}

function FNplaceSelectedMarker( $object ){
 	$regex = [regex]"(?i)\`$selected\`$"   # search for $selected$ (?i) = case insensitive
	if ( ($regex.Matches($RichTextBox1.text)).count -ge 1 ) { 
		FNHighlighttext "`$selected`$" 1
		FNstatusbar 'You already have a "$selected$"-marker in the snippet. Please delete the old one first.' 2
	}
	else {$RichTextBox1.selectedtext = '$selected$'
	FNstatusbar "Ready." 
	}	
}

function FNPlaceEndMarker( $object ){	
	$regex = [regex]"(?i)\`$end\`$"   # search for $selected$ (?i) = case insensitive
	if ( ($regex.Matches($RichTextBox1.text)).count -ge 1 ) { 
		FNHighlighttext "`$end`$" 1
		FNstatusbar 'You already have a "$end$"-marker in the snippet. Please delete the old one first.' 2
	}
	else {$RichTextBox1.selectedtext = '$end$'
	FNstatusbar "Ready." 
	}
}

function FNHighlightPLHs ($PLHstring) { 
	$hti = $LVplaceholders.HitTest($_.X, $_.Y).subitem
	$itemindex = $LVplaceholders.HitTest($_.X, $_.Y).Item.SubItems.IndexOf($hti)
	
	if ( $itemindex -eq 2 ){ return	}
	if ( $itemindex -eq 0 ){  $searchstringPLH = ('$'+$hti.Text+'$')	}
		else { $searchstringPLH = $hti.Text }
	
	if ($searchstringPLH.trim() -eq "") { return }
	FNHighlighttext $searchstringPLH
 	FNstatusbar "Ready." 
}

function FNHighlighttext ($hlText,$warn,$casesensitive) {
   if ($changed -eq 1) {$override = 1} # prevent "changed"-Event due to new highlighting
	
	#$RichTextBox1.hideselection = $true
	$RichTextBox1.selectall()
	$RichTextBox1.SelectionBackColor = "#FBFBFD"
	$RichTextBox1.deselectall()
	#$RichTextBox1.hideselection = $false
	
	if ($warn -eq 1) { $hlCol = "#FFE5A9"  }
		  else { $hlCol = "#FFE5A9" }  # gray: #DBDBDB # yellow #FFED9D
	if ($casesensitive -eq 1) { $options = "MatchCase" }
		  else { $options = "none" }	
	
	do  {
		$erg = $RichTextBox1.find($hlText,$erg,$options) 
		$RichTextBox1.SelectionBackColor = $hlCol 
		$erg = $erg +1
	} while ($erg -gt 0)

	$RichTextBox1.deselectall()
	if ($override -ne 1){ $script:changed = 0 }
}

function FNsearch {
			  $Pos = [System.Windows.Forms.Cursor]::Position
			  $dialog.text = "Please enter a search string:"
			  $dialog.left = ( $pos.x -50)      
			  $dialog.top = ($pos.y +10)   
			  $script:Dialogresult = ""
			  $Dialog.ShowDialog() 
			  if ($Dialogresult -eq "ok"){
		 	  FNHighlighttext $Inputbox.Text 0 0  				
			  }
			  FNstatusbar "Ready." 
}

function FNSaveSnippet( $savemode ){
	# savemode 1 = save  / 2 = save as
   ### Filter forbidden filename chars and suggest filename
	$suggestedfilename = $TBSnippetTitle.Text.Trim() 
	$forbiddenchars = "\\","\/",":","\`"","\`*","\?","<",">","\|","\`'"
	foreach ($forbiddenchar in $forbiddenchars) {
		$suggestedfilename = $suggestedfilename -replace $forbiddenchar, ""
	}
	if ($suggestedfilename -eq "") {
		Fnstatusbar "Please enter a name for the snippet. This name will be displayed in the snippet menu in PowerGUI Script Editor." 2
		return "Cancel"
	}
	if ($savemode -eq 2 ){ 
		if ($expltype -eq "File") { $savepath = Split-Path $explpath }
		 else { $savepath = $explpath }
		$SaveFileDialog1.FileName = "$savepath\$suggestedfilename"
		$SaveFileDialog1.InitialDirectory = "$savepath"
	}		
	else {
	  	$SaveFileDialog1.FileName = "$lastSnippetDir\$suggestedfilename"
		$SaveFileDialog1.InitialDirectory = "$lastSnippetDir"
	}
	
	if (($savemode -eq 1 ) -and ($snippetloaded -eq 1) ){
			$filename = $loadedsnipfullpath
			$dontrefresh =  1
	}
	else {
		### show dialog
		$result = $SaveFileDialog1.showdialog()
		if ($result -ne "OK" ){ 
				FNstatusbar "Ready."
				return "Cancel"	}
		$filename = $SaveFileDialog1.FileName  
		## check for overwrite
		if ( [system.io.file]::exists("$filename") ){ 
			$askoverw = [Windows.Forms.MessageBox]::Show("The file $filename already exists, do you want to continue?", "SnippetManager", [Windows.Forms.MessageBoxButtons]::yesno, [Windows.Forms.MessageBoxIcon]::Question)
			if ($askoverw -ne [System.Windows.Forms.DialogResult]::YES) { 
		   	$dontrefresh =  1
				FNSaveSnippet $savemode
				return }
		}	
	}
    
	### create XML
		$newXML = [xml]'<?xml version="1.0" encoding="utf-8"?><CodeSnippets><CodeSnippet><Header><SnippetTypes><SnippetType>Expansion</SnippetType><SnippetType>SurroundsWith</SnippetType>
</SnippetTypes></Header><Snippet><Declarations></Declarations><Code></Code></Snippet></CodeSnippet></CodeSnippets>'
		
		$newXML.CodeSnippets.SetAttribute("xmlns","http://schemas.microsoft.com/VisualStudio/2005/CodeSnippet")
		$newXML.CodeSnippets.CodeSnippet.SetAttribute("Format","1.0.0")
		$newXML.CodeSnippets.CodeSnippet.Snippet.SelectSingleNode("Code").SetAttribute("Language","powershell")
		
	### Put Header in 
		$headerelements = "Title","ShortCut","Description","Author"
		$headertexts = $TBSnippetTitle.Text,$TBSnippetTitle.Text,$TBsnippetDescription.Text,$TBsnippetAuthor.Text
		$i= 0
		foreach ($headerelement in $headerelements) {
			$element = $newXML.CreateElement($headerelement) 
			$element.psbase.InnerText = $headertexts[$i]
			$newXML.CodeSnippets.Codesnippet.SelectSingleNode("Header").AppendChild($element)
			$i++
		}

	### Put Placeholders in
		## Create 'Literal' Node for each Placeholder in the Listview
		foreach ($placeholder in $LVplaceholders.items) {
			$node = $newXML.CreateElement("Literal") 
			$newnode = $newXML.CodeSnippets.Codesnippet.Snippet.SelectSingleNode("Declarations").AppendChild($node)

			## Put Elements in Literalnodes
			$literalElements = "ID","Default","ToolTip"
			$literaltexts = $placeholder.Subitems[0].text,$placeholder.Subitems[1].text,$placeholder.Subitems[2].text
			$i= 0
			foreach ($literalElement in $literalElements) {
				$element = $newXML.CreateElement($literalElement) 
				$element.psbase.InnerText = $literaltexts[$i]
				$newnode.AppendChild($element)
				$i++
			}
		}
	### Put Code in 
		$newXML.CodeSnippets.Codesnippet.Snippet.SelectSingleNode("Code").AppendChild( $newXML.CreateCDataSection($RichTextBox1.text) )
		
	### save and check XMLfile
		try  { $newXML.save("$filename")}
		catch {FNstatusbar "Snippet could not be saved! (Check if you have write access to this path.)" 3 
		 return "Cancel" }
		
		if ( [system.io.file]::exists("$filename") ){  		
			$script:changed = 0
			$script:saved = 1
			if ($dontrefresh -ne 1) {
				FNbuildtree 1 }
			FNexpandNode $rootnode $filename
			FNstatusbar ("Snippet: '"+$filename+"' saved.") 1
			return "OK"
		}
		else { FNstatusbar "Snippet could not be saved!" 3 
		 return "Cancel"
		}

}

#endregion


#region --- StoreRoom - Functions ######

function FNstorageRefresh( $object ){
  if ($storebuiltinitial -ne 1) {
  $form1.refresh()
  ### load Dirs
	FNbuildtree 2	
	FNbuildtree 3
	$script:storebuiltinitial = 1
	}
}

function FNTreeExpandall( $tv ){
	if ($tv -eq 1) { $rootnode1.Expandall() }
	if ($tv -eq 2) { $rootnode2.Expandall() }
}

function FNstoreNodechecked( $nodeobject,$state ){	
   if ($script:autocheckrunning -eq 1) { return }
	$script:autocheckrunning = 1	
	if (($state -eq "true") -and ($nodeobject.tag[0] -ne "File")  ) {
			FNstoreCheckAllSubNodes $nodeobject
	}	
	if (($state -eq "false") -and ($nodeobject.tag[0] -ne "File")  ) {
 		   FNstoreUNCheckAllSubNodes $nodeobject
	}	
	$script:autocheckrunning = 0
}

function FNstoreCheckAllSubNodes ($nodeobj) {
	 foreach ($n in $nodeobj.Nodes){
		   	$n.Checked = $True		
			if ($n.Nodes.Count -ne 0) {
				  FNstoreCheckAllSubNodes $n
			}
		}
}

function FNstoreUNCheckAllSubNodes ($nodeobj) {
	 foreach ($n in $nodeobj.Nodes){
		   	$n.Checked = $False		
			if ($n.Nodes.Count -ne 0) {
				  FNstoreUNCheckAllSubNodes $n
			}
		}
}

function FNmoveToStorage ($object) {
	$script:storeerror = 0
	$error.clear()
   foreach ($node in $storetree1.Nodes) {
		FNrenamecheckedNodes $node 1
	}
	$storebuiltinitial = 0 ; FNstorageRefresh
	$script:storeChanged = 1
	if ($storeerror -eq 0) {
		FNstatusbar "Snippets deactivated. Folders without active snippets will still show up in the snippet explorer here, but in PowerGUI they won't." 1
	}
	else {
		FNstatusbar "Not all snippets could be deactivated. Please check if there are already deactivated snippets with the same name." 3
	}
}

function FNmoveToActive( $object ){
	$script:storeerror = 0
	$error.clear()
   foreach ($node in $storetree2.Nodes) {
		FNrenamecheckedNodes $node 2
	}
	$storebuiltinitial = 0 ; FNstorageRefresh
	$script:storeChanged = 1
	if ($storeerror -eq 0) {
		FNstatusbar "Snippets activated." 1
	}
	else {
		FNstatusbar "Not all snippets could be activated. Please check if there are already active snippets with the same name." 3
	}
}

function FNtabSwitch( $object ){
	if ($storeChanged -eq 1) {
	 $form1.refresh()
	  FNbuildtree 1
	  $script:storeChanged = 0
	} 
}

function FNrenamecheckedNodes ($node,$mode){
    foreach ($n in $Node.Nodes){
			if (($n.Checked -eq $true) -and ($n.tag[0] -eq "File")) {
			 	if ($mode -eq 1) {
					$oldname = $n.name
					$newname = ((Split-Path "$oldname")+"\"+$n.Text+".NAsnippet")
					 Rename-Item  $oldname $newname 
					if ($error ) { $script:storeerror = 1 }
				}
				if ($mode -eq 2) {
					$oldname = $n.name
					$newname = ((Split-Path "$oldname")+"\"+$n.Text+".snippet")
					 Rename-Item  $oldname $newname 
					if ($error) { $script:storeerror = 1 } 
				}
			}
			if ($n.Nodes.Count -ne 0)  { FNrenamecheckedNodes $n $mode}
	 }
}

#endregion

Main # This call must remain below all other event functions

#endregion


	 
	 
	 
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzLyRi/NykagrDcxSdoRCqbR1
# LQ6gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFuwlxElEE0AatJ1
# 037o/QsoiRhSMA0GCSqGSIb3DQEBAQUABIIBAGsoLTqyAQ7FnkF+na8qXwtXpIAY
# LssJZbdBC54aW9f1EHHe8io0A5QnWUC33XNdLZX/PEgZpK0gzv2QhCxGXAJi4jHL
# ofieukq5OO92gOhToN8dBF/DKaB8WmaqHR4lV8qBeskXpRiV/uny1mUcIbyE+3xa
# JnupYaSGYHZ2lkWxXK0zleS/nMS8hbt32ny/W+E1hAgQWHLStCImyniF9GdO0gcp
# nFmeVxf/m/iYJOzeYhIidWqq2hEn98NWPLEgaXCzw2+c8iaCc8G9QTw1+OEo1tfj
# k+mVG7zn53o/QBwcSt6ZfuXz2lDn1EJI8amexm1F99zYssv6H1pDpdNjxck=
# SIG # End signature block
