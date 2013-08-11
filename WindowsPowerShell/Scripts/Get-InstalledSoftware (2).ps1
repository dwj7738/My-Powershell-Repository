# ------------------------------------------------------------------
# Title: Get-InstalledSoftware
# Author: Jon Gurgul
# Description: A simple way to get all installed software on a local or remote machine using the Uninstall registry keys. Usage Examples:Get-InstalledSoftwareGet-InstalledSoftware | Select Name,InstallDate | Format-TableGet-InstalledSoftware | Sort-Object @{Expression={$_.ComputerName};As
# Date Published: 10-Jun-11 2:01:32 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/519e1d3a-6318-4e3d-b507-692e962c6666
# Tags: installed;local;Remote
# Rating: 4 rated by 4
# ------------------------------------------------------------------

Function Get-InstalledSoftware{
	Param([String[]]$Computers) 
	If (!$Computers) {$Computers = $ENV:ComputerName}
	$Base = New-Object PSObject;
	$Base | Add-Member Noteproperty ComputerName -Value $Null;
	$Base | Add-Member Noteproperty Name -Value $Null;
	$Base | Add-Member Noteproperty Publisher -Value $Null;
	$Base | Add-Member Noteproperty InstallDate -Value $Null;
	$Base | Add-Member Noteproperty EstimatedSize -Value $Null;
	$Base | Add-Member Noteproperty Version -Value $Null;
	$Results =  New-Object System.Collections.Generic.List[System.Object];

	ForEach ($ComputerName in $Computers){
		$Registry = $Null;
		Try{$Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$ComputerName);}
		Catch{Write-Host -ForegroundColor Red "$($_.Exception.Message)";}
		
		If ($Registry){
			$UninstallKeys = $Null;
			$SubKey = $Null;
			$UninstallKeys = $Registry.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Uninstall",$False);
			$UninstallKeys.GetSubKeyNames()|%{
				$SubKey = $UninstallKeys.OpenSubKey($_,$False);
				$DisplayName = $SubKey.GetValue("DisplayName");
				If ($DisplayName.Length -gt 0){
					$Entry = $Base | Select-Object *
					$Entry.ComputerName = $ComputerName;
					$Entry.Name = $DisplayName.Trim(); 
					$Entry.Publisher = $SubKey.GetValue("Publisher"); 
					[ref]$ParsedInstallDate = Get-Date
					If ([DateTime]::TryParseExact($SubKey.GetValue("InstallDate"),"yyyyMMdd",$Null,[System.Globalization.DateTimeStyles]::None,$ParsedInstallDate)){					
					$Entry.InstallDate = $ParsedInstallDate.Value
					}
					$Entry.EstimatedSize = [Math]::Round($SubKey.GetValue("EstimatedSize")/1KB,1);
					$Entry.Version = $SubKey.GetValue("DisplayVersion");
					[Void]$Results.Add($Entry);
				}
			}
		}
	}
	$Results
}