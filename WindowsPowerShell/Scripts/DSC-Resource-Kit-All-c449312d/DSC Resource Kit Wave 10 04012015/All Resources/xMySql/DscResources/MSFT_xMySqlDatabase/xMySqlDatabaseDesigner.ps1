# a Powershell script to create MySqlDatabase resource using xDSCResourceDesigner tool
$friendlyName = "xMySqlDatabase"
$resourceName = "MSFT_$friendlyName"
$classVersion = "1.0.0"

$scriptRoot = Split-Path $MyInvocation.MyCommand.Path
$originalModuleRoot = join-Path $scriptroot "..\.."
$originalModuleRootPath = Resolve-Path $originalModuleRoot
$moduleRoot = Join-Path $env:temp "$($originalModuleRootPath.path | split-path -Leaf)Temp"

$resources = @()
$schemaPath = (join-path $scriptRoot "$resourceName.schema.mof")

#Key properties
$resources += New-xDscResourceProperty -Name Name -Type String -Attribute Key -Description "Name of the database." 

#Write properties
$resources += New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -Description "Should the database be present or absent." -ValidateSet @("Present","Absent") 
$resources += New-xDscResourceProperty -Name ConnectionCredential -Type PSCredential -Attribute Write -Description "The user credential that is used to install MySql server."


Resource is being created...


# Create a New template resource to a temporary folder
New-xDscResource -Property $resources -ClassVersion $classVersion -Name $resourceName -Path $moduleRoot -FriendlyName $friendlyName