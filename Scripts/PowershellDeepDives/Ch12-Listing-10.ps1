<#
.SYNOPSIS
   HTML System Inventory Report

.DESCRIPTION
   Create an HTML System Inventory Report for multiple computers

.PARAMETER ComputerName
   Supply a name(s) of the computer(s) to create a report for

.PARAMETER ReportFile
   Path to export the report file to

.PARAMETER ImagePath
   Path to an image file to place at the top of the report

.EXAMPLE
   Get-HTMLSystemsInventoryReport -ComputerName Server01 -ReportFile C:\Report\InventoryReport.html -ImagePath C:\Report\Image.jpg
#>

[CmdletBinding()]

Param
    (
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("CN","__SERVER","IPAddress","Server")]
        [String[]]
        $ComputerName,

        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ReportFile,

        [Parameter(Position=2)]        
        [String]
        $ImagePath
    )


begin {

    # --- Check whether the parameter is specified or from the pipeline
    $UsedParameter = $False
    if ($PSBoundParameters.ContainsKey('ComputerName')){
        $UsedParameter = $True
        $InputObject = $ComputerName
    }

    if (!(Test-Path (Split-Path $ReportFile))){

        throw "$(Split-Path $ReportFile) is not a valid path to the report file"
    }

    # Set the HTML header

    $HTMLHeader = @"   

    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

    <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
    <head>
    <title>Systems Inventory</title>
    <style type="text/css">
    <!--


    body {
        background-color: #66CCFF;
    } 
 
    table {
        background-color: white;
        margin: 5px;
        top: 10px;
        display: inline-block;
        padding: 5px;
        border: 1px solid black
    }

    h2 {
        clear: both;
        font-size: 150%;
        margin-left: 10px;
        margin-top: 15px;
    }

    h3 {
        clear: both;
        color: #FF0000;
        font-size: 115%;
        margin-left: 10px;
        margin-top: 15px;
    }

    p {

        color: #FF0000;
        margin-left: 10px;
        margin-top: 15px; 
    }


    tr:nth-child(odd) {background-color: lightgray}

    -->
    </style>
    </head>
    <body>

"@

    # Function to encode image file to Base64
    function Get-Base64Image ($Path) {
        [Convert]::ToBase64String((Get-Content $Path -Encoding Byte))
    }

    # Create the HTML code to embed the image into the webpage
    if ($ImagePath) {
        if (Test-Path -Path $ImagePath) {

        $HeaderImage = Get-Base64Image -Path $ImagePath

        $ImageHTML = @"
            <img src="data:image/jpg;base64,$($HeaderImage)" style="left: 150px" alt="System Inventory">
"@
        }
    else {
        throw "$($ImagePath) is not a valid path to the image file"
        }
    }

    function New-PieChart {
    <#
    .SYNOPSIS
       Create a new Pie Chart using .Net Chart Controls

    .DESCRIPTION
       Create a new Pie Chart using .Net Chart Controls

    .PARAMETER Title
       Title of the chart

    .PARAMETER Width
       Width of the chart

    .PARAMETER Height
       Height of the chart

    .PARAMETER Alignment
       Alignment of the chart

    .PARAMETER SeriesName
        Name of the data series

    .PARAMETER xSeries
        Property to use for x series

    .PARAMETER ySeries
        Property to use for y series

    .PARAMETER Data
       Data for the chart

    .PARAMETER ImagePath
       Path to save a png of the chart to

    .EXAMPLE
       New-PieChart -Title "Service Status" -Series "Service" -xSeries "Name" -ySeries "Count" -Data $Services -ImagePath C:\Report\Image.jpg
    #>

    [CmdletBinding()]

    Param
        (
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [String]$Title,

            [Parameter(Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [Int]$Width = 400,

            [Parameter(Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [Int]$Height = 400,

            [Parameter(Mandatory=$false)]
            [ValidateSet("TopLeft","TopCenter","TopRight",
                        "MiddleLeft","MiddleCenter","MiddleRight",
                        "BottomLeft","BottomCenter","BottomRight")]
            [String]$Alignment = "TopCenter",

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [String]$SeriesName,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [String]$xSeries,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [String]$ySeries,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [PSObject]$Data,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]      
            [String]$ImagePath
        )


    [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

 
    # --- Create the chart object
       $Chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
       $Chart.Width = $Width
       $Chart.Height = $Height

    # --- Set the title and its alignment
       [void]$Chart.Titles.Add("$Title")
       $Chart.Titles[0].Alignment = $Alignment
       $Chart.Titles[0].Font = "Calibri,20pt"
 
    # --- Create the chart area and set it to be 3D
       $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
       $ChartArea.Area3DStyle.Enable3D = $true
       $Chart.ChartAreas.Add($ChartArea)   
 
    # --- Create the data series and pie chart style
       [void]$Chart.Series.Add($SeriesName)
       $Chart.Series[$SeriesName].ChartType = "Pie"
       $Chart.Series[$SeriesName]["PieLabelStyle"] = "Outside"
       $Data | ForEach-Object {$Chart.Series[$SeriesName].Points.Addxy( $_.$xSeries , $_.$ySeries) } | Out-Null
       $Chart.Series[$SeriesName].Points.FindMaxByValue()["Exploded"] = $true
  
    # --- Save the chart to a png file
       $Chart.SaveImage("$ImagePath","png")
    }
 }


 process {

    if (!($UsedParameter)){

        $InputObject = $_
    }

    foreach ($Computer in $InputObject){

        # --- Inventory Queries
        $OperatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $Computer
        $ComputerSystem = Get-WmiObject Win32_ComputerSystem -ComputerName $Computer
        $LogicalDisk = Get-WmiObject Win32_LogicalDisk -ComputerName $Computer
        $NetworkAdapterConfiguration = Get-WmiObject -Query "Select * From Win32_NetworkAdapterConfiguration Where IPEnabled = 1" -ComputerName $Computer
        $Services = Get-WmiObject Win32_Service -ComputerName $Computer
        $Hotfixes = Get-HotFix -ComputerName $Computer

        # --- Variable Build
        $Hostname = $ComputerSystem.Name
        $DNSName = $OperatingSystem.CSName +"." + $NetworkAdapterConfiguration.DNSDomain
        $OSName = $OperatingSystem.Caption
        $Manufacturer = $ComputerSystem.Manufacturer
        $Model = $ComputerSystem.Model

        $Resources = [pscustomobject] @{
            NoOfCPUs = $ComputerSystem.NumberOfProcessors
            RAMGB = $ComputerSystem.TotalPhysicalMemory /1GB -as [int]
            NoOfDisks = ($LogicalDisk | Where-Object {$_.DriveType -eq 3} | Measure-Object).Count
        }

        # --- Insert Pie Chart
        $StartMode = $Services | Group-Object StartMode
        $PieChartPath = Join-Path (Split-Path $script:MyInvocation.MyCommand.Path) -ChildPath ServicesChart.png
        New-PieChart -Title "Service StartMode" -Series "Service StartMode by Type" -xSeries "Name" -ySeries "Count" -Data $StartMode -ImagePath $PieChartPath

        $PieImage = Get-Base64Image -Path $PieChartPath

$ServiceImageHTML = @"
            <img src="data:image/jpg;base64,$($PieImage)" style="right: 150px" alt="Services">
"@

        # HTML Build
        $ServicesHTML = $Services | Sort-Object @{Expression="State";Descending=$true},@{Expression="Name";Descending=$false} | Select-Object Name,State | ConvertTo-Html -Fragment
        $ServicesFormattedHTML =  $ServicesHTML | ForEach {

           $_ -replace "<td>Running</td>","<td style='color: green'>Running</td>" -replace "<td>Stopped</td>","<td style='color: red'>Stopped</td>"
                    
        }

        $HotfixesHTML = $Hotfixes | Sort-Object Description | Select-Object HotfixID,Description,InstalledBy,Installedon | ConvertTo-Html -Fragment
        $HotfixesFormattedHTML =  $HotfixesHTML | ForEach {

           $_ -replace "<td>Update</td>","<td style='color: blue'>Update</td>" -replace "<td>Security Update</td>","<td style='color: red'>Security Update</td>"
                    
        }

        $ResourcesHTML = $Resources | ConvertTo-Html -Fragment

    # --- Set the HTML content

$ItemHTML = @"
    <hr noshade size=5 width="100%">

    <p><h2>$Hostname</p></h2>
    <h3>System</h3>
    <table>
    <tr>
    <td>DNS Name</td>
    <td>$DNSName</td>
    </tr>
    <tr>
    <td>Operating System</td>
    <td>$OSName</td>
    </tr>
    <tr>
    <td>Manufacturer</td>
    <td>$Manufacturer</td>
    </tr>
    <tr>
    <td>Model</td>
    <td>$Model</td>
    </tr>
    </table>

    <br></br>

    <hr noshade size=1 width="100%">

    <h3>Services</h3>
    <p>Installed Services</p>
    $ServicesFormattedHTML

    $ServiceImageHTML

    <hr noshade size=1 width="100%">

    <h3>Hotfixes</h3>
    <p>Installed Hotfixes</p>
    $HotfixesFormattedHTML
    <br></br>

    <hr noshade size=1 width="100%">

    <h3>Resources</h3>
    <p>Installed Resources</p>
    $ResourcesHTML
"@    
        $HTMLSystemReport += $ItemHTML
    }
}

end {
    $HTMLHeader +$ImageHTML + $HTMLSystemReport | Out-File $ReportFile
}
# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfRKIoq1qK4/TeP8kiAsUc/zy
# u46gggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPxVbf57lfH0zJO2
# qyx9BSnOohkTMA0GCSqGSIb3DQEBAQUABIIBAIHAGou0u3eDcTJzOvT0s8FL2xUF
# 8dGlSTjgEj2ek0unYgGNKahoUDZWoFGwp4PoAo6gRd5O9Yf8T3BMHoqIll0skdYh
# vTvs5UZMyrniLOsSXApZjzZfs1VWdTnZwuP01UV2w2seWkwEUFaf7qbfIF2Vrqmc
# 5cNHS/JW6B3dTtQhBtoO07aFI73k5hPWr8+WkZkmA3zaeJMSTD0nbu5RdCFM590u
# Rw7drGWpbN0+VAqg+l5gQFkToodUPFFyheU7SvOZyFJp1L02HwXZ/4o5CzKaovXe
# D3SAJuqtoIjAkHVQuvrFQjH5TvwyVlGeai70K9ER8MqsEh88psi+7pw66pQ=
# SIG # End signature block
