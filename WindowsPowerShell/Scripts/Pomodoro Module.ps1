#PomoDoro Module (make sure its a PS1)
#12-3-2011 Karl Prosser

#example
#import-module C:\amodule\Pomodoro.psm1 -force
#Start-Pomodoro -ShowPercent -Work "coding" -UsePowerShellPrompt


#future todos
# -limit , a number (by default 0 meaning forever) that will only run the pomodoro that many times
# -Confirm (after one is finished it will ask questions like whether you want to do another and whether you were successful)
# -StartSound - path to it - with the current ones as default
# -BreakSound -path to it -with current ones as default
# possibly some custom sounds and the module gets distributed as a zip.
# document all the functions fully with standard powershell help techniques.

# -useprompt - create a prompt instead and update that each time instead..
#   Pomo 4:21>   (means we are in the pomodoro with that many minutes left.. if work is specified like "watchlogs" then it could be
# watchlogs 4:21>
# and when its a break then Break 4:21>
# support reason for stopping
# when no progress is shown, do a write-host to state changes.
$script:DefaultLength = 25;
$script:DefaultBreak = 5;
$script:timer = $null
$script:showprogress = $true

function Stop-Pomodoro
{
 [CmdletBinding()]
param(
	[parameter()]
	$reason
)
Unregister-Event "Pomodoro" -ErrorAction silentlycontinue 
$script:timer = $null
}

function Set-PomodoroPrompt
{
 [CmdletBinding()]
param ()
$script:promptbackup = $function:prompt 
$function:prompt = { Get-PomodoroStatus -ForPrompt} 
}

function Restore-PomodoroPrompt
{
[CmdletBinding()]
 param ()
$function:prompt = $script:promptbackup 
}
function Show-PomodoroProgress
{
 [cmdletbinding()]param()
$script:showprogress = $true
}
function Hide-PomodoroProgress
{
[cmdletbinding()]param()
$script:showprogress = $false
}

function Get-PomodoroStatus
{
 [CmdletBinding(DefaultParameterSetName="summary")] 
param(
	[Parameter(ParameterSetName="remaining",Position=0)] 
	[switch]$remaining
	,
	[Parameter(ParameterSetName="From",Position=0)] 
	[switch]$From
	,
	[Parameter(ParameterSetName="Until",Position=0)] 
	[switch]$Until
	,
	[Parameter(ParameterSetName="Length",Position=0)] 
	[switch]$Length 
	,
	[Parameter(ParameterSetName="forPrompt",Position=0)] 
	[switch]$ForPrompt 
)

if($script:timer)
{
	if($script:pomoorbreak) 
	{
		$prefix = "Pomodoro - $script:currentwork" 
		$pomotime = new-object system.TimeSpan 0,0,$script:currentlength,0
	} 
	else 
	{
		$prefix = "Having a Break from work - $script:currentwork"
		$pomotime = new-object system.TimeSpan 0,0,$script:currentbreak,0
	}

	$diff = (get-Date) - $script:starttime 
	$timeleft = $pomotime - $diff
	$endtime = $starttime + $pomotime
}

switch ($PsCmdlet.ParameterSetName) 
{
	"summary" { "{5} for {4} minutes from {0:hh:mm} to {1:hh:mm} - {2}:{3:00} minutes left." -f $starttime,$endtime ,$timeleft.minutes, $timeleft.seconds ,$pomotime.minutes,$prefix} 
	"remaining" { $timeleft} 
	"From" {$script:starttime}
	"Until" { $endtime }
	"Length" {$pomotime}
	"ForPrompt" {
		if($script:timer)
		{
			if ($script:pomoorbreak)
			{
				if($script:currentwork -and ($script:currentwork.trim() -ne [string]::Empty))
				{
					"{0} {1}:{2:00}>" -f $(if($script:currentwork.length -gt 8) { $script:currentwork.substring(0,8)} else {$script:currentwork} ),
					$timeleft.minutes, $timeleft.seconds
				}
				else
				{
					"{0} {1}:{2:00}>" -f "Pomo",$timeleft.minutes, $timeleft.seconds
				}
			}
			else
			{
				"{0} {1}:{2:00}>" -f "Break",$timeleft.minutes, $timeleft.seconds
			}
		}
		else
		{
			"No Pomo>"
		}

	} 
} 



}
function Start-Pomodoro
{
 [CmdletBinding()]
param (
	[Parameter()]
	[int]$Length = $script:DefaultLength
	,
	[Parameter()]
	[int]$Break = $script:DefaultBreak
	,
	[Parameter()]
	[string]$Work
	,
	[Parameter()]
	[switch]$ShowPercent
	,
	[Parameter()]
	[switch]$HideProgress
	,
	[Parameter()]
	[switch]$UsePowerShellPrompt
)
$script:currentlength = $length
$script:currentbreak = $break;
$script:currentshowpercent = [bool]$showpercent;
$script:currentwork = $work
if($HideProgress) { $script:showprogress = $false } else { $script:showprogress = $true }
#if pomoDoro Already running then stop it
Unregister-Event "Pomodoro" -ErrorAction silentlycontinue
$script:timer = $null

$script:pomoorbreak = $true
$script:starttime = get-Date

$script:timer = New-Object System.Timers.Timer 
$script:timer.Interval = 1000 
$script:timer.Enabled = $true 

$null = Register-ObjectEvent $timer "Elapsed" -SourceIdentifier "Pomodoro" -Action { 
	$breakmode = & (get-Module Pomodoro) { $script:PomoOrBreak }
	$starttime = & (get-Module Pomodoro) { $script:starttime }
	$break = & (get-Module Pomodoro) {$script:currentbreak}
	$length = & (get-Module Pomodoro) { $script:currentlength } 
	$work = & (get-Module Pomodoro) { $script:currentwork } 
	if($breakmode) 
	{
		$prefix = "Pomodoro - $work " 
		$pomotime = new-object system.TimeSpan 0,0,$length,0
	} 
	else 
	{
		$prefix = "Having a Break from work - $work"
		$pomotime = new-object system.TimeSpan 0,0,$break,0
	}

	$diff = (get-Date) - $starttime

	$timeleft = $pomotime - $diff
	$endtime = $starttime + $pomotime
	$timeleftdisplay = "for {4} minutes from {0:hh:mm} to {1:hh:mm} - {2}:{3:00} minutes left." -f $starttime,$endtime ,$timeleft.minutes, $timeleft.seconds ,$pomotime.minutes
	if (($pomotime - $diff) -le 0) 
	{
		write-Progress -Activity " " -Status "done"; 
		$sound = new-Object System.Media.SoundPlayer;
		if ($breakmode) 
		{
			$sound.SoundLocation="$env:systemroot\Media\tada.wav";
		}
		else
		{
			$sound.SoundLocation="$env:systemroot\Media\notify.wav";
		} 
		$sound.Play();
		sleep 1
		$sound.Play();
		sleep 1
		$sound.Play();
		iex "& (get-module pomodoro) {`$script:starttime = get-Date; `$script:pomoorbreak = ! `$$breakmode } "

	}
	else 
	{
		if ( & (get-Module Pomodoro) { $script:showprogress } )
		{

			if (& (get-Module Pomodoro) { $script:currentshowpercent} ) 
			{
				$perc =100 - ( [int] ([double]$timeleft.totalseconds * 100 / [double]$pomotime.totalseconds))
				write-Progress -Activity $prefix -Status "$timeleftdisplay" -PercentComplete $perc
			}
			else
			{
				write-Progress -Activity $prefix -Status "$timeleftdisplay"
			}
		} 
	}

}
if($UsePowerShellPrompt) { Set-PomodoroPrompt }


}

export-ModuleMember -Function "*"
$myInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
	if ($script:promptbackup) { $function:prompt = $script:promptbackup } 
}