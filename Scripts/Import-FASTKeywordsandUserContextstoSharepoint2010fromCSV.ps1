# Contributors: Eric Dixon, Keenan Newton, Brent Groom, Cem Aykan, Dan Benson
param([string]$name="", [switch]$list, [switch]$GenerateSampleConfigurationFile, [string]$directoryForConfigFile=$pwd.Path)

Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 

function add-KeywordContext($ssg, $folder) {
    #Add Contexts
    addContext -ssg $ssg -contextCSVFile "$folder\Context.csv"
    
    #Add Keywords
    addKeyWord -ssg $ssg -keywordCSVFile "$folder\Keyword.csv"
    
    #Add BestBets
    addBestBet -ssg $ssg -bestBetCSVFile "$folder\BestBet.csv"

    #Add Visual BestBets
    addVisualBestBet -ssg $ssg -visualBestBetCSVFile "$folder\VisualBestBet.csv"
    
    #Add Document Promotions
    addDocumentPromotion -ssg $ssg -documentPromotionCSVFile "$folder\DocumentPromotion.csv" 
}

function createSampleFiles($pathToSampleFiles)
{  
 
$defaultfile = @"
BestBet, User Context, Keyword, Description, Url, Start Date, End Date, Position
"bing","","bing","","http://bing.com/","","",""
"Vacation","","Vacation","","http://www.expedia.com","","",""
"@ | Out-File "$pathToSampleFiles\BestBet.csv" 
$defaultfile = @"
Visual BestBet, User Context, Keyword, Url, Start Date, End Date, Position
"@ | Out-File "$pathToSampleFiles\VisualBestBet.csv" 
$defaultfile = @"
Title, User Context, Keyword, Url, Start Date, End Date, Boost Value
"@ | Out-File "$pathToSampleFiles\DocumentPromotion.csv" 
$defaultfile = @"
User Context, Ask Me About, Office Location
"@ | Out-File "$pathToSampleFiles\Context.csv" 
$defaultfile = @"
Keyword,Definition,Two-Way Synonym,One-Way Synonym
spc2011,<DIV></DIV>,Anaheim;Sharepoint Conference 2011,
bing,<DIV></DIV>,,
Vacation,<DIV></DIV>,,
"@ | Out-File "$pathToSampleFiles\Keyword.csv" 

} 

function addContext($ssg, $contextCSVFile) {
    $contextCSV = Import-CSV -Path $contextCSVFile -erroraction SilentlyContinue 
    
    foreach($row in $contextCSV) {

        $userContextName = $row."User Context"
        $askMeAbout = $row."Ask Me About"
        $officeLocation = $row."Office Location"
        
        if ($ssg.Contexts.ContainsContext($userContextName))
        {
            Write-Host "Context '$userContextName' already exists. Dettaching it from all search settings and recreating it based on csv file data."
            
            $cx = $ssg.Contexts.GetContext($userContextName)
            foreach ($setting in $cx.SearchSettings)
            {
                $setting.DetachContext($cx)
            }
            $ssg.Contexts.RemoveContext($userContextName)
        }
        
        Write-Host "Adding Context: $userContextName"
        
        $cx = $ssg.Contexts.AddContext($userContextName)
        $cx.Description = $userContextName
        
        $rootExpr = $cx.AddAndExpression()
        
        if($askMeAbout -and $askMeAbout.Contains(";")) {
            $orExpr = $rootExpr.AddOrExpression()
            $askMeAbouts = $askMeAbout.Split(";")
            
            foreach($item in $askMeAbouts) {
                [void]$orExpr.AddMatchExpression("SPS-Responsibility", $item)
            }
            
        } else {
            [void]$rootExpr.AddMatchExpression("SPS-Responsibility", $askMeAbout)
        }
        
        if($officeLocation -and $officeLocation.Contains(";")) {
            $orExpr = $rootExpr.AddOrExpression()
            $officeLocations = $officeLocation.Split(";")
            
            foreach($item in $officeLocations) {
                [void]$orExpr.AddMatchExpression("SPS-Location", $item)
            }
            
        } else {
            [void]$rootExpr.AddMatchExpression("SPS-Location", $officeLocation)
        }
    }
}

function addKeyWord($ssg, $keywordCSVFile) {
    $keywordCSV = Import-CSV -Path $keywordCSVFile -erroraction SilentlyContinue 
    
    foreach($row in $keywordCSV) {

        $keywordName = $row."Keyword"
        $definition = $row."Definition"
        $twoWaySynonym = $row."Two-Way Synonym"
        $oneWaySynonym = $row."One-Way Synonym"
        
        if ($ssg.Keywords.ContainsKeyword($keywordName)) {
            Write-Host "Keyword '$keywordName' already exists. Recreating it based on csv file data."
            $ssg.Keywords.RemoveKeyword($keywordName);
        }
        else
        {
            Write-Host "Adding Keyword: $keywordName"
        }

        $keyword = $ssg.Keywords.AddKeyword($keywordName);
        
        if([String]::IsNullOrEmpty($definition)) {
            $keyword.Definition = "<DIV></DIV>"
        } else {
            $keyword.Definition = $definition
        }
        
        if(![String]::IsNullOrEmpty($twoWaySynonym)) {
            $synType = [Microsoft.SharePoint.Search.Extended.Administration.Keywords.SynonymExpansionType]::TwoWay
            if($twoWaySynonym.Contains(";")) {
                $twoWaySynonyms = $twoWaySynonym.Split(";")
                
                foreach($item in $twoWaySynonyms) {
                    [void]$keyword.AddSynonym($item, $synType)
                }
                
            } else {
                [void]$keyword.AddSynonym($twoWaySynonym, $synType)
            }
        }
        
        if(![String]::IsNullOrEmpty($oneWaySynonym)) {
            $synType = [Microsoft.SharePoint.Search.Extended.Administration.Keywords.SynonymExpansionType]::OneWay
            if($oneWaySynonym.Contains(";")) {
                $oneWaySynonyms = $oneWaySynonym.Split(";")
                
                foreach($item in $oneWaySynonyms) {
                    [void]$keyword.AddSynonym($item, $synType)
                }
                
            } else {
                [void]$keyword.AddSynonym($oneWaySynonym, $synType)
            }
        }
    }
}

function addBestBet($ssg, $bestBetCSVFile) {
    $bestBetCSV = Import-CSV -Path $bestBetCSVFile -erroraction SilentlyContinue 

    foreach($row in $bestBetCSV) {

        $bestBetName = $row."BestBet"
        $contextName = $row."User Context"
        $keywordName = $row."Keyword"
        $description = $row."Description"
        $url = $row."Url"
        $startDate = $row."Start Date"
        $endDate = $row."End Date"
        $position = $row."Position"

        Write-Host "Adding BestBet '$bestBetName' to Keyword '$keywordName'"

        if($keywordName) {
            if($keywordName.Contains(";")) {
                $keywordNames = $keywordName.Split(";")
                
                foreach($item in $keywordNames) {
                    $keyword = $ssg.Keywords.GetKeyword($item)
                    if($keyword) {
                        addBestBetToKeyword -keyword $keyword -bestBetName $bestBetName -contextName $contextName -description $description -url $url -startDate $startDate -endDate $endDate -position $position
                    }
                }
                
            } else {
                $keyword = $ssg.Keywords.GetKeyword($keywordName)
                if($keyword) {
                    addBestBetToKeyword -keyword $keyword -bestBetName $bestBetName -contextName $contextName -description $description -url $url -startDate $startDate -endDate $endDate -position $position
                }
            }
        }
    }
}

function addVisualBestBet($ssg, $visualBestBetCSVFile) {
    $visualBestBetCSV = Import-CSV -Path $visualBestBetCSVFile -erroraction SilentlyContinue 

    foreach($row in $visualBestBetCSV) {

        $visualBestBetName = $row."Visual BestBet"
        $contextName = $row."User Context"
        $keywordName = $row."Keyword"
        $url = $row."Url"
        $startDate = $row."Start Date"
        $endDate = $row."End Date"
        $position = $row."Position"
        
        Write-Host "Adding Visual BestBet '$visualBestBetName' to Keyword '$keywordName'"

        if($keywordName) {
            if($keywordName.Contains(";")) {
                $keywordNames = $keywordName.Split(";")
                
                foreach($item in $keywordNames) {
                    $keyword = $ssg.Keywords.GetKeyword($item)
                    if($keyword) {
                        addVisualBestBetToKeyword -keyword $keyword -visualBestBetName $visualBestBetName -contextName $contextName -url $url -startDate $startDate -endDate $endDate -position $position
                    }
                }
                
            } else {
                $keyword = $ssg.Keywords.GetKeyword($keywordName)
                if($keyword) {
                    addVisualBestBetToKeyword -keyword $keyword -visualBestBetName $visualBestBetName -contextName $contextName -url $url -startDate $startDate -endDate $endDate -position $position
                }
            }
        }
    }
}

function addDocumentPromotion($ssg, $documentPromotionCSVFile) 
{
    $documentPromotionCSV = Import-CSV -Path $documentPromotionCSVFile -erroraction SilentlyContinue 

    foreach($row in $documentPromotionCSV) {

        $contextName = $row."User Context"
        $documentPromotionName = $row."Title"
        $keywordName = $row."Keyword"
        $url = $row."Url"
        $startDate = $row."Start Date"
        $endDate = $row."End Date"
        $boostValue = $row."Boost Value"

        Write-Host "Adding Promotion $documentPromotionName"
        
        if($keywordName) {
            if($keywordName.Contains(";")) {
                $keywordNames = $keywordName.Split(";")
                
                foreach($item in $keywordNames) {
                    $keyword = $ssg.Keywords.GetKeyword($item)
                    if($keyword) {
                        addDocumentPromotionToKeyword -keyword $keyword -documentPromotionName $documentPromotionName -boostValue $boostValue -contextName $contextName -url $url -startDate $startDate -endDate $endDate
                    }
                }
                
            } else {
                $keyword = $ssg.Keywords.GetKeyword($keywordName)
                if($keyword) {
                    addDocumentPromotionToKeyword -keyword $keyword -documentPromotionName $documentPromotionName -boostValue $boostValue -contextName $contextName -url $url -startDate $startDate -endDate $endDate
                }
            }
        }

    }
}

function populateSearchSetting($searchSetting, $name, $description, $startDate, $endDate, $contextName) {
    if($name) { $searchSetting.Name = $name }
    if($description) { $searchSetting.Description = $description }
    if($startDate) { $searchSetting.StartDate = $startDate }
    if($endDate) { $searchSetting.EndDate = $endDate }
    
    if($contextName) {
        if($contextName.Contains(";")) {
            $contextNames = $contextName.Split(";")
            
            foreach ($item in $contextNames)
            {
                if ($searchSetting.Group.Contexts.ContainsContext($item))
                {
                    $cx = $searchSetting.Group.Contexts.GetContext($item)
                    [void]$searchSetting.AttachContext($cx)
                }
                else
                {
                    Write-Host "Searchsetting '$name' references a context that doesn't exist: '$item'"
                }
            }
        } else {
            if ($searchSetting.Group.Contexts.ContainsContext($contextName))
            {
                $cx = $searchSetting.Group.Contexts.GetContext($contextName)
                [void]$searchSetting.AttachContext($cx)
            }
            else
            {
                Write-Host "Searchsetting '$name' references a context that doesn't exist: '$contextName'"
            }
        }
    }
}

function addBestBetToKeyword ($keyword, $bestBetName, $contextName, $description, $url, $startDate, $endDate, $position) {
    $bestBet = $keyword.BestBets.GetBestBet($bestBetName)
    
    if($bestBet) {
        Write-Host "BestBet '$bestBetName' already exists. Dettaching it from all search settings and recreating it based on csv file data."
        $keyword.RemoveBestBet($bestBet)
    }
    
    $bestBet = $keyword.AddBestBet($bestBetName)
    $bestBet.Uri = New-Object Uri($url)
    $bestBet.Position = $position
    
    populateSearchSetting -searchSetting $bestBet -name $bestBetName -description $description -startDate $startDate -endDate $endDate -contextName $contextName
    
}

function addVisualBestBetToKeyword ($keyword, $visualBestBetName, $contextName, $url, $startDate, $endDate, $position) {
    $visualBestBet = $keyword.FeaturedContent.GetFeaturedContent($visualBestBetName)
    
    if($visualBestBet) {
        Write-Host "Visual BestBet '$visualBestBetName' already exists. Dettaching it from all search settings and recreating it based on csv file data."
        $keyword.RemoveFeaturedContent($visualBestBet)
    }
    
    $visualBestBet = $keyword.AddFeaturedContent($visualBestBetName)
    $visualBestBet.Uri = New-Object Uri($url)
    $visualBestBet.Position = $position
    
    populateSearchSetting -searchSetting $visualBestBet -name $visualBestBetName -startDate $startDate -endDate $endDate -contextName $contextName
    
}

function addDocumentPromotionToKeyword ($keyword, $documentPromotionName, $boostValue, $contextName, $url, $startDate, $endDate) {
    $documentPromotion = $keyword.Promotions.GetPromotion($documentPromotionName)
    
    if($documentPromotion) {
        Write-Host "Promotion '$documentPromotionName' already exists. Dettaching it from all search settings and recreating it based on csv file data."
        $keyword.RemovePromotion($documentPromotion)
    }
    
    $documentPromotion = $keyword.AddPromotion($documentPromotionName)    
    $documentPromotion.BoostValue = $boostValue

    if($url.Contains("|")) {
        $urls = $url.Split("|")
        
        foreach($item in $urls) {
            $uri = New-Object Uri($item)
            [void]$documentPromotion.PromotedItems.AddPromotedDocument($uri)
        }
    } else {
        $uri = New-Object Uri($url)
        [void]$documentPromotion.PromotedItems.AddPromotedDocument($uri)
    }
    
    populateSearchSetting -searchSetting $documentPromotion -name $documentPromotionName -startDate $startDate -endDate $endDate -contextName $contextName
}

function main($name, $list)
{
    if($GenerateSampleConfigurationFile)
    {
      
      createSampleFiles $directoryForConfigFile
      exit
    }
    
    if($list)
    {
        $ssg = Get-FASTSearchSearchSettingGroup
        if($ssg)
        {
            foreach($group in $ssg)
            {
                Write-Host "Search Setting Group Name: " $group.Name
            }
        }
        else
        {
            Write-Host -foregroundcolor 'red' "Unable to find a Search Setting Group."
        }
        return
    }
    
    if($name)
    {
        $ssg = Get-FASTSearchSearchSettingGroup -name $name
        if($ssg)
        {
            add-KeywordContext -ssg $ssg -folder "csv"
        }
        else
        {
            Write-Host -foregroundcolor 'red' "Unable to get Search Setting Group for name=" $name
        }
        return
    }
    
    $ssg = Get-FASTSearchSearchSettingGroup
    if($ssg -and $ssg.Length -eq 1)
    {    
        add-KeywordContext -ssg $ssg -folder "csv"
    }
    else
    {
        Write-Host -foregroundcolor 'red' "Found more than one Search Setting Group."
        Write-Host -foregroundcolor 'red' "Use the -list switch to list all group names."
        Write-Host -foregroundcolor 'red' "Use the -name option to import to a specific Search Setting Group."
        Write-Host -foregroundcolor 'red' "Example: <script_file>.ps1 -list"
        Write-Host -foregroundcolor 'red' "Example: <script_file>.ps1 -name <NameOfSearchSettingGroup>"
    }
}


main $name $list



# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOhmL/LApUDs7xjjfvolnTNFb
# 9sagggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
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
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEOYhy/sqrzjijz0
# AQZ++oD+gApnMA0GCSqGSIb3DQEBAQUABIIBAHuK7X7HeAmqnwL0rST9l3ISEV9I
# scosVFZ6ddf6Y4RrUCYZbgIsoMTgJ/Tyauhvfyne2QpybJRZO3ReLS0mnq3I4eB1
# i7IyvHlKtnE8Q2vt3ruZ6pTiFCNxjx+3+xceFzxuJLAKhdRBSc+bNNUwSjQpyJMx
# ggAYbBvhteX/faUaxGqTj13DNJxwQKWDuRlNWIkGPEk4YPZRHjtE97NKibH8QU8f
# EmnTBMa8QlctCyMHakLKvtONP2ZGqOzs4uaWDuiILS4jwvzg9OMViZn9RJkTI+AJ
# OpFpbt0cuCF+sXxr+2CwCMp41+MFO8VFRdVwX8ZTDfZ22g6EanRJ3+Q5vuk=
# SIG # End signature block
