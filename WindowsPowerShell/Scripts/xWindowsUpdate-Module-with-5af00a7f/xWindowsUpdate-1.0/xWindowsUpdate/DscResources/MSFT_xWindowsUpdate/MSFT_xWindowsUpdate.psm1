Data LocalizedData
{
    # culture="en-US"e
    ConvertFrom-StringData @'
        GettingHotfixMessage=Getting the hotfix patch with ID {0}.
        ValidatingPathUri=Validating path/URI.
        ErrorPathUriSpecifiedTogether=Hotfix path and Uri parameters cannot be specified together.
        ErrorInvalidFilePathMsu=Filename provided is an invalid file path for hotfix since it does not have the msu suffix to it.
        StartKeyWord=START
        EndKeyWord= END
        FailedKeyword = FAILED
        ActionDownloadFromUri= Download from {0} using BitsTransfer
        ActionInstallUsingwsusa = Install using wsusa.exe
        ActionUninstallUsingwsusa = Uninstall using wsusa.exe
        DownloadingPackageTo = Downloading package to filepath {0}
        FileDoesntExist=The given path {0} does not exist.
        LogNotSpecified=Log name hasn't been specified. Hotfix will use the temporary log {0} 
        ErrorOccuredOnHotfixInstall = \nCould not install the windows update. Details are stored in the log {0} . Error message is \n\n {1}  .\n\nPlease look at Windows Update error codes here for more information - http://technet.microsoft.com/en-us/library/dd939837(WS.10).aspx
        ErrorOccuredOnHotfixUninnstall = \nCould not uninstall the windows update. Details are stored in the log {0} . Error message is \n\n {1}  .\n\nPlease look at Windows Update error codes here for more information - http://technet.microsoft.com/en-us/library/dd939837(WS.10).aspx
        TestingEnsure = Testing whether hotfix is {0}
'@
}


# Get-TargetResource function  
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	Param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Id
	)

    Write-Verbose $($LocalizedData.GettingHotfixMessage -f ${Id})
	
    $PSBoundParameters.Remove("Id")

    $hotfix = Get-HotFix -Id $Id @PSBoundParameters
	
	$returnValue = @{
		Path = ""
		Id = $hotfix.HotFixId
		Log = ""
	}

	$returnValue	

}


# The Set-TargetResource cmdlet
function Set-TargetResource
{
	[CmdletBinding()]
	Param
	(
		[System.String]
		$Path,

		[System.String]
		$Uri,

		[parameter(Mandatory = $true)]
		[System.String]
		$Id,

		[System.String]
		$Log,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure="Present"
	)
    if (!$Log)
    {
        $Log = [IO.Path]::GetTempFileName()
        $Log += ".etl"

        Write-Verbose "$($LocalizedData.LogNotSpecified -f ${Log})"
    }
    if($Ensure -eq "Present")
    {
        $PSBoundParameters.Remove("Ensure") > $null
        $PSBoundParameters.Remove("Log") > $null
        $PSBoundParameters.Remove("Id") > $null
        $filePath = Get-FilePath @PSBoundParameters 
        Write-Verbose "$($LocalizedData.StartKeyWord) $($LocalizedData.ActionInstallUsingwsusa)"
    
        Start-Process -FilePath "wusa.exe" -ArgumentList "`"$filepath`" /quiet /norestart /log:$Log" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        $errorOccured = Get-WinEvent -Path $Log -Oldest | Where-Object {$_.Id -eq 3}                         
        if($errorOccured)
        {
            $errorMessage= $errorOccured.Message
            Throw "$($LocalizedData.ErrorOccuredOnHotfixInstall -f ${Log}, ${errorMessage})"
        }

        Write-Verbose "$($LocalizedData.EndKeyWord) $($LocalizedData.ActionInstallUsingwsusa)"

	    
        
    
    }
    else
    {
        
        Write-Verbose "$($LocalizedData.StartKeyWord) $($LocalizedData.ActionUninstallUsingwsusa)"
    
        Start-Process -FilePath "wusa.exe" -ArgumentList "/uninstall /KB:$Id /quiet /norestart /log:$Log" -Wait -NoNewWindow  -ErrorAction SilentlyContinue
        #Read the log and see if there was an error event
        $errorOccured = Get-WinEvent -Path $Log -Oldest | Where-Object {$_.Id -eq 3}                         
        if($errorOccured)
        {
            $errorMessage= $errorOccured.Message
            Throw "$($LocalizedData.ErrorOccuredOnHotfixUninstall -f ${Log}, ${errorMessage})"
        }

        Write-Verbose "$($LocalizedData.EndKeyWord) $($LocalizedData.ActionUninstallUsingwsusa)"

	    
    }
    
    if ($LASTEXITCODE -eq 3010)
    {
	    $global:DSCMachineStatus = 1        
    }
            
    
}


# Function to test if Hotfix is installed.
function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[System.String]
		$Path,

		[System.String]
		$Uri,

		[parameter(Mandatory = $true)]
		[System.String]
		$Id,

		[System.String]
		$Log,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure="Present"
	)
    Write-Verbose "$($LocalizedData.TestingEnsure -f ${Ensure})"
    ValidatePathAndUriExclusive -Path $Path -Uri $Uri
    
	$result = Get-HotFix -Id $Id -ErrorAction SilentlyContinue
	$returnValue=  [bool]$result
    if($Ensure -eq "Present")
    {

    	Return $returnValue
    }
    else
    {
        Return !$returnValue
    }

}


#Function to look at the path or uri and return the path name of the msu file
Function Get-FilePath
{
    Param([System.String]
		$Path,

		[System.String]
		$Uri)
        
    ValidatePathAndUriExclusive -Path $Path -Uri $Uri

    if ($path -ne $null)
    {
        # check if $path represents a .msu file 
        $filename = Split-Path -Path $Path -Leaf

        if (!($filename.Substring($filename.Length - 3) -ieq "msu"))
        {
            Throw $LocalizedData.ErrorInvalidFilePathMsu
        }
        if(![IO.File]::Exists($Path))
        {
            Throw $LocalizedData.FileDoesntExist -f ${Path}
        }
        $filepath = $Path
    }
    else
    {
         $filepath = [io.path]::GetTempFileName()
         $filepath += ".msu"
         Write-Verbose "$($LocalizedData.StartKeyWord) $($LocalizedData.ActionDownloadFromUri -f ${Uri}) "
         
         $bitsTransferParameters= @{ Source = $Uri;
                                     Destination= $filePath;
                                     Description = "From `'$Uri'` " ;
                                     ErrorVariable = "errorOccured";
                                     DisplayName = $($LocalizedData.DownloadingPackageTo -f ${filePath});
                                     Priority = "ForeGround"}


         Start-BitsTransfer @bitsTransferParameters

         if ($errorOccured)
         {
            Throw  "$($LocalizedData.ActionDownloadFromUri -f ${Uri}) $($LocalizedData.FailedKeyWord)" 
         }
         Write-Verbose "$($LocalizedData.EndKeyWord) $($LocalizedData.ActionDownloadFromUri -f ${Uri})" 
    
    }

    Return $filePath

    
}


#Function to validate that either the path or URI are entered
function ValidatePathAndUriExclusive
{
	param
	(
		[System.String]
		$Path,

		[System.String]
		$Uri
	)
    Write-Verbose $($LocalizedData.ValidatingPathUri)
	
    if ([string]::IsNullOrEmpty($Path) -and ![string]::IsNullOrEmpty($Uri))
    {
	    Return
    }
    if (![string]::IsNullOrEmpty($Path) -and [string]::IsNullOrEmpty($Uri))
    {
	    Return
    }

    $errorMessage= $LocalizedData.ErrorPathUriSpecifiedTogether
    Throw $errorMessage
}



Export-ModuleMember -Function *-TargetResource


