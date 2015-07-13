function Add-AzureStartupTask
{
    <#
    .Synopsis
        Adds a startup task to Azure
    .Description
        Adds a startup task to an azure service configuration, and packs some extra information into the XML to allow 
        using ScriptBlock as startup tasks
    .Example
        New-AzureServiceDefinition -ServiceName "MyService" |
            Add-AzureStartupTask -ScriptBlock { "Hello World" } -Elevated -asString
            
    .Link
        Out-AzureService
    #>
    [OutputType([xml],[string])]
    [CmdletBinding(DefaultParameterSetName='CommandLine')]
    param(    
    # The Service Definition XML
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
    [ValidateScript({
        $isServiceDefinition = $_.NameTable.Get("http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition")
        if (-not $IsServiceDefinition) {
            throw "Input must be a ServiceDefinition XML"
        }
        return $true
    })]    
    [Xml]
    $ServiceDefinition,
        
    # The role
    [string]
    $ToRole,
    
    # The command line to run    
    [Parameter(Mandatory=$true,ParameterSetName='CommandLine')]    
    [string]
    $CommandLine,
    
    # The ScriptBlock to run. 
    [Parameter(Mandatory=$true,ParameterSetName='ScriptBlock')]    
    [ScriptBlock]
    $ScriptBlock,
    
    # The parameter to be passed to the script block
    [Parameter(ParameterSetName='ScriptBlock')]    
    [Hashtable]
    $Parameter,       
    
    # The task type.  
    [ValidateSet('Simple', 'Background', 'Foreground')]
    [string]
    $TaskType = 'Simple',
    
    # If set, the task will be run elevated
    [switch]
    $Elevated,
    
    # If set, returns the service definition XML up to this point as a string
    [switch]
    $AsString
    )
    
    process {        
        $taskType = $taskType.ToLower()
        
        # Resolve the role if it set, create the role if it doesn't exist, and track it if they assume the last item.
        $roles = @($ServiceDefinition.ServiceDefinition.WebRole), @($ServiceDefinition.ServiceDefinition.WorkerRole) +  @($ServiceDefinition.ServiceDefinition.VirtualMachineRole)
        $xmlNamespace = @{'ServiceDefinition'='http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition'}        
        $selectXmlParams = @{
            XPath = '//ServiceDefinition:WebRole|//ServiceDefinition:WorkerRole|//ServiceDefinition:VirtualMachineRole'
            Namespace = $xmlNamespace
        }        
        $roles = @(Select-Xml -Xml $ServiceDefinition @selectXmlParams | 
            Select-Object -ExpandProperty Node)
        if (-not $roles) {
            $ServiceDefinition = $ServiceDefinition | 
                Add-AzureRole -RoleName "WebRole1"
                
            $roles = @(Select-Xml -Xml $ServiceDefinition @selectXmlParams | 
                Select-Object -ExpandProperty Node)
        }
        
        if ($roles.Count -gt 1) {
            if ($ToRole) {
            } else {
                $role = $roles[-1]                
            }
        } else {
            if ($ToRole) {
                if ($roles[0].Name -eq $ToRole) {
                    $role = $roles[0]
                } else { 
                    $role = $null 
                }
            } else {            
                $role = $roles[0]
            }           
        }
        
        if (-not $role) { return }
                
        if (-not $role.Startup) {
            $role.InnerXml += "<Startup/>"
        }
        
        $startupNode = Select-Xml -Xml $role -Namespace $xmlNamespace -XPath '//ServiceDefinition:Startup' |
            Select-Object -ExpandProperty Node -First 1
        
        $execContext= if ($elevated) { 'elevated'  } else { 'limited' }    
        if ($psCmdlet.ParameterSetName -eq 'CommandLine') {
            $startupNode.InnerXml += "<Task commandLine='$CommandLine' executionContext='$execContext' taskType='$taskType'/>"
        } elseif ($psCmdlet.ParameterSetName -eq 'ScriptBlock') {
            $parameterChunk = if ($parameter) { 
                $parameterChunk = "<Parameters>"
                foreach ($kv in $parameter.GetEnumerator()) {
                    if ($kv.Value) {
                        $parameterChunk  += "<Parameter name='$($kv.Key)' value='$([Security.SecurityElement]::Escape($kv.Value))' />"
                    } else {
                        $parameterChunk  += "<Parameter name='$($kv.Key)' />"
                    }
                }
                $parameterChunk += "</Parameters>"
            } else { ""}            
            $startupNode.InnerXml += "<Task commandLine='' executionContext='$execContext' taskType='$taskType'>
                <ScriptBlock>
                    $([Security.SecurityElement]::Escape($ScriptBlock))                    
                </ScriptBlock>
                $parameterChunk
            </Task>"
        }

    }
    
    end {
        if ($AsString) {
            $strWrite = New-Object IO.StringWriter
            $serviceDefinition.Save($strWrite)
            return "$strWrite"
        } else {
            $serviceDefinition
        }   

    }
} 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUuyDuLS36tz2bs8+L1F9vkXoh
# hoqgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEfWLPOv5kNnNjSt
# 6aEvraSM97O4MA0GCSqGSIb3DQEBAQUABIIBAJkALUPSH39U6ozGkACr5dFIU8Lv
# 8+quQ2QafwRtaxz8cTuUN/AZCSEOzoe+JNwPGeSMZXLPSoQeIuwztWruKyiaAeW7
# /LU706moOEgQ+wpYWfcWupyF0xg+Zsp4Gi/ztHZvdA6U+oO8EpJXfJeitr9EfJNy
# bpO1Jr2k3K/9S53ob+Uvu3HqovS2Gl6jZGIJ3vWzjkot0cS2enIsO/P0eujoScnx
# wVh0MRebI0B/nKtX3+qz32FqZkZg2MXXXR5nVwsYLDo1AkyG2HjseCmTaGbOjkJ4
# IhfqqxUZH3ghlu39qYviXJvP9okV/CB9azw1XhH+1FAHiVz0st4MELjYs1I=
# SIG # End signature block
