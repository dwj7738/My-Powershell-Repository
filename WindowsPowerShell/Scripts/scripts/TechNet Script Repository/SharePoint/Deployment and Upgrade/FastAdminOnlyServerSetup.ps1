param([Switch]$viewAllCrawledProperties, [Switch]$resetPipelineExtensibility, [string]$configDir="config")


# todo: implement an uninstall/clean section
$homedir=$pwd.Path
# remove the best bets and synonyms if they exist
if (test-path ".\Scripts\TechNet Script Repository\SharePoint\Search Management\csv")
{            
  remove-item '.\Scripts\TechNet Script Repository\SharePoint\Search Management\csv' -Force -Recurse
}


cd '.\Scripts\TechNet Script Repository\SharePoint\Search Management'
if (test-path "..\..\..\..\$configDir\FASTSearch\keywords\csv")
{
  cp -r ..\..\..\..\$configDir\FASTSearch\keywords\csv
  $ssg = Get-FASTSearchSearchSettingGroup
  .\Import-FASTKeywordsandUserContextstoSharepoint2010fromCSV.ps1 -name $ssg.name
}
cd $homedir

cd '.\Scripts\TechNet Script Repository\SharePoint\Search Management'
.\Maintain-FASTSearchMetadataProperties.ps1 -ConfigurationFile "$homedir\$configDir\FASTSearch\Maintain-FASTSearchMetadataProperties.config"
cd $homedir

cd \fastsearch\installer\scripts
.\AdvancedFilterPack.ps1 -enable -confirmSecurityWarning
cd $homedir


