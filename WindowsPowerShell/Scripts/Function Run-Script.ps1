#################################################################################
# This function should be included in the PowerShell ISE profile.ps1 and it will 
# display the start and end times of any scripts started by clicking 'Run Script'
# in the Add-ons Menu, or F2; additionally they will be logged to the Scripts
# Event Log (which needs creating first) and also to a text log file. This 
# defaults to that created by the Windows Script Monitor Service (available from 
# www.SeaStarDevelopment.Bravehost.com) which normally indicates the full command
# line used to start each script. 
# The source directory of any script must always be the current '$pwd'.
# V2.0 Use Try/Catch to trap (child) script errors & change Hotkey to F2.
# v3.1 Arguments entered on the command line will now be passed to the script.
#################################################################################

function Run-Script {
	$script = $psISE.CurrentFile.DisplayName
	if ($script.StartsWith("Untitled") -or $script.Contains("profile.") -or `
		(			$host.Name -ne 'Windows PowerShell ISE Host' )) {
		return
	}
	$psISE.CurrentFile.Save()
	$logfile = "$env:programfiles\Sea Star Development\" + 
	"Script Monitor Service\ScriptMon.txt" #Change to suit.        
	if (!(Test-Path env:\JobCount)) {
				$env:JobCount = 1 #This will work across multi Tab sessions.
			}
			$number = $env:JobCount.PadLeft(4,'0')
			$startTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
			#Now grab any parameters entered from the command line...
			$parms = $psISE.CurrentPowerShellTab.CommandPane.Text
			$tag = "$startTime [$script] start. --> PSE $($myInvocation.Line) $pwd\$script $parms"
			if (Test-Path $logfile) {
				$tag | Out-File $logfile -encoding 'Default' -Append
			}
			"$startTime [$script] started." 
			Write-EventLog -Logname Scripts -Source Monitor -EntryType Information -EventID 2 -Category 002 -Message "Script Job: $script (PSE$number) started."
			try {
				Invoke-Expression "$pwd\$script $parms"
			}
			catch {
				Write-Host -ForegroundColor Red ">>> ERROR: $_"
			}
			$endTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
			$tag = "$endTime [$script] ended. --> PSE $($myInvocation.Line) $pwd\$script $parms"
			if (Test-Path $logfile) {
				$tag | Out-File $logfile -encoding 'Default' -Append
			}
			"$endTime [$script] ended."
			Write-Eventlog -Logname Scripts -Source Monitor -EntryType Information -EventID 1 -Category 001 -Message "Script Job: $script (PSE$number) ended."
			$env:JobCount = [int]$env:JobCount + 1
		}

		$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Run Script",{Run-Script}, "F2") | Out-Null