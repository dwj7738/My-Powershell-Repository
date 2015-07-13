<#
.Synopsis
   Gives a user full permission on another users calendar
.Description
    This script will give a user full permission on another users exchange calendar
.EXAMPLE
Give-CalendarPermision -CalendarOwner abc@domain.com -user def@domain.com
.Link
http://www.experts-exchange.com/questions/28694426/what-is-the-power-shell-to-give-someone-owner-rights-to-calendar-and-tasks.html
https://technet.microsoft.com/en-us/library/ee617241.aspx
https://technet.microsoft.com/en-us/library/aa998225%28v=exchg.150%29.aspx

.Notes

Adds functionality to original script designed by Will Szymkowski
#>
function Give-CalendarPermision
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # The Calendar Owners username
        [Parameter(ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $CalendarOwner,
        # The User to give permissions to.
        $User
    )

#check for paremeters existing and get values if not there

   if ($CalendarOwner -eq $null){
    $CalendarOwner = Read-host "Calendar to Share user@domain.com"
    }
    if ($user -eq $null){
    $user2 = Read-Host "User to Give Access To user@domain.com"
    }
    $identity = $CalendarOwner + ":\\Tasks"
#check if the mailbox exists
    if ((get-Mailbox -identity $CalendarOwner) -eq $null){
    Write-Output ("Mailbox:" + $CalendarOwner + " doesn't exist")
    break
    }
#check if user exists
if ((get-aduser -Filter [(samaccountname -eq $user)]) -eq $null) {
Write-Output ("Username:" + $User + " doesn't exist")
    break
}
$identity = $CalendarOwner + ":\\Tasks"
Add-MailboxFolderPermission -Identity $identity -User $user -AccessRights Owner
}   
   