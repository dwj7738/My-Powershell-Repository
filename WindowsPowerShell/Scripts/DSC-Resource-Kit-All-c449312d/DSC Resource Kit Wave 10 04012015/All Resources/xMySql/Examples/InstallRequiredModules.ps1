# This Script installs the required modules for the MySql Sample
# It uses the PowerShell Resource Gallery, see https://msconfiggallery.cloudapp.net/
# This requires WMF 5.  If you don't have WMF 5, Please install the modules manually.

Write-Host "Installing required modules..."
Install-Module xMySql -MinimumVersion 1.0.1 -Force
