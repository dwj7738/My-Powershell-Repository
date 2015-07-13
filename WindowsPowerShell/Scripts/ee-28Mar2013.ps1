<#
=====================================================================
Title       : Experts- Exchange Question
Description : http://www.experts-exchange.com/Programming/Languages/Scripting/Powershell/Q_28078813.html#a39031922
Author      : David Johnson (ve3ofa)
Date        : 29/04/2013
Input       : 
Output      : 
Usage		: PS> .\find-old-files.ps1Notes		: This will check all drives on All Named Servers
Tag			: included function http://gallery.technet.microsoft.com/scriptcenter/Get-files-older-than-a-76dd16fd get-filesolderthan
## =====================================================================
#>
function ee-28mar2013
{
$ErrorActionPreference = "silentlycontinue"
$servers = Get-Content c:\test\servers.txt
$LastWrite = get-date "01/01/2010"
$dtstart = Get-Date
$age = $dtstart - $LastWrite
$DaysOld = $age.Days
$MyObject = $null
$FileArray = $null
$i = 0
$FileArray = @()
foreach ($server in $servers) {

#	$drives = $null
#	$drive = $null
    $drives = get-drives1
     
#    $drives = Get-DriveInfo
	foreach ($drive in $drives) {
		$driveletter = $drive.deviceid + "\"
		$d = "Scanning Drive: " + $driveletter
		$d
		Get-FilesOlderThan -Path $driveletter -PeriodName Days -PeriodValue $DaysOld -Recurse | ft
	}
}
$dtend = Get-Date
Write-Output("Elapsed Time:" + ($dtend - $dtstart))
}

function get-drives1 {
get-wmiobject win32_logicaldisk -filter "drivetype=3" | select-object deviceid, freespace,size
}

function get-drives2 {
$d = Get-PSDrive | where {$_.Name -like "?" -and $_.free -ge 1} 
foreach ($dd in $d) {select_object Name }

}

Function Get-FilesOlderThan {
    [CmdletBinding()]
    [OutputType([Object])]   
    param (
        [parameter(ValueFromPipeline=$true)]
        [string[]] $Path = (Get-Location),
        [parameter()]
        [string[]] $Filter,
        [parameter(Mandatory=$true)]
        [ValidateSet('Seconds','Minutes','Hours','Days','Months','Years')]
        [string] $PeriodName,
        [parameter(Mandatory=$true)]
        [int] $PeriodValue,
        [parameter()]
        [switch] $Recurse = $false
    )
    
    process {
        
        #If one of more of the paths specified does not exist generate an error  
        if ($(test-path $path) -eq $false) {
            write-error "Cannot find the path: $path because it does not exist"
        }
        
        Else {
        
            <#  
            If the recurse switch is not passed get all files in the specified directories older than the period specified, if no directory is specified then
            the current working directory will be used.
            #>
            If ($recurse -eq $false) {
        
                Get-ChildItem -Path $(Join-Path -Path $Path -ChildPath \*) -Include $Filter | Where-Object { $_.LastWriteTime -lt $(get-date).('Add' + $PeriodName).Invoke(-$periodvalue) `
                -and $_.psiscontainer -eq $false } | `
                #Loop through the results and create a hashtable containing the properties to be added to a custom object
                ForEach-Object {
                    $properties = @{ 
                        Path = $_.Directory 
                        Name = $_.Name 
                        DateModified = $_.LastWriteTime }
                    #Create and output the custom object     
                    New-Object PSObject -Property $properties | select Path,Name,DateModified 
                }                
                  
            } #Close if clause on Recurse conditional
        
            <#  
            If the recurse switch is passed get all files in the specified directories and all subfolders that are older than the period specified, if no directory
            is specified then the current working directory will be used.
            #>   
            Else {
            
                Get-ChildItem  -Path $(Join-Path -Path $Path -ChildPath \*) -Include $Filter -recurse | Where-Object { $_.LastWriteTime -lt $(get-date).('Add' + $PeriodName).Invoke(-$periodvalue) `
                -and $_.psiscontainer -eq $false } | `
                #Loop through the results and create a hashtable containing the properties to be added to a custom object
                ForEach-Object {
                    $properties = @{ 
                        Path = $_.Directory 
                        Name = $_.Name 
                        DateModified = $_.LastWriteTime }
                    #Create and output the custom object     
                    New-Object PSObject -Property $properties | select Path,Name,DateModified 
                }

            } #Close Else clause on recurse conditional       
        } #Close Else clause on Test-Path conditional
    
    } #End Process block
} #End Function

ee-28mar2013
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVZofqgWW7Ol7EDcCixSBgIwR
# UTOgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHhToNeyIKmZqdM2
# KAYlO0yMr938MA0GCSqGSIb3DQEBAQUABIIBACCglpMGHcfSDtuVWFu2E8iaZWZR
# zK5hf3/Zc2u5QmaBn/UaKVjp6YTNh/Jjo2pPHq7bnaHXGArspGd01SZA/wMv8cSn
# E46RtHKSY3GMjL+W7OwP3Spc3vTSr+8WoKlV/0AMurJNfZ2Ccc4cHON9BcdBQLLz
# fBU0b8Fa0/IvplFT1PsL4cXeeaUUqPrHM+LjbAKnWxTFHfaDpNFme7bRqaG7fThC
# 0vaG8p2eq+oYfspdfunUPw5FsfF0pOM0YFhP6sRQXRa4unW+tZRswpyl+UB5+KlK
# YcQH6Q5UmrnW1w+EEna+A5SbQNheD8MRIP44wQ+/mg12p8yx4g40kVNMeuc=
# SIG # End signature block
