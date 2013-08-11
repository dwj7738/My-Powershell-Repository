## =====================================================================
## Title       : Experts- Exchange Question
## Description : This will check all drives on all servers for files older than a specified date
## Author      : David Johnson (ve3ofa)
## Date        : 29/04/2013
## Input       : 
## Output      : 
## Usage		: PS> . foo -{param} {value} -v -d
## Notes		: This will check all drives on All Named Servers
## Tag			:http://www.experts-exchange.com/Programming/Languages/Scripting/Powershell/Q_28078813.html#a39031922
## =====================================================================
 

function find-old-files()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
}$servers = Get-Content c:\test\servers.txt
$LastWrite = get-date "01/01/2012"
$dtstart = Get-Date
$MyObject = $null
$FileArray = $null
$i = 0
$FileArray = @()
cls
foreach ($server in $servers) {
	$drives = $null
	$drive = $null
	$drives = Get-DriveInfo 
	foreach ($drive in $drives) {
		$d = "Scanning Drive: " + $drive.VolumeLabel
		$d += " (" + $drive.Name + ")"
		write-output($d)
		$files = $null
		$files = Get-ChildItem $drive.Name -Recurse -ErrorAction SilentlyContinue
		Write-Output("Found: " + $files.Count)
		for ($counter =0; $counter -le $files.count; $counter ++) 
		{
			$activity = "Checking File Dates: File: " + $counter + " of " + $files.count
			Write-Progress -Activity $activity -status "Found Items $i" -percentComplete (($counter / [int ]$files.count)*100)
			if ($files[$counter].LastWriteTime -lt $LastWrite) 
			{
				$MyObject = New-Object PSObject -Property @{ 
					Path = $files[$counter].FullName
					Size = $files[$counter].Length
					LastWriteDAte = $files[$counter].LastWriteTime 
					#$owner = get-acl -path $files[$counter].FullName -ErrorAction SilentlyContinue
					#Owner =$owner.owner
				}
				$FileArray += $MyObject
				$i++
			}
		}
	}
}
$dtend = Get-Date
Write-Output("Elapsed Time:" + ($dtend - $dtstart))
}

find-old-files