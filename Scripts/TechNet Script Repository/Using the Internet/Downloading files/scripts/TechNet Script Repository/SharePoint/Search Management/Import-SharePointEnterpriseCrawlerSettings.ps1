# Contributors: Eric Dixon
param([string]$SearchApplication="",[string]$importFile="",[switch]$createTemplate,[switch]$help)
Add-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue 
function writeTemplate($filename)
{
    $crawlerSettingsTempl = 
@" 
<CrawlerConfig searchServiceApplication=''>
 <CrawlContentSources>
  <CrawlContentSource name=''>
   <Property name='Type'></Property>
   <Property name='CrawlPriority'></Property>
   <Property name='SharePointCrawlBehavior'></Property>
   <Property name='MaxPageEnumerationDepth'></Property>
   <Property name='MaxSiteEnumerationDepth'></Property>
   <Property name='StartAddresses'>
    <Property name='StartAddress'></Property>
   </Property>
   <Property name='FollowDirectories'></Property>
   <Property name='FullCrawlSchedule'>
    <Property name='ScheduleType'></Property>
    <Property name='BeginDay'></Property>
    <Property name='BeginMonth'></Property>
    <Property name='BeginYear'></Property>
    <Property name='DaysOfWeek'></Property>
    <Property name='DaysOfMonth'></Property>
    <Property name='MonthsOfYear'></Property>
    <Property name='RepeatDuration'></Property>
    <Property name='RepeatInterval'></Property>
    <Property name='StartHour'></Property>
    <Property name='StartMinute'></Property>
    <Property name='WeeksInterval'></Property>
   </Property>
  </CrawlContentSource>
 </CrawlContentSources>
 <CrawlRules>
  <CrawlRule name=''>
   <Property name='Path'></Property>
   <Property name='Type'></Property>
   <Property name='CaseSensitiveURL'></Property>
   <Property name='CrawlAsHttp'></Property>
   <Property name='FollowComplexUrls'></Property>
   <Property name='IsAdvancedRegularExpression'></Property>
   <Property name='SuppressIndexing'></Property>
   <Property name='Priority'></Property>
  </CrawlRule>
 </CrawlRules>
 <FileExtensions>
  <FileExtension>
   <Property name='ext'></Property>
  </FileExtension>
 </FileExtensions>
</CrawlerConfig>
"@ 
    $crawlerSettingsTempl | Out-File $filename
}
function makeSchedule($prop)
{
    foreach($p in $prop)
    {
        if($p.name -ne "ScheduleType"){continue}
        
        $ssa = Get-SPServiceApplication -name $SearchApplication
        if(!$ssa)
        {
            Write-Host "Unable to retrieve SearchServiceApplication: $SearchApplication" -ForegroundColor red
            exit
        }
        switch($p.InnerText)
        {
            "DailySchedule" {$sched = New-Object Microsoft.Office.Server.Search.Administration.DailySchedule($ssa);break}
            "MonthlyDateSchedule" {$sched = New-Object Microsoft.Office.Server.Search.Administration.MonthlyDateSchedule($ssa);break}
            "MonthlyDayOfWeekSchedule" {$sched = New-Object Microsoft.Office.Server.Search.Administration.MonthlyDayOfWeekSchedule($ssa);break}
            "WeeklySchedule" {$sched = New-Object Microsoft.Office.Server.Search.Administration.WeeklySchedule($ssa);break}
        }
        break
    }
    if($sched)
    {
        foreach($p in $prop)
        {
            if($p.name -eq "ScheduleType"){continue}
            $name = $p.name
            ($sched.$name) = $p.InnerText
        }
    }
    else
    {
        Write-Host "Unable to create a schedule" -ForegroundColor red
        exit
    }
    return $sched
}
function importContentSource($source)
{
    Write-Host "Importing Content Source: " $source.name
    $scheduleType = ""
    foreach($prop in $source.Property)
    {
        $proptext = $prop.InnerText.tostring().replace('&amp;','&')
        switch($prop.name)
        {
            "Type" {$type = $proptext;break}
            "CrawlPriority" {$crawlPriority = $proptext;break}
            "MaxPageEnumerationDepth" {$maxPageEnumerationDepth = $proptext;break}
            "MaxSiteEnumerationDepth" {$maxSiteEnumerationDepth = $proptext;break}
            "FollowDirectories" {$followDirectories = $proptext;break}
            "StartAddresses" {foreach($addr in $prop.Property){$addresses += $addr.InnerText+","};break}
            "IncrementalCrawlSchedule" {$scheduleType = "IncrementalCrawlSchedule"; $schedule = makeSchedule -prop $prop.Property;break}
            "SharePointCrawlBehavior" {$sharePointCrawlBehavior = $proptext;break}
        }
    }
    $addresses = $addresses.trimend(",")
    switch($type)
    {
        "web" 
        {
            $cs = New-SPEnterpriseSearchCrawlContentSource -Name $source.name -SearchApplication $SearchApplication -Type $type -StartAddresses $addresses -CrawlPriority $crawlPriority -MaxPageEnumerationDepth $maxPageEnumerationDepth -MaxSiteEnumerationDepth $maxSiteEnumerationDepth -ErrorAction SilentlyContinue -ErrorVariable err
            break
        }
        "custom" 
        {
            $cs = New-SPEnterpriseSearchCrawlContentSource -Name $source.name -SearchApplication $SearchApplication -Type $type -StartAddresses $addresses -CrawlPriority $crawlPriority -MaxPageEnumerationDepth $maxPageEnumerationDepth -MaxSiteEnumerationDepth $maxSiteEnumerationDepth -ErrorAction SilentlyContinue -ErrorVariable err
            break
        }
        "sharepoint" 
        {
            $cs = New-SPEnterpriseSearchCrawlContentSource -Name $source.name -SearchApplication $SearchApplication -Type $type -StartAddresses $addresses -CrawlPriority $crawlPriority -SharePointCrawlBehavior $sharePointCrawlBehavior -ErrorAction SilentlyContinue -ErrorVariable err
            break
        }
        default 
        {
            $cs = New-SPEnterpriseSearchCrawlContentSource -Name $source.name -SearchApplication $SearchApplication -Type $type -StartAddresses $addresses -CrawlPriority $crawlPriority -ErrorAction SilentlyContinue -ErrorVariable err
        }
    }
    if(!$cs)
    {
        $s = [string]$err[0].Exception
        if($s.Contains("already exists"))
        {
            Write-Host "Content Source '"$source.name"' already exists. Skipping."
        }
        else
        {
            Write-Host -foregroundcolor 'red' $s
        }     
        return  
    }
    
    if($scheduleType)
    {
        $cs.$scheduleType = $schedule
        Set-SPEnterpriseSearchCrawlContentSource -Identity $cs 
    }
    
}      

function importRule($source)
{
    Write-Host "Importing Crawl Rule: " $source.name
    foreach($prop in $source.Property)
    {
        switch($prop.name)
        {
            "Path" {$path = $prop.InnerText;break}
            "Type" {$type = $prop.InnerText;break}
            "CaseSensitiveURL" {$caseSensitiveURL = [System.Convert]::ToBoolean($prop.InnerText);break}
            "CrawlAsHttp" {$crawlAsHttp = [System.Convert]::ToBoolean($prop.InnerText);break}
            "FollowComplexUrls" {$followComplexUrls = [System.Convert]::ToBoolean($prop.InnerText);break}
            "IsAdvancedRegularExpression" {$isAdvancedRegularExpression = [System.Convert]::ToBoolean($prop.InnerText);break}
            "SuppressIndexing" {$suppressIndexing = [System.Convert]::ToBoolean($prop.InnerText);break}
            "Priority" {$priority = $prop.InnerText;break}
        }
    }
    $rule = New-SPEnterpriseSearchCrawlRule -Path $path -SearchApplication $SearchApplication -Type $type -CrawlAsHttp $crawlAsHttp -FollowComplexUrls $followComplexUrls -IsAdvancedRegularExpression $isAdvancedRegularExpression -Priority $priority -SuppressIndexing $suppressIndexing  -ErrorAction SilentlyContinue -ErrorVariable err
    if(!$rule)
    {
        $s = [string]$err[0].Exception
        if($s.Contains("already exists"))
        {
            Write-Host "Crawl Rule '"$source.name"' already exists. Skipping."
        }
        else
        {
            Write-Host -foregroundcolor 'red' $s
        }
        return       
    }
    $rule.CaseSensitiveURL = $caseSensitiveURL
    Set-SPEnterpriseSearchCrawlRule -Identity $rule 
}      

function importFileExtension($source)
{
    foreach($prop in $source.Property)
    {
        switch($prop.name)
        {
            "ext" {$ext = $prop.InnerText;break}
        }
    }
    
    $fe = New-SPEnterpriseSearchCrawlExtension $ext -SearchApplication $SearchApplication -ErrorAction SilentlyContinue -ErrorVariable err
    if(!$fe)
    {
        $s = [string]$err[0].Exception
        if($s.Contains("The object you are trying to create already exists"))
        {
            Write-Host "File Extension '$ext' already exists. Skipping."
        }
        else
        {
            Write-Host -foregroundcolor 'red' $s
        }       
    }
}      

function importCrawlerSettings($xmldata)
{
    $nodes = $xmldata.SelectNodes("CrawlerConfig/CrawlContentSources/CrawlContentSource")
    foreach($n in $nodes)
    {
        importContentSource -source $n
    }
    $nodes = $xmldata.SelectNodes("CrawlerConfig/CrawlRules/CrawlRule")
    foreach($n in $nodes)
    {
        importRule -source $n
    }
    $nodes = $xmldata.SelectNodes("CrawlerConfig/FileExtensions/FileExtension")
    if($nodes.Count)
    {
        Write-Host "Importing File Extensions: " 
    }
    foreach($n in $nodes)
    {
        importFileExtension -source $n
    }
}

function writeHelp()
{
    Write-Host -foregroundcolor 'green' "This script file imports a Crawler Settings XML file."
    Write-Host -foregroundcolor 'green' ""
    Write-Host -foregroundcolor 'green' "Use the -list switch to list all application names."
    Write-Host -foregroundcolor 'green' "Use the -SearchApplication option to export a specific Search Service Application."
    Write-Host -foregroundcolor 'green' "Use the -importFile option to name the configuration file you want to import."
    Write-Host -foregroundcolor 'green' "Use the -overwrite switch to overwrite existing template file."
    Write-Host -foregroundcolor 'green' "Use the -createTemplate switch to create a template import file for Crawler Settings."
    Write-Host -foregroundcolor 'green' "Example: <script_file>.ps1 -SearchServiceApplication <NameOfSearchServiceApplication>"
}
 
function main($file, $createTemplate, $overwrite, $help)
{
    if($createTemplate)
    {
        $fileName = "Crawler_Config_Template.xml"
        if((Test-Path $fileName) -and !$overwrite){ Write-Host "Template file $filename already exists."; return}
        Write-Host "Creating template file $fileName"
        writeTemplate($fileName)
        Write-Host "Done."
        return
    }
    if($file)
    {
        Write-Host "Using configuration file: $file"
        $xmldata = [xml](Get-Content $file)
        if($xmldata)
        {
            importCrawlerSettings -xmldata $xmldata
            Write-Host "Done importing crawl settings and content sources."
        }
        else
        {
            Write-Host "Unable to find configuration file: $file" -ForegroundColor 'red'
        }
        return
    }
    else
    {
        Write-Host -foregroundcolor 'red' "Please specify a Crawler Settings import file."
        writeHelp
        return
    }
    
    writeHelp
}
if(!$SearchApplication)
{
       $ssa = Get-SPEnterpriseSearchServiceApplication 
       [int]$count = 0
       foreach ($sa in $ssa)
       {
          write-host $count - $ssa[$count].name
          $count += 1
       }
       $ssa = $ssa[(read-host "Enter the SSA number")]
       $SearchApplication = $ssa.name
       $name = $ssa.name
       write-host SSA selected: $name
       write-host SSA: $ssa
    }
main $importFile $createTemplate $overwrite $help


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQoM98yvJ9usWmerAfhAg/AUy
# +KGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFI+fjnCazitmXKqx
# 1IgKK+7W45h4MA0GCSqGSIb3DQEBAQUABIIBAAwvJZCEpwqdubN4QZdHVf/XNn/Z
# wHjR+w3ZgJeA3BEIs764PD34CRWqBhnZj81oh+KEbQvdQNjsbB4OyBvoViadLO5r
# kqFQEV2J8JgTMrpAirmhpQV5Zqp43vGCWCyu/3jI7znAa7a1S2ZEEo6HqgkTzhFv
# Wt3ZtWMlQT3/yOzYWP8SVZb1eA9zSemFf33YAeTmA1cVafVo2i/YCscUvUBb1Bnj
# aUU7OYolBD9uYH7vQUTPxavlyLsaffi2fud+6OXLdbrTZcSFn6GbJ2rWLBwiRJ1w
# BbNZ7HuuHqYj0qeUvCgL8SOyAu3HyldR/33iY0XHzpxgBelXRz7f3i6DOAg=
# SIG # End signature block
