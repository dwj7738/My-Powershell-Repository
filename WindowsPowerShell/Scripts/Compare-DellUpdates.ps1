#Requires -version 2
#Author: Nathan Linley
#Script: Computer-DellUpdates
#Site: http://myitpath.blogspot.com
#Date: 2/9/2012

param(
	[parameter(mandatory=$true)][ValidateScript({test-path $_ -pathtype 'leaf'})][string]$catalogpath,
	[parameter(mandatory=$true,ValueFromPipeline=$true)][string]$server
)

function changedatacase([string]$str) {
	#we need to change things like this:  subDeviceID="1f17" to subDeviceID="1F17"
	#without changing case of the portion before the =
	if ($str -match "`=`"") {
		$myparts = $str.split("=")
		$result = $myparts[0] + "=" + $myparts[1].toupper()
		return $result
	} else { return $str}
}

$catalog = [xml](get-Content $catalogpath)
$oscodeid = &{
	$caption = (Get-WmiObject win32_operatingsystem -ComputerName $server).caption
	if ($caption -match "2003") {
		if ($caption -match "x64") { "WX64E" } else { "WNET2"}
	} elseif ($caption -match "2008 R2") { 
		"W8R2" 
	} elseif ($caption -match "2008" ) {
		if ($caption -match "x64") { 
			"WSSP2" 
		} else {
			"LHS86"
		} 
	}
}
write-debug $oscodeid

$systemID = (Get-WmiObject -Namespace "root\cimv2\dell" -query "Select Systemid from Dell_CMInventory" -ComputerName $server).systemid
$model = (Get-WmiObject -Namespace "root\cimv2\dell" -query "select Model from Dell_chassis" -ComputerName $server).Model
$model = $model.replace("PowerEdge","PE").replace("PowerVault","PV").split(" ") #model[0] = Brand Prefix  #model[1] = Model #

$devices = Get-WmiObject -Namespace "root\cimv2\dell" -Class dell_cmdeviceapplication -ComputerName $server
foreach ($dev in $devices) {
	$xpathstr = $parts = $version = ""
	if ($dev.Dependent -match "(version=`")([A-Z\d.-]+)`"") { $version = $matches[2] } else { $version = "unknown" }
	$parts = $dev.Antecedent.split(",")
	for ($i = 2; $i -lt 6; $i++) {
		$parts[$i] = &changedatacase $parts[$i]
	}
	$depparts = $dev.dependent.split(",")
	$componentType = $depparts[0].substring($depparts[0].indexof('"'))
	Write-Debug $parts[1]
	if ($dev.Antecedent -match 'componentID=""') {
		$xpathstr = "//SoftwareComponent[@packageType='LWXP']/SupportedDevices/Device/PCIInfo"
		if ($componentType -match "DRVR") {
			$xpathstr += "[@" + $parts[2] + " and @" + $parts[3] + "]/../../.."
			$xpathstr += "/SupportedOperatingSystems/OperatingSystem[@osVendor=`'Microsoft`' and @osCode=`'" + $osCodeID + "`']/../.."
		} else {
			$xpathstr += "[@" + $parts[2] + " and @" + $parts[3] + " and @" + $parts[4] + " and @" + $parts[5] + "]/../../.."
			#$xpathstr += "/SupportedSystems/Brand[@prefix=`'" + $model[0] + "`']/Model[@systemID=`'" + $systemID + "`']/../../.."
			$xpathstr += "/ComponentType[@value='FRMW']/.."

		}
		$xpathstr += "/ComponentType[@value=" + $componentType + "]/.."
	} else {
		$xpathstr = "//SoftwareComponent[@packageType='LWXP']/SupportedDevices/Device[@" 
		$xpathstr += $parts[0].substring($parts[0].indexof("componentID"))
		$xpathstr += "]/../../SupportedSystems/Brand[@prefix=`'" + $model[0] + "`']/Model[@systemID=`'"
		$xpathstr += $systemID + "`']/../../.."
	}
	Write-Debug $xpathstr

	$result = Select-Xml $catalog -XPath $xpathstr |Select-Object -ExpandProperty Node
	$result |Select-Object @{Name="Component";Expression = {$_.category.display."#cdata-section"}},path,vendorversion,@{Name="currentversion"; Expression = {$version}},releasedate,@{Name="Criticality"; Expression={($_.Criticality.display."#cdata-section").substring(0,$_.Criticality.display."#cdata-section".indexof("-"))}},@{Name="AtCurrent";Expression = {$_.vendorVersion -eq $version}}
}