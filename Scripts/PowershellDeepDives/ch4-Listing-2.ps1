[cmdletbinding()]
Param (
    [parameter(Mandatory=$True)]
    [string]$Computername,
    [Int]$Port = 389
)

Try {
    #Create client and connect to Domain Controller
    $tcpClient = New-Object System.Net.Sockets.TCPClient
    $tcpClient.Connect($Computername,$Port)

    #If connection was successful, proceed with the bind request
    If ($tcpClient.Connected) {
        #Create LDAP packet payloads
        [byte[]]$bindRequest = 0x30,0x84,0x00,0x00,0x00,0x10,0x02,0x01,
        0x01,0x60,0x84,0x00,0x00,0x00,0x07,0x02,0x01,0x02,0x04,0x00,0x80,0x00
        [byte[]]$searchRequest = 0x30,0x84,0x00,0x00,0x00,0x2d,0x02,0x01,
        0x02,0x63,0x84,0x00,0x00,0x00,0x24,0x04,0x00,0x0a,0x01,0x00,0x0a,
        0x01,0x00,0x02,0x01,0x00,0x02,0x01,0x00,0x01,0x01,0x00,0x87,0x0b,0x6f,
        0x62,0x6a,0x65,0x63,0x74,0x63,0x6c,0x61,0x73,0x73,0x30,0x84,0x00,0x00,0x00,0x00
        [byte[]]$unbindRequest = 0x30,0x84,0x00,0x00,0x00,0x05,0x02,0x01,0x03,0x42,0x00

        #hard coded buffer at 22 bytes because this what should be expected from the Domain Controller after the bind request
        $bindResponseBuffer = New-Object Byte[] -ArgumentList 1024 

        #Get the client stream
        $stream = $TcpClient.GetStream()

        #Send the bind request stream to the Domain Controller and flush the stream
        $stream.Write($bindRequest,0,$bindRequest.length)
        $stream.Flush()
            
        #Let the data buffer
        Start-Sleep -Milliseconds 1000            
    
        #If response packet from the Domain Controller is 22 bytes, then we know that the bind was successful and can proceed
        If ($tcpClient.Available -eq 22) {
            Try {
                #Get for response from Domain Controller
                [Int]$response = $stream.Read($bindResponseBuffer, 0, $bindResponseBuffer.count)        
                        
                #Send the search request stream to the Domain Controller and flush the stream
                $stream.Write($searchRequest,0,$searchRequest.length)
                $stream.Flush()
            
                #Let the data buffer
                Start-Sleep -Milliseconds 1000
                $availableBytes = $tcpClient.Available
                $searchResponse = $Null
                [int]$response = 0            
                Do {                
                    $searchResponseBuffer = New-Object Byte[] -ArgumentList 1024
                    #Get for response from Domain Controller
                    [Int]$response = $response + $stream.Read($searchResponseBuffer, 0, $searchResponseBuffer.count)
                    [byte[]]$searchResponse += $searchResponseBuffer
                    Write-Progress -Activity ("Downloading LDAP Response from {0}" -f $Computername) -Status ("Bytes Received: {0}" -f ($response)) `
                                   -PercentComplete (($response / $availableBytes)*100) -Id 0
                } While ($stream.DataAvailable)
            
                #Send the unbind request stream to the Domain Controller and flush the stream
                Try {
                    $stream.Write($unbindRequest,0,$unbindRequest.length)
                    $stream.Flush()   
                } Catch {
                    #Sometimes the unbind request fails for an unknown reason
                    Write-Warning ("Line: {0} -> {1}" -f $_.invocationInfo.ScriptLineNumber,$_.Exception.Message)            
                } 
            
                ##Begin the decoding of the LDAP packet
                #Build Memory and Binary Stream readers
                $MemoryStream = new-object System.IO.MemoryStream -ArgumentList $searchResponse[0..$availableBytes],0,$availableBytes
                $binaryReader = new-object System.IO.BinaryReader -ArgumentList $MemoryStream

                #Strip out the Parser Header
                $binaryReader.ReadBytes(6) | Out-Null

                #Strip out the Message ID
                $binaryReader.ReadBytes(3) | Out-Null

                #Strip out the Operational Header
                $binaryReader.ReadBytes(6) | Out-Null

                #Strip out the Object Name as it is Null
                $binaryReader.ReadBytes(2) | Out-Null

                #Strip out the Sequence Header
                $binaryReader.ReadBytes(6) | Out-Null

                [byte[]]$bytes = $Null

                $isHeader = $True
                $isPropertyHeader = $True

                #Build an object for future use
                $Object = New-Object PSObject

                Do {
                    Write-Verbose ("Begin of Do: {0}" -f ($binaryReader.BaseStream.Position -eq $binaryReader.BaseStream.Length))
                    If ($isHeader) {
                        Write-Verbose ("Removing Header information")
                        #Strip out the Header
                        $binaryReader.ReadBytes(6) | Out-Null
                        $isHeader = $False
                    } Else {
                        If ($binaryReader.ReadByte() -eq 0x04) {
                            #Get expected bytes
                            $expectedBytes = $binaryReader.ReadByte()
                            [byte[]]$bytes += $binaryReader.ReadBytes($expectedBytes)
                        }
                        If ($isPropertyHeader) {
                            Try {
                                Write-Verbose ("Reached the end of the Property Header")
                                $propertyHeader = [System.Text.Encoding]::ASCII.GetString($bytes)
                            } Catch {}
                            $isPropertyHeader = $False
                            #Strip out header
                            $isHeader = $True   
                            $bytes = $Null                     
                        } Else {
                            #Check to see if there are no more attribute properties left
                            If ($binaryReader.PeekChar() -eq 0x30) {
                                Try {
                                    Switch ($propertyHeader) {
                                        "currentTime" {
                                            $time = ([System.Text.Encoding]::ASCII.GetString($bytes) -split "\.")[0]                                            
                                            $property = [datetime]::ParseExact($time,'yyyyMMddHHmmss',$Null)
                                        }
                                        Default {
                                            $property = [System.Text.Encoding]::ASCII.GetString($bytes)
                                            If ($Property -match "\t") {
                                                $property = $property -split "\t"
                                            }
                                        }
                                    }
                                    Write-Verbose ("Reached the end of the Property")                                                                   
                                    #Add the property header and property to the existing object
                                    $Object = Add-Member -InputObject $Object -MemberType NoteProperty -Name $propertyHeader -Value $property -PassThru 
                                } Catch {}
                                $isPropertyHeader = $True
                                $isHeader = $True
                                $bytes = $Null
                            } Else {
                                #Add a tab delimitter so this can be split into an array
                                [byte[]]$bytes += 0x09
                            }
                        }
                    }
                    Write-Verbose ("Reached end of Do Statement")
                    Write-Progress -Activity "Formatting LDAP Response" `
                                    -Status ("Bytes Remaining: {0}" -f ($binaryReader.BaseStream.Length - $binaryReader.BaseStream.Position)) `
                                    -PercentComplete (($binaryReader.BaseStream.Position / $binaryReader.BaseStream.Length)*100) -Id 1
                    Write-Verbose ("End of Stream: {0}" -f ($binaryReader.BaseStream.Position -eq $binaryReader.BaseStream.Length))
                } Until ($binaryReader.BaseStream.Position -eq $binaryReader.BaseStream.Length)
            
                #Add a typename for this object
                $object.pstypenames.insert(0,'Net.TCP.LDAPMessage')
                Write-Output $Object               
            } Catch {
                Write-Warning ("Line: {0} -> {1}" -f $_.invocationInfo.ScriptLineNumber,$_.Exception.Message)            
            }
        } Else {
            Write-Warning ("Bind was unsuccessful with {0} on port {1}!" -f $Computername, $port)
        }
        #Close everything up
        $stream.Close(1)
        $TcpClient.Close()
    } Else {
        Write-Warning ("{0}: LDAP Connection Failed!" -f $Computername)
    }
} Catch {
    Write-Warning ("{0}: {1}" -f $Computername, $_.Exception.Message)
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaIMGrpAPF8+TCpnjzAK83AXL
# FXegggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPDucD4rYv+UJ9PV
# 7lsPLEuw3LQ/MA0GCSqGSIb3DQEBAQUABIIBALmKiT0Y14agYMDYlSpK3EHNkDOL
# vthCEZ9K1qrsZ5XdCL2zoJeMxoaqUzLKIdq8aiTwMBnke+p5bPi9JhbRjsxDm5l7
# HlNvJ/LamRnqFZlCiiYNu3KK1PeLVxwRneVpLPytVaau1YqqXIdmLb7nZRuYE+PK
# uNb+hHSlKgm3VEBGWq1XEcfyXVYHcgpzhLPRpkrF5R04ZuUMq9mxmkdseGVRL4f9
# tUsbOUKTUqjqCCRahyqXD3XI/17JOPynteDC0GWW8HXO5HSqokxzXyy2igdGCGnO
# CeWrq018Md4J88PWRfjfx4jVI/i4EC4bZ3fsCF28LrMEtRNqBHQC8I++r1M=
# SIG # End signature block
