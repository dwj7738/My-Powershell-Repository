Function Get-HardwareReport {
[CmdletBinding()] Param
(
[parameter(Mandatory=$true,
ValueFromPipeline=$true)] [String[]]$devices
)
Begin {Write-Host " Starting Hardware Reports"}
Process {
foreach ($device in $devices) {
$name=$device
$filepath="$home\$name.html"
$PingDevice=Test-Connection $name -count 1 -quiet;trap{continue}
#Ping Test, then Server is online so get the hardware info
If ($PingDevice -eq “True”) {
Write-Host " Processing info for $name "
#### HTML Output Formatting #######
$a = "<style>"
$a = $a + "BODY{background-color:Lavender ;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:skyblue}"
$a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:lightyellow}"
$a = $a + "</style><Title>$name Hardware Report</Title>"
####################################
ConvertTo-Html -Head $a -Body "<h1> Computer Name : $name </h1>" > "$filepath"
# MotherBoard: Win32_BaseBoard # You can Also select Tag,Weight,Width
Get-WmiObject -ComputerName $name Win32_BaseBoard | Select Name,Manufacturer,Product,SerialNumber,Status | ConvertTo-html -Body "<H2> MotherBoard Information</H2>" >> "$filepath"
# BIOS
Get-WmiObject win32_bios -ComputerName $name | Select Manufacturer,Name,@{name='biosversion' ; Expression={$_.biosversion -join '; '}}, @{name='ListOfLanguages' ; Expression={$_.ListOfLanguages -join '; '}},PrimaryBIOS,ReleaseDate,SMBIOSBIOSVersion,SMBIOSMajorVersion,SMBIOSMinorVersion | ConvertTo-html -Body "<H2> BIOS Information </H2>" >>"$filepath"
# CD ROM Drive
Get-WmiObject Win32_CDROMDrive -ComputerName $name | select Name,Drive,MediaLoaded,MediaType,MfrAssignedRevisionLevel | ConvertTo-html -Body "<H2> CD ROM Information</H2>" >> "$filepath"
# System Info
Get-WmiObject Win32_ComputerSystemProduct -ComputerName $name | Select Vendor,Version,Name,IdentifyingNumber,UUID | ConvertTo-html -Body "<H2> System Information </H2>" >> "$filepath"
# Hard-Disk
Get-WmiObject win32_diskDrive -ComputerName $name | select Model,SerialNumber,InterfaceType,Size,Partitions | ConvertTo-html -Body "<H2> Harddisk Information </H2>" >> "$filepath"
# NetWord Adapters -ComputerName $name
Get-WmiObject win32_networkadapter -ComputerName $name | Select Name,Manufacturer,Description ,AdapterType,Speed,MACAddress,NetConnectionID | ConvertTo-html -Body "<H2> Network Card Information</H2>" >> "$filepath"
# Memory
Get-WmiObject Win32_PhysicalMemory -ComputerName $name | select BankLabel,DeviceLocator,Capacity,Manufacturer,PartNumber,SerialNumber,Speed | ConvertTo-html -Body "<H2> Physical Memory Information</H2>" >> "$filepath"
# Processor
Get-WmiObject Win32_Processor -ComputerName $name | Select Name,Manufacturer,Caption,DeviceID,CurrentClockSpeed,CurrentVoltage,DataWidth,L2CacheSize,L3CacheSize,NumberOfCores,NumberOfLogicalProcessors,Status | ConvertTo-html -Body "<H2> CPU Information</H2>" >> "$filepath"
## System enclosure
Get-WmiObject Win32_SystemEnclosure -ComputerName $name | Select Tag,InstallDate,LockPresent,PartNumber,SerialNumber | ConvertTo-html -Body "<H2> System Enclosure Information </H2>" >> "$filepath"
## Invoke Expressons
invoke-Expression "$filepath"
# Closing If Statement
}else {Write-Host " $name is offline - will not be included in the reports"}
#Closing For Loop
}
# Closing Process
}
End {Write-Host "Ending Hardware Report for $name"}
#Closing Function Get-HardwareReport
}