<# 
.SYNOPSIS 
       The purpose of this script is to deploy a set of configuration files and settings to a sharepoint and fast farm 
.DESCRIPTION 
       The purpose of this script is to deploy a set of configuration files and settings to a sharepoint and fast farm 
       This script is used in conjunction with the SharePointServerSetup script and together they 
       help create a mechanism for rapidly developing custom search solutions. Also, this script 
       can be autodownloaded with many other search related powershell scripts by running the 
       download script.

.EXAMPLE
.\deploy.ps1 -deploySampleConfigStarterPackage

Runs the deployment package

.LINK 
This Script - http://gallery.technet.microsoft.com/deploy-fabe1771
Download Script - http://gallery.technet.microsoft.com/DownloadScriptsv2-cfbf4342

.NOTES 
  File Name : deploy.ps1 
  Author    : Brent Groom, Peter Lenhart
#> 
 
param([Switch]$deploySampleConfigSiteNameRefiner, [Switch]$deploySampleConfigShowAllCrawledAndManagedProperties, [Switch]$deploySampleConfigStarterPackage)

$configurationname = $myinvocation.mycommand.name.Substring(0, $myinvocation.mycommand.name.IndexOf('.')) 


function mainwork
{   
    
    if($deploySampleConfigStarterPackage)
    {
        .\SetupEnvironment.ps1 -dev01
        .\FastAdminOnlyServerSetup.ps1 -configDir SampleConfigStarterPackage
        .\FastAllServerSetup.ps1 -configDir SampleConfigStarterPackage
        .\SharePointServerSetup.ps1 -allSteps -configDir SampleConfigStarterPackage
    }    
    
    if($deploySampleConfigShowAllCrawledAndManagedProperties)
    {
        .\FastAdminOnlyServerSetup.ps1 -configDir SampleConfigShowAllCrawledAndManagedProperties
        .\FastAllServerSetup.ps1 -viewAllCrawledProperties -configDir SampleConfigShowAllCrawledAndManagedProperties
        .\SharePointServerSetup.ps1 -allSteps -configDir SampleConfigShowAllCrawledAndManagedProperties
    }
    
    if($deploySampleConfigSiteNameRefiner)
    {
        .\FastAdminOnlyServerSetup.ps1 -configDir SampleConfigSiteNameRefiner
        .\FastAllServerSetup.ps1 -configDir SampleConfigSiteNameRefiner
        .\SharePointServerSetup.ps1 -allSteps -configDir SampleConfigSiteNameRefiner
    }

    $DEPLOY_ROLES = iex $ENV:DEPLOY_ROLES
    if($DEPLOY_ROLES -contains "FASTDOCPROC")
    {          
          "Setting up FAST Doc Proc server using config directory: $($env:ConfigurationDirectory)"
          .\FastAllServerSetup.ps1 -configDir $($env:ConfigurationDirectory)
    }

    if($DEPLOY_ROLES -contains "FASTADMIN")
    {          
          "Setting up FAST Admin server using config directory: $($env:ConfigurationDirectory)"
          .\FastAdminOnlyServerSetup.ps1 -configDir $($env:ConfigurationDirectory)
    }

    if($DEPLOY_ROLES -contains "SP")
    {  
          "Setting up SharePoint server using config directory: $($env:ConfigurationDirectory)"
          net share xmlfiles /delete
          net share xmlfiles=$($pwd.Path)\$($env:ConfigurationDirectory)\PlatinumContent\xml
                
          .\SharePointServerSetup.ps1 -allSteps -configDir $($env:ConfigurationDirectory)
    }

}

mainwork 

