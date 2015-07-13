function Out-AzureService
{
    <#
    .Synopsis
        Creates a an Azure Service Deployment pack, definition, and configuration file
    .Description
        Uses the Azure SDK tool CSPack to create a deployment package (cspkg) and associated deployment files.               
    .Link 
        New-AzureServiceDefinition
    .Link 
        Publish-AzureService
    #>
    [OutputType([IO.FileInfo])]
    param(    
    # The Service DefinitionXML
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

    # The output directory for the azure service.
    [Parameter(Mandatory=$true)]
    [string]
    $OutputPath,
       
    # If set, will look for a specific Azure SDK Version
    [Version]
    $SdkVersion,
    
    [Uint32]
    $InstanceCount = 2
    )
    
    begin {
        #region Find CSPack
        $azureSdkDir = Get-ChildItem "$env:ProgramFiles\Windows Azure SDK", "$env:ProgramFiles\Microsoft SDKs\Windows Azure\.NET SDK" -Force -ErrorAction SilentlyContinue 
        if ($azureSdkDir) {
            $latestcsPack = $azureSdkDir | 
                Sort-Object { $_.Name.Replace('v', '') -as [Version] }  |
                Where-Object {
                    if ($sdkVersion) {
                        $_.Name.Replace('v', '') -eq $SdkVersion
                    } else {
                        return $true
                    }                    
                } |
                Select-Object -Last 1 |
                Get-ChildItem -Filter 'bin' |
                Get-ChildItem -Filter 'cspack*'
                
            if ($latestCsPack) {
                $csPack  = Get-Command $latestCsPack.fullname
            }
        } else {
            $latestCSPack = $csPack = Get-Command $psScriptRoot\Tools\cspack.exe
        }        
        #endregion Find CSPAck
    }
    
    process {
        if (-not $latestCSPack) { 
            Write-Error "Azure SDK tool CSPack not found"
            return 
        } 
        $temporaryServiceDirectory = New-Item -ItemType Directory -Path "$env:Temp\$(Get-Random).azureService" 
        
        $serviceName = $ServiceDefinition.ServiceDefinition.name
        try { $null = $ServiceDefinition.CreateXmlDeclaration("1.0", "utf8", $null) } catch  {} 
        $serviceDefinitionFile = Join-Path $temporaryServiceDirectory "$serviceName.csdef"
        $ServiceDefinition.Save($serviceDefinitionFile)
                    
        $serverShellDirectory = $psScriptRoot
        
        $workingDirectory = Split-Path $serviceDefinitionFile
        $leaf = Split-Path $serviceDefinitionFile -Leaf
        $configurationFile = "$serviceName.cscfg"
        
        $arguments = @("$leaf")
        
        
                
        
        $roles = @($ServiceDefinition.ServiceDefinition.WebRole), @($ServiceDefinition.ServiceDefinition.WorkerRole) +  @($ServiceDefinition.ServiceDefinition.VirtualMachineRole)
        $xmlNamespace = @{'ServiceDefinition'='http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition'}        
        $selectXmlParams = @{
            XPath = '//ServiceDefinition:WebRole|//ServiceDefinition:WorkerRole|//ServiceDefinition:VirtualMachineRole'
            Namespace = $xmlNamespace
        }        
        $roles = @(Select-Xml -Xml $ServiceDefinition @selectXmlParams | 
            Select-Object -ExpandProperty Node)
        
        #$roles[0]
        $startupBin = "$temporaryServiceDirectory\Startup\bin"
        New-Item $startupBin  -ErrorAction SilentlyContinue -Force -ItemType Directory | Out-Null
                      
        
        #$arguments += "/role:$roleArgs"
        $firstSitePhysicalDirectory = $null
        foreach ($role in $roles) {
            $roleDir = Join-Path $temporaryServiceDirectory $role.Name
            $null = New-Item -ItemType Directory -Path $roleDir
            $roleBinDir = Join-Path $temporaryServiceDirectory "$($role.Name)_bin"            
            $null = New-Item -ItemType Directory -Path $roleBinDir
            $roleBin = Join-Path $roleBinDir "bin"
            $null = New-Item -ItemType Directory -Path $roleBin
            # The azure sdk requires a binary, so give them a binary
            Add-Type -OutputAssembly "$roleBin\Placeholder.dll" -TypeDefinition @"
namespace Namespace$(Get-Random) {
    public class Stuff 
    {
        public int StuffCount;
    }
}
"@            
            $configSettingsChunk = "<ConfigurationSettings />"
            $arguments+= "/role:$($role.Name);$($role.Name)_bin"
            if ($role.ConfigurationSettings) {
                $configSettingsChunk = "<ConfigurationSettings>"
                foreach ($configSetting in $role.ConfigurationSettings.Setting) {
                    $configSettingsChunk += $configSetting.innerXml
                    $null = $configSetting.RemoveAttribute('value')
                }
                $configSettingsChunk += "</ConfigurationSettings>"                
                $ServiceDefinition.Save($serviceDefinitionFile)
            }
            
            if ($role.Startup) {
                $c = 0
                foreach ($task in $role.Startup.Task) {
                    $c++
                    if ($task.ScriptBlock) {
                        $null = $task.SetAttribute('commandLine', "startupScript${c}.cmd")
                        # Create the cmd file
                        $cmdFile = "powershell.exe -executionpolicy bypass -file startupScript${c}.ps1"
                        $scriptFile = "`$scriptBlockParameters = @{}
`$serviceName = '$($serviceDefinition.Name)'
"
                        
                        if ($task.Parameters) {
                            foreach ($parameter in $task.Parameters) {
                                $scriptFile += "

`$scriptBlockParameters.'$($Parameter.Name)' = '$($parameter.Value)'
                                
                                "
                            }
                        }
                        $scriptFile += "
                        
& {
    $($task.ScriptBlock.'#text')
} @scriptBlockParameters 
                        " 
                        $cmdFile > "$roleBin\startupScript${c}.cmd"
                        $scriptFile > "$roleBin\startupScript${c}.ps1"
                    }
                    foreach ($i in @($task.GetEnumerator())) { 
                        $null = try { $task.RemoveChild($i)  } catch { }
                    } 
                }
                $ServiceDefinition.Save($serviceDefinitionFile)
            }
            $roleConfigChunk += "<Role name='$($role.Name)'>
    $configSettingsChunk
    <Instances count='$InstanceCount' />
  </Role>"            
            $sites = $roles = @(Select-Xml -Xml $ServiceDefinition -Namespace $xmlNamespace -XPath //ServiceDefinition:Site | 
                Select-Object -ExpandProperty Node)
            if ($sites) {            
                foreach ($site in $sites ) {
                    if (-not $firstSitePhysicalDirectory) { $firstSitePhysicalDirectory= $site.PhysicalDirectory}                    
                    $webConfigFile = Join-Path $site.PhysicalDirectory "Web.Config"
                    if (-not (Test-Path $webConfigFile)) {
                        '
<configuration>
    <system.web>
        <customErrors mode="Off"/>
    </system.web>
</configuration>                        
                        ' | Set-Content -path $webConfigFile                                                
                    }
                    
                }
            }
            $startupTasks = @(Select-Xml -Xml $ServiceDefinition -Namespace $xmlNamespace -XPath //ServiceDefinition:Task | 
                Select-Object -ExpandProperty Node)
        }
        
        
        $cscfgXml = [xml]@"
<ServiceConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" serviceName="$serviceName" xmlns="http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceConfiguration" osFamily='2' osVersion='*'>
  $RoleConfigChunk
</ServiceConfiguration>        
"@             
        
        
        $tempOutFile = Join-Path $env:Temp (Get-Random)

        Push-Location $workingDirectory
        $results = & $csPack $arguments 
        Pop-Location

        $errs =$results -like "*Error*:*"
        if ($errs) {
            foreach ($err in $errs) {
                Write-Error $err.Substring($err.IndexOf(":") + 1)
            }
            return
        }
        
        
        $csdef = $serviceDefinitionFile
        $cspkg = Join-Path $workingDirectory "$serviceName.cspkg"
        
        if (-not $outputPath) {        
            $serviceDeploymentRoot = "$psScriptRoot\AzureServices"
            if (-not (Test-Path $serviceDeploymentRoot)) {
                $null = New-Item -ItemType Directory -Path $serviceDeploymentRoot
            }
            
            $serviceDropDirectory = "$serviceDeploymentRoot\$serviceName"
            if (-not (Test-Path $serviceDropDirectory)) {
                $null = New-Item -ItemType Directory -Path $serviceDropDirectory
            }        

            $nowString = (Get-Date | Out-String).Trim().Replace(":", "-")
            $thisDropDirectory  =Join-Path $serviceDropDirectory $nowString 
            if (-not (Test-Path $thisDropDirectory)) {
                $null = New-Item -ItemType Directory -Path $thisDropDirectory
            }           
        } else {
            $unResolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputPath)
            if (-not (Test-Path $unResolvedPath)) {
                $newPath = New-Item -ItemType Directory $unResolvedPath
                if ($newPath) { 
                    $thisDropDirectory = "$newPath"
                }
            } else {
                $thisDropDirectory = "$unResolvedPath"
            }
            
        }
        
        
        #Move-Item -LiteralPath $cscfg -Destination "$thisDropDirectory"
        $cscfg = Join-Path $thisDropDirectory $configurationFile
        if (Test-Path $cscfg) { Remove-Item -Force $cscfg }
        $cscfgXml.Save("$cscfg")
        Move-Item -LiteralPath $csdef -Destination "$thisDropDirectory" -Force
        Move-Item -LiteralPath $cspkg -Destination "$thisDropDirectory" -Force                
        
        Remove-Item -Recurse -Force $workingDirectory
        Get-ChildItem $thisDropDirectory -Force               
    }
} 

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUIdSYbxRbufItj6xjYfjsIHMQ
# 8wmgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJr3zexgV/o0OgFa
# 88Zsuhhe81PRMA0GCSqGSIb3DQEBAQUABIIBAAg3dAGVQyw14j37/8mibhCS5WWQ
# 19wX/7IDQtNifSH8+zjTQsAGH+u1UMudRBTYKRaX1hVXTEiVwWuMVa0A7yImoIjY
# MobYj7+/PXq+x1wpgC8LH+mzQeZYneFGpZaxabutcHEQc2s39fJen0QNvDiWNOPp
# EmcEMOFckMUL7vfjtQiT99BI41ZvsqN9eVLaJjtXD0rP9lxjjTGi8VIaU+yPAxGe
# c6+tjUmwvIq4swvDtIb6fAHWz8yB/lzOfGjLWxTPd1t3w1VpOO0+aFjwpE/5+ohU
# NGZDckgaNnz5gloO7jdgC4z0gxL2vuf7Pj6aND4Ctn/ZRDagY0nhU9XJJ2Y=
# SIG # End signature block
