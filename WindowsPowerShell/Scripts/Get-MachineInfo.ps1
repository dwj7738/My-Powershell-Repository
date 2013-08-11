# ------------------------------------------------------------------
# Title: Get Machine Info
# Author: rerun
# Description: A little script I wrote to collect info from it relies on another script to get the IP Address
# Date Published: 16-Nov-2009 1:54:27 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/de3603ed-d9d0-493b-ac18-a3885397d625
# ------------------------------------------------------------------

function Get-MachineInfo  
{
	param([String] $name)
	#Write-Debug -Debug $name;
	$OEA = $ErrorActionPreference
	$ErrorActionPreference ="SilentlyContinue";
	
	if($name -eq "")
	{
		$A = Get-Member -inpu $input;
		Write-Host $A
		return $input |% { GetMachineInfo $_.trim() ; }
	}
	else
	{
		$obj = New-Object -Type psobject;
		trap{
			Add-Member -InputObject $obj -MemberType NoteProperty -Value $name -Name Name;
			Add-Member -InputObject $obj -MemberType NoteProperty -Value $IP -Name "No DNS Entry";
			Add-Member -InputObject $obj -MemberType NoteProperty -Value $Sn -Name "";
			$obj;
			continue;
		}
		
		$IP = . get-ipaddress $name | select-object -first 1 
		$Sn = gwmi -class Win32_SystemEnclosure -computer $name | Get-PropertyValue SerialNumber;
		$Ver = gwmi -class win32_operatingsystem -computer $name | get-propertyvalue Version;
		$osName = gwmi -class win32_operatingsystem -computer $name |% { $_.name.split('|')[0] }
		Add-Member -InputObject $obj -MemberType NoteProperty -Value $name -Name Name;
		Add-Member -InputObject $obj -MemberType NoteProperty -Value $IP -Name IP;
		Add-Member -InputObject $obj -MemberType NoteProperty -Value $Sn -Name SerialNumber;
		add-member -input $obj -membertype noteproperty -value $Ver -name Version
		add-member -input $obj -membertype noteproperty -value $osName -name OS
		
	}
	$obj;
	$ErrorActionPreference =$OEA;
}	