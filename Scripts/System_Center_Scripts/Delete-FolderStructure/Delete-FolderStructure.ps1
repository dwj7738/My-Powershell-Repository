<#
.SYNOPSIS
	Deletes packages and folders beneath a given folder structure.
.DESCRIPTION
	Deletes packages and folders beneath a given folder structure.
.PARAMETER SiteCode
    ConfigMgr Site SiteCode
    This parameter is mandatory!
    This parameter has an alias of SC.
.PARAMETER ManagementPoint
    FQDN of a ManagementPoint in this hierarchy. 
    This parameter is mandatory!
    This parameter has an alias of MP.
.PARAMETER FolderPath
    This parameter expects the path to the folder UNDER which you want to delete ALL packages and ALL folders.
    This parameter is mandatory!
    This parameter has an alias of FP.
.EXAMPLE
	PS C:\PSScript > .\delete-folderstructure.ps1 -SiteCode PR1 -ManagementPoint CM12.do.local -FolderPath "Software\HelpDesk"

    This will use PR1 as Site Code.
    This will use CM12.do.local as Management Point.
    This will use "Software\HelpDesk" as the path to the folder under which you want to delete content. ALL content beneath the folder HelpDesk and ALL packages will be deleted. USE WITH CAUTION!!!
.INPUTS
	None.  You cannot pipe objects to this script.
.OUTPUTS
	No objects are output from this script.  This script creates a Word document.
.LINK
	http://www.david-obrien.net
.NOTES
	NAME: delete-folderstructure.ps1
	VERSION: 1.0
	AUTHOR: David O'Brien
	LASTEDIT: June 20, 2013
    Change history:
.REMARKS
	To see the examples, type: "Get-Help .\delete-folderstructure.ps1 -examples".
	For more information, type: "Get-Help .\delete-folderstructure.ps1 -detailed".
    This script will only work with Powershell 3.0.
#>



[CmdletBinding( SupportsShouldProcess = $False, ConfirmImpact = "None", DefaultParameterSetName = "" ) ]
param(
[parameter(
	Position = 1, 
	Mandatory=$true )
	] 
	[Alias("SC")]
	[ValidateNotNullOrEmpty()]
	[string]$SiteCode="",
    
    [parameter(
	Position = 2, 
	Mandatory=$true )
	] 
	[Alias("MP")]
	[ValidateNotNullOrEmpty()]
	[string]$ManagementPoint="",

    [parameter(
	Position = 3, 
	Mandatory=$true )
	] 
	[Alias("FP")]
	[ValidateNotNullOrEmpty()]
	[string]$FolderPath=""
)
<#
#Import the CM12 Powershell cmdlets
Import-Module ($env:SMS_ADMIN_UI_PATH.Substring(0,$env:SMS_ADMIN_UI_PATH.Length – 5) + '\ConfigurationManager.psd1') | Out-Null
#CM12 cmdlets need to be run from the CM12 drive
Set-Location "$($SiteCode):" | Out-Null
if (-not (Get-PSDrive -Name $SiteCode))
    {
        Write-Error "There was a problem loading the Configuration Manager powershell module and accessing the site's PSDrive."
        exit 1
    }
#>

$Packages = @()
$ChildFolders = @()
$Children = $null
$IDPath = @()
$GreatChildFolders = $null
$ChildFolders = $null
$Folders = $null

[array]$Folders = $FolderPath.Split("\")

$i = 0
foreach ($Folder in $Folders)
    {
        $FolderID = $null
        if ($i -eq 0)
            {
                $RootFolder = "0"
            }                
        $FolderID = (Get-WmiObject -Class SMS_ObjectContainerNode -Namespace root\SMS\site_$($SiteCode) -ComputerName $($ManagementPoint) -Filter "Name = '$($Folder)' and ObjectType = '2' and ParentContainerNodeID = '$($RootFolder)'").ContainerNodeID
        $RootFolder = $FolderID
        $IDPath += $FolderID
        $i++
    }

$ParentFolder = $StartFolder = (Get-WmiObject -Class SMS_ObjectContainerNode -Namespace root\SMS\site_$($SiteCode) -ComputerName $($ManagementPoint) -Filter "ContainerNodeID = '$($IDPath[-1])'").ContainerNodeID


$Children = (Get-WmiObject -Class SMS_ObjectContainerNode -Namespace root\SMS\site_$($SiteCode) -ComputerName $($ManagementPoint) -Filter "ParentContainerNodeID = '$($ParentFolder)'").ContainerNodeID
$ChildFolders += $Children

foreach ($Child in $ChildFolders)
    {
        try 
            {
                $GreatChildFolders = (Get-WmiObject -Class SMS_ObjectContainerNode -Namespace root\SMS\site_$($SiteCode) -ComputerName $($ManagementPoint) -Filter "ParentContainerNodeID = '$($Child)'").ContainerNodeID 
            }   
        catch [System.Management.Automation.PropertyNotFoundException] 
            {
                Write-Verbose "This was the last folder."
            }
        
        
        $ChildFolders += $GreatChildFolders
    }

Write-Host "Folders to be deleted: $($ChildFolders)"

foreach ($ChildFolder in $ChildFolders)
    {
        try 
            {
                $Packages += (Get-WmiObject -Class SMS_ObjectContainerItem -Namespace root\SMS\site_$($SiteCode) -ComputerName $($ManagementPoint) -Filter "ContainerNodeID = '$($ChildFolder)'").InstanceKey
            }   
        catch [System.Management.Automation.PropertyNotFoundException] 
            {
                Write-Verbose "This was the last Package."
            }
    }

Write-Host "Packages to be deleted: $($Packages)"

if ((Read-Host -Prompt "Are you sure you want to delete these folders and packages? [true]") -eq $true)
    {

        foreach ($Pkg in $Packages)
            {
                try
                    {
                        $Pkg = (Get-WmiObject -Class SMS_Package -Namespace root\sms\site_$SiteCode -Filter "PackageID = '$($Pkg)'").__PATH
                        Remove-WmiObject -Path $Pkg
                    }
                catch [System.Management.Automation.PropertyNotFoundException] 
                    {
                        Write-Verbose "This was the last Package."
                    }
            }
        foreach ($Fld in $ChildFolders)
            {
                try
                    {
                        $Fld = (Get-WmiObject -Class SMS_ObjectContainerNode -Namespace root\SMS\site_$($SiteCode) -ComputerName $($ManagementPoint) -Filter "ContainerNodeID = '$($Fld)'").__PATH
                        Remove-WmiObject -Path $Fld -ErrorAction SilentlyContinue
                    }
                catch [System.Management.Automation.PropertyNotFoundException] 
                    {
                        Write-Verbose "This was the last folder."
                    }
            }
    }
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGEYx10rb8w2pYeRvMQMMj/FR
# D6KgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKxIHZRNNOzGMmyL
# nWgbRDrgWBPaMA0GCSqGSIb3DQEBAQUABIIBAK6dytveY+chAFYisl1FgHQwxNiT
# FWmYAE6zXRpsO1s0R+Ip/n5681afmHSlHStc6RUKfSGTqmbExx9VZFwCF7c4BHj7
# BSsP66N8uSP5y5qacPzOAKNX90mD+JKJpk9sf4MJPzKhP57j0m+AwA0v+QJcHzwx
# t2ohdDIfIZfaS4ij7hjm1vBb/cjrN3PC8Jm9ARBYX+G0+h57rObzwECrXqyvj+9c
# dYXjmFnFfoQcx0g9CvS1OwrlYb2wRil+urGdn819MTyo5+VPajAry/vE8LWukl6n
# K4l2S6TdARQnC0h1KOJz9tTmnPhpUVbOSJUFJQJFsvh6FFaORNYZXsCEhCI=
# SIG # End signature block
