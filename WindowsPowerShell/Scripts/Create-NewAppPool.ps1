if (@(Get-PSSnapin | Where-Object {$_.Name -eq "WebAdministration"}).Count -eq 0)
    {
    Add-PSSnapin WebAdministration
    }

$cred = Get-Credential "MYDOMAIN\THEuserACCOUNTforTHEappPool"
$userName = $cred.UserName
$password = $cred.GetNetworkCredential().Password
if (Test-Path IIS:\AppPools\MyTestAppPool) {
    Remove-Item IIS:\AppPools\MyTestAppPool -Force -Recurse
    }
$myNewPool = New-Item IIS:\AppPools\MyTestAppPool
$myNewPool.processModel.userName = $userName
$myNewPool.processModel.password = $password
$myNewPool.processModel.identityType = "SpecificUser"
$myNewPool.processModel.idleTimeout = [TimeSpan] "0.00:00:00"
$myNewPool.managedRuntimeVersion = "4.0"   # or 2.0
$myNewPool.recycling.periodicRestart.time = [TimeSpan] "00:00:00"
$myNewPool | Set-Item