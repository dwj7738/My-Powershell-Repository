Configuration MSFT_xChrome
{
    param
    (
	[string]$Language = "en",
	[string]$LocalPath = "$env:SystemDrive\Windows\DtlDownloads\GoogleChromeStandaloneEnterprise.msi"
    )
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    xRemoteFile Downloader
    {
        Uri = "https://dl.google.com/tag/s/appguid={8A69D345-D564-463C-AFF1-A69D9E530F96}&iid={00000000-0000-0000-0000-000000000000}&lang="+$Language+"&browser=3&usagestats=0&appname=Google%2520Chrome&needsadmin=prefers/edgedl/chrome/install/GoogleChromeStandaloneEnterprise.msi" 
        DestinationPath = $LocalPath
    }
	 
    Package Installer
    {
	Ensure = "Present"
	Path = $LocalPath
	Name = "Google Chrome"
	ProductId = ''
        DependsOn = "[xRemoteFile]Downloader"
    }
}