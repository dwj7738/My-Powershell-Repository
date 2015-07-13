###########################################################
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl 
# DATE    : 26-04-2012 
# EDIT    : 07-08-2014
# COMMENT : This script creates new Active Directory users,
#           including different kind of properties, based
#           on an input_create_ad_users.csv.
# VERSION : 1.3
###########################################################

# CHANGELOG
# Version 1.2: 15-04-2014 - Changed the code for better
# - Added better Error Handling and Reporting.
# - Changed input file with more logical headers.
# - Added functionality for account Enabled,
#   PasswordNeverExpires, ProfilePath, ScriptPath,
#   HomeDirectory and HomeDrive
# - Added the option to move every user to a different OU.
# Version 1.3: 08-07-2014
# - Added functionality for ProxyAddresses

# ERROR REPORTING ALL
Set-StrictMode -Version latest

#----------------------------------------------------------
# LOAD ASSEMBLIES AND MODULES
#----------------------------------------------------------
Try
{
  Import-Module ActiveDirectory -ErrorAction Stop
}
Catch
{
  Write-Host "[ERROR]`t ActiveDirectory Module couldn't be loaded. Script will stop!"
  Exit 1
}

#----------------------------------------------------------
#STATIC VARIABLES
#----------------------------------------------------------
$path     = Split-Path -parent $MyInvocation.MyCommand.Definition
$newpath  = $path + "\import_create_ad_users.csv"
$log      = $path + "\create_ad_users.log"
$date     = Get-Date
$addn     = (Get-ADDomain).DistinguishedName
$dnsroot  = (Get-ADDomain).DNSRoot
$i        = 1

#----------------------------------------------------------
#START FUNCTIONS
#----------------------------------------------------------
Function Start-Commands
{
  Create-Users
}

Function Create-Users
{
  "Processing started (on " + $date + "): " | Out-File $log -append
  "--------------------------------------------" | Out-File $log -append
  Import-CSV $newpath | ForEach-Object {
    If (($_.Implement.ToLower()) -eq "yes")
    {
      If (($_.GivenName -eq "") -Or ($_.LastName -eq "") -Or ($_.Initials -eq ""))
      {
        Write-Host "[ERROR]`t Please provide valid GivenName, LastName and Initials. Processing skipped for line $($i)`r`n"
        "[ERROR]`t Please provide valid GivenName, LastName and Initials. Processing skipped for line $($i)`r`n" | Out-File $log -append
      }
      Else
      {
        # Set the target OU
        $location = $_.TargetOU + ",$($addn)"

        # Set the Enabled and PasswordNeverExpires properties
        If (($_.Enabled.ToLower()) -eq "true") { $enabled = $True } Else { $enabled = $False }
        If (($_.PasswordNeverExpires.ToLower()) -eq "true") { $expires = $True } Else { $expires = $False }

        # A check for the country, because those were full names and need 
        # to be land codes in order for AD to accept them. I used Netherlands 
        # as example
        If($_.Country -eq "Netherlands")
        {
          $_.Country = "NL"
        }
        Else
        {
          $_.Country = "EN"
        }
        # Replace dots / points (.) in names, because AD will error when a 
        # name ends with a dot (and it looks cleaner as well)
        $replace = $_.Lastname.Replace(".","")
        If($replace.length -lt 4)
        {
          $lastname = $replace
        }
        Else
        {
          $lastname = $replace.substring(0,4)
        }
        # Create sAMAccountName according to this 'naming convention':
        # <FirstLetterInitials><FirstFourLettersLastName> for example
        # htehp
        $sam = $_.Initials.substring(0,1).ToLower() + $lastname.ToLower()
        Try   { $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$sam)" }
        Catch { }
        If(!$exists)
        {
          # Set all variables according to the table names in the Excel 
          # sheet / import CSV. The names can differ in every project, but 
          # if the names change, make sure to change it below as well.
          $setpass = ConvertTo-SecureString -AsPlainText $_.Password -force

          Try
          {
            Write-Host "[INFO]`t Creating user : $($sam)"
            "[INFO]`t Creating user : $($sam)" | Out-File $log -append
            New-ADUser $sam -GivenName $_.GivenName -Initials $_.Initials `
            -Surname $_.LastName -DisplayName ($_.LastName + "," + $_.Initials + " " + $_.GivenName) `
            -Office $_.OfficeName -Description $_.Description -EmailAddress $_.Mail `
            -StreetAddress $_.StreetAddress -City $_.City -State $_.State `
            -PostalCode $_.PostalCode -Country $_.Country -UserPrincipalName ($sam + "@" + $dnsroot) `
            -Company $_.Company -Department $_.Department -EmployeeID $_.EmployeeID `
            -Title $_.Title -OfficePhone $_.Phone -AccountPassword $setpass -Manager $_.Manager `
            -profilePath $_.ProfilePath -scriptPath $_.ScriptPath -homeDirectory $_.HomeDirectory `
            -homeDrive $_.homeDrive -Enabled $enabled -PasswordNeverExpires $expires
            Write-Host "[INFO]`t Created new user : $($sam)"
            "[INFO]`t Created new user : $($sam)" | Out-File $log -append
     
            $dn = (Get-ADUser $sam).DistinguishedName
            # Set an ExtensionAttribute
            If ($_.ExtensionAttribute1 -ne "" -And $_.ExtensionAttribute1 -ne $Null)
            {
              $ext = [ADSI]"LDAP://$dn"
              $ext.Put("extensionAttribute1", $_.ExtensionAttribute1)
              Try   { $ext.SetInfo() }
              Catch { Write-Host "[ERROR]`t Couldn't set the Extension Attribute : $($_.Exception.Message)" }
            }

            # Set ProxyAdresses
            Try { $dn | Set-ADUser -Add @{proxyAddresses = ($_.ProxyAddresses -split ";")} -ErrorAction Stop }
            Catch { Write-Host "[ERROR]`t Couldn't set the ProxyAddresses Attributes : $($_.Exception.Message)" }
       
            # Move the user to the OU ($location) you set above. If you don't
            # want to move the user(s) and just create them in the global Users
            # OU, comment the string below
            If ([adsi]::Exists("LDAP://$($location)"))
            {
              Move-ADObject -Identity $dn -TargetPath $location
              Write-Host "[INFO]`t User $sam moved to target OU : $($location)"
              "[INFO]`t User $sam moved to target OU : $($location)" | Out-File $log -append
            }
            Else
            {
              Write-Host "[ERROR]`t Targeted OU couldn't be found. Newly created user wasn't moved!"
              "[ERROR]`t Targeted OU couldn't be found. Newly created user wasn't moved!" | Out-File $log -append
            }
       
            # Rename the object to a good looking name (otherwise you see
            # the 'ugly' shortened sAMAccountNames as a name in AD. This
            # can't be set right away (as sAMAccountName) due to the 20
            # character restriction
            $newdn = (Get-ADUser $sam).DistinguishedName
            Rename-ADObject -Identity $newdn -NewName ($_.GivenName + " " + $_.LastName)
            Write-Host "[INFO]`t Renamed $($sam) to $($_.GivenName) $($_.LastName)`r`n"
            "[INFO]`t Renamed $($sam) to $($_.GivenName) $($_.LastName)`r`n" | Out-File $log -append
          }
          Catch
          {
            Write-Host "[ERROR]`t Oops, something went wrong: $($_.Exception.Message)`r`n"
          }
        }
        Else
        {
          Write-Host "[SKIP]`t User $($sam) ($($_.GivenName) $($_.LastName)) already exists or returned an error!`r`n"
          "[SKIP]`t User $($sam) ($($_.GivenName) $($_.LastName)) already exists or returned an error!" | Out-File $log -append
        }
      }
    }
    Else
    {
      Write-Host "[SKIP]`t User ($($_.GivenName) $($_.LastName)) will be skipped for processing!`r`n"
      "[SKIP]`t User ($($_.GivenName) $($_.LastName)) will be skipped for processing!" | Out-File $log -append
    }
    $i++
  }
  "--------------------------------------------" + "`r`n" | Out-File $log -append
}

Write-Host "STARTED SCRIPT`r`n"
Start-Commands
Write-Host "STOPPED SCRIPT"