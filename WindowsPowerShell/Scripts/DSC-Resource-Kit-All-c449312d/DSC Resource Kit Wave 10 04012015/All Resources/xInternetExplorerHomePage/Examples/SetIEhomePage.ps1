#--------------------------------------------------------------------------------- #The sample scripts are not supported under any Microsoft standard support #program or service. The sample scripts are provided AS IS without warranty  #of any kind. Microsoft further disclaims all implied warranties including,  #without limitation, any implied warranties of merchantability or of fitness for #a particular purpose. The entire risk arising out of the use or performance of  #the sample scripts and documentation remains with you. In no event shall #Microsoft, its authors, or anyone else involved in the creation, production, or #delivery of the scripts be liable for any damages whatsoever (including, #without limitation, damages for loss of business profits, business interruption, #loss of business information, or other pecuniary loss) arising out of the use #of or inability to use the sample scripts or documentation, even if Microsoft #has been advised of the possibility of such damages #--------------------------------------------------------------------------------- 

Configuration SetIEHomePage
{
    Param
    (
        #Target nodes to apply the configuration  
        [String[]]$NodeName = $env:COMPUTERNAME,  
  
        #Specifies the URL for the home page of Internet Explorer.
        [Parameter(Mandatory)]  
        [ValidateNotNullOrEmpty()]  
        [String]$StartPageURL,  
  
        #Specifies the URL for the secondary home pages of Internet Explorer.
        [Parameter()]   
        [String]$SecondaryStartPagesURL,  
  
        #Set the value as 'Present'/'Absent', it indicates the IE home page is configured/unconfigured.
        [Parameter(Mandatory)]  
        [ValidateSet('Present','Absent')]  
        [String]$SetEnsure
    )
    
    Import-DSCResource -ModuleName xInternetExplorerHomePage

    Node "localhost"
    {
        xInternetExplorerHomePage IEHomePage
        {
            StartPage = $StartPageURL
            SecondaryStartPages = $SecondaryStartPagesURL
            Ensure = $SetEnsure
        }
    }
}

SetIEHomePage -StartPageURL "www.bing.com" -SecondaryStartPagesURL "www.google.com" -SetEnsure 'Present'
Start-DscConfiguration -Path .\SetIEHomePage  -Wait -Force -Verbose