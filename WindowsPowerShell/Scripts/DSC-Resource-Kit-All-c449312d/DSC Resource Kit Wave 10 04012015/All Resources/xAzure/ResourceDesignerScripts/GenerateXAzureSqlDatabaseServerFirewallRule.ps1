$Name = New-xDscResourceProperty -Name RuleName -Type String -Attribute Key -Description 'Name of the firewall rule'
$ServerName = New-xDscResourceProperty -Name ServerName -Type String -Attribute Key -Description 'Name of the database server for which firewall rule should be created'
$StartIPAddress = New-xDscResourceProperty -Name StartIPAddress -Type String -Attribute Required -Description 'Start IP address of the firewall rule'
$EndIPAddress = New-xDscResourceProperty -Name EndIPAddress -Type String -Attribute Required -Description 'End IP address of the firewall rule'
$AzureSubscriptionName = New-xDscResourceProperty -Name AzureSubscriptionName -Type String -Attribute Write -Description 'Specifies the name of the Azure subscription that should be set to Current'
$AzurePublishSettingsFile = New-xDscResourceProperty -Name AzurePublishSettingsFile -Type String -Attribute Write -Description 'Specifies the location of the Publish Settings file for the Azure Subscription'
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present", "Absent" -Description 'Ensure that firewall rule is present or absent'
New-xDscResource -Name MSFT_xAzureSqlDatabaseServerFirewallRule -Property @($Name, $ServerName, $StartIPAddress, $EndIPAddress, $AzureSubscriptionName, $AzurePublishSettingsFile, $Ensure) -ModuleName xAzure -FriendlyName xAzureSqlDatabaseServerFirewallRule
