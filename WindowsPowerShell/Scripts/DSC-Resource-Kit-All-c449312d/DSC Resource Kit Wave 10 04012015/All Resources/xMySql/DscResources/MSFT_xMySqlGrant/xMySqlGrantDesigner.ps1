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
$resources += New-xDscResourceProperty -Name UserName -Type String -Attribute Key -Description "Name of MySQL user." 
$resources += New-xDscResourceProperty -Name DatabaseName -Type String -Attribute Key -Description "MySql database name to grant permissions." 

#Write properties
$resources += New-xDscResourceProperty -Name ConnectionCredential -Type PSCredential -Attribute Write -Description "MySql connection credential used for the root."
$resources += New-xDscResourceProperty -Name PermissionType -Type String -Attribute Write -Description "Ensure given grant to mySql database present or absent." -ValidateSet @("ALL PRIVILEGES", "CREATE", "DROP", "DELETE", "INSERT", "SELECT", "UPDATE", "EXECUTE") 
$resources += New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -Description "Ensure given grant to mySql database present or absent." -ValidateSet @("Present","Absent") 


Write-Host Resource is being created...

# Create a New template resource to a temporary folder
New-xDscResource -Property $resources -ClassVersion $classVersion -Name $resourceName -Path $moduleRoot -FriendlyName $friendlyName