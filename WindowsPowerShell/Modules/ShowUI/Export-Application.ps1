function Export-Application
{
    <#
    .Synopsis
        Exports a WPK script into an executable
    .Description
        Exports a WPK script into an executable.
        Embeds all needed scripts within the executable, an
    .Example
        # Creates an .exe at the current path that runs digitalclock.ps1
        $clock = Get-Command $env:UserProfile\Documents\WindowsPowerShell\Modules\WPK\Examples\DigitalClock.ps1
        $clock | Export-Application 
    .Parameter Command
        The Command to turn into an application.
        The command should either be a function or an external script
    .Parameter Name
        The name of the .EXE to produce.  By default, the name will be the
        command name with an .EXE extension instead of a .PS1 extension
    .Parameter ReferencedAssemblies
        Additional Assemblies to Reference when compilign.
    .Parameter OutputPath
        If set, will output the executable into this path.
        By default, executables are outputted to the current directory.
    .Parameter TopModule
        The top level module to import.
        By default, this is the module that is exporting Export-Application
    #>
    param(
    [Parameter(ValueFromPipeline=$true)]
    [Management.Automation.CommandInfo]
    $Command,    
    [string]
    $Name,    
    [Reflection.Assembly[]]
    $ReferencedAssemblies = @(),
    [String]$OutputPath,
    [switch]$DoNotEmbed,
    [string]$TopModule = $myInvocation.MyCommand.ModuleName 
    ) 

    process {       
        $optimize = $true
        Set-StrictMode -Off
        if (-not $name) {
            $name = $command.Name
            if ($name -like "*.ps1") {
                $name = $name.Substring(0, $name.LastIndexOf("."))
            }
        }
        
        $referencedAssemblies+= [PSObject].Assembly
        $referencedAssemblies+= [Windows.Window].Assembly
        $referencedAssemblies+= [System.Windows.Threading.DispatcherFrame].Assembly
        $referencedAssemblies+= [System.Windows.Media.Brush].Assembly
        
        if (-not $outputPath)  {
            $outputPath = "$name.exe"
        }
        
        $initializeChunk = ""
        foreach ($r in $referencedAssemblies) {
            if ($r -notlike "*System.Management.Automation*") {
                $initializeChunk += "
          #      [Reflection.Assembly]::LoadFrom('$($r.Location)')
                "
            }
        }
        
        if ($optimize) {
            $iss = [Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $builtInCommandNames = $iss.Commands | 
                Where-Object { $_.ImplementingType } | 
                Select-Object -ExpandProperty Name         

            $aliases = @{}
            $outputChunk = "" 
            $command | 
                Get-ReferencedCommand | 
                ForEach-Object {
                    if ($_ -is [Management.Automation.AliasInfo]) {
                        $aliases.($_.Name) = $_.ResolvedCommand
                        $_.ResolvedCommand
                    }
                    $_        
                } | Foreach-Object {
                    if ($_ -is [Management.Automation.CmdletInfo]) {
                        if ($builtInCommandNames -notcontains $_.Name) {
                            $outputChunk+= "
                            Import-Module '$($_.ImplementingType.Assembly.Location)'
                            "
                        }
                    }
                    $_        
                } | ForEach-Object {
                    if ($_ -is [Management.Automation.FunctionInfo]) {
                        $outputChunk += "function $($_.Name) {
                            $($_.Definition)
                        }
                        "
                    }
                }
                
                $outputChunk += $aliases.GetEnumerator() | ForEach-Object {
                    "
                    Set-Alias $($_.Key) $($_.Value)
                    "
                }                
            $initializeChunk += $outputChunk
        } else {
            $initializeChunk += "
            Import-Module '$topModule'
            "
        }
        if (-not $DoNotEmbed) {
            if ($command.ScriptContents) {
                $base64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command.ScriptContents))
            } else {
                if ($command.Definition) {
                    $base64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command.Definition))
                }
            }
            $argsSection = @"
                sb.Append(System.Text.Encoding.Unicode.GetString(Convert.FromBase64String("$base64")));
"@        
        } else {
            $argsSection = @'
                if (args.Length == 2) {
                    if (String.Compare(args[0],"-encoded", true) == 0) {
                        sb.Append(System.Text.Encoding.Unicode.GetString(Convert.FromBase64String(args[1])));
                    }
                } else {
                    foreach (string a in args) {
                        sb.Append(a);
                        sb.Append(" ");                
                    }            
                }
'@        
        }
        
        $initBase64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($initializeChunk))
        
      
        $applicationDefinition = @"
    
    using System;
    using System.Text;
    using System.Management.Automation;
    using System.Management.Automation.Runspaces;
        
    public static class $name {
        public static void Main(string[] args) {
            StringBuilder sb = new StringBuilder();

            $argsSection

            PowerShell psCmd = PowerShell.Create();
            Runspace rs = RunspaceFactory.CreateRunspace();
            rs.ApartmentState = System.Threading.ApartmentState.STA;
            rs.ThreadOptions = PSThreadOptions.ReuseThread;
            rs.Open();
            psCmd.Runspace =rs;
            psCmd.AddScript(Encoding.Unicode.GetString(Convert.FromBase64String("$initBase64")), false).Invoke();
            psCmd.Invoke();            
            psCmd.Commands.Clear();           
            psCmd.AddScript(sb.ToString());
            try {
                psCmd.Invoke();
            } catch (Exception ex) {
                System.Windows.MessageBox.Show(ex.Message, ex.GetType().FullName);                
                rs.Close();
                rs.Dispose();     
            }
            foreach (ErrorRecord err in psCmd.Streams.Error) {
                System.Windows.MessageBox.Show(err.ToString());
            }
            rs.Close();
            rs.Dispose();                        
        }
    }   
"@   
        Write-Verbose $applicationDefinition
        Add-Type $applicationDefinition -IgnoreWarnings -ReferencedAssemblies $referencedAssemblies `
            -OutputAssembly $outputPath -OutputType WindowsApplication
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6VQtBxa7WVJI9+lik4WMtnAL
# 1sGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFB0hxLn2tR0F/VRb
# DHqbXazDJ42SMA0GCSqGSIb3DQEBAQUABIIBAJmjMbB7HsSGR41dYlgLIVUTfo67
# wZcqCcEtGsJRyh4eFDljf7g225S2UF8B0pxfZaseqaAE6rnIbPbrBut8kR+SzsxM
# rt95uvbWUgZLLAr2pDwRpL8Z//FS0jYGqx4d+ZbHfVC4ZGSo/+UL8dLU1/5r7Psu
# RXoMtAi2WhHiwTL3DH0tft4xilUPcnV9jEpCq9c5BZ7S2lmn2m7LvWoymUUganVi
# 7jdJIOzvBaXLYaq81cB7BweFi/zUr7MsLA3wMJmreE8VUJRo2KPs466ZqwMGjtRt
# wU5tiRuGo0O486tHhNvo4hcKjfHX0r1Jc/Z3dYJ0IhrDRAROjr/zJGcquic=
# SIG # End signature block
