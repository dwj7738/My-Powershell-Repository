########################################
#Get-ADForestHealth V2
#By Winston McMiller
#Synoposis: script leverages Repadmin.exe and DCdiag.exe across the entire forest or domain to help analysis and troubleshooting. 


Param(
  [string]$filePath,
  [string]$Domain,
  [Switch]$Report
    )

$local = $env:Computername + "."+ $env:Userdnsdomain


Function WMIDateStringToDate($Bootup) {  
    [System.Management.ManagementDateTimeconverter]::ToDateTime($Bootup)  
} 

Function Get-ForestDNSAnalysis_Local{

                $adreporttxt = "ADREPORT for" + $domain + (Get-Date -Format M.d.yyyy.hh.mm.ss) +".txt"          
                $Dcdiag= dcdiag /test:DNS /v
                $DNSLog= $dcDiag -like "*invalid DNS server*" 
				$SRVLog= $dcDiag -like "*Missing SRV record*"
				$SRVLog2=$dcDiag -like "*Error details: 9003*"
                $CFLOG= $dcDiag -like "*Missing A record at DNS server*"
				$REP=repadmin /replsummary
                $w32tm = w32tm /monitor /computers:$dc /nowarn
                $icmp = ($w32tm -like "*ICMP*") -replace "ICMP:",""                
                If($icmp -le "0ms"){$timestatus="Optimal"}                IF($icmp -gt "300000ms"){$timestatus="Critical. Over 5 mins!"}                If($icmp -gt "100000ms"){$timestatus="Possible Drift Warning"}
                
                $CPULOAD= Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select Average 
                $Systems = Get-WMIObject -class Win32_OperatingSystem -computer $dc  
                $NIC=Get-wmiobject -class Win32_NetworkAdapterConfiguration -filter "IPEnabled=True"
                $ComputerIP = $nic.IPaddress[0] 
				$dnsServers = $nic.dnsserversearchorder 
                              
                                foreach ($system in $Systems) {  
                                   $Bootup = $system.LastBootUpTime  
                                   $LastBootUpTime = WMIDateStringToDate $bootup  
                                   $now = Get-Date
                                   $Uptime = $now - $lastBootUpTime  
                                                               }                                                              
                                                    
                		$unreachableServers = foreach ($d in $dnsServers) {
						    try { 
				        if ((-not (Get-Service -Name Dns -ComputerName  $d -ErrorAction SilentlyContinue))  -as [Bool]) {
						        $d
						}
						    } catch {
						         $d
						    }
						    }

							    $ADreports=New-Object PSObject -Property @{
							    HasInvalidDNSServerIPs = $($unreachableServers -as [bool])
							    MissingSrvRecords = $($srvLog -as [bool])
							    MissingARecord = $($cflog -as [bool])
							    DnsServerSearchOrder= ($dnsServers -join ([Environment]::Newline))
							    Unreachable_DNS_ServersIP = ($unreachableServers -join ([Environment]::Newline))
                                Computer_IP_Address = $ComputerIP
							    ComputerName = $DC
                                Time_Status = $timestatus
                                Time_Sync = $ICMP
                                Last_Bootup = $LastBootUpTime
                                AverageCPULoad= $CPULOAD.Average
                                Replication_Summary= ( $rep -replace "Beginning data collection for replication summary, this may take awhile:" -join ([Environment]::Newline))}                         
                                
                                $adreports                                
                                             
              If($srvlog){
              Write-Host "Repairing Missing SRV record on $DC" -ForegroundColor Green
              nltest /dsregdns
              $Repadmin=Repadmin /syncall
                         }
                         
              $Nltest
              If($Nltest -like "*ERROR_NO_TRUST_SAM_ACCOUNT*"){
              test-computersecurechannel -repair
                                                              } 
                                                              
              If($timestatus = "Critical. Over 5 mins!"){
              w32tm /config /update
              w32tm /resync
              Stop-Service -Name w32time
              Start-Service -Name w32time
              Get-Date -Format hh.mm.ss
              Write-Host "Time Service configured for $DC...." -ForegroundColor Green 
              }                                                
              
              If($unreachableServers){
              Write-Host "Bad DNS IP:$unreachableServers on $DC" -ForegroundColor Green
  
              $title = "Delete the misconfigured IP"
              $message = "Do you want to delete the misconfigured IP from $DC? "

              $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                     "Deletes the misconfigured IP from the DNS search order."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Retains the DNS search order."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {"You selected Yes."}
        1 {"You selected No."}
    }
If($result=0){
              netsh interface ipv4 delete dnsservers "local area Connection" $unreachableServers
              netsh interface ipv4 show dnsservers "local area Connection"
              $Repadmin
              }
                
               Write-Host "_______________________________________________________________________________________________________" -ForegroundColor Blue
               Write-Host " "
  }   
             IF($Report){$adreports >> $adreporttxt}  
  }                     

Function Get-ForestDNSAnalysis{
                
                $adreporttxt= "ADREPORT for" + $domain + (Get-Date -Format M.d.yyyy.hh.mm.ss) +".txt"  
                $Dcdiag = invoke-command -computername $DC -scriptblock {dcdiag /test:DNS /v}
                $DNSLog= $dcDiag -like "*invalid DNS server*" 
				$SRVLog= $dcDiag -like "*Missing SRV record*"
				$SRVLog2=$dcDiag -like "*Error details: 9003*"
				$CFLOG= $dcDiag -like "*Missing A record at DNS server*"
				$REP = invoke-command -computername $DC -scriptblock {repadmin /replsummary | where {$_ -ne ""}}
                $w32tm = invoke-command -computername $DC -scriptblock{w32tm /monitor /computers:$dc /nowarn}
                $icmp = ($w32tm -like "*ICMP*") -replace "ICMP:",""                                If($icmp[0] -le "0ms"){$timestatus="Optimal"}                IF($icmp[0] -gt "300000ms"){$timestatus="Critical. Over 5 mins!"}                If($icmp[0] -gt "100000ms"){$timestatus="Possible Drift Warning"}
                
                $CPULOAD = invoke-command -computername $DC -scriptblock {Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select Average }
                $Systems = invoke-command -computername $DC -scriptblock {Get-WMIObject -class Win32_OperatingSystem}
                $Nic=invoke-command -computername $DC -scriptblock {Get-wmiobject -class Win32_NetworkAdapterConfiguration -filter "IPEnabled=True"}
                $ComputerIP = $nic.IPaddress[0] 
				$dnsServers = $nic.dnsserversearchorder 
                              
                                foreach ($system in $Systems) {  
                                   $Bootup = $system.LastBootUpTime  
                                   $LastBootUpTime = WMIDateStringToDate $bootup  
                                   $now = Get-Date
                                   $Uptime = $now - $lastBootUpTime  
                                   $d = $Uptime.Days  
                                   $h = $Uptime.Hours  
                                   $m = $uptime.Minutes  
                                   $ms= $uptime.Milliseconds  
                                                                 }  
			        
						$unreachableServers = foreach ($d in $dnsServers) {
						    try { 
				            if ((-not (Get-Service -Name Dns -ComputerName  $d -ErrorAction SilentlyContinue))  -as [Bool]) {
						        $d
						}
						    } catch {
						         $d
						    }
						    }

							    $adreports=New-Object PSObject -Property @{
							    HasInvalidDNSServerIPs = $($unreachableServers -as [bool])
							    MissingSrvRecords = $($srvLog -as [bool])
							    MissingARecord = $($cflog -as [bool])
							    DnsServerSearchOrder= ($dnsServers -join ([Environment]::Newline))
							    Unreachable_DNS_ServersIP = ($unreachableServers -join ([Environment]::Newline))
                                Computer_IP_Address = $ComputerIP
							    ComputerName = $DC
                                Time_Status = $timestatus
                                Time_Sync = $ICMP
                                Last_Bootup = $LastBootUpTime
                                AverageCPULoad= $CPULOAD.Average
                                Replication_Summary= ( $rep -replace "Beginning data collection for replication summary, this may take awhile:" -join ([Environment]::Newline))}                         
                   
                   $adreports
                   
                                             
              If($srvlog){
              Write-Host "Repairing Missing SRV record on $DC" -ForegroundColor Green
              $Nltest=invoke-command -computername $DC -scriptblock {nltest /dsregdns}
              $Repadmin=invoke-command -computername $DC -scriptblock {Repadmin /syncall}
                         }
                         
              $Nltest
              If($Nltest -like "*ERROR_NO_TRUST_SAM_ACCOUNT*"){
              invoke-command -computername $DC -scriptblock {test-computersecurechannel -repair}

              If($timestatus = "Critical. Over 5 mins!"){
              invoke-command -computername $DC -scriptblock {w32tm /config /update}
              invoke-command -computername $DC -scriptblock {Stop-Service -Name w32time}
              invoke-command -computername $DC -scriptblock {Start-Service -Name w32time}
              invoke-command -ComputerName $DC -ScriptBlock {w32tm /resync}
              invoke-command -computername $DC -scriptblock {Get-Date -Format hh.mm.ss}
              Write-Host "Time Service configured for $DC...." -ForegroundColor Green 
              }
                                                              }   
              
              If($unreachableServers){
              Write-Host "Bad DNS IP:$unreachableServers on $DC" -ForegroundColor Green
  
              $title = "Delete the misconfigured IP"
              $message = "Do you want to delete the misconfigured IP from $DC? "

              $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                     "Deletes the misconfigured IP from the DNS search order."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Retains the DNS search order."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {"You selected Yes."}
        1 {"You selected No."}
    }
If($result=0){
              invoke-command -computername $DC -scriptblock {netsh interface ipv4 delete dnsservers "local area Connection" $args[0] } -Args $unreachableServers
              invoke-command -computername $DC -scriptblock {netsh interface ipv4 show dnsservers "local area Connection"}
              $Repadmin
              }
                IF($Report){$adreports >> $adreporttxt}
  
  }
                Write-Host "_______________________________________________________________________________________________________" -ForegroundColor Blue
               Write-Host " "
  }
              
If($Domain){
Write-Host "Enumerating $Domain Domain...." -ForegroundColor Green
  ipmo activedirectory
                $DCS=(get-addomain $domain).ReplicaDirectoryServers
                Foreach($DC in $DCS){
                If($local -eq $DC){Get-ForestDNSAnalysis_Local}
                If($local -ne $DC){Get-ForestDNSAnalysis}
} 
}
    
If($filePath){
$Domains=Get-Content $filepath
ForEach($Domain in $Domains){
Write-Host "Enumerating $Domain Domain...." -ForegroundColor Green
$DCS=(get-addomain $domain).ReplicaDirectoryServers
                Foreach($DC in $DCS){
                If($local -eq $DC){Get-ForestDNSAnalysis_Local}
                If($local -ne $DC){Get-ForestDNSAnalysis}
                            }
            }
}
            
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsCovr2/xaytTSdCL+kLABU4j
# s8igggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFLcVUjjWoMbljYSn
# 96tL13RiBcZDMA0GCSqGSIb3DQEBAQUABIIBAFIsy75U1/r34ZGBMy9nmoBVSM3B
# zZy0jUJQubvxCb7UiqFBTV7+JskcKZRNCLXl8wE73a2dJLtJ0YtvHV4b14elugQZ
# JZrFu1Do0LDk8QD1nGOUNv5mhP87XDSFo430fT63cVfy4lH1lDu6c+SOrxyWAEgW
# O8qJWlNs2FcsFXLAwGyEE0s0xftqQ9BeH+EZkNIKliQ8wWOM8Mmq8C3FISjk6nCi
# +iUfC7G622KFmWXYWvUQfgaQwHT/VUgjmaszxiUXIs3DgQIWkys0D9wUKCnVfDEk
# cfCYjBk4g7BfZFmPr+TO2tix26W1JpqKAtOE4GdzzfCgVFnG0F2OvM0uayw=
# SIG # End signature block
