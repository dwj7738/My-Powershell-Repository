function Get-RandomNames {
<#
.SYNOPSIS
Gets Full Names from a List of Names from http://names.mongabay.com
.DESCRIPTION
Downloads the Names from the Websites and randomizes the order of Names and gives back an Object with surname, lastname and gender
.PARAMETER MaxNames
Number of names returned by the function
.PARAMETER Gender
Gender of the names
.EXAMPLE
Get-RandomNames -Maxnames 20 -Gender Female
.EXAMPLE
Get-RandomNames
.NOTES
Name: Get-RandomNames
Author: baschuel
Date: 17.02.2013
Version: 1.0
Thanks to http://names.mongabay.com
#>
    [CmdletBinding()]
    param (
        [parameter(Position=0)]
        [int]$MaxNames = 10,
        [parameter(Position=1)]
        [string]$Gender = "Male"       
    )
    BEGIN{
        $surnameslink = "http:\\names.mongabay.com/most_common_surnames.htm"
		$malenameslink = "http:\\names.mongabay.com/male_names_alpha.htm"
		$femalenameslink = "http:\\names.mongabay.com/female_names_alpha.htm"
    }#begin
    
    PROCESS{
		
		
        function get-names ($url) {
            
            Try {
            
                $web = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction Stop

                $html = $web.Content

                $regex = [RegEx]'((?:<td>)(.*?)(?:</td>))+'

                $Matches = $regex.Matches($html)
            
                $matches | ForEach-Object {
                    If ($_.Groups[2].Captures[0].Value -ge 1) {
                    
                        $hash = @{Name = $_.Groups[2].Captures[0].Value;
                                  Rank = [int]$_.Groups[2].Captures[3].Value}
                        New-Object -TypeName PSObject -Property $hash
                    
                    }#If
                }#Foreach-Object

            } Catch {

                Write-Warning "Can't access the data from $url."
                Write-Warning "$_.Exception.Message"
                Break

            }
            
        }#Function get-names


        If ($Gender -eq "Male") {
            
            $AllMaleFirstNames = (get-Names $malenameslink).name
            $AllSurnames = (get-names $surnameslink).name
            
            If ($AllMaleFirstNames.Count -le $AllSurnames.Count) {
                $UpperRange = $AllMaleFirstNames.Count
            } else {
                $UpperRange = $AllSurnames.Count
            }
            

            If (($MaxNames -le $AllMaleFirstNames.Count) -and ($MaxNames -le $AllSurnames.Count)) {

                1..$UpperRange | 
                Get-Random -Count $MaxNames | 
                ForEach-Object {
                    $hash = @{Givenname = $AllMaleFirstNames[$_];
                              Surname = $AllSurnames[$_];
                              Gender = "Male"}
                    
                    $hash.Givenname = $($hash.Givenname[0]) + $hash.givenname.Substring(1,$hash.givenname.Length-1).ToLower()
                    $hash.Surname = $($hash.Surname[0]) + $hash.surname.Substring(1,$hash.surname.Length-1).ToLower()
                    
                    New-Object -TypeName PSObject -Property $hash
                } # Foreach-Object

            } Else {
    
                Write-Warning "Don't know so many names! Try a smaller number"

            }#If

        } elseIf ($Gender -eq "Female") {
        
            $AllFeMaleFirstNames = (get-Names $femalenameslink).name
            $AllSurnames = (get-names $surnameslink).name
            
            If ($AllFeMaleFirstNames.Count -le $AllSurnames.Count) {
                $UpperRange = $AllMaleFirstNames.Count
            } else {
                $UpperRange = $AllSurnames.Count
            }
            If (($MaxNames -le $AllFeMaleFirstNames.Count) -and ($MaxNames -le $AllSurnames.Count)) {

                1..$UpperRange | 
                Get-Random -Count $MaxNames | 
                ForEach-Object {
                    $hash = @{Givenname = $AllFeMaleFirstNames[$_];
                              Surname = $AllSurnames[$_];
                              Gender = "Female"}
                    
                    $hash.Givenname = $($hash.Givenname[0]) + $hash.givenname.Substring(1,$hash.givenname.Length-1).ToLower()
                    $hash.Surname = $($hash.Surname[0]) + $hash.surname.Substring(1,$hash.surname.Length-1).ToLower()
                    
                    New-Object -TypeName PSObject -Property $hash
                } # Foreach-Object

            } Else {
    
                Write-Warning "Don't know so many names! Try a smaller number"

            }#If
        }#If
        
    }

}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9CmM5UGf6R4GIn3ojXxqEmhO
# PD+gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFKd4ihFPuYE/XvCR
# ckp0Ded0akxCMA0GCSqGSIb3DQEBAQUABIIBAAy8cbhCRHxEhcgssiAu+mjNQqEG
# hnAgyLr+4m/8nKclafvLDjfRtvpNjt2PceYkBRGXPxWWa/2EWb5I8T6Zxtd1NR3P
# JPGt66nPwVGy/LPLg7vI1B7SUo4nmOfluOHeb9xb2K2zitFkuxeEDgKVjCKqpmI+
# H/WNYL1QkQvUjgdQLjbKwqa/8uSi3YLw+Uys070sjf8ahZqgzcZuZBpEx5f7EUpZ
# g7Cuk7bsEFiB3tFt5W2kUIFn45JkDb1nTdj8f95HAd+d1wuIlhBrofZKY2WUW0L2
# zarGIkqr7CmnOs9xSBJMQmmqDcaxU41BQtNwdwrtSCZezE5PnL8LxRIAWME=
# SIG # End signature block
