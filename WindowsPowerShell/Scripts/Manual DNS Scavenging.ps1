#==========================================================================
#
# PowerShell Source File 
#
# AUTHOR: Stephen Wheet
# NAME: dnsscavenge.ps1
# Version: 1.2
# Date: 8/12/10
#
# COMMENT: 
#	This script was created to manually scavenge DNS records for a given 
#   period. Specify the date of last registration and everything older
#   than that will be deleted.
#
#   v1.1 - Added Network Range to filter based on network range (good for 
#          doing one site/floor at a time)
#   v1.2 - Added the ability to do multiple ranges at the same time.
#
#==========================================================================
$DeleteKey = 0 #change to 0 for only a report, 1 to delete the records

#Define network range to filter on
$NetworkRange = "192.168.1.*","192.168.2.*"

# No-Refresh + Refresh (in Days)
$TotalAgingInterval = 60

$ServerName = "DNSSERVER" #DC to connect to
$ContainerName = "Domain.local" #domain name to scavenge from

#Place Headers on out-put file
ForEach ($Network in $NetworkRange){
	$filename = "DC-" + $ServerName + "--DOMAIN-" + $ContainerName + "--AGE-" + $TotalAgingInterval + `
	"--RANGE-" + $Network.Replace("*","") + ".csv"
	$logfile = "D:\reports\DNSscavenge\$filename"
	$list = "Ownername,TimeStamp,Deleted"
	$list | format-table | Out-File "$logfile"
} #end for each

$MinTimeStamp = [Int](New-TimeSpan `
	-Start $(Get-Date("01/01/1601 00:00")) `
	-End $((Get-Date).AddDays(-$TotalAgingInterval))).TotalHours

$records = Get-WMIObject -Computer $ServerName `
-Namespace "root\MicrosoftDNS" -Class "MicrosoftDNS_AType" `
-Filter `
"ContainerName='$ContainerName' AND TimeStamp<$MinTimeStamp AND TimeStamp<>0 " 

ForEach ($record in $records){
	$IPA = $record.IPAddress

	ForEach ($Network in $NetworkRange){

		If ( $IPA -like $Network ){

			$Ownername = $record.Ownername
			$TimeStamp = (Get-Date("01/01/1601")).AddHours($record.TimeStamp)
			Write-host "$Ownername,$IPA,$TimeStamp"
			$filename = "DC-" + $ServerName + "--DOMAIN-" + $ContainerName + "--AGE-" + $TotalAgingInterval + `
			"--RANGE-" + $Network.Replace("*","") + ".csv"
			$logfile = "D:\reports\DNSscavenge\$filename" # Logfile location

			If ($DeleteKey){
				$record.psbase.Delete()

				If($?) { 

					Write-host "Successfully deleted A record: $Ownername"

				}Else { 
					Write-host "Could not delete A record: $Ownername, error: $($error[0])"
				}

				$list = ("$Ownername,$TimeStamp,$?")
				$list | format-table | Out-File -append "$logfile"

			}Else{

				$list = ("$Ownername,$TimeStamp,No")
				$list | format-table | Out-File -append "$logfile" 

			} #end if/else
		} #end if
	} #end for each
} #end for each