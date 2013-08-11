
Param (
	[Parameter(Position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
	[alias("Name","ComputerName")]$Computer = @($env:ComputerName),
	[switch] $Output
)

process{
	if (Test-Connection -ComputerName $Computer -Count 1 -Quiet){
		write-host "Getting Uptime for $Computer" -foregroundcolor green
		$Result = GetUpTime $Computer
		$Global:objOut += $Result
	}
	else {
		Write-Output $("$($Computer) cannot be reached")
	}
}

begin{
	$Global:objOut = @()

	Function GetUpTime ($HostName){
		try{
            $LastBoot = (Get-WmiObject -Class Win32_OperatingSystem -Computer $HostName).LastBootUpTime
			$UpTime = [System.Management.ManagementDateTimeconverter]::ToDateTime($lastboot)
			$UpTimeSpan = New-TimeSpan -start $UpTime -end $(Get-Date -Hour 8 -Minute 0 -second 0)
			$Filter = @{ProviderName= "USER32";LogName = "system"}
			$Reason = (Get-WinEvent -ComputerName $HostName -FilterHashtable $Filter | where {$_.Id -eq 1074} | Select -First 1)
			$Result = New-Object PSObject -Property @{
				Date = $(Get-Date -Format d)
				ComputerName =[String] $HostName
				LastBoot = $UpTime
				Reason = $Reason.Message
				Days = $($UpTimeSpan.Days)
				Hours = $($UpTimeSpan.Hours)
				Minutes = $($UpTimeSpan.Minutes)
				Seconds = $($UpTimeSpan.Seconds)
			}
			return $Result
		}
		catch{
            Write-output("Hit an Error")		
	        write-error $error[0]
			return $null
		}
	}

}

end{
	if ($Output){
		[string]$OutputLog = ([environment]::getfolderpath("mydocuments")) + "\" + "Servers_Uptime.csv"
		$Global:objOut | ConvertTo-Csv -Delimiter ";" -NoTypeInformation | out-file $OutputLog
	}
	else{
		$Global:objOut | Select Date, Servername, Lastboot, Reason, Days, Hours, Minutes, Seconds | fl
	}
}