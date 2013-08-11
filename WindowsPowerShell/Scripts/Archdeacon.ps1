function Run-Script {
	if ($psISE.CurrentFile.DisplayName.StartsWith("Untitled")) {
		return
	}
	$script = $psISE.CurrentFile.DisplayName
	$psISE.CurrentFile.Save()
	$logfile = "$env:programfiles\Sea Star Development\" + 
	"Script Monitor Service\ScriptMon.txt" #Change to suit.        
	if (!(Test-Path env:\JobCount)) {
				$env:JobCount = 1 #This will work across multi Tab sessions.
			}
			$number = $env:JobCount.PadLeft(4,'0')
			$startTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
			$tag = "$startTime [$script] start. --> PSE $($myInvocation.Line)"
			if (Test-Path $logfile) {
				$tag | Out-File $logfile -encoding 'Default' -Append
			}
			"$startTime [$script] started."
			Write-EventLog -Logname Scripts -Source Monitor -EntryType Information -EventID 2 -Category 002 -Message "Script Job: $script (PSE$number) started."
			Invoke-Command -Scriptblock { & "$pwd\$script" }
			$endTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
			$tag = "$endTime [$script] ended. --> PSE $($myInvocation.Line)"
			if (Test-Path $logfile) {
				$tag | Out-File $logfile -encoding 'Default' -Append
			}
			"$endTime [$script] ended."
			Write-Eventlog -Logname Scripts -Source Monitor -EntryType Information -EventID 1 -Category 001 -Message "Script Job: $script (PSE$number) ended."
			$env:JobCount = [int]$env:JobCount + 1
		}

		$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Run Script",{Run-Script}, "Alt+R") | Out-Null