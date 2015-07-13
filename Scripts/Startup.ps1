<#======================================================================================
         File Name : Startup.ps1
   Original Author : Kenneth C. Mazie
                   :
       Description : This is a Windows startup script with pop-up notification and checks to
                   : assure things are not exectuted if already running or set.  It can be run 
                   : as a personal startup script or as a domain startup (with some editing).  
                   : It is intended to be executed from the Start Menu "All Programs\Startup" folder.
                   :
		   : The script will Start programs, map shares, set routes, and can email the results
		   : if desired.  The email subroutine is commented out.  You'll need to edit it yourself.
		   : When run with the "debug" variable set to TRUE it also displays staus in the 
		   : PowerShell command window. Other wise all operation statuses are displayed in pop-up
		   : ballons near the system tray.
		   :
                   : To call the script use the following in a shortcut or in the RUN registry key.
                   : "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden –Noninteractive -NoLogo -Command "&{C:\Startup.ps1}"
                   : Change the script name and path as needed to suit your environment.
                   :
                   : Be sure to edit all sections to suit your needs before executing.  Be sure to 
		   : enable sections you wish to run by uncommenting them at the bottom of the script.
		   :
		   : Route setting is done as a function of selecting a specific Network Adapter with the intent
		   : of manually altering your routes for hardline or WiFi connectivity.  This section you will
		   : need to customize to suit your needs or leave commented out.  This allowed me to
		   : alter the routing for my office (Wifi) or lab (hardline) by detecting whether my
		   : laptop was docked or not.  The hardline is ALWAYS favored as written.
		   :
		   : To identify process names to use run "get-process" by itself to list process 
                   : names that PowerShell will be happy with, just make sure each app you want to 
                   : identify a process name for is already running first.
                   :
                   : A 2 second sleep delay is added to smooth out processing but can be removed if needed.
                   :
             Notes : Sample script is safe to run as written, it will only load taskmanager and firefox.
		   : In general, I did not write this script for ease of readability.  Most commands are 
		   : one-liner style, sorry if that causes you grief.
                   :
          Warnings : Drive mapping passwords are clear text within the script.
                   :  
                   :
    Last Update by : Kenneth C. Mazie (kcmjr)
   Version History : v1.0 - 05-03-12 - Original
    Change History : v2.0 - 11-15-12 - Minor edits  
                   : v3.0 - 12-10-12 - Converted application commands to arrays
		   : v4.0 - 02-14-13 - Converted all other sections to arrays
		   :
=======================================================================================#>

clear-host
$Debug = $True
$CloudStor = $False
$ScriptName = "Startup Script"

#--[ Prep Pop-up Notifications ]--
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$Icon = [System.Drawing.SystemIcons]::Information
$Notify = new-object system.windows.forms.notifyicon
$Notify.icon = $Icon  			#--[ NOTE: Available tooltip icons are = warning, info, error, and none
$Notify.visible = $true

#--[ Force to execute with admin priviledge ]--
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = new-object Security.Principal.WindowsPrincipal $identity
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)  -eq $false) {$Args = '-noprofile -nologo -executionpolicy bypass -file "{0}"' -f $MyInvocation.MyCommand.Path;Start-Process -FilePath 'powershell.exe' -ArgumentList $Args -Verb RunAs;exit}
if ($debug){write-host "`n------[ Running with Admin Privileges ]------`n" -ForegroundColor DarkCyan}
$Notify.ShowBalloonTip(2500,$ScriptName,"Script is running with full admin priviledges",[system.windows.forms.tooltipicon]::Info)

if ($debug){write-host "Running in DEBUG Mode..." -ForegroundColor DarkCyan}

function Pause-Host {  #--[ Only use if you need a countdown timer ]--
    param($Delay = 10)
    $counter = 0;
    While(!$host.UI.RawUI.KeyAvailable -and ($Delay-- -ne $counter ))  #--count down
	#While(!$host.UI.RawUI.KeyAvailable -and ($counter++ -lt $Delay ))  #--count up
    {
	clear-host
	if ($debug){Write-Host "testing... $Delay"} #--count down
	#Write-Host "testing... $counter" #--count up
   	[Threading.Thread]::Sleep(1000)
    }
}

Function SetRoutes {  #--[ Array consists of Network, Mask ]--
  $RouteArray = @()
  $RouteArray += , @("10.0.0.0","255.0.0.0")
  $RouteArray += , @("172.1.0.0","255.255.0.0")
  $RouteArray += , @("192.168.1.0","255.255.255.0")
  #--[ Add more route entries here... ]--
  
  $Index = 0
  Do {
  $RouteNet = $ShareArray[$Index][0]
  $RouteMask = $ShareArray[$Index][1]

  iex "route delete $RouteNet"
  Sleep (2)
  iex "route add $RouteNet mask $RouteMask $IP"
  Sleep (2)
  $Index++
  }
  While ($Index -lt $RouteArray.length)
}
  
Function SetMappings {  #--[ Array consists of Drive Letter, Path, User, and Password ]--
  $ShareArray = @()
  $ShareArray += , @("J:","\\192.168.1.250\Share1","username","password")
  $ShareArray += , @("K:","\\192.168.1.250\Share2","username","password")
  #--[ Add more mapping entries here... ]--

  $Index = 0
  Do {
  $MapDrive = $ShareArray[$Index][0]
  $MapPath = $ShareArray[$Index][1]
  $MapUser = $ShareArray[$Index][2]
  $MapPassword = $ShareArray[$Index][3]
  
  $net = $(New-Object -Com WScript.Network)
  if ( Exists-Drive $MapDrive){$Notify.ShowBalloonTip(2500,$ScriptName,"Drive $MapDrive is already mapped...",[system.windows.forms.tooltipicon]::Info);if ($debug){write-host "Drive $MapDrive already mapped" -ForegroundColor DarkRed}}else{if (test-path $MapPath){$net.MapNetworkDrive($MapDrive, $MapPath, "False",$MapUser,$MapPassword);$Notify.ShowBalloonTip(2500,$ScriptName,"Mapping Drive $MapDrive...",[system.windows.forms.tooltipicon]::Info);if ($debug){write-host "Mapping Drive $MapDrive" -ForegroundColor DarkGreen}}else{$Notify.ShowBalloonTip(2500,$ScriptName,"Cannot Map Drive $MapDrive - Target Not Found...",[system.windows.forms.tooltipicon]::Info);if ($debug){write-host "Cannot Map Drive $MapDrive - Target Not Found" -ForegroundColor DarkRed}}}
  Sleep (2)
  $Index++
  }While ($Index -lt $ShareArray.length)						 
}

Function Exists-Drive {
	param($driveletter) 
    (New-Object System.IO.DriveInfo($driveletter)).DriveType -ne 'NoRootDirectory'   
} 
       
Function LoadApps {  #--[ Array consists of Process Name, File Path, Arguements, Title ]--
$AppArray = @()
$AppArray += , @("firefox","C:\Program Files (x86)\Mozilla Firefox\firefox.exe","https://www.google.com","FireFox")
#--[ Add more app entries here... ]--
#--[ Cloud Storage Provider Subsection ]--
if (!$CloudStor ){$Notify.ShowBalloonTip(2500,$ScriptName,"Cloud Providers Bypassed...",[system.windows.forms.tooltipicon]::Info);if ($debug){write-host "Cloud Providers Bypassed..." -ForegroundColor Magenta;}}
else
{
$AppArray += , @("googledrivesync","C:\Program Files (x86)\Google\Drive\googledrivesync.exe","/autostart","GoogleDrive") 
#--[ Add more cloud entries here... ]--
}
$AppArray += , @("taskmgr","C:\Windows\System32\taskmgr.exe"," ","Task Manager")
#--[ Add more app entries here... ]--

$Index = 0
Do {
   $AppProcess = $AppArray[$Index][0]
   $AppExe = $AppArray[$Index][1]
   $AppArgs = $AppArray[$Index][2]
   $AppName = $AppArray[$Index][3]

   If((get-process -Name $AppProcess -ea SilentlyContinue) -eq $Null){start-process -FilePath $AppExe -ArgumentList $AppArgs ;$Notify.ShowBalloonTip(2500,$ScriptName,"$AppName is loading...",[system.windows.forms.tooltipicon]::Info);if ($debug){write-host "Loading" $AppName "..." -ForegroundColor DarkGreen}}else{$Notify.ShowBalloonTip(2500,$ScriptName,"$AppName is already running...",[system.windows.forms.tooltipicon]::Info);if ($debug){write-host "$AppName Already Running..." -ForegroundColor DarkRed } }
   Sleep (2)
   $Index++
   }
   While ($Index -lt $AppArray.length)
}

<#

function SendMail {
    #param($strTo, $strFrom, $strSubject, $strBody, $smtpServer)
    param($To, $From, $Subject, $Body, $smtpServer)
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = $From
    $msg.To.Add($To)
    $msg.Subject = $Subject
    $msg.IsBodyHtml = 1
    $msg.Body = $Body
    $smtp.Send($msg)
}

#>

Function IdentifyNics {
$Domain1 = "LabDomain.com"
$Domain2 = "OfficeDomain.com"

#--[ Detect Network Adapters ]--
$Wired = get-wmiobject -class "Win32_NetworkAdapterConfiguration" | where {$_.IPAddress -like "192.168.1.*" }
#--[ Alternate detection methods]--                                              
#$Wired = get-wmiobject -class "Win32_NetworkAdapterConfiguration" | where {$_.IPAddress -like "192.168.1.*" } | where {$_.DNSDomainSuffixSearchOrder -match $Domain2}
#$Wired = get-wmiobject -class "Win32_NetworkAdapterConfiguration" | where {$_.Description -like "Marvell Yukon 88E8056 PCI-E Gigabit Ethernet Controller" }
$WiredIP = ([string]$Wired.IPAddress).split(" ")
$WiredDesc = $Wired.Description 
if ($debug){
write-host "Name:       " $Wired.Description`n"DNS Domain: " $Wired.DNSDomainSuffixSearchOrder`n"IPv4:       " $WiredIP[0]`n"IPv6:       " $WiredIP[1]`n""
if ($WiredIP[0]){$Notify.ShowBalloonTip(2500,$ScriptName,"Detected $WiredDesc",[system.windows.forms.tooltipicon]::Info)}else{$Notify.ShowBalloonTip(2500,$ScriptName,"Hardline not detected",[system.windows.forms.tooltipicon]::Info)}
}
sleep (2)

$WiFi = get-wmiobject -class "Win32_NetworkAdapterConfiguration" | where {$_.Description -like "Intel(R) Centrino(R) Advanced-N 6250 AGN" }
$WiFiIP = ([string]$WiFi.IPAddress).split(" ")
$WiFiDesc = $WiFi.Description 
write-host "Name:       " $WiFi.Description`n"DNS Domain: " $WiFi.DNSDomainSuffixSearchOrder`n"IPv4:       " $WiFiIP[0]`n"IPv6:       " $WiFiIP[1]
if ($WiFiIP[0]){$Notify.ShowBalloonTip(2500,$ScriptName,"Detected $WiFiDesc",[system.windows.forms.tooltipicon]::Info)}else{$Notify.ShowBalloonTip(2500,$ScriptName,"WiFi not detected",[system.windows.forms.tooltipicon]::Info)}
sleep (2)	
	
#--[ Set Routes ]--	
if ($WiredIP[0]) { #--[ The hardline is connected.  Favor the hardline if both connected ]--
  $IP = $WiredIP[0]
  if ($Wired.DNSDomainSuffixSearchOrder -like $Domain1 -or $Wired.DNSDomainSuffixSearchOrder -like $Domain2) { #--[ the hardline is connected ]--
    write-host ""`n"Setting routes for hardline"`n""
	$Notify.ShowBalloonTip(2500,$ScriptName,"Setting routes for hardline...",[system.windows.forms.tooltipicon]::Info)
	#SetRoutes $IP 
  } 
} else {
  if ($WiFiIP[0]) {
    if ($WiFi.DNSDomainSuffixSearchOrder -like $Domain2) { #--[ The wifi is connected --] 	
      $IP = $WiFiIP[0]  
	  write-host ""`n"Setting routes for wifi"`n""
	  $Notify.ShowBalloonTip(2500,$ScriptName,"Setting routes for wifi...",[system.windows.forms.tooltipicon]::Info)
      #SetRoutes $IP
      }
    } 
  }
}
	
#Write-Host $IP	

#IdentifyNics

#SetMappings

#Pause-Host

LoadApps

If ($debug){write-host "Completed All Operations..." -ForegroundColor DarkCyan}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzYZWTiFluhk+bcOZFvcjNJyb
# h2KgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMKCHfzX69/gNBzy
# nreXg04s/pUVMA0GCSqGSIb3DQEBAQUABIIBAI/O/WOx/kGeGeGrM9MhHxCTkVu9
# zWSTK8EkdtWJ802eRIGLURU/1h4Aaqis8UniUmLPzXsHwne4+yvW+5YQd87VS4rk
# XsXuZglnNQD5kg3VpMCDhhFF28Q8sZEQBCZXSMBt7FIUSlHVxyGlFN9PbG/wdBQL
# BOUHWpI0qzvaFrsNxbFVo54e9PeW21zKu6pHLnDwhGQvd8N/EWLFLYqMoATdftB/
# s/VyHp+r7Ili0WOQYhqYbr6Sk99cP/0p4voEny/u/JyMVONIMSdcdd8TTyutDW04
# IBfbT3HiG3d1ZG6e5wIBfPpB+oEFyVkShQsgLWUr1oxnW3ZEVHgv3DnVUf8=
# SIG # End signature block
