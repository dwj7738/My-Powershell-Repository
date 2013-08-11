function Get-FSMORole {
<#
.SYNOPSIS
Retrieves the FSMO role holders from one or more Active Directory domains and forests.
.DESCRIPTION
Get-FSMORole uses the Get-ADDomain and Get-ADForest Active Directory cmdlets to determine
which domain controller currently holds each of the Active Directory FSMO roles.
.PARAMETER DomainName
One or more Active Directory domain names.
.EXAMPLE
Get-Content domainnames.txt | Get-FSMORole
.EXAMPLE
Get-FSMORole -DomainName domain1, domain2
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [string[]]$DomainName = $env:USERDOMAIN
    )
    BEGIN {
        Import-Module ActiveDirectory -Cmdlet Get-ADDomain, Get-ADForest -ErrorAction SilentlyContinue
    }
    PROCESS {
        foreach ($domain in $DomainName) {
            Write-Verbose "Querying $domain"
            Try {
            $problem = $false
            $addomain = Get-ADDomain -Identity $domain -ErrorAction Stop
            } Catch { $problem = $true
            Write-Warning $_.Exception.Message
            }
            if (-not $problem) {
                $adforest = Get-ADForest -Identity (($addomain).forest)

                New-Object PSObject -Property @{
                    InfrastructureMaster = $addomain.InfrastructureMaster
                    PDCEmulator = $addomain.PDCEmulator
                    RIDMaster = $addomain.RIDMaster
                    DomainNamingMaster = $adforest.DomainNamingMaster
                    SchemaMaster = $adforest.SchemaMaster
                }
            }
        }
    }
}
# SIG # Begin signature block
# MIID9QYJKoZIhvcNAQcCoIID5jCCA+ICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKhX5QWbhbM09AJ18zchGdWvA
# FyCgggITMIICDzCCAXygAwIBAgIQ5NAahjNzvZtFSsmQYHmmfDAJBgUrDgMCHQUA
# MBgxFjAUBgNVBAMTDURhdmlkIEpvaG5zb24wHhcNMTMwNDE2MTM1NDUyWhcNMzkx
# MjMxMjM1OTU5WjAYMRYwFAYDVQQDEw1EYXZpZCBKb2huc29uMIGfMA0GCSqGSIb3
# DQEBAQUAA4GNADCBiQKBgQCjEybZVdsJkX5Nmnd3n23lTIgvKKHtfgxsbd6pkGv6
# n+yNM9BMSkCc5hkhmcSXRZ6oRT0sr1J/9arNFztRx/7laGb7MPEgINwkbnY3QQ8p
# XbpSHHYcNJIEave1Xw18pnWsjsszK+wLr2+/DzPX1gTZkpGAynysN41CKrL0UIxU
# lwIDAQABo2IwYDATBgNVHSUEDDAKBggrBgEFBQcDAzBJBgNVHQEEQjBAgBAikkKX
# Gqkfh3UbhrTTeP8KoRowGDEWMBQGA1UEAxMNRGF2aWQgSm9obnNvboIQ5NAahjNz
# vZtFSsmQYHmmfDAJBgUrDgMCHQUAA4GBAAUwc5DOfdZ8R4LFy2MB17k5lOa4vs4e
# jJlW0xy+FFSPBSgcdwFpQEo6FAkSXR/L8WZ3Xc5TgTtkDbk+0x0wSjbB/QV40U9j
# DJOrt+gprcUI0Z0qOUPWaiHmciuCPyZim2FacD8/9YeNJTZmCSjDjyofXvVOVMzm
# eYXBhVVc21w+MYIBTDCCAUgCAQEwLDAYMRYwFAYDVQQDEw1EYXZpZCBKb2huc29u
# AhDk0BqGM3O9m0VKyZBgeaZ8MAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQGpKyKu1Cl9nOzY4II
# bqOCftJp9zANBgkqhkiG9w0BAQEFAASBgJBqn25YKCyfzm+OuOc13h1lONm+SzRi
# QM/gPRe4/baeSXUySzAcJRxV+zAlYYNVDourUyMhiAcycf2CidMYDpvBX/klWWNQ
# Z8mLHXzm9k0Ho6zeWhQ4REIJNvNRP4EVcS/q0wzSkPrPnp8vAWlAz797m8dqqpRX
# AItDrC2aBCRM
# SIG # End signature block
