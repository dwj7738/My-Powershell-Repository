#-----------------------------------------------------------------------------
# PowerShell MVP Deep Dives
# Chapter 25 Code Sample
# Robert C. Cain 
# 
# Notes
#   In the listings you will see a few sections called "Warm Fuzzy". These
#   listings are just so you can validate the work in the previous lisitng. 
#   Basically, to give you a good feeling or a "warm fuzzy" that your code
#   worked correctly.
#
#   They aren't needed to complete the end result and can be omitted if you 
#   decide to implement this as a full script. 
#-----------------------------------------------------------------------------




  #---------------------------------------------------------------------------
  # Listing 4. Create the table if it doesn't exist.
  #---------------------------------------------------------------------------

    $instance = $env:COMPUTERNAME
    $Server = New-Object `
      Microsoft.SqlServer.Management.Smo.Server("$instance")
    $db = $Server.Databases["PSMVP"]    
    if ($db.Tables.Contains("TableStats") -eq $false)
    {
      # Create a table object in our current database object
      $table = New-Object Microsoft.SqlServer.Management.Smo.Table($db, "TableStats")
	
      $col1 = New-Object Microsoft.SqlServer.Management.Smo.Column ($table, "TableStatsID")   
      $col1.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::Int
      $col1.Nullable = $false
      
      # This will be an auto incrementing primary key
      $col1.Identity = $true
      $col1.IdentitySeed = 1
      $col1.IdentityIncrement = 1
      $table.Columns.Add($col1) 

      # DatabaseName
      $col2 = New-Object Microsoft.SqlServer.Management.Smo.Column ($table, "DatabaseName")
      $col2.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250)
      $col2.Nullable = $false
      $table.Columns.Add($col2)  

      # TableName
      $col3 = New-Object Microsoft.SqlServer.Management.Smo.Column ($table, "TableName")
      $col3.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250)
      $col3.Nullable = $false
      $table.Columns.Add($col3)  

      # FileGroup
      $col4 = New-Object Microsoft.SqlServer.Management.Smo.Column ($table, "FileGroup")
      $col4.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250)
      $col4.Nullable = $false
      $table.Columns.Add($col4)  

      # TableOwner
      $col5 = New-Object Microsoft.SqlServer.Management.Smo.Column ($table, "TableOwner")
      $col5.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(250)
      $col5.Nullable = $false
      $table.Columns.Add($col5)

      # RowCount
      $col6 = New-Object Microsoft.SqlServer.Management.Smo.Column ($table, "RowCount")
      $col6.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::Int
      $col6.Nullable = $false
      $table.Columns.Add($col6)

      # DataSpaceUsed
      $col7 = New-Object Microsoft.SqlServer.Management.Smo.Column ($table, "DataSpaceUsed")
      $col7.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::Int
      $col7.Nullable = $false
      $table.Columns.Add($col7)

      # IndexSpaceUsed
      $col8 = New-Object Microsoft.SqlServer.Management.Smo.Column ($table, "IndexSpaceUsed")
      $col8.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::Int
      $col8.Nullable = $false
      $table.Columns.Add($col8)

      # Replicated
      $col9 = New-Object Microsoft.SqlServer.Management.Smo.Column ($table, "Replicated")
      $col9.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::NVarChar(20)
      $col9.Nullable = $false
      $table.Columns.Add($col9)

      $table.Create()   

      # Add the primary key
      # Start with adding the primary key structure
      $pk = New-Object Microsoft.SqlServer.Management.Smo.Index($table, "PK_TableStatsId")
      $pk.IndexKeyType = [Microsoft.SqlServer.Management.Smo.IndexKeyType]::DriPrimaryKey

      # Next add the column to be indexed to the PK
      $ic = New-Object Microsoft.SqlServer.Management.Smo.IndexedColumn($pk, "TableStatsID")  
      $pk.IndexedColumns.Add($ic)

      # Now add the primary key to the table's indexes collection
      $table.Indexes.Add($pk)

      # Finally update the table applying the new index
      $table.Alter() 
    }


  #---------------------------------------------------------------------------
  # Warm fuzzy. Show the table exists.
  #---------------------------------------------------------------------------

    $instance = $env:COMPUTERNAME
    $Server = New-Object `
      Microsoft.SqlServer.Management.Smo.Server("$instance")
    $db = $Server.Databases["PSMVP"]    
    $db.Tables |
      Format-Table -AutoSize `
                   -Property Schema, `
                             Name, `
                             FileGroup                   


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUr+GApEoky/yBVgKu2jVGb+CI
# GVOgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFK3mOaUEfHWSCHM/
# t20RBx6o8ifNMA0GCSqGSIb3DQEBAQUABIIBAEf8cT+73MXh3Z6yTqoNhIcjLgT7
# GQKqnVED6Mum0bJMXaQOh1rX0uZJzktdLeufdgNAuMgjtMfYNxtygIF8qA+lS2jm
# QVaIHRLmTg1vPKD/Rgx4+x4AVqHwgzjXjxDHc7NoWnjAko3YoMAIYqJxb97FI1Cy
# evVWHWdKa0e9Yqt02DOGlbDp+xewBrjHzQbSBH7AKOvF2qsKsb8bwznC/NL0iNLZ
# BQz1uAkbKecxrzcex+BQNkXPJvkw8Kfk2OhhPsvXcxpLn9Rwz91SAssqTeOjnuyR
# e7G89UqsZeMr4IPV/ia7E6ywctxMhxaVEjB9Km6JA7922ma17FWtoatZSN0=
# SIG # End signature block
