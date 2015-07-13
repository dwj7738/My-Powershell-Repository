Configuration MSFT_xFirefox
{
    param
    (
        [string]$VersionNumber = "31.0",
        [string]$Language = "en-US",
	[string]$OS = "win",
        [string]$MachineBits = "x86",
	[string]$LocalPath = "$env:SystemDrive\Windows\DtlDownloads\Firefox Setup " + $versionNumber +".exe"
    )
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    xRemoteFile Downloader
    {
         Uri = "http://download.mozilla.org/?product=firefox-" + $VersionNumber +"&os="+$OS+"&lang=" + $Language 
	 DestinationPath = $LocalPath
    }
	 
    Package Installer
    {
	 Ensure = "Present"
	 Path = $LocalPath
         Name = "Mozilla Firefox " + $VersionNumber + " (" + $MachineBits + " " + $Language +")"
	 ProductId = ''
         Arguments = "/SilentMode"
         DependsOn = "[xRemoteFile]Downloader"
    }
}