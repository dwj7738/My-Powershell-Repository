function Write-WalkthruHTML
{
    <#
    .Synopsis
        Writes a walkthru HTML file
    .Description
        Writes a section of HTML to walk thru a set of code.
    .Example
        Write-WalkthruHTML -Text @"
#a simple demo
Get-Help about_walkthruFiles
"@
    .Link
        Get-Walkthru
        Write-ScriptHTML    
    #>
    [CmdletBinding(DefaultParameterSetName='Text')]  
    [OutputType([string])]  
    param(    
    # The text used to generate walkthrus
    [Parameter(Position=0,Mandatory=$true,
        ParameterSetName="Text",
        ValueFromPipeline=$true)]    
    [ScriptBlock]$ScriptBlock,    
    
    # A walkthru object, containing a source file and a property named
    # walkthru with several walkthru steps
    [Parameter(Position=0,Mandatory=$true,        
        ParameterSetName="Walkthru",
        ValueFromPipeline=$true)]    
    [PSObject]$WalkThru,
    
    # with a different step on each layer
    [Parameter(Position=1)]
    [Switch]$StepByStep,

    # If set, will run each demo step
    [Parameter(Position=2)]
    [Switch]$RunDemo,

    # If set, output will be treated as HTML.  Otherwise, output will be piped to Out-String and embedded in <pre> tags.
    [Parameter(Position=3)]
    [Switch]$OutputAsHtml,

    # If set, will start with walkthru with a <h3></h3> tag, or include the walkthru name on each step
    [Parameter(Position=4)]
    [string]$WalkthruName,
    
    # If set, will embed the explanation as text, instead of converting it to markdown.
    [Parameter(Position=5)]
    [switch]$DirectlyEmbedExplanation    
    )
    
    process {
        if ($psCmdlet.ParameterSetName -eq 'Text') {                        
            Write-WalkthruHTML -Walkthru (Get-Walkthru -Text "$ScriptBlock") -StepByStep:$stepByStep
        } elseif ($psCmdlet.ParameterSetName -eq 'Walkthru') {            
            $NewRegionParameters = @{
                Layer = @{}
                Order = @()
                HorizontalRuleUnderTitle = $true                                
            }                                   
                        
            $walkThruHTML = New-Object Text.StringBuilder
            
            
            $count = 1
            $total = @($walkThru).Count
            foreach ($step in $walkThru) {
                
                # If we're going step by step, then we need to reset the string builder each time 
                if ($stepByStep) {                      
                    $walkThruHTML = New-Object Text.StringBuilder 
                }     
                
                if ($DirectlyEmbedExplanation -or $step.Explanation -like "*<*") {
                
                $null = $walkThruHtml.Append("

                <div class='ModuleWalkthruExplanation'>
                $($step.Explanation.Replace([Environment]::newline, '<BR/>'))
                </div>")
                } else {
                    $null = $walkThruHtml.Append("

                <div class='ModuleWalkthruExplanation'>
                $(ConvertFrom-Markdown -Markdown "$($step.Explanation) ")
                </div>")
                }
                if ($step.VideoFile -and $step.VideoFile -like "http*") {
                    if ($step.VideoFile -like "http://www.youtube.com/watch?v=*") {
                        $uri = $step.VideoFile -as [uri]
                        $type, $youTubeId = $uri.Query -split '='
                        $type = $type.Trim("?")
                        $null = 
                            $walkThruHtml.Append(@"                                    
<br/>
<embed type="application/x-shockwave-flash" width="425" height="344" src="http://www.youtube.com/${type}/${youTubeId}?hl=en&amp;fs=1&amp;modestbranding=true" allowscriptaccess="always" allowfullscreen="true">
"@)
                    } elseif ($step.VideoFile -like "http://player.vimeo.com/video/*") {
                        $vimeoId = ([uri]$step.VideoFile).Segments[-1]
                        $null = 
                            $walkThruHtml.Append(@"
<br/>
<iframe src="http://player.vimeo.com/video/${vimeoId}?title=0&amp;byline=0&amp;portrait=0" width="400" height="245" frameborder="0">
</iframe><p><a href="http://vimeo.com/{$vimeoId}">$($walkThru.Explanation)</a></p>

"@)
                    } else {
                        $null = 
                            $walkThruHtml.Append("
                            <br/>
                            <a class='ModuleWalkthruVideoLink' href='$($step.VideoFile)'>Watch Video</a>")
                    }   
                }
                $null = $walkThruHtml.Append("<br/></p>")  
                
                if (("$($step.Script)".Trim())-and ("$($step.Script)".Trim() -ne '$null')) {
                    $scriptHtml = Write-ScriptHTML -Text $step.Script 
                    $null = $walkThruHtml.Append(@"
<p class='ModuleWalkthruStep'>
$scriptHtml
</p>
"@)                            
                }

                if ($RunDemo) {
                    $outText = . $step.Script
                    if (-not $OutputAsHtml) {
                    $null = $walkThruHtml.Append("<pre class='ModuleWalkthruOutput' foreground='white' background='#012456'>
                    $([Security.SecurityElement]::Escape(($outText | Out-String)))
                    </pre>")                        
                    } else {
                        $null = $walkThruHtml.Append("$OutText")
                    }
                }
                if ($stepByStep) {
                    $NewRegionParameters.Layer."$WalkthruName [$Count of $Total]" = "<div style='margin-left:15px;margin-top:15px;'>$walkThruHTML</div>"
                    $NewRegionParameters.Order+= "$WalkthruName [$Count of $Total]" 
                    
                }                
                $Count++                                    
            }
            
            if (-not $stepByStep) { 
                "$walkThruHTML"
            } else {
                if ($WalkthruName) {
                    New-Region @newRegionParameters -AsAccordian -LayerId "Walkthru_$WalkthruName"
                } else {
                    New-Region @newRegionParameters -AsAccordian
                }
                
            }
            
            
                
            }
        
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmqQqQp/drH1Sc3yYUVMcFWNT
# aM2gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDqIvFFnWLH2uMcj
# E4/XAUPnncA5MA0GCSqGSIb3DQEBAQUABIIBALbldoxMlmvUjV7NyUM7IyucOGJz
# tICesfLwPEbCYqa86Dr/75jlHUdvBYTxAH7cIU3Hd+DgeYqUgkTYcWMgTqqKYgHZ
# ZRFMmQlL1F/65+GJivcw5asYXJtrISM3xo//5nQHDqjws08cGfJVz1ypGCop2ypJ
# 2W7ExYShO6wwVmfCt1ZHc694fR3jU4D2ORmPCZ1bSwZ71KN2OPMmEfsfFU0AecEJ
# qNh237ZIdhIosyL8JYfIEXeCSxEdNR2yRZ4stepUPBY3Ii3ucJwgAoag7YvLdJLJ
# L6qWhC8jQvMz4BRoGjNrgPI+7P0zRh2j0iQbRA46/m+MOlFqprn7PRBtpZs=
# SIG # End signature block
