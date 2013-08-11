function Run ([String]$scriptName = '-BLANK-') {
	<# The next function records any running scripts started in the console
   session (from $pwd) in the Scripts Event Log.
   It should be placed in the Console $profile. Scripts should be started
   by typing 'Run example' to capture example.ps1, for example. 
   The default logfile is that used by the Windows Script Monitor Service, 
   available from www.SeaStarDevelopment.Bravehost.com
#> 
	if ($host -ne 'ConsoleHost') {
		return
	}
	$logfile = "$env:programfiles\Sea Star Development\" + 
	"Script Monitor Service\ScriptMon.txt"
	$parms = $myInvocation.Line -replace "run(\s+)$scriptName(\s*)"
	$script = $scriptName -replace "\.ps1\b" #Replace from word end only.          
	$script = $script + ".ps1"
	if (Test-Path $pwd\$script) {
			if(!(Test-Path Variable:\Session.Script.Job)) {
						Set-Variable Session.Script.Job -value 1 -scope global `
						-description "Script counter"
					}
					$Job = Get-Variable -name Session.Script.Job
					$number = $job.Value.ToString().PadLeft(4,'0')
					$startTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
					$tag = "$startTime [$script] start. --> $($myInvocation.Line)"
					if (Test-Path $logfile) {
						$tag | Out-File $logfile -encoding 'Default' -Append
					}
					Write-EventLog -Logname Scripts -Source Monitor -EntryType Information -EventID 2 -Category 002 -Message "Script Job: $script (PS$number) started."
					Invoke-Expression -command "$pwd\$script $parms"
					$endTime = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
					$tag = "$endTime [$script] ended. --> $($myInvocation.Line)"
					if (Test-Path $logfile) {
						$tag | Out-File $logfile -encoding 'Default' -Append
					}
					Write-Eventlog -Logname Scripts -Source Monitor -EntryType Information -EventID 1 -Category 001 -Message "Script Job: $script (PS$number) ended."
					$job.Value += 1 
				}
				else {
					Write-Error "$pwd\$script does not exist."
				}
			}