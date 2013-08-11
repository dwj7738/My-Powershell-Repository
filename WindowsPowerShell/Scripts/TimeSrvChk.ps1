# ==============================================================================================
# 
# Microsoft PowerShell Source File -- Created with SAPIEN Technologies PrimalScript 2007
# 
# NAME:		TimeSrvChk.ps1 	
# AUTHOR: 	Jesse Hamrick
# DATE  : 	4/29/2009
# Web	:	www.PowerShellPro.com
# COMMENT: 	Script checks registry settings for Time Server configuration.
# 
# ==============================================================================================

# ==============================================================================================
# Functions Section
# ==============================================================================================
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
# Function Name 'ListComputers' - Enumerates ALL Servers objects in AD
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

# ========================================================================
# Function Name StartRPT
# ========================================================================
Function StartRPT {
foreach ($strComputer in $ColComputers){
#Ping Server to see if alive!!!
$reply = gwmi win32_PingStatus -Filter "Address='$strComputer'"
if ($reply.statusCode -eq "0"){
		$Reg = [WMIClass]"\\$strComputer\root\default:StdRegProv"
		
		#Connect HKLM
		#Enum Parameter settings
		$Regpath = "SYSTEM\CurrentControlSet\Services\W32TIME\Parameters"
		$values = $Reg.EnumValues($HKLM, $Regpath)
			foreach($value in $values.sNames){
			#$value + " = "+$Reg.GetStringValue($HKLM,$Regpath,$value).sValue
			$colValues = $Reg.GetStringValue($HKLM,$Regpath,$value).sValue
			foreach($Item in $colValues){
			if($Item.Contains("NT5DS")){
			$Sheet.Cells.Item($intRow, 1) = $strComputer
			$Sheet.Cells.Item($intRow, 2) = "Synchronizes to domain hierarchy [default]"
			$Sheet.Cells.Item($intRow, 3) = "Domain"
			$intRow = $intRow + 1
			}
			Elseif($Item.Contains("NTP")){
			$Sheet.Cells.Item($intRow, 1) = $strComputer
			$Sheet.Cells.Item($intRow, 2) = "Synchronizes to manually configured source"
			$Sheet.Cells.Item($intRow, 3) = $Reg.GetStringValue($HKLM,$Regpath,"ntpserver").sValue
			$intRow = $intRow + 1
			}
			Elseif($Item.Contains("AllSync")){
			$Sheet.Cells.Item($intRow, 1) = $strComputer
			$Sheet.Cells.Item($intRow, 2) = "Synchronizes using Netlogon [allsync]"
			$Sheet.Cells.Item($intRow, 3) = $Reg.GetStringValue($HKLM,$Regpath,"ntpserver").sValue
			$intRow = $intRow + 1
			}
			Elseif($Item.Conatins("NoSync")){
			$Sheet.Cells.Item($intRow, 1) = $strComputer
			$Sheet.Cells.Item($intRow, 2) = "Does not synchronize time"
			$intRow = $intRow + 1			
			}
			
			}
			}
		
		}	
}
	$WorkBook.EntireColumn.AutoFit()
	clear
#}	
}
# ========================================================================
# Function - CreateExcel
# ========================================================================
Function CreateExcel {
$Excel = New-Object -Com Excel.Application
$Excel.visible = $True
$ExcelWBS = $Excel.Workbooks.Add()

$Sheet = $ExcelWBS.WorkSheets.Item(1)
$Sheet.Cells.Item(1,1) = “Computer”
$Sheet.Cells.Item(1,2) = “Synchronization”
$Sheet.Cells.Item(1,3) = “Time Server”

$WorkBook = $Sheet.UsedRange
$WorkBook.Interior.ColorIndex = 8
$WorkBook.Font.ColorIndex = 11
$WorkBook.Font.Bold = $True

$intRow = 2

}
# ========================================================================
# Script Body
# ========================================================================
$erroractionpreference = "SilentlyContinue"
# Registry Constants
$HKLM = 2147483650
$HKCU = 2147483649
$HKCR = 2147483648
$HKEY_USERS = 2147483651

Write-Host "**********************" -ForegroundColor Green
Write-Host "Time Server Check"		-ForegroundColor Green
Write-Host "by: Jesse Hamrick"		-ForegroundColor Green
Write-Host "www.PowerShellPro.com:"	-ForegroundColor Green
Write-Host "**********************" -ForegroundColor Green
Write-Host ""

	
# Prompt for computer resources
Write-Host "Which computer resources would you like in the report?"	-ForegroundColor Green
$strResponse = Read-Host "[1] All Domain Computers, [2] All Domain Servers, [3] Computer names from a File, [4] Choose a Computer manually"
If($strResponse -eq "1"){$colComputers = ListComputers | Sort-Object}
	elseif($strResponse -eq "2"){$colComputers = ListServers | Sort-Object}
	elseif($strResponse -eq "3"){. ListTextFile}
	elseif($strResponse -eq "4"){. ManualEntry}
	else{Write-Host "You did not supply a correct response, `
	Please run script again." -foregroundColor Red}				
Write-Progress -Activity "Getting Inventory" -status "Running" -id 1

#Start Report

$Excel = New-Object -Com Excel.Application
$Excel.visible = $True
$ExcelWBS = $Excel.Workbooks.Add()

$Sheet = $ExcelWBS.WorkSheets.Item(1)
$Sheet.Cells.Item(1,1) = “Computer_Name”
$Sheet.Cells.Item(1,2) = “Time_Synchronization”
$Sheet.Cells.Item(1,3) = “Time_Source”

$WorkBook = $Sheet.UsedRange
$WorkBook.Interior.ColorIndex = 8
$WorkBook.Font.ColorIndex = 11
$WorkBook.Font.Bold = $True

$intRow = 2

StartRPT
# ========================================================================
# End of Script
# ========================================================================
