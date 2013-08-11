<#
.SYNOPSIS
   Gets a computer name
.DESCRIPTION
   Resolve a computer name using an IP address
.PARAMETER <paramName>
   $IPAddress
.EXAMPLE
   Get-ComputerNameByIP "192.168.1.1"
.AUTHOR
   G.W. Scheppink
#>

function Get-ComputerNameByIP {
	param(
		$IPAddress = $null
	)

	begin { }

	process {
		if ($IPAddress -and $_) {
			Throw ?Please use either pipeline or input parameter?
			break
		} elseif ($IPAddress) {
			(				[System.Net.Dns]::GetHostbyAddress($IPAddress))
		} elseif ($_) {
			trap [Exception] {
				write-warning $_.Exception.Message
				continue;
			}
			[System.Net.Dns]::GetHostbyAddress($_)
		} else {
			$IPAddress = Read-Host ?Please supply the IP Address?
			[System.Net.Dns]::GetHostbyAddress($IPAddress)
		}
	}

	end { } 

} # End function

function Check-Online {
	param(
		$computername
	)

	test-connection -count 1 -ComputerName $computername -TimeToLive 5 -asJob |
	Wait-Job |
	Receive-Job |
	Where-Object { $_.StatusCode -eq 0 } |
	Select-Object -ExpandProperty Address StatusCode
}

# This code pings an IP segment from 192.168.1.1 to 192.168.1.254 and returns only those IPs that respond.
CLS
$Start = Get-Date
$ips = 1..254 | ForEach-Object { "192.168.6.$_" }
$online = Check-Online -computername $ips
$online

foreach ($PC in $online) {
	Get-ComputerNameByIP $PC
}

$End = Get-Date
Write-Host "`nStarted at: " $Start
Write-Host "Ended at: " $End