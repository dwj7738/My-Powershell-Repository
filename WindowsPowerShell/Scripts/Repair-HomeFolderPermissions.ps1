#############################################################################
# Script: Repair-HomeFolderPermissions.ps1
# Author: Chris Brown    http://www.flamingkeys.com
# Date: 20/10/2010
# Keywords:
# Comments:
# Pre-Requisites: Full Control over destination folder.
#
# +------------+-----+---------------------------------------------------------+
# |       Date | Usr | Description                                             |
# +------------+-----+---------------------------------------------------------+
# | 20/10/2010 | CJB | Initial Script                                          |
# | 28/09/2011 | CJB | Fixed flags issue                                       |
# +------------+-----+---------------------------------------------------------+
#
# DISCLAIMER
# ==========
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
# RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#############################################################################
 
# ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠
#            Variables
#
# Where is the root of the home drives?
$homeDrivesDir="\\msfs01\home$"
# Report only? ($false = fix problems)
$reportMode = $false
# Print all valid directories?
$verbose = $false
# What domain are your users in?
$domainName = "corp.msft"
#
# ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠ ♥ ♦ ♣ ♠
 
# Save the current working directory before we change it (purely for convenience)
pushd .
# Change to the location of the home drives
set-location $homeDrivesDir
 
# Warn the user if we will be fixing or just reporting on problems
write-host ""
 
if ($reportMode) {
 Write-Host "Report mode is on. Not fixing problems"
} else {
 Write-Host "Report mode is off. Will fix problems"
}
 
write-host ""
 
# Initialise a few counter variables. Only useful for multiple executions from the same session
$goodPermissions = $unfixablePermissions = $fixedPermissions = $badPermissions = 0
$failedFolders = @()
 
# For every folder in the $homeDrivesDir folder
foreach($homeFolder in (Get-ChildItem $homeDrivesDir | Where {$_.psIsContainer -eq $true})) {
 
 # dump the current ACL in a variable
 $Acl = Get-Acl $homeFolder
 
 # create a permission mask in the form of DOMAIN\Username where Username=foldername
 #    (adjust as necessary if your home folders are not exactly your usernames)
 $compareString = "*" + $domainName + "\" + $homeFolder.Name + " Allow  FullControl*"
 
 # if the permission mask is in the ACL
 if ($Acl.AccessToString -like $compareString) {
 
 # everything's good, increment the counter and move on.
 if ($verbose) {Write-Host "Permissions are valid for" $homeFolder.Name -backgroundcolor green -foregroundcolor white}
 $goodPermissions += 1
 
 } else {
 # Permissions are invalid, either fix or report
 # increment the number of permissions needing repair
 $badPermissions += 1
 # if we're in report mode
 if ($reportMode -eq $true) {
 # reportmode is on, don't do anything
 Write-Host "Permissions not valid for" $homeFolder.Name -backgroundcolor red -foregroundcolor white
 } else {
 # reportmode is off, fix the permissions
 Write-Host "Setting permissions for" $homeFolder.Name -foregroundcolor white -backgroundcolor red
 # Add the user in format DOMAIN\Username
 $username = $domainName + "\" + $homeFolder.Name
 # Grant the user full control
 $accessLevel = "FullControl"
 # Should permissions be inherited from above?
 $inheritanceFlags = "ContainerInherit, ObjectInherit"
 # Should permissions propagate to below?
 $propagationFlags = "None"
 # Is this an Allow/Deny entry?
 $accessControlType = "Allow"
 try {
 # Create the Access Rule
 $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($username,$accessLevel,$inheritanceFlags,$propagationFlags,$accessControlType)
 
 # Attempt to apply the access rule to the ACL
 $Acl.SetAccessRule($accessRule)
 Set-Acl $homeFolder $Acl
 # if it hasn't errored out by now, increment the counter
 $fixedPermissions += 1
 } catch {
 # It failed!
 # Increment the fail count
 $unfixablePermissions += 1
 # and add the folder to the list of failed folders
 $failedFolders += $homeFolder
 }
 } #/if
 } #/if
} #/foreach
 
# Print out a summary
 
Write-Host ""
Write-Host $goodPermissions "valid permissions"
Write-Host $badPermissions "permissions needing repair"
if ($reportMode -eq $false) {Write-Host $fixedPermissions "permissions fixed"}
if ($unfixablePermissions -gt 0) {
 Write-Host $unfixablePermissions "ACLs could not be repaired."
 foreach ($folder in $failedFolders) {Write-Host " -" $folder}
}
 
# Cleanup
popd