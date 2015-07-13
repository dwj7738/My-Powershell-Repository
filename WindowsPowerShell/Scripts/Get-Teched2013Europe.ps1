#######################################################################################################################                        
# Description:   Download MMS 2013 Channel 9 videos
# PowerShell version: 3                   
# Author(s):     Stefan Stranger (Microsoft)
#                Jamie Moyer (Microsoft          
# Example usage: Run Get-MMS2013Channel9Videos.ps1 -path c:\temp -verbose
#                Select using the Out-Gridview the videos you want to download and they are stored in your myvideos folder.
#                You can multiple select videos, holding the ctrl key.
# Disclamer:     This program source code is provided "AS IS" without warranty representation or condition of any kind
#                either express or implied, including but not limited to conditions or other terms of merchantability and/or
#                fitness for a particular purpose. The user assumes the entire risk as to the accuracy and the use of this
#                program code.
# Date:          04-13-2012                        
# Name:          Get-MMS2013Channel9Videos.ps1            
# Version:       v1.001 - 04-14-2012 - Stefan Stranger - initial release
# Version:       v1.005 - 04-29-2013 - Jamie Moyer, Stefan Stranger - added more robustness and HTML Report
########################################################################################################################
#requires -version 3.0

[CmdletBinding()]
Param
(
        # Path where to store video's locally
        [Parameter(Mandatory=$false,
                   Position=0)]
        
        $Path=[environment]::getfolderpath("myvideos") +"\TechEd2013-Europe", [Parameter(Mandatory=$false,Position=1)]
        $rssfeed="http://channel9.msdn.com/Events/TechEd/Europe/2013/RSS/mp4high"
    )

function Get-NewFileName($name)
{
    Write-Verbose "Calling Get-NewFileName Function"
    $r=$Path+"\"+(($name -replace "[^\w\s\-]*") -replace "\s+") + ".mp4";$r
}

Write-Verbose "Remove last slash if added using the downloaddirectory Parameter"
if ($path.EndsWith("\")){$path = $path.Substring(0,$path.Length-1)}
write-verbose "Path is: $path"

Write-Verbose "Checking if Download directory $Path exists"
if(!(test-path $Path -PathType Container))
{
    Write-Verbose "Creating $Path"
    New-Item -ItemType Directory $Path | Out-Null
}

Write-Verbose "Downloading RSS Feed Items from $rssfeed"
$feeditems = Invoke-RestMethod $rssfeed
[array]$feeditemsWithDetails = $feeditems | 
    select Title, Summary, Duration, Enclosure,creator | 
        Add-Member -MemberType ScriptProperty -Name AlreadyDownloaded -Value {(test-path("$Path\$($this.enclosure.url.split('/')[6])"))} -PassThru -Force |
        Add-Member -MemberType ScriptProperty -Name Destination -Value {("$Path\$($this.enclosure.url.split('/')[6])")} -PassThru -Force |
        Add-Member -MemberType ScriptProperty -Name Source -Value {$this.enclosure.url} -PassThru -Force |
            select AlreadyDownloaded,Title, Summary, Duration, Enclosure,Source,Destination,creator | sort Title

Write-Verbose "Add all already downloaded items back to the list"
$duplicateVideoNames = $feeditemsWithDetails |sort name| group destination | where-object {$_.Name -ne "" -and $_.Count -gt 1} | 
    ForEach-Object {$_.Group}

Write-Verbose "Remove the posts with duplicate file names from the feeditemsSelected array"
$feeditemsSelected = @($feeditemsSelected | Where-Object {$duplicateVideoNames -notcontains $_})

Write-Verbose "Change video names to filenames, check to see if they are downloaded already and added them back to the array with updated details"
$duplicateVideoNames | foreach-object {
                                        $newDestination = Get-NewFileName $_.Title
                                        $_.Destination = $newDestination
                                        $_.AlreadyDownloaded = (Test-Path $newDestination)
                                        $feeditemsWithDetails += $_
                                      }

Write-Verbose "Open Out-GridView to select vidoes to download"
[array]$feeditemsSelected = $feeditemsWithDetails| Out-GridView -PassThru | 
    select AlreadyDownloaded,Title, Summary, Duration, Enclosure,Source,Destination

Write-Verbose "Downloading videos"
$feeditemsSelected |Where-Object{!(Test-Path $_.Destination)} | select Source,Destination | Start-BitsTransfer -Priority Foreground | Out-Null

Write-Verbose "Add all already downloaded items back to the list"
$feeditemsWithDetails | where-object {$_.AlreadyDownloaded} | 
                            foreach-object {
                                                if(-not [bool]($feeditemsSelected | Select-String $_.Title -Quiet))
                                                {
                                                    $feeditemsSelected += $_
                                                }
                                           }

Write-Verbose "Create HTML Report"
$feeditemsSelected | sort Name | Out-Null
$html = $feeditemsSelected |?{Test-Path "$($_.Destination)"} | % {@"
     <H4><a href="$($_.Destination)">$($_.Title)</a></H4> 
     <H5>Speaker(s): $($_.creator)</H5>
     <H5>$($_.Summary)</H5>
"@}

Write-Verbose "Open HTML Report"
ConvertTo-Html -Head "<h1>My Downloaded Teched 2013 Europe Videos - $($feeditemsSelected.Count) Downloaded</h1>" -Body $html | 
    Out-File $Path\MyTeched2013EuropeContent.html
    start "$Path\MyTeched2013EuropeContent.html"
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCUtprO2kunf/YmS3KNoXYwGX
# qHugggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGdTMnV3cM/KHKmd
# 2E787QQPIQZKMA0GCSqGSIb3DQEBAQUABIIBAAFJmyqu2SD17KQVVv3x0vCuggCl
# GLXdZ8j0w+QTrikHwnclZ4L8+m4vF49t7cwQ4Ov+haUBirOwzxma5Igb/jdp/Y7m
# ZTfDQgkAGCsDV2/xWQrHxDqFYdmxKvO6YkMk+32P7hTJwfcDvq+bGNmZHoZ2vkRz
# QyzaOrqaJSsJqZGJKUXsSqyN3yiopckV7oAfHaNBvkRua7BHuiSwF0jcxsGs5b8w
# n0M3+RlQy4t6d7+rOposz0yD/RB6IJZmexbynlKbo0tImEKevoSO5JFDNdXBljwe
# bDIl5P/GleG7zAuoOM1UsEiA7rBAAbw8Bn2fA0mdLD45VtHKUkZZ7+CuoQg=
# SIG # End signature block
