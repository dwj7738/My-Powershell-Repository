param
(
$CountdownYear="2015"
)

Function Draw-Number($digit,$Column)
{

$Number=New-object 'object[,]' 11,8

$Number[0,0]="******* "
$Number[0,1]="*     * "
$Number[0,2]="*     * "
$Number[0,3]="*     * "
$Number[0,4]="*     * "
$Number[0,5]="*     * "
$Number[0,6]="******* "
$Number[0,7]="        "

$Number[1,0]="      * "
$Number[1,1]="      * "
$Number[1,2]="      * "
$Number[1,3]="      * "
$Number[1,4]="      * "
$Number[1,5]="      * "
$Number[1,6]="      * "
$Number[1,7]="        "

$Number[2,0]="******* "
$Number[2,1]="      * "
$Number[2,2]="      * "
$Number[2,3]="******* "
$Number[2,4]="*       "
$Number[2,5]="*       "
$Number[2,6]="******* "
$Number[2,7]="        "

$Number[3,0]="******* "
$Number[3,1]="      * "
$Number[3,2]="      * "
$Number[3,3]="******* "
$Number[3,4]="      * "
$Number[3,5]="      * "
$Number[3,6]="******* "
$Number[3,7]="        "

$Number[4,0]="*     * "
$Number[4,1]="*     * "
$Number[4,2]="*     * "
$Number[4,3]="******* "
$Number[4,4]="      * "
$Number[4,5]="      * "
$Number[4,6]="      * "
$Number[4,7]="        "

$Number[5,0]="******* "
$Number[5,1]="*       "
$Number[5,2]="*       "
$Number[5,3]="******* "
$Number[5,4]="      * "
$Number[5,5]="      * "
$Number[5,6]="******* "
$Number[5,7]="        "

$Number[6,0]="******* "
$Number[6,1]="*       "
$Number[6,2]="*       "
$Number[6,3]="******* "
$Number[6,4]="*     * "
$Number[6,5]="*     * "
$Number[6,6]="******* "
$Number[6,7]="        "

$Number[7,0]="******* "
$Number[7,1]="      * "
$Number[7,2]="      * "
$Number[7,3]="      * "
$Number[7,4]="      * "
$Number[7,5]="      * "
$Number[7,6]="      * "
$Number[7,7]="        "

$Number[8,0]="******* "
$Number[8,1]="*     * "
$Number[8,2]="*     * "
$Number[8,3]="******* "
$Number[8,4]="*     * "
$Number[8,5]="*     * "
$Number[8,6]="******* "
$Number[8,7]="        "

$Number[9,0]="******* "
$Number[9,1]="*     * "
$Number[9,2]="*     * "
$Number[9,3]="******* "
$Number[9,4]="      * "
$Number[9,5]="      * "
$Number[9,6]="******* "
$Number[9,7]="        "

$Number[10,0]="        "
$Number[10,1]="   **   "
$Number[10,2]="   **   "
$Number[10,3]="        "
$Number[10,4]="   **   "
$Number[10,5]="   **`  "
$Number[10,6]="        "
$Number[10,7]="        "

$Adjust=($column*10)+8

$Remember=$host.ui.RawUI.CursorPosition
$Base=$Remember

$base.X=$base.X+$adjust
$Y=$base.Y

    for($a=0;$a -le 7;$a++)
    {
    $host.ui.RawUI.CursorPosition=$base
    write-host -foregroundcolor Yellow -object $number[$digit,$a] -NoNewline
    $y++
    $Base.Y=$Y
    }

$host.ui.RawUI.CursorPosition=$Remember

}

[datetime]$Countdown="01/01/$CountdownYear 00:00"

CLEAR-HOST
$size=$host.ui.RawUI.WindowSize
$size.Height=20
$size.width=75

$host.ui.rawui.WindowSize=$size

$starthere=$host.ui.RawUI.CursorPosition
do
{
$data=($Countdown-(GET-DATE))
$Days=$data.days

$host.ui.RawUI.CursorPosition=$starthere
$host.ui.RawUI.WindowTitle=(GET-DATE).tostring()

WRITE-HOST -ForegroundColor Cyan -Object "`n`n                        It is now $Days Day(s) until New Years Eve $CountdownYear and ...`n`n"
WRITE-HOST -ForegroundColor Green "              HOURS                        MINUTES                       SECONDS`n`n"

Draw-Number ($data.hours.tostring().padleft(2,"0").substring(0,1)) 0
Draw-Number ($data.hours.tostring().padleft(2,"0").substring(1,1)) 1
Draw-Number 10 2
Draw-Number ($data.minutes.tostring().padleft(2,"0").substring(0,1)) 3
Draw-Number ($data.minutes.tostring().padleft(2,"0").substring(1,1)) 4
Draw-Number 10 5
Draw-Number ($data.seconds.tostring().padleft(2,"0").substring(0,1)) 6
Draw-Number ($data.seconds.tostring().padleft(2,"0").substring(1,1)) 7

start-sleep -Seconds .75
}
until((GET-DATE) -gt $Countdown)
     s
CLEAR-HOST

do 
{
$Here=$host.ui.RawUI.CursorPosition
$here.X=30
$here.Y=10
$host.ui.RawUI.CursorPosition=$Here
WRITE-HOST -foregroundColor (GET-RANDOM ("Black","Blue","Cyan","Gray","Green","Magenta","Red","White","Yellow")) -OBJECT "H A P P Y   N E W   Y E A R   $countdownyear" -nonewline
start-sleep .75
} until ($FALSE)

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPDVTakjtkXKpRbxxNRxfQGG1
# ZXigggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJrq/TCuaIjtxOgk
# drPIUre0kHwFMA0GCSqGSIb3DQEBAQUABIIBAGszcg0+80cRlSIe4e/V/X7GQJ0j
# XY4zXjDDhJt1b2TeCPxqfXYgCPAnHSxushuASYprqa8LY6QCKK/ELViwjPKd+uCJ
# rsaK38+lrxtaj0voIA+qR97l4XbRdSLW1UHswT3Ti/bsSvPsB9XrAtI0EA6p+7EB
# oDAwLplPg+d00eLPjRpGIQYOWj7LsEcfpZxu3XSoOIHSIwAs/FEys+TYsWFLwlam
# 7QFNEfS5dvg03A18Kt1PWTEZJ1qt0JKqHtJndtRl7kvhtJwb+aJ/shPGi+ipS5O1
# DaX3p77+e3neOznLQk7jdMgBlCLF9dCxqtfuwOFUfx4KlLsglr/4bPifNB8=
# SIG # End signature block
