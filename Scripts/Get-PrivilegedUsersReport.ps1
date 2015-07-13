<#
  This script will create a report of users that are members of the following
  privileged groups:
  - Enterprise Admins
  - Schema Admins
  - Domain Admins
  - Cert Publishers
  - Administrators
  - Account Operators
  - Server Operators
  - Backup Operators
  - Print Operators

  A summary report is output to the console, whilst a full report is exported
  to a CSV file.

  The original script was written by Doug Symalla from Microsoft:
  - http://blogs.technet.com/b/askpfeplat/archive/2013/04/08/audit-membership-in-privileged-active-directory-groups-a-second-look.aspx
  - http://gallery.technet.microsoft.com/scriptcenter/List-Membership-In-bff89703

  The script was okay, but needed some updates to be more accurate and
  bug free. As Doug had not updated it since 26th April 2013, I though
  that I would. The changes I made are:

  1. Addressed a bug with the member count in the main section.
     Changed...
       $numberofUnique = $uniqueMembers.count
     To...
       $numberofUnique = ($uniqueMembers | measure-object).count
  2. Addressed a bug with the $colOfMembersExpanded variable in the
     getMemberExpanded function 
     Added...
       $colOfMembersExpanded=@()
  3. Enhanced the main section
  4. Enhanced the getForestPrivGroups function
  5. Enhanced the getUserAccountAttribs function
  6. Added script variables
  7. Added the accountExpires and info attributes
  8. Enhanced description of object members (AKA csv headers) so that
     it's easier to read.

  Script Name: Get-PrivilegedUsersReport.ps1
  Release 1.2
  Modified by Jeremy@jhouseconsulting.com 13/06/2014

#>
#-------------------------------------------------------------
# Set this to maximum number of unique members threshold
$MaxUniqueMembers = 25

# Set this to maximum password age threshold
$MaxPasswordAge = 365

# Set this to true to privide a detailed output to the console
$DetailedConsoleOutput = $False
#-------------------------------------------------------------

##################   Function to Expand Group Membership ################
function getMemberExpanded
{
        param ($dn)

        $colOfMembersExpanded=@()
        $adobject = [adsi]"LDAP://$dn"
        $colMembers = $adobject.properties.item("member")
        Foreach ($objMember in $colMembers)
        {
                $objMembermod = $objMember.replace("/","\/")
                $objAD = [adsi]"LDAP://$objmembermod"
                $attObjClass = $objAD.properties.item("objectClass")
                if ($attObjClass -eq "group")
                {
			  getmemberexpanded $objMember           
                }   
                else
                {
			$colOfMembersExpanded += $objMember
		}
        }    
$colOfMembersExpanded 
}    

########################### Function to Calculate Password Age ##############
Function getUserAccountAttribs
{
                param($objADUser,$parentGroup)
		$objADUser = $objADUser.replace("/","\/")
                $adsientry=new-object directoryservices.directoryentry("LDAP://$objADUser")
                $adsisearcher=new-object directoryservices.directorysearcher($adsientry)
                $adsisearcher.pagesize=1000
                $adsisearcher.searchscope="base"
                $colUsers=$adsisearcher.findall()
                foreach($objuser in $colUsers)
                {
                	$dn = $objuser.properties.item("distinguishedname")
	                $sam = $objuser.properties.item("samaccountname")
        	        $attObjClass = $objuser.properties.item("objectClass")
			If ($attObjClass -eq "user")
			{
				$description = $objuser.properties.item("description")[0]
				$notes = $objuser.properties.item("info")[0]
				$notes = $notes -replace "`r`n", "|"
                		If (($objuser.properties.item("lastlogontimestamp") | Measure-Object).Count -gt 0) {
                		  $lastlogontimestamp = $objuser.properties.item("lastlogontimestamp")[0]
                		  $lastLogon = [System.DateTime]::FromFileTime($lastlogontimestamp)
                		  $lastLogonInDays = ((Get-Date) - $lastLogon).Days
                		  if ($lastLogon -match "1/01/1601") {
                                    $lastLogon = "Never logged on before"
                		    $lastLogonInDays = "N/A"
                                  }
                		} else {
                		  $lastLogon = "Never logged on before"
                		  $lastLogonInDays = "N/A"
                		}
                		$accountexpiration = $objuser.properties.item("accountexpires")[0]
                		If (($accountexpiration -eq 0) -OR ($accountexpiration -gt [DateTime]::MaxValue.Ticks)) {
                		  $accountexpires = "<Never>"
                		} else {
                		  $accountexpires = [datetime]::fromfiletime([int64]::parse($accountexpiration))
                		}

        	        	$pwdLastSet=$objuser.properties.item("pwdLastSet")
                		if ($pwdLastSet -gt 0)
                        	{
                        		$pwdLastSet = [datetime]::fromfiletime([int64]::parse($pwdLastSet))
                                	$PasswordAge = ((get-date) - $pwdLastSet).days
                        	}
                        	Else {$PasswordAge = "<Not Set>"}                                                                        
                		$uac = $objuser.properties.item("useraccountcontrol")
                        	$uac = $uac.item(0)
                		if (($uac -bor 0x0002) -eq $uac) {$disabled="TRUE"}
                        	else {$disabled = "FALSE"}
                        	if (($uac -bor 0x10000) -eq $uac) {$passwordneverexpires="TRUE"}
                        	else {$passwordNeverExpires = "FALSE"}
                        }                                                        
                        $record = "" | select-object SamAccountName,DistinguishedName,MemberOf,PasswordAge,LastLogon,LastLogonInDays,Disabled,PasswordNeverExpires,AccountExpires,Description,Notes
                        $record.SamAccountName = [string]$sam
                        $record.DistinguishedName = [string]$dn
                        $record.MemberOf = [string]$parentGroup
                        $record.PasswordAge = $PasswordAge
                        $record.LastLogon = $lastLogon
                        $record.LastLogonInDays = $lastLogonInDays
                        $record.Disabled = $disabled
                        $record.PasswordNeverExpires = $passwordNeverExpires
                        $record.AccountExpires = $accountexpires
                        $record.Description = $description
                        $record.Notes = $notes

                } 
$record
}
####### Function to find all Privileged Groups in the Forest ##########
Function getForestPrivGroups
{
  # Privileged Group Membership for the following groups:
  # - Enterprise Admins - SID: S-1-5-21root domain-519
  # - Schema Admins - SID: S-1-5-21root domain-518
  # - Domain Admins - SID: S-1-5-21domain-512
  # - Cert Publishers - SID: S-1-5-21domain-517
  # - Administrators - SID: S-1-5-32-544
  # - Account Operators - SID: S-1-5-32-548
  # - Server Operators - SID: S-1-5-32-549
  # - Backup Operators - SID: S-1-5-32-551
  # - Print Operators - SID: S-1-5-32-550
  # Reference: http://support.microsoft.com/kb/243330

                $colOfDNs = @()
                $Forest = [System.DirectoryServices.ActiveDirectory.forest]::getcurrentforest()
		$RootDomain = [string]($forest.rootdomain.name)
		$forestDomains = $forest.domains
		$colDomainNames = @()
		ForEach ($domain in $forestDomains)
		{
			$domainname = [string]($domain.name)
			$colDomainNames += $domainname
		}
		
                $ForestRootDN = FQDN2DN $RootDomain
		$colDomainDNs = @()
		ForEach ($domainname in $colDomainNames)
		{
			$domainDN = FQDN2DN $domainname
			$colDomainDNs += $domainDN	
		}

		$GC = $forest.FindGlobalCatalog()
                $adobject = [adsi]"GC://$ForestRootDN"
        	$RootDomainSid = New-Object System.Security.Principal.SecurityIdentifier($AdObject.objectSid[0], 0)
		$RootDomainSid = $RootDomainSid.toString()
		$colDASids = @()
		ForEach ($domainDN in $colDomainDNs)
		{
			$adobject = [adsi]"GC://$domainDN"
        		$DomainSid = New-Object System.Security.Principal.SecurityIdentifier($AdObject.objectSid[0], 0)
			$DomainSid = $DomainSid.toString()
			$daSid = "$DomainSID-512"
			$colDASids += $daSid
			$cpSid = "$DomainSID-517"
			$colDASids += $cpSid
		}


		$colPrivGroups = @("S-1-5-32-544";"S-1-5-32-548";"S-1-5-32-549";"S-1-5-32-551";"S-1-5-32-550";"$rootDomainSid-519";"$rootDomainSid-518")
		$colPrivGroups += $colDASids
                
		$searcher = $gc.GetDirectorySearcher()
		ForEach($privGroup in $colPrivGroups)
                {
                                $searcher.filter = "(objectSID=$privGroup)"
                                $Results = $Searcher.FindAll()
                                ForEach ($result in $Results)
                                {
                                                $dn = $result.properties.distinguishedname
                                                $colOfDNs += $dn
                                }
                }
$colofDNs
}

########################## Function to Generate Domain DN from FQDN ########
Function FQDN2DN
{
	Param ($domainFQDN)
	$colSplit = $domainFQDN.Split(".")
	$FQDNdepth = $colSplit.length
	$DomainDN = ""
	For ($i=0;$i -lt ($FQDNdepth);$i++)
	{
		If ($i -eq ($FQDNdepth - 1)) {$Separator=""}
		else {$Separator=","}
		[string]$DomainDN += "DC=" + $colSplit[$i] + $Separator
	}
	$DomainDN
}

########################## MAIN ###########################
# Get the script path
$ScriptPath = {Split-Path $MyInvocation.ScriptName}
$ReferenceFile = $(&$ScriptPath) + "\PrivilegedUsers.csv"

$forestPrivGroups = GetForestPrivGroups
$colAllPrivUsers = @()

$rootdse=new-object directoryservices.directoryentry("LDAP://rootdse")

Foreach ($privGroup in $forestPrivGroups)
{
                Write-Host ""
		Write-Host "Enumerating $privGroup.." -foregroundColor yellow
                $uniqueMembers = @()
                $colOfMembersExpanded = @()
		$colofUniqueMembers = @()
                $members = getmemberexpanded $privGroup
                If ($members)
                {
                                $uniqueMembers = $members | sort-object -unique
				$numberofUnique = ($uniqueMembers | measure-object).count
				Foreach ($uniqueMember in $uniqueMembers)
				{
					 $objAttribs = getUserAccountAttribs $uniqueMember $privGroup
                                         $colOfuniqueMembers += $objAttribs      
				}
                                $colAllPrivUsers += $colOfUniqueMembers
                }
                Else {$numberofUnique = 0}
                
                If ($numberofUnique -gt $MaxUniqueMembers)
                {
                                Write-host "...$privGroup has $numberofUnique unique members" -foregroundColor Red
                }
		Else { Write-host "...$privGroup has $numberofUnique unique members" -foregroundColor White }

                $pwdneverExpiresCount = 0
                $pwdAgeCount = 0

                ForEach($user in $colOfuniquemembers)
                {
                                $i = 0
                                $userpwdAge = $user.pwdAge
                                $userpwdneverExpires = $user.pWDneverExpires
                                $userSAM = $user.SAM
                                IF ($userpwdneverExpires -eq $True)
                                {
                                  $pwdneverExpiresCount ++
                                  $i ++
                                  If ($DetailedConsoleOutput) {Write-host "......$userSAM has a password age of $userpwdage and the password is set to never expire" -foregroundColor Green}
                                }
                                If ($userpwdAge -gt $MaxPasswordAge)
                                {
                                  $pwdAgeCount ++
                                  If ($i -gt 0)
                                  {
                                    If ($DetailedConsoleOutput) {Write-host "......$userSAM has a password age of $userpwdage days" -foregroundColor Green}
                                  }
                                }
                }

                If ($numberofUnique -gt 0)
                {
                                Write-host "......There are $pwdneverExpiresCount accounts that have the password is set to never expire." -foregroundColor Green
                                Write-host "......There are $pwdAgeCount accounts that have a password age greater than $MaxPasswordAge days." -foregroundColor Green
                }
}

write-host "`nComments:" -foregroundColor Yellow
write-host " - If a privileged group contains more than $MaxUniqueMembers unique members, it's highlighted in red." -foregroundColor Yellow
If ($DetailedConsoleOutput) {
  write-host " - The privileged user is listed if their password is set to never expire." -foregroundColor Yellow
  write-host " - The privileged user is listed if their password age is greater than $MaxPasswordAge days." -foregroundColor Yellow
  write-host " - Service accounts should not be privileged users in the domain." -foregroundColor Yellow
}

$colAllPrivUsers | Export-CSV -notype -path "$ReferenceFile" -Delimiter ';'

# Remove the quotes
(get-content "$ReferenceFile") |% {$_ -replace '"',""} | out-file "$ReferenceFile" -Fo -En ascii

# SIG # Begin signature block
# MIINGAYJKoZIhvcNAQcCoIINCTCCDQUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYzuflcEnyB7QBH12klOtDYS8
# JGGgggpaMIIFIjCCBAqgAwIBAgIQAupQIxjzGlMFoE+9rHncOTANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE0MDcxNzAwMDAwMFoXDTE1MDcy
# MjEyMDAwMFowaTELMAkGA1UEBhMCQ0ExCzAJBgNVBAgTAk9OMREwDwYDVQQHEwhI
# YW1pbHRvbjEcMBoGA1UEChMTRGF2aWQgV2F5bmUgSm9obnNvbjEcMBoGA1UEAxMT
# RGF2aWQgV2F5bmUgSm9obnNvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAM3+T+61MoGxUHnoK0b2GgO17e0sW8ugwAH966Z1JIzQvXFa707SZvTJgmra
# ZsCn9fU+i9KhC0nUpA4hAv/b1MCeqGq1O0f3ffiwsxhTG3Z4J8mEl5eSdcRgeb+1
# jaKI3oHkbX+zxqOLSaRSQPn3XygMAfrcD/QI4vsx8o2lTUsPJEy2c0z57e1VzWlq
# KHqo18lVxDq/YF+fKCAJL57zjXSBPPmb/sNj8VgoxXS6EUAC5c3tb+CJfNP2U9vV
# oy5YeUP9bNwq2aXkW0+xZIipbJonZwN+bIsbgCC5eb2aqapBgJrgds8cw8WKiZvy
# Zx2qT7hy9HT+LUOI0l0K0w31dF8CAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrE
# uXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTnMIKoGnZIswBx8nuJckJGsFDU
# lDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAw
# bjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYB
# BQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEB
# BHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsG
# AQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEy
# QXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
# 9w0BAQsFAAOCAQEAVlkBmOEKRw2O66aloy9tNoQNIWz3AduGBfnf9gvyRFvSuKm0
# Zq3A6lRej8FPxC5Kbwswxtl2L/pjyrlYzUs+XuYe9Ua9YMIdhbyjUol4Z46jhOrO
# TDl18txaoNpGE9JXo8SLZHibwz97H3+paRm16aygM5R3uQ0xSQ1NFqDJ53YRvOqT
# 60/tF9E8zNx4hOH1lw1CDPu0K3nL2PusLUVzCpwNunQzGoZfVtlnV2x4EgXyZ9G1
# x4odcYZwKpkWPKA4bWAG+Img5+dgGEOqoUHh4jm2IKijm1jz7BRcJUMAwa2Qcbc2
# ttQbSj/7xZXL470VG3WjLWNWkRaRQAkzOajhpTCCBTAwggQYoAMCAQICEAQJGBtf
# 1btmdVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAw
# MFoXDTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGln
# aUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1
# f+Wondsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+ykn
# x9N7I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4c
# SocI3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTm
# K/5sy350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/B
# ougsUfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0w
# ggHJMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAoGCGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNV
# HSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEA
# PuwNWiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH2
# 0ZJ1D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV
# +7qvtVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyP
# u6j4xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD
# 2rOwjNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6S
# kepobEQysmah5xikmmRR7zGCAigwggIkAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# MTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcg
# Q0ECEALqUCMY8xpTBaBPvax53DkwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwx
# CjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFM472VVvZbDVQ1vm
# EWzfYgQn/gngMA0GCSqGSIb3DQEBAQUABIIBAJ0sHAXZ9yR1Ua+t1dg/6cqroruu
# ictu1fw8zoVKvmSk3YSRDAVu/zlZlhqksoxsGL+8zJlKnCWxCD3nPtgnc4rEPRdS
# kY3UnCxbsyIz9mfUBWGCD7J8P6rYgMzp51ZlRU9mAgtDNlgqV7UrEBNTsvRKoHZ7
# /edwUyd7mtGbpUWLA4R5z5etH8iWrkfcYWLEWDvWyOmvKKPz/7DrZTlWZwd6MtfK
# tLE3zfxia0Rl6Z4UtLKi/FpSNTfmaxRulCba/Zp/bIj/j9xX7l5yOsh5AHNuQeB/
# AuWUt3RZG91AvH3O9ELPAgiEtRv7UlthP378iwlCcTuwZhsr7VXQWGn3/eo=
# SIG # End signature block
