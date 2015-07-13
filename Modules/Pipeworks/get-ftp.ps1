function Get-FTP
{
    <#
    .Synopsis
        Gets files from FTP
    .Description
        Lists files on an FTP server, or downloads files
    .Example
        Get-FTP -FTP "ftp://edgar.sec.gov/edgar/full-index/1999/" -Download -Filter "*.idx", "*.xml" 
    #>
    param(
    # The url 
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [Uri]$Ftp,

    # The credential used to connect to FTP.  If not provided, will connect anonymously.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSCredential]
    $Credential,

    # If set, will download files instead of discover them
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]$Download,

    # The download path (by default, the downloads directory)
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [string]$DownloadPath = "$env:UserProfile\Downloads",

    # If provided, will only download files that match the filter
    [Parameter(ValueFromPipelineByPropertyName=$true,Position=1)]
    [string[]]$Filter,

    # If set, will download files that already have been downloaded and have the exact same file size.
    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [Switch]$Force
    )

    begin {
        
        $folders = New-Object "system.collections.generic.queue[string]"
        function GetFtpStream($url, $method, $cred) {
                $ftp = [System.Net.WebRequest]::Create($url)
                if ($Credential)  {
                    $ftp.Credentials = $Credential.GetNetworkCredential()
                }
                $ftp.Method = $method
                $response = $ftp.GetResponse()
                  
                return New-Object IO.StreamReader $response.GetResponseStream()

        }
        function Get-FTPFile ($Source,$Target,$UserName,$Password) 
        { 
             $ftprequest = [System.Net.FtpWebRequest]::create($Source) 
             if ($Credential) {
                $ftprequest.Credentials = $Credential.GetNetworkCredential()
             }
             $ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile 
             $ftprequest.UseBinary = $true 
             $ftprequest.KeepAlive = $false 
      
             $ftpresponse = $ftprequest.GetResponse() 
             $responsestream = $ftpresponse.GetResponseStream() 
             if (-not $responsestream) { return  } 
      
             $targetfile = New-Object IO.FileStream ($Target,[IO.FileMode]::Create) 
             [byte[]]$readbuffer = New-Object byte[] 1024 
      
             do{ 
                 $readlength = $responsestream.Read($readbuffer,0,1024) 
                 $targetfile.Write($readbuffer,0,$readlength) 
             } 
             while ($readlength -ne 0) 
      
             $targetfile.close() 
        }
    }
    process {
        $null = $folders.Enqueue("$ftp")
        while($folders.Count -gt 0){
            $fld = $folders.Dequeue()
        
            $newFiles = New-Object "system.collections.generic.list[string]"
            $newDirs = New-Object "system.collections.generic.list[string]"
            $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        
            $reader = GetFtpStream $fld $operation
    
            while (($line = $reader.ReadLine()) -ne $null) {
               [void]$newFiles.Add($line.Trim()) 
            }
            $reader.Dispose()


            $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
            $reader = GetFtpStream $fld $operation
    
            while (($line = $reader.ReadLine()) -ne $null) {
               [void]$newDirs.Add($line.Trim()) 
            }
            $reader.Dispose()
    
                
            foreach ($d in $newDirs) {
                $parts = ($d -split " " -ne '')
                if ($parts[4] -eq 4096 -or $parts[4] -eq 0) {
                    $newName = $parts[-1]
                    Write-Verbose "Enqueing Folder $($fld + $newName  + "/")"
                    $null = $folders.Enqueue($fld + $newName + "/")
                } else {
                    $updatedAt = $parts[-4..-2] -join ' ' -as [datetime]
                    
                    if (-not $updatedAt) { continue } 
                    $out = 
                        New-Object PSObject -Property @{
                            Ftp = $fld + $parts[-1]                        
                            Size = $parts[4]
                            UpdatedAt = $updatedAt
                        }

                    if ($filter) {
                        $matched = $false
                        foreach ($f in $filter) {
                            if ($parts[-1] -like "$f") {
                                $matched  = $true
                                break
                            }
                        }
                        if (-not $matched) {
                            continue
                        }
                    }
                    if ($download -or $psBoundParameters.DownloadPath) {
                        
                        $folderUri = [uri]($fld + $parts[-1])
                        
                        $downloadTo = Join-Path $DownloadPath $folderUri.LocalPath
                        $downloadDir  = Split-Path $downloadTo 
                        if (-not (Test-Path $downloadDir)) {
                            $null = New-Item -ItemType Directory $downloadDir
                        }

                        $item = Get-Item -Path $downloadTo -ErrorAction SilentlyContinue
                        if (($item.Length -ne $parts[4]) -or $Force) {
                            Get-FtpFile -Source $folderUri -Target $downloadTo                                                         
                        }
                        if (Test-Path $downloadTo) {
                            Get-Item $downloadTo
                        }
                        
                    } else {

                        $out
                    }
                    
                }
            }
            
        }
    }
}



# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUQfBzHPXKdYS/SGL17gWmnJw
# lH2gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKfkNz1zFYzATqx7
# WwYLmnI5kYVOMA0GCSqGSIb3DQEBAQUABIIBAEYtdP9pr1qdFhKaOAVO2LswUpWZ
# 3ZpLI35t3tWZmwyoyIohHEkueUYObp8Y6bub29yzzQIbhQk+8+5pQWArKnNjIlDr
# +PrC5br0BLpN/bzWKDTHGek5Kbk7Gkaw0TWaH9v8r5obpGQtZpwifPStrizKCowg
# I1/RTlFt00CsYLr500q4YEyPE/QLD2U29MXX0CimYs+K8jx7IjBAIfSDVzvwSfhi
# F98fQ6ep1/92Zv4JrUA02BASBTV3wx14GE/0rx4cFXCCAG7xdNImpf/3El7odflF
# Da1LNFoGPrZNAnLQe0uvk7di+Pk7HAX4wSUG4qsnpntCcxsL9r0qN+85MHA=
# SIG # End signature block
