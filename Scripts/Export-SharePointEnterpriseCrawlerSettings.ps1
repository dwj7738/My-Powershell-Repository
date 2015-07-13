# Contributors: Eric Dixon 
param([string]$SearchServiceApplication="", [switch]$list,[switch]$createTemplate,[switch]$overwrite,[switch]$help, 	[string]$directoryForConfigFile=$pwd.Path,

    [switch]
    # Specifies whether the script should generate a sample configuration file. If you specify this flag, 
    # the script will generate the file and exit.
    $GenerateSampleConfigurationFile) 
 
Add-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue  

$configurationname = $myinvocation.mycommand.name.Substring(0, $myinvocation.mycommand.name.IndexOf('.'))
 

$exportFileName 
 
function out($line) 
{ 
    $line | Out-File $exportFileName -append 
} 

function writeSampleConfigurationFile()
{
$sampleFile = @"
<CrawlerConfig searchServiceApplication='FASTContent'>
	<CrawlContentSources>
		<CrawlContentSource name='SPC 2011'>
			<Property name='Type'>SharePoint</Property>
			<Property name='CrawlPriority'>1</Property>
			<Property name='SharePointCrawlBehavior'>CrawlSites</Property>
			<Property name='StartAddresses'>
			<Property name='StartAddress'>http://$env:computername/sites/spc2011</Property>
			</Property>
		</CrawlContentSource>
		<CrawlContentSource name='FileShare'>
			<Property name='Type'>File</Property>
			<Property name='CrawlPriority'>1</Property>
			<Property name='StartAddresses'>
			<Property name='StartAddress'>file://$env:computername/xmlcontent</Property>
			</Property>
			<Property name='FollowDirectories'>True</Property>
		</CrawlContentSource>
		<CrawlContentSource name='HTML FileShare'>
			<Property name='Type'>File</Property>
			<Property name='CrawlPriority'>1</Property>
			<Property name='StartAddresses'>
			<Property name='StartAddress'>file://$env:computername/htmlcontent</Property>
			</Property>
			<Property name='FollowDirectories'>True</Property>
		</CrawlContentSource>
    	<CrawlContentSource name='Oracle Scott BDC '>
			<Property name='Type'>Business</Property>
			<Property name='CrawlPriority'>1</Property>
			<Property name='StartAddresses'>
			<Property name='StartAddress'>bdc3://oracle_2_oracle_sys_instance_2/Default/00000000%252D0000%252D0000%252D0000%252D000000000000/Oracle%25202/Oracle%2520Sys%2520Instance%25202&amp;s_ce=04082402000204080g01004020800</Property>
			</Property>
		</CrawlContentSource>
	</CrawlContentSources>
</CrawlerConfig>
"@ | Out-File "$directoryForConfigFile\SPC2011ContentSources.xml"

}

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
 
function writeProperty($prop, $value, $indent) 
{ 
    if($value -eq $null){return} 
     
    $line = "" 
    for($i=0; $i -lt $indent; $i++){$line += "`t"} 
    $line += "<Property name='"+$prop+"'>" + $value + "</Property>" 
    out -line $line 
} 
 
function exportContentSource($obj) 
{ 
    out -line ("`t`t<CrawlContentSource name='"+$obj.Name+"'>") 
     
    writeProperty -prop "Type" -value $obj.Type -indent 3 
    writeProperty -prop "CrawlPriority" -value $obj.CrawlPriority.value__ -indent 3 
    writeProperty -prop "MaxPageEnumerationDepth" -value $obj.MaxPageEnumerationDepth -indent 3 
    writeProperty -prop "MaxSiteEnumerationDepth" -value $obj.MaxSiteEnumerationDepth -indent 3 
    writeProperty -prop "SharePointCrawlBehavior" -value $obj.SharePointCrawlBehavior -indent 3 
     
    out -line ("`t`t`t<Property name='StartAddresses'>") 
    foreach($addr in $obj.StartAddresses) 
    { 
        writeProperty -prop "StartAddress" -value $addr.tostring().replace('&','&amp;') -indent 4 
    } 
    out -line ("`t`t`t</Property>") 
    writeProperty -prop "FollowDirectories" -value $obj.FollowDirectories -indent 3 
     
    if($obj.FullCrawlSchedule -ne $null) 
    { 
        $schedule = $obj.FullCrawlSchedule 
        out -line ("`t`t`t<Property name='FullCrawlSchedule'>") 
    } 
    elseif($obj.IncrementalCrawlSchedule -ne $null) 
    { 
        $schedule = $obj.IncrementalCrawlSchedule 
        out -line ("`t`t`t<Property name='IncrementalCrawlSchedule'>") 
    } 
    if($schedule -ne $null) 
    { 
        out -line ("`t`t`t`t<Property name='ScheduleType'>" + $schedule.GetType().Name + "</Property>") 
        $schedProps = $schedule | Get-Member -MemberType Property 
        $props = $schedProps| % {$_.Name}  
        foreach($p in $props) 
        { 
            if($p -eq "Description"){continue} 
            if($p -eq "NextRunTime"){continue} 
            writeProperty -prop "$p" -value $schedule.$p -indent 4 
        } 
        out -line ("`t`t`t</Property>") 
    } 
     
    out -line "`t`t</CrawlContentSource>" 
} 
 
function exportCrawlRule($obj) 
{ 
    out -line ("`t`t<CrawlRule name='"+$obj.Path+"'>") 
 
    writeProperty -prop "Path" -value $obj.Path -indent 3 
    writeProperty -prop "Type" -value $obj.Type -indent 3 
    writeProperty -prop "CaseSensitiveURL" -value $obj.CaseSensitiveURL -indent 3 
    writeProperty -prop "CrawlAsHttp" -value $obj.CrawlAsHttp -indent 3 
    writeProperty -prop "FollowComplexUrls" -value $obj.FollowComplexUrls -indent 3 
    writeProperty -prop "IsAdvancedRegularExpression" -value $obj.IsAdvancedRegularExpression -indent 3 
    writeProperty -prop "SuppressIndexing" -value $obj.SuppressIndexing -indent 3 
    writeProperty -prop "Priority" -value $obj.Priority -indent 3 
     
    out -line "`t`t</CrawlRule>" 
} 
 
 
function exportFileExtensions($obj) 
{ 
    out -line ("`t`t<FileExtension>") 
    writeProperty -prop "ext" -value $obj.FileExtension -indent 3 
    out -line "`t`t</FileExtension>" 
} 
 
 
function exportCrawlerConfiguration($ssa) 
{ 
    $xmlFile = New-item -itemtype file $exportFilename  -force 
     
    $line = "<CrawlerConfig searchServiceApplication='"+$ssa.Name+"'>" 
    out -line $line 
             
    Write-Host "Exporting Content Sources..." 
    out -line "`t<CrawlContentSources>" 
    write-host SSA: $ssa
    $sources = (Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $ssa) 
    foreach($s in $sources) 
    { 
        exportContentSource -obj $s 
    } 
    out -line "`t</CrawlContentSources>" 
     
    Write-Host "Exporting Crawl Rules..." 
    out -line "`t<CrawlRules>" 
    $rules = (Get-SPEnterpriseSearchCrawlRule -SearchApplication $ssa) 
    foreach($r in $rules) 
    { 
        exportCrawlRule -obj $r 
    } 
    out -line "`t</CrawlRules>" 
     
    Write-Host "Exporting File Extensions..." 
    out -line "`t<FileExtensions>" 
    $extenstions = (Get-SPEnterpriseSearchCrawlExtension -SearchApplication $ssa) 
    foreach($ext in $extenstions) 
    { 
        exportFileExtensions -obj $ext 
    } 
    out -line "`t</FileExtensions>" 
     
    #export -objects (Get-SPEnterpriseSearchCrawlMapping -SearchApplication $ssa) -type "CrawlMapping" 
    #export -objects (Get-SPEnterpriseSearchCrawlDatabase -SearchApplication $ssa) -type "CrawlDatabase" 
    #export -objects (Get-SPEnterpriseSearchCrawlCustomConnector -SearchApplication $ssa) -type "CrawlCustomConnector" 
    #need to loop through topologies 
    #export -objects (Get-SPEnterpriseSearchCrawlTopology -CrawlTopology $ssa.CrawlTopologies) -type "CrawlTopology" 
    #export -objects (Get-SPEnterpriseSearchCrawlComponent -CrawlTopology $ssa.CrawlTopologies) -type "CrawlTopology" 
     
    out -line "</CrawlerConfig>" 
     
} 
 
function writeHelp() 
{ 
    Write-Host -foregroundcolor 'green' "This script file exports Crawler Settings to an XML file." 
    Write-Host -foregroundcolor 'green' "" 
    Write-Host -foregroundcolor 'green' "Use the -list switch to list all application names." 
    Write-Host -foregroundcolor 'green' "Use the -ServiceApplication option to export a specific Search Service Application." 
    Write-Host -foregroundcolor 'green' "Use the -overwrite switch to overwrite existing export files." 
    Write-Host -foregroundcolor 'green' "Use the -createTemplate switch to create a template import file for Crawler Settings." 
    Write-Host -foregroundcolor 'green' "Example: <script_file>.ps1 -list" 
    Write-Host -foregroundcolor 'green' "Example: <script_file>.ps1 -SearchServiceApplication <NameOfSearchServiceApplication>" 
} 
 
function main($name, $list, $createTemplate, $overwrite, $help) 
{
    if($GenerateSampleConfigurationFile)
    {
	    writeSampleConfigurationFile
		exit
	}
 
    if($createTemplate) 
    { 
        $fileName = "Crawler_Config_Template.xml" 
        if((Test-Path $fileName) -and !$overwrite){ Write-Host "Template file $filename already exists."; return} 
        Write-Host "Creating template file $fileName" 
        writeTemplate($fileName) 
        Write-Host "Done." 
        return 
    } 
    if($list) 
    { 
        $ssa = Get-SPEnterpriseSearchServiceApplication 
        if($ssa) 
        { 
            foreach($app in $ssa) 
            { 
                Write-Host "Search Service Application Name: " $app.Name 
            } 
        } 
        else 
        { 
            Write-Host -foregroundcolor 'red' "Unable to find a Search Service Application." 
        } 
        return 
    } 
     
    if(!$name) 
    { 
        #try and get name, if there is only 1 ssa 
        $ssa = Get-SPEnterpriseSearchServiceApplication
        if($ssa -and $ssa.Length -eq 1) 
        {     
            $name = $ssa.Name 
            #fall through 
        } 
        elseif($ssa -and $ssa.Length -gt 1) 
        { 
           [int]$count = 0
           foreach ($sa in $ssa)
           {
              write-host $count - $ssa[$count].name
              $count += 1
           }
           $ssa = $ssa[(read-host "Enter the SSA number")]
           $name = $ssa.name
           write-host SSA selected: $name
           #write-host SSA: $ssa
        } 
    } 
 
    if($name) 
    { 
        #check to see if we already have an ssa from above 
        if(!$ssa){$ssa = Get-SPEnterpriseSearchServiceApplication -Identity $name} 
        if($ssa) 
        { 
            $exportFilename = "Crawler_Config_"+$ssa.Name+".xml" 
            if((Test-Path $exportFilename) -and !$overwrite) 
            {  
                Write-Host -foregroundcolor 'red' "Export file $exportFilename already exists." 
                return 
            } 
 
            Write-Host "Exporting Crawl Settings for Search Service Application for name=" $name 
            exportCrawlerConfiguration -ssa $ssa 
            Write-Host "Completed export. " 
            return 
        } 
        else 
        { 
            Write-Host -foregroundcolor 'red' "Unable to get Search Service Application for name=" $name 
        } 
        return 
    } 
     
    writeHelp     
} 
 
main -name $SearchServiceApplication $list $createTemplate $overwrite $help
 


# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUiFSOYhUzMHysvZuovsemHBy2
# GZagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFIKNm3g+a3WlQLVc
# NXSUfuyjRroYMA0GCSqGSIb3DQEBAQUABIIBAH5uA0PkZU210GvQsccF5lg5Ezd+
# vCLHyOOz+tDHwUosb2+RhZuEelj2SVPuFPWFHzcjPQ6F4aJTfwM4gmP1WwxywpVc
# Igecp+XjANkF3eso+tYyN6JIsZmqehs4cuPod34Ur5Kc8hVxv8SdaCi97t8eqIiB
# RBdmdoHEl7CNtrhGmytaFDp2PL1Lw6lccDrjwbunTPmKc8vXNbUo8A8Jpl1P50Yq
# ZczbbsGYSMj+UIKDJ8Ox3cJr7S4/V6aNJdho7gSicN/JjnUT+NgM0ryyFhCCL0mM
# 6A57/lj/9wo45HOZkhpVgGJ0AkB1WzcEW7nYVXT9UpwP4iy7Jibyd8N8vZM=
# SIG # End signature block
