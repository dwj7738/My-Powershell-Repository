#.Synopsis
#  Creates a fir tree in your console!
#.Description
#  A simple christmas tree simulation with (optional) flashing lights. 
#  Requires your font be set to a True Type font (best results with Consolas).
#.Parameter Trim
#  Whether or not to trim the tree. NOTE: In violation of convention, this switch to true!
#  To disable the tree lights, use Get-Tree -Trim:$false 
#.Example
#  Get-Tree -Trim:$false 
#.Example
#  Get-tree Red, Cyan, Blue, Gray, Green
#
#  Description
#  -----------
#  Creates a tree with multi-colored lights in the five colors that work best...
param(
   [switch]$Trim=$true
, 
   [ValidateSet("Red","Blue","Cyan","Yellow","Green","Gray","Magenta","All")]
   [Parameter(Position=0)]
   [String[]]$LightColor = @("Red")
)
if($LightColor -contains "All") {
   $LightColor = "Red","Yellow","Green","Gray","Magenta","Cyan","Blue"
}

Clear-Host
$OFS = "`n"
$center = [Math]::Min( $Host.UI.RawUI.WindowSize.Width, $Host.UI.RawUI.WindowSize.Height ) - 10

$Sparkle = [string][char]0x0489  
$DkShade = [string][char]0x2593
$Needles  = [string][char]0x0416

$Width = 2
[string[]]$Tree = $(
   "$(" " * $Center) "
   "$(" " * $Center)$([char]0x039B)"
   "$(" " * ($Center - 1))$($Needles * 3)"
  
   for($i = 3; $i -lt $center; $i++) {
      (" " * ($Center - $i)) + (Get-Random $Needles, " ") + ($Needles * (($Width * 2) + 1)) + (Get-Random $Needles, " ")
      $Width++
   }
   for($i = 0; $i -lt 4; $i++) {
      " " * ($Center + 2)
   }
) 

$TreeOn = $Host.UI.RawUI.NewBufferCellArray( $Tree, "DarkGreen", "DarkMagenta" )
$TreeOff = $Host.UI.RawUI.NewBufferCellArray( $Tree, "DarkGreen", "DarkMagenta" )

# Make the tree trunk black
for($x=-2;$x -le 2;$x++) { 
   for($y=0;$y -lt 4;$y++) {
      $TreeOn[($center+$y),($center+$x)] = $TreeOff[($center+$y),($center+$x)] = 
         New-Object System.Management.Automation.Host.BufferCell $DkShade, "Black", "darkMagenta", "Complete"
   }  
}

if($trim) {
$ChanceOfLight = 50
$LightIndex = 0
for($y=0;$y -le $TreeOn.GetUpperBound(0);$y++) {
   for($x=0;$x -le $TreeOn.GetUpperBound(1);$x++) {
      # only put lights on the tree ...
      if($TreeOn[$y,$x].Character -eq $Needles) {
         $LightIndex += 1
         if($LightIndex -ge $LightColor.Count) {
            $LightIndex = 0
         }
         # distribute the lights randomly, but not next to each other
         if($ChanceOfLight -gt (Get-Random -Max 100)) {
            # Red for on and DarkRed for off.
            $Light = $LightColor[$LightIndex]
            $TreeOn[$y,$x] = New-Object System.Management.Automation.Host.BufferCell $Sparkle, $Light, "darkMagenta", "Complete"
            $TreeOff[$y,$x] = New-Object System.Management.Automation.Host.BufferCell $Sparkle, "Dark$Light", "darkMagenta", "Complete"
            $ChanceOfLight = 0 # Make sure the next spot won't have a light
         } else { 
            # Increase the chance of a light every time we don't have one
            $ChanceOfLight += 3
         }
      }
   }
}
# Set the star on top
$TreeOn[0,$Center] = $TreeOff[0,$Center] = New-Object System.Management.Automation.Host.BufferCell $Sparkle, "Yellow", "darkMagenta", "Complete"
}


# Figure out where to put the tree
$Coord = New-Object System.Management.Automation.Host.Coordinates (($Host.UI.RawUI.WindowSize.Width - ($Center*2))/2), 2
$Host.UI.RawUI.SetBufferContents( $Coord, $TreeOff )

while($trim) { # flash the lights on and off once per second, if we trimmed the tree
   sleep -milli 500
   $Host.UI.RawUI.SetBufferContents( $Coord, $TreeOn )
   sleep -milli 500
   $Host.UI.RawUI.SetBufferContents( $Coord, $TreeOff )
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpYs/R3YwqF4LjAHheng7Vtka
# L2mgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFGarnKrjFY3Vd/+l
# lQt0HfTSy8azMA0GCSqGSIb3DQEBAQUABIIBALx9nDVdbc9JUsNXtQVu/P2H4AN5
# MBepsbZaVGSTOCu0L+BeUpCoRbUSKoLhTraw8ksUe9kXSwOyHEtAAcMIDZjgcIMn
# 8/citPRmGJ7uG5s198HEcGI7O3pTnMxsfqmdTdHyzCSSmdbSzskpox/vwW1ojYdu
# 6rqwhCNL2STZzWII7u6b0v+kfqEqptKdwssAHtFi7nrwxWRJ1Odm1LAAIkSIWnfK
# MpsQ6N2w5AwrBREBx3eqVxExyS/5tee9+uQbNDtjUQS2Cl4hQ2eGfPBsTzHczs3j
# ulzWPDgqxGJ0J0+lsk9ilfA9twB+ydIyJZ7ACzM9/l9c2Q9Tm7xZziXx3Jg=
# SIG # End signature block
