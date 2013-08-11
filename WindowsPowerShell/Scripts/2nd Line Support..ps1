##Creates variable for filename

$date = (get-date).tostring("yyyy-MM-dd")
$filename = "D:\dailychecks\checks_$date.xls"

## Imports exchange modules

Import-Module "\\emailserver\c$\PS Modules\vamail.videoarts.info.psm1"

## Start Internet Explorer to check that Video Arts website is up

Start-Process iexplore.exe

## Creates new excel object
$erroractionpreference = "SilentlyContinue"
$a = New-Object -comobject Excel.Application
$a.visible = $True 

##creates workbook and three worksheets. Names three worksheets.
$b = $a.Workbooks.Add()
$c = $b.Worksheets.Item(1)
$d = $b.Worksheets.Item(2)
$e = $b.Worksheets.Item(3)

$b.name = "$title"
$c.name = "Stopped Services"
$d.name = "Free Disk Space"
$e.name = "Server Connectivity"

##Populates cells with the titles

$c.Cells.Item(1,1) = "STOPPED SERVICES"
$c.Cells.Item(2,1) = "Machine Name"
$c.Cells.Item(2,2) = "Service Name"
$c.Cells.Item(2,3) = "State"

$d.Cells.Item(1,1) = "FREE DISK SPACE"
$d.Cells.Item(2,1) = "Machine Name"
$d.Cells.Item(2,2) = "Drive"
$d.Cells.Item(2,3) = "Total size (MB)"
$d.Cells.Item(2,4) = "Free Space (MB)"
$d.Cells.Item(2,5) = "Free Space (%)"

$e.Cells.Item(1,1) = "SERVER CONNECTIVITY"
$e.Cells.Item(2,1) = "Server Name"
$e.Cells.Item(2,2) = "Server Status"


##Changes colours and fonts for header sections populated above 
$c = $c.UsedRange
$c.Interior.ColorIndex = 19
$c.Font.ColorIndex = 11
$c.Font.Bold = $True

$d = $d.UsedRange
$d.Interior.ColorIndex = 19
$d.Font.ColorIndex = 11
$d.Font.Bold = $True

$e = $e.UsedRange
$e.Interior.ColorIndex = 19
$e.Font.ColorIndex = 11
$e.Font.Bold = $True
$e.EntireColumn.AutoFit()


##sets variables for the row in which data will start populating
$servRow = 3
$diskRow = 3
$pingRow = 3

###Create new variable to run connectivity check###

$colservers = Get-Content "D:\dailychecks\Servers.txt"
foreach ($strServer in $colservers)
##Populate computer names in first column
{
	$e.Cells.Item($pingRow, 1) = $strServer.ToUpper()

	## Create new object to ping computers, if they are succesful populate cells with green/success, if anything else then red/offline

	$ping = new-object System.Net.NetworkInformation.Ping
	$Reply = $ping.send($strServer)
	if ($Reply.status -eq "Success")
	{
		$rightcolor = $e.Cells.Item($pingRow, 2)
		$e.Cells.Item($pingRow, 2) = "Online"
		$rightcolor.interior.colorindex = 10
	}
	else
	{

		$wrongcolor = $e.Cells.Item($pingRow, 2)
		$e.Cells.Item($pingRow, 2) = "Offline"
		$wrongcolor.interior.colorindex = 3

	}
	$Reply = ""

	##Set looping variable so that one cell after another populates rather than the same cell getting overwritten
	$pingRow = $pingRow + 1

	##Autofit collumnn
	$e.EntireColumn.AutoFit()
}
##gets each computer
$colComputers = get-content "D:\dailychecks\Servers.txt"
foreach ($strComputer in $colComputers)
{
	##gets each service with startmode 'Auto' and state 'Stopped' for each computer
	$stoppedservices = get-wmiobject Win32_service -computername $strComputer | where{$_.StartMode -eq "Auto" -and $_.State -eq "stopped"} 
	foreach ($objservice in $stoppedservices)

	{
		##Populates cells
		$c.Cells.Item($servRow, 1) = $strComputer.ToUpper()
		$c.Cells.Item($servRow, 2) = $objService.Name
		$c.Cells.Item($servRow, 3) = $objService.State
		$servRow = $servRow + 1
		$c.EntireColumn.AutoFit()
	}

	##Gets disk information for each computer
	$colDisks = get-wmiobject Win32_LogicalDisk -computername $strComputer -Filter "DriveType = 3" 
	foreach ($objdisk in $colDisks)

	{
		##Populates cells
		$d.Cells.Item($diskRow, 1) = $strComputer.ToUpper()
		$d.Cells.Item($diskRow, 2) = $objDisk.DeviceID
		$d.Cells.Item($diskRow, 3) = "{0:N0}" -f ($objDisk.Size/1024 / 1024)
		$d.Cells.Item($diskRow, 4) = "{0:N0}" -f ($objDisk.FreeSpace/1024 / 1024)
		$d.Cells.Item($diskRow, 5) = "{0:P0}" -f ([double]$objDisk.FreeSpace/[double]$objDisk.Size)
		$diskRow = $diskRow + 1
		$d.EntireColumn.AutoFit()
	}


}

##Saves file using Filename variable set at the top of the document

$b.SaveAs($filename, 1)