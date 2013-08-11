# ========================================================
#
# 	Script Information
#
#	Title:			Remote Computer Inventory
#	Author:			Assaf Miron
#	Originally created:	21/06/2008
#	Original path:		Computer-Inventory.PS1
#	Description:		Collects Remote Computer Data Using WMI and Registry Access	
#						Outputs all information to a Data Grid Form and to a CSV Log File						
#	
# ========================================================

#region Constructor
# Import Assembly
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

# Log File where the results are Saved
$LogFile = "C:\Monitoring\Test-Monitor.csv"
# Check to see if the Log File Directory exists
If((Test-Path ($LogFile.Substring(0,$logFile.LastIndexof("\")))) -eq $False)
{ 
	# Create The Directory
	New-Item ($LogFile.Substring(0,$logFile.LastIndexof("\"))) -Type Directory
}
#endregion

#region Form Creation

#~~< Form1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Form1 = New-Object System.Windows.Forms.Form
$Form1.AutoSize = $TRUE
$Form1.ClientSize = New-Object System.Drawing.Size(522, 404)
$Form1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form1.Text = "Computer Inventory"
#~~< Panel1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Panel1 = new-object System.Windows.Forms.Panel
$Panel1.Dock = [System.Windows.Forms.DockStyle]::Fill
$Panel1.Location = new-object System.Drawing.Point(0, 24)
$Panel1.Size = new-object System.Drawing.Size(522, 380)
$Panel1.TabIndex = 20
$Panel1.Text = ""
#~~< btnRun >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Enabled = $FALSE
$btnRun.Location = New-Object System.Drawing.Point(431, 30)
$btnRun.Size = New-Object System.Drawing.Size(75, 23)
$btnRun.TabIndex = 2
$btnRun.Text = "Run"
$btnRun.UseVisualStyleBackColor = $TRUE
$btnRun.add_Click({ RunScript($btnRun) })
#~~< Label1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Label1 = New-Object System.Windows.Forms.Label
$Label1.AutoSize = $False#$TRUE
$Label1.Location = New-Object System.Drawing.Point(12, 31)
$Label1.Size = New-Object System.Drawing.Size(163, 13)
$Label1.TabIndex = 15
$Label1.Text = "File containing Computer Names"
#~~< TextBox1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBox1 = New-Object System.Windows.Forms.TextBox
$TextBox1.Location = New-Object System.Drawing.Point(177, 30)
$TextBox1.Size = New-Object System.Drawing.Size(161, 20)
$TextBox1.TabIndex = 0
$TextBox1.Text = ""
#~~< btnBrowse >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Location = New-Object System.Drawing.Point(347, 30)
$btnBrowse.Size = New-Object System.Drawing.Size(75, 23)
$btnBrowse.TabIndex = 1
$btnBrowse.Text = "Browse"
$btnBrowse.UseVisualStyleBackColor = $TRUE
$btnBrowse.add_Click({ BrowseFile($btnBrowse) })
#~~< DataGridView1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$DataGridView1 = new-object System.Windows.Forms.DataGridView
$DataGridView1.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
$DataGridView1.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize
$DataGridView1.Location = New-Object System.Drawing.Point(12, 59)
$DataGridView1.Size = New-Object System.Drawing.Size(497, 280)
$DataGridView1.TabIndex = 4
$DataGridView1.ClipboardCopyMode = [System.Windows.Forms.DataGridViewClipboardCopyMode]::Disable
$DataGridView1.Text = ""
#~~< ProgressBar1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ProgressBar1 = New-Object System.Windows.Forms.ProgressBar
$ProgressBar1.Anchor = ([System.Windows.Forms.AnchorStyles] ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right ))
$ProgressBar1.Location = New-Object System.Drawing.Point(12, 345)
$ProgressBar1.Size = New-Object System.Drawing.Size(410, 23)
$ProgressBar1.TabIndex = 5
$ProgressBar1.Text = ""
#~~< btnExit >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right))
$btnExit.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$btnExit.Location = New-Object System.Drawing.Point(431, 345)
$btnExit.Size = New-Object System.Drawing.Size(78, 23)
$btnExit.TabIndex = 3
$btnExit.Text = "Exit"
$btnExit.UseVisualStyleBackColor = $TRUE
$btnExit.add_Click({ CloseForm($btnExit) })
#~~< MenuStrip1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$MenuStrip1 = new-object System.Windows.Forms.MenuStrip
$MenuStrip1.Location = new-object System.Drawing.Point(0, 0)
$MenuStrip1.Size = new-object System.Drawing.Size(292, 24)
$MenuStrip1.TabIndex = 6
$MenuStrip1.Text = "MenuStrip1"
#~~< FileToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$FileToolStripMenuItem = new-object System.Windows.Forms.ToolStripMenuItem
$FileToolStripMenuItem.Size = new-object System.Drawing.Size(35, 20)
$FileToolStripMenuItem.Text = "File"
#~~< OpenLogFileToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$OpenLogFileToolStripMenuItem = new-object System.Windows.Forms.ToolStripMenuItem
$OpenLogFileToolStripMenuItem.Size = new-object System.Drawing.Size(152, 22)
$OpenLogFileToolStripMenuItem.Text = "Open Log File"
$OpenLogFileToolStripMenuItem.add_Click({Open-file($OpenLogFileToolStripMenuItem)})
#~~< ExitToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ExitToolStripMenuItem = new-object System.Windows.Forms.ToolStripMenuItem
$ExitToolStripMenuItem.Size = new-object System.Drawing.Size(152, 22)
$ExitToolStripMenuItem.Text = "Exit"
$ExitToolStripMenuItem.add_Click({CloseForm($ExitToolStripMenuItem)})
$FileToolStripMenuItem.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]](@($OpenLogFileToolStripMenuItem, $ExitToolStripMenuItem)))
#~~< HelpToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$HelpToolStripMenuItem = new-object System.Windows.Forms.ToolStripMenuItem
$HelpToolStripMenuItem.Size = new-object System.Drawing.Size(40, 20)
$HelpToolStripMenuItem.Text = "Help"
#~~< AboutToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$AboutToolStripMenuItem = new-object System.Windows.Forms.ToolStripMenuItem
$AboutToolStripMenuItem.Size = new-object System.Drawing.Size(152, 22)
$AboutToolStripMenuItem.Text = "About"
$AboutToolStripMenuItem.add_Click({Show-About($AboutToolStripMenuItem)})
#~~< HowToToolStripMenuItem >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$HowToToolStripMenuItem = new-object System.Windows.Forms.ToolStripMenuItem
$HowToToolStripMenuItem.Size = new-object System.Drawing.Size(152, 22)
$HowToToolStripMenuItem.Text = "How To?"
$HowToToolStripMenuItem.add_Click({Show-HowTo($HowToToolStripMenuItem)})
$HelpToolStripMenuItem.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]](@($AboutToolStripMenuItem, $HowToToolStripMenuItem)))
$MenuStrip1.Items.AddRange([System.Windows.Forms.ToolStripItem[]](@($FileToolStripMenuItem, $HelpToolStripMenuItem)))
$Panel1.Controls.Add($MenuStrip1)
$Panel1.Controls.Add($btnRun)
$Panel1.Controls.Add($Label1)
$Panel1.Controls.Add($TextBox1)
$Panel1.Controls.Add($btnBrowse)
$Panel1.Controls.Add($ProgressBar1)
$Panel1.Controls.Add($btnExit)
$Panel1.Controls.Add($DataGridView1)
$Panel1.Controls.Add($Menu)
$Form1.Controls.Add($Panel1)
#~~< Ping1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Ping1 = New-Object System.Net.NetworkInformation.Ping
#~~< OpenFileDialog1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$OpenFileDialog1 = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog1.Filter = "Text Files|*.txt|CSV Files|*.csv|All Files|*.*"
$OpenFileDialog1.InitialDirectory = "C:"
$OpenFileDialog1.Title = "Open Computers File"
#~~< objNotifyIcon >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 
# Assign an Icon and Icon Type For the NotifyIcon Object
$objNotifyIcon.Icon = "D:\Assaf\Scripts\Icons\XP\people15.ico"
$objNotifyIcon.BalloonTipIcon = "Info" 

#endregion

#region Functions

function out-DataTable
# Function Creates a New Data Table that will be set as the Data Source of the Data Grid View
# Thanks to /\/\o\/\/ http:\\thePowerShellGuy.com
{
	$dt = New-Object Data.datatable
	$First = $TRUE	

	foreach ($item in $Input)
	{
		$DR = $DT.NewRow()
		$Item.PsObject.get_properties() | foreach {
			if ($first)
			{
				$Col = New-Object Data.DataColumn
				$Col.ColumnName = $_.Name.ToString()
			$DT.Columns.Add($Col) }
			if ($_.value -eq $null)
			{
				$DR.Item($_.Name) = "[empty]"
			}
			elseif ($_.IsArray) {
				$DR.Item($_.Name) = [string]::Join($_.value, ";")
			}
			else
			{
				$DR.Item($_.Name) = $_.value
			}
		}
		$DT.Rows.Add($DR)
		$First = $FALSE
	}
		
	return @(, ( $dt ))
		
}

function Join-Data
# Function Joins arrays and Strings to a Single Object with Members
# I Used the same principle of the Out-DataTable and converted it to Join Objects into one
# Using the Add-Member cmdlet. the Function writes to a predefiend object named $DataObject
{
	param($objName="") # This parameter is used for objects that don't have member other than Length like Strings
	foreach ($item in $Input)
	{
		$Item.PsObject.get_properties() | foreach{
			if ($_.value -eq $null)
			{
				$DataObject | Add-Member noteproperty $_.Name "[empty]"
			}
			elseif ($_.IsArray) {
				$DataObject | Add-Member noteproperty $_.Name [string]::Join($_.value, ";")
			}
			elseif ($objName -ne "") {
				$DataObject | Add-Member noteproperty $objName $Item
			}
			else
			{
				$DataObject | Add-Member noteproperty $_.Name $_.value -Force
			}
		}
	}
	
	return @(,$DataObject)
}

function Get-Reg {
# Function Connects to a remote computer Registry using the Parameters it recievs
	param(
		$Hive,
		$Key,
		$Value,
		$RemoteComputer="." # If not enterd Local Computer is Selected
	)
	# Connect to Remote Computer Registry
	$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $RemoteComputer)
	# Open Remote Sub Key
	$regKey= $reg.OpenSubKey($Key)
	if($regKey.ValueCount -gt 0) # check if there are Values 
	{$regKey.GetValue($Value)} # Return Value
}

function Get-WMIItem {
# Function Retreives a specific Item from a remote computer's WMI
	param(
		$Class,
		$RemoteComputer=".", # If not enterd Local Computer is Selected
		$Item,
		$Query="", # If not enterd an empty WMI SQL Query is Entered
		$Filter="" # If not enterd an empty Filter is Entered
	)
	if ($Query -eq "") # No Specific WMI SQL Query
	{
		# Execute WMI Query, Return only the Requsted Items
		gwmi -Class $Class -ComputerName $RemoteComputer -Filter $Filter -Property $Item | Select $Item
	}
	else # User Entered a WMI SQL Query
	{gwmi -ComputerName $RemoteComputer -Query $Query | select $Item}
}

function Show-NotifyIcon {
# Function Controls the Notification Icon
# Changes its Title and Text
	param(
		$Title,
		$Text
	)
		# Change Notify Icon Title
		$objNotifyIcon.BalloonTipTitle = $Title
		# Change Notify Icon Text
		$objNotifyIcon.BalloonTipText = $Text
		# Show Notify Icon for 10 Secs
		$objNotifyIcon.Visible = $TRUE 
		$objNotifyIcon.ShowBalloonTip(10000)
}

#endregion

#region Event Loop

function Main
# Main Function, Runs the Form
{
	[System.Windows.Forms.Application]::EnableVisualStyles()
	[System.Windows.Forms.Application]::Run($Form1)
}

#endregion


#region Event Handlers

function BrowseFile($object)
# Function for Running the OpenFileDialog
# Used when Clicking on the Browse Button
{
	$OpenFileDialog1.showdialog()
	$TextBox1.Text = $OpenFileDialog1.FileName
	$btnRun.Enabled = $TRUE
}

function Open-File( $object ){
# Function Open the Log File
	if(Test-Path $LogFile){
		Invoke-Item $LogFile
	}
}

function Show-PopUp
# Function for Showing Custom Pop up Forms
{
	param(
		$PopupTitle,
		$PopupText
		)
	#~~< PopupForm >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	$PopupForm = New-Object System.Windows.Forms.Form
	$PopupForm.ClientSize = New-Object System.Drawing.Size(381, 356)
	$PopupForm.ControlBox = $false
	$PopupForm.ShowInTaskbar = $false
	$PopupForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
	$PopupForm.Text = $PopupTitle
	#~~< PopupColse >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	$PopupColse = New-Object System.Windows.Forms.Button
	$PopupColse.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
	$PopupColse.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	$PopupColse.Location = New-Object System.Drawing.Point(137, 321)
	$PopupColse.Size = New-Object System.Drawing.Size(104, 23)
	$PopupColse.TabIndex = 0
	$PopupColse.Text = "Close"
	$PopupColse.UseVisualStyleBackColor = $true
	$PopupForm.AcceptButton = $PopupColse
	$PopupForm.CancelButton = $PopupColse
	#~~< PopupHeader >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	$PopupHeader = New-Object System.Windows.Forms.Label
	$PopupHeader.Font = New-Object System.Drawing.Font("Calibri", 15.75, ([System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold -bor [System.Drawing.FontStyle]::Italic)), [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
	$PopupHeader.Location = New-Object System.Drawing.Point(137, 9)
	$PopupHeader.Size = New-Object System.Drawing.Size(104, 23)
	$PopupHeader.TabIndex = 2
	$PopupHeader.Text = $PopupTitle
	$PopupHeader.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
	#~~< PopUpTextArea >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	$PopUpTextArea = New-Object System.Windows.Forms.Label
	$PopUpTextArea.Anchor = ([System.Windows.Forms.AnchorStyles]([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right))
	$PopUpTextArea.Location = New-Object System.Drawing.Point(12, 15)
	$PopUpTextArea.Size = New-Object System.Drawing.Size(357, 265)
	$PopUpTextArea.TabIndex = 1
	$PopUpTextArea.Text = $PopupText
	$PopUpTextArea.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
	$PopupForm.Controls.Add($PopupHeader)
	$PopupForm.Controls.Add($PopUpTextArea)
	$PopupForm.Controls.Add($PopupColse)
	
	# Show Form
	$PopupForm.Add_Shown({$PopupForm.Activate()})  
	[void]$PopupForm.showdialog() 

}

function Show-About( $object ){
# Function Opens the About Page
	$AboutText = @("
	Script Title:	            Remote Computer Inventory`n
	Script Author:              Assaf Miron`n
	Script Description:         Collects Remote Computer Data Using WMI and Registry Access Outputs all information to a Data Grid Form and to a CSV Log File.`n
	
	Log File Name:	$LogFile")
	
	Show-Popup -PopupTitle "About" -PopupText $AboutText
}

function Show-HowTo( $object ){
# Function Opens the Help Page
	$HowToText = @("
	1. Click on the Browse Button and select a TXT or a CSV File Containing Computer Names`n
	2. After File is Selected click on the Run Button.`n
	3. You will see a Notify Icon with the Coresponding Text.`n
	4. The Script has begon collecting Remote Computer Inventory!`n
	`nWhen The script is Done you will see a Popup Message and all data will be presented in the DataGrid.`n
	** Because Poweshell works only in MTA mode there is no Option Copying the Data off the DataGrid...`n
	5. All Data will be Exported to a Log File Located Here: $LogFile")
	
	Show-Popup -PopupTitle "How To?" -PopupText $HowToText
}

function CloseForm($object)
# Function End the Program
{
	$Form1.Close()
}

function RunScript($object)
# Function Runs the Program and starts collecting data
{
# Create an Array of Computers Enterd in the Input File
$arrComputers = Get-Content -path $textBox1.Text -encoding UTF8

# Create an Array to Keep all Computers Objects
$AllComputers = @()

# Init the Progress bar to it's Maximum Value
if(($arrComputers -is [array]) -eq $FALSE) { $ProgressBar1.Maximum = 1 }
else { $ProgressBar1.Maximum = $arrComputers.Count }
$ProgressBar1.Minimum = 0
$ProgressBar1.Value = 0
$ProgressBar1.Step = 1 # Define the Progress bar Step value

# Scan all Computers in the Array $arrComputers
foreach ($strComputer in $arrComputers)
	{ 
		# Uses the Ping Command to check if the Computer is Alive
		if($Ping1.Send($strComputer).Status -eq "Success"){
		Show-NotifyIcon -Title "Retriving Computer Information" -Text "Scanning $strComputer For Hardware Data" 

		# Collect Computer Details from Win32_computersystem Using WMI
		$ComputerDet = Get-WMIItem -Class "Win32_computersystem" -RemoteComputer $strComputer -Item Caption,Domain,SystemType,Manufacturer,Model,NumberOfProcessors,TotalPhysicalMemory,UserName
		
		if($ComputerDet.Caption.Length -gt 1) # Check to See if Any data was Collected at all
		{	

#region Total Memory Formating
			# Check Total Physical Memory Size and Format it acourdingly
			if($ComputerDet.TotalPhysicalMemory -ge 1GB){
			$ComputerDet.TotalPhysicalMemory = ($ComputerDet.TotalPhysicalMemory/1GB).Tostring("# GB")} # Format to GB
			else {$ComputerDet.TotalPhysicalMemory = ($ComputerDet.TotalPhysicalMemory/1MB).Tostring("# MB")} # Format to MB
#endregion

#region CPU Name
			# Collect CPU Name Using WMI
			$CPUName = Get-WMIItem -Class "Win32_Processor" -RemoteComputer $strComputer -Item Name
			# CPU Names Can Contain Multiple Values, in Order to Insert Them into the DataGridView I Divde them to String with ";" Seperators
			$arrCPUNames = @() 
			foreach($CPU in $CPUName){
				$arrCPUNames = $CPU.Name.Trim()+";"+$arrCPUNames # the Sting of the CPU Name has White Space in The Begining - Trim It
				}
#endregion	

#region Operating System Data
			# Collect Operating System and Service Pack Information Usin WMI
			$OS = Get-WMIItem -Class "win32_operatingsystem" -RemoteComputer $strComputer -Item Caption,csdversion
#endregion

#region Chassis Type
			# Collect Machine Chassis Using WMI
			$ChassisType = Get-WMIItem -Class Win32_SystemEnclosure -RemoteComputer $strComputer -Item ChassisTypes 
			# Select Machine Chassis
			switch ($ChassisType.ChassisTypes) {
					1 {$ChassisType = "Other"}
					2 {$ChassisType = "Unknown"}
					3 {$ChassisType = "Desktop"}
					4 {$ChassisType = "Low Profile Desktop"}
					5 {$ChassisType = "Pizza Box"}
					6 {$ChassisType = "Mini Tower"}
					7 {$ChassisType = "Tower"}
					8 {$ChassisType = "Portable"}
					9 {$ChassisType = "Laptop"}
					10 {$ChassisType = "Notebook"}
					11 {$ChassisType = "Handheld"}
					12 {$ChassisType = "Docking Station"}
					13 {$ChassisType = "All-in-One"}
					14 {$ChassisType = "Sub-Notebook"}
					15 {$ChassisType = "Space Saving"}
					16 {$ChassisType = "Lunch Box"}
					17 {$ChassisType = "Main System Chassis"}
					18 {$ChassisType = "Expansion Chassis"}
					19 {$ChassisType = "Sub-Chassis"}
					20 {$ChassisType = "Bus Expansion Chassis"}
					21 {$ChassisType = "Peripheral Chassis"}
					22 {$ChassisType = "Storage Chassis"}
					23 {$ChassisType = "Rack Mount Chassis"}
					24 {$ChassisType = "Sealed- PC"}
					default {$ChassisType = "Unknown"}
				}
#endregion

#region Automatic Updates
			# Collect the Automatic Updates Options Using Registry Access
			$AUOptions = Get-Reg -Hive LocalMachine -Key "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Value "AUOptions"
			
			# Collect the Automatic Updates Install Day Using Registry Access
			$AUDay = Get-Reg -Hive LocalMachine -Key "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Value "ScheduledInstallDay"
			
			# Collect the Automatic Updates Install Time Using Registry Access
			$AUTime = Get-Reg -Hive LocalMachine -Key "SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Value "ScheduledInstallTime"
			if($AUOptions -eq $null){ # Automatic Updates is defined in Group Policy
				$AUOptions = Get-Reg -Hive LocalMachine -Key "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Value "AUOptions"
				$AUDay = Get-Reg -Hive LocalMachine -Key "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Value "ScheduledInstallDay"
				$AUTime = Get-Reg -Hive LocalMachine -Key "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Value "ScheduledInstallTime"
				}
			switch ($AUOptions){ # Check Wich Automatic Update Option is Selected
				1 {$AUClient = "Automatic Updates is Turnd off."}
				2 {$AUClient = "Notify for download and notify for install "}
				3 {$AUClient = "Auto download and notify for install "}
				4 {
					switch ($AUDay) # Check on What day the Automatic Update Installs
					{
					0 {$InstDay = "Every Day"}
					1 {$InstDay = "Sunday"}
					2 {$InstDay = "Monday"}
					3 {$InstDay = "Tuesday"}
					4 {$InstDay = "Wensday"}
					5 {$InstDay = "Thursday"}
					6 {$InstDay = "Friday"}
					7 {$InstDay = "Saturday"}
					}
					# Check on What time the Automatic Update Installs
					if ($AUTime -le 12) { $AUTime = $AUTime.ToString() + " AM" } else { $AUTime = ($AUTime -12) + " PM" }
						$AUClient = "Auto download and schedule the install - "+$InstDay+" "+$AUTime}
				Defualt {"Automatic Updates is not Set."} # No setting Collected
			}
#endregion

#region Computer Total Health
			# Collect Avialable Memory with WMI
			$AvialableMem = Get-WMIItem -Class "Win32_PerfFormattedData_PerfOS_Memory" -RemoteComputer $strComputer -Item "AvailableMBytes"
			
			# Collect Disk Queue,Queue Length, Processor time Data Using WMI
			$DiskQueue = Get-WMIItem -Class "Win32_PerfFormattedData_PerfDisk_LogicalDisk" -RemoteComputer $strComputer -Item CurrentDiskQueueLength
			$QueueLength = Get-WMIItem -Class "Win32_PerfFormattedData_PerfNet_ServerWorkQueues" -RemoteComputer $strComputer -Item QueueLength
			$Processor = Get-WMIItem -Class "Win32_PerfFormattedData_PerfOS_Processor" -RemoteComputer $strComputer -Item PercentProcessorTime
			
			$intHealth = 0 # integer for Collecting Computer Total Health
			# Using the Avialable Memory to Check Computer Totla Health
			if($AvialableMem.AvailableMBytes -lt 4) { $intHealth += 1; $strHealth += "Low Free Memory;" }
			# Using Current Disk Queue Length to Check Computer Total Health
			if($DiskQueue.CurrentDiskQueueLength -gt 2) { $intHealth += 1; $strHealth += "High Disk Queue;" }
			# Using Queue Length to Check Computer Total Health
			if($QueueLength.QueueLength -gt 4) { $intHealth += 1; $strHealth += "Long Disk Queue;" }
			# Using Processor Time(%) to Check Computer Total Health
			if($Processor.PercentProcessorTime -gt 90) { $intHealth += 1; $strHealth += "Processor Usage Over 90%;" }
			# If the integer is Bigger than 1 so the computer is Unhealthy, Describe Computer Problems
			# Else The Computer is Healthy
			if($intHealth -gt 1) { $ComputerTotalHealth = "UnHealthy, " + $strHealth } else { $ComputerTotalHealth = "Healthy" }
#endregion	

#region Avialable Memory Formating
			# Format Avialable Memory MB
			$AvialableMem.AvailableMBytes = $AvialableMem.AvailableMBytes.ToString("# MB")
#endregion

#region Disk Drive Info			
			# Collect Disk Drive Information Using WMI
			$DriveInfo = Get-WMIItem -Class "Win32_LogicalDisk" -RemoteComputer $strComputer -Item Caption,Size,FreeSpace
			# Format Every Drive Size and Free Space
			foreach($DRSize in $DriveInfo)
				{ # Check Object Size and Format Acourdingly
					if($DRSize.Size -ge 1GB){
					$DRSize.Size = ($DRSize.Size/1GB).ToString("# GB") } # Format to GB
					else { $DRSize.Size = ($DRSize.Size/1MB).ToString("# MB") } # Format to MB
					if($DRSize.FreeSpace -ge 1GB){
					$DRSize.FreeSpace = ($DRSize.FreeSpace/1GB).ToString("# GB") } # Format to GB
					else { $DRSize.FreeSpace = ($DRSize.FreeSpace/1MB).ToString("# MB") } # Format to MB
				}
			# Disk Drives Can Contain Multiple Values, in Order to Insert Them into the DataGridView I divide them to Strings with ";" Seperators
			$arrDiskDrives = @() 
			$arrDiskSize = @() 
			$arrDiskFreeSpace = @() 
			foreach($Drive in $DriveInfo){
				$arrDiskDrives = $Drive.Caption+";"+$arrDiskDrives
				$arrDiskSize = $Drive.Size+";"+$arrDiskSize
				$arrDiskFreeSpace = $Drive.FreeSpace+";"+$arrDiskFreeSpace
				}
#endregion	

#region IP Addresses
			# Collect IPAddresses Using WMI, Filter only Enabled IPs
			$IPAddress = Get-WmiItem -Class "Win32_NetworkAdapterConfiguration" -Filter "IPEnabled = True" -RemoteComputer $strComputer -Item IPAddress
			# IPAddress Can Contain Multiple Values, in Order to Insert Them into the DataGridView I divide them to Strings with ";" Seperators
			$arrIPAddress = @() 
			foreach($IP in $IPAddress){
				$arrIPAddress = $IP.IPAddress[0]+";"+$arrIPAddress
				}
#endregion

#region Time Zone
			# Collect Time Zone Information Using WMI
			$TimeZone = Get-WMIItem -Class "Win32_TimeZone" -RemoteComputer $strComputer -Item Bias,StandardName
			$TimeZone.Bias = $TimeZone.Bias/60
#endregion

#region System Restore Status			
			# Collect System Restore Information Using Remote Registry
			$SysRestoreStatus = Get-Reg -Hive LocalMachine -RemoteComputer $strComputer -Key "SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Value "DisableSR"
			if ($SysRestoreStatus -eq 0) { $SysRestoreStatus = "Enabled" } else { $SysRestoreStatus = "Disabled" }
#endregion

#region Offline Files Status			
			# Collect Offline Files Information Using Remote Registry
			$OfflineFolStatus = Get-Reg -Hive LocalMachine -RemoteComputer $strComputer -Key "SOFTWARE\Microsoft\Windows\CurrentVersion\NetCache" -Value "Enabled"
			if ($OfflineFolStatus -eq 1) { $OfflineFolStatus = "Enabled" } else { $OfflineFolStatus = "Disabled" }
#endregion

#region Printers
			# Collect Printers Information Using WMI
			$Printers = Get-WMIItem -Class "Win32_Printer" -RemoteComputer $strComputer -Item Name,PortName,Caption
			# Printers Contain Multiple Values, in Order to Insert Them into the DataGridView I divide them to Strings with ";" Seperators
			$arrPrinters = @() 
			foreach($Printer in $Printers){
				$arrPrinters = $Printer.Name+"("+$Printer.PortName+");"+$arrPrinters
				}
#endregion

#region BIOS Serial Number
			# Collect BIOS Serial Number Using WMI
			$BIOSSN = Get-WMIItem -Class "Win32_Bios" -RemoteComputer $strComputer -Item SerialNumber
#endregion

#region Network Drives
			# Collect Network Drives Using WMI
			$NetDrives = Get-WMIItem -Query "Select * From Win32_LogicalDisk Where DriveType = 4" -RemoteComputer $strComputer -Item DeviceID,ProviderName
			# Network Drives Contain Multiple Values, in Order to Insert Them into the DataGridView I divide them to Strings with ";" Seperators
			$arrNetDrives = @() 
			foreach($NetDrive in $NetDrives){
				$arrNetDrives = $NetDrive.DeviceID+"("+$NetDrive.ProviderName+");"+$arrNetDrives
				}
#endregion

#region Anti-Virus Client Data
			# Collect Anti-Virus Info Using Remote Registry
			$AVParentServer = Get-Reg -Hive LocalMachine -RemoteComputer $strComputer -Key "SOFTWARE\Intel\LANDesk\VirusProtect6\CurrentVersion" -Value "Parent"
			# Read the Anti-Virus Virus Definition File and Format it to an actual Date
			$VirusDefFile = "C:\Program Files\Common Files\Symantec Shared\VirusDefs\definfo.dat"
			If(Test-Path $VirusDefFile){
				$AVDefs = Get-Content $VirusDefFile | where { $_ -match "CurDefs" }
				$AVDefs = $AVDefs.Substring(8)
				$AVDefs = [datetime]($AVDefs.Substring(5,1)  + "/" + $AVDefs.Substring(6,2) + "/" + $AVDefs.substring(0,4))
			}
			Else { $AVDefs = "" }
#endregion

#region Operating Systems Hotfixes
			# Collect all Hotfix Information Using WMI
			$HotFixes = Get-WMIItem -Class "Win32_QuickFixEngineering" -RemoteComputer $strComputer -Item Description,HotFixID,ServicePackInEffect
			# HotFixes Contain Multiple Values, in Order to Insert Them into the DataGridView I divide them to Strings with ";" Seperators
			$arrHotFixes = @()
			foreach($Fix in $HotFixes){
				if($Fix.Description -eq ""){
					if($Fix.HotFixID -eq "File 1"){	$arrHotFixes = $Fix.ServicePackInEffect+";"+$arrHotFixes }
					else { $arrHotFixes =$Fix.HotFixID+";"+$arrHotFixes }
				}
				else { $arrHotFixes = $Fix.Description+";"+$arrHotFixes }
			}
#endRegion			

#region Remote Desktop Status
			# Collect Remote Desktop Protocol Status Using Remote Registry
			$RDPStatus = Get-Reg -Hive LocalMachine -remoteComputer $strComputer -Key "SYSTEM\CurrentControlSet\Control\Terminal Server" -Value "fAllowToGetHelp"
			if($RDPStatus -eq 0) {$RDPStatus = "Enabled" } else {$RDPStatus = "Disabled" }
#endregion

#region Remote Assistance Status			
			# Collect Remote Assistance Status Using Remote Registry
			$RAStatus = Get-Reg -Hive LocalMachine -remoteComputer $strComputer -Key "SYSTEM\CurrentControlSet\Control\Terminal Server" -Value "fDenyTSConnections"
			if($RAStatus -eq 1) {$RAStatus = "Enabled" } else {$RAStatus = "Disabled" }
#endregion

			# Change the Notify Icon to Show Exporting Text
			Show-NotifyIcon -Text "Exporting $strComputer Information" -Title "Exporting..."
			
#region Check the Null Valued Paramters
			# If one of the Parameters are Null, Enter Space (looks better in the Table)
			if($ComputerDet -eq $Null){ $ComputerDet = " " }
			if($ChassisType -eq $Null){ $ChassisType = " " }
			if($BIOSSN -eq $Null){ $BIOSSN = " " }
			if($CPUName -eq $Null){ $CPUName = " " }
			if($AvialableMem -eq $Null){ $AvialableMem = " " }	
			if($OS -eq $Null){ $OS = " " }
			if($SP -eq $Null){ $SP = " " }
			if($IPAddress -eq $Null){ $IPAddress = " " }
			if($HotFixes -eq $Null){ $HotFixes = " " }
			if($arrDiskDrives -eq $Null){ $arrDiskDrives=" " }
			if($arrDiskFreeSpace -eq $Null){ $arrDiskFreeSpace=" " }
			if($arrDiskSize -eq $Null){ $arrDiskSize=" " }
			if($RDPStatus -eq $Null){ $RDPStatus = " " }
			if($RAStatus -eq $Null){ $RAStatus = " " }
			if($AUClient -eq $Null){ $AUClient = " " }
			if($AVParentServer -eq $Null){ $AVParentServer = " " }
			if($AVDefs -eq $Null){ $AVDefs = " " }
			if($Printers -eq $Null){ $Printers = " " }
			if($ComputerTotalHealth -eq $Null){ $ComputerTotalHealth = " " }
#endregion

#region Creating the Data Object - $DataObject
			# Create an Empty psObject, $DataObjcet - Used by this Name in the Join-Data Function
			$DataObject = New-Object psobject
			# Join all the Data to the DataObject
			$ComputerDet | Join-Data # Contians Multiple Values, No need to Define a Name
			$ChassisType | Join-Data -objName "Chassis Type" # String with no Values - Define a Name
			$BIOSSN | Join-Data # Contians Multiple Values, No need to Define a Name
			$CPUName | Join-Data # Contians Multiple Values, No need to Define a Name
			$AvialableMem | Join-Data # Contians Multiple Values, No need to Define a Name
			$OS.Caption | Join-Data -objName "Operating System" # Contians Multiple Values, Caption Value canot be overwritten - Define a Name to a certian Value
			$OS.CsdVersion | Join-Data -objName "Service Pack" # String with no Values - Define a Name
			$arrIPAddress | Join-Data -objName "IP Addresses" # String with no Values - Define a Name
			$arrHotFixes| Join-Data -objName "HotFixes" # String with no Values - Define a Name
			$arrDiskDrives| Join-Data -objName "Disk Drives" # String with no Values - Define a Name
			$RDPStatus.ToString() | Join-Data -objName "Remote Desktop" # String with no Values - Define a Name			
			$RAStatus.ToString()  | Join-Data -objName "Remote Assistance" # String with no Values - Define a Name
			$AUClient  | Join-Data -objName "Automatic Updates" # String with no Values - Define a Name			
			$AVParentServer  | Join-Data -objName "Anti-Virus Server" # String with no Values - Define a Name
			$AVDefs | Join-Data -objName "Anti-Virus Defs" # String with no Values - Define a Name
			$arrPrinters | Join-Data  -objName "Printers" # String with no Values - Define a Name
			$ComputerTotalHealth | Join-Data -objName "Computer Totla Health" # String with no Values - Define a Name
#endregion
			$AllComputers += $DataObject
#region Exporting data
			# Export the DataObject to the DataGridView Using the out-DataTable
			$DataTable = $AllComputers | out-dataTable
			# Define Data Grid's Data Source to the DataTable we Created
			$DataGridView1.DataSource = $DataTable.psObject.baseobject

			$DataGridView1.Refresh() # Refresh the Table View in order to View the new lines
			
			# Export all the Data to the Log File
			$AllComputers | Export-Csv -Encoding OEM -Path $LogFile
#endregion

		} 
		}
		else { # No Ping to Computer
			$objNotifyIcon.BalloonTipIcon = "Error" 
			Show-NotifyIcon -Title "$strComputer is not avialable" -Text "No Ping to $strComputer.`nNo Data was Collected"
			$objNotifyIcon.BalloonTipIcon = "Info" 
		  }
	   
		$ProgressBar1.PerformStep()
	  }
	

#region Finishing - Script is Done

# Assign an Icon and Icon Type For the NotifyIcon Object
$objNotifyIcon.Icon = "D:\Assaf\Scripts\Icons\XP\people5.ico"
$objNotifyIcon.BalloonTipIcon = "Info" 

# Pop Up a Message box
$MSGObject = new-object -comobject wscript.shell
$MSGResult = $MSGObject.popup("Script Has Finished Running!",0,"I'm Done",0)

# Show Notify Icon with Finishing Text
$objNotifyIcon.BalloonTipText = "Done!`nFile Saved in "+$LogFile
$objNotifyIcon.Visible = $TRUE 
$objNotifyIcon.ShowBalloonTip(10000)
$objNotifyIcon.Visible = $FALSE # Set to False so that the Notify Icon will Disapear after the Script is Done

#endregion
}

Main # This call must remain below all other event functions

#endregion