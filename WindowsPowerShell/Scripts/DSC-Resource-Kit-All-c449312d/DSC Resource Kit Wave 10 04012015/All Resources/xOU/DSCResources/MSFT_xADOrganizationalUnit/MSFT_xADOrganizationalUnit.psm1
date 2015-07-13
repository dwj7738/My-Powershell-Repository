#
# cADOrganizationalUnit: DSC resource to manage Organizational Units in Active Directory.
#

#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (	
        [parameter(Mandatory)] 
        [string] $Name,

        [parameter(Mandatory)] 
        [string] $Path
    )

    $ou = Get-ADOrganizationalUnit -Filter { Name -eq $Name } -SearchBase $Path -SearchScope OneLevel -Properties ProtectedFromAccidentalDeletion, Description
    if ($ou -eq $null)
    {
	    $returnValue = @{
		    Name = $Name
    		Path = $Path
	    	Ensure = "Absent"
		    ProtectedFromAccidentalDeletion = $null
		    Description = $null
	    }
    }
    else
    {
	    $returnValue = @{
		    Name = $Name
    		Path = $Path
	    	Ensure = "Present"
		    ProtectedFromAccidentalDeletion = if ($ou.ProtectedFromAccidentalDeletion) { "Yes" } else { "No" }
		    Description = $ou.Description
	    }
    }

    return $returnValue
}


#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)] 
        [string] $Name,

        [parameter(Mandatory)] 
        [string] $Path,
        
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [ValidateNotNull()]
		[PSCredential] $Credential,

        [ValidateNotNull()]
		[ValidateSet("No", "Yes")]
        [System.String] $ProtectedFromAccidentalDeletion = "Yes",

        [ValidateNotNull()]
        [System.String]
        $Description = ""
    )

    $info = Get-TargetResource -Name $Name -Path $Path
    
    if ($info.Ensure -eq "Present")
    {
        $ou = Get-ADOrganizationalUnit -Filter { Name -eq $Name } -SearchBase $Path -SearchScope OneLevel
        if ($Ensure -eq "Present")
        {
            Write-Verbose "The OU `"$($info.Name)`" is being updated"
            Set-ADOrganizationalUnit -Identity $ou -Credential $Credential -Description $Description -ProtectedFromAccidentalDeletion ($ProtectedFromAccidentalDeletion -eq "Yes")
        }
        else
        {
            Write-Verbose "The OU `"$($info.Name)`" is being deleted"
            if ($info.ProtectedFromAccidentalDeletion -eq "Yes")
            {
                Set-ADOrganizationalUnit -Identity $ou -Credential $Credential -ProtectedFromAccidentalDeletion $false
            }

            Remove-ADOrganizationalUnit -Identity $ou -Credential $Credential 
        }
    }
    else
    {
        Write-Verbose "The OU `"$($info.Name)`" is being created"
        New-ADOrganizationalUnit -Credential $Credential -Name $Name -Path $Path -Description $Description -ProtectedFromAccidentalDeletion ($ProtectedFromAccidentalDeletion -eq "Yes")
    }
}

#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
    [OutputType([Boolean])]
    param
    (	
        [parameter(Mandatory)] 
        [string] $Name,

        [parameter(Mandatory)] 
        [string] $Path,
        
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [ValidateNotNull()]
		[PSCredential] $Credential,

        [ValidateNotNull()]
		[ValidateSet("No", "Yes")]
        [System.String] $ProtectedFromAccidentalDeletion = "Yes",

        [ValidateNotNull()]
        [System.String]
        $Description = ""
    )

    $info = Get-TargetResource -Name $Name -Path $Path
    
    if ($info.Ensure -eq "Present")
    {
        if ($Ensure -eq "Present")
        {
            $ok = ($info.Name -eq $Name -and $info.Path -eq $Path -and $info.ProtectedFromAccidentalDeletion -eq $ProtectedFromAccidentalDeletion -and $info.Description -eq $Description)
            if ($ok)
            {
                Write-Verbose "The OU `"$($info.Name)`" exists and is in the desired state"
            }
            else
            {
                Write-Verbose "The OU `"$($info.Name)`" exists but is not in the desired state"
            }
        }
        else
        {
            $ok = $false
            Write-Verbose "The OU `"$($info.Name)`" exists when it should not exist"
        }
    }
    else
    {
        if ($Ensure -eq "Present")
        {
            $ok = $false
            Write-Verbose "The OU `"$($info.Name)`" does not exist when it should exist"
        }
        else
        {
            $ok = $true
            Write-Verbose "The OU `"$($info.Name)`" does not exist and that is the desired state"
        }
    }

    return $ok
}

Export-ModuleMember -Function *-TargetResource
