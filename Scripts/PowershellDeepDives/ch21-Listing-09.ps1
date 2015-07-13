#listing 1.9 Updated Remote Scriptblock , now we have pipeline streaming.
function Get-AvailableModule {
[CmdletBinding(DefaultParameterSetName='InProcess')]
param(

    [Parameter(ParameterSetName='InProcess',Position=0,ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='Uri',Position=1,ValueFromPipeline=$true)]
    [Parameter(ParameterSetName='ComputerName',Position=1,ValueFromPipeline=$true)]    
    [Parameter(ParameterSetName='Session',Position=1,ValueFromPipeline=$true)]    
    [string]$Name = "*",


    [Parameter(ParameterSetName='Session', Position=0)]    
    [ValidateNotNullOrEmpty()]
    [System.Management.Automation.Runspaces.PSSession[]]
    ${Session},

    [Parameter(ParameterSetName='ComputerName', Position=0)]    
    [Alias('Cn')]
    [ValidateNotNullOrEmpty()]
    [string[]]
    ${ComputerName},
    
    [Parameter(ParameterSetName='ComputerName', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='Uri', ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    ${Credential},

    [Parameter(ParameterSetName='ComputerName')]
    [ValidateRange(1, 65535)]
    [int]
    ${Port},

    [Parameter(ParameterSetName='ComputerName')]
    [switch]
    ${UseSSL},
    
    [Parameter(ParameterSetName='ComputerName', ValueFromPipelineByPropertyName=$true)]
    [Parameter(ParameterSetName='Uri', ValueFromPipelineByPropertyName=$true)]
    [string]
    ${ConfigurationName},

    [Parameter(ParameterSetName='ComputerName', ValueFromPipelineByPropertyName=$true)]
    [string]
    ${ApplicationName},

    [Parameter(ParameterSetName='Uri')]
    [Parameter(ParameterSetName='Session')]
    [Parameter(ParameterSetName='ComputerName')]
    [int]
    ${ThrottleLimit},

    [Parameter(ParameterSetName='Uri', Position=0)]    
    [Alias('URI','CU')]
    [ValidateNotNullOrEmpty()]
    [uri[]]
    ${ConnectionUri},

    [Parameter(ParameterSetName='ComputerName')]
    [Parameter(ParameterSetName='Session')]
    [Parameter(ParameterSetName='Uri')]
    [switch]
    ${AsJob},

    [Parameter(ParameterSetName='ComputerName')]
    [Parameter(ParameterSetName='Session')]
    [Parameter(ParameterSetName='Uri')]
    [Alias('HCN')]
    [switch]
    ${HideComputerName},

    [Parameter(ParameterSetName='ComputerName')]
    [Parameter(ParameterSetName='Session')]
    [Parameter(ParameterSetName='Uri')]
    [string]
    ${JobName},
    
    [Parameter(ParameterSetName='Uri')]    
    [switch]
    ${AllowRedirection},

    [Parameter(ParameterSetName='Uri')]
    [Parameter(ParameterSetName='ComputerName')]
    [System.Management.Automation.Remoting.PSSessionOption]
    ${SessionOption},
    
    [Parameter(ParameterSetName='ComputerName')]
    [Parameter(ParameterSetName='Uri')]
    [System.Management.Automation.Runspaces.AuthenticationMechanism]
    ${Authentication},

   
    [Parameter(ValueFromPipeline=$true)]
    [psobject]
    ${InputObject},
   
    [Parameter(ParameterSetName='Uri')]
    [Parameter(ParameterSetName='ComputerName')]
    [string]
    ${CertificateThumbprint})

begin
{
        function Get-InnerAvailableModule(
    [Parameter(ValueFromPipeline = $true) ]
    [string]$Name = "*"
    ) 
    { 
       process {       
       Get-Module -ListAvailable -Name $Name | 
       Select Name,Version | 
       Add-Member -Name WhereRan `
                  -Value $ENV:ComputerName `
                  -MemberType NoteProperty -PassThru
                }
    }   

    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Invoke-Command', [System.Management.Automation.CommandTypes]::Cmdlet)        
        $null = $PSBoundParameters.Remove("Name")        
        $RemoteScriptBlock = {
          param($scriptblockToRun,[hashtable]$arguments)
            $scriptblockToRun = [scriptblock]::Create($scriptblockToRun)
            if($input) {
                $arguments.remove("Name")
                $input | &$scriptblockToRun @arguments
              }
            else {
               &$scriptblockToRun @arguments
            } 
            
        }        
        $Arguments = @{name = $Name}        
        $PSBoundParameters.Add("Scriptblock",$RemoteScriptBlock ) 
        $PSBoundParameters.Add("ArgumentList",@(${function:Get-InnerAvailableModule},$Arguments ))
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzNjTi7HTx0WEps0ssMB5aec9
# Z8mgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFFW6svPoF4zQzn9t
# dnk1beApSihmMA0GCSqGSIb3DQEBAQUABIIBAKjAWgU438adPyJCCmhDMSv1rfbM
# GZNqFDegTk37vyBU06+FoAW4Xo4wONxGt/30hAUQ63oxE1f8oqoT/myR+AXej9BT
# 6WqHPU+wQjSw3Ime+CFoy/mIWgb+qV0HoiMAlmHNHNc9J6t2/9CPapkS9jFhRdrj
# XxvfJwnRSmrD9WXmw3AnQCNrE1/Q9YmNr/x0kmsUQk1Q2win823ui30Gf/s5RtsR
# uTZiBCqHUH3rH2nIVZRnf7cukGxn6VvxH1ESPg8BKZPuh6+cAh+HViIx0Rqe9/jf
# 4UCIC9ZdPjHwC9AUPxEGRgQ5qjMn0UIJeuW1fYFNaDSGZUTbbwJmev5UPE0=
# SIG # End signature block
