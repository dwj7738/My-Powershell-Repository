<#
 filename:Manage-SPEnterpriseSearchCrawlRules.ps1

 Create an xml configuration file of the following form. This is meant to be placed in the farm configuration file
 For this version the code is hard coded to look at a local xml file: SPDeploymentConfig.xml

 <Configuration>
 ...
  <crawlrules>
    <searchapplication name="FASTContent" type="InclusionRule" csvfile="CrawlRules-Include.csv"/>
    <searchapplication name="FASTContent" type="ExclusionRule" csvfile="CrawlRules-Exclude.csv"/>
  </crawlrules>
 ...
 
 Create csv files of the following format
PS C:\Users\sp_admin\Desktop\MESGLab\scripts> type .\CrawlRules-Exclude.csv
path
*yellowpages.com*
http://cnn.com

PS C:\Users\sp_admin\Desktop\MESGLab\scripts> type .\CrawlRules-Include.csv
path
http://msnbc.com
*contoso.com*

 Reference

 New-SPEnterpriseSearchCrawlRule - http://technet.microsoft.com/en-us/library/ff608119(office.14).aspx
#>

# Read in the deployment file to find out about the crawl rules and the search application to add them to
# Read in a text file containing a list of sites
# Iterate the list and create a crawl rule for each line

Function mainwork([string]$configfile)
{
	$xmldata = [xml](Get-Content $configfile)

	$searchapplications = $xmldata.SelectNodes("Configuration/crawlrules/searchapplication")
	foreach ($searchapplication in $searchapplications)
	{
        $searchapplicationname = $searchapplication.name
        $crawltype = $searchapplication.type
        $csvfile = $searchapplication.csvfile
        $urls = import-csv -Path $csvfile
        foreach ($url in $urls)
        {
            $urlpath = $url.path
            
            New-SPEnterpriseSearchCrawlRule -SearchApplication $searchapplicationname -Path $urlpath -Type $crawltype
        }        
    }
}

mainwork SPDeploymentConfig.xml




