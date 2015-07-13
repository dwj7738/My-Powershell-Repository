#Installs the specified version of Firefox in the specified language.

Configuration Sample_InstallFirefoxBrowser
{
    param
    (
		
	[Parameter(Mandatory)]
	$VersionNumber,
		
        [Parameter(Mandatory)]
	$Language,
		
	[Parameter(Mandatory)]
	$OS,
		
	[Parameter(Mandatory)]
	$LocalPath		
		
    )
	
    Import-DscResource -module xFirefox
	
    MSFT_xFirefox firefox
    {
	VersionNumber = $VersionNumber
	Language = $Language
	OS = $OS
	LocalPath = $LocalPath
    }
}