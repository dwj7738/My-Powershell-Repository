function Add-AzureWebSite
{
    <#
    .Synopsis
        Adds an Azure web site to a service definition.
    .Description
        Adds an Azure web site to a service definition.  
        
        The site can bind to multiple host
        
        Creates a web role if one does not exist.                
    .Example
        New-AzureServiceDefinition -ServiceName "AService" |
            Add-AzureWebSite -SiteName "ASite" -PhysicalDirectory "C:\inetpub\wwwroot\asite" -HostHeader a.subdomain.com, nakeddomain.com, www.fulldomain.com -asString
    .Link
        New-AzureServiceDefinition
    #>
    [OutputType([xml],[string])]
    param(    
    # The ServiceDefinition XML.  This should be created with New-AzureServiceDefinition or retreived with Import-AzureServiceDefinition
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

    # If set, the local resource will only apply to the role named ToRole.  If ToRole is not found, or doesn't
    # exist, the last role will be used.
    [Parameter(ValueFromPipelineByPropertyName=$true)]        
    [string]
    $ToRole,
    
    # The name of the site to create. If Sitename is not set, sites will be named Web1, Web2, Web3, etc    
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $SiteName,
    
    # The physical directory of the website.  This is where the web site files are located.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]
    $PhysicalDirectory,            
    
    # One or more host headers to use for the site
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string[]]
    $HostHeader,
    
    # Additional bindings.  Each hashtable can contain an EndpointName, Name, and HostHeader
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Hashtable[]]
    [ValidateScript({
        Test-SafeDictionary -Dictionary $_ -ThrowOnUnsafe
    })]
    $Binding,
    
    # Additional virtual directories.  
    # The keys will be the name of the virtual directories, and the values will be the physical directory on
    # the local machine.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Hashtable]
    [ValidateScript({
        Test-SafeDictionary -Dictionary $_ -ThrowOnUnsafe
    })]
    $VirtualDirectory,
    
    # Additional virtual applications.  
    # The keys will be the name of the virtual applications, and the values will be the physical directory on
    # the local machine.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Hashtable]
    [ValidateScript({
        Test-SafeDictionary -Dictionary $_ -ThrowOnUnsafe
    })]    
    $VirtualApplication,   
    
    # The VMSize
    [ValidateSet('ExtraSmall','Small','Medium', 'Large', 'Extra-Large', 'XS', 'XL', 'S', 'M', 'L')]
    $VMSize,
    
    # If set, will return values as a string
    [switch]
    $AsString
    )
    
    begin {
        $xmlNamespace = @{'ServiceDefinition'='http://schemas.microsoft.com/ServiceHosting/2008/10/ServiceDefinition'}                
        if (-not $script:siteCount) {$script:SiteCount  = 0}
    }
    
    process {        
     
        $script:siteCount++
        # Resolve the role if it set, create the role if it doesn't exist, and track it if they assume the last item.
        $roles = @($ServiceDefinition.ServiceDefinition.WebRole), @($ServiceDefinition.ServiceDefinition.WorkerRole) +  @($ServiceDefinition.ServiceDefinition.VirtualMachineRole)
        
        $selectXmlParams = @{
            XPath = '//ServiceDefinition:WebRole'
            Namespace = $xmlNamespace
        }        
        $roles = @(Select-Xml -Xml $ServiceDefinition @selectXmlParams | 
            Select-Object -ExpandProperty Node)
        if (-not $roles) {
            $params = @{}
            if ($vmSize) { $params['vmSize']= $vmSize}
            $ServiceDefinition = $ServiceDefinition | 
                Add-AzureRole -RoleName "WebRole1" @params
                
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
        
        $realSize = [Math]::Ceiling($size / 1mb)
        
        if (-not $role.Sites) {
            $role.InnerXml += "<Sites/>"
        }
        
        $sitesNode = Select-Xml -Xml $role -Namespace $xmlNamespace -XPath '//ServiceDefinition:Sites' |
            Select-Object -ExpandProperty Node
        if (-not $siteName) { 
            if ($physicalPath) {
                $SiteName = "WebSite${siteCount}"
            } else {
                $SiteName = "Web${siteCount}"
            }
            
        }
        
        if ($PhysicalDirectory) {   
            $translatedPhysicalPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PhysicalDirectory)
            $sitesNode.InnerXml += "<Site name='$SiteName' physicalDirectory='$translatedPhysicalPath' />"
        } else {
            $sitesNode.InnerXml += "<Site name='$SiteName' />"
        }
        
        $siteNode = Select-Xml -Xml $sitesNode -Namespace $xmlNamespace -XPath "//ServiceDefinition:Site"|
            Where-Object { $_.Node.Name -eq $siteName } | 
            Select-Object -ExpandProperty Node -Last 1
                
        
        if ($psBoundParameters.VirtualDirectory)
        {
            foreach ($kv in $psBoundParameters.VirtualDirectory.GetEnumerator()) {
                $siteNode.InnerXml += " <VirtualDirectory name='$($kv.Key)' physicalDirectory='$($kv.Value)' />"
                $role.Sites.InnerXml  = $sitesNode.InnerXml.Replace('xmlns=""', '')
            }
        }
        
        if ($psBoundParameters.VirtualApplication) {
            foreach ($kv in $psBoundParameters.VirtualApplication.GetEnumerator()) {
                $siteNode.InnerXml += " <VirtualApplication name='$($kv.Key)' physicalDirectory='$($kv.Value)' />"
                $role.Sites.InnerXml  = $sitesNode.InnerXml.Replace('xmlns=""', '')
            }
        }
        
        $usedDefaultEndPoint = $false
        if (-not $role.Endpoints) {
            $usedDefaultEndPoint = $true
            $role.InnerXml += "<Endpoints><InputEndpoint name='DefaultWebSiteEndPoint' protocol='http' port='80' />
            </Endpoints>"
        }
        
        $specifiesBindingEndPoint = $false
        
        if ((-not $psBoundParameters.Binding) -and (-not $psBoundParameters.HostHeader)) {
            $endpointsNode = Select-Xml -Xml $role -Namespace $xmlNamespace -XPath "//ServiceDefinition:Endpoints"|
                Select-Object -ExpandProperty Node
        
            $endPointName = @($endPointsNode.InputEndPoint)[-1].Name
            
            $siteNode.InnerXml += "<Bindings><Binding endpointName='$endPointName' name='Binding1' /></Bindings>"            
            $role.Sites.InnerXml  = $sitesNode.InnerXml.Replace('xmlns=""', '')
        }
        
        if ($psBoundParameters.Binding) {
            $bindings = foreach ($ht in $psBoundParameters.Binding) {
                $bindingXmlText = "<Binding"
                foreach ($kv in $ht.GetEnumerator()) {
                    if ($kv.Key -eq 'EndpointName') {
                        $attributeName = 'endpointName'
                        $specifiesBindingEndPoint = $true                        
                    } elseif ($kv.Key -eq 'Name') {
                        $attributeName = 'name'
                    } elseif ($key.Key -eq 'HostHeader') {
                        $attributeName = 'hostHeader'
                    }
                    if ($attributeName){
                        $bindingXmlText+= " $attributeName='$($kv.Value)'"
                    }
                }
                "$bindingXmlText />"      
            }
            
            $ofs = [Environment]::NewLine
            $siteNode.InnerXml += "<Bindings>$bindings</Bindings>"    
            $role.Sites.InnerXml  = $sitesNode.InnerXml.Replace('xmlns=""', '')
         
        }
        
        if ($psBoundParameters.HostHeader) {
            $endpointsNode = Select-Xml -Xml $role -Namespace $xmlNamespace -XPath "//ServiceDefinition:Endpoints"|
                Select-Object -ExpandProperty Node

            $endPointName = @($endPointsNode.InputEndPoint)[-1].Name
            
            $bindingCount = 1
            $bindings = foreach ($header in $psBoundParameters.HostHeader) {
                "<Binding endpointName='$endPointName' name='Binding${BindingCount}' hostHeader='$header'/>"
            }
            $ofs = [Environment]::NewLine
            if ($siteNode.InnerXml)  {
                 $siteNode.InnerXml += "<Bindings>$bindings</Bindings>" 
            } else {
                 $siteNode.InnerXml = "<Bindings>$bindings</Bindings>" 
            }
            $role.Sites.InnerXml  = $sitesNode.InnerXml.Replace('xmlns=""', '')         
            
        }                                               
    }
    
    end {
        $webRole= Select-Xml -Xml $role -Namespace $xmlNamespace -XPath '//ServiceDefinition:WebRole' |
            Select-Object -ExpandProperty Node
            

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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6yWbnSh1TRn+OaXRnZ8WdqoQ
# +GagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDyfGFCSO51VLVNj
# uogMIBFaxfLrMA0GCSqGSIb3DQEBAQUABIIBABYPK+mH+TsGFF/LXhAt6IBuzs/b
# J+9C6zKgsqAOIBQAsEZrB7dZhb0C5iNCP4JNsPPA2VVYJBb6f+txcDtuXZFw+ZAm
# cY1P/NEPAsKyocfNvrRoiXjLDBWxVpEK5WVFBa7RWy01GJmZ8DFHmlU9hGWkO86L
# /o2PsS6ilCVFIfcbHzu4rNznynpaXIhffL1fNGpszhl7N15aN/oqJtVCVgq25QTE
# K4N4ynIvQbPQw0kaPrclPGftLcT/ofYkv0DH1XYauJpl2OGmRMhFZp1VK12Ui40W
# 01pDIBNBoVL4OnZztGjbgnWpABP3O0nOeEP1LbL5S54aqwaPyUA9Zqw7aVw=
# SIG # End signature block
