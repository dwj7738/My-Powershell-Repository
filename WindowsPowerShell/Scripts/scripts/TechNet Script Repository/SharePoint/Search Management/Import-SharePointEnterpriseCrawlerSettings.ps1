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

