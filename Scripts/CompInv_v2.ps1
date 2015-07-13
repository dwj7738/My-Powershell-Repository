# ==============================================================================================
# 
# Microsoft PowerShell Source File -- Created with SAPIEN Technologies PrimalScript 2007
# 
# NAME: Server/Workstation Inventory (CompInv_v2.ps1)
# 
# AUTHOR: Jesse Hamrick
# DATE  : 2/25/2009
# Web	: www.PowerShellPro.com
# COMMENT: Script Inventories Computers and sends results to an excel file.
# 
# ==============================================================================================

# ==============================================================================================
# Functions Section
# ==============================================================================================
# Function Name 'WMILookup' - Gathers info using WMI and places results in Excel
# ==============================================================================================
Function WMILookup {
foreach ($StrComputer in $colComputers){
		$GenItems1 = gwmi Win32_ComputerSystem -Comp $StrComputer
		$GenItems2 = gwmi Win32_OperatingSystem -Comp $StrComputer
		$SysItems1 = gwmi Win32_BIOS -Comp $StrComputer
		$SysItems2 = gwmi Win32_TimeZone -Comp $StrComputer
		$SysItems3 = gwmi Win32_WmiSetting -Comp $StrComputer
		$ProcItems1 = gwmi Win32_Processor -Comp $StrComputer
		$MemItems1 = gwmi Win32_PhysicalMemory -Comp $StrComputer
		$memItems2 = gwmi Win32_PhysicalMemoryArray -Comp $StrComputer
		$DiskItems = gwmi Win32_LogicalDisk -Comp $StrComputer
		$NetItems = gwmi Win32_NetworkAdapterConfiguration -Comp $StrComputer |`
					where{$_.IPEnabled -eq "True"}
		
				
# Populate General Sheet(1) with information
	foreach ($objItem in $GenItems1){
		$Sheet1.Cells.Item($intRow, 1) = $StrComputer
		Switch($objItem.DomainRole)
			{
			0{$Sheet1.Cells.Item($intRow, 2) = "Stand Alone Workstation"}
			1{$Sheet1.Cells.Item($intRow, 2) = "Member Workstation"}
			2{$Sheet1.Cells.Item($intRow, 2) = "Stand Alone Server"}
			3{$Sheet1.Cells.Item($intRow, 2) = "Member Server"}
			4{$Sheet1.Cells.Item($intRow, 2) = "Back-up Domain Controller"}
			5{$Sheet1.Cells.Item($intRow, 2) = "Primary Domain Controller"}
			default{"Undetermined"}
			}
		$Sheet1.Cells.Item($intRow, 3) = $objItem.Manufacturer
		$Sheet1.Cells.Item($intRow, 4) = $objItem.Model
		$Sheet1.Cells.Item($intRow, 5) = $objItem.SystemType
		$Sheet1.Cells.Item($intRow, 6) = $objItem.NumberOfProcessors
		$Sheet1.Cells.Item($intRow, 7) = $objItem.TotalPhysicalMemory / 1024 / 1024
		}
	foreach ($objItem in $GenItems2){
		$Sheet1.Cells.Item($intRow, 8) = $objItem.Caption
		$Sheet1.Cells.Item($intRow, 9) = $objItem.csdversion
		}
			
#Populate Systems Sheet
	foreach ($objItem in $SysItems1){
		$Sheet2.Cells.Item($intRow, 1) = $StrComputer
		$Sheet2.Cells.Item($intRow, 2) = $objItem.Name
		$Sheet2.Cells.Item($intRow, 3) = $objItem.SMBIOSbiosVersion
		$Sheet2.Cells.Item($intRow, 4) = $objItem.SerialNumber
		}
	foreach ($objItem in $SysItems2){	
		$Sheet2.Cells.Item($intRow, 5) = $objItem.Caption
		}
	foreach ($objItem in $SysItems3){
		$Sheet2.Cells.Item($intRow, 6) = $objItem.BuildVersion
		}
				
#Populate Processor Sheet		
	foreach ($objItem in $ProcItems1){
		$Sheet3.Cells.Item($intRowCPU, 1) = $StrComputer
		$Sheet3.Cells.Item($intRowCPU, 2) = $objItem.DeviceID+" "+$objItem.Name
		$Sheet3.Cells.Item($intRowCPU, 3) = $objItem.Description
		$Sheet3.Cells.Item($intRowCPU, 4) = $objItem.family
		$Sheet3.Cells.Item($intRowCPU, 5) = $objItem.currentClockSpeed
		$Sheet3.Cells.Item($intRowCPU, 6) = $objItem.l2cacheSize
		$Sheet3.Cells.Item($intRowCPU, 7) = $objItem.UpgradeMethod
		$Sheet3.Cells.Item($intRowCPU, 8) = $objItem.SocketDesignation
		$intRowCPU = $intRowCPU + 1
		}
				
#Populate Memory Sheet
$bankcounter = 1
	foreach ($objItem in $memItems2){
		$MemSlots = $objItem.MemoryDevices +1
			
	foreach ($objItem in $MemItems1){
		$Sheet4.Cells.Item($intRowMem, 1) = $StrComputer
		$Sheet4.Cells.Item($intRowMem, 2) = "Bank " +$bankcounter
	if($objItem.BankLabel -eq ""){
		$Sheet4.Cells.Item($intRowMem, 3) = $objItem.DeviceLocator}
	Else{$Sheet4.Cells.Item($intRowMem, 3) = $objItem.BankLabel}
		$Sheet4.Cells.Item($intRowMem, 4) = $objItem.Capacity/1024/1024
		$Sheet4.Cells.Item($intRowMem, 5) = $objItem.FormFactor
		$Sheet4.Cells.Item($intRowMem, 6) = $objItem.TypeDetail
		$intRowMem = $intRowMem + 1
		$bankcounter = $bankcounter + 1
		}
	while($bankcounter -lt $MemSlots)	
		{
		$Sheet4.Cells.Item($intRowMem, 1) = $StrComputer
		$Sheet4.Cells.Item($intRowMem, 2) = "Bank " +$bankcounter
		$Sheet4.Cells.Item($intRowMem, 3) = "is Empty"
		$Sheet4.Cells.Item($intRowMem, 4) = ""
		$Sheet4.Cells.Item($intRowMem, 5) = ""
		$Sheet4.Cells.Item($intRowMem, 6) = ""
		$intRowMem = $intRowMem + 1
		$bankcounter = $bankcounter + 1
		}
	}
			
			
#Populate Disk Sheet
	foreach ($objItem in $DiskItems){
		$Sheet5.Cells.Item($intRowDisk, 1) = $StrComputer
		Switch($objItem.DriveType)
		{
		2{$Sheet5.Cells.Item($intRowDisk, 2) = "Floppy"}
		3{$Sheet5.Cells.Item($intRowDisk, 2) = "Fixed Disk"}
		5{$Sheet5.Cells.Item($intRowDisk, 2) = "Removable Media"}
		default{"Undetermined"}
		}
		$Sheet5.Cells.Item($intRowDisk, 3) = $objItem.DeviceID
		$Sheet5.Cells.Item($intRowDisk, 4) = $objItem.Size/1024/1024
		$Sheet5.Cells.Item($intRowDisk, 5) = $objItem.FreeSpace/1024/1024
		$intRowDisk = $intRowDisk + 1
		}
		
#Populate Network Sheet
	foreach ($objItem in $NetItems){
		$Sheet6.Cells.Item($intRowNet, 1) = $StrComputer
		$Sheet6.Cells.Item($intRowNet, 2) = $objItem.Caption+" (enabled)"
		$Sheet6.Cells.Item($intRowNet, 3) = $objItem.DHCPEnabled
		$Sheet6.Cells.Item($intRowNet, 4) = $objItem.IPAddress
		$Sheet6.Cells.Item($intRowNet, 5) = $objItem.IPSubnet
		$Sheet6.Cells.Item($intRowNet, 6) = $objItem.DefaultIPGateway
		$Sheet6.Cells.Item($intRowNet, 7) = $objItem.DNSServerSearchOrder
		$Sheet6.Cells.Item($intRowNet, 8) = $objItem.FullDNSRegistrationEnabled
		$Sheet6.Cells.Item($intRowNet, 9) = $objItem.WINSPrimaryServer
		$Sheet6.Cells.Item($intRowNet, 10) = $objItem.WINSSecondaryServer
		$Sheet6.Cells.Item($intRowNet, 11) = $objItem.WINSEnableLMHostsLookup
		$intRowNet = $intRowNet + 1
		}
		
$intRow = $intRow + 1
$intRowCPU = $intRowCPU + 1
$intRowMem = $intRowMem + 1
$intRowDisk = $intRowDisk + 1
$intRowNet = $intRowNet + 1
}
}

# ==============================================================================================
# Function Name 'WMILookupCred'-Uses Alternative Credential-Gathers info using WMI.
# ==============================================================================================
Function WMILookupCred {
foreach ($StrComputer in $colComputers){
		$GenItems1 = gwmi Win32_ComputerSystem -Comp $StrComputer -Credential $cred
		$GenItems2 = gwmi Win32_OperatingSystem -Comp $StrComputer -Credential $cred
		$SysItems1 = gwmi Win32_BIOS -Comp $StrComputer -Credential $cred
		$SysItems2 = gwmi Win32_TimeZone -Comp $StrComputer -Credential $cred
		$SysItems3 = gwmi Win32_WmiSetting -Comp $StrComputer -Credential $cred
		$ProcItems1 = gwmi Win32_Processor -Comp $StrComputer -Credential $cred
		$MemItems1 = gwmi Win32_PhysicalMemory -Comp $StrComputer -Credential $cred
		$memItems2 = gwmi Win32_PhysicalMemoryArray -Comp $StrComputer -Credential $cred
		$DiskItems = gwmi Win32_LogicalDisk -Comp $StrComputer -Credential $cred
		$NetItems = gwmi Win32_NetworkAdapterConfiguration -Comp $StrComputer -Credential $cred |`
					where{$_.IPEnabled -eq "True"}
		
				
# Populate General Sheet(1) with information
	foreach ($objItem in $GenItems1){
		$Sheet1.Cells.Item($intRow, 1) = $StrComputer
		Switch($objItem.DomainRole)
			{
			0{$Sheet1.Cells.Item($intRow, 2) = "Stand Alone Workstation"}
			1{$Sheet1.Cells.Item($intRow, 2) = "Member Workstation"}
			2{$Sheet1.Cells.Item($intRow, 2) = "Stand Alone Server"}
			3{$Sheet1.Cells.Item($intRow, 2) = "Member Server"}
			4{$Sheet1.Cells.Item($intRow, 2) = "Back-up Domain Controller"}
			5{$Sheet1.Cells.Item($intRow, 2) = "Primary Domain Controller"}
			default{"Undetermined"}
			}
		$Sheet1.Cells.Item($intRow, 3) = $objItem.Manufacturer
		$Sheet1.Cells.Item($intRow, 4) = $objItem.Model
		$Sheet1.Cells.Item($intRow, 5) = $objItem.SystemType
		$Sheet1.Cells.Item($intRow, 6) = $objItem.NumberOfProcessors
		$Sheet1.Cells.Item($intRow, 7) = $objItem.TotalPhysicalMemory / 1024 / 1024
		}
	foreach ($objItem in $GenItems2){
		$Sheet1.Cells.Item($intRow, 8) = $objItem.Caption
		$Sheet1.Cells.Item($intRow, 9) = $objItem.csdversion
		}
			
#Populate Systems Sheet
	foreach ($objItem in $SysItems1){
		$Sheet2.Cells.Item($intRow, 1) = $StrComputer
		$Sheet2.Cells.Item($intRow, 2) = $objItem.Name
		$Sheet2.Cells.Item($intRow, 3) = $objItem.SMBIOSbiosVersion
		$Sheet2.Cells.Item($intRow, 4) = $objItem.SerialNumber
		}
	foreach ($objItem in $SysItems2){	
		$Sheet2.Cells.Item($intRow, 5) = $objItem.Caption
		}
	foreach ($objItem in $SysItems3){
		$Sheet2.Cells.Item($intRow, 6) = $objItem.BuildVersion
		}
				
#Populate Processor Sheet		
	foreach ($objItem in $ProcItems1){
		$Sheet3.Cells.Item($intRowCPU, 1) = $StrComputer
		$Sheet3.Cells.Item($intRowCPU, 2) = $objItem.DeviceID+" "+$objItem.Name
		$Sheet3.Cells.Item($intRowCPU, 3) = $objItem.Description
		$Sheet3.Cells.Item($intRowCPU, 4) = $objItem.family
		$Sheet3.Cells.Item($intRowCPU, 5) = $objItem.currentClockSpeed
		$Sheet3.Cells.Item($intRowCPU, 6) = $objItem.l2cacheSize
		$Sheet3.Cells.Item($intRowCPU, 7) = $objItem.UpgradeMethod
		$Sheet3.Cells.Item($intRowCPU, 8) = $objItem.SocketDesignation
		$intRowCPU = $intRowCPU + 1
		}
				
#Populate Memory Sheet
$bankcounter = 1
	foreach ($objItem in $memItems2){
		$MemSlots = $objItem.MemoryDevices +1
			
	foreach ($objItem in $MemItems1){
		$Sheet4.Cells.Item($intRowMem, 1) = $StrComputer
		$Sheet4.Cells.Item($intRowMem, 2) = "Bank " +$bankcounter
	if($objItem.BankLabel -eq ""){
		$Sheet4.Cells.Item($intRowMem, 3) = $objItem.DeviceLocator}
	Else{$Sheet4.Cells.Item($intRowMem, 3) = $objItem.BankLabel}
		$Sheet4.Cells.Item($intRowMem, 4) = $objItem.Capacity/1024/1024
		$Sheet4.Cells.Item($intRowMem, 5) = $objItem.FormFactor
		$Sheet4.Cells.Item($intRowMem, 6) = $objItem.TypeDetail
		$intRowMem = $intRowMem + 1
		$bankcounter = $bankcounter + 1
		}
	while($bankcounter -lt $MemSlots)	
		{
		$Sheet4.Cells.Item($intRowMem, 1) = $StrComputer
		$Sheet4.Cells.Item($intRowMem, 2) = "Bank " +$bankcounter
		$Sheet4.Cells.Item($intRowMem, 3) = "is Empty"
		$Sheet4.Cells.Item($intRowMem, 4) = ""
		$Sheet4.Cells.Item($intRowMem, 5) = ""
		$Sheet4.Cells.Item($intRowMem, 6) = ""
		$intRowMem = $intRowMem + 1
		$bankcounter = $bankcounter + 1
		}
	}
			
			
#Populate Disk Sheet
	foreach ($objItem in $DiskItems){
		$Sheet5.Cells.Item($intRowDisk, 1) = $StrComputer
		Switch($objItem.DriveType)
		{
		2{$Sheet5.Cells.Item($intRowDisk, 2) = "Floppy"}
		3{$Sheet5.Cells.Item($intRowDisk, 2) = "Fixed Disk"}
		5{$Sheet5.Cells.Item($intRowDisk, 2) = "Removable Media"}
		default{"Undetermined"}
		}
		$Sheet5.Cells.Item($intRowDisk, 3) = $objItem.DeviceID
		$Sheet5.Cells.Item($intRowDisk, 4) = $objItem.Size/1024/1024
		$Sheet5.Cells.Item($intRowDisk, 5) = $objItem.FreeSpace/1024/1024
		$intRowDisk = $intRowDisk + 1
		}
		
#Populate Network Sheet
	foreach ($objItem in $NetItems){
		$Sheet6.Cells.Item($intRowNet, 1) = $StrComputer
		$Sheet6.Cells.Item($intRowNet, 2) = $objItem.Caption+" (enabled)"
		$Sheet6.Cells.Item($intRowNet, 3) = $objItem.DHCPEnabled
		$Sheet6.Cells.Item($intRowNet, 4) = $objItem.IPAddress
		$Sheet6.Cells.Item($intRowNet, 5) = $objItem.IPSubnet
		$Sheet6.Cells.Item($intRowNet, 6) = $objItem.DefaultIPGateway
		$Sheet6.Cells.Item($intRowNet, 7) = $objItem.DNSServerSearchOrder
		$Sheet6.Cells.Item($intRowNet, 8) = $objItem.FullDNSRegistrationEnabled
		$Sheet6.Cells.Item($intRowNet, 9) = $objItem.WINSPrimaryServer
		$Sheet6.Cells.Item($intRowNet, 10) = $objItem.WINSSecondaryServer
		$Sheet6.Cells.Item($intRowNet, 11) = $objItem.WINSEnableLMHostsLookup
		$intRowNet = $intRowNet + 1
		}
		
$intRow = $intRow + 1
$intRowCPU = $intRowCPU + 1
$intRowMem = $intRowMem + 1
$intRowDisk = $intRowDisk + 1
$intRowNet = $intRowNet + 1
}
}

# =============================================================================================
# Function Name 'ListComputers' - Enumerates ALL computer objects in AD
# ==============================================================================================
Function ListComputers {
$strCategory = "computer"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = ("(objectCategory=$strCategory)")

$colProplist = "name"
foreach ($i in $colPropList){$objSearcher.PropertiesToLoad.Add($i)}

$colResults = $objSearcher.FindAll()

foreach ($objResult in $colResults)
    {$objComputer = $objResult.Properties; $objComputer.name}
}

# ==============================================================================================
# Function Name 'ListServers' - Enumerates ALL Servers objects in AD
# ==============================================================================================
Function ListServers {
$strCategory = "computer"
$strOS = "Windows*Server*"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = ("(&(objectCategory=$strCategory)(OperatingSystem=$strOS))")

$colProplist = "name"
foreach ($i in $colPropList){$objSearcher.PropertiesToLoad.Add($i)}

$colResults = $objSearcher.FindAll()

foreach ($objResult in $colResults)
    {$objComputer = $objResult.Properties; $objComputer.name}
}

# ========================================================================
# Function Name 'ListTextFile' - Enumerates Computer Names in a text file
# Create a text file and enter the names of each computer. One computer
# name per line. Supply the path to the text file when prompted.
# ========================================================================
Function ListTextFile {
	$strText = Read-Host "Enter the path for the text file"
	$colComputers = Get-Content $strText
}

# ========================================================================
# Function Name 'SingleEntry' - Enumerates Computer from user input
# ========================================================================
Function ManualEntry {
	$colComputers = Read-Host "Enter Computer Name or IP" 
}

# ==============================================================================================
# Script Body
# ==============================================================================================
$erroractionpreference = "SilentlyContinue"


#Gather info from user.
Write-Host "********************************" 	-ForegroundColor Green
Write-Host "Computer Inventory Script" 			-ForegroundColor Green
Write-Host "By: Jesse Hamrick" 					-ForegroundColor Green
Write-Host "Created: 04/15/2009" 				-ForegroundColor Green
Write-Host "Contact: www.PowerShellPro.com" 	-ForegroundColor Green
Write-Host "********************************" 	-ForegroundColor Green
Write-Host " "
Write-Host "Admin rights are required to enumerate information." 	-ForegroundColor Green
Write-Host "Would you like to use an alternative credential?"		-ForegroundColor Green
$credResponse = Read-Host "[Y] Yes, [N] No"
	If($CredResponse -eq "y"){$cred = Get-Credential DOMAIN\USER}
Write-Host " "
Write-Host "Which computer resources would you like in the report?"	-ForegroundColor Green
$strResponse = Read-Host "[1] All Domain Computers, [2] All Domain Servers, [3] Computer names from a File, [4] Choose a Computer manually"
If($strResponse -eq "1"){$colComputers = ListComputers | Sort-Object}
	elseif($strResponse -eq "2"){$colComputers = ListServers | Sort-Object}
	elseif($strResponse -eq "3"){. ListTextFile}
	elseif($strResponse -eq "4"){. ManualEntry}
	else{Write-Host "You did not supply a correct response, `
	Please run script again." -foregroundColor Red}				
Write-Progress -Activity "Getting Inventory" -status "Running..." -id 1

#New Excel Application
$Excel = New-Object -Com Excel.Application
$Excel.visible = $True

# Create 6 worksheets
$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.Worksheets.Add()
$Sheet = $Excel.Worksheets.Add()
$Sheet = $Excel.Worksheets.Add()

# Assign each worksheet to a variable and
# name the worksheet.
$Sheet1 = $Excel.Worksheets.Item(1)
$Sheet2 = $Excel.WorkSheets.Item(2)
$Sheet3 = $Excel.WorkSheets.Item(3)
$Sheet4 = $Excel.WorkSheets.Item(4)
$Sheet5 = $Excel.WorkSheets.Item(5)
$Sheet6 = $Excel.WorkSheets.Item(6)
$Sheet1.Name = "General"
$Sheet2.Name = "System"
$Sheet3.Name = "Processor"
$Sheet4.Name = "Memory"
$Sheet5.Name = "Disk"
$Sheet6.Name = "Network"

#Create Heading for General Sheet
$Sheet1.Cells.Item(1,1) = "Device_Name"
$Sheet1.Cells.Item(1,2) = "Role"
$Sheet1.Cells.Item(1,3) = "HW_Make"
$Sheet1.Cells.Item(1,4) = "HW_Model"
$Sheet1.Cells.Item(1,5) = "HW_Type"
$Sheet1.Cells.Item(1,6) = "CPU_Count"
$Sheet1.Cells.Item(1,7) = "Memory_MB"
$Sheet1.Cells.Item(1,8) = "Operating_System"
$Sheet1.Cells.Item(1,9) = "SP_Level"

#Create Heading for System Sheet
$Sheet2.Cells.Item(1,1) = "Device_Name"
$Sheet2.Cells.Item(1,2) = "BIOS_Name"
$Sheet2.Cells.Item(1,3) = "BIOS_Version"
$Sheet2.Cells.Item(1,4) = "HW_Serial_#"
$Sheet2.Cells.Item(1,5) = "Time_Zone"
$Sheet2.Cells.Item(1,6) = "WMI_Version"

#Create Heading for Processor Sheet
$Sheet3.Cells.Item(1,1) = "Device_Name"
$Sheet3.Cells.Item(1,2) = "Processor(s)"
$Sheet3.Cells.Item(1,3) = "Type"
$Sheet3.Cells.Item(1,4) = "Family"
$Sheet3.Cells.Item(1,5) = "Speed_MHz"
$Sheet3.Cells.Item(1,6) = "Cache_Size_MB"
$Sheet3.Cells.Item(1,7) = "Interface"
$Sheet3.Cells.Item(1,8) = "#_of_Sockets"

#Create Heading for Memory Sheet
$Sheet4.Cells.Item(1,1) = "Device_Name"
$Sheet4.Cells.Item(1,2) = "Bank_#"
$Sheet4.Cells.Item(1,3) = "Label"
$Sheet4.Cells.Item(1,4) = "Capacity_MB"
$Sheet4.Cells.Item(1,5) = "Form"
$Sheet4.Cells.Item(1,6) = "Type"

#Create Heading for Disk Sheet
$Sheet5.Cells.Item(1,1) = "Device_Name"
$Sheet5.Cells.Item(1,2) = "Disk_Type"
$Sheet5.Cells.Item(1,3) = "Drive_Letter"
$Sheet5.Cells.Item(1,4) = "Capacity_MB"
$Sheet5.Cells.Item(1,5) = "Free_Space_MB"

#Create Heading for Network Sheet
$Sheet6.Cells.Item(1,1) = "Device_Name"
$Sheet6.Cells.Item(1,2) = "Network_Card"
$Sheet6.Cells.Item(1,3) = "DHCP_Enabled"
$Sheet6.Cells.Item(1,4) = "IP_Address"
$Sheet6.Cells.Item(1,5) = "Subnet_Mask"
$Sheet6.Cells.Item(1,6) = "Default_Gateway"
$Sheet6.Cells.Item(1,7) = "DNS_Servers"
$Sheet6.Cells.Item(1,8) = "DNS_Reg"
$Sheet6.Cells.Item(1,9) = "Primary_WINS"
$Sheet6.Cells.Item(1,10) = "Secondary_WINS"
$Sheet6.Cells.Item(1,11) = "WINS_Lookup"

$colSheets = ($Sheet1, $Sheet2, $Sheet3, $Sheet4, $Sheet5, $Sheet6)
foreach ($colorItem in $colSheets){
$intRow = 2
$intRowCPU = 2
$intRowMem = 2
$intRowDisk = 2
$intRowNet = 2
$WorkBook = $colorItem.UsedRange
$WorkBook.Interior.ColorIndex = 20
$WorkBook.Font.ColorIndex = 11
$WorkBook.Font.Bold = $True
}

If($credResponse -eq "y"){WMILookupCred}
Else{WMILookup}

#Auto Fit all sheets in the Workbook
foreach ($colorItem in $colSheets){
$WorkBook = $colorItem.UsedRange															
$WorkBook.EntireColumn.AutoFit()
clear
}
Write-Host "*******************************" -ForegroundColor Green
Write-Host "The Report has been completed."  -ForeGroundColor Green
Write-Host "*******************************" -ForegroundColor Green
# ========================================================================
# END of Script
# ========================================================================

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUT9mkuHb5GjGyfYZet0/RXEMR
# pHugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJbSp5z7WoqpEWY6
# 8FhGFPniBCZZMA0GCSqGSIb3DQEBAQUABIIBAATjnG17YPy/5IJRclYPzoFVw9Cj
# XxB0dweGyZ5hLrljAhKbGHY9lS8ZWfbw0te7l7jvgJQ1qWAVF2er7t1Jfem615Bh
# MS0NAFu69f+zVyj6mMFwn75gqvUr8isOYu+MuozWYnYJFkUDV2egHseiMoo53QbJ
# VRabZ39RkH4OJOxylHR302hP8ITqL3LaVUjQEwyzAJh+4i2VwXOSIeh4WxXOc1/q
# FuNMkvYdX8uPBQlf0PXGmNbSxVZ6hiFoweMoP7UWhmC7l2yA9dNpe5YWua9VN1Eq
# ifPTSRDDWKlOKjTX2jdDrEvMuyRmBxLlxcf6s3206RLYa5wLw00jJWH7oJQ=
# SIG # End signature block
