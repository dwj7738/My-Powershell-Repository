<#
 filename:RemoveAll-SPEnterpriseSearchCrawlRules.ps1

 Create an xml configuration file of the following form. This is meant to be placed in the farm configuration file
 For this version the code is hard coded to look at a local xml file: SPDeploymentConfig.xml

 <Configuration>
 ...
  <crawlrules>
    <searchapplication name="FASTContent" type="InclusionRule" csvfile="CrawlRules-Include.csv"/>
    <searchapplication name="FASTContent" type="ExclusionRule" csvfile="CrawlRules-Exclude.csv"/>
  </crawlrules>
 ...
 

 Reference

 New-SPEnterpriseSearchCrawlRule - http://technet.microsoft.com/en-us/library/ff608119(office.14).aspx
#>
 
# Iterate the list of searchapplications and remove the crawl rules for each application

Function mainwork([string]$configfile)
{
    $searchapplicationCache = @{}
	$xmldata = [xml](Get-Content $configfile)

	$searchapplications = $xmldata.SelectNodes("Configuration/crawlrules/searchapplication")
	foreach ($searchapplication in $searchapplications)
	{
        $searchapplicationCache[$searchapplication.name] = $searchapplication.name
    }
    foreach ($sa in $searchapplicationCache.keys)
    {
        $crawlrules = Get-SPEnterpriseSearchCrawlRule -SearchApplication $sa
        if ($crawlrules.Length -gt 0)
        {
            foreach ( $crawlrule in $crawlrules)
            {
                Remove-SPEnterpriseSearchCrawlRule -Identity $crawlrule -Confirm:$false
            }
        }
    }
}

mainwork SPDeploymentConfig.xml
