# ------------------------------------------------------------------
# Title: Hardware Inventory Using PowerShell
# Author: Aman Dhally
# Description: Hi,The basic idea of this script to find the Part Number and Serial Number of installed hardwares. For example serial Number of Harddisk, Physical ram , Cd drives.In my enviornmnet i want that this script should reside on Users Laptop/desktop. and create a batch file to call this
# Date Published: 05-Mar-2012 2:10:39 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Hardware-Inventory-Using-fe6611e0
# Tags: Hardware Information;Hardware inventory;aman dhally
# Rating: 3.75 rated by 4
# ------------------------------------------------------------------

<#
			"SatNaam WaheGuru"

Date: 03:03:2012, 18:20PM
Author: Aman Dhally
Email:  amandhally@gmail.com
web:	www.amandhally.net/blog
blog:	http://newdelhipowershellusergroup.blogspot.com/
More Info : 

Version : 1

	/^(o.o)^\ 


#>



$name = (Get-Item env:\Computername).Value
$filepath = (Get-ChildItem env:\userprofile).value

## Email Setting

$smtp = "Your-ExchangeServer"
$to = "YourIT@YourDomain.com"
$subject = "Hardware Info of $name"
$attachment = "$filepath\$name.html"
$from =  (Get-Item env:\username).Value + "@yourdomain.com"




#### HTML Output Formatting #######

$a = "<style><!--mce:0--></style>"

###############################################



#####

ConvertTo-Html -Head $a  -Title "Hardware Information for $name" -Body "<h1> Computer Name : $name </h1>" >  "$filepath\$name.html" 

# MotherBoard: Win32_BaseBoard # You can Also select Tag,Weight,Width 
Get-WmiObject -ComputerName $name  Win32_BaseBoard  |  Select Name,Manufacturer,Product,SerialNumber,Status  | ConvertTo-html  -Body "<H2> MotherBoard Information</H2>" >> "$filepath\$name.html"

# Battery 
Get-WmiObject Win32_Battery -ComputerName $name  | Select Caption,Name,DesignVoltage,DeviceID,EstimatedChargeRemaining,EstimatedRunTime  | ConvertTo-html  -Body "<H2> Battery Information</H2>" >> "$filepath\$name.html"

# BIOS
Get-WmiObject win32_bios -ComputerName $name  | Select Manufacturer,Name,BIOSVersion,ListOfLanguages,PrimaryBIOS,ReleaseDate,SMBIOSBIOSVersion,SMBIOSMajorVersion,SMBIOSMinorVersion  | ConvertTo-html  -Body "<H2> BIOS Information </H2>" >> "$filepath\$name.html"

# CD ROM Drive
Get-WmiObject Win32_CDROMDrive -ComputerName $name  |  select Name,Drive,MediaLoaded,MediaType,MfrAssignedRevisionLevel  | ConvertTo-html  -Body "<H2> CD ROM Information</H2>" >> "$filepath\$name.html"

# System Info
Get-WmiObject Win32_ComputerSystemProduct -ComputerName $name  | Select Vendor,Version,Name,IdentifyingNumber,UUID  | ConvertTo-html  -Body "<H2> System Information </H2>" >> "$filepath\$name.html"

# Hard-Disk
Get-WmiObject win32_diskDrive -ComputerName $name  | select Model,SerialNumber,InterfaceType,Size,Partitions  | ConvertTo-html  -Body "<H2> Harddisk Information </H2>" >> "$filepath\$name.html"

# NetWord Adapters -ComputerName $name
Get-WmiObject win32_networkadapter -ComputerName $name  | Select Name,Manufacturer,Description ,AdapterType,Speed,MACAddress,NetConnectionID |  ConvertTo-html  -Body "<H2> Nerwork Card Information</H2>" >> "$filepath\$name.html"

# Memory
Get-WmiObject Win32_PhysicalMemory -ComputerName $name  | select BankLabel,DeviceLocator,Capacity,Manufacturer,PartNumber,SerialNumber,Speed  | ConvertTo-html  -Body "<H2> Physical Memory Information</H2>" >> "$filepath\$name.html"

# Processor 
Get-WmiObject Win32_Processor -ComputerName $name  | Select Name,Manufacturer,Caption,DeviceID,CurrentClockSpeed,CurrentVoltage,DataWidth,L2CacheSize,L3CacheSize,NumberOfCores,NumberOfLogicalProcessors,Status  | ConvertTo-html  -Body "<H2> CPU Information</H2>" >> "$filepath\$name.html"

## System enclosure 

Get-WmiObject Win32_SystemEnclosure -ComputerName $name  | Select Tag,AudibleAlarm,ChassisTypes,HeatGeneration,HotSwappable,InstallDate,LockPresent,PoweredOn,PartNumber,SerialNumber  | ConvertTo-html  -Body "<H2> System Enclosure Information </H2>" >> "$filepath\$name.html"

## Invoke Expressons

invoke-Expression "$filepath\$name.html"


#### Sending Email

Send-MailMessage -To $to -Subject $subject -From $from  $subject -SmtpServer $smtp -Priority "High" -BodyAsHtml -Attachments "$filepath\$name.html" 
