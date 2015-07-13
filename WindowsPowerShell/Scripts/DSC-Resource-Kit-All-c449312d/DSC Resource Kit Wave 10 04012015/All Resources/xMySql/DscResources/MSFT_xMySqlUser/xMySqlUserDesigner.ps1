# a Powershell script to create MySqlDatabase resource using xDSCResourceDesigner tool
$friendlyName = "xMySqlGrant"
$resourceName = "MSFT_$friendlyName"
$classVersion = "1.0.0"

$scriptRoot = Split-Path $MyInvocation.MyCommand.Path
$originalModuleRoot = join-Path $scriptroot "..\.."
$originalModuleRootPath = Resolve-Path $originalModuleRoot
$moduleRoot = Join-Path $env:temp "$($originalModuleRootPath.path | split-path -Leaf)Temp"

$resources = @()
$schemaPath = (join-path $scriptRoot "$resourceName.schema.mof")

#Key properties
$resources += New-xDscResourceProperty -Name Name -Type String -Attribute Key -Description "Name of MySQL user to create or remove." 

#Write properties
$resources += New-xDscResourceProperty -Name Credential -Type PSCredential -Attribute Write -Description "Credential for MySql user."
$resources += New-xDscResourceProperty -Name ConnectionCredential -Type PSCredential -Attribute Write -Description "MySql connection credential used to create a user."
$resources += New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -Description "Ensure mysql user is present or absent." -ValidateSet @("Present","Absent") 


Write-Host Resource is being created...

# Create a New template resource to a temporary folder
New-xDscResource -Property $resources -ClassVersion $classVersion -Name $resourceName -Path $moduleRoot -FriendlyName $friendlyName