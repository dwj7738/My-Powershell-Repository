<#
.SYNOPSIS 
       This script sets system variables specific to each installation farm  
.DESCRIPTION 
       This script sets system variables specific to each installation farm  
       This script is used in conjunction with the SharePointServerSetup script and together they 
       help create a mechanism for rapidly developing custom search solutions. Also, this script 
       can be autodownloaded with many other search related powershell scripts by running the 
       download script.

.LINK 
This Script - http://gallery.technet.microsoft.com/CrawlAllContentSources-8b722858
Download Script - http://gallery.technet.microsoft.com/DownloadScriptsv2-cfbf4342
.NOTES 
  File Name : SetupEnvironment.ps1 
  Author    : Brent Groom 
#>

param([Switch]$StandaloneServer)

function IdentifyCurrentInstallation()
{
    # Environment to server mapping
    $arrStandaloneServer = "DEMO2010A"
    $arrDevDave = "DAVESERVER1", "DAVESERVER2"
    $arrOAT1 = "SPCENTRALADMINSVR"
    $arrDEVVMSET1 = "FASTADMINSVR"
    $arrDEVVMSET2 = "FASTDOCPROCSVR"
    $arrPROD = "FASTDOCPROCSVR"

    $DEPLOY_CURRENT_INSTALLATION = "UNKOWN"
   
    if($arrDevDave -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "DEVDAVE"
    }
    elseif($arrOAT -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "OAT"
    }
    elseif($arrDEVVMSET1 -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "DEVVMSET1"
    }
    elseif($arrDEVVMSET2 -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "DEVVMSET2"
    }
    elseif($arrPROD -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "PROD"
    }
    elseif($arrStandaloneServer -contains $env:computername)
    {
        $DEPLOY_CURRENT_INSTALLATION = "STANDALONESERVER"
    } 
    elseif($StandaloneServer)
    {
        $DEPLOY_CURRENT_INSTALLATION = "STANDALONESERVER"
    }



    # set environment variable so it is persistent on the machine
    $output = setx DEPLOY_CURRENT_INSTALLATION $DEPLOY_CURRENT_INSTALLATION /M
    # set an environment variable for the local command window
    $env:DEPLOY_CURRENT_INSTALLATION = $DEPLOY_CURRENT_INSTALLATION
    # Display that the environment variable is set
    "Set Environment variable DEPLOY_CURRENT_INSTALLATION to $($env:DEPLOY_CURRENT_INSTALLATION) "
    

}

# This function reads a file, replaces a specific set of environment variables, and writes the changed file
function ReplaceVariablesInFiles()
{
    $fileToProcess = ".\$env:configurationDirectory\SharePoint\ContentSources.xml"
    # TODO if there isn't a backup, make a backup of the original file 
    $fileContents = get-content $fileToProcess
    $fileContents = $fileContents -replace '\$\(\$env:computername\)', "$($env:computername)"
    $fileContents | Out-File $fileToProcess

}


function IdentifyRoles()
{
    # machine to role mapping
    #
    # Valid Roles: ALL, FASTALL, SP, FASTADMIN, FASTDOCPROC 

    $arrSP = "SPCENTRALADMINSVR","DEMO2010A"
    $arrFASTADMIN = "FASTADMINSVR","DEMO2010A"
    $arrFASTDOCPROC = "FASTDOCPROCSVR","DEMO2010A"


    # This is the array of roles for the current server
    # To translate this into a powershell array use: $DEPLOY_RULES = iex $ENV:DEPLOY_ROLES 
    $arrROLES = '"ArraryOfRolesForThisServer"'
        
    if($arrSP -contains $env:computername)
    {
        $arrROLES += ',"SP"'
    }
    if($arrFASTADMIN -contains $env:computername)
    {
        $arrROLES += ',"FASTADMIN"'
    }
    if($arrFASTDOCPROC -contains $env:computername)
    {
        $arrROLES += ',"FASTDOCPROC"'
    }
    # set environment variable so it is persistent on the machine
    $output = setx DEPLOY_ROLES $arrROLES /M
    # set an environment variable for the local command window
    $env:DEPLOY_ROLES = $arrROLES
    # Display that the environment variable is set
    "Set Environment variable DEPLOY_ROLES to $($env:DEPLOY_ROLES) "
    $DEPLOY_ROLES = iex $ENV:DEPLOY_ROLES

}

#couldn't get this to work...
function setenvironmentvariable([string]$name, [string]$value)
{
    # set a machine environment variable for all users
    setx $name $value /M
    # set an environment variable for the local command window
    #???$env:"$name"=$value
    #$env:$name
}

function main() 
{
    IdentifyRoles
    IdentifyCurrentInstallation
    $installEnv = ""
    if($ENV:DEPLOY_CURRENT_INSTALLATION -eq "STANDALONESERVER")
    {
        # set a machine environment variable for all users
        $output = setx FASTSEARCHSITENAME "http://$env:computername" /M
        # set an environment variable for the local command window
        $env:FASTSEARCHSITENAME = "http://$env:computername"
        "Set Environment variable FASTSEARCHSITENAME to $($env:FASTSEARCHSITENAME) "

        #--------------------------------------------------------------------
        $newvarname = "FS4SPINSTALLENV"
        $newvarval = "$($env:computername)"
        # set environment variable so it is persistent on the machine
        $output = setx FS4SPINSTALLENV "$env:computername" /M
        # set an environment variable for the local command window
        $env:FS4SPINSTALLENV = "$env:computername"
        # Display that the environment variable is set
        "Set Environment variable FS4SPINSTALLENV to $($env:FS4SPINSTALLENV) "

        #--------------------------------------------------------------------
        # set environment variable so it is persistent on the machine
        $output = setx FASTContentSSA "FASTContent" /M
        # set an environment variable for the local command window
        $env:FASTContentSSA = "FASTContent"
        # Display that the environment variable is set
        "Set Environment variable FASTContentSSA to $($env:FASTContentSSA) "

        #------------- FAST Search Center -------------------------------------------
        # set environment variable so it is persistent on the machine
        $output = setx FASTSearchCenter "http://intranet.contoso.com/search" /M
        # set an environment variable for the local command window
        $env:FASTSearchCenter = "http://intranet.contoso.com/search"
        # Display that the environment variable is set
        "Set Environment variable FASTSearchCenter to $($env:FASTSearchCenter) "

        #------------- Configuration Directory --------------------------------------
        # set environment variable so it is persistent on the machine
        $output = setx ConfigurationDirectory "DefaultConfig" /M
        # set an environment variable for the local command window
        $env:ConfigurationDirectory = "DefaultConfig"
        # Display that the environment variable is set
        "Set Environment variable ConfigurationDirectory to $($env:ConfigurationDirectory) "

        #------------- Configuration Directory --------------------------------------
        # set environment variable so it is persistent on the machine
        $output = setx ServerRole "ALL" /M
        # set an environment variable for the local command window
        $env:ServerRole = "ALL"
        # Display that the environment variable is set
        "Set Environment variable ServerRole to $($env:ServerRole) "
                

    }
    elseif($ENV:DEPLOY_CURRENT_INSTALLATION -eq "DEVSCOTT")
    {
    }
    elseif($ENV:DEPLOY_CURRENT_INSTALLATION -eq "OAT")
    {
    }
    elseif($ENV:DEPLOY_CURRENT_INSTALLATION -eq "DEVVMSET1")
    {
    }
    elseif($ENV:DEPLOY_CURRENT_INSTALLATION -eq "DEVVMSET2")
    {
    }
    elseif($ENV:DEPLOY_CURRENT_INSTALLATION -eq "PROD")
    {
    }
        else
    {
        " You must choose an environment to setup"
    }

        # Replace environment variables within configuration files so they are specific to the current farm

        ReplaceVariablesInFiles
}

main



