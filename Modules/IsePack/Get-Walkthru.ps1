# Some Demo Text
# Some More Demo Text
#.Audio MyAudioFile
#.Video MyVideoFile
#.Question "What Color is the Sky?"
#.Answer {$input -like "*Blue*" }
#.Hint { "Look Outside", "On a Nice Day", "Are you color blind?" }
function Get-Walkthru {
    <#
    .SynsopsiS
        Gets information from a file as a walkthru
        
    #>
    [CmdletBinding(DefaultParameterSetName="Command")]
    param(
    [Parameter(Mandatory=$true,
        ParameterSetName="Command",
        ValueFromPipeline=$true)]
    [Management.Automation.CommandInfo]
    $Command,    
    [Parameter(Mandatory=$true,
        ParameterSetName="File",
        ValueFromPipelineByPropertyName=$true)]    
    [Alias('Fullname')]
    [string]$File,
    
    [Parameter(Mandatory=$true,
        ParameterSetName="Text")]    
    [String]$Text
    )
    
    begin {
        $err = $null
        if (-not ('PSWalkthru.WalkthruData' -as [Type])) {
            Add-Type -UsingNamespace System.Management.Automation -Namespace PSWalkthru -Name WalkthruData -MemberDefinition '
public string SourceFile = String.Empty;','
public string Command = String.Empty;','
public string Explanation = String.Empty;','
public string AudioFile = String.Empty;','
public string VideoFile = String.Empty;','
public string Question = String.Empty;','
public string Answer = String.Empty;','
public string[] Hint;','
public ScriptBlock Script;'
        }
    }
    process {
        if ($psCmdlet.ParameterSetName -eq "File") {
            $realItem = Get-Item $file -ErrorAction SilentlyContinue
            if (-not $realItem) { return } 
            $text = [IO.File]::ReadAllText($realItem.FullName)                        
            $Result = Get-Walkthru -Text $text
            $result | 
                ForEach-Object {
                    $_.SourceFile = $realItem.Fullname
                    $_
                }
            return
        } elseif ($psCmdlet.ParameterSetName -eq "Command") {
            $help = $command | Get-Help 
            
            $c= 1
            $help.Examples.Example | 
                ForEach-Object {
                    $text = $_.code + ($_.remarks | Out-String)                
                    Get-Walkthru -Text $text |
                        ForEach-Object {
                            $_.Command = "$command Walkthru $c"
                            $_
                        }
                    $c++
                }
            return
        }
                                       
        $tokens = [Management.Automation.PSParser]::Tokenize($text, [ref]$err)                
        if ($err.Count) { return } 

        $lastToken = $null
        $isInContent = $false
        $lastResult = New-Object PSWalkthru.WalkthruData

        foreach ($token in $tokens) { 
            if ($token.Type -eq "Newline") { continue }
            if ($token.Type -ne "Comment" -or $token.StartColumn -gt 1) {
                $isInContent = $true
                if (-not $lastToken) { $lastToken = $token } 
            } else {
                if ($lastToken.Type -ne "Comment" -and $lastToken.StartColumn -eq 1) {
                    $chunk = $text.Substring($lastToken.Start, 
                        $token.Start - 1 - $lastToken.Start)
                    $lastResult.Script = [ScriptBlock]::Create($chunk)
                    # mutliparagraph, split up the results if multiparagraph                                                            
                    foreach ($p in $paragraphs) {
                        New-Object PSWalkthru.WalkthruData -Property @{Explanation = $p}
                    }
                    if ($lastIndex -ne -1) {
                        $lastResult.Explanation = $lastResult.Explanation.Substring($lastIndex + 1)
                    }
                    $lastResult                    

                    $null = $paragraphs
                    $lastToken = $null
                    $lastResult = New-Object PSWalkthru.WalkthruData
                    $isInContent = $false                
                }
            }
            if (-not $isInContent) {
                $lines = $token.Content.Trim("<>#")
                $lines = $lines.Split([Environment]::NewLine, 
                    [StringSplitOptions]"RemoveEmptyEntries")
                foreach ($l in $lines) {
                    switch ($l) {
                        {$_ -like ".Audio *" } {
                            $lastResult.AudioFile =
                                $l.Substring(".Audio ".Length)
                        }
                        {$_ -like ".Video *" } {
                            $lastResult.VideoFile =
                                $l.Substring(".Video ".Length)
                        }                        
                        {$_ -like ".Question *" } {
                            $lastResult.Question =
                                $l.Substring(".Question ".Length)
                        }                        
                        {$_ -like ".Answer *" } {
                            $lastResult.Answer =
                                $l.Substring(".Answer ".Length)
                        }
                        {$_ -like ".Hint *" } {
                            $lastResult.Hint =
                                $l.Substring(".Hint ".Length) -split ','
                        }                        
                        default {
                            $lastResult.Explanation += ($l + [Environment]::NewLine)                        
                        }
                    }
                }
            }            
        }
        
        if ($lastToken -and $lastResult) {
            $chunk = $text.Substring($lastToken.Start)
            $lastResult.Script = [ScriptBlock]::Create($chunk)
            $lastResult
        }
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUD7L7zf2tM7QRrt29n+jdNdna
# WrWgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFByHf9xTH3o7XPWZ
# CIT6OLZOFGsKMA0GCSqGSIb3DQEBAQUABIIBALSSH0dH9l93ZXAV9JGR6+z5oNTL
# mXpxHGpTAtxKJQ5UShRoZsLynWiKKJDwO/LiNmJ1eeKYUcq+Wc0UTm90Sl+qC/9j
# F3wqcyWiCLuaxEDaj3+It/wJxRsD0uYK7EEFVs/0nB2GJsK9o58NVq/rjWG1fn/S
# 6jvbT67JED3rMUT2tTmA0Dntdjje+oC4GamsF7cnO3qQ1AFb0YgqhTky+UXaFXZ3
# YfGQg5k18kkIanptPxVTEHdA1u0NI/nf9ea1+2NvjWlaEytq9iUhyVnaFH75f97i
# IOVcATCDR1DRLkFTQxMtLVGL++dWZJEeyUpgNzvCDAdEDHV/QwoWHs2GDcw=
# SIG # End signature block
