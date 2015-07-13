function Find-Factual {
    <#
    .Synopsis
        Finds content on Factual
    .Description
        Finds content on Factual's global places API
    .Example
        Find-Factual Starbucks in Seattle        
    .Example
        $l = Resolve-Location -Address 'Redmond, WA'
        Find-Factual -GeoPulse -TypeOfFilter Point -Filter "$($l.longitude),$($l.Latitude)" -Verbose
    .Example
        Find-Factual -InTable vYrq7F -Filter 'Washington' -TypeOfFilter State -Limit 50
    .Example
        # Wineries
        Find-Factual -InTable cQUvfi  
    #>
    param(
    # The factual query
    [Parameter(Position=0)]
    [string]
    $Query,

    # The type of the filter
    [Parameter(Position=1)]
    [ValidateSet("In","Near","Category","Country", "UPC", "EAN", "Brand", "Point", "Name", "Brewery", "Beer", "Style", "State", "PostCode")]
    [string[]]    
    $TypeOfFilter,

    # The filter 
    [Parameter(Position=2)]    
    [string[]]
    $Filter,

    # Within.  This is only used when 'near' is used
    [Parameter(Position=3)]
    [Uint32]
    $Within = 1000,

    # Your Factual API Key
    [Parameter(Position=4)]
    [string]
    $FactualKey,

    # A secure setting containing your factual key
    [Parameter(Position=5)]
    [string]
    $FactualKeySetting = "FactualKey",

    # If set, will only find US resturaunts
    [Switch]
    $Restaurants,

    # If set, will only find health care providers
    [Switch]
    $HeathCare, 

    # If set, will only find products
    [Switch]
    $Product,

    # If set, searches the places data set
    [switch]
    $Place,

    # If set, gets the GeoPulse of an area
    [Switch]
    $GeoPulse,

    # If set, will get data from a table
    [string]
    $InTable,
    
    # If set, will limit the number of responses returned
    [ValidateRange(1,50)]
    [Uint32]
    $Limit,

    # If set, will start returning results at a point
    [Uint32]
    $Offset,

    # If set, will query all records that match a filter.  This will result in multiple queries.
    [Switch]
    $All


    )

    process {
        $filters = ""

        if ($TypeOfFilter.Count -ne $Filter.Count) {
            throw "Must be an equal number of filters and types of filters"
        }


        $geoString = ""

        
        $filterString = 
        for ($i = 0; $i -lt $TypeOfFilter.Count; $i++) {
            if ($TypeOfFilter[$i] -eq 'Category') {
                "{`"category`":{`"`$bw`":$('"' + ($Filter[$i] -join '","') + '"')}}"
            } elseif ($TypeOfFilter[$i] -eq 'In') {

                "{`"locality`":{`"`$in`":[$('"' + ($Filter[$i] -join '","') + '"')]}}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'Upc') {

                "{`"upc`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'Ean13') {

                "{`"ean13`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'ProductName') {

                "{`"product_name`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'Name') {

                "{`"name`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'Brewery') {

                "{`"brewery`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'Beer') {

                "{`"beer`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'State') {

                "{`"state`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'Country') {

                "{`"country`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'Style') {

                "{`"style`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'Brand') {

                "{`"brand`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'PostCode') {

                "{`"postcode`":`"$($Filter[$i])`"}"
             
                
            } elseif ($TypeOfFilter[$i] -eq 'Near') {
                
                ""
                $geoString = "&geo={`"`$circle`":{`"`$center`":[$(($Filter[$i] -split ",")[0]),$(($Filter[$i] -split ",")[1])],`"`$meters`":$Within }}"
            } elseif ($TypeOfFilter[$i] -eq 'Point') {
                ""
                $lat = [Math]::Round((($Filter[$i] -split ",")[0]), 5)
                $long = [Math]::Round((($Filter[$i] -split ",")[1]), 5)
                $geoString = "&geo={`"`$point`":[$lat,$long], `"`$meters`":$within}"
            }
        }


        

        
        
        $factualUrl = "http://api.v3.factual.com/t/global?"
        if ($Restaurants) {
            $factualUrl = "http://api.v3.factual.com/t/restaurants-us?"
        } elseif ($HeathCare) {
            $factualUrl = "http://api.v3.factual.com/t/health-care-providers-us?"
        } elseif ($Place) {
            $factualUrl = "http://api.v3.factual.com/t/world-geographies?"
        } elseif ($product) {
            $factualUrl = "http://api.v3.factual.com/t/products-cpg?"
        } elseif ($GeoPulse) {
            $factualUrl = "http://api.v3.factual.com/places/geopulse?"
        } elseif ($InTable) {
            $factualUrl = "http://api.v3.factual.com/t/${InTable}?"
            
        }
        
        if ($Query) {
            $factualUrl += "q=$Query&"
        } else {
        }

        if ($filterString) {

        $factualUrl +=
            if ($filterstring -is [Array]) {
                # ands
                "filters={`"`$and`":[$($filterString -join ',')]}"            
            } else {
                # simple $filter
                "filters=$($filterString)"
            } 
        } else {
            $geoString= $geoString.TrimStart("&")    
        }
        if ($geoString) {
            $factualUrl += $geostring
        }

        if (-not $GeoPulse) {
            $factualUrl +="&include_count=true"
        
            if ($limit) {
                $factualUrl +="&limit=$limit"
            }

            if ($Offset) {
                $factualUrl +="&offset=$offset"
            }
        }
        


        
        Write-Verbose "Querying From Factual $factualUrl&Key=******"
        
        if (-not $FactualKey) {
            $FactualKey = Get-SecureSetting -Name $FactualKeySetting -ValueOnly
        }
        

        $factualUrl += 
            if($FactualKey ){
                "&KEY=$FACTUALKey"
            }
        
        $factualResult = Get-Web -Url $factualUrl -AsJson -UseWebRequest

        while ($factualResult) {
            
            $rowCount = $factualResult.response.total_row_count
            if ($rowCount) {
                Write-Verbose "$RowCount total records to return"
            }


            



            $factualResult= $factualResult.response.data  
            if (-not $factualResult) { break }

            $factualResult = foreach ($f in $factualResult) {
                if (-not $f){ continue } 
                    
                if ($geoPulse) {
                    $null = Update-List -InputObject $f -remove "System.Management.Automation.PSCustomObject", "System.Object" -add "Factual.GeoPulse" -Property pstypenames 
                } elseif ($f.Beer) {
                    $null = Update-List -InputObject $f -remove "System.Management.Automation.PSCustomObject", "System.Object" -add "Factual.Beer" -Property pstypenames 
                } elseif ($f.Operating_Name -and $f.permit_number) {
                    $null = Update-List -InputObject $f -remove "System.Management.Automation.PSCustomObject", "System.Object" -add "Factual.Winery" -Property pstypenames 
                } elseif (-not $Product) {
                    $f = $f | 
                        Add-Member AliasProperty telephone tel -Force -PassThru |
                        Add-Member AliasProperty url website -Force -PassThru 
                    $null = Update-List -InputObject $f -remove "System.Management.Automation.PSCustomObject", "System.Object" -add "http://schema.org/Place" -Property pstypenames 
                } else {
                    
                    $null = Update-List -InputObject $f -remove "System.Management.Automation.PSCustomObject", "System.Object" -add "http://schema.org/Product" -Property pstypenames 
                }
                $f
            }
            $factualResult 

            if ($all) {
                if ($factualUrl -like "*offset=*") {
                    $factualUrl = $factualUrl -replace '\&offset=\d{1,}', ''
                    $Offset += 20
                } else {
                    $Offset = 20
                }
                $factualUrl+="&offset=$Offset"
                $factualResult = Get-Web -Url $factualUrl -AsJson   
            } else {
                $factualResult  = $null

            }
        }
#        
    }
}




# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUK3BtFmA6aN+1Ivuiww198Z0z
# 58+gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFG6BfygZUCOWf2J+
# yuTzdiUvtdPrMA0GCSqGSIb3DQEBAQUABIIBAGHOn0aD7YN7Xnt30U0N91EDYKEP
# Mqha9YurXA2udvQwKlnCdfE3d+LdvQiNK/XaQd9YzCPUAyd/NAwzFLEJJZYsp86Z
# gSDVFh2S1eszF4EUNOrk7ODe/ooxsMM1MzS/geFuccEWjHQ+TXNWjG+ECPJMFxmc
# /L2kBYe2GV+K1c7k4hsCXDqvKmt49646Td3fS0XNA5P8TKXzrg66Tmx3UOvyOODL
# XP5kf6WA+3eTBYWchYivF/4FForQ25sqU2sHByT8xfH1Nsi4EZZqPKJEA3wSphMt
# SAAzu/H89sSvDxzAzThpZFZ0pecg//0krXiSo2gWxZMGzFDgmk+Qww1PFCI=
# SIG # End signature block
