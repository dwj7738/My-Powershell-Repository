#Unit tests for VSAR_cSetSharePermissions
Import-Module "C:\Program Files\WindowsPowerShell\Modules\cFileShare\DSCResources\VSAR_cSetSharePermissions"

#Variable Declarations
$ShareName = "TestShare"
$Users = @("[domain]\[user1]", "[domain]\[user2]")
$Path = "C:\Test"
$User1 = "[domain]\[user1]"
$User2 = "[domain]\[user2]"

$PassCounter = 0
$FailCounter = 0



##############################
#
# Tests for Get-TargetResource
#
##############################

################################
# Test #1: Share does not exist
#          Ensure is Absent
################################

#Setup for Test #1
$SetupResult = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
if ($SetupResult)
{
    $SetupResult = Remove-SmbShare -Name $ShareName -Force
}

$result = Get-TargetResource -ShareName "TestShare"

if ($result.Ensure -eq "Present")
{
    $FailCounter += 1
    "Test 1 Failed"
}
else
{
    $PassCounter += 1
    "Test 1 Passed"
}

#####################################################################################################
#
#This setup is valid for the rest of the tests. Ensures the share exists before beginning these tests
#
#####################################################################################################

$SetupResult = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
if (!$SetupResult)
{
    $SetupResult = New-SmbShare -Path $Path -Name $ShareName
}

###############################
#
# Tests for Test-TargetResource
#
###############################

############################################
# Test #2: Ensure is Present
#          AccessLevel is Read
#          One user is not in the Read group
#          Result False
############################################

#setup - add a single user to the Read group
RemoveUsers($ShareName, $User1, $User2);
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Read -AccountName $User1 -Force

#test
$TestResult = Test-TargetResource -ShareName $ShareName -ReadAccessUsers $Users -Ensure Present
if ($TestResult)
{
    $FailCounter += 1
    "Test 2 Failed"
}
else
{
    $PassCounter += 1
    "Test 2 Passed"
}

############################################
# Test #3: Ensure is Present
#          AccessLevel is Read
#          One user is in the Full group
#          One user is in the Change group
#          Result True
############################################

#setup
RemoveUsers($ShareName, $User1, $User2);
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Change -AccountName $User1 -Force
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Full -AccountName $User2 -Force

#test
$TestResult = Test-TargetResource -ShareName $ShareName -ReadAccessUsers $Users -Ensure Present
if (!$TestResult)
{
    $FailCounter += 1
    "Test 3 Failed"
}
else
{
    $PassCounter += 1
    "Test 3 Passed"
}

############################################
# Test #4: Ensure is Present
#          AccessLevel is Change
#          One user is in the Full group
#          One user is in the Change group
#          Result True
############################################

#setup
RemoveUsers($ShareName, $User1, $User2);
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Change -AccountName $User1 -Force
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Full -AccountName $User2 -Force

#test
$TestResult = Test-TargetResource -ShareName $ShareName -ChangeAccessUsers $Users -Ensure Present
if (!$TestResult)
{
    $FailCounter += 1
    "Test 4 Failed"
}
else
{
    $PassCounter += 1
    "Test 4 Passed"
}

############################################
# Test #5: Ensure is Present
#          AccessLevel is Change
#          One user is in the Full group
#          One user is in the Read group
#          Result False
############################################

#setup
RemoveUsers($ShareName, $User1, $User2);
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Read -AccountName $User1 -Force
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Full -AccountName $User2 -Force

#test
$TestResult = Test-TargetResource -ShareName $ShareName -ChangeAccessUsers $Users -Ensure Present
if ($TestResult)
{
    $FailCounter += 1
    "Test 5 Failed"
}
else
{
    $PassCounter += 1
    "Test 5 Passed"
}

############################################
# Test #6: Ensure is Present
#          AccessLevel is Full
#          One user is in the Full group
#          One user is in the Change group
#          Result False
############################################

#setup
RemoveUsers($ShareName, $User1, $User2);
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Change -AccountName $User1 -Force
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Full -AccountName $User2 -Force

#test
$TestResult = Test-TargetResource -ShareName $ShareName -FullAccessUsers $Users -Ensure Present
if ($TestResult)
{
    $FailCounter += 1
    "Test 6 Failed"
}
else
{
    $PassCounter += 1
    "Test 6 Passed"
}

############################################
# Test #7: Ensure is Absent
#          AccessLevel is Read
#          One user is in the Full group
#          One user is in the Change group
#          Result True
############################################

#setup
RemoveUsers($ShareName, $User1, $User2);
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Change -AccountName $User1 -Force
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Full -AccountName $User2 -Force

#test
$TestResult = Test-TargetResource -ShareName $ShareName -ReadAccessUsers $Users -Ensure Absent
if (!$TestResult)
{
    $FailCounter += 1
    "Test 8 Failed"
}
else
{
    $PassCounter += 1
    "Test 8 Passed"
}

############################################
# Test #8: Ensure is Absent
#          AccessLevel is Change
#          One user is in the Full group
#          One user is in the Change group
#          Result False
############################################

#setup
RemoveUsers($ShareName, $User1, $User2);
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Change -AccountName $User1 -Force
$SetupResult = Grant-SmbShareAccess -Name $ShareName -AccessRight Full -AccountName $User2 -Force

#test
$TestResult = Test-TargetResource -ShareName $ShareName -ChangeAccessUsers $Users -Ensure Absent
if ($TestResult)
{
    $FailCounter += 1
    "Test 9 Failed"
}
else
{
    $PassCounter += 1
    "Test 9 Passed"
}

""
"Passed: $PassCounter, Failed: $FailCounter"

function RemoveUsers($a)
{
    $revokeResult = Revoke-SmbShareAccess -Name $a[0] -AccountName $a[1] -force
    $revokeResult = Revoke-SmbShareAccess -Name $a[0] -AccountName $a[2] -force
}