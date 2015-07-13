<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   Version 1.2
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
Param( 
[parameter(mandatory=$False,HelpMessage='Name of test file')] 
[ValidateLength(2,30)] 
$TestFileName = "test.dat",

[parameter(mandatory=$False,HelpMessage='Test file size in GB')] 
[ValidateSet('1','5','10','50','100','500','1000')] 
$TestFileSizeInGB = 1,

[parameter(mandatory=$False,HelpMessage='Path to test folder')] 
[ValidateLength(3,254)] 
$TestFilepath = 'C:\Test',

[parameter(mandatory=$True,HelpMessage='Test mode, use Get-SmallIO for IOPS and Get-LargeIO for MB/s ')] 
[ValidateSet('Get-SmallIO','Get-LargeIO')] 
$TestMode,

[parameter(mandatory=$False,HelpMessage='Fast test mode or standard')] 
[ValidateSet('True','False')] 
$FastMode = 'True',

[parameter(mandatory=$False,HelpMessage='Remove existing test file')] 
[ValidateSet('True','False')] 
$RemoveTestFile='False',

[parameter(mandatory=$False,HelpMessage='Remove existing test file')] 
[ValidateSet('Out-GridView','Format-Table')] 
$OutputFormat='Out-GridView'
)
Function New-TestFile{
$Folder = New-Item -Path $TestFilePath -ItemType Directory -Force -ErrorAction SilentlyContinue
$TestFileAndPath = "$TestFilePath\$TestFileName"
Write-Host "Checking for $TestFileAndPath"
$FileExist = Test-Path $TestFileAndPath
if ($FileExist -eq $True)
{
    if ($RemoveTestFile -EQ 'True')
    {
        Remove-Item -Path $TestFileAndPath -Force
    }
    else
    {
        Write-Host 'File Exists, break'
        Break
    }
}
Write-Host 'Creating test file using fsutil.exe...'
& cmd.exe /c FSUTIL.EXE file createnew $TestFileAndPath ($TestFileSizeInGB*1024*1024*1024)
& cmd.exe /c FSUTIL.EXE file setvaliddata $TestFileAndPath ($TestFileSizeInGB*1024*1024*1024)
}
Function Remove-TestFile{
$TestFileAndPath = "$TestFilePath\$TestFileName"
Write-Host "Checking for $TestFileAndPath"
$FileExist = Test-Path $TestFileAndPath
if ($FileExist -eq $True)
{
    Write-Host 'File Exists, deleting'
    Remove-Item -Path $TestFileAndPath -Force -Verbose
}
}
Function Get-SmallIO{
Write-Host 'Initialize for SmallIO...'
8..64 | % {
    $KBytes = '8'
    $Type = 'random'
    $b = "-b$KBytes";
    $f = "-f$Type";
    $o = "-o $_";  
    $Result = & $RunningFromFolder\sqlio.exe $Duration -kR $f $b $o -t4 -LS -BN "$TestFilePath\$TestFileName"
    Start-Sleep -Seconds 5 -Verbose
    $iops = $Result.Split("`n")[10].Split(':')[1].Trim() 
    $mbs = $Result.Split("`n")[11].Split(':')[1].Trim() 
    $latency = $Result.Split("`n")[14].Split(':')[1].Trim()
    $SeqRnd = $Result.Split("`n")[14].Split(':')[1].Trim()
    New-object psobject -property @{
        Type = $($Type)
        SizeIOKBytes = $($KBytes)
        OutStandingIOs = $($_)
        IOPS = $($iops)
        MBSec = $($mbs)
        LatencyMS = $($latency)
        Target = $("$TestFilePath\$TestFileName")
        }
    }
}
Function Get-LargeIO{
$KBytes = '512'
$Type = 'sequential'
Write-Host 'Initialize for LargeIO...'
Write-Host "Reading $KBytes Bytes in $Type mode using $TestFilePath\$TestFileName as target"
1..32 | % {
    $b = "-b$KBytes";
    $f = "-f$Type";
    $o = "-o $_";  
    $Result = & $RunningFromFolder\sqlio.exe $Duration -kR $f $b $o -t1 -LS -BN "$TestFilePath\$TestFileName"
    Start-Sleep -Seconds 5 -Verbose
    $iops = $Result.Split("`n")[10].Split(':')[1].Trim() 
    $mbs = $Result.Split("`n")[11].Split(':')[1].Trim() 
    $latency = $Result.Split("`n")[14].Split(':')[1].Trim()
    $SeqRnd = $Result.Split("`n")[14].Split(':')[1].Trim()
    New-object psobject -property @{
        Type = $($Type)
        SizeIOKBytes = $($KBytes)
        OutStandingIOs = $($_)
        IOPS = $($iops)
        MBSec = $($mbs)
        LatencyMS = $($latency)
        Target = $("$TestFilePath\$TestFileName")
        }
    }
}

#Checking for fast mode
if ($FastMode -lt $True){$Duration = '-s60'}else{$Duration = '-s10'}

#Setting script location to find the exe's
$RunningFromFolder = $MyInvocation.MyCommand.Path | Split-Path -Parent 
Write-Host “Running this from $RunningFromFolder”

#Main
. New-TestFile
switch ($OutputFormat){
    'Out-GridView' {
    . $TestMode | Select-Object MBSec,IOPS,SizeIOKBytes,LatencyMS,OutStandingIOs,Type,Target | Out-GridView
    }
    'Format-Table' {
    . $TestMode | Select-Object MBSec,IOPS,SizeIOKBytes,LatencyMS,OutStandingIOs,Type,Target | Format-Table
    }
    Default {}
}
. Remove-TestFile

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnZrKtIfaQloZEkWZ77Gx58s1
# ZO+gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFOn+VuncFElRVw86
# pzirvo6X4r3dMA0GCSqGSIb3DQEBAQUABIIBALA6sVplFwwkigFSxuGgxTj0+cl4
# IXTmQlaXgKXVYspCr7HXSU4UEhv8czWE+Q3r+5Z2vz/fvYxIVWhJvjKBpz2mhMun
# NmeU7ppiVeKiJXKa494DZzN6ogyP6DiFl6qwlvUX+7U95GLdYnbhAz3/m+1B6AKH
# xnF5c1L1DqF22xOcEUiFrKegRLDOZqk/qRXzy1QgkTWULTt1nLKuC9PJCPiWBdS3
# oFvcqmk7l2qb/oRV316p0zh6t1rWwnlU/YkOpPgXyCiIatmFWCWtEPHFR2dRvoBy
# cwGCm2aeNcelsAFe6Ov2DL5P9IUMoKHIQ+LuM5OSROGd+zvPsK9c/A9+dgE=
# SIG # End signature block
