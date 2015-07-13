    Function Get-DiskUsage {
     
    <#
     
    .SYNOPSIS
    A tribute to the excellent Unix command DU.
     
    .DESCRIPTION
    This command will output the full path and the size of any object
    and it's subobjects. Using just the Get-DiskUsage command without
    any parameters will result in an output of the directory you are
    currently placed in and it's subfolders.
     
    .PARAMETER Path
    If desired a path can be specified with the Path parameter. In no path
    is specified $PWD will be used.
     
    .PARAMETER h
    the -h paramater is the same as -h in Unix. It will list the folders
    and subfolders in the most appropriate unit depending on the size
    (i.e. Human Readable).
     
    .PARAMETER l
    The -l paramater will add the largest file to the end of the output.
     
    .PARAMETER Sort
    Allows you to sort by Folder or Size. If none i specified the default
    of Folder will be used.
     
    .PARAMETER Depth
    Depth will allow you to specify a maximum recursion depth. A depth
    of 1 would return the immediate subfolders under the root.
     
    .PARAMETER Force
    Works the same way as Get-ChildItem -force.
     
    .PARAMETER Descending
    Works the same way as Sort-Object -descending.
     
    .LINK
    http://www.donthaveasite.nu
     
    .NOTES
    Author: Jonas Hallqvist
    Developed with Powershell v3
     
    #>
     
        [CmdletBinding(
            SupportsShouldProcess=$True
        )]
     
        param (
            [String]$Path=$PWD,
            [Switch]$h,
            [Switch]$l,
            [String]$Sort="Folder",
            [Int]$Depth,
            [Switch]$Force,
            [Switch]$Descending
        )
     
        $ErrorActionPreference = "silentlycontinue"
     
        function HumanReadable {
            param ($size)
            switch ($size) {
                {$_ -ge 1PB}{"{0:#'P'}" -f ($size / 1PB); break}
                {$_ -ge 1TB}{"{0:#'T'}" -f ($size / 1TB); break}
                {$_ -ge 1GB}{"{0:#'G'}" -f ($size / 1GB); break}
                {$_ -ge 1MB}{"{0:#'M'}" -f ($size / 1MB); break}
                {$_ -ge 1KB}{"{0:#'K'}" -f ($size / 1KB); break}
                default {"{0}" -f ($size) + "B"}
            }
        }
     
        function LargestFolder {
            if ($h) {
                $large = ($results | Sort-Object -Property Size -Descending)[0] | Format-Table @{Label="Size";Expression={HumanReadable $_.Size};Align="Right"},Folder  -AutoSize -HideTableHeaders
                Write-host "Largest Folder is:" -NoNewline
                $large
            }
            else {
                $large = ($results | Sort-Object -Property Size -Descending)[0] | Format-Table @{Label="Size";Expression={"$($_.Size)B"};Align="Right"},Folder -AutoSize -HideTableHeaders
                Write-host "Largest Folder is:" -NoNewline
                $large
            }
        }
     
        function Max-Depth {
            param(
                [String]$Path = '.',
                [String]$Filter = '*',
                [Int]$Level = 0,
                [Switch]$Force,
                [Switch]$Descending,
                [int]$i=0
            )
            $results=@()
            $root = (Resolve-Path $Path).Path
     
            if ($root -notmatch '\\$') {$root += '\'}
     
            if (Test-Path $root -PathType Container) {
     
                do {
                    [String[]]$_path += $root + "$Filter"
                    $Filter = '*\' + $Filter
                    $i++
                }
                until ($i -eq $Level)
     
                $dirs=Get-ChildItem -directory $_path -Force:$Force
       
                foreach ($dir in $dirs) {
                    $size = 0
                    $size += (gci $dir.Fullname -recurse | Measure-Object -Property Length -Sum).Sum
                    $results += New-Object psobject -Property @{Folder=$dir.fullname;Size=$size}
                }
                if ($h) {
                    $results | Sort-Object $Sort -Descending:$Descending | Format-Table @{Label="Size";Expression={HumanReadable $_.Size};Align="Right"},Folder -AutoSize
                }
                if ($l) {
                    LargestFolder
                }
                if (($h -eq $false) -and ($l -eq $false)) {
                    $results | Sort-Object $Sort -Descending:$Descending | Format-Table @{Label="Size";Expression={"$($_.Size)B"};Align="Right"},Folder -AutoSize
                }
            }
        }
     
        if ($Depth) {
            Max-Depth -Path $Path -Level $Depth -Force:$Force -Descending:$Descending
        }
     
        else {
            $results = @()
            $dirs=Get-ChildItem -directory $Path -Force:$Force -Recurse
            foreach ($dir in $dirs) {
                $size = 0
                $size += (gci $dir.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
                $results+= New-Object psobject -Property @{Folder=$dir.FullName;Size=$size}
            }
            if ($h) {
                $results | Sort-Object $Sort -Descending:$Descending | Format-Table @{Label="Size";Expression={HumanReadable $_.Size};Align="Right"},Folder -AutoSize
            }
            if ($l) {
                LargestFolder
            }
            if (($h -eq $false) -and ($l -eq $false)) {
                $results | Sort-Object $Sort -Descending:$Descending | Format-Table @{Label="Size";Expression={"$($_.Size)B"};Align="Right"},Folder -AutoSize
            }
        }
    }
     
    <#
    Copyright (c) 2013, Jonas Hallqvist
     All rights reserved.
     
    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
    Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
     
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
    THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
    GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
    #>

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKvPGDswCk8u3LcEIw/1EWn/t
# qKegggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAWwMOOj6pZ250nq
# df2RFQYjZvx+MA0GCSqGSIb3DQEBAQUABIIBAI2e6BtTOLoY1/u3cQ+uRULRhMmO
# yIKoNDXWlhlv+ZGMEnq54vPQTQ3/sYl7Q/uZGC2LXRtYZOP7WJYsMcqa5ZKeHI6l
# jYi13VsZS7ZoZIOZRuDEDND1C3a3ivgiT/ejs/ThIsNuzs3qMm8L5mo2ALT15Ofz
# SXPKuEntoXGWXk3OhwyXJxIWrC4w/iNguSNup2QHT2Xby86zbwhWHCYXdHKH7BX4
# iG6zG9A1mWpCcqJEi7BPFaLwyX0zOrV81geM/oLC7gl/ZOy0BOoZGuwf1ztGtnjx
# Lx+CtIr15MLSyOKUf5tylccn0EtqywAC4hbGN5hOvWVNjymp9FgfsW7lvWk=
# SIG # End signature block
