function Invoke-Background
{
    [CmdletBinding(DefaultParameterSetName='ScriptBlock')]
    param(
    # A Script block to run in the background.
    # To pass parameters to this script block, add a param() statement
    [Parameter(Mandatory=$true,ParameterSetName='ScriptBlock',Position=0)]
    [ScriptBlock]$ScriptBlock,
    
    # Invoke a command in the background
    [Parameter(Mandatory=$true,ParameterSetName='Command',Position=0)]
    [string]
    $Command,    
    
    [Hashtable]$Parameter,    
    $control = $this,
    [ValidateScript({
        if ($_.RunspaceStateInfo.State -ne 'Opened') {
            throw 'If a runspace is provided, it must be opened'
        }
        return $true
    })]
    [Management.Automation.Runspaces.Runspace]$InRunspace,
    [Switch]$DoNotAutomaticallyCreate,
    [Switch]$CreateDataContextHere,
    [Switch]$ResetDataSource,
    
    [System.Management.Automation.ScriptBlock[]]
    ${On_PropertyChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_OutputChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ErrorChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_WarningChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_DebugChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_VerboseChanged},

    [System.Management.Automation.ScriptBlock[]]
    ${On_ProgressChanged},
    
    [System.Management.Automation.ScriptBlock[]]
    ${On_IsRunningChanged},
    
    [System.Management.Automation.ScriptBlock[]]
    ${On_IsFinishedChanged},
    
    [System.Management.Automation.ScriptBlock[]]
    ${On_TimeStampedOutputChanged}    
    ) 
    
    process {
        if (-not $control ) { return } 
        $parent = Get-ParentControl -Control $control
        if (-not $parent) { $createDataContextHere = $true}
        if ($createDataContextHere) { 
            $target = $control
        } else {
            $target = $parent
        } 
        

                                           
        
        
        if ($ResetDataSource -or 
            $target.DataContext -isnot [ShowUI.PowerShellDataSource]) {
            
            if ($target.DataContext) {
                Write-Debug "Overwriting existing data context"
            }
              
            
            $target.DataContext = Get-PowerShellDataSource -Parent $target -Script { 
                
            }
            
            if ($target.CommandBindings.Add) {
                if (-not $target.CommandsBindings.Count) { 
                    $cmdBind = New-Object Windows.Input.CommandBinding @(
                        [ShowUI.ShowUICommands]::BackgroundPowerShellCommand,{
                            . Initialize-EventHandler
                            $sb = try { [ScriptBlock]::Create($_.Parameter) } catch { }
                            Invoke-Background -ScriptBlock $sb
                            trap {
                                . Write-WPFError
                                continue
                            }
                        }, {
                            $sb = try { [ScriptBlock]::Create($_.Parameter) } catch { }
                            . Initialize-EventHandler                                                        
                            $_.CanExecute = -not (Get-PowerShellOutput -GetDataSource | Select-Object -ExpandProperty IsRunning)
                            trap {
                                . Write-WPFError
                                continue
                            }
                        }
                    )
                    $target.CommandBindings.Add($cmdBind)
                }                
            }                                     
        }                                         
        
        $eventParameters = @{}
        foreach ($eventName in ($psBoundParameters.Keys -like "On_*")) {
            $eventParameters.$eventName = $psBoundParameters[$eventName]
        } 
        $handlerNames = @($target.DataContext.Resources.EventHandlers.Keys)
        if ($handlerNames) {
            foreach ($handler in $handlerNames) {
                $handlerMethod  = "remove_$($handler.Substring(3))"
                $target.DataContext.$handlerMethod.Invoke($target.DataContext.Resources.EventHandlers[$handler])
                $null = $target.DataContext.Resources.EventHandlers.Remove($handler)
            }
        }
        
        Set-Property -inputObject $target.DataContext -property $eventParameters 
        
        
        $target.DataContext.Parent = $target
        $target.DataContext.Command.Commands.Clear()
        
        if ($InRunspace) {
            $target.DataContext.Command.Runspace = $InRunspace            
        }
        
        if ($target.DataContext.Command.Runspace.RunspaceAvailability -ne 'Available') {
            Write-Error "Runspace was busy.  Will not run $command"
            return
        }        
        
        if ($parameter) {
            $target.DataContext.Command.Runspace.SessionStateProxy.PSVariable.Set('CommandParameters', $parameter)
            if ($debugPreference -ne 'SilentlyContinue') {
                $parameter
            }
            if ($psCmdlet.ParameterSetName -eq 'scriptBlock') {
                $target.DataContext.Script = ". { $ScriptBlock} @commandParameters"
            } else {
                $realCommand = $target.DataContext.Command.Runspace.SessionStateProxy.InvokeCommand.GetCommand($command, "All") 
                $target.DataContext.Script = "$($realCommand.Name) @commandParameters"
            }
            $target.DataContext.Resources.Parameter = $parameter
        } else {
            if ($psCmdlet.ParameterSetName -eq 'scriptBlock') {
                $target.DataContext.Script = "$ScriptBlock"
            } else {
                $target.DataContext.Script = "$Command"
            }
            
        }                
    }
} 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6CKuBLuKRNIQIzZebLKSMD9G
# tgegggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFCCoURZHg/vBq4Q4
# j0gVjo/Rpo6tMA0GCSqGSIb3DQEBAQUABIIBAI8oVYdYQJLN8o/BrqOwrelbZRIo
# B/j+Ah4MO7SUlV5Fnh+luZ9fRR8zL1dftQBA6/4Dr4Vol0UWDLlhDCvSsr6b06Xy
# tl8HG3cZFfFoGvkhX2NVSC7C56hWPLpPcavRHyylBSIpVXBIihwr3RL9ipsL6XvD
# x7unyhaUGr2YzWQ2Kit18DBkA6j1UM/PZspXgKkGueuaeRlXL/EgQC5VaiTReKfK
# V5YdDFBGH3EY4ZacAp0u/MuQhPDxPO+Pnf2/yTtNr6ORBWwSg8t5U/7V9mWQIkBt
# 15CxTUisEu+P308z5BDb+VdI3WKzDDHe5gib9zbTsDjadw3t7DxCDGSZdHk=
# SIG # End signature block
