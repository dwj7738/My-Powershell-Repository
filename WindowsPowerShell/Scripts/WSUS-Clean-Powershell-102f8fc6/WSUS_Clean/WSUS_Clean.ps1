# Performs a cleanup of WSUS.
# Outputs the results to a text file.
# Adapted and tested by BigTeddy
# 3 July 2012

$outFilePath = '.\wsusClean.txt'
[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
$cleanupScope = new-object Microsoft.UpdateServices.Administration.CleanupScope;
$cleanupScope.DeclineSupersededUpdates = $true       
$cleanupScope.DeclineExpiredUpdates         = $true
$cleanupScope.CleanupObsoleteUpdates     = $true
$cleanupScope.CompressUpdates                  = $true
#$cleanupScope.CleanupObsoleteComputers = $true
$cleanupScope.CleanupUnneededContentFiles = $true
$cleanupManager = $wsus.GetCleanupManager();
$cleanupManager.PerformCleanup($cleanupScope) | Out-File -FilePath $outFilePath
