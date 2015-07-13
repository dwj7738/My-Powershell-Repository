# This configuration will, via the xPHP composite configuration:
# 1) Make sure IIS is installed
# 2) Make sure PHP is present
# 3) Make sure that PHP is registered with IIS
# 4) Make sure PHP is in the path
#
# ********* NOTE ***********
# PHP changes their download URLs frequently.  Please verify the URL.
# the VC Redist URL changes less frequently, but should still be verified.
# After verifying the download URLs for the products and update them appropriately.
# **************************
$scriptRoot = Split-Path $MyInvocation.MyCommand.Path
$phpIniPath = (Join-Path $scriptRoot "phpConfigTemplate.txt")
if (-not (Test-Path $phpIniPath))
{
    $message = "Missing required file $phpIniPath"
    # This file is in the samples folder of the resource
    throw $message
}
Configuration SamplePhp
{
    # Import composite resources
    Import-DscResource -module xPhp

    Node "localhost"
    {

        File PackagesFolder
        {
            DestinationPath = "C:\package"
            Type = "Directory"
            Ensure = "Present"
        }

        # Make sure PHP is installed in IIS
        xPhp  php
        {
            InstallMySqlExt = $true
            PackageFolder =  "C:\package"
            # Update with the latest "VC11 x64 Non Thread Safe" from http://windows.php.net/download/
            DownloadURI = "http://windows.php.net/downloads/releases/php-5.5.14-nts-Win32-VC11-x64.zip"
            DestinationPath = "C:\php"
            ConfigurationPath = $phpIniPath
            Vc2012RedistDownloadUri = "http://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"

            # Removed because this dependency does not work in Windows Server 2012 R2 and below
            # This should work in WMF v5 and above
            # DependsOn = "[IisPreReqs_WordPress]Iis"
        }
    }
}

SamplePhp

Start-DscConfiguration -path .\SamplePhp -wait -verbose