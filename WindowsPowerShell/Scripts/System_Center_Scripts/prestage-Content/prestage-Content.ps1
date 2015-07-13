[CmdletBinding()]
Param(
    [Parameter(ParameterSetName='Package',Position=0)]
    [switch]$Package,
    [Parameter(ParameterSetName='Package',Position=0)]
    [string]$PackageFolderName,

    [Parameter(ParameterSetName='Application',Position=0)]
    [switch]$Application,
    [Parameter(ParameterSetName='Application',Position=0)]
    [string]$ApplicationFolderName,

    [Parameter(ParameterSetName='OS',Position=0)]
    [switch]$OS,
    [Parameter(ParameterSetName='OS',Position=0)]
    [string]$OSFolderName,

    [Parameter(ParameterSetName='BootImage',Position=0)]
    [switch]$BootImage,
    [Parameter(ParameterSetName='BootImage',Position=0)]
    [string]$BootImageFolderName,

    [Parameter(ParameterSetName='DriverPackage',Position=0)]
    [switch]$DriverPackage,
    [Parameter(ParameterSetName='DriverPackage',Position=0)]
    [string]$DriverPackageFolderName,
    
    [Parameter(ParameterSetName='AllInOne')]
    [Parameter(ParameterSetName='Package')]
    [Parameter(ParameterSetName='Application')]
    [Parameter(ParameterSetName='OS')]
    [Parameter(ParameterSetName='BootImage')]
    [Parameter(ParameterSetName='DriverPackage')]
    [switch]$AllInOneFile,

    [Parameter(ParameterSetName='AllInOne')]
    [Parameter(ParameterSetName='Package')]
    [Parameter(ParameterSetName='Application')]
    [Parameter(ParameterSetName='OS')]
    [Parameter(ParameterSetName='BootImage')]
    [Parameter(ParameterSetName='DriverPackage')]
    [string]$ExportFileName,

    [Parameter(Position=1,
        Mandatory=$True,
        ValueFromPipeline=$True)]
    [string]$SiteCode,

    [Parameter(Position=2,
        Mandatory=$True,
        ValueFromPipeline=$True)]
    [string]$ExportFolder,
  
    [Parameter(Position=3,
        Mandatory=$True,
        ValueFromPipeline=$True)]
    [string]$SourceDistributionPoint

 )


if (-not [Environment]::Is64BitProcess)
    {

        # this script needs to run in a x86 shell, but we need to access the x64 reg-hive to get the AdminConsole install directory
        $Hive = "LocalMachine"
        $ServerName = "localhost"
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]$Hive,$ServerName,[Microsoft.Win32.RegistryView]::Registry64)

        $Subkeys = $reg.OpenSubKey('SOFTWARE\Microsoft\SMS\Setup\')

        $AdminConsoleDirectory = $Subkeys.GetValue('UI Installation Directory')

        #Import the CM12 Powershell cmdlets
        Import-Module "$($AdminConsoleDirectory)\bin\ConfigurationManager.psd1"
        #CM12 cmdlets need to be run from the CM12 drive
        Set-Location "$($SiteCode):"
     
        if ($Package)
            {
                $FolderID = (gwmi -Class SMS_ObjectContainerNode -Namespace root\sms\site_$SiteCode | Where-Object {($_.Name -eq "$($PackageFolderName)") -and ($_.ObjectType -eq "2")}).ContainerNodeID
                $PackageIDs = (gwmi -Class SMS_ObjectContainerItem -Namespace root\sms\site_$SiteCode | Where-Object {$_.ContainerNodeID -eq "$($FolderID)"}).InstanceKey

                if ($AllInOneFile)
                    {
                        Publish-CMPrestageContent -PackageId $PackageIDs -FileName $(Join-Path $ExportFolder "$ExportFileName.pkgx") -DistributionPointName $SourceDistributionPoint | Out-Null
                    }
                
                else 
                    {
                        foreach ($SinglePackageID in $PackageIDs)
                            {
                              $PackageName = (gwmi -Class SMS_Package -Namespace root\sms\site_$SiteCode | Where-Object {$_.PackageID -eq "$($SinglePackageID)"}).Name
              
                              Publish-CMPrestageContent -PackageId $SinglePackageID -FileName $(Join-Path $ExportFolder "$PackageName.pkgx") -DistributionPointName $SourceDistributionPoint | Out-Null
                            }
                    }
            }
        
        if ($Application)
            {
                $FolderID = (gwmi -Class SMS_ObjectContainerNode -Namespace root\sms\site_$SiteCode | Where-Object {($_.Name -eq "$($ApplicationFolderName)") -and ($_.ObjectType -eq "6000")}).ContainerNodeID
                $ApplicationIDs = (gwmi -Class SMS_ObjectContainerItem -Namespace root\sms\site_$SiteCode | Where-Object {$_.ContainerNodeID -eq "$($FolderID)"}).InstanceKey
                
                if ($AllInOneFile)
                    {
                        foreach ($AppID in $ApplicationIDs)
                            {
                                $IDs = @()
                                $ApplicationID = (Get-CMApplication | Where-Object {$_.ModelName -eq "$($AppID)"}).ModelID
                                $IDs += $ApplicationID
                            }
                        Publish-CMPrestageContent -ApplicationId $IDs -FileName $(Join-Path $ExportFolder "$ExportFileName.pkgx") -DistributionPointName $SourceDistributionPoint | Out-Null
                    }
                else 
                    {
                       
                        foreach ($SingleApplicationID in $ApplicationIDs)
                            {
                        
                                $ApplicationID = (Get-CMApplication | Where-Object {$_.ModelName -eq "$($SingleApplicationID)"}).ModelID
                                $ApplicationName = (Get-CMApplication | Where-Object {$_.ModelName -eq "$($SingleApplicationID)"}).LocalizedDisplayName
                                              
                                Publish-CMPrestageContent -ApplicationId $ApplicationID -FileName $(Join-Path $ExportFolder "$ApplicationName.pkgx") -DistributionPointName $SourceDistributionPoint | Out-Null
                            }
                    }
            }
        
        if ($OS)
            {
                $FolderID = (gwmi -Class SMS_ObjectContainerNode -Namespace root\sms\site_$SiteCode | Where-Object {($_.Name -eq "$($OSFolderName)") -and ($_.ObjectType -eq "18")}).ContainerNodeID
                $OSIDs = (gwmi -Class SMS_ObjectContainerItem -Namespace root\sms\site_$SiteCode | Where-Object {$_.ContainerNodeID -eq "$($FolderID)"}).InstanceKey

                if ($AllInOneFile)
                    {
                        Publish-CMPrestageContent -OperatingSystemImageId $OSIDs -FileName $(Join-Path $ExportFolder "$ExportFileName.pkgx") -DistributionPointName $SourceDistributionPoint | Out-Null
                    }
                else 
                    {

                        foreach ($SingleOSID in $OSIDs)
                            {
                                $OSName = (gwmi -Class SMS_ImagePackage -Namespace root\sms\site_$SiteCode | Where-Object {$_.PackageID -eq "$($SingleOSID)"}).Name
                                                                     
                                Publish-CMPrestageContent -OperatingSystemImageId $SingleOSID -FileName $(Join-Path $ExportFolder "$OSName.pkgx") -DistributionPointName $SourceDistributionPoint | Out-Null
                            }
                    }
            }
        
        if ($BootImage)
            {
                
                $FolderID = (gwmi -Class SMS_ObjectContainerNode -Namespace root\sms\site_$SiteCode | Where-Object {($_.Name -eq "$($BootImageFolderName)") -and ($_.ObjectType -eq "19")}).ContainerNodeID
                $BootImageIDs = (gwmi -Class SMS_ObjectContainerItem -Namespace root\sms\site_$SiteCode | Where-Object {$_.ContainerNodeID -eq "$($FolderID)"}).InstanceKey

                if ($AllInOneFile)
                    {
                        Publish-CMPrestageContent -BootImageId $BootImageIDs -FileName $(Join-Path $ExportFolder "$ExportFileName.pkgx") -DistributionPointName $SourceDistributionPoint | Out-Null
                    }
                else 
                    {

                        foreach ($SingleBootImageID in $BootImageIDs)
                            {
                                $BootImageName = (gwmi -Class SMS_BootImagePackage -Namespace root\sms\site_$SiteCode | Where-Object {$_.PackageID -eq "$($SingleBootImageID)"}).Name
                                                                     
                                Publish-CMPrestageContent -BootImageId $SingleBootImageID -FileName $(Join-Path $ExportFolder "$BootImageName.pkgx") -DistributionPointName $SourceDistributionPoint | Out-Null
                            }
                    }
            }
        
        if ($DriverPackage)
            {
                $FolderID = (gwmi -Class SMS_ObjectContainerNode -Namespace root\sms\site_$SiteCode | Where-Object {($_.Name -eq "$($DriverPackageFolderName)") -and ($_.ObjectType -eq "23")}).ContainerNodeID
                $DriverPackageIDs = (gwmi -Class SMS_ObjectContainerItem -Namespace root\sms\site_$SiteCode | Where-Object {$_.ContainerNodeID -eq "$($FolderID)"}).InstanceKey
                
                if ($AllInOneFile)
                    {
                        Publish-CMPrestageContent -DriverPackageID $DriverPackageIDs -FileName $(Join-Path $ExportFolder "$ExportFileName.pkgx") -DistributionPointName $SourceDistributionPoint | Out-Null
                    }
                else 
                    {
                        foreach ($SingleDriverPackageID in $DriverPackageIDs)
                        {
                            $DriverPackageName = (gwmi -Class SMS_DriverPackage -Namespace root\sms\site_$SiteCode | Where-Object {$_.PackageID -eq "$($SingleDriverpackageID)"}).Name
                                                                     
                            Publish-CMPrestageContent -DriverPackageID $SingleDriverPackageID -FileName $(Join-Path $ExportFolder "$DriverPackageName.pkgx") -DistributionPointName $SourceDistributionPoint | Out-Null
                        }
                    }
            }

    }
else
    {
        Write-Error "This Script needs to be executed in a 32-bit Powershell"
        exit 1
    }
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUY7afibEUIfykdRvo3Hk8u8Kj
# A0OgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMhil+zy3bcQUpY3
# NFGgMsZLNKZPMA0GCSqGSIb3DQEBAQUABIIBALOsX6YBIdOO8BFbqH5WW4By6+iN
# ltEjbi4EhW8sBjivNdLu+pUKNzbAsqBaeMNQ/KB9Sisjhu5jHuMezB/T/Xmjrc1s
# abHXiy4fNUIqQdPgzGgMBVTx8k1Do34CHlqrNDrD2HwgfguU/AubLFfMy2sdzk6Q
# 6QV1j4mNrtl3MR5Th24VMnTYzi1+evKA8PkLoIosexGJ1lor0a6vcRtH+lzj1KUm
# aeGIwp5qZPI8xliHPMio2yvCAv5rtQUvSHkUAkEXhg+z7H6gVt11B+8xZ2alz4l2
# PfwuyHMpa6/Ckf+4EXV4gHz4LYhHXsN3CqzGp0IV0Me/rVlxA+baS3gpZgU=
# SIG # End signature block
