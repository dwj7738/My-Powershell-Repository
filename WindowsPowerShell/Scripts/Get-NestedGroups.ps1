<#
	.SYNOPSIS
		Enumerate all AD group memberships of an account (including nested membership).
	.DESCRIPTION
		This script will return all the AD groups an account is member of.
	.PARAMETER UserName
		The username whose group memberships to find.
	.EXAMPLE
		.\Get-NestedGroups.ps1 'johndoe'

		Name                                                        DistinguishedName
		----                                                        -----------------
		Domain Users                                                CN=Domain Users,CN=Users,DC=contoso,DC=com
		Finance                                                     CN=Finance,OU=Department,OU=Groups,DC=contos...
		
	.NOTES
		ScriptName : Get-NestedGroups
		Created By : Gilbert van Griensven
		Date Coded : 06/17/2012
		
		The script iterates through all nested groups and skips circular nested groups.
	.LINK
#>
Param
(
	[Parameter(Mandatory=$true)]$UserName
)
Begin
{
	Function LoadADModule {
		If (!(Get-Module ActiveDirectory)) {
			If (Get-Module -ListAvailable | ? {$_.Name -eq "ActiveDirectory"}) {
				Import-Module ActiveDirectory
				Return $True
			} Else {
				Return $False
			}
		} Else {
			Return $True
		}
	}

	Function GetNestedGroups ($strGroupDN) {
		$currentGroupmemberships = (Get-ADGroup $strGroupDN -Properties MemberOf | Select-Object MemberOf).MemberOf
		foreach ($groupDN in $currentGroupmemberships) {
			if (!(($Script:UserGroupMembership | Select-Object -ExpandProperty DistinguishedName) -contains $groupDN)) {
				$arrProps = @{
					Name = (Get-ADGroup $groupDN).Name
					DistinguishedName = $groupDN
				}
				$Script:UserGroupMembership += (New-Object psobject -Property $arrProps)
				GetNestedGroups $groupDN
			}
		}
	}

	Function FindGroupMembership ($strUsername) {
		$Script:UserGroupMembership = @()
		$arrProps = @{
			Name = "Domain Users"
			DistinguishedName = (Get-ADGroup "Domain Users").DistinguishedName
		}
		$Script:UserGroupMembership += (New-Object psobject -Property $arrProps)
		GetNestedGroups (Get-ADGroup "Domain Users").DistinguishedName
		$directMembershipGroups = (Get-ADUser $strUsername -Properties MemberOf | Select-Object MemberOf).MemberOf
		foreach ($groupDN in $directMembershipGroups) {
			$arrProps = @{
				Name = (Get-ADGroup $groupDN).Name
				DistinguishedName = $groupDN
			}
			$Script:UserGroupMembership += (New-Object psobject -Property $arrProps)
			GetNestedGroups $groupDN
		}
	}
}
Process
{
	If (!(LoadADModule)) {
		Write-Host "Could not load module ActiveDirectory!"
		Return
	}
	If ($UserName) {
		FindGroupMembership $UserName
		Return $Script:UserGroupMembership
	}
}
End
{
	Remove-Module ActiveDirectory -ErrorAction SilentlyContinue
}