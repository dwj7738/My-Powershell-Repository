#requires -version 2.0

# -----------------------------------------------------------------------------
# Script: New-CommentHelp.ps1
# Version: 1.0
# Author: Jeffery Hicks
#    http://jdhitsolutions.com/blog
#    http://twitter.com/JeffHicks
# Date: 3/28/2011
# Keywords: ISE, Help, Read-Host
# Comments:
#
# "Those who forget to script are doomed to repeat their work."
#
#  ****************************************************************
#  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
#  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
#  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
#  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
#  ****************************************************************
# -----------------------------------------------------------------------------

Function New-CommentHelp {

Param()

#define beginning of comment based string

$comment=@"
<#
.SYNOPSIS
{0}
.DESCRIPTION
{1}

"@

#prompt for command name (default to script name)
$name=Read-Host "What is the name of your function or command?"

#prompt for synopsis
$Synopsis=Read-Host "Enter a synopsis"
#prompt for description
$description=Read-Host "Enter a description. You can expand and edit later"

#Create comment based help string
$help=$comment -f $synopsis,$description

#test if command is loaded and if so get parameters
#ignore common: 
$common="VERBOSE|DEBUG|ERRORACTION|WARNINGACTION|ERRORVARIABLE|WARNINGVARIABLE|OUTVARIABLE|OUTBUFFER"
Try 
{
    $command=get-command -Name $name -ErrorAction Stop
    $params=$command.parameters.keys | where {$_ -notmatch $common} 
}
Catch
{
    #otherwise prompt
    $scriptname=Read-Host "If your command is a script file, enter the full file name with extension. Otherwise leave blank"
    if ($scriptname)
    {
        Try 
        {
            $command=get-command -Name $scriptname -ErrorAction Stop
            $params=$command.parameters.keys | where {$_ -notmatch $common} 
        }
        Catch
        {
            Write-Warning "Failed to find $scriptname"
            Return 
        }

    } #if $scriptname
    else
    {
        #prompt for a comma separated list of parameter names
        $EnterParams=Read-Host "Enter a comma separated list of parameter names"
        $Params=$EnterParams.Split(",")
    }
}

#get parameters from help or prompt for comma separated list
 Foreach ($param in $params) {
    #prompt for a description for each parameter
    $paramDesc=Read-host "Enter a short description for parameter $($Param.ToUpper())"
    #define a new line
#this must be left justified to avoid a parsing error
$paramHelp=@"
.PARAMETER $Param
$paramDesc

"@
       
        
    #append the parameter to the help comment
    $help+=$paramHelp
    } #foreach
    
Do
{
    #prompt for an example command
    $example=Read-Host "Enter an example command. You do not need to include a prompt. Leave blank to continue"
    if ($example)
    {
    
    #prompt for an example description
    $exampleDesc=Read-Host "Enter a brief description of this example"
    
#this must be left justified to avoid a parsing error    
$exHelp=@"
.EXAMPLE
PS C:\> $example
$exampleDesc

"@    
    
    #add the example to the help comment
    $help+=$exHelp
    } #if $example
    
} While ($example)


#Prompt for version #
$version=Read-Host "Enter a version number"

#Prompt for date
$resp=Read-Host "Enter a last updated date or press Enter for the current date."
if ($resp)
{
    $verDate=$resp
}
else
{
    #use current date
    $verDate=(Get-Date).ToShortDateString()
}

#construct a Notes section
$NoteHere=@"
.NOTES
NAME        :  {0}
VERSION     :  {1}   
LAST UPDATED:  {2}
AUTHOR      :  {3}\{4}

"@

#insert the values
$Notes=$NoteHere -f $Name,$version,$verDate,$env:userdomain,$env:username

#add the section to help
$help+=$Notes

#prompt for URL Link
$url=Read-Host "Enter a URL link. This is optional"
if ($url)
{
$urlLink=@"
.LINK
$url

"@

#add the section to help
$help+=$urlLink
}

#prompt for comma separated list of links
$links=Read-Host "Enter a comma separated list of Link references or leave blank for none"
if ($links)
{
#define a here string
$linkHelp=@"
.LINK

"@

#add each link
Foreach ($link in $links.Split(",")) {
    #insert the link and a new line return
    $linkHelp+="$link `n"
}
#add the section to help
$help+=$linkHelp

}

#Inputs
$inputHelp=@"
.INPUTS
{0}

"@

$Inputs=Read-Host "Enter a description for any inputs. Leave blank for NONE."
if ($inputs)
{
    #insert the input value and append to the help comment
    $help+=($inputHelp -f $inputs)    
}
else
{
   #use None as the value and insert into the help comment
   $help+=($inputHelp -f "None")    
}

#outputs
$outputHelp=@"
.OUTPUTS
{0}

"@
$Outputs=Read-Host "Enter a description for any outputs. Leave blank for NONE."
if ($Outputs)
{
    #insert the output value and append to the help comment
    $help+=($outputHelp -f $Outputs)    
}
else
{
   #use None as the value and insert into the help comment
   $help+=($outputHelp -f "None")    
}

#close the help comment
$help+="#>"

#if ISE insert into current file
if ($psise)
{
    $psise.CurrentFile.Editor.InsertText($help) | Out-Null
}
else
{
    #else write to the pipeline
    $help
}

} #end function
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPlugePPcF3WJamn3NuRKsujc
# /vWgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFArtPWSH3rsOKU9L
# a+E+eAgeCoSZMA0GCSqGSIb3DQEBAQUABIIBAIIw/gDPbznZDE5sbWHgGmwoIiZJ
# Vr4e68e6T612hjPROOcjG0XF7O98HNFC8/dyyoK1zv85GL7NaYOSz21RgRP8EMEM
# JHNsYOVj0PGSi6ZcpBFuw5v7ZPeVKvu9eODystYDaFjh3xSLmHvLLI4SchHEftpu
# TdG0T1Gn9r7Gv8Z7adCHtUnh/Kh6zjbF9J34sh0KSPFd1nA+XuYCITSg89gCJ/Qn
# AZ+6X+sVFfiL/F8RSDUHURbFl3ifgJNBcrTuF1tUM3e0JX/L61OkSygNGtU5isfl
# f3mGIVl3qfs4kYI2W0o1xCg428ZNWxz86kITdN0Ktu0qBEhvSCXOYWnKK8A=
# SIG # End signature block
