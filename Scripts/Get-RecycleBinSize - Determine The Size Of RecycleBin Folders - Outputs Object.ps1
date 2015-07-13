# ------------------------------------------------------------------
# Title: Get-RecycleBinSize - Determine The Size Of RecycleBin Folders - Outputs Object
# Author: Brian Wilhite
# Description: The Get-RecycleBinSize function will query and calculate the size of each users Recycle Bin Folder.  The function uses the Get-ChildItem cmdlet to query items in each users' Recycle Bin Folder. Remove-Item is used to remove all items in all Recycle Bin Folders.
# Date Published: 27-Feb-12 11:28:53 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Get-RecycleBinSize-092f15c7
# Tags: disk space;recycle bin;recycle bin size
# Rating: 5 rated by 1
# ------------------------------------------------------------------

Function Get-RecycleBinSize
{
<#
.SYNOPSIS

This function will query and calculate the size of each users Recycle Bin Folder.  This function
will also empty the Recycle Bin if the -Empty parameter is specified.

.DESCRIPTION

This function will query and calculate the size of each users Recycle Bin Folder.  The function
uses the Get-ChildItem cmdlet to determine items in each users Recycle Bin Folder.  Remove-Item
is used to remove all items in all Recycle Bin Folders.  The function uses WMI and the
System.Security.Principal.SecurityIdentifier .NET Class to determine User Account to Recycle Bin
Folder.  Due to the number of objects and their values the default object output is in a 
"Format-List" format.  There may be SIDs that aren't translated for various reasons, the function
will not return an error if it is unable to do so, it will however, return a $null value for the
User property.  If there are a great number of items in the Recycle Bin Folders, the function
will take a few minutes to calculate.

.PARAMETER ComputerName

A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).

.PARAMETER Drive

A single Drive Letter or an array of Drive Letters to run the function against.  If the Drive
parameter is not used, the function will check all "WMI Type 3" (Logical Fixed Disks) drive letters.
The parameter will only accept, via RegEx, input that is formated as an actual drive letter C: or
D: etc.

.PARAMETER Empty

The Empty parameter is used to Remove Items from the Recycle Bin Folders, according to what is
queried.  Using the Empty parameter without the Drive parameter will Empty all the Recycle Bin
Folders on the Local or Remote Computer.

.EXAMPLE

Get-RecycleBinSize -ComputerName SERVER01

This example will return all the Recycle Bin Folders on the SERVER01 Computer.

Computer : SERVER01
Drive    : C:
User     : SERVER01\Administrator
BinSID   : S-1-5-21-3177594658-3897131987-2263270018-500
Size     : 0

.EXAMPLE

Get-RecycleBinSize -ComputerName SERVER01 -Drive D: -Empty

This example will Empty all the items in the Recycle Bin for the D: Drive.

.LINK

Windows Build Information:
http://en.wikipedia.org/wiki/Windows_NT
Win32_LogicalDisk
http://msdn.microsoft.com/en-us/library/windows/desktop/aa394173(v=vs.85).aspx
Win32_UserAccount
http://msdn.microsoft.com/en-us/library/windows/desktop/aa394507(v=vs.85).aspx
System.Security.Principal.SecurityIdentifier
http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx

.NOTES

Author: Brian Wilhite
Email:  bwilhite1@carolina.rr.com
Date:  02/24/2012
#>

[CmdletBinding()]
param(
 [Parameter(Position=0,ValueFromPipeline=$true)]
 [Alias("CN","Computer")]
 [String[]]$ComputerName="$env:COMPUTERNAME",
 [ValidatePattern(".:")]
 [String[]]$Drive,
 [Switch]$Empty
 )

Begin
 {
  #Adjusting ErrorActionPreference to stop on all errors
  $TempErrAct = $ErrorActionPreference
  $ErrorActionPreference = "Stop"
 }#End Begin Script Block
Process
 {
  Foreach ($Computer in $ComputerName)
   {
    $Computer = $Computer.ToUpper().Trim()
    Try
     {
      $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer
      Switch ($WMI_OS.BuildNumber)
       {
        {$_ -le 3790} {$RecBin = "RECYCLER"}
        {$_ -ge 6000} {$RecBin = "`$Recycle.Bin"}
       }#End Switch ($WMI_OS.BuildNumber)
      If (!$Drive)
       {
        $WMI_LDisk = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $Computer -Filter "DriveType = 3"
        Foreach ($LDisk in $WMI_LDisk)
         {
          $Disk = $LDisk.DeviceID
          $LDisk = $LDisk.DeviceID.Replace(":","$")
          $Bins = Get-ChildItem -Path \\$Computer\$LDisk\$RecBin -Force
          Foreach ($Bin in $Bins)
           {
            If ($Empty)
             {
              $Delete = $Bin.FullName + "\*"
              Remove-Item -Path $Delete -Exclude "desktop.ini" -Force -Recurse
             }#End If ($Empty)
            $Size = Get-ChildItem -Path $Bin.FullName -Exclude "desktop.ini" -Force -Recurse
            $Size = $Size | ForEach-Object {$_.Length} | Measure-Object -Sum
            
            #Attempting to Convert the Recycle Bin "Folder" Name to the Users Account.
            Try
             {
              $UserSID = New-Object System.Security.Principal.SecurityIdentifier($Bin.Name)
              $User = $UserSID.Translate([System.Security.Principal.NTAccount])
             }#End Try
            Catch
             {
              $User = $null
             }#End Catch
            If (!$User)
             {
              #Obtaining Local Account SIDs for $Bin.Name comparison.
              $WMI_UsrAcct = Get-WmiObject -Class Win32_UserAccount -ComputerName $Computer -Filter "Domain = '$Computer'"
              #Using a While Loop to search Local User Accounts for Matching $Bin.Name
              $i = 0
              While ($i -le $WMI_UsrAcct.Count)
               {
                If ($WMI_UsrAcct[$i].SID -eq $Bin.Name)
                 {
                  $User = $WMI_UsrAcct[$i].Caption
                  Break
                 }#End If ($WMI_UsrAcct[$i].SID -eq $Bin.Name)
                $i++
               }#End While ($i -le $WMI_UsrAcct.Count)
             }#End If (!$User)
            
            #Creating Output Object
            $RecInfo = New-Object PSObject -Property @{
            Computer=$Computer
            Drive=$Disk
            User=$User
            BinSID=$Bin.Name
            Size=$Size.Sum
            }
            
            #Formatting Output Object
            $RecInfo = $RecInfo | Select-Object Computer, Drive, User, BinSID, Size
            $RecInfo
           }#End Foreach ($Bin in $AllBins)
         }#End Foreach ($Drv in $Drive)
       }#End If ($Drive -eq $null)
      If ($Drive)
       {
        Foreach ($Disk in $Drive)
         {
          $MDisk = $Disk.Replace(":","$")
          $Bins = Get-ChildItem -Path \\$Computer\$MDisk\$RecBin -Force
          Foreach ($Bin in $Bins)
           {
            If ($Empty)
             {
              $Delete = $Bin.FullName + "\*"
              Remove-Item -Path $Delete -Exclude "desktop.ini" -Force -Recurse
             }#End If ($Empty)
            $Size = Get-ChildItem -Path $Bin.FullName -Exclude "desktop.ini" -Force -Recurse
            $Size = $Size | ForEach-Object {$_.Length} | Measure-Object -Sum
            
            #Attempting to Convert the Recycle Bin "Folder" Name to the Users Account.
            Try
             {
              $UserSID = New-Object System.Security.Principal.SecurityIdentifier($Bin.Name)
              $User = $UserSID.Translate([System.Security.Principal.NTAccount])
             }#End Try
            Catch
             {
              $User = $null
             }#End Catch
            If (!$User)
             {
              #Obtaining Local Account SIDs for $Bin.Name comparison.
              $WMI_UsrAcct = Get-WmiObject -Class Win32_UserAccount -ComputerName $Computer -Filter "Domain = '$Computer'"
              #Using a While Loop to search Local User Accounts for Matching $Bin.Name
              $i = 0
              While ($i -le $WMI_UsrAcct.Count)
               {
                If ($WMI_UsrAcct[$i].SID -eq $Bin.Name)
                 {
                  $User = $WMI_UsrAcct[$i].Caption
                  Break
                 }
                $i++
               }#End While ($i -le $WMI_UsrAcct.Count)
             }#End If (!$User)

            #Creating Output Object
            $RecInfo = New-Object PSObject -Property @{
            Computer=$Computer
            Drive=$Disk.ToUpper()
			User=$User
            BinSID=$Bin.Name
            Size=$Size.Sum
            }
            
            #Formatting Output Object
            $RecInfo = $RecInfo | Select-Object Computer, Drive, User, BinSID, Size
            $RecInfo
           }#End Foreach ($Bin in $AllBins)
         }#End Foreach ($Disk in $Drive)
       }#End Else
     }#End Try
    Catch
     {
      $Error[0].Exception.Message
     }#End Catch
   }#End Foreach ($Computer in $ComputerName)
 }#End Process
End
 {
  #Resetting ErrorActionPref
  $ErrorActionPreference = $TempErrAct
 }#End End
}#End Function
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU39LeHTk9hy8OBLMpA8lnV1OJ
# 6oSgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGDI4Jdcjc+Rn8fA
# NO4+t/r33MguMA0GCSqGSIb3DQEBAQUABIIBACc+sRW1haVehlgFWwYfDWMhPZJQ
# EFySHQH0fES4/RIH/YnXbT4GT2FKvcRzBRWlP+rHDWnUQWtMzm3NOyzNHI8GQ+Y9
# DX6BxRD/ZR7R5sBnI4W8C9YHyyHA6E5rt6bLJVv0yg+7i5xIW7cY9GVEfKFMJQTi
# vetvkZIEHFCGMadvkIhcsQpzzT2gB9Ymz6hVdfTGn+p0LlLpBCeyYdGxMY7fHxX2
# CeZ3LzkVU7UvKNJfuFEFApve9HIkVKEDhrhTvr/MO8uUb1hVF3BlD2qu1h6ww7vv
# dkNZVSN1QCAJTj4yueo9757WTGIdsd+aneNdrr8rbcNuUtDobPyq/+CiU6Q=
# SIG # End signature block
