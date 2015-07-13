function Get-Person
{
    <#
    .Synopsis
        Gets information about a person
    .Description
        Gets account information about a person.
        
        
        
        Get-Person contains the common tools to get user information from users on:
            - Active Directory
            - Azure Tables 
            - Facebook
            - Local Directory
    .Example
        Get-Person -UserTable SuppliUsUsers -Name "James Brundage" -UserPartition Users 
    .Example
        Get-Person -Local "James Brundage"
    #>
    [CmdletBinding(DefaultParameterSetName='Alias')]

    param(
    # The account alias or UserID
    [Parameter(Mandatory=$true,
        ParameterSetName='Alias',
        ValueFromPipelineByPropertyName=$true)]
    [Alias('MailNickname', 'UserID', 'SamAccountName')]
    [string]$Alias,
    
    # If provided, will get a list of properties from the user
    [string[]]$Property,
    

    # If set, will look for local accounts
    [Switch]$IsLocalAccount,

    # The account name
    [Parameter(Mandatory=$true,
        ParameterSetName='Name',
        ValueFromPipelineByPropertyName=$true)]
    [string]$Name,

    # The table in Azure that stores user information.  If provided, will search for accounts in Azure
    [string]$UserTable,
    
    # The parition within a table in Azure that should have user information.  Defaults to "Users"
    [string]$UserPartition = "Users",
    
    # The storage account.  If not provided, the StorageAccountSetting will be used
    [string]$StorageAccount,
    
    # The storage key.  If not provided, the StorageKeySetting will be used
    [string]$StorageKey,
    
    # The storage account setting.  This setting will be found with either Get-SecureSetting or Get-WebConfigurationSetting. Defaults to AzureStorageAccountName.
    [string]$StorageAccountSetting = "AzureStorageAccountName",
    
    # The storage key setting.  This setting will be found with either Get-SecureSetting or Get-WebConfigurationSetting.  Defaults to AzureStorageAccountKey
    [string]$StorageKeySetting = "AzureStorageAccountKey",
    
    # A facebook access token
    [Parameter(Mandatory=$true,ParameterSetName='FacebookAccessToken',ValueFromPipelineByPropertyName=$true)]

    [string]$FacebookAccessToken,


    # A Live ID Access Token
    [Parameter(Mandatory=$true,ParameterSetName='LiveIDAccessToken',ValueFromPipelineByPropertyName=$true)]
    [string]$LiveIDAccessToken,
    
    [Parameter(ParameterSetName='FacebookAccessToken',ValueFromPipelineByPropertyName=$true)]
    [Alias('ID')]
    [string]$FacebookUserID
    )

    begin {
        $beginProcessingEach = {
            $propertyMatch = @{}
            foreach ($prop in $property) {
                if (-not $prop) { continue } 
                $propertyMatch[$prop] = $prop
            }   
        }
        $processEach = {
            if ($OnlyBasicInfo) {
                $sortedKeys = "displayname", "Title,", "company", "department", "mail", "telephoneNumber", "physicaldeliveryofficename", "cn", "gn", "sn", "samaccountname", "thumbnailphoto" 
            } else {
                if ($in.Properties.Keys) {
                    $sortedKeys = $in.Properties.Keys | Sort-Object
                } elseif ($in.Properties.PropertyNames) {
                    $sortedKeys = $in.Properties.PropertyNames| Sort-Object                
                }
            }
            
            $personObject = New-Object PSObject
            $personObject.pstypenames.clear()
            $personObject.pstypenames.Add("http://schema.org/Person")           
            
            
            foreach ($s in $sortedKeys) {
                $unrolledValue = foreach($_ in $in.Properties.$s)  { $_} 
                $noteProperty = New-Object Management.Automation.PSNoteProperty $s, $unrolledValue
                if (-not $propertyMatch.Count) {
                    $null = $personObject.psObject.Properties.Add($noteProperty)                
                } elseif ($propertyMatch[$s]) {
                    $null = $personObject.psObject.Properties.Add($noteProperty)
                }
                
                #Add-Member -MemberType NoteProperty -InputObject $personObject -Name $s -Value $unrolledValue
            }
            
            $personObject
        }
    }

    process {
       
       if ($userTable -and $UserPartition) {
            $storageParameters = @{}
            if ($storageAccount) {
                $storageParameters['StorageAccount'] =$storageAccount
            } elseif ($storageAccountSetting) {
                if ((Get-SecureSetting "$storageAccountSetting" -ValueOnly)) {
                    $storageParameters['StorageAccount'] =(Get-SecureSetting "$storageAccountSetting" -ValueOnly)
                } elseif ((Get-WebConfigurationSetting -Setting "$storageAccountSetting")) {
                    $storageParameters['StorageAccount'] =(Get-WebConfigurationSetting -Setting "$storageAccountSetting")
                }
            }
            
            if ($storageKey) {
                $storageParameters['StorageKey'] =$storageKey
            } elseif ($StorageKeySetting) {
                if ((Get-SecureSetting "$storagekeySetting" -ValueOnly)) {
                    $storageParameters['Storagekey'] =(Get-SecureSetting "$storagekeySetting" -ValueOnly)
                } elseif ((Get-WebConfigurationSetting -Setting "$storagekeySetting")) {
                    $storageParameters['Storagekey'] =(Get-WebConfigurationSetting -Setting "$storagekeySetting")
                }
            }
        }
        
        
        
        $parameters= @{} + $psBoundParameters
        if ($pscmdlet.ParameterSetName -eq 'Alias') {
            
            if ($credential) {
                if (-not $exchangeserver) {
                    $exchangeServer = "http://ps.outlook.com/Exchange"
                }
            } elseif ($userTable -and $UserPartition) {                                                                
                Search-AzureTable @storageParameters -TableName $userTable -Filter "PartitionKey eq '$userPartition'" |
                    Where-Object { $_.UserEmail -eq $alias }            
            } elseif (((Get-WmiObject Win32_ComputerSystem).Domain -ne 'WORKGROUP') -and (-not $IsLocalAccount)) {
                if (-not $script:DomainList) {
                    $script:DomainList= 
                        [DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Domains | 
                            Select-Object -ExpandProperty Name

                }         
                
                foreach ($d in $script:domainList) {
                    if (-not $d) { continue } 
                    $searcher = New-Object DirectoryServices.DirectorySearcher ([ADSI]"LDAP://$d")
                    
                    $searcher.Filter = "(&(objectCategory=person)(samaccountname=$alias))"
                    $searcher.SearchScope = "Subtree"
                    . $beginProcessingEach
                    foreach ($in in $searcher.FindAll()) {
                        . $processEach 
                    }
                }
                
            } else {                
                $all = 
                    ([ADSI]"WinNT://$env:computerName,computer").psbase.Children |
                        Where-Object {
                            $_.SchemaClassName -eq 'User'
                        }
                    
                $found= $all | 
                    Where-Object {                         
                        $_.Name -ieq $alias 
                    }
                    
                
                foreach ($in in $found) {
                    if ($in) {
                        $each = . $processEach

                        if ($each.Fullname) {
                            $each | 
                                Add-Member NoteProperty Name $each.FullName -Force
                        }

                        $each
                        
                            
                    }
                }                
            }            
        } elseif ($psCmdlet.ParameterSetName -eq 'Name') {
            if ($userTable -and $UserPartition) {
                Search-AzureTable @storageParameters -TableName $userTable -Filter "PartitionKey eq '$userPartition'" |
                    Where-Object { $_.Name -eq $name } 
                               
            
            } elseif (((Get-WmiObject Win32_ComputerSystem).Domain -ne 'WORKGROUP') -and (-not $IsLocalAccount)) {
                if (-not $script:DomainList) {
                    $script:DomainList= 
                        [DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Domains | 
                            Select-Object -ExpandProperty Name

                }         
                
                foreach ($d in $script:domainList) {
                    if (-not $d) { continue } 
                    $searcher = New-Object DirectoryServices.DirectorySearcher ([ADSI]"LDAP://$d")
                    $searcher.Filter = "(&(objectCategory=person)(cn=$Name))"
                    . $beginProcessingEach                    

                    foreach ($in in $searcher.Findall()) {
                        . $processEach
                    }
                }
            } else {
                $all = 
                    ([ADSI]"WinNT://$env:computerName,computer").psbase.Children | 
                    Where-Object { 
                        $_.SchemaClassName -eq 'User' -and 
                        $_.Name -eq $name
                    }
                    
                
                foreach ($in in $all) {
                    . $processEach 
                }
            }
        } elseif ($psCmdlet.ParameterSetName -eq 'FacebookAccessToken') {
            $facebookPerson =
                if ($faceboookUserId) {
                
                    Get-Web -Url "https://graph.facebook.com/$FacebookUserId" -AsJson -UseWebRequest   
                } else {

                    Get-Web -Url "https://graph.facebook.com/Me/?access_token=$FacebookAccessToken" -asjson -UseWebRequest
                }

            if (-not $facebookPerson) {
                # If at first you don't succeed, try, try again (because SOMETIMES on first boot, Get-Web barfs and then works)
                $facebookPerson =
                    if ($faceboookUserId) {
                
                        Get-Web -Url "https://graph.facebook.com/$FacebookUserId" -AsJson    
                    } else {

                        Get-Web -Url "https://graph.facebook.com/Me/?access_token=$FacebookAccessToken" -asjson 
                    }

            }
            
            if ($facebookPerson) {
                foreach ($property in @($facebookPerson.psobject.properties)) {
                    $value = $Property.Value
                    $changed = $false
                    if ($Value -is [string] -and $Value -like "*\u*") {
                        $value = [Regex]::Replace($property.Value, 
                            "\\u(\d{4,4})", { 
                            ("0x" + $args[0].Groups[1].Value) -as [Uint32] -as [Char]
                        })
                        $changed = $true
                    }
                    if ($Value -is [string] -and $Value -like "*\r\n*") {
                        $value = [Regex]::Replace($property.Value, 
                            "\\r\\n", [Environment]::NewLine)
                        $changed = $true
                    }


                    if ($changed) {
                        Add-Member -inputObject $facebookPerson NoteProperty $property.Name -Value $value -Force
                    }
                }
                

                $facebookPerson | Add-Member AliasProperty FacebookID ID 
                $facebookPerson.pstypenames.clear()
                $facebookPerson.pstypenames.add('http://schema.org/Person')
                $facebookPerson
            }
            
        } elseif ($psCmdlet.ParameterSetName -eq 'LiveIDAccessToken') {
            $liveIdPerson =                
                Get-Web -Url "https://apis.live.net/v5.0/me?access_token=$LiveIDAccessToken" -asjson -UseWebRequest
            
            if (-not $LiveIDPerson) {
                # If at first you don't succeed, try, try again (because SOMETIMES on first boot, Get-Web barfs and then works)
                $liveIdPerson =                
                    Get-Web -Url "https://apis.live.net/v5.0/me?access_token=$LiveIDAccessToken" -asjson 
            
            }    
            


            if ($liveIdPerson ) {
                foreach ($property in @($liveIdPerson.psobject.properties)) {
                    $value = $Property.Value
                    $changed = $false
                    if ($Value -is [string] -and $Value -like "*\u*") {
                        $value = [Regex]::Replace($property.Value, 
                            "\\u(\d{4,4})", { 
                            ("0x" + $args[0].Groups[1].Value) -as [Uint32] -as [Char]
                        })
                        $changed = $true
                    }
                    if ($Value -is [string] -and $Value -like "*\r\n*") {
                        $value = [Regex]::Replace($property.Value, 
                            "\\r\\n", [Environment]::NewLine)
                        $changed = $true
                    }


                    if ($changed) {
                        Add-Member -inputObject $liveIdPerson NoteProperty $property.Name -Value $value -Force
                    }
                }
                
                $liveIdPerson | Add-Member AliasProperty LiveID ID 
                $liveIdPerson.pstypenames.clear()
                $liveIdPerson.pstypenames.add('http://schema.org/Person')
                $liveIdPerson 
            }
            
        }
     
    }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmX/NRsR+mBPOp36tx9uDqYOT
# wOKgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDzhCl6iH4TmN52b
# ei0yAG79g8yFMA0GCSqGSIb3DQEBAQUABIIBACBij8CbyyDye8lSD6I6hrJMvHie
# vHHUyrFwx1CrESFF21o+76yy4ZCCD4bZNclLF2w/Ue9s/TrWvSnnNZocr2JsQ+cL
# rH54h3bvebKfHmrzEgBn45Goy39/O0dNS4QLxlXSnylGR7VinRFsPxRawd+0zVwv
# JubNa1Z+NVaP71AeG19u1ZH+KU5Wxnhz9DqfIrpBcdQ3ZD8N4MXN7jF9yjokBNnO
# TLrJnyXG5QCm9kjgh40FrVW4rPGbeZzTwnx1pDcf1g/huE8gCxqD24ZtRhRbrgBl
# 4GOF/Q2AR18SeMtUafTUwCkjDcdESt1OvSgBtEXLxC+VbjaGXEAXu5Kn10k=
# SIG # End signature block
