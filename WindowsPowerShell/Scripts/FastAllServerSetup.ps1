param([string]$configDir="config", [switch]$viewAllCrawledProperties)

function mainwork
{

$homedir=$pwd.Path
$scriptdir = ".\scripts\TechNet Script Repository\SharePoint\Search Management"
cd $scriptdir

if($resetPipelineExtensibility)
{

}

if($viewAllCrawledProperties)
{
    # NOTE!!! This powershell script will OVERWRITE your existing pipelineextensibility.xml file
    .\View-AllCrawledProperties-PipelineExtensibility.ps1 -getFASTCrawledProperties -deploy
}
cd $homedir

#net stop FS4SPPipelineExtensibilityWebService
Copy-Item -Path .\$configDir\FASTSearch\overlay\* -Destination $env:fastsearch -Force -Recurse

#net start FS4SPPipelineExtensibilityWebService
psctrl reset
Start-Sleep -Seconds 5
nctrl restart procserver_1
nctrl restart procserver_2
nctrl restart procserver_3
nctrl restart procserver_4

}

mainwork

