# Sample script to create the template or update the Wordpress Resource

# Resource Details 
# Friendly name of the resource:
$friendlyName = "xWordPressSite"
# Name of the resource:
$resourceName = "MSFT_$friendlyName"
# Class Version of the resource:
$classVersion = "1.0.0"


# Various Paths
$diff = join-Path ${env:ProgramFiles(x86)} "Beyond compare 2\bc2.exe"
$scriptRoot = Split-Path $MyInvocation.MyCommand.Path
$originalModuleRoot = join-Path $scriptroot "..\.."
$originalModuleRootPath = Resolve-Path $originalModuleRoot
$moduleRoot = Join-Path $env:temp "$($originalModuleRootPath.path | split-path -Leaf)Temp"

$resources = @()
$schemaPath = (join-path $scriptRoot "$resourceName.schema.mof")

#Key properties
$resources += New-xDscResourceProperty -Name Uri -Type String -Attribute Key -Description "The WordPress Site URI." 


#Required Properites
$resources += New-xDscResourceProperty -Name Title -Type String -Attribute Required -Description "The WordPress Site Default page title." 
$resources += New-xDscResourceProperty -Name AdministratorCredential -Type PSCredential -Attribute Required -Description "The username and password of the WordPress administrator to create when creating the site." 
$resources += New-xDscResourceProperty -Name AdministratorEmail -Type String -Attribute Required -Description "The email address of the WordPress administrator to create." 

#Write Properties
$resources += New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -Description "Currenly only Present is allowed." -ValidateSet @("Present") 

#Read Properties
#$resources += New-xDscResourceProperty -Name EndPointSetup -Type Boolean -Attribute Read -Description "The End Point is setup.  Such as a Fast Cgi endpoint."



Write-Host updating...

# Create a New template resource to a temporary folder
New-xDscResource -Property $resources -ClassVersion $classVersion -Name $resourceName -Path $moduleRoot -FriendlyName $friendlyName


# Use your favorite diff program to compare and merge the current resource and the existing resource
if((test-Path $diff))
{
    &$diff $originalModuleRoot  $moduleRoot 
}
else
{
    Write-Warning "Diff propgram not found!`r`nUse your favorite diff program to compare and merge:`r`n `t$($originalModuleRootPath.path)`r`n and:`r`n `t$moduleRoot"
}

