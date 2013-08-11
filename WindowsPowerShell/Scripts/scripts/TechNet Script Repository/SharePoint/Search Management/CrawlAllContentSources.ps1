<#
.SYNOPSIS 
       This script starts a full crawl of all content sources within a search service application. 
.DESCRIPTION 
       This script starts a full crawl of all content sources within a search service application. 
       This script is used in conjunction with the SharePointServerSetup script and together they 
       help create a mechanism for rapidly developing custom search solutions. Also, this script 
       can be autodownloaded with many other search related powershell scripts by running the 
       download script.

.LINK 
This Script - http://gallery.technet.microsoft.com/CrawlAllContentSources-8b722858
Download Script - http://gallery.technet.microsoft.com/DownloadScriptsv2-cfbf4342
.NOTES 
  File Name : CrawlAllContentSources.ps1 
  Author    : Brent Groom 
#>

param([string]$SearchServiceApplication="")

Add-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue  
if($SearchServiceApplication.length -gt 0)
{
  $cs = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $SearchServiceApplication
  foreach($c in $cs)
  {
    if($c -ne $null)
    {
      $c.StartFullCrawl()
    }
    else
    {
      "Could not find any content sources to crawl for $SearchServiceApplication"
    }
  }
}
else
{
  "You must specify a valid Search Service Application"
}
