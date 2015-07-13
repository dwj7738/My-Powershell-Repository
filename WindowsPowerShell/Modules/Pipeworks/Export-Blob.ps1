function Export-Blob
{
    <#
    .Synopsis
        Exports data to a cloud blob
    .Description
        Exports data to a blob in Azure 
    .Example
        Get-ChildItem -Filter *.ps1 | Export-Blob -Container scripts -StorageAccount astorageAccount -StorageKey (Get-SecureSetting aStorageKey -ValueOnly)
    #>    
    param(
    [Parameter(ValueFromPipeline=$true)]
    [PSObject]
    $InputObject,

    # The name of the container
    [Parameter(Mandatory=$true,Position=0, ValueFromPipelineByPropertyName=$true)]
    [string]$Container,

    # The name of the blob
    [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
    [string]$Name,

    # The content type.  If a file is provided as input, this will be provided automatically.  If not, it will be text/plain
    [string]$ContentType = "text/plain",

    # The storage account
    [string]$StorageAccount,

    # The storage key
    [string]$StorageKey,

    # If set, the container the blob is put into will be made public
    [Switch]
    $Public
    )


    begin {


        if (-not $script:cachedContentTypes) {
            $script:cachedContentTypes = @{}
            $ctKey = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey("MIME\Database\Content Type")
            $ctKey.GetSubKeyNames() |
                ForEach-Object {
                    $extension= $ctKey.OpenSubKey($_).GetValue("Extension") 
                    if ($extension) {
                        $script:cachedContentTypes["${extension}"] = $_
                    }
                }

        }


$signMessage = {
    param(
    [Hashtable]$Header,
    [Uri]$Url,
    [Uint32]$ContentLength,
    [string]$IfMatch  ="",
    [string]$Md5OrContentType = "",
    [string]$NowString = [DateTime]::now.ToString("R", [Globalization.CultureInfo]::InvariantCulture),
    [Switch]$IsTableStorage,    
    [string]$method = "GET",
    [string]$Storageaccount,
    [string]$StorageKey
    )

    $method = $method.ToUpper()
    $MessageSignature = 
    if ($IsTableStorage) {
        [String]::Format("{0}`n`n{1}`n{2}`n{3}",@(
            $method,
            "application/atom+xml",
            $NowString,
            ( & $GetCanonicalizedResource $Url $StorageAccount)))

    } else {
        if ($md5OrCOntentType) {
            [String]::Format("{0}`n`n`n{1}`n`n{5}`n`n`n{2}`n`n`n`n{3}{4}", @(
                $method,
                $(if ($method -eq "GET" -or $method -eq "HEAD") {[String]::Empty} else { $ContentLength }),
                $IfMatch,
                "$(& $GetCanonicalizedHeader $Header)",
                "$( & $GetCanonicalizedResource $Url $StorageAccount)",
                $Md5OrContentType
                ));
        } else {
            [String]::Format("{0}`n`n`n{1}`n{5}`n`n`n`n{2}`n`n`n`n{3}{4}", @(
                $method,
                $(if ($method -eq "GET" -or $method -eq "HEAD") {[String]::Empty} else { $ContentLength }),
                $IfMatch,
                "$(& $GetCanonicalizedHeader $Header)",
                "$( & $GetCanonicalizedResource $Url $StorageAccount)",
                $Md5OrContentType
                ));
        }
        
    }    

    $SignatureBytes = [Text.Encoding]::UTF8.GetBytes($MessageSignature)

    [byte[]]$b64Arr = [Convert]::FromBase64String($StorageKey)
    $SHA256 = new-object Security.Cryptography.HMACSHA256 
    $sha256.Key = $b64Arr
    $AuthorizationHeader = "SharedKey " + $StorageAccount + ":" + [Convert]::ToBase64String($SHA256.ComputeHash($SignatureBytes))
    $AuthorizationHeader 
}

$GetCanonicalizedHeader = {
    param(
    [Hashtable]$Header
    )

    $headerNameList = new-OBject  Collections.ArrayList;
    $sb = new-object Text.StringBuilder;
    foreach ($headerName in $Header.Keys) {
        if ($headerName.ToLowerInvariant().StartsWith("x-ms-", [StringComparison]::Ordinal)) {
                $null = $headerNameList.Add($headerName.ToLowerInvariant());
        }
    }
    $null = $headerNameList.Sort();
    [Collections.Specialized.NameValueCollection]$headers =NEw-OBject Collections.Specialized.NameValueCollection    
    foreach ($h in $header.Keys) {
        $null = $headers.Add($h, $header[$h])
    }

    
    foreach ($headerName in $headerNameList)
    {
        $builder = new-Object Text.StringBuilder $headerName
        $separator = ":";
        foreach ($headerValue in (& $GetHeaderValues $headers $headerName))
        {
            $trimmedValue = $headerValue.Replace("`r`n", [String]::Empty)
            $null =  $builder.Append($separator)
            $null = $builder.Append($trimmedValue)
            $separator = ","
        }
        $null = $sb.Append($builder.ToString())
        $null = $sb.Append("`n")
    }
    return $sb.ToString()    
}


$GetHeaderValues  = {
    param([Collections.Specialized.NameValueCollection]$headers, $headerName)
    $list = new-OBject  Collections.ArrayList
    
    $values = $headers.GetValues($headerName)
    if ($values -ne $null)
    {
        foreach ($str in $values) {
            $null = $list.Add($str.TrimStart($null))
        }
    }
    return $list;
}

$GetCanonicalizedResource = {
    param([uri]$address, [string]$accountName)

    $str = New-object Text.StringBuilder
    $builder = New-object Text.StringBuilder "/" 
    $null = $builder.Append($accountName)
    $null = $builder.Append($address.AbsolutePath)
    $null = $str.Append($builder.ToString())
    $values2 = New-Object Collections.Specialized.NameValueCollection
    if (!$IsTableStorage) {
        $values = [Web.HttpUtility]::ParseQueryString($address.Query)
        foreach ($str2 in $values.Keys) {
            $list = New-Object Collections.ArrayList 
            foreach ($v in $values.GetValues($str2)) {
                $null = $list.add($v)
            }
            $null = $list.Sort();
            $builder2 = New-Object Text.StringBuilder
            foreach ($obj2 in $list)
            {
                if ($builder2.Length -gt 0)
                {
                    $null = $builder2.Append(",");
                }
                $null = $builder2.Append($obj2.ToString());
            }
            $valueName = if ($str2 -eq $null) {
                $str2 
            } else {
                $str2.ToLowerInvariant()
            }
            $values2.Add($valueName , $builder2.ToString())
        }
    }
    $list2 = New-Object Collections.ArrayList 
    foreach ($k in $values2.AllKeys) {
        $null = $list2.Add($k)
    }
    $null = $list2.Sort()
    foreach ($str3 in $list2)
    {
        $builder3 = New-Object Text.StringBuilder([string]::Empty);
        $null = $builder3.Append($str3);
        $null = $builder3.Append(":");
        $null = $builder3.Append($values2[$str3]);
        $null = $str.Append("`n");
        $null = $str.Append($builder3.ToString());
    }
    return $str.ToString();

}

        #$inputList = New-Object Collections.ArrayList
        $inputData = New-Object Collections.ArrayList

        if (-not $script:alreadyPublicContainers) {
            $script:alreadyPublicContainers = @{}
        }

        if (-not $script:knownContainers) {
            $script:knownContainers= @{}
        }
    }


    process {
        #$null = $inputList.Add($inputObject)
        $null = $inputData.Add((@{} + $psBoundParameters)) 
    }

    end {
        #region check for and cache the storage account
        if (-not $StorageAccount) {
            $storageAccount = $script:CachedStorageAccount
        }

        if (-not $StorageKey) {
            $StorageKey = $script:CachedStorageKey
        }

        if (-not $StorageAccount) {
            Write-Error "No storage account provided"
            return
        }

        if (-not $StorageKey) {
            Write-Error "No storage key provided"
            return
        }

        $script:CachedStorageAccount = $StorageAccount
        $script:CachedStorageKey = $StorageKey
        #endregion check for and cache the storage account
        foreach ($inputInfo in $inputData) {
            if ($inputInfo.Name) {
                $Name = $inputInfo.Name
            }

            if ($inputInfo.Container) {
                $Container = $inputInfo.Container
            }

            $InputObject = $inputInfo.InputObject
        
            $containerBlobList = $null
            $Container = "$Container".ToLower()
            if (-not $knownContainers[$Container]) {
                $method = 'GET'
                $uri = "http://$StorageAccount.blob.core.windows.net/${Container}?restype=container&comp=list&include=metadata"
                $header = @{
                    "x-ms-date" = $nowString 
                    "x-ms-version" = "2011-08-18"
                    "DataServiceVersion" = "2.0;NetFx"
                    "MaxDataServiceVersion" = "2.0;NetFx"

                }
                $header."x-ms-date" = [DateTime]::Now.ToUniversalTime().ToString("R", [Globalization.CultureInfo]::InvariantCulture)
                $nowString = $header.'x-ms-date'
                $header.authorization = . $signMessage -header $Header -url $Uri -nowstring $nowString -storageaccount $StorageAccount -storagekey $StorageKey -contentLength 0 -method GET
        
            
                $containerBlobList = Get-Web -UseWebRequest -Header $header -Url $Uri -Method GET -ErrorAction SilentlyContinue -ErrorVariable err -HideProgress

                if ($containerBlobList) {
                    $knownContainers[$Container] = $knownContainers[$Container]
                }
            }
        
            if (-not $containerBlobList) {
                # Tries to create the container if it's not found
                $method = 'PUT'
                $uri = "http://$StorageAccount.blob.core.windows.net/${Container}?restype=container"

                $header = @{
                    "x-ms-date" = $nowString 
                    "x-ms-version" = "2011-08-18"
                    "DataServiceVersion" = "2.0;NetFx"
                    "MaxDataServiceVersion" = "2.0;NetFx"

                }
                $header."x-ms-date" = [DateTime]::Now.ToUniversalTime().ToString("R", [Globalization.CultureInfo]::InvariantCulture)
                $nowString = $header.'x-ms-date'
                $header.authorization = . $signMessage -header $Header -url $Uri -nowstring $nowString -storageaccount $StorageAccount -storagekey $StorageKey -contentLength 0 -method PUT
                $result = 
                    try {
                        Get-Web -UseWebRequest -Header $header -Url $Uri -Method PUT -HideProgress                 
                    } catch {
                        $_
                    }
            
            }
        

            if ($Public -and -not $script:alreadyPublicContainers[$Container]){
                
                # Enables public access to the container
                $acl =@"
<?xml version="1.0" encoding="utf-8"?>
  <SignedIdentifiers>
    <SignedIdentifier>
        <Id>Policy1</Id>
        <AccessPolicy>
        <Start>2011-01-01T09:38:05Z</Start>
        <Expiry>2011-12-31T09:38:05Z</Expiry>
        <Permission>r</Permission>
    </AccessPolicy>
   </SignedIdentifier>
   <SignedIdentifier>
     <Id>Policy2</Id>
       <AccessPolicy>
           <Start>2010-01-01T09:38:05Z</Start>
           <Expiry>2012-12-31T09:38:05Z</Expiry>
           <Permission>r</Permission>
       </AccessPolicy>
   </SignedIdentifier>
</SignedIdentifiers>
"@
        
                $aclBytes= [Text.Encoding]::UTF8.GetBytes("$acl")    
                $method = 'PUT'
                $uri = "http://$StorageAccount.blob.core.windows.net/${Container}?restype=container&comp=acl"
                $header = @{
                    "x-ms-date" = $nowString 
                    "x-ms-version" = "2011-08-18"
                    "x-ms-blob-public-access" = "container"
                    "DataServiceVersion" = "2.0;NetFx"
                    "MaxDataServiceVersion" = "2.0;NetFx"
                    'content-type' = $ct 
                }
                $header."x-ms-date" = [DateTime]::Now.ToUniversalTime().ToString("R", [Globalization.CultureInfo]::InvariantCulture)
                $nowString = $header.'x-ms-date'
                $ct ='application/x-www-form-urlencoded'
                $header.authorization = & $signMessage -header $Header -url $Uri -nowstring $nowString -storageaccount $StorageAccount -storagekey $StorageKey -contentLength $aclBytes.Length -method PUT  -md5OrContentType $ct 
                $Created = Get-Web -UseWebRequest -Header $header -Url $Uri -Method PUT -RequestBody $aclBytes -ErrorAction SilentlyContinue 
                $script:alreadyPublicContainers[$Container] = $Container

            
            }


            $uri = "http://$StorageAccount.blob.core.windows.net/$Container/$Name"


            # Turn our input into bytes
            if ($InputObject -is [IO.FileInfo]) {
                $bytes = [io.fIle]::ReadAllBytes($InputObject.Fullname)
                $extension = [IO.Path]::GetExtension($InputObject.Fullname)
                $mimeType = $script:CachedContentTypes[$extension]
                if (-not $mimeType) {
                    $mimetype = "unknown/unknown"
                }
            } elseif ($InputObject -as [byte[]]) {
                $bytes = $InputObject -as [byte[]]
            } else {
                $bytes = [Text.Encoding]::UTF8.GetBytes("$InputObject")
            }

            if (-not $mimetype) {
                $mimeType = $ContentType
            }

            $method = 'PUT'
            $header = @{
                'x-ms-blob-type' = 'BlockBlob'
                "x-ms-date" = $nowString 
                "x-ms-version" = "2011-08-18"
                "DataServiceVersion" = "2.0;NetFx"
                "MaxDataServiceVersion" = "2.0;NetFx"
                'content-type' = $mimeType 
            }
            $header."x-ms-date" = [DateTime]::Now.ToUniversalTime().ToString("R", [Globalization.CultureInfo]::InvariantCulture)
            $nowString = $header.'x-ms-date'
            $header.authorization = . $signMessage -header $Header -url $Uri -nowstring $nowString -storageaccount $StorageAccount -storagekey $StorageKey -contentLength $bytes.Length -method PUT -md5OrContentType $mimeType
        
        
            $blobData= Get-Web -UseWebRequest -Header $header -Url $Uri -Method PUT -RequestBody $bytes -ContentType $mimeType 
        }
    }
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUp3gNRZ/qwT7Tzn8fKmHPcYqY
# m8+gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAuub81YX/qz//kB
# AxvNfaaWFPNnMA0GCSqGSIb3DQEBAQUABIIBACwR+kFC3SGacCjGdLkezEYgypJz
# Hh/TVslpGj8ACPmThPCepibvSmVOJVIbZpgv6LW8IjCZzIREd3/CvvejNCUanwhf
# vqCLFRWfFZPzO5nQVwlLeVc8jVIZ9apavoqJlmDxmeoIsYZnrsjB6s+dIFlSY+AF
# fDwUgZJElcKn8II2Gkpz4MZl9TgJ0g1opYYsxxvMLkErMLcNE/GM1HKddDQiru3P
# 2FOKoF1Du/qrEmaBKubfozljIMqpDBAz5P/jiMygxy9hUxGkKMbZYVdST+bHzS+I
# lpY9uGXSKvTZ7cX5cyYd1nRbuNICs72xbk+T0N+0Rlh81mmousHas5WiM3A=
# SIG # End signature block
