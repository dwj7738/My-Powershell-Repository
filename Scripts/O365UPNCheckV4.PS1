######################################################################################################################################################
# Script Title:    .\O365UPNCheck.ps1
# Script Version:  Version 4.0 February 7, 2012
# Script Author:   Rick Bergman & Ray Zabilla, Microsoft Corporation                                    
#                                                                                         
# Script Purpose:  Uses an import file to retrive the users current DN & UPN from AD, then checks to users metadata to see when their UPN was updated 
#                  and on which Server it was updated on.  Next it will grab all Event ID 642 from the list of DC's.
#
# Script Paramaters:  .\O365UPNCheckV4.ps1 'Full' - will run the event log gathering step
#                     .\O365UPNCheckV4.ps1 with no command line parameters, will log only UPN update information and NOT gather the Security event logs              
#                                                                                         
# Result:          Script generates the following files:
#                  Output.csv - which then deleted when the script completes
#                  BadUPN_<DateTimeStamp>.csv - List of UPN that have changed
#                  O365UPNCheck_<DTS>.csv - General Log
#                  EventID642_<SrvName>_<DTS>.log        \ Both are created for each DC that is scanned.
#                  EventID642_<SrvName>_<DTS>_Timing.log / Timing how long has it taken for the log
#
# Email:           An Email notification will be sent to DL_UPN_Changes@Contoso.com DL including the BadUPNs from the 1600 user list
#
######################################################################################################################################################

#-----------------Configurations--------------------
Param($RunType)
$IFN = ".\1600ToFix.csv"
$IFile = Import-Csv $IFN
$DT = Get-Date -format "yyyymmddHHmmss"
$LogFile = ".\O365UPNCheck_" + $DT + ".log" 
$CompFile = ".\Output.csv"
$BadUPN = ".\BadUPN_" + $DT + ".log"
$SrvArray = @()
$DC = (Get-ADDomainController).HostName
$GC = $DC + ":3268"
$SB = "DC=Contoso,DC=com"
$Domain = "Contoso.com"

#---------------End Configurations-------------------------

# Creates and Open the General Log
Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop 
Add-Content -Path $LogFile -Value "O365UPNCheck.ps1 Version 1.0 (January 31,2012)" 
Add-Content -Path $LogFile -Value $("Started: " + (Get-Date).ToString()) 
Add-Content -Path $LogFile -Value "Input file: $FN"
Add-Content -Path $LogFile -Value "Log file: $LogFile" 
Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop 
Add-Content -Path $LogFile -Value " "

# Check for AD Module, if not there add it, otherwise continue
If ( (Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue) -eq $null )
{
    Import-Module ActiveDirectory
}

# Check for existence of of the Output file, delete if it exists because the assumption is that it is old
If (Test-Path $CompFile)
{
    Remove-Item $CompFile
}

# Updating the Script Run Log
Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop 
Add-Content -Path $LogFile -Value "Started Processing Input File & Checking AD Information"
Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop
Add-Content -Path $LogFile -Value " "

# Use the Input File to create a comparison file by querying AD
Add-Content -Path $CompFile -Value "SamAccountName;UserPrincipalName;DistinguishedName"

# loop through each record in the input file and get the SamAccountName, UPN and DistinguishedName and write to the log files
ForEach ($Obj in $IFile)
{
    $SAM = $Obj.sAMAccountName
    $OUser = Get-ADUser -Filter {sAMAccountName -eq $SAM} -Server $GC -SearchBase $SB
    If ($OUser)
    {
        Add-Content -Path $CompFile -Value $($OUser.SamAccountName + ";" + $OUser.UserPrincipalName + ";" + $OUser.DistinguishedName)
        Add-Content -Path $LogFile -Value $("SUCCES - User Found in AD - " + $OUser.SamAccountName)
    }
    Else
    {
        Add-Content -Path $LogFile -Value $("ERROR - User NOT Found in AD - " + $OUser.SamAccountName)
    }  
}

# Updating the Script Run Log
Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop 
Add-Content -Path $LogFile -Value "Started Processing Changed UPN's and Finding EventID 642"
Add-Content -Path $LogFile -Value $("Created an UPN Error Log - " + $BadUPN)
Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop
Add-Content -Path $LogFile -Value " "

# Use the Comparsion file to compare user account UPN to see if it has any "."
$CFile = Import-Csv $CompFIle -Delimiter ";"

# Create the Incorrect UPN Log file and write the header
Add-Content -Path $BadUPN -Value "SamAccountName,UserPrincipalName,DistinguishedName,OriginatingServer,LastOriginatingChangeTime"

# Loop through all users to get their Replication Meta Data Information
ForEach ($Acct in $CFile)
{
    # Split the UPN value at the "@"
    $SPLT = $Acct.UserPrincipalName -split "@"
    $Name = $SPLT[0]
    
    # Check to see if the first part of the UPN contains a "." Example John.Doe, if not then get the AD Meta Data 
    If (-not ($Name.Contains(".")))
    {
        # Get the Replication Meta Data
        $ObjectDN = $Acct.DistinguishedName
        $Property = "userprincipalname"
        $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain",$domain)
        $oDC = [System.DirectoryServices.ActiveDirectory.DomainController]::findOne($context)
        $meta = $oDC.GetReplicationMetadata($objectDN)
        $OrgSvr = $meta.userprincipalname.OriginatingServer
        $LastChg = $meta.userprincipalname.LastOriginatingChangeTime
        
        # Write to the Bad UPN Log
        Add-Content -Path $BadUPN -Value $($Acct.SamAccountName +","+ $Acct.UserPrincipalName +","""+ $ObjectDN +""","+ $OrgSvr +","+ $LastChg)
        Add-Content -Path $LogFile -Value $("ERROR - User's UPN was incorrect " + $Acct.SamAccountName)
        
        # Filter out duplicate Server names
        If ($OrgSvr -ne $null)
        {
            If (-not ($SrvArray -Contains ($OrgSvr)))
            {
                $SrvArray += $OrgSvr
            }
        }
    }
    Else
    {
        # Log the Good Users
        Add-Content -Path $LogFile -Value $("SUCCESS - User's UPN was correct - " + $Acct.SamAccountName)
    } 
}

# Check input param for full run or not
If ($RunType -eq "Full")
{
    # Updating the Script Run Log
    Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop 
    Add-Content -Path $LogFile -Value "Started Finding EventID 642 from a lists of DCs"
    Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop
    Add-Content -Path $LogFile -Value " "

    # Connect to the Servers in list and dump the security event logs for Event ID 642
    ForEach ($Srv in $SrvArray)
    {
        Start-Job -Name "DmpEvt$Srv" -ArgumentList $Srv -ScriptBlock {
            Param ($comp)
            $DT = Get-Date -format "yyyymmddHHmmss"
            $CompName = ($comp.SPlit("."))[0]
            $File = "D:\Work\EventID642_" + $compName + "_" + $DT + ".Log"
            $Timing = "D:\Work\EventID642_" + $compName + "_" + $DT + "_Timing" + ".Log"
    	    $stime = Get-Date
    	    Add-Content -path $Timing -Value "  -------------  Started processing log file processing at   $stime"
            GWMI Win32_ntlogevent -Filter "logfile='Security' AND EventCode=642" -ComputerName $Comp | Out-File -FilePath $File
            # Get-EventLog Security -Computer $compName -newest 100 | Out-File -FilePath $File
           	$etime = Get-date
    	    Add-Content -path $Timing -Value "  -------------  End Log file processing at  $etime"
        }
    }
}
Else
{
    Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop 
    Add-Content -Path $LogFile -Value "The Option was choosen to skip scanning the event logs for Event ID 642"
    Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop
    Add-Content -Path $LogFile -Value " "

}
If (Test-Path $CompFile)
{
    Remove-Item $CompFile
}
Add-Content -Path $Logfile -Value " "
Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop 
Add-Content -Path $Logfile -Value "Sending Email Notification that the script has run"
Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop 

$EmailFrom = "Test@Contoso.com"
$EmailTo = "DL_UPN_Changes@Contoso.com"
$EmailSubject = "O365UPNCheckV4.PS1 Script has completed"
$EmailBody = "Attached is the output from the Office 365 UPN Check Script"
$Attach = Get-ChildItem $BadUPN
$SMTPSvr = "Mail1.Contoso.com"

Send-MailMessage -From $EmailFrom -To $EmailTo -Subject $EmailSubject -Body $EmailBody -Attachments $Attach -SMTPServer $SMTPSvr

Add-Content -Path $Logfile -Value " "
Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop 
Add-Content -Path $Logfile -Value $("Completed: " + (Get-Date).ToString())
Add-Content -Path $LogFile -Value "------------------------------------------------" -ErrorAction Stop 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUg6pFkqPZy2JlKfnzSKfZ3d4E
# 3GqgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFO6kDErG9yvDB0CR
# WtJ8yFnuuwUVMA0GCSqGSIb3DQEBAQUABIIBAJvZrNe7cfRefqUXIz62Z/xCWOwS
# +oOD50g8Nyb9tt/dPLn8zteS/hbwbgHe/Pa7DLFnu8NEt/279RIjm8dKHbdXOk8K
# 0pjYTIuE9IdpFBoMvhpnKStmHSkkyZ2aVt7Sq5bw6IzvoJC5NS+XD4Ma/O9jVlQg
# YQ7DFEj1VBaKxmrK0BILkqTrZFgEli47za3kghQFxl24B407D+rOJ3l2cfsjKMXW
# BYt+oUes/Jf62kBAaDRb55RhLinaNnK/7YHUNRfYvqpWvTlv6RDfy93MMWD5yv/U
# CYA1dsEmjPVLCFYPfcYjQU4GXsrqbY8UKz4dbD0B7hMmu/ovGt87Y458IdA=
# SIG # End signature block
