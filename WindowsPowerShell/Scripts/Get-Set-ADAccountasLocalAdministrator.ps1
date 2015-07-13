<#
.SYNOPSIS   
Script to add an AD User or group to the Local Administrator group
    
.DESCRIPTION 
The script can use either a plaintext file or a computer name as input and will add the trustee (user or group) as an administrator to the computer
	
.PARAMETER InputFile
A path that contains a plaintext file with computer names

.PARAMETER Computer
This parameter can be used instead of the InputFile parameter to specify a single computer or a series of
computers using a comma-separated format
	
.PARAMETER Trustee
The SamAccount name of an AD User or AD Group that is to be added to the Local Administrators group

.NOTES   
Name: Set-ADAccountasLocalAdministrator.ps1
Author: Jaap Brasser
Version: 1.1
DateCreated: 2012-09-06
DateUpdated: 2013-07-23

.LINK
http://www.jaapbrasser.com

.EXAMPLE   
.\Get-Set-ADAccountasLocalAdministrator.ps1 -Computer Server01 -Trustee JaapBrasser

Description:
Will set the the JaapBrasser account as a Local Administrator on Server01

.EXAMPLE   
.\Get-Set-ADAccountasLocalAdministrator.ps1 -Computer 'Server01,Server02' -Trustee Contoso\HRManagers

Description:
Will set the HRManagers group in the contoso domain as Local Administrators on Server01 and Server02

.EXAMPLE   
.\Set-ADAccountasLocalAdministrator.ps1 -InputFile C:\ListofComputers.txt -Trustee User01

Description:
Will set the User01 account as a Local Administrator on all servers and computernames listed in the ListofComputers file
#>
[cmdletbinding()]
param(
    [Parameter(ParameterSetName='InputFile')]
    [string]
        $InputFile,
    [Parameter(ParameterSetName='Computer')]
    [string]
        $Computer,
    [string]
        $Trustee
)
<#
.SYNOPSIS
    Function that resolves SAMAccount and can exit script if resolution fails
#>

function Resolve-SamAccount {
param(
    [string]
        $SamAccount,
    [boolean]
        $Exit
)
    process {
        try
        {
            $ADResolve = ([adsisearcher]"(samaccountname=$Trustee)").findone().properties['samaccountname']
        }
        catch
        {
            $ADResolve = $null
        }

        if (!$ADResolve) {
            Write-Warning "User `'$SamAccount`' not found in AD, please input correct SAM Account"
            if ($Exit) {
                exit
            }
        }
        $ADResolve
    }
}
function Set-ADAccountasLocalAdministrator {

    if (!$Trustee) {
        $Trustee = Read-Host "Please input trustee"
    }

            if ($Trustee -notmatch '\\') {
    $ADResolved = (Resolve-SamAccount -SamAccount $Trustee -Exit:$true)
    $Trustee = 'WinNT://',"$env:userdomain",'/',$ADResolved -join ''
    } else {
        $ADResolved = ($Trustee -split '\\')[1]
        $DomainResolved = ($Trustee -split '\\')[0]
        $Trustee = 'WinNT://',$DomainResolved,'/',$ADResolved -join ''
    }
   
    if (!$InputFile) {
	    if (!$Computer) {
		    $Computer = Read-Host "Please input computer name"
	    }
	    [string[]]$Computer = $Computer.Split(',')
	    $Computer | ForEach-Object {
		    $_
		    Write-Host "Adding `'$ADResolved`' to Administrators group on `'$_`'"
		    try {
			    ([ADSI]"WinNT://$_/Administrators,group").add($Trustee)
			    Write-Host -ForegroundColor Green "Successfully completed command for `'$ADResolved`' on `'$_`'"
		    } catch {
			    Write-Warning "$_"
		    }	
	    }
    }
    else {
	    if (!(Test-Path -Path $InputFile)) {
		    Write-Warning "Input file not found, please enter correct path"
		    exit
	    }
	    Get-Content -Path $InputFile | ForEach-Object {
		    Write-Host "Adding `'$ADResolved`' to Administrators group on `'$_`'"
		    try {
			    ([ADSI]"WinNT://$_/Administrators,group").add($Trustee)
			    Write-Host -ForegroundColor Green "Successfully completed command"
		    } catch {
			    Write-Warning "$_"
		    }        
	    }
    }
}