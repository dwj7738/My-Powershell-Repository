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


