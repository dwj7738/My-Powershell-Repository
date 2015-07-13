
  <#
            .AUTHORS
            RezSupport
            David Johnson (ve3ofa)

            .VERSION
            1.01

            .FILENAME
          Save as "Check-IllegalCharacters.ps1"
           
           .SYNOPSIS 
          Checks and Optionally Fixes Files with Illegal Characters
          or FilePaths > 127 Characters

           .DESCRIPTION
          The Check-IllegalCharacters.ps1 script checks the path given
           for files with illegal characters and filelenghts greater than 
           127 characters for input to Onedrive
              
           .PARAMETER Path
           Specifies the path to the Root Directory to Search

           .PARAMETER -Fix
           Will Fix files with Illegal Filenames

           .PARAMETER -Verbose
           Will Give Verbose Output 
           
           .INPUTS
           None. You cannot pipe objects to Check-IllegalCharacters.ps1.

           .OUTPUTS
           None. Check-IllegalCharacters.ps1 does not generate any output.

           .EXAMPLE
           C:\PS> .\Check-IllegalCharacters.ps1 -path c:\

           .EXAMPLE
           C:\PS> .\Check-IllegalCharacters.ps1 -path C:\Data\ -Fix

           .EXAMPLE
           C:\PS> .\Check-IllegalCharacters.ps1 -path C:\Data\ - Verbose
           #>


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
        [string]$Path,
        [Parameter(Mandatory=$False)]
        [switch] $Fix
        )       
    if (test-path $path) {
    Write-Host Checking files in $Path, please wait...
    #Get all files and folders under the path specified
    $items = Get-ChildItem -Path $Path -Recurse
    foreach ($item in $items)
    {
        #Check if the item is a file or a folder
        if ($item.PSIsContainer) { $type = "Folder" }
        else { $type = "File" }
       
        #Report item has been found if verbose mode is selected
        if ($Verbose) { Write-Host Found a $type called $item.FullName }
       
        #Check if item name is 128 characters or more in length
        if ($item.Name.Length -gt 127)
        {
            Write-Host $type $item.Name is 128 characters or over and will need to be truncated -ForegroundColor Red
        }
        else
        {
            #Got this from http://powershell.com/cs/blogs/tips/archive/2011/05/20/finding-multiple-regex-matches.aspx
            $illegalChars = '[&{}~#%]'
            filter Matches($illegalChars)
            {
                $item.Name | Select-String -AllMatches $illegalChars |
                Select-Object -ExpandProperty Matches
                Select-Object -ExpandProperty Values
            }
           
            #Replace illegal characters with legal characters where found
            $newFileName = $item.Name
            Matches $illegalChars | ForEach-Object {
                Write-Host $type $item.FullName has the illegal character $_.Value -ForegroundColor Red
                #These characters may be used on the file system but not SharePoint
                if ($_.Value -match "&") { $newFileName = ($newFileName -replace "&", "and") }
                if ($_.Value -match "{") { $newFileName = ($newFileName -replace "{", "(") }
                if ($_.Value -match "}") { $newFileName = ($newFileName -replace "}", ")") }
                if ($_.Value -match "~") { $newFileName = ($newFileName -replace "~", "-") }
                if ($_.Value -match "#") { $newFileName = ($newFileName -replace "#", "") }
                if ($_.Value -match "%") { $newFileName = ($newFileName -replace "%", "") }
            }
           
            #Check for start, end and double periods
            if ($newFileName.StartsWith(".")) { Write-Host $type $item.FullName starts with a period -ForegroundColor red }
            while ($newFileName.StartsWith(".")) { $newFileName = $newFileName.TrimStart(".") }
            if ($newFileName.EndsWith(".")) { Write-Host $type $item.FullName ends with a period -ForegroundColor Red }
            while ($newFileName.EndsWith("."))   { $newFileName = $newFileName.TrimEnd(".") }
            if ($newFileName.Contains("..")) { Write-Host $type $item.FullName contains double periods -ForegroundColor red }
            while ($newFileName.Contains(".."))  { $newFileName = $newFileName.Replace("..", ".") }
           
            #Fix file and folder names if found and the Fix switch is specified
            if (($newFileName -ne $item.Name) -and ($Fix))
            {
                Rename-Item $item.FullName -NewName ($newFileName)
                Write-Host $type $item.Name has been changed to $newFileName -ForegroundColor Blue
            }
        }
    }
 }
 else {
 Write-host("Path " + $path + " Does Not Exist")
 }
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUP4Chs1Fb2XxmcAyA6UEi8rvt
# /xGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGgbs9EWp7NO+aFG
# mhxtwHAWf+WAMA0GCSqGSIb3DQEBAQUABIIBALe0kGB/GPbwfsvuUToffqfkIazu
# 1bKzXnknhWlYGrmrubhRYAWbmoIh6xnQP16aNYVg/dMk5RuWwg2+jV9w4mGf3GGz
# ztjHKH9A8/DzWjlAonSAXZ6EwmFGROf68BbgtYdDcdp0kAVHu2rYihS+Ia2os9r1
# MJ9m/ui/l/pUwXDQbhZirDh1wWk3cVOjZHqfS3C0w2ORaYRTiu0vawD/2u3jlt7N
# KlbyYwzUEB0VVqjIfGMdRTitm/PELYsfGDaI/nx5eUYv5jTqmFBqNFzeeBCHJFuW
# r5yS96GymJwXh3kVL0iDnLCQNiFzaBMDE/J5lp4OBEFj7++tVjnTFi4ZWrc=
# SIG # End signature block
