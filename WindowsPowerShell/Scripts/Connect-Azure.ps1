$mySubID = "d77de785-04d2-469b-98b5-b6481e9a5742"
$certThumbprint = "441A0EF8E6EC955BAA91017198A248F010EB0E7B"
$myCert = Get-Item cert:\CurrentUser\My\$certThumbprint
$mySubName = " Visual Studio Premium with MSDN"
Set-AzureSubscription -SubscriptionName $mySubName -Certificate $myCert -SubscriptionID $mySubID
Select-AzureSubscription -SubscriptionName $mySubName
get-azurewebsite
Get-AzureEnvironment
get-azureconfig
Set-AzureStorageAccount ultimatesolution



