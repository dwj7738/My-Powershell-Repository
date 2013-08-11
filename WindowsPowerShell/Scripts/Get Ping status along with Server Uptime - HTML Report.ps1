# ------------------------------------------------------------------
# Title: Get Ping status along with Server Uptime - HTML Report
# Author: Bhavik Solanki
# Description: Introduction: This script is used to check Ping status of the server. If server is up and running then it will retrive uptime of the server. Script will generate HTML report as output. It will also highlight list of servers which are down.Before you start:This script expect text
# Date Published: 29-Mar-12 12:14:50 AM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Get-Ping-status-along-with-bd579238
# Tags: Powershell;Servers;Ping Status
# ------------------------------------------------------------------

<######################################################################
# 																	
# Author       : Bhavik Solanki										
# Date         : 28th March 2012									
# Version      : 1.0												
# Desctiption  : This script will help to monitor Server availability.
#																	
######################################################################>
Function GetStatusCode
{ 
	Param([int] $StatusCode)  
	switch($StatusCode)
	{
		0 		{"Success"}
		11001   {"Buffer Too Small"}
		11002   {"Destination Net Unreachable"}
		11003   {"Destination Host Unreachable"}
		11004   {"Destination Protocol Unreachable"}
		11005   {"Destination Port Unreachable"}
		11006   {"No Resources"}
		11007   {"Bad Option"}
		11008   {"Hardware Error"}
		11009   {"Packet Too Big"}
		11010   {"Request Timed Out"}
		11011   {"Bad Request"}
		11012   {"Bad Route"}
		11013   {"TimeToLive Expired Transit"}
		11014   {"TimeToLive Expired Reassembly"}
		11015   {"Parameter Problem"}
		11016   {"Source Quench"}
		11017   {"Option Too Big"}
		11018   {"Bad Destination"}
		11032   {"Negotiating IPSEC"}
		11050   {"General Failure"}
		default {"Failed"}
	}
}

Function GetUpTime
{
	param([string] $LastBootTime)
	$Uptime = (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime($LastBootTime)
	"Days: $($Uptime.Days); Hours: $($Uptime.Hours); Minutes: $($Uptime.Minutes); Seconds: $($Uptime.Seconds)" 
}

#Change value of the following parameter as needed
$OutputFile = "D:\Output.htm"
$ServerList = Get-Content "D:\ServerList.txt"

$Result = @()
Foreach($ServerName in $ServerList)
{
	$pingStatus = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$ServerName'"
		
	$Uptime = $null
	if($pingStatus.StatusCode -eq 0)
	{
		$OperatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $ServerName -ErrorAction SilentlyContinue
		$Uptime = GetUptime( $OperatingSystem.LastBootUpTime )
	}
	
    $Result += New-Object PSObject -Property @{
	    ServerName = $ServerName
		IPV4Address = $pingStatus.IPV4Address
		Status = GetStatusCode( $pingStatus.StatusCode )
		Uptime = $Uptime
	}
}

if($Result -ne $null)
{
	$HTML = '<style type="text/css">
	#Header{font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;width:100%;border-collapse:collapse;}
	#Header td, #Header th {font-size:14px;border:1px solid #98bf21;padding:3px 7px 2px 7px;}
	#Header th {font-size:14px;text-align:left;padding-top:5px;padding-bottom:4px;background-color:#A7C942;color:#fff;}
	#Header tr.alt td {color:#000;background-color:#EAF2D3;}
	</Style>'

    $HTML += "<HTML><BODY><Table border=1 cellpadding=0 cellspacing=0 id=Header>
		<TR>
			<TH><B>Server Name</B></TH>
			<TH><B>IP Address</B></TD>
			<TH><B>Status</B></TH>
			<TH><B>Uptime</B></TH>
		</TR>"
    Foreach($Entry in $Result)
    {
        if($Entry.Status -ne "Success")
		{
			$HTML += "<TR bgColor=Red>"
		}
		else
		{
			$HTML += "<TR>"
		}
		$HTML += "
						<TD>$($Entry.ServerName)</TD>
						<TD>$($Entry.IPV4Address)</TD>
						<TD>$($Entry.Status)</TD>
						<TD>$($Entry.Uptime)</TD>
					</TR>"
    }
    $HTML += "</Table></BODY></HTML>"

	$HTML | Out-File $OutputFile
}