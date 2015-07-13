# This Script installs the required modules for the WordPress Sample
# It uses the PowerShell Resource Gallery, see https://msconfiggallery.cloudapp.net/
# This requires WMF 5.  If you don't have WMF 5, Please install the modules manually.

Write-Host "Installing required modules..."
Install-Module xWebAdministration -MinimumVersion 1.3.2 -Force
Install-Module xPSDesiredStateConfiguration -MinimumVersion 3.0.1 -Force
Install-Module xMySql -MinimumVersion 1.0 -Force
Install-Module xWordPress -MinimumVersion 1.0 -Force
Install-Module xPhp -MinimumVersion 1.0.1 -Force
