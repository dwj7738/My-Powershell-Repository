#------------------------------------------------------------------------------------------------------------
# getinfo.psm1
# Change Log
# Date: 05/09/2014, By: Jeff Mason - modified to disregard Physical vs. Virtual - 
# now checks BOTH, should display info for both types, tested okay in my environment
#----------------------------------------------------------------------------------------------------------------------
# Purpose: To gather the following Computer Info from one or more servers:
#  Name, Type (phys/virt), O/S, Svc Pack, Phys Mem, # CPUs, # Cores,  Active IP address(es) + MAC, MAC for All NICS, & Serial #
# Credit to Original Author/Source: mohdazam89 on TechNet (Azam)
#  Source Link: 
# http://social.technet.microsoft.com/Forums/windowsserver/en-US/a6d4b749-badb-4051-a804-a0504f856481/powershell-to-get-servers-info?forum=winserverpowershell
#
# Other Authors: Jeff Mason, G. Samuel Hays, and possibly others: 
#
#    Jeff Mason (aka TNJMAN aka bitdoctor) - below are the changes/enhancements I made:
#    a) Changed memory "MB" spec to "GB" for better use in Excel
#    b) Added top comment section as documentation, how-to-run, etc.
#    c) Added NumberOfLogicalProcessors per tip from Mike Laughlin - CPU info is "cpucore & cpulp" (Processors & Logical Processors)
#    d) Added check for Microsoft VM servers
#    e) Added custom "$csv" output section to make it more "Excel-friendly" (since some fields don't export nicely)
#    f) Added "write $csv" to an output ("c:\computerinfo.csv") file
#    g) Added an "End{}" section to make it a proper/formal PowerShell module (not needed, but for consistency)
#    h) Combined "Active IP + MAC" (made sense at the time)
#    i) Added section to aggregate MAC address from all NICs, active or inactive, included DeviceID and "-" 
#       Note that disabled NICs will have NO MAC & only "DeviceID-"; i.e, similar to "#7-"
#    j) Added $outfile variable for report file
#    k) Made the process ONLY continue If $res = "Physical" (I only care about physical server inventory in this case)
#
# 1) Save/Copy this "getinfo.psm1" file to "c:\windows\system32\WindowsPowerShell\v1.0\Modules\" folder
# 2) Go into PowerShell
# 3) Import this module into powershell: import-module c:\Windows\System32\WindowsPowerShell\v1.0\Modules\getinfo.psm1
#
# 4) To run this against a single computer (or small # of computers), from PowerShell, after importing this module, type:
#      getinfo remote-server1 
# or, type:
#      getinfo remote-server1, remote-server2
#    (where "remote-server1" and "remote-server2 are the names of the remote computers to report against)
#
# 5) To run against a larger number of computers, 
#    a) Create a "wrapper script" to call this "getinfo" moudule, with computer name passed as parameter, each on a separate line
#       - Alternatively, you can place all computer names on one line - i.e., "getinfo server1, server2, server3"
#
#       #getinfo-servers.ps1 #wrapper script#
#       set-executionpolicy unrestricted
#       import-module "c:\Windows\System32\WindowsPowerShell\v1.0\Modules\getinfo.psm1"
#       getinfo remote-server1
#       getinfo remote-server2
#       getinfo remote-server3
#       #end of getinfo-servers.ps1 #wrapper script#
#
#    b) Execute the above-saved "getinfo-servers.ps1 "wrapper script"
#       (Assuming script is saved in "c:\scripts" folder)
#       powershell c:\scripts\getinfo-servers.ps1
#
# 6) Review the results:
#    notepad c:\scripts\computerinfo.csv
#----------------------------------------------------------------------------------------------------------------------
# NOTES: 
#  This APPENDS to the "$outfile" (c:\scripts\computerinfo.csv) - if you desire to start fresh, you must manually delete/rename that file before running
#  This does not work well with Windows Server 2003 - it's mainly for Windows 7 and higher, and Windows Server 2008 and higher
#----------------------------------------------------------------------------------------------------------------------
 
Function GetInfo {
 
      [CmdletBinding()]
 
      Param(
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)] 
      [string[]]$computername, 
      [string]$logfile = 'c:\scripts\unreachable.txt',
      [string]$outfile = 'c:\scripts\computerinfo.csv'
 
      )
 
BEGIN {

      Remove-Item $logfile –erroraction silentlycontinue
 
}
 
PROCESS {
 
      Foreach ($computer in $computername) {

            $continue = $true
            try {
 
                  $os = Get-WmiObject –class Win32_OperatingSystem –computername $computer –erroraction Stop
 
            } catch {
 
                  $continue = $false
                  "$computer is not reachable" | Out-File $logfile -append
 
            }
 

            if ($continue) {
 
                  $bios = Get-WmiObject –class Win32_BIOS –computername $computer
                  $os = Gwmi win32_operatingsystem -cn $computer
                  $mem = get-wmiobject Win32_ComputerSystem -cn $computer | select @{name="PhysicalMemory";Expression={"{0:N2}" -f($_.TotalPhysicalMemory/1gb).tostring("N0")}},NumberOfProcessors,Name,Model
                  $cpuinfo = "numberOfCores","NumberOfLogicalProcessors","maxclockspeed","addressWidth"


                  [string[]]$cpudata = Get-WmiObject -class win32_processor –computername $computer -Property $cpuinfo | Select-Object -Property $cpuinfo

                  $phyv = Get-WmiObject win32_bIOS -computer $computer | select serialnumber

                  $res = "Physical” # Assume "physical machine" unless resource has "vmware" in the value or a "dash" in the serial #                 


                  if ($phyv -like "*-*" -or $phyv -like "*VM*" -or $phyv -like "*vm*") { $res = "Virtual" } # else

                  #{                  

                   # Find all active NICs and IP of the NIC

                   $Networks = gwmi Win32_NetworkAdapterConfiguration -ComputerName $computer | ? {$_.IPEnabled}

                     foreach ($Network in $Networks) {[string[]]$IPAddress += ("[" + $Network.IpAddress[0] + " " + $Network.MACAddress + "]")}

                   $ActiveIPs = $IPAddress

                   $Networks = gwmi -ComputerName $computer win32_networkadapter | where-object { $_.physicaladapter }

                     foreach ($Network in $Networks) {

                       #if ({$_.$Network.MACAddress}) {[string[]]$MACinfo += "#" + $Network.DeviceID + "-" + $Network.MACAddress} else {[string[]]$MACinfo += "#" + $Network.DeviceID + "-Dis"}

                       [string[]]$MACinfo += "#" + $Network.DeviceID + "-" + $Network.MACAddress

                     }

                   $obj = New-Object –typename PSObject

# DISPLAY Section ($obj - output to screen)
# - For "report-ONLY," you can comment out the "$obj" (11 lines) below

                   $obj | Add-Member –membertype NoteProperty –name ComputerName –value ($computer) –PassThru |
                          Add-Member –membertype NoteProperty –name Hardware –value ($res) -PassThru |
                          Add-Member –membertype NoteProperty –name OperatingSystem –value ($os.Caption) -PassThru |
                          Add-Member –membertype NoteProperty –name ServicePack –value ($os.ServicePackMajorVersion) -PassThru |
                          Add-Member –membertype NoteProperty –name "PhysicalMemory(GB)" –value ($mem.PhysicalMemory) -PassThru |
                          Add-Member –membertype NoteProperty –name Processors –value ($mem.numberofprocessors)  -PassThru |
                          Add-Member –membertype NoteProperty –name CPUInfo –value ($cpudata) -PassThru |
                          Add-Member –membertype NoteProperty –name IPAddress –value ($ActiveIPs) -PassThru  |
                          Add-Member –membertype NoteProperty –name NICs –value ($MACinfo) -PassThru |
                          Add-Member –membertype NoteProperty –name Serial -value ($phyv)

# REPORT Section ($csv - output to file)

                   $csv = $computer + "," `
                           + $res + "," `
                           + $os.Caption +"," `
                           + $os.ServicePackMajorVersion + "," `
                           + $mem.PHysicalmemory + "," `
                           + $mem.numberofprocessors + "," `
                           + $cpudata + "," `
                           + $ActiveIPs + "," `
                           + $MACinfo + "," `
                           + $phyv

                   Write-Output $obj
                   #Write-Output $csv - uncomment this to debug the report output line
                   Write $csv | Out-File $outfile -append

                 # } # End of Else ($res = "Physical)

            } # End of IF (continue)
            
      } # End of ForEach
 
  } # End of Process

END {}
 
} # End Function
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsGoPRwQYVhNq4i1P9NoJMpty
# LfqgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKXSRxRRF3cWe0+t
# iMTJUpWfnt3vMA0GCSqGSIb3DQEBAQUABIIBAAR9VL2GdYj5ZY8ML1GabpFMbSb5
# Ik9v3Sk+r59L+IBhFhqWsVj0+zCzJrht1le2aJR6ML852XjBGjpZHMzoitZhMctt
# hp1H6LFM8XFvF/iRMhJy2cKvfLmhz8cHdnObQ6E58Jvao2wiCB6wey9fh+X83Izl
# 9l+toOdu4gykBtqDxYqS49afrwMq67g8wTYKc+MZ4qQz6WzaJhYGZ4J1KnljkYs4
# LG0gpObyb3vDjn+nXsTfn3iGPpTJ95fM6sjasEXtjaHpKo2TdQO0j5g4tnZHYdtF
# PVeTp12Bas/afu8IX/nSlHSJovLzE7yDxd0Iq2TXqiKV5LAobWNvPO0AMCo=
# SIG # End signature block
