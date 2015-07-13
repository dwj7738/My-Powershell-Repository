data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
WordPressInstallationSiteNotFound=Not able to connect to wordpress site using {0}.
WordPressInstallationFailed=Request to connect to wordpress site failed. Returned Status Code is {0], Description is {1}.
'@
}

$Debug = $true
Function Trace-Message
{
    param([string] $Message)
    if($Debug)
    {
        Write-Verbose $Message
    }
}

# The Get-TargetResource cmdlet is used to fetch the status of role or Website on the target machine.
# It gives the Website info of the requested role/feature on the target machine.  
function Get-TargetResource 
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
		$Uri,

		[parameter(Mandatory = $true)]
		[System.String]
		$Title,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$AdministratorCredential,

		[parameter(Mandatory = $true)]
		[System.String]
		$AdministratorEmail
	)

        $Ensure = "Absent"
           try 
           {
                $response = Invoke-WebRequest -UseBasicParsing -Uri $Uri 
                if(-not ($response.Content -like "*<title>WordPress &rsaquo; Installation</title>*"))
                {
                    $Ensure = "Present"
                }
            }
            catch
            {
                Write-Verbose ($($LocalizedData.WordPressInstallationSiteNotFound) -f ${Uri})
                return $false
            }
     
        $getTargetResourceResult = @{
                                        Uri = $Uri 
                                        Ensure = $Ensure
                                        Title = $Title
                                        AdministratorEmail = $AdministratorCredential 
                                    }
        
        return $getTargetResourceResult;
}


# The Set-TargetResource cmdlet is used to create, delete or configuure a website on the target machine. 
function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param 
    (       
		[parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
		$Uri,

		[parameter(Mandatory = $true)]
		[System.String]
		$Title,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$AdministratorCredential,

		[parameter(Mandatory = $true)]
		[System.String]
		$AdministratorEmail,

        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present"
    )
 
    if((Test-TargetResource @psboundparameters))
    {
        return
    }

    $status = Get-TargetResource @psboundparameters
    Trace-Message "Get Wordpress site resource completed."
    
    $result = Invoke-WebRequest -UseBasicParsing -Uri "$Uri/wp-admin/install.php?step=2" -Method Post -Body "weblog_title=$Title&user_name=$($AdministratorCredential.UserName)&admin_password=$($AdministratorCredential.GetNetworkCredential().Password)&admin_password2=$($AdministratorCredential.GetNetworkCredential().Password)&admin_email=$AdministratorEmail&Submit=Install+WordPress"

    if ($result.StatusCode -ne 200)
    {
        Write-Verbose ($($LocalizedData.WordPressInstallationFailed) -f $result.StatusCode, $result.StatusDescription)
    }
}


# The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as expected in the instance document.
function Test-TargetResource 
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
		$Uri,

		[parameter(Mandatory = $true)]
		[System.String]
		$Title,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$AdministratorCredential,

		[parameter(Mandatory = $true)]
		[System.String]
		$AdministratorEmail,
        
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present"   )
 
    $handlerState = Get-TargetResource  @psboundparameters

    if($handlerState.Ensure -eq  "Present" )
    {
        return $true 
    }
    else
    {
        return $false 
    }

}

Export-ModuleMember -Function *-TargetResource