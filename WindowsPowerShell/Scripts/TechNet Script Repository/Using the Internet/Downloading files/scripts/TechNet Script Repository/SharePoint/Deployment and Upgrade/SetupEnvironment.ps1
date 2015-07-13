<#
.SYNOPSIS 
       This script sets system variables specific to each installation farm  
.DESCRIPTION 
       This script sets system variables specific to each installation farm  
       This script is used in conjunction with the SharePointServerSetup script and together they 
       help create a mechanism for rapidly developing custom search solutions. Also, this script 
       can be autodownloaded with many other search related powershell scripts by running the 
       download script.

.LINK 
This Script - http://gallery.technet.microsoft.com/CrawlAllContentSources-8b722858
Download Script - http://gallery.technet.microsoft.com/DownloadScriptsv2-cfbf4342
.NOTES 
  File Name : SetupEnvironment.ps1 
  Author    : Brent Groom 
#>

param([Switch]$StandaloneServer)

function IdentifyCurrentInstallation()
{
    # Environment to server mapping
    $arrStandaloneServer = "DEMO2010A"
    $arrDevDave = "DAVESERVER1", "DAVESERVER2"
    $arrOAT1 = "SPCENTRALADMINSVR"
    $arrDEVVMSET1 = "FASTADMINSVR"
    $arrDEVVMSET2 = "FASTDOCPROCSVR"
    $arrPROD = "FASTDOCPROCSVR"

    $DEPLOY_CURRENT_INSTALLATION = "UNKOWN"
   
    if($arrDevDave -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "DEVDAVE"
    }
    elseif($arrOAT -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "OAT"
    }
    elseif($arrDEVVMSET1 -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "DEVVMSET1"
    }
    elseif($arrDEVVMSET2 -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "DEVVMSET2"
    }
    elseif($arrPROD -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "PROD"
    }
    elseif($arrStandaloneServer -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "STANDALONESERVER"
    } 
    elseif($StandaloneServer)
    {
        $DEPLOY_CURRENT_INSTALLATION = "STANDALONESERVER"
    }



    # set environment variable so it is persistent on the machine
    $output = setx DEPLOY_CURRENT_INSTALLATION $DEPLOY_CURRENT_INSTALLATION /M
    # set an environment variable for the local command window
    $env:DEPLOY_CURRENT_INSTALLATION = $DEPLOY_CURRENT_INSTALLATION
    # Display that the environment variable is set
    "Set Environment variable DEPLOY_CURRENT_INSTALLATION to $($env:DEPLOY_CURRENT_INSTALLATION) "
    

}

# This function reads a file, replaces a specific set of environment variables, and writes the changed file
function ReplaceVariablesInFiles()
{
    $fileToProcess = ".\$env:configurationDirectory\SharePoint\ContentSources.xml"
    # TODO if there isn't a backup, make a backup of the original file 
    $fileContents = get-content $fileToProcess
    $fileContents = $fileContents -replace '\$\(\$env:computername\)', "$($env:computername)"
    $fileContents | Out-File $fileToProcess

}


function IdentifyRoles()
{
    # machine to role mapping
    #
    # Valid Roles: ALL, FASTALL, SP, FASTADMIN, FASTDOCPROC 

    $arrSP = "SPCENTRALADMINSVR","DEMO2010A"
    $arrFASTADMIN = "FASTADMINSVR","DEMO2010A"
    $arrFASTDOCPROC = "FASTDOCPROCSVR","DEMO2010A"


    # This is the array of roles for the current server
    # To translate this into a powershell array use: $DEPLOY_RULES = iex $ENV:DEPLOY_ROLES 
    $arrROLES = '"ArraryOfRolesForThisServer"'
        
    if($arrSP -contains $env:computername)
    {
        $arrROLES += ',"SP"'
    }
    if($arrFASTADMIN -contains $env:computername)
    {
        $arrROLES += ',"FASTADMIN"'
    }
    if($arrFASTDOCPROC -contains $env:computername)
    {
        $arrROLES += ',"FASTDOCPROC"'
    }
    # set environment variable so it is persistent on the machine
    $output = setx DEPLOY_ROLES $arrROLES /M
    # set an environment variable for the local command window
    $env:DEPLOY_ROLES = $arrROLES
    # Display that the environment variable is set
    "Set Environment variable DEPLOY_ROLES to $($env:DEPLOY_ROLES) "
    $DEPLOY_ROLES = iex $ENV:DEPLOY_ROLES

}

#couldn't get this to work...
function setenvironmentvariable([string]$name, [string]$value)
{
    # set a machine environment variable for all users
    setx $name $value /M
    # set an environment variable for the local command window
    #???$env:"$name"=$value
    #$env:$name
}

function main() 
{
    IdentifyRoles
    IdentifyCurrentInstallation
    $installEnv = ""
    if($ENV:DEPLOY_CURRENT_INSTALLATION -eq "STANDALONESERVER")
    {
        # set a machine environment variable for all users
        $output = setx FASTSEARCHSITENAME "http://$env:computername" /M
        # set an environment variable for the local command window
        $env:FASTSEARCHSITENAME = "http://$env:computername"
        "Set Environment variable FASTSEARCHSITENAME to $($env:FASTSEARCHSITENAME) "

        #--------------------------------------------------------------------
        $newvarname = "FS4SPINSTALLENV"
        $newvarval = "$($env:computername)"
        # set environment variable so it is persistent on the machine
        $output = setx FS4SPINSTALLENV "$env:computername" /M
        # set an environment variable for the local command window
        $env:FS4SPINSTALLENV = "$env:computername"
        # Display that the environment variable is set
        "Set Environment variable FS4SPINSTALLENV to $($env:FS4SPINSTALLENV) "

        #--------------------------------------------------------------------
        # set environment variable so it is persistent on the machine
        $output = setx FASTContentSSA "FASTContent" /M
        # set an environment variable for the local command window
        $env:FASTContentSSA = "FASTContent"
        # Display that the environment variable is set
        "Set Environment variable FASTContentSSA to $($env:FASTContentSSA) "

        #------------- FAST Search Center -------------------------------------------
        # set environment variable so it is persistent on the machine
        $output = setx FASTSearchCenter "http://intranet.contoso.com/search" /M
        # set an environment variable for the local command window
        $env:FASTSearchCenter = "http://intranet.contoso.com/search"
        # Display that the environment variable is set
        "Set Environment variable FASTSearchCenter to $($env:FASTSearchCenter) "

        #------------- Configuration Directory --------------------------------------
        # set environment variable so it is persistent on the machine
        $output = setx ConfigurationDirectory "DefaultConfig" /M
        # set an environment variable for the local command window
        $env:ConfigurationDirectory = "DefaultConfig"
        # Display that the environment variable is set
        "Set Environment variable ConfigurationDirectory to $($env:ConfigurationDirectory) "

        #------------- Configuration Directory --------------------------------------
        # set environment variable so it is persistent on the machine
        $output = setx ServerRole "ALL" /M
        # set an environment variable for the local command window
        $env:ServerRole = "ALL"
        # Display that the environment variable is set
        "Set Environment variable ServerRole to $($env:ServerRole) "
                

    }
    elseif($ENV:DEPLOY_CURRENT_INSTALLATION -eq "DEVSCOTT")
    {
    }
    elseif($ENV:DEPLOY_CURRENT_INSTALLATION -eq "OAT")
    {
    }
    elseif($ENV:DEPLOY_CURRENT_INSTALLATION -eq "DEVVMSET1")
    {
    }
    elseif($ENV:DEPLOY_CURRENT_INSTALLATION -eq "DEVVMSET2")
    {
    }
    elseif($ENV:DEPLOY_CURRENT_INSTALLATION -eq "PROD")
    {
    }
        else
    {
        " You must choose an environment to setup"
    }

        # Replace environment variables within configuration files so they are specific to the current farm

        ReplaceVariablesInFiles
}

main




# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUIJYNV3fYM+IqczEt+OmJpRNp
# P2OgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDAHM30pJBcBFrpy
# xDN1MotX8AckMA0GCSqGSIb3DQEBAQUABIIBAKJTpMqvAjLCBHpF/GaGaTUm4ZNN
# rHoB77B9ePfCFSlZMwfP+CVgtLQEPNUMVAUkGaSc8Vkc2xs+6Ji8q8uGLDNUqakq
# eYOKcuCq7XqGP4owEHTR24JOMYGwhITF5McW1eixXbt1X9BPwqa5nPSTkIBRoY2U
# j6EMk0snQTqcck2hL5nl/Zo+MaX+oz8CZksjAfAF4LYRwnusnPb6dfvH47uR/nRk
# /Lr7jSOuwKZIXzFL+5fqNo8IgW7wbjaCAw/mwqD2Lqet7wBKBEYVrq7/eFX9kLkB
# 47hON9DHZOUoUjOrLjv23BxR+Gcxpq8jAgp6KjlA6+zpNByRuVLZ54GEoMI=
# SIG # End signature block
