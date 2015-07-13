$script:domainDn = (Get-ADDomain).DistinguishedName
$script:testOuName = "testou"
$script:testOuDescription = "description"
$script:testOuSecondDescription = "second description"
$script:credential = New-Object System.Management.Automation.PSCredential("$domainName\Administrator", (ConvertTo-SecureString "Passw0rd1" -AsPlainText -Force))

function Get-TestOu()
{
    $ouName = $script:testOuName
    $domainDn = $script:domainDn
    $ou = Get-ADOrganizationalUnit -Filter { Name -eq $ouName } -SearchBase $domainDn -SearchScope OneLevel -Properties ProtectedFromAccidentalDeletion, Description
    return $ou
}

function Remove-TestOu()
{
    $ou = Get-TestOu
    if ($ou -ne $null)
    {
        if ($ou.ProtectedFromAccidentalDeletion)
        {
            Set-ADOrganizationalUnit -Identity $ou -ProtectedFromAccidentalDeletion $false
        }

        Remove-ADOrganizationalUnit -Identity $ou -Confirm:$false
    }
}

function Create-TestOuNotProtected()
{
    Remove-TestOu
    New-ADOrganizationalUnit -Name $script:testOuName -Path $script:domainDn -Description $script:testOuDescription -ProtectedFromAccidentalDeletion $false
}

function Create-TestOuProtected()
{
    Remove-TestOu
    New-ADOrganizationalUnit -Name $script:testOuName -Path $script:domainDn -Description $script:testOuDescription -ProtectedFromAccidentalDeletion $true
}

function Write-TestSucceeded($number)
{
    Write-Host "Test $number [OK]"  -ForegroundColor Green
}

function Write-TestFailed($number, $reason)
{
    Write-Host "Test $number [FAIL]: $reason"  -ForegroundColor Red
}

function Run-Test1()
{
    Remove-TestOu

    $result = Get-TargetResource -Name $script:testOuName -Path $script:domainDn -ErrorAction SilentlyContinue

    if ($result.Ensure -eq "Absent")
    {
        Write-TestSucceeded 1
    }
    else
    {
        Write-TestFailed 1 "OU should not have been found"
    }
}

function Run-Test2()
{
    Create-TestOuNotProtected

    $result = Get-TargetResource -Name $script:testOuName -Path $script:domainDn -ErrorAction SilentlyContinue

    if ($result.Ensure -ne "Present")
    {
        Write-TestFailed 2 "OU should have been found"
    }
    elseif ($result.Description -ne $script:testOuDescription)
    {
        Write-TestFailed 2 "OU description does not match"
    }
    elseif ($result.ProtectedFromAccidentalDeletion -ne "No")
    {
        Write-TestFailed 2 "OU protection does not match"
    }
    else
    {
        Write-TestSucceeded 2
    }
}

function Run-Test3()
{
    Create-TestOuProtected

    $result = Get-TargetResource -Name $script:testOuName -Path $script:domainDn -ErrorAction SilentlyContinue

    if ($result.Ensure -ne "Present")
    {
        Write-TestFailed 3 "OU should have been found"
    }
    elseif ($result.Description -ne $script:testOuDescription)
    {
        Write-TestFailed 3 "OU description does not match"
    }
    elseif ($result.ProtectedFromAccidentalDeletion -ne "Yes")
    {
        Write-TestFailed 3 "OU protection does not match"
    }
    else
    {
        Write-TestSucceeded 3
    }
}


function Run-Test4()
{
    Remove-TestOu

    $result = Test-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Absent" -ErrorAction SilentlyContinue

    if ($result)
    {
        Write-TestSucceeded 4
    }
    else
    {
        Write-TestFailed 4 "OU should not have been found"
    }
}

function Run-Test5()
{
    Create-TestOuNotProtected

    $result = Test-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuDescription -ProtectedFromAccidentalDeletion "No" -ErrorAction SilentlyContinue

    if ($result)
    {
        Write-TestSucceeded 5
    }
    else
    {
        Write-TestFailed 5 "OU should have been found"
    }
}

function Run-Test6()
{
    Create-TestOuNotProtected

    $result = Test-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuSecondDescription -ProtectedFromAccidentalDeletion "No" -ErrorAction SilentlyContinue

    if ($result)
    {
        Write-TestFailed 6 "OU test should have failed because of description"
    }
    else
    {
        Write-TestSucceeded 6
    }
}

function Run-Test7()
{
    Create-TestOuNotProtected

    $result = Test-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuDescription -ProtectedFromAccidentalDeletion "Yes" -ErrorAction SilentlyContinue

    if ($result)
    {
        Write-TestFailed 7 "OU test should have failed because of protection"
    }
    else
    {
        Write-TestSucceeded 7
    }
}


function Run-Test8()
{
    Remove-TestOu

    Set-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuDescription -ProtectedFromAccidentalDeletion "Yes" -Credential $script:credential -ErrorAction SilentlyContinue
    $result = Test-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuDescription -ProtectedFromAccidentalDeletion "Yes" -ErrorAction SilentlyContinue

    if ($result)
    {
        Write-TestSucceeded 8
    }
    else
    {
        Write-TestFailed 8 "OU not created correctly"
    }
}

function Run-Test9()
{
    Remove-TestOu

    Set-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuDescription -ProtectedFromAccidentalDeletion "Yes" -Credential $script:credential -ErrorAction SilentlyContinue
    Set-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuSecondDescription -ProtectedFromAccidentalDeletion "Yes" -Credential $script:credential -ErrorAction SilentlyContinue
    $result = Test-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuSecondDescription -ProtectedFromAccidentalDeletion "Yes" -ErrorAction SilentlyContinue

    if ($result)
    {
        Write-TestSucceeded 9
    }
    else
    {
        Write-TestFailed 9 "OU drift of description not corrected"
    }
}

function Run-Test10()
{
    Remove-TestOu

    Set-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuDescription -ProtectedFromAccidentalDeletion "Yes" -Credential $script:credential -ErrorAction SilentlyContinue
    Set-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuDescription -ProtectedFromAccidentalDeletion "No" -Credential $script:credential -ErrorAction SilentlyContinue
    $result = Test-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Present" -Description $script:testOuDescription -ProtectedFromAccidentalDeletion "No" -ErrorAction SilentlyContinue

    if ($result)
    {
        Write-TestSucceeded 10
    }
    else
    {
        Write-TestFailed 10 "OU drift of protection not corrected"
    }
}

function Run-Test11()
{
    Create-TestOuNotProtected

    Set-TargetResource -Name $script:testOuName -Path $script:domainDn -Credential $script:credential -Ensure "Absent" -ErrorAction SilentlyContinue
    $result = Get-TargetResource -Name $script:testOuName -Path $script:domainDn -ErrorAction SilentlyContinue

    if ($result.Ensure -eq "Absent")
    {
        Write-TestSucceeded 11
    }
    else
    {
        Write-TestFailed 11 "Unprotected OU not deleted"
    }
}

function Run-Test12()
{
    Create-TestOuProtected

    Set-TargetResource -Name $script:testOuName -Path $script:domainDn -Ensure "Absent" -Credential $script:credential -ErrorAction SilentlyContinue
    $result = Get-TargetResource -Name $script:testOuName -Path $script:domainDn -ErrorAction SilentlyContinue

    if ($result.Ensure -eq "Absent")
    {
        Write-TestSucceeded 12
    }
    else
    {
        Write-TestFailed 12 "Protected OU not deleted"
    }
}

Import-Module "c:\Program Files\WindowsPowerShell\Modules\xOU\DSCResources\MSFT_xADOrganizationalUnit"

$ConfirmPreference = "None"
Run-Test1
Run-Test2
Run-Test3
Run-Test4
Run-Test5
Run-Test6
Run-Test7
Run-Test8
Run-Test9
Run-Test10
Run-Test11
Run-Test12