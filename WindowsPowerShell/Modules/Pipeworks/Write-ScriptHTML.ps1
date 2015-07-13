function Write-ScriptHTML 
{
     <#
    .Synopsis
        Writes Windows PowerShell as colorized HTML
    .Description
        Outputs a Windows PowerShell script as colorized HTML.
        The script is wrapped in HTML PRE  tags with SPAN tags defining color regions.
    .Example
        Write-ScriptHTML {Get-Process}    
    .Link
        ConvertFrom-Markdown  
    #>
    [CmdletBinding(DefaultParameterSetName="Text")]
    [OutputType([string])]
    param(   
    # The Text to colorize
    [Parameter(Mandatory=$true,
        ParameterSetName="Text",
        Position=0,
        ValueFromPipeline=$true)]
    [Alias('ScriptContents')]
    [ScriptBlock]$Text,
    
    
    # The script as a string.
    [Parameter(Mandatory=$true,
        ParameterSetName="ScriptString",
        Position=0,
        ValueFromPipelineByPropertyName=$true)]    
    [string]$Script,
    
    # The start within the string to colorize    
    [Int]$Start = -1,
    # the end within the string to colorize    
    [Int]$End = -1,        
        
    # The palette of colors to use.  
    # By default, the colors will be the current palette for the
    # Windows PowerShell Integrated Scripting Environment
    $Palette = $Psise.Options.TokenColors,

    # If set, will include the script within a span instead of a pre tag
    [Switch]$NoNewline,
    
    # If set, will treat help within the script as markdown
    [Switch]$HelpAsMarkdown, 

    # If set, will not put a white background and padding around the script
    [Switch]$NoBackground
    )
    
    begin {
        function New-ScriptPalette
        {
            param(
            $Attribute = "#FFADD8E6",
            $Command = "#FF0000FF",
            $CommandArgument = "#FF8A2BE2",   
            $CommandParameter = "#FF000080",
            $Comment = "#FF006400",
            $GroupEnd = "#FF000000",
            $GroupStart = "#FF000000",
            $Keyword = "#FF00008B",
            $LineContinuation = "#FF000000",
            $LoopLabel = "#FF00008B",
            $Member = "#FF000000",
            $NewLine = "#FF000000",
            $Number = "#FF800080",
            $Operator = "#FFA9A9A9",
            $Position = "#FF000000",
            $StatementSeparator = "#FF000000",
            $String = "#FF8B0000",
            $Type = "#FF008080",
            $Unknown = "#FF000000",
            $Variable = "#FFFF4500"        
            )
    
            process {
                $NewScriptPalette= @{}
                foreach ($parameterName in $myInvocation.MyCommand.Parameters.Keys) {
                    $var = Get-Variable -Name $parameterName -ErrorAction SilentlyContinue
                    if ($var -ne $null -and $var.Value) {
                        if ($var.Value -is [Collections.Generic.KeyValuePair[System.Management.Automation.PSTokenType,System.Windows.Media.Color]]) {
                            $NewScriptPalette[$parameterName] = $var.Value.Value
                        } elseif ($var.Value -as [Windows.Media.Color]) {
                            $NewScriptPalette[$parameterName] = $var.Value -as [Windows.Media.Color]
                        }
                    }
                }
                $NewScriptPalette    
            }
        }
                                                 
        Set-StrictMode -Off
        Add-Type -AssemblyName PresentationCore, PresentationFramework, System.Web
    }
        
    process {
        if (-not $Palette) {
            $palette = @{} 
        }
        
        if ($psCmdlet.ParameterSetName -eq 'ScriptString') {
            $text = [ScriptBLock]::Create($script)
        }
        

        if ($Text) {
            #
            # Now parse the text and report any errors...
            #
            $parse_errs = $null
            $tokens = [Management.Automation.PsParser]::Tokenize($text,
                [ref] $parse_errs)
         
            if ($parse_errs) {
                $parse_errs | Write-Error
                return
            }
            $stringBuilder = New-Object Text.StringBuilder
            $backgroundAndPadding = 
                if (-not $NoBackground) {
                    "background-color:#fefefe;padding:5px"
                } else {
                    ""
                }
                        
            $null = $stringBuilder.Append("<$(if (-not $NoNewline) {'pre'} else {'span'}) class='PowerShellColorizedScript' style='font-family:Consolas;$($backgroundAndPadding)'>")
            # iterate over the tokens an set the colors appropriately...
            $lastToken = $null
            $ColorPalette = New-ScriptPalette @Palette
            $scriptText = "$text" 
            $c = 0  
            $tc = $tokens.Count 
            foreach ($t in $tokens)
            {
                $C++
                if ($c -eq $tc) { break } 
                if ($lastToken) {
                    $spaces = "&nbsp;" * ($t.Start - ($lastToken.Start + $lastToken.Length))
                    $null = $stringBuilder.Append($spaces)
                }
                if ($t.Type -eq "NewLine") {
                    $null = $stringBuilder.Append("            
")
                } else {
                    $chunk = $scriptText.SubString($t.start, $t.length).Trim()                    
                    if ($t.Type -eq 'Comment' -and $HelpAsMarkdown) {
                        if ($chunk -like "#*") {
                            $chunk = $chunk.Substring(1)
                        }
                        $chunk =  "<p>" + (ConvertFrom-Markdown -Markdown $chunk) + "</p>"
                    }
                    
                    $color = $ColorPalette[$t.Type.ToString()]            
                    $redChunk = "{0:x2}" -f $color.R
                    $greenChunk = "{0:x2}" -f $color.G
                    $blueChunk = "{0:x2}" -f $color.B
                    $colorChunk = "#$redChunk$greenChunk$blueChunk"                    
                    $null = $stringBuilder.Append("<span style='color:$colorChunk'>$([Web.HttpUtility]::HtmlEncode($chunk).Replace('&amp;','&').Replace('&quot;','`"'))</span>")                    
                }                       
                $lastToken = $t
            }
            $null = $stringBuilder.Append("</$(if (-not $NoNewline) {'pre'} else {'span'})>")
            
            
            $stringBuilder.ToString()
        }
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUueDCNeOTepNq671z+cjPV91C
# OpigggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFOPFc/PI4+INAogd
# uGHuj5Cu9XjuMA0GCSqGSIb3DQEBAQUABIIBALGhackJv1CObgoxfInXOXc2UFXv
# UFruXxPPGkaLJFNKoG7jv6tkSIeYkTHJ31jgtZXmjWQ79npJsTgjXdq/2Pzq1Tir
# aoAslvPQ7zhXINF6nLWT6iXoKoWpjR2RlEX70iPckRwJltZWLT2ATm7wSma1PJwq
# mAWl6iBm+9cdzLiV7rragbmIA7rkVMs8lEZoGNfk0p78Ooaxsc3HBILJnkQ4ACt1
# xUQdUzrFtAwXg0g6dIwXW5aFBm2G48vcEwRfoRPGMt06TftvtEWDSWkULDnM5TQa
# 6zKcknEQZvq67M0ti8qwwutcRi1VXxl+7F8pXqw8uLjP6GKup/OaY/itNdg=
# SIG # End signature block
