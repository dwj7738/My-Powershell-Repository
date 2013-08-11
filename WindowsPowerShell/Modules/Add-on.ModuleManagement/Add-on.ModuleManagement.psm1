#######################################################################################################################
# File:             Add-on.ModuleManagement.psm1                                                                      #
# Author:           Kirk Munro                                                                                        #
# Publisher:        Quest Software, Inc.                                                                              #
# Copyright:        © 2010 Quest Software, Inc. All rights reserved.                                                  #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.ModuleManagement module.                                                      #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this command:         #
#                       Import-Module -Name Add-on.ModuleManagement                                                   #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
#######################################################################################################################

Set-StrictMode -Version 2

#region Initialize the Script Editor Add-on.

if ($Host.Name –ne 'PowerGUIScriptEditorHost') { return }
if ($Host.Version -lt '2.1.1.1202') {
	[System.Windows.Forms.MessageBox]::Show("The ""$(Split-Path -Path $PSScriptRoot -Leaf)"" Add-on module requires version 2.1.0.1200 or later of the Script Editor. The current Script Editor version is $($Host.Version).$([System.Environment]::NewLine * 2)Please upgrade to version 2.1.0.1200 and try again.","Version 2.1.0.1200 or later is required",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
	return
}

$configuration = @{}

$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

#endregion

#region Load resources from disk.

$iconLibrary = @{
	       NewModuleIcon16 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\NewModule.ico",16,16
	       NewModuleIcon32 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\NewModule.ico",32,32
	     NewManifestIcon16 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\NewManifest.ico",16,16
	     NewManifestIcon32 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\NewManifest.ico",32,32
	 ConvertToModuleIcon16 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ConvertToModule.ico",16,16
	 ConvertToModuleIcon32 = New-Object -TypeName System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\ConvertToModule.ico",32,32
}

$imageLibrary = @{
	      NewModuleImage16 = $iconLibrary['NewModuleIcon16'].ToBitmap()
	      NewModuleImage32 = $iconLibrary['NewModuleIcon32'].ToBitmap()
	    NewManifestImage16 = $iconLibrary['NewManifestIcon16'].ToBitmap()
	    NewManifestImage32 = $iconLibrary['NewManifestIcon32'].ToBitmap()
	ConvertToModuleImage16 = $iconLibrary['ConvertToModuleIcon16'].ToBitmap()
	ConvertToModuleImage32 = $iconLibrary['ConvertToModuleIcon32'].ToBitmap()
}

#endregion

#region Define the New Module dialog.

$newModuleDialogCode = @'
using System;
using System.Windows.Forms;

namespace Addon
{
	namespace ModuleManagement
	{
		public partial class NewModuleForm : Form
		{
			public NewModuleForm()
			{
				InitializeComponent();
			}

			private void buttonOK_Click(object sender, EventArgs e)
			{
				this.DialogResult = DialogResult.None;
				if (this.textBoxName.Text.Trim().Length == 0)
				{
					MessageBox.Show(this, "You must provide a name for your new module.", "Name is required", MessageBoxButtons.OK, MessageBoxIcon.Error);
					this.textBoxName.SelectAll();
					this.textBoxName.Focus();
				}
				else if ((this.textBoxVersion.Text.Trim().Length > 0) && (!System.Text.RegularExpressions.Regex.Match(this.textBoxVersion.Text.Trim(), "^\\d+\\.\\d+(\\.\\d+(\\.\\d+)?)?$").Success))
				{
					MessageBox.Show(this, "The initial version number that was provided is not a valid version number.\r\n\r\nVersion numbers are in the format Major.Minor[.Build[.Revision]].", "Invalid initial version number", MessageBoxButtons.OK, MessageBoxIcon.Error);
					this.textBoxVersion.SelectAll();
					this.textBoxVersion.Focus();
				}
				else
				{
					this.DialogResult = DialogResult.OK;
				}
			}

			public System.Drawing.Image Image
			{
				set
				{
					this.pictureBoxIcon.Image = value;
				}
			}

			public System.String Title
			{
				set
				{
					if (value.Trim().Length > 0)
					{
						this.Text = value.Trim();
					}
				}
			}

			public System.String Instructions
			{
				set
				{
					if (value.Trim().Length > 0)
					{
						this.labelInstructions.Text = value.Trim();
					}
				}
			}

			public System.String ModuleName
			{
				get
				{
					return this.textBoxName.Text.Trim();
				}
				set
				{
					if (value.Trim().Length > 0)
					{
						this.textBoxName.Text = value.Trim();
					}
				}
			}

			public System.String ModuleDescription
			{
				get
				{
					return this.textBoxDescription.Text.Trim();
				}
				set
				{
					if (value.Trim().Length > 0)
					{
						this.textBoxDescription.Text = value.Trim();
					}
				}
			}

			public System.String ModuleAuthor
			{
				get
				{
					return this.textBoxAuthor.Text.Trim();
				}
				set
				{
					if (value.Trim().Length > 0)
					{
						this.textBoxAuthor.Text = value.Trim();
					}
				}
			}

			public System.String ModuleCompanyName
			{
				get
				{
					return this.textBoxCompanyName.Text.Trim();
				}
				set
				{
					if (value.Trim().Length > 0)
					{
						this.textBoxCompanyName.Text = value.Trim();
					}
				}
			}

			public System.String ModuleVersion
			{
				get
				{
					return this.textBoxVersion.Text.Trim();
				}
				set
				{
					if (value.Trim().Length > 0)
					{
						this.textBoxVersion.Text = value.Trim();
					}
				}
			}
		}

		partial class NewModuleForm
		{
			/// <summary>
			/// Required designer variable.
			/// </summary>
			private System.ComponentModel.IContainer components = null;

			/// <summary>
			/// Clean up any resources being used.
			/// </summary>
			/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
			protected override void Dispose(bool disposing)
			{
				if (disposing && (components != null))
				{
					components.Dispose();
				}
				base.Dispose(disposing);
			}

			#region Windows Form Designer generated code

			/// <summary>
			/// Required method for Designer support - do not modify
			/// the contents of this method with the code editor.
			/// </summary>
			private void InitializeComponent()
			{
				this.textBoxName = new System.Windows.Forms.TextBox();
				this.labelInstructions = new System.Windows.Forms.Label();
				this.labelName = new System.Windows.Forms.Label();
				this.labelDescription = new System.Windows.Forms.Label();
				this.textBoxDescription = new System.Windows.Forms.TextBox();
				this.labelAuthor = new System.Windows.Forms.Label();
				this.textBoxAuthor = new System.Windows.Forms.TextBox();
				this.labelCompanyName = new System.Windows.Forms.Label();
				this.textBoxCompanyName = new System.Windows.Forms.TextBox();
				this.labelVersion = new System.Windows.Forms.Label();
				this.textBoxVersion = new System.Windows.Forms.TextBox();
				this.pictureBoxIcon = new System.Windows.Forms.PictureBox();
				this.buttonOK = new System.Windows.Forms.Button();
				this.buttonCancel = new System.Windows.Forms.Button();
				((System.ComponentModel.ISupportInitialize)(this.pictureBoxIcon)).BeginInit();
				this.SuspendLayout();
				// 
				// textBoxName
				// 
				this.textBoxName.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
							| System.Windows.Forms.AnchorStyles.Right)));
				this.textBoxName.Location = new System.Drawing.Point(107, 79);
				this.textBoxName.Name = "textBoxName";
				this.textBoxName.Size = new System.Drawing.Size(380, 20);
				this.textBoxName.TabIndex = 2;
				// 
				// labelInstructions
				// 
				this.labelInstructions.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
							| System.Windows.Forms.AnchorStyles.Right)));
				this.labelInstructions.Location = new System.Drawing.Point(73, 19);
				this.labelInstructions.Name = "labelInstructions";
				this.labelInstructions.Size = new System.Drawing.Size(414, 40);
				this.labelInstructions.TabIndex = 0;
				this.labelInstructions.Text = "Please provide the name of the module that you are creating and optionally" +
					" include a manifest by setting a description, author, company name and version f" +
					"or the module.";
				// 
				// labelName
				// 
				this.labelName.AutoSize = true;
				this.labelName.Location = new System.Drawing.Point(12, 82);
				this.labelName.Name = "labelName";
				this.labelName.Size = new System.Drawing.Size(38, 13);
				this.labelName.TabIndex = 1;
				this.labelName.Text = "&Name:";
				// 
				// labelDescription
				// 
				this.labelDescription.AutoSize = true;
				this.labelDescription.Location = new System.Drawing.Point(12, 116);
				this.labelDescription.Name = "labelDescription";
				this.labelDescription.Size = new System.Drawing.Size(63, 13);
				this.labelDescription.TabIndex = 3;
				this.labelDescription.Text = "&Description:";
				// 
				// textBoxDescription
				// 
				this.textBoxDescription.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
							| System.Windows.Forms.AnchorStyles.Right)));
				this.textBoxDescription.Location = new System.Drawing.Point(107, 113);
				this.textBoxDescription.Name = "textBoxDescription";
				this.textBoxDescription.Size = new System.Drawing.Size(380, 20);
				this.textBoxDescription.TabIndex = 4;
				// 
				// labelAuthor
				// 
				this.labelAuthor.AutoSize = true;
				this.labelAuthor.Location = new System.Drawing.Point(12, 150);
				this.labelAuthor.Name = "labelAuthor";
				this.labelAuthor.Size = new System.Drawing.Size(41, 13);
				this.labelAuthor.TabIndex = 5;
				this.labelAuthor.Text = "&Author:";
				// 
				// textBoxAuthor
				// 
				this.textBoxAuthor.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
							| System.Windows.Forms.AnchorStyles.Right)));
				this.textBoxAuthor.Location = new System.Drawing.Point(107, 147);
				this.textBoxAuthor.Name = "textBoxAuthor";
				this.textBoxAuthor.Size = new System.Drawing.Size(380, 20);
				this.textBoxAuthor.TabIndex = 6;
				// 
				// labelCompanyName
				// 
				this.labelCompanyName.AutoSize = true;
				this.labelCompanyName.Location = new System.Drawing.Point(12, 184);
				this.labelCompanyName.Name = "labelCompanyName";
				this.labelCompanyName.Size = new System.Drawing.Size(85, 13);
				this.labelCompanyName.TabIndex = 7;
				this.labelCompanyName.Text = "&Company Name:";
				// 
				// textBoxCompanyName
				// 
				this.textBoxCompanyName.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
							| System.Windows.Forms.AnchorStyles.Right)));
				this.textBoxCompanyName.Location = new System.Drawing.Point(107, 181);
				this.textBoxCompanyName.Name = "textBoxCompanyName";
				this.textBoxCompanyName.Size = new System.Drawing.Size(380, 20);
				this.textBoxCompanyName.TabIndex = 8;
				// 
				// labelVersion
				// 
				this.labelVersion.AutoSize = true;
				this.labelVersion.Location = new System.Drawing.Point(12, 218);
				this.labelVersion.Name = "labelVersion";
				this.labelVersion.Size = new System.Drawing.Size(45, 13);
				this.labelVersion.TabIndex = 9;
				this.labelVersion.Text = "&Version:";
				// 
				// textBoxVersion
				// 
				this.textBoxVersion.Location = new System.Drawing.Point(107, 215);
				this.textBoxVersion.Name = "textBoxVersion";
				this.textBoxVersion.Size = new System.Drawing.Size(109, 20);
				this.textBoxVersion.TabIndex = 10;
				// 
				// pictureBoxIcon
				// 
				this.pictureBoxIcon.Location = new System.Drawing.Point(23, 23);
				this.pictureBoxIcon.Name = "pictureBoxIcon";
				this.pictureBoxIcon.Size = new System.Drawing.Size(32, 32);
				this.pictureBoxIcon.SizeMode = System.Windows.Forms.PictureBoxSizeMode.AutoSize;
				this.pictureBoxIcon.TabIndex = 11;
				this.pictureBoxIcon.TabStop = false;
				// 
				// buttonOK
				// 
				this.buttonOK.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
				this.buttonOK.DialogResult = System.Windows.Forms.DialogResult.OK;
				this.buttonOK.Location = new System.Drawing.Point(331, 255);
				this.buttonOK.Name = "buttonOK";
				this.buttonOK.Size = new System.Drawing.Size(75, 23);
				this.buttonOK.TabIndex = 12;
				this.buttonOK.Text = "OK";
				this.buttonOK.UseVisualStyleBackColor = true;
				this.buttonOK.Click += new System.EventHandler(this.buttonOK_Click);
				// 
				// buttonCancel
				// 
				this.buttonCancel.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
				this.buttonCancel.DialogResult = System.Windows.Forms.DialogResult.Cancel;
				this.buttonCancel.Location = new System.Drawing.Point(412, 255);
				this.buttonCancel.Name = "buttonCancel";
				this.buttonCancel.Size = new System.Drawing.Size(75, 23);
				this.buttonCancel.TabIndex = 13;
				this.buttonCancel.Text = "Cancel";
				this.buttonCancel.UseVisualStyleBackColor = true;
				// 
				// NewModuleForm
				// 
				this.AcceptButton = this.buttonOK;
				this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
				this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
				this.CancelButton = this.buttonCancel;
				this.ClientSize = new System.Drawing.Size(499, 290);
				this.ControlBox = false;
				this.Controls.Add(this.buttonCancel);
				this.Controls.Add(this.buttonOK);
				this.Controls.Add(this.pictureBoxIcon);
				this.Controls.Add(this.labelVersion);
				this.Controls.Add(this.textBoxVersion);
				this.Controls.Add(this.labelCompanyName);
				this.Controls.Add(this.textBoxCompanyName);
				this.Controls.Add(this.labelAuthor);
				this.Controls.Add(this.textBoxAuthor);
				this.Controls.Add(this.labelDescription);
				this.Controls.Add(this.textBoxDescription);
				this.Controls.Add(this.labelName);
				this.Controls.Add(this.labelInstructions);
				this.Controls.Add(this.textBoxName);
				this.MaximizeBox = false;
				this.MinimizeBox = false;
				this.Name = "NewModuleForm";
				this.ShowIcon = false;
				this.ShowInTaskbar = false;
				this.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide;
				this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
				this.Text = "New Module";
				((System.ComponentModel.ISupportInitialize)(this.pictureBoxIcon)).EndInit();
				this.ResumeLayout(false);
				this.PerformLayout();

			}

			#endregion

			private System.Windows.Forms.TextBox textBoxName;
			private System.Windows.Forms.Label labelInstructions;
			private System.Windows.Forms.Label labelName;
			private System.Windows.Forms.Label labelDescription;
			private System.Windows.Forms.TextBox textBoxDescription;
			private System.Windows.Forms.Label labelAuthor;
			private System.Windows.Forms.TextBox textBoxAuthor;
			private System.Windows.Forms.Label labelCompanyName;
			private System.Windows.Forms.TextBox textBoxCompanyName;
			private System.Windows.Forms.Label labelVersion;
			private System.Windows.Forms.TextBox textBoxVersion;
			private System.Windows.Forms.PictureBox pictureBoxIcon;
			private System.Windows.Forms.Button buttonOK;
			private System.Windows.Forms.Button buttonCancel;
		}
	}
}
'@
if (-not ('Addon.ModuleManagement.NewModuleForm' -as [System.Type])) {
	Add-Type -ReferencedAssemblies 'System.Windows.Forms','System.Drawing' -TypeDefinition $newModuleDialogCode
}

#endregion

#region Create the "New|Module..." command.

if (-not ($newModuleCommand = $se.Commands['FileCommand.NewModule'])) {
	$newModuleCommand = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'FileCommand','NewModule'
	$newModuleCommand.Text = '&Module...'
	$newModuleCommand.Image = $imageLibrary['NewModuleImage16']
	$newModuleCommand.AddShortcut('Ctrl+Shift+M')
	$newModuleCommand.ScriptBlock = {
		$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
		$configPath = "${PSScriptRoot}\Add-on.ModuleManagement.config.xml"
		$defaultDescription = 'A PowerShell module.'
		$defaultCompanyName = ''
		$defaultAuthor = ''
		$defaultInitialVersion = '1.0.0.0'
		if ($registryData = Get-ItemProperty -LiteralPath 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion' -Name RegisteredOrganization,RegisteredOwner -ErrorAction SilentlyContinue) {
			if (Get-Member -InputObject $registryData -Name RegisteredOrganization -ErrorAction SilentlyContinue) {
				$defaultCompanyName = $registryData.RegisteredOrganization
			}
			if (Get-Member -InputObject $registryData -Name RegisteredOwner -ErrorAction SilentlyContinue) {
				$defaultAuthor = $registryData.RegisteredOwner
			}
		}
		if (Test-Path -LiteralPath $configPath) {
			$configuration = Import-Clixml -Path $configPath
			$defaultDescription = $configuration['Description']
			$defaultCompanyName = $configuration['CompanyName']
			$defaultAuthor = $configuration['Author']
			$defaultInitialVersion = $configuration['InitialVersion']
		}
		$newModuleDialog = New-Object -TypeName Addon.ModuleManagement.NewModuleForm
		$newModuleDialog.Image = $imageLibrary['NewModuleImage32']
		$newModuleDialog.ModuleDescription = $defaultDescription
		$newModuleDialog.ModuleCompanyName = $defaultCompanyName
		$newModuleDialog.ModuleAuthor = $defaultAuthor
		$newModuleDialog.ModuleVersion = $defaultInitialVersion
		$result = $newModuleDialog.ShowDialog()
		if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
			$name = $newModuleDialog.ModuleName | Split-Path -Leaf
			if ($path = $newModuleDialog.ModuleName | Split-Path -Parent) {
				$path = "\$path"
			}
			$description = $newModuleDialog.ModuleDescription
			$companyName = $newModuleDialog.ModuleCompanyName
			$author = $newModuleDialog.ModuleAuthor
			$initialVersion = $newModuleDialog.ModuleVersion
			if (-not (Get-Variable -Name configuration)) {
				$configuration = @{}
			}
			$configuration = @{
				   'Description' = $description
				   'CompanyName' = $companyName
						'Author' = $author
				'InitialVersion' = $initialVersion
			}
			Export-Clixml -InputObject $configuration -Path $configPath
			if (Test-Path -Path "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name\$name.ps[md]1") {
				$dialogResult = [System.Windows.Forms.MessageBox]::Show("A module called ""$name"" already exists in your ""$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path"" folder.$([System.Environment]::NewLine * 2)Do you want to overwrite it?","Module $name already exists",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question,[System.Windows.Forms.MessageBoxDefaultButton]::Button2)
				if ($dialogResult -eq [System.Windows.Forms.DialogResult]::No) {
					return
				}
			}
			if (-not (Test-Path -LiteralPath "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name")) {
				New-Item -Force -ItemType Directory -Path "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name" | Out-Null
			}
			$header = @"
$('#' * 119)
# File:             {0,-96} #
# Author:           {1,-97} #
# Publisher:        {2,-97} #
# Copyright:        {3,-97} #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   {4,-97} #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name {5,-73} #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
$('#' * 119)
"@ -f "$name.{0}",$author,$companyName,("© {0} {1} All rights reserved." -f (Get-Date -Format yyyy),$(if ($companyName -match '\.$') {$companyName} else {"${companyName}."})),("3. Check the {0} module." -f $name),$(if ($path) {"$($path -replace '^\\')\$name"} else {$name})
			if ($description -or $companyName -or $author -or $initialVersion) {
				$manifest = @"
$($header -f 'psd1')

@{

# Script module or binary module file associated with this manifest
ModuleToProcess = '$name.psm1'

# Version number of this module.
ModuleVersion = '$initialVersion'

# ID used to uniquely identify this module
GUID = '{$([System.Guid]::NewGuid().ToString().ToLower())}'

# Author of this module
Author = '$author'

# Company or vendor of this module
CompanyName = '$companyName'

# Copyright statement for this module
Copyright = '© $(Get-Date -Format yyyy) $(if ($companyName -match '\.$') {$companyName} else {"${companyName}."}) All rights reserved.'

# Description of the functionality provided by this module
Description = '$description'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Minimum version of the .NET Framework required by this module
DotNetFrameworkVersion = '2.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '2.0.50727'

# Processor architecture (None, X86, Amd64, IA64) required by this module
ProcessorArchitecture = 'None'

# Modules that must be imported into the global environment prior to importing
# this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to
# importing this module
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @()

# Modules to import as nested modules of the module specified in
# ModuleToProcess
NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
ModuleList = @()

# List of all files packaged with this module
FileList = @(
	'.\$name.psm1'
	'.\$name.psd1'
)

# Private data to pass to the module specified in ModuleToProcess
PrivateData = ''

}
"@
				$manifestPath = "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name\$name.psd1"
				foreach ($item in $se.DocumentWindows) {
					if ($item.Document.Path -eq $manifestPath) {
						$item.Close([Quest.PowerGUI.SDK.OperationMode]::Force)
						break
					}
				}
				Out-File -Force -InputObject $manifest -FilePath $manifestPath
				try {
					$se.DocumentWindows.Add($manifestPath) | Out-Null
				}
				catch {
				}
			}
			$module = @"
$($header -f 'psm1')

Set-StrictMode -Version 2

# TODO: Define your module here.

"@
			$modulePath = "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name\$name.psm1"
			foreach ($item in $se.DocumentWindows) {
				if ($item.Document.Path -eq $modulePath) {
					$item.Close([Quest.PowerGUI.SDK.OperationMode]::Force)
					break
				}
			}
			Out-File -Force -InputObject $module -FilePath $modulePath
			try {
				$se.DocumentWindows.Add($modulePath) | Out-Null
			}
			catch {
			}
		}
	}

	$se.Commands.Add($newModuleCommand)
}

#endregion

#region Add the "New" submenu to the File menu.

if (($fileMenu = $se.Menus['MenuBar.File']) -and
    (-not ($newSubMenu = $fileMenu.Items['FileCommand.NewSubMenu']))) {
	$index = -1
	if ($openMenuItem = $fileMenu.Items['FileCommand.Open']) {
		$index = $fileMenu.Items.IndexOf($openMenuItem)
	}
	$newSubMenuCommand = New-Object -TypeName Quest.PowerGUI.SDK.MenuCommand -ArgumentList 'FileCommand','NewSubMenu'
	$newSubMenuCommand.Text = 'Ne&w'
	if ($index -ge 0) {
		$fileMenu.Items.Insert($index,$newSubMenuCommand)
	} else {
		$fileMenu.Items.Add($newSubMenuCommand)
	}
	if ($newCommand = $fileMenu.Items['FileCommand.New']) {
		$newCommand.Text = '&New Document'
	}
}

#endregion

#region Add the "Module..." command to the File|New sub menu.

if (($fileMenu = $se.Menus['MenuBar.File']) -and
    ($newSubMenu = $fileMenu.Items['FileCommand.NewSubMenu']) -and
    (-not ($newModuleMenuItem = $newSubMenu.Items['FileCommand.NewModule']))) {
	$newSubMenu.Items.Add($newModuleCommand)
}

#endregion

#region Insert the "New Module..." command in the Standard toolbar.

$standardToolbar = $null
foreach ($item in $se.Toolbars) {
	if ($item.Title -eq 'Standard') {
		$standardToolbar = $item
		break
	}
}
if (($standardToolbar) -and
    (-not ($newModuleToolbarButton = $standardToolbar.Items['FileCommand.NewModule']))) {
	$index = -1
	if ($openToolbarButton = $standardToolbar.Items['FileCommand.Open']) {
		$index = $standardToolbar.Items.IndexOf($openToolbarButton)
	}
	if ($index -ge 0) {
		$standardToolbar.Items.Insert($index,$newModuleCommand)
	} else {
		$standardToolbar.Items.Add($newModuleCommand)
	}
}

#endregion

#region Create the "New|Manifest" command.

if (-not ($newManifestCommand = $se.Commands['FileCommand.NewManifest'])) {
	$newManifestCommand = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'FileCommand','NewManifest'
	$newManifestCommand.Text = 'Ma&nifest...'
	$newManifestCommand.Image = $imageLibrary['NewManifestImage16']
	$newManifestCommand.AddShortcut('Ctrl+Shift+N')
	$newManifestCommand.ScriptBlock = {
		$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
		$configPath = "${PSScriptRoot}\Add-on.ModuleManagement.config.xml"
		$defaultDescription = 'A PowerShell module.'
		$defaultCompanyName = ''
		$defaultAuthor = ''
		$defaultInitialVersion = '1.0.0.0'
		if ($registryData = Get-ItemProperty -LiteralPath 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion' -Name RegisteredOrganization,RegisteredOwner -ErrorAction SilentlyContinue) {
			if (Get-Member -InputObject $registryData -Name RegisteredOrganization -ErrorAction SilentlyContinue) {
				$defaultCompanyName = $registryData.RegisteredOrganization
			}
			if (Get-Member -InputObject $registryData -Name RegisteredOwner -ErrorAction SilentlyContinue) {
				$defaultAuthor = $registryData.RegisteredOwner
			}
		}
		if (Test-Path -LiteralPath $configPath) {
			$configuration = Import-Clixml -Path $configPath
			$defaultDescription = $configuration['Description']
			$defaultCompanyName = $configuration['CompanyName']
			$defaultAuthor = $configuration['Author']
			$defaultInitialVersion = $configuration['InitialVersion']
		}
		$newManifestDialog = New-Object -TypeName Addon.ModuleManagement.NewModuleForm
		$newManifestDialog.Image = $imageLibrary['NewManifestImage32']
		$newManifestDialog.Title = 'New Module Manifest'
		$newManifestDialog.Instructions = "Please provide the name (including the relative path) of the manifest that you are creating along with a description, author, company name and version for the module associated with that manifest."
		$newManifestDialog.ModuleDescription = $defaultDescription
		$newManifestDialog.ModuleCompanyName = $defaultCompanyName
		$newManifestDialog.ModuleAuthor = $defaultAuthor
		$newManifestDialog.ModuleVersion = $defaultInitialVersion
		$result = $newManifestDialog.ShowDialog()
		if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
			$name = $newManifestDialog.ModuleName | Split-Path -Leaf
			if ($path = $newManifestDialog.ModuleName | Split-Path -Parent) {
				$path = "\$path"
			}
			$description = $newManifestDialog.ModuleDescription
			$companyName = $newManifestDialog.ModuleCompanyName
			$author = $newManifestDialog.ModuleAuthor
			$initialVersion = $newManifestDialog.ModuleVersion
			if (-not (Get-Variable -Name configuration)) {
				$configuration = @{}
			}
			$configuration = @{
				   'Description' = $description
				   'CompanyName' = $companyName
						'Author' = $author
				'InitialVersion' = $initialVersion
			}
			Export-Clixml -InputObject $configuration -Path $configPath
			if (Test-Path -Path "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name.psd1") {
				$dialogResult = [System.Windows.Forms.MessageBox]::Show("A manifest called ""$name"" already exists in your ""$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path"" folder.$([System.Environment]::NewLine * 2)Do you want to overwrite it?","Manifest $name already exists",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question,[System.Windows.Forms.MessageBoxDefaultButton]::Button2)
				if ($dialogResult -eq [System.Windows.Forms.DialogResult]::No) {
					return
				}
			}
			if (-not (Test-Path -LiteralPath "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path")) {
				New-Item -Force -ItemType Directory -Path "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path" | Out-Null
			}
			$header = @"
$('#' * 119)
# File:             {0,-96} #
# Author:           {1,-97} #
# Publisher:        {2,-97} #
# Copyright:        {3,-97} #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   {4,-97} #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name {5,-73} #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
$('#' * 119)
"@ -f "$name.{0}",$author,$companyName,("© {0} {1} All rights reserved." -f (Get-Date -Format yyyy),$(if ($companyName -match '\.$') {$companyName} else {"${companyName}."})),("3. Check the {0} module." -f $name),"$($path -replace '^\\')\$name"
			$manifest = @"
$($header -f 'psd1')

"@
			$manifestPath = "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name.psd1"
			foreach ($item in $se.DocumentWindows) {
				if ($item.Document.Path -eq $manifestPath) {
					$item.Close([Quest.PowerGUI.SDK.OperationMode]::Force)
					break
				}
			}
			Out-File -Force -InputObject $manifest -FilePath $manifestPath
			try {
				$se.DocumentWindows.Add($manifestPath) | Out-Null
			}
			catch {
			}
			$document = $null
			foreach ($item in $se.DocumentWindows) {
				if ($item.Document.Path -eq $manifestPath) {
					$document = $item
					break
				}
			}
			if ($document) {
				$document.Activate()
				$document.Document.CaretLine = $document.Document.Lines.Count
				$document.Document.CaretCharacter = 1
				$se.Snippets['Manifest'].Invoke()
				for ($index = 1; $index -lt $document.Document.Lines.Count; $index++) {
					$line = $document.Document.Lines[$index]
					if ($line -match '^ModuleToProcess = ''.*''$' ) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						if (-not ($moduleToProcess = $manifestPath | Split-Path -Parent | Get-ChildItem -Filter '*.psm1' | Select-Object -First 1 | Select-Object -ExpandProperty Name)) {
							$moduleToProcess = $manifestPath | Split-Path -Parent | Get-ChildItem -Filter '*.dll' | Select-Object -First 1 | Select-Object -ExpandProperty Name
						}
						$document.Document.SelectedText = "ModuleToProcess = '$moduleToProcess'"
						continue
					}
					if ($line -match '^GUID = ''.*''$' ) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$document.Document.SelectedText = "GUID = '{$([System.Guid]::NewGuid().ToString().ToLower())}'"
						continue
					}
					if ($line -match '^Copyright = ''.*''$' ) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$document.Document.SelectedText = "Copyright = '© $(Get-Date -Format yyyy)$(if ($companyName -and ($companyName -match '\.$')) {"" $companyName""} else {"" $companyName.""}) All rights reserved.'"
						continue
					}
					if ($initialVersion -and ($line -match '^ModuleVersion = ''.*''$')) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$document.Document.SelectedText = "ModuleVersion = '$initialVersion'"
						continue
					}
					if ($author -and ($line -match '^Author = ''.*''$')) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$document.Document.SelectedText = "Author = '$author'"
						continue
					}
					if ($companyName -and ($line -match '^CompanyName = ''.*''$')) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$document.Document.SelectedText = "CompanyName = '$companyName'"
						continue
					}
					if ($description -and ($line -match '^Description = ''.*''$')) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$document.Document.SelectedText = "Description = '$description'"
						continue
					}
					if ($line -match '^PowerShellVersion = ''.*''$' ) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$document.Document.SelectedText = "PowerShellVersion = '$($PSVersionTable.PSVersion.ToString())'"
						continue
					}
					if ($line -match '^PowerShellHostName = ''.*''$' ) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$document.Document.SelectedText = "PowerShellHostName = ''"
						continue
					}
					if ($line -match '^PowerShellHostVersion = ''.*''$' ) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$document.Document.SelectedText = "PowerShellHostVersion = ''"
						continue
					}
					if ($line -match '^CLRVersion = ''.*''$' ) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$document.Document.SelectedText = "CLRVersion = '$($PSVersionTable.CLRVersion.ToString())'"
						continue
					}
					if ($line -match '^FileList = @\(\)$' ) {
						$document.Document.Select($index,1,$index,[System.Int32]::MaxValue)
						$includeFiles = @()
						foreach ($item in $manifestPath | Split-Path -Parent | Get-ChildItem -Recurse -Exclude *.xmlscc) {
							if ($item.PSIsContainer) {
								continue
							}
							$includeFiles += "'.\$($item.FullName -replace ""^$([System.Text.RegularExpressions.Regex]::Escape(($manifestPath | Split-Path -Parent)))\\(.*)`$"",'$1')'"
						}
						$document.Document.SelectedText = "FileList = @($([System.Environment]::NewLine)`t$($includeFiles -join $([System.Environment]::NewLine + ""`t""))$([System.Environment]::NewLine))"
						continue
					}
				}
				if ($saveCommand = $se.Commands['FileCommand.Save']) {
					$saveCommand.Invoke()
				}
				$document.Document.CaretLine = 1
				$document.Document.CaretCharacter = 1
			}
		}
	}

	$se.Commands.Add($newManifestCommand)
}

#endregion

#region Add the "Manifest..." command to the File|New sub menu.

if (($fileMenu = $se.Menus['MenuBar.File']) -and
    ($newSubMenu = $fileMenu.Items['FileCommand.NewSubMenu']) -and
    (-not ($newManifestMenuItem = $newSubMenu.Items['FileCommand.NewManifest']))) {
	$newSubMenu.Items.Add($newManifestCommand)
}

#endregion

#region Create the "Convert to Module..." command.

if (-not ($convertToModuleCommand = $se.Commands['FileCommand.ConvertToModule'])) {
	$convertToModuleCommand = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'FileCommand','ConvertToModule'
	$convertToModuleCommand.Text = 'Convert to Mo&dule...'
	$convertToModuleCommand.Image = $imageLibrary['ConvertToModuleImage16']
	$convertToModuleCommand.ScriptBlock = {
		$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
		if (-not ($se.CurrentDocumentWindow | Get-Member -Name Document -ErrorAction SilentlyContinue)) {
			return
		}
		$body = $se.CurrentDocumentWindow.Document.SelectedText
		if (-not $body) {
			$body = $se.CurrentDocumentWindow.Document.Text
		}
		$configPath = "${PSScriptRoot}\Add-on.ModuleManagement.config.xml"
		$defaultDescription = 'A PowerShell module.'
		$defaultCompanyName = ''
		$defaultAuthor = ''
		$defaultInitialVersion = '1.0.0.0'
		if ($registryData = Get-ItemProperty -LiteralPath 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion' -Name RegisteredOrganization,RegisteredOwner -ErrorAction SilentlyContinue) {
			if (Get-Member -InputObject $registryData -Name RegisteredOrganization -ErrorAction SilentlyContinue) {
				$defaultCompanyName = $registryData.RegisteredOrganization
			}
			if (Get-Member -InputObject $registryData -Name RegisteredOwner -ErrorAction SilentlyContinue) {
				$defaultAuthor = $registryData.RegisteredOwner
			}
		}
		if (Test-Path -LiteralPath $configPath) {
			$configuration = Import-Clixml -Path $configPath
			$defaultDescription = $configuration['Description']
			$defaultCompanyName = $configuration['CompanyName']
			$defaultAuthor = $configuration['Author']
			$defaultInitialVersion = $configuration['InitialVersion']
		}
		$convertToModuleDialog = New-Object -TypeName Addon.ModuleManagement.NewModuleForm
		$convertToModuleDialog.Image = $imageLibrary['ConvertToModuleImage32']
		$convertToModuleDialog.Title = 'Convert to Module'
		$convertToModuleDialog.Instructions = "Please provide a name for the module that you are creating from $(if ($se.CurrentDocumentWindow.Document.SelectedText) {'the selected text'} else {'your script file'}) and optionally include a manifest by setting a description, author, company name and version for the module."
		$convertToModuleDialog.ModuleDescription = $defaultDescription
		$convertToModuleDialog.ModuleCompanyName = $defaultCompanyName
		$convertToModuleDialog.ModuleAuthor = $defaultAuthor
		$convertToModuleDialog.ModuleVersion = $defaultInitialVersion
		$result = $convertToModuleDialog.ShowDialog()
		if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
			$name = $convertToModuleDialog.ModuleName | Split-Path -Leaf
			if ($path = $convertToModuleDialog.ModuleName | Split-Path -Parent) {
				$path = "\$path"
			}
			$description = $convertToModuleDialog.ModuleDescription
			$companyName = $convertToModuleDialog.ModuleCompanyName
			$author = $convertToModuleDialog.ModuleAuthor
			$initialVersion = $convertToModuleDialog.ModuleVersion
			if (-not (Get-Variable -Name configuration)) {
				$configuration = @{}
			}
			$configuration = @{
				   'Description' = $description
				   'CompanyName' = $companyName
						'Author' = $author
				'InitialVersion' = $initialVersion
			}
			Export-Clixml -InputObject $configuration -Path $configPath
			if (Test-Path -Path "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name\$name.ps[md]1") {
				$dialogResult = [System.Windows.Forms.MessageBox]::Show("A module called ""$name"" already exists in your ""$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path"" folder.$([System.Environment]::NewLine * 2)Do you want to overwrite it?","Module $name already exists",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question,[System.Windows.Forms.MessageBoxDefaultButton]::Button2)
				if ($dialogResult -eq [System.Windows.Forms.DialogResult]::No) {
					return
				}
			}
			if (-not (Test-Path -LiteralPath "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name")) {
				New-Item -Force -ItemType Directory -Path "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name" | Out-Null
			}
			$header = @"
$('#' * 119)
# File:             {0,-96} #
# Author:           {1,-97} #
# Publisher:        {2,-97} #
# Copyright:        {3,-97} #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   {4,-97} #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name {5,-73} #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
$('#' * 119)
"@ -f "$name.{0}",$author,$companyName,("© {0} {1} All rights reserved." -f (Get-Date -Format yyyy),$(if ($companyName -match '\.$') {$companyName} else {"${companyName}."})),("3. Check the {0} module." -f $name),,"$($path -replace '^\\')\$name"
			if ($description -or $companyName -or $author -or $initialVersion) {
				$manifest = @"
$($header -f 'psd1')

@{

# Script module or binary module file associated with this manifest
ModuleToProcess = '$name.psm1'

# Version number of this module.
ModuleVersion = '$initialVersion'

# ID used to uniquely identify this module
GUID = '{$([System.Guid]::NewGuid().ToString().ToLower())}'

# Author of this module
Author = '$author'

# Company or vendor of this module
CompanyName = '$companyName'

# Copyright statement for this module
Copyright = '© $(Get-Date -Format yyyy) $(if ($companyName -match '\.$') {$companyName} else {"${companyName}."}) All rights reserved.'

# Description of the functionality provided by this module
Description = '$description'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Minimum version of the .NET Framework required by this module
DotNetFrameworkVersion = '2.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '2.0.50727'

# Processor architecture (None, X86, Amd64, IA64) required by this module
ProcessorArchitecture = 'None'

# Modules that must be imported into the global environment prior to importing
# this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to
# importing this module
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @()

# Modules to import as nested modules of the module specified in
# ModuleToProcess
NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
ModuleList = @()

# List of all files packaged with this module
FileList = @(
	'.\$name.psm1'
	'.\$name.psd1'
)

# Private data to pass to the module specified in ModuleToProcess
PrivateData = ''

}
"@
				$manifestPath = "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name\$name.psd1"
				foreach ($item in $se.DocumentWindows) {
					if ($item.Document.Path -eq $manifestPath) {
						$item.Close([Quest.PowerGUI.SDK.OperationMode]::Force)
						break
					}
				}
				Out-File -Force -InputObject $manifest -FilePath $manifestPath
				try {
					$se.DocumentWindows.Add($manifestPath) | Out-Null
				}
				catch {
				}
			}
			$module = @"
$($header -f 'psm1')

$body

"@
			$modulePath = "$([System.Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules$path\$name\$name.psm1"
			foreach ($item in $se.DocumentWindows) {
				if ($item.Document.Path -eq $modulePath) {
					$item.Close([Quest.PowerGUI.SDK.OperationMode]::Force)
					break
				}
			}
			Out-File -Force -InputObject $module -FilePath $modulePath
			try {
				$se.DocumentWindows.Add($modulePath) | Out-Null
			}
			catch {
			}
		}
	}

	$se.Commands.Add($convertToModuleCommand)
}


#endregion

#region Add the "Convert to Module..." command to the File menu.

if (($fileMenu = $se.Menus['MenuBar.File']) -and
    (-not ($convertToModuleMenuItem = $fileMenu.Items['FileCommand.ConvertToModule']))) {
	$index = -1
	if ($searchOnlineMenuItem = $fileMenu.Items['FileCommand.SearchOnline']) {
		$index = $fileMenu.Items.IndexOf($searchOnlineMenuItem)
	}
	if ($index -ge 0) {
		$fileMenu.Items.Insert($index,$convertToModuleCommand)
	} else {
		$fileMenu.Items.Add($convertToModuleCommand)
	}
	$convertToModuleMenuItem = $fileMenu.Items['FileCommand.ConvertToModule']
	$convertToModuleMenuItem.FirstInGroup = $true
}

#endregion

#region Insert the "Convert to Module..." command in the Standard toolbar.

$standardToolbar = $null
foreach ($item in $se.Toolbars) {
	if ($item.Title -eq 'Standard') {
		$standardToolbar = $item
		break
	}
}
if (($standardToolbar) -and
    (-not ($convertToModuleToolbarButton = $standardToolbar.Items['FileCommand.ConvertToModule']))) {
	$index = -1
	if ($searchToolbarButton = $standardToolbar.Items['EditCommand.Search']) {
		$index = $standardToolbar.Items.IndexOf($searchToolbarButton)
	}
	if ($index -ge 0) {
		$standardToolbar.Items.Insert($index,$convertToModuleCommand)
	} else {
		$standardToolbar.Items.Add($convertToModuleCommand)
	}
    $convertToModuleToolbarButton = $standardToolbar.Items['FileCommand.ConvertToModule']
	$convertToModuleToolbarButton.FirstInGroup = $true
}

#endregion

#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
	$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

	#region Remove the Convert to Module toolbar button from the Standard toolbar.

	$standardToolbar = $null
	foreach ($item in $se.Toolbars) {
		if ($item.Title -eq 'Standard') {
			$standardToolbar = $item
			break
		}
	}
	if (($standardToolbar) -and
	    ($convertToModuleToolbarButton = $standardToolbar.Items['FileCommand.ConvertToModule'])) {
		$standardToolbar.Items.Remove($convertToModuleToolbarButton) | Out-Null
	}

	#endregion

	#region Remove the Convert to Module menu item from the File menu.
	
	if (($fileMenu = $se.Menus['MenuBar.File']) -and
	    ($convertToModuleMenuItem = $fileMenu.Items['FileCommand.ConvertToModule'])) {
		$fileMenu.Items.Remove($convertToModuleMenuItem) | Out-Null
	}

	#endregion

	#region Remove the Convert to Module command.

	if ($convertToModuleCommand = $se.Commands['FileCommand.ConvertToModule']) {
		$se.Commands.Remove($convertToModuleCommand) | Out-Null
	}

	#endregion

	#region Remove the New|Manifest menu item from the File menu.
	
	if (($fileMenu = $se.Menus['MenuBar.File']) -and
	    ($newSubMenu = $fileMenu.Items['FileCommand.NewSubMenu']) -and
	    ($newManifestMenuItem = $newSubMenu.Items['FileCommand.NewManifest'])) {
		$newSubMenu.Items.Remove($newManifestMenuItem) | Out-Null
	}

	#endregion

	#region Remove the New|Manifest command.

	if ($newManifestCommand = $se.Commands['FileCommand.NewManifest']) {
		$se.Commands.Remove($newManifestCommand) | Out-Null
	}

	#endregion

	#region Remove the New Module toolbar button from the Standard toolbar.

	$standardToolbar = $null
	foreach ($item in $se.Toolbars) {
		if ($item.Title -eq 'Standard') {
			$standardToolbar = $item
			break
		}
	}
	if (($standardToolbar) -and
	    ($newModuleToolbarButton = $standardToolbar.Items['FileCommand.NewModule'])) {
		$standardToolbar.Items.Remove($newModuleToolbarButton) | Out-Null
	}

	#endregion

	#region Remove the New|Module menu item from the File menu.
	
	if (($fileMenu = $se.Menus['MenuBar.File']) -and
	    ($newSubMenu = $fileMenu.Items['FileCommand.NewSubMenu']) -and
	    ($newModuleMenuItem = $newSubMenu.Items['FileCommand.NewModule'])) {
		$newSubMenu.Items.Remove($newModuleMenuItem) | Out-Null
	}

	#endregion

	#region Remove the New sub menu from the File menu if it is empty.
	
	if (($fileMenu = $se.Menus['MenuBar.File']) -and
	    ($newSubMenu = $fileMenu.Items['FileCommand.NewSubMenu']) -and
		($newSubMenu.Items.Count -eq 0)) {
		$fileMenu.Items.Remove($newSubMenu) | Out-Null
		if ($newSubMenuCommand = $se.Commands['FileCommand.NewSubMenu']) {
			$se.Commands.Remove($newSubMenuCommand) | Out-Null
		}
		if ($newCommand = $fileMenu.Items['FileCommand.New']) {
			$newCommand.Text = $newCommand.Command.Text
		}
	}

	#endregion

	#region Remove the New|Module command.

	if ($newModuleCommand = $se.Commands['FileCommand.NewModule']) {
		$se.Commands.Remove($newModuleCommand) | Out-Null
	}

	#endregion
}

#endregion

# SIG # Begin signature block
# MIIOhgYJKoZIhvcNAQcCoIIOdzCCDnMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOHwuhY70dGp0P9nu4cZwUjXx
# aAyggguFMIIFczCCBFugAwIBAgIQVDMCUo2yXdJ9VuMdT5/s7jANBgkqhkiG9w0B
# AQUFADCBtDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8w
# HQYDVQQLExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTswOQYDVQQLEzJUZXJtcyBv
# ZiB1c2UgYXQgaHR0cHM6Ly93d3cudmVyaXNpZ24uY29tL3JwYSAoYykxMDEuMCwG
# A1UEAxMlVmVyaVNpZ24gQ2xhc3MgMyBDb2RlIFNpZ25pbmcgMjAxMCBDQTAeFw0x
# MTAzMDMwMDAwMDBaFw0xNDAzMDIyMzU5NTlaMIG2MQswCQYDVQQGEwJVUzETMBEG
# A1UECBMKQ2FsaWZvcm5pYTEUMBIGA1UEBxMLQWxpc28gVmllam8xHTAbBgNVBAoU
# FFF1ZXN0IFNvZnR3YXJlLCBJbmMuMT4wPAYDVQQLEzVEaWdpdGFsIElEIENsYXNz
# IDMgLSBNaWNyb3NvZnQgU29mdHdhcmUgVmFsaWRhdGlvbiB2MjEdMBsGA1UEAxQU
# UXVlc3QgU29mdHdhcmUsIEluYy4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQCZUApfRti5qDWpZJP9X7WliUx3W4I3DEZMNZ7N9XpYrzrvj+RZi8WwgH0Z
# 8ylo0zqMwBcPfMH6BR64005alBJCP27JgrsxOKv5FI9e8cgQCmoQT8/gBByOHhlt
# /hYBatlFB4uxIfvDtIkWrqtVdC92aqtVVP+yCQVRkWiYfo6OfNYcoGTqIIrSTwfS
# XMd21pFnFO1wButj0AcfSoIGcK1UGNpdg3D5cYOs9mv5KTHaIz4JXVL1xAscRwZi
# SqKbM7Xc9VMOM4FJYYt4JrosM7BXIzk3ZGtvyIfXbs4UXxC/5Vr4exO04DsR4Rg7
# RRZGT0RvjU2j40I82xpsoLGhR1qNAgMBAAGjggF7MIIBdzAJBgNVHRMEAjAAMA4G
# A1UdDwEB/wQEAwIHgDBABgNVHR8EOTA3MDWgM6Axhi9odHRwOi8vY3NjMy0yMDEw
# LWNybC52ZXJpc2lnbi5jb20vQ1NDMy0yMDEwLmNybDBEBgNVHSAEPTA7MDkGC2CG
# SAGG+EUBBxcDMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LnZlcmlzaWduLmNv
# bS9ycGEwEwYDVR0lBAwwCgYIKwYBBQUHAwMwcQYIKwYBBQUHAQEEZTBjMCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC52ZXJpc2lnbi5jb20wOwYIKwYBBQUHMAKGL2h0
# dHA6Ly9jc2MzLTIwMTAtYWlhLnZlcmlzaWduLmNvbS9DU0MzLTIwMTAuY2VyMB8G
# A1UdIwQYMBaAFM+Zqep7JvRLyY6P1/AFJu/j0qedMBEGCWCGSAGG+EIBAQQEAwIE
# EDAWBgorBgEEAYI3AgEbBAgwBgEBAAEB/zANBgkqhkiG9w0BAQUFAAOCAQEAVoxv
# js9TBh3o1cyZJMBqt5mHMjGPVsowHCfkzFyBoB85hOqZD7mU570h0Sr4wYUH+tgT
# bDlgsJQzFhBoG23a67VPYy8c1lZeEq9Ix2qimk6BM3855B0rj3wn713wtO9gdDZK
# jgJTP7TG0NBAczIR1f0kpvMe/IdyOuX0cY2AUiCeX7aad/q2BQ2fAhKvWASCqCSF
# fkeF8NOo5PRYOlmls6FtlQ4P66qOX7srE584PAqlDoC/noUL7RCm9ZRABk00j0N6
# wm4GnIeDKzs1sAaarHlYzlmXsPqvjSgU2rR4jHGZ49h3Ry+Qbxk8niK3E2L8LQQ0
# w5ix9FsZ7G357XXZvTCCBgowggTyoAMCAQICEFIA5aolVvwahu2WydRLM8cwDQYJ
# KoZIhvcNAQEFBQAwgcoxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwg
# SW5jLjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE6MDgGA1UECxMx
# KGMpIDIwMDYgVmVyaVNpZ24sIEluYy4gLSBGb3IgYXV0aG9yaXplZCB1c2Ugb25s
# eTFFMEMGA1UEAxM8VmVyaVNpZ24gQ2xhc3MgMyBQdWJsaWMgUHJpbWFyeSBDZXJ0
# aWZpY2F0aW9uIEF1dGhvcml0eSAtIEc1MB4XDTEwMDIwODAwMDAwMFoXDTIwMDIw
# NzIzNTk1OVowgbQxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5j
# LjEfMB0GA1UECxMWVmVyaVNpZ24gVHJ1c3QgTmV0d29yazE7MDkGA1UECxMyVGVy
# bXMgb2YgdXNlIGF0IGh0dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEgKGMpMTAx
# LjAsBgNVBAMTJVZlcmlTaWduIENsYXNzIDMgQ29kZSBTaWduaW5nIDIwMTAgQ0Ew
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD1I0tepdeKuzLp1Ff37+TH
# Jn6tGZj+qJ19lPY2axDXdYEwfwRof8srdR7NHQiM32mUpzejnHuA4Jnh7jdNX847
# FO6G1ND1JzW8JQs4p4xjnRejCKWrsPvNamKCTNUh2hvZ8eOEO4oqT4VbkAFPyad2
# EH8nA3y+rn59wd35BbwbSJxp58CkPDxBAD7fluXF5JRx1lUBxwAmSkA8taEmqQyn
# bYCOkCV7z78/HOsvlvrlh3fGtVayejtUMFMb32I0/x7R9FqTKIXlTBdOflv9pJOZ
# f9/N76R17+8V9kfn+Bly2C40Gqa0p0x+vbtPDD1X8TDWpjaO1oB21xkupc1+NC2J
# AgMBAAGjggH+MIIB+jASBgNVHRMBAf8ECDAGAQH/AgEAMHAGA1UdIARpMGcwZQYL
# YIZIAYb4RQEHFwMwVjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cudmVyaXNpZ24u
# Y29tL2NwczAqBggrBgEFBQcCAjAeGhxodHRwczovL3d3dy52ZXJpc2lnbi5jb20v
# cnBhMA4GA1UdDwEB/wQEAwIBBjBtBggrBgEFBQcBDARhMF+hXaBbMFkwVzBVFglp
# bWFnZS9naWYwITAfMAcGBSsOAwIaBBSP5dMahqyNjmvDz4Bq1EgYLHsZLjAlFiNo
# dHRwOi8vbG9nby52ZXJpc2lnbi5jb20vdnNsb2dvLmdpZjA0BgNVHR8ELTArMCmg
# J6AlhiNodHRwOi8vY3JsLnZlcmlzaWduLmNvbS9wY2EzLWc1LmNybDA0BggrBgEF
# BQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLnZlcmlzaWduLmNvbTAd
# BgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUHAwMwKAYDVR0RBCEwH6QdMBsxGTAX
# BgNVBAMTEFZlcmlTaWduTVBLSS0yLTgwHQYDVR0OBBYEFM+Zqep7JvRLyY6P1/AF
# Ju/j0qedMB8GA1UdIwQYMBaAFH/TZafC3ey78DAJ80M5+gKvMzEzMA0GCSqGSIb3
# DQEBBQUAA4IBAQBWIuY0pMRhy0i5Aa1WqGQP2YyRxLvMDOWteqAif99HOEotbNF/
# cRp87HCpsfBP5A8MU/oVXv50mEkkhYEmHJEUR7BMY4y7oTTUxkXoDYUmcwPQqYxk
# bdxxkuZFBWAVWVE5/FgUa/7UpO15awgMQXLnNyIGCb4j6T9Emh7pYZ3MsZBc/D3S
# jaxCPWU21LQ9QCiPmxDPIybMSyDLkB9djEw0yjzY5TfWb6UgvTTrJtmuDefFmveh
# tCGRM2+G6Fi7JXx0Dlj+dRtjP84xfJuPG5aexVN2hFucrZH6rO2Tul3IIVPCglNj
# rxINUIcRGz1UUpaKLJw9khoImgUux5OlSJHTMYICazCCAmcCAQEwgckwgbQxCzAJ
# BgNVBAYTAlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjEfMB0GA1UECxMWVmVy
# aVNpZ24gVHJ1c3QgTmV0d29yazE7MDkGA1UECxMyVGVybXMgb2YgdXNlIGF0IGh0
# dHBzOi8vd3d3LnZlcmlzaWduLmNvbS9ycGEgKGMpMTAxLjAsBgNVBAMTJVZlcmlT
# aWduIENsYXNzIDMgQ29kZSBTaWduaW5nIDIwMTAgQ0ECEFQzAlKNsl3SfVbjHU+f
# 7O4wCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZI
# hvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcC
# ARUwIwYJKoZIhvcNAQkEMRYEFIe8CjbUtj5YOc88MvTEJv3V8sUOMA0GCSqGSIb3
# DQEBAQUABIIBAJTUbtZlUbVjOoUJrnPcJV4kGqP3gNCiN4iMyHK5dJ3FuiZcgqaY
# E2Aba/a6z1idULtCy7h6kkEHVqT7MzZzuwpgETGuQP32CROCy59eiGZt1FuFpsjX
# UArHI6CC1Gz0Wlbdjx9ycNuczaRa/42PHP8ynx67dX21dRhUL+Z+EWnFOiUfwSax
# CjWwT1rUxK7PGBpqAGMJyCqTk2qP/ReIv+DiN47BBbaBA2+aSAGpVLapxYpA3JSN
# qiWFFQNmIr9QDu1aqf9gIKPEB5JhiX1oHxqbFLkUfLLHLaSYIit+RhW7loLad1s8
# 3wzHogRJcwY+muGf6Xko+7bhFkZIlEITFRo=
# SIG # End signature block
