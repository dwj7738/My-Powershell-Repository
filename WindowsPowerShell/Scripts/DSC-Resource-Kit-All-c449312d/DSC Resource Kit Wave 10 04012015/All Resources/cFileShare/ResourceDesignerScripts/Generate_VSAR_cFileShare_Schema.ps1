#This creates the definition for the resource

#The share to create
$ShareName = New-xDscResourceProperty -Name ShareName -Type String -Attribute Key

#The path where the folder that maps to the share should be created
$Path      = New-xDscResourceProperty -Name Path -Type String -Attribute Required

#Identify if the action is to create the share or remove the share (i.e. should it be present or absent)
$Ensure    = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present", "Absent"

#An array of users who should have full access
$FullAccessUsers      = New-xDscResourceProperty -Name FullAccessUsers -Type String[] -Attribute Write

#An array of users who should have change access
$ChangeAccessUsers    = New-xDscResourceProperty -Name ChangeAccessUsers -Type String[] -Attribute Write

#An array of users who should have read access
$ReadAccessUsers      = New-xDscResourceProperty -Name ReadAccessUsers -Type String[] -Attribute Write

#Create the actual resource
New-xDscResource -Name VSAR_cCreateFileShare -Property $ShareName, $Path, $Ensure -Path 'C:\Program Files\WindowsPowerShell\Modules\cFileShare' -FriendlyName cCreateFileShare
New-xDscResource -Name VSAR_cSetSharePermissions -Property $ShareName, $Ensure, $FullAccessUsers, $ChangeAccessUsers, $ReadAccessUsers -Path 'C:\Program Files\WindowsPowerShell\Modules\cFileShare' -FriendlyName cSetSharePermissions