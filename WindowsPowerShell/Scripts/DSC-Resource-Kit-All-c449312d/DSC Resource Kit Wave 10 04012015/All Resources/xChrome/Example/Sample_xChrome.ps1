#Installs the latest version of Chrome in the language specified in the parameter Language.

Configuration Sample_InstallChromeBrowser
{
    param
    (
	[Parameter(Mandatory)]
	$Language,
		
	[Parameter(Mandatory)]
	$LocalPath
		
    )
	
    Import-DscResource -module xChrome
	
    MSFT_xChrome chrome
    {
	Language = $Language
	LocalPath = $LocalPath
    }
}