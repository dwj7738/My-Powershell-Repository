# Title: Get-InstalledSoftware
# Author: Jon Gurgul
# ------------------------------------------------------------------
# Modified by: David Johnson 18-Sep-2012
#
# Global Variables
$subnet = "192.168.0"
$start= 1 
$end = 230 
$searchproduct = "Microsoft"
$searchlength = $searchproduct.Length


Function Get-InstalledSoftware ($ComputerName) {
	$Base = New-Object PSObject;
	$Base | Add-Member Noteproperty ComputerName -Value $Null;
	$Base | Add-Member Noteproperty Name -Value $Null;
	$Base | Add-Member Noteproperty InstallDate -Value $Null;
	$Results =  New-Object System.Collections.Generic.List[System.Object];
	$Registry = $Null;
	Try{$Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$ComputerName);}
		Catch{}
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
								[ref]$ParsedInstallDate = Get-Date
					If ([DateTime]::TryParseExact($SubKey.GetValue("InstallDate"),"yyyyMMdd",$Null,[System.Globalization.DateTimeStyles]::None,$ParsedInstallDate)){					
					$Entry.InstallDate = $ParsedInstallDate.Value
					}
					if (($entry.name).startswith($searchproduct)) {[Void]$Results.Add($Entry);}
                    else { 
                    Write-output($entry.name)
                    }
				}
			}
		}
	
	$Results
}       
$count = 0
$count1 = 1
$counter = 0
$Computers =  New-Object System.Collections.Generic.List[System.Object];
#Write-Output("Starting Ping Search")
$colitems = ($end - $start)+2
$nodes  =$start..$end | foreach-object {"$subnet.$_"}
foreach ($node in $nodes){  
    $count++
    Write-Progress -Activity "Gathering Reachable Computers" -status "Found  $counter" -percentComplete ($count / $colItems*100)
    $test = test-connection $node -quiet -Count 1
    if ($test -ne $false) {
        $counter ++
        [void] $computers.add($node)         
          }
    }
    
foreach ($comp in $computers) { 
    $numcomputers = $Computers.Count
    Write-Progress -Activity "Checking for Computers that have $searchproduct" -status "$count1 of $numcomputers" -percentComplete ($count1 / $numcomputers*100)
    $count1 ++
    Get-InstalledSoftware($comp)
    }
