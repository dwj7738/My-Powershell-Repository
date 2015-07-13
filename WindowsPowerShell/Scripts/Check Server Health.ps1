########################################################
# Created by Brian English 
#   Brian.English@charlottefl.com
#   eddiephoenix@gmail.com
# 
# for Charlotte County Government
# No warranty suggested or implied
########################################################
# Purpose: Check Server Service Health
########################################################
# Notes:   For checking Vmware to work you must have the VMWare ToolKit for windows installed
#          For checking Citrix to work you must have the MPSSDK intalled
#          For checking DNS to work you must have dcdiag in your path
########################################################
#input params
param($Server)
#################
#other variables
#################
$GLOBAL:priority="normal"
$FreePercent = 5
$date = date
#################

#turn off error handling
#$SavedEA=$Global:ErrorActionPreference 
#$Global:ErrorActionPreference="SilentlyContinue" 

$inAry = @($input)
if($inAry.count -gt 0)
{$server = $inary}


#############
function checkSystem()
{ $status = "`nChecking Server Systems"    
  
  for($i = 0; $i -lt @($Server).count; $i++ ) 
  { $srv = @($Server)[$i]
    $checkVMWare = $false
    $checkDNS = $false
    $checkDHCP = $false
    $checkShares = $false
    $checkExc = $false
    $checkCitrix = $false
    $checkIIS = $false
    
    write-progress "Checking Server Systems: $srv "-> -perc ($i * (100/@($Server).count))
    
    $status += "`n***$srv***"
    $errcnt = 0
    $error.clear()
    
    if((ping-computer "$srv").protocoladdress -ne "")
    {
      if((gwmi -computername $srv win32_computersystem).dnshostname -ne $srv -or (gwmi -computername $srv win32_computersystem).name -ne $srv)
      { $status += "`n`t! ServerName does not match"
        $errcnt += 1
      }
    
      foreach($drive in(gwmi win32_logicaldisk -computername $srv | where{$_.Drivetype -like "3"}))
      { if((($drive.freespace/1gb)/($drive.size/1gb) * 100 ) -lt $FreePercent)
        { $status += "`n`t! Drive: " + $drive.deviceid + " Free Space: " + ($drive.freespace/ 1GB) + "GB"
          $priority = "high"
          $errcnt += 1
        }
      }
      
      foreach($svc in(gwmi win32_service -computername $srv | where{$_.StartMode -like "Auto" -and $_.name -ne "SysmonLog"}))
      { if($svc.state -ne "Running")
        { $status += "`n`t! Service: " + $svc.DisplayName + " is " + $svc.state
          $errcnt += 1 
        }
        if($svc.name -eq "vpxd" -and $svc.state -eq "Running")
        {$checkVMWare = $true}
        if($svc.name -eq "DNS" -and $svc.state -eq "Running")
        {$checkDNS = $true}
        if($svc.name -eq "DHCPServer" -and $svc.state -eq "Running")
        {$checkDHCP = $true}
        if($svc.name -eq "lanmanserver" -and $svc.state -eq "Running")
        {$checkShares = $true}
        if($svc.name -eq "MSExchangeIS" -and $svc.state -eq "Running")
        {$checkExc = $true}
        if($svc.name -eq "cpsvc" -and $svc.state -eq "Running")
        {$checkCitrix = $true}
        if($svc.name -eq "IISADMIN" -and $svc.state -eq "Running")
        {$checkIIS = $true}
      }
          
      if($checkVMWare)
      { $vi = get-esx $srv
        
        $status += "`nHosts"    
        foreach($vmh in get-vmhost)
        { if($vmh.state -ne "Connected")
          { $status += "`n`t! Host: " + $vmh.Name + "; State: " + $vmh.state  }
        }
        
        $status += "`nVMs"
        $vms = (get-vm -server $vi)      
        $greenvms = 0
        
        $status += "`n`tTotal VMs: " + $vms.count
        $status += "`n`tVMs powered Off: " + ($vms | where{$_.PowerState -eq "PoweredOff"}).count
        $status += "`n`tVMs powered On: " + ($vms | where{$_.PowerState -eq "PoweredOn"}).count
            
        foreach($vm in ($vms | where{$_.PowerState -eq "PoweredOn"}))
        { $vmv = get-view $vm.id
          
          if($vmv.Overallstatus -ne "green" -or $vmv.configstatus -ne "green") # -or $vmv.guestheartbeatstatus -ne "green")
          { $status += "`n`t`t" + $vm.name + " Overall: " + $vmv.overallStatus
            $status += "`n`t`t" + $vm.name + " Config: " + $vmv.configStatus
            $status += "`n`t`t" + $vm.name + " Heartbeat: " + $vmv.GuestHeartbeatStatus
            
            foreach($alrm in $vmv.triggeredAlarmState)
            { $av = get-view $alrm.alarm
              $status += "`n`t`t " + $vm.name + " Triggered: " + $av.info.Name
            }
            $priority = "high"
          }
          else
          {$greenvms += 1}              
        }#for
        $status += "`n`tGreen VMs: " + $greenvms + "`n"
      }
      
      if($checkDNS)
      { foreach($ln in (dcdiag /test:DNS /s:$srv /v))
        { if( $ln -like "*warning:*" -or $ln -like "*error:*") 
          {$status += "`n`t" + $ln.trim()}
        }
        foreach($ln in (dcdiag /test:CheckSecurityError /s:$srv /v))
        { if($ln -like "*warning:*" -or $ln -like "*error:*") 
          {$status += "`n`t" + $ln.trim()}
        }
      }#checkdns
      
      if($checkDHCP)
      {
        ##########################
        #add code to check DHCP data
      }#checkDHCP
      
      if($checkShares)
      { foreach($share in (gwmi win32_share -computername $srv | where {$_.status -ne "OK"}))
        { $status += "`n`t! Share: " + $share.Name + " is " + $share.status
          $errcnt += 1
        }      
      }#checkShares
      
      if($checkExc)
      { foreach($exc in (gwmi ExchangeConnectorState -namespace "root\cimv2\applications\exchange" -computername $srv | where {$_.IsUp -ne $true}))
        { $status += "`n`t! Exchange Connector: " + $exc.Name + " is DOWN"
          $errcnt += 1
        }
        
        foreach($exc in (gwmi ExchangeQueue -namespace "root\cimv2\applications\exchange" -computername $srv | where {$_.NumberOfMessages -gt 1}))
        { $status += "`n`t! Exchange Queue: " + $exc.QueueName + " has " + $exc.NumberofMessages
          $errcnt += 1
        }
        
        foreach($exc in (gwmi Exchange_Logon -namespace "root\microsoftexchangev2" -computername $srv | where {$_.Latency -gt 60000}))
        { $status += "`n`t! Exchange Logons: " + $exc.MailboxDisplayName + " in Store " + $exc.StoreName + " has a latency of " + $exc.Latency
          $errcnt += 1
        }
        
      }#checkExc
      
      if($checkCitrix)
      { $mfserver = New-Object -com "MetaframeCom.MetaFrameServer"
        $mfserver.initialize(6,$srv)
        $status += "`n`t Sesion Count " + $mfserver.SessionCount
        
        switch($mfserver.WinServerObject.EnableLogon)
        {
          "0" { $status += "`n`t! Not Allowing Connections"
                $errcnt += 1
              }
          "1" {}
        }
      }#checkCitrix
      
      if($checkIIS)
      { $pathToTest = "\\$srv\c$\windows\system32\inetsrv\metabase.xml"
        if(test-path $pathToTest)
        { $mb=[xml](get-content $pathToTest)
        
          $WebSites = $mb.configuration.MBProperty.IIsWebServer 
          $WebVDirs = $mb.configuration.MBProperty.IIsWebVirtualDir
          
          If(!($mb.configuration.MBProperty.IIsWebService.Custom | where {$_.name -eq "ServerComment"}).value) 
          { $WebServerName = "[UNKNOWN]"  } 
          Else 
          { $WebServerName = ($mb.configuration.MBProperty.IIsWebService.Custom | where {$_.name -eq "ServerComment"}).value }
          
          If($WebServerName -ne $srv) 
          { $status += "`n`t! WebServer Name Mismatch $WebServerName, $srv"  
            $errcnt += 1
          }
        
          ForEach ($Site in $WebSites) 
          { if($Site.ServerComment -notlike "Allows*")
            { $sitePath = "$srv" + ($site.location -replace "/LM","")
              $siteState = ([ADSI]("IIS://$sitepath")).serverstate
              if($siteState -ne "2")
              { switch($sitestate)
                { "1" {$siteState = "starting"}
                  "2" {$siteState = "started"}
                  "3" {$siteState = "stopping"}
                  "4" {$siteState = "stopped"}
                  "5" {$siteState = "pausing"}
                  "6" {$siteState = "paused"}
                  "7" {$siteState = "continuing"}
                }
                $status += "`n`t! " + $Site.ServerComment + " is not running: state " + $sitestate
                $errcnt += 1
              }
            }
          }
        
        }   
        else
        { $status += "`n`t! Unable to verify IIS Metabase"
          $errcnt += 1
        }
      }#checkIIS
    }
    else
    { $status += "`n`t! Server Unreachable"
      $errcnt += 1
    }
    
    if($error[0])
    { $status += "`n`t Errors Occured: "
      foreach($err in $error)
      { $status += "`n`t`!" + $err }
    } 
    elseif($errCnt -eq 0)
    {$status += "`n***$srv*** Healthy" }
    else
    {$status += "`n***$srv*** Unhealthy"}
    $status
    $status = ""
  }#for
}#checkSystem
#############

########################################################
#Execute script
############

checkSystem 
########################################################
#reset error handling
#$Global:ErrorActionPreference=$SavedEA
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUePopuLfM8im/Lerqi4xXUc4p
# 4HmgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMVjWEFB9EaBPMmP
# bPNMXAI9l3AWMA0GCSqGSIb3DQEBAQUABIIBAGNjZmPkpBLUFfBvRVVrZmn+dxJN
# MOm0LGBRLT/0foBe4IQv1RJRvFosqFS3ffy5BX1ijf0lurKm89c/wBcXNeRh2l63
# 5WxZQpu45xnZw0Kxkmc406JQBGInjCEYrFxE9dNesfpARew3Ci10v/wzFhiqj9w7
# P90HrDx357XxnWvLQD1YXo0Ku9VYLQIJvsbiRZpv5b/GfvXWnF7AbKajMMMmHyJi
# ynIcYbDwwvy2mL8aY8qm/f56mhY/IlSJk1pozqh1fpvxgX8LVQVt0zk6bKI7Dmv0
# vY4O7EplJ2LYEo4EZ8XqqhiBL/bi17DgLhkwTFsORDc0mdmiUwlOWbvjMaM=
# SIG # End signature block
