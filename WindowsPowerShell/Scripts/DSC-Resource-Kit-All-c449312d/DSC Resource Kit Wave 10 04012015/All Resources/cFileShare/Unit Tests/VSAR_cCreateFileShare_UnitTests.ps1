#Unit tests for VSAR_cCreateFileShare
Import-Module "C:\Program Files\WindowsPowerShell\Modules\cFileShare\DSCResources\VSAR_cCreateFileShare"

#Variable Declarations
$ShareName = "TestShare"
$Path = "C:\Test"

$PassCounter = 0
$FailCounter = 0

##############################
#
# Tests for Get-TargetResource
#
##############################

#####################################################
# Test #1 - If share exists, Ensure returns "Present"
#####################################################

#Setup for Test #1
$SetupResult = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
if (!$SetupResult)
{
    New-SmbShare -Path $Path -Name $ShareName
}

$Result = Get-TargetResource -ShareName $ShareName -Path $Path

if ($Result.Ensure -ne "Present")
{
    $FailCounter += 1
    "Test 1 Failed"
}
else
{
    $PassCounter += 1
    "Test 1 Passed"
}

############################################################
# Test #2 - If share does not exist, Ensure returns "Absent"
############################################################

#Setup for Test #2
$SetupResult = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
if ($SetupResult)
{
    Remove-SmbShare -Name $ShareName -Force
}

$Result = Get-TargetResource -ShareName $ShareName -Path $Path

if ($Result.Ensure -eq "Present")
{    
    $FailCounter += 1
    "Test 2 Failed"
}
else
{
    $PassCounter += 1
    "Test 2 Passed"
}

###############################
#
# Tests for Test-TargetResource
#
###############################

############################################################
# Test #3 - Configuration: Ensure Present
#           Share does exist
#           Returns True
############################################################

#Setup for Test #3
$SetupResult = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
if (!$SetupResult)
{
    $NewResult = New-SmbShare -Path $Path -Name $ShareName
}

$Result = Test-TargetResource -ShareName $ShareName -Path $Path -Ensure Present

if ($Result -eq $true)
{
    $PassCounter += 1
    "Test 3 Passed"
}
else
{
    $FailCounter += 1
    "Test 3 Failed"
}

############################################################
# Test #4 - Configuration: Ensure Present
#           Share does not exist 
#           Returns False
############################################################

#Setup for Test #4
$SetupResult = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
if ($SetupResult)
{
    Remove-SmbShare -Name $ShareName -Force
}

$Result = Test-TargetResource -ShareName $ShareName -Path $Path -Ensure Present

if ($Result -eq $true)
{
    $FailCounter += 1
    "Test 4 Failed"
}
else
{
    $PassCounter += 1
    "Test 4 Passed"
}

############################################################
# Test #5 - Configuration: Ensure Absent
#           Share does not exist 
#           Returns True
############################################################

#Setup for Test #5
$SetupResult = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
if ($SetupResult)
{
    Remove-SmbShare -Name $ShareName -Force
}

$Result = Test-TargetResource -ShareName $ShareName -Path $Path -Ensure Absent

if ($Result -eq $true)
{
    $PassCounter += 1
    "Test 5 Passed"
}
else
{
    $FailCounter += 1
    "Test 5 Failed"
}

############################################################
# Test #6 - Configuration: Ensure Absent
#           Share does exists
#           Returns False
############################################################

#Setup for Test #6
$SetupResult = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
if (!$SetupResult)
{
    $NewResult = New-SmbShare -Path $Path -Name $ShareName
}

$Result = Test-TargetResource -ShareName $ShareName -Path $Path -Ensure Absent

if ($Result -eq $true)
{
    $FailCounter += 1
    "Test 6 Failed"
}
else
{
    $PassCounter += 1
    "Test 6 Passed"
}

##############################
#
# Tests for Set-TargetResource
#
##############################

############################################################
# Test #7 - Configuration: Ensure Absent
#           Share does exists
#           Result: Share no longer exists
############################################################


############################################################
# Test #8 - Configuration: Ensure Absent
#           Share does not exists
#           Result: Share still does not exists
############################################################


############################################################
# Test #9 - Configuration: Ensure Present
#           Share does exists
#           Result: Share still exists
############################################################


############################################################
# Test #10 - Configuration: Ensure Present
#           Path exists but share does not exist
#           Result: Share exists
############################################################


############################################################
# Test #11 - Configuration: Ensure Present
#           Path does not exist and share does not exist
#           Result: Share exists
############################################################

#Add in the unit tests for the set share permissions

""
"Passed: $PassCounter, Failed: $FailCounter"