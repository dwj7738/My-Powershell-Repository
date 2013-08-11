# Contributors: Eric Dixon, Keenan Newton, Brent Groom, Cem Aykan, Dan Benson
param([string]$name="", [switch]$list,[switch]$allgroups)

Add-PSSnapin Microsoft.FASTSearch.PowerShell -erroraction SilentlyContinue 


function save-KeywordContext($ssg, $folder) 
{
    #Save Contexts
    saveContext -ssg $ssg -contextCSVFile "$folder\Context.csv"
    
    #Save Keywords
    saveKeyWord -ssg $ssg -keywordCSVFile "$folder\Keyword.csv"
    
    #Save BestBets
    saveBestBet -ssg $ssg -bestBetCSVFile "$folder\BestBet.csv"

    #Save Visual BestBets
    saveVisualBestBet -ssg $ssg -visualBestBetCSVFile "$folder\VisualBestBet.csv"
    
    #Save Document Promotions
    saveDocumentPromotion -ssg $ssg -documentPromotionCSVFile "$folder\DocumentPromotion.csv"
}

function saveContext($ssg, $contextCSVFile) 
{
    Write-Host "Creating file $contextCSVFile"
    $csvFile = New-item -itemtype file $contextCSVFile  -force
    "User Context, Ask Me About, Office Location" | Out-File $contextCSVFile
     
    foreach($context in $ssg.Contexts)
    {
        if(!($context.Name))
        {
            continue
        }
        Write-Host "Saving Context: " $context.Name
        
        $askMeAbout = ""
        $officLocations = ""
        
        foreach($exp in $context.ContextExpression)
        {
            if($exp.Name -eq "SPS-Responsibility" -and $exp.Value)
            {
                $askMeAbout += $exp.Value + ";"
            }
            elseif ($exp.Name -eq "SPS-Location" -and $exp.Value)
            {
                $officLocations += $exp.Value + ";"
            }
        }
        $askMeAbout = $askMeAbout.Trim(";")
        $officLocations = $officLocations.Trim(";")
        
        $line = '"' + $context.Name +'","'+ $askMeAbout +'","'+ $officLocations +'"'
        $line | Out-File $contextCSVFile -append
           
    }
}

function saveKeyWord($ssg, $keywordCSVFile) 
{
    $foundkeywords = $false

    foreach($keyword in $ssg.Keywords) 
    {
        if(!($keyword.Term))
        {
            continue
        }
        if($foundkeywords -eq $false)
        {
          Write-Host "Creating file $keywordCSVFile"
          $csvFile = New-item -itemtype file $keywordCSVFile  -force
          "Keyword, Definition, Two-Way Synonym, One-Way Synonym" | Out-File $keywordCSVFile
          $foundkeywords = $true
        }
        Write-Host "Saving Keyword: " $keyword.Term
        
        $synonyms_oneway = ""
        $synonyms_twoway = ""
        foreach($synonym in $keyword.synonyms)
        {
            if($synonym.ExpansionType -eq "TwoWay")
            {
                $synonyms_twoway += $synonym.Term + ";"
            }    
            elseif($synonym.ExpansionType -eq "OneWay")
            {
                $synonyms_oneway += $synonym.Term + ";"
            }
        }
        $synonyms_oneway = $synonyms_oneway.Trim(";")
        $synonyms_twoway = $synonyms_twoway.Trim(";")
        
        #$line = '"'+$keyword.Term+'","'+$keyword.Definition+'","'+$synonyms_twoway+'","'+$synonyms_oneway+'"'
        $line = '"'+$keyword.Term+'"," ","'+$synonyms_twoway+'","'+$synonyms_oneway+'"'
        $line | Out-File $keywordCSVFile -append
    }
    
}

function saveBestBet($ssg, $bestBetCSVFile) 
{
    $foundbb = $false
    foreach($bb in $ssg.BestBets)
    {
        if(!($bb.Name))
        {
            continue
        }
        if($foundbb -eq $false)
        {
            Write-Host "Creating file $bestBetCSVFile"
            $csvFile = New-item -itemtype file $bestBetCSVFile  -force
            "BestBet, User Context, Keyword, Description, Url, Start Date, End Date, Position" | Out-File $bestBetCSVFile
            $foundbb = $true
        }
        Write-Host "Saving BestBet: " $bb.Name
        
        $contexts = ""
        foreach($context in $bb.contexts)
        {
            $contexts += $context.Name + ";"
        }
        $contexts = $contexts.Trim(";")
        $line = '"'+$bb.Name+'","'+$contexts+'","'+$bb.Keyword.Term+'","'+$bb.Description+'","'+$bb.Uri+'","'+$bb.StartDate+'","'+$bb.EndDate+'","'+$bb.Position+'"'
        $line | Out-File $bestBetCSVFile -append    
    }
}

function saveVisualBestBet($ssg, $visualBestBetCSVFile) 
{
    $foundvbb = $false
    foreach($vbb in $ssg.FeaturedContent)
    {
        if(!($vbb.Name))
        {
            continue
        }
        if($foundvbb -eq $false)
        {
            Write-Host "Creating file $visualBestBetCSVFile"
            $csvFile = New-item -itemtype file $visualBestBetCSVFile  -force
            "Visual BestBet, User Context, Keyword, Url, Start Date, End Date, Position"  | Out-File $visualBestBetCSVFile
            $foundvbb = $true
        }
        Write-Host "Saving Visual BestBet: " $vbb.Name
        
        $contexts = ""
        foreach($context in $vbb.contexts)
        {
            $contexts += $context.Name + ";"
        }
        $contexts = $contexts.Trim(";")
        $line = '"'+$vbb.Name+'","'+$contexts+'","'+$vbb.Keyword.Term+'","'+$vbb.Uri+'","'+$vbb.StartDate+'","'+$vbb.EndDate+'","'+$vbb.Position+'"'
        $line | Out-File $visualBestBetCSVFile -append
    }
}

function saveDocumentPromotion($ssg, $documentPromotionCSVFile) 
{
    $foundpromo = $true

    foreach($promo in $ssg.Promotions)
    {
        if(!($promo.Name))
        {
            continue
        }
        if($foundpromo -eq $false)
        {
            Write-Host "Creating file $documentPromotionCSVFile"
            $csvFile = New-item -itemtype file $documentPromotionCSVFile  -force
            "Title, User Context, Keyword, Url, Start Date, End Date, Boost Value" | Out-File $documentPromotionCSVFile
            $foundpromo = $true
        }
        Write-Host "Saving Promotion: " $promo.Name
        
        $contexts = ""
        foreach($context in $promo.contexts)
        {
            $contexts += $context.Name + ";"
        }
        $contexts = $contexts.Trim(";")
        
        $urls = ""
        foreach($url in $promo.PromotedItems)
        {
            $urls += $url.DocumentId + "|"
        }
        $urls = $urls.Trim("|")
        
        $line = '"'+$promo.Name+'","'+$contexts+'","'+$promo.Keyword.Term+'","'+$urls+'","'+$promo.StartDate+'","'+$promo.EndDate+'","'+$promo.BoostValue+'"'
        $line | Out-File $documentPromotionCSVFile -append
    }
}

function main($name, $list, $allgroups)
{
    if($list -or $allgroups)
    {
        $ssg = Get-FASTSearchSearchSettingGroup
        if($ssg)
        {
            foreach($group in $ssg)
            {
                Write-Host "Search Setting Group Name: " $group.Name
                if($allgroups)
                {
                    $ssg = Get-FASTSearchSearchSettingGroup -name $group.Name
                    if($ssg)
                    {
                        save-KeywordContext -ssg $ssg -folder "csv-$($group.Name)"
                    }
                    else
                    {
                        Write-Host -foregroundcolor 'red' "Unable to get Search Setting Group for name=" $name
                    }
                }
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
            save-KeywordContext -ssg $ssg -folder "csv-$($name)"
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
        save-KeywordContext -ssg $ssg -folder "csv-$($name)"
    }
    else
    {
        Write-Host -foregroundcolor 'red' "Found more than one Search Setting Group."
        Write-Host -foregroundcolor 'red' "Use the -list switch to list all group names."
        Write-Host -foregroundcolor 'red' "Use the -name option to export a specific Search Setting Group."
        Write-Host -foregroundcolor 'red' "Example: <script_file>.ps1 -list"
        Write-Host -foregroundcolor 'red' "Example: <script_file>.ps1 -name <NameOfSearchSettingGroup>"
    }
}


main $name $list $allgroups



