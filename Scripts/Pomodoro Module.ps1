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
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUW0dzIVNuGQW9Fulydr1X8gFU
# hLKgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFwA3f+OMZEEfNG7
# g+XRnxcCNOHgMA0GCSqGSIb3DQEBAQUABIIBAFAR+k7ziJND+SuPsLcC2e/fAm48
# bjjx1ILrTPVNu+fu4cn4iOqJwpTDFxHPei5yA5Y5xv+xqap/Obkp3cZUkkVoiXKr
# ci6wMCXeHHNaTdmD3TJbsOWPkmYNusVHjEVCo3bjIxbZqc/9YGmbzTz8p9xplZRS
# 7KmWXSNBLext9bg5NcRi1IK0bOWqTLnLl4jvN4AwdjCFEBL5cyb5qC4C0zEzjphE
# BfSxpIS/5vY9XpoegBPWKqsaQklAsS8Z7aUl+YlusujSRxbv6WGDmMt3uWJUvCj3
# 1/lyhr16iz/tB51TvQ6soiL8PKhrUOHpoL4R/7BmnyqGf+PFNAXD5zIp1Qc=
# SIG # End signature block
