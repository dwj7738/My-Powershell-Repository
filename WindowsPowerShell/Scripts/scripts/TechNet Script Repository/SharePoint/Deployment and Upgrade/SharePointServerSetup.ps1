param([switch]$setWebPartProperties, [switch]$crawlSources, [switch]$createSources, [switch]$allSteps, [string]$configDir = "config")


function main()
{
    if($allSteps)
    {
        $setWebPartProperties = $true
        $crawlSources = $true
        $createSources = $true
    }

    $installEnv = $env:FS4SPINSTALLENV
    $FASTContentSSA = $env:FASTContentSSA
    if($FASTContentSSA.length -eq 0)
    {
        "You must setup the environment variable FASTContentSSA. Modify and execute the file SetupEnvironment.ps1"
        return
    }

    $FASTSearchCenter = $env:FASTSearchCenter
    if($FASTContentSSA.length -eq 0)
    {
        "You must setup the environment variable FASTSearchCenter. Modify and execute the file SetupEnvironment.ps1"
        return
    }

    if($installEnv.length -gt 0)
    {
        # Set the farm properties
        #cd ".\Scripts\TechNet Script Center\Deployment and Upgrade"
        #.\Set-FarmProperties.ps1 -ConfigurationFile ".\..\..\..\SharePoint\$configDir\Properties-$installEnv.config"
        #cd ..\..\..

        #Reload the BDC Model
        #cd ".\Scripts\SharePoint"
        #.\Import-BDCModel.ps1 -modelFilePath ".\..\..\SharePoint\$configDir\Model.xml" -serviceContextUrl "http://localhost" -entityNamespace "http://www.microsoft.com" -entityName "Entity1" -modelName "ModelName"
        #cd ..\..
        if($createSources)
        {
            cd ".\scripts\TechNet Script repository\SharePoint\Search Management"
            $contentSourceFile = "..\..\..\..\$configDir\SharePoint\ContentSources.xml"
            if (($contentSourceFile.length -gt 0) -and (test-path "$contentSourceFile"))
            {
                .\Import-SharePointEnterpriseCrawlerSettings.ps1 -importFile $contentSourceFile -SearchApplication $FASTContentSSA
                Write-Host "Sleep until content sources are created"
                Start-Sleep -m 20000
            }
            else
            {
                "Could not find content source file: $contentSourceFile"
            }
            cd ..\..\..\..

        }
        if($crawlSources)
        {
            cd ".\scripts\TechNet Script repository\SharePoint\Search Management"
            .\CrawlAllContentSources.ps1 -SearchServiceApplication $FASTContentSSA
            cd ..\..\..\..
            "Done starting crawl of content sources"
        }

        # If the content source exists then remove the content source on the Content SSA
        #cd ".\Scripts\SharePoint"
        #.\Remove-SPEnterpriseSearchCrawlContentSource.ps1 -SSAName "FAST Content SSA" -contentSourceName "Model Content Source"
        #cd ..\..

        # Create the content source on the Content SSA
        #cd ".\Scripts\SharePoint"
        #.\New-SPEnterpriseSearchCrawlContentSourceLOB.ps1 -SSAName "FAST Content SSA" -contentSourceName "Model Content Source" -LobSystemInstanceName "LOBInstanceName" -LobSystemName "LOBSystemName"
        #cd ..\..

        # Deploy the web part 
        #cd ".\Scripts\SharePoint"
        #.\RedeploySolution.ps1
        #cd ..\..
        if($setWebPartProperties)
        {
            "Starting setup of web part properties"
            cd ".\scripts\TechNet Script repository\SharePoint\Search Management"
            $webPartConfigFile = ".\..\..\..\..\$configDir\SharePoint\Set-WebPartProperties.xml"
            if (($webPartConfigFile.length -gt 0) -and (test-path "$webPartConfigFile"))
            {
                .\Set-WebPartProperties.ps1 -configfile $webPartConfigFile -sitenameinput $FASTSearchCenter
            }
            cd ..\..\..\..
        }
    }
    else
    {
        "You must run SetupEnvironment.ps1 first" 
    }
}

main 



