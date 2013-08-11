# ------------------------------------------------------------------
# Title: Get-RecycleBinSize - Determine The Size Of RecycleBin Folders - Outputs Object
# Author: Brian Wilhite
# Description: The Get-RecycleBinSize function will query and calculate the size of each users Recycle Bin Folder.  The function uses the Get-ChildItem cmdlet to query items in each users' Recycle Bin Folder. Remove-Item is used to remove all items in all Recycle Bin Folders.
# Date Published: 27-Feb-12 11:28:53 PM
# Source: http://gallery.technet.microsoft.com/scriptcenter/Get-RecycleBinSize-092f15c7
# Tags: disk space;recycle bin;recycle bin size
# Rating: 5 rated by 1
# ------------------------------------------------------------------

Function Get-RecycleBinSize
{
<#
.SYNOPSIS

This function will query and calculate the size of each users Recycle Bin Folder.  This function
will also empty the Recycle Bin if the -Empty parameter is specified.

.DESCRIPTION

This function will query and calculate the size of each users Recycle Bin Folder.  The function
uses the Get-ChildItem cmdlet to determine items in each users Recycle Bin Folder.  Remove-Item
is used to remove all items in all Recycle Bin Folders.  The function uses WMI and the
System.Security.Principal.SecurityIdentifier .NET Class to determine User Account to Recycle Bin
Folder.  Due to the number of objects and their values the default object output is in a 
"Format-List" format.  There may be SIDs that aren't translated for various reasons, the function
will not return an error if it is unable to do so, it will however, return a $null value for the
User property.  If there are a great number of items in the Recycle Bin Folders, the function
will take a few minutes to calculate.

.PARAMETER ComputerName

A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).

.PARAMETER Drive

A single Drive Letter or an array of Drive Letters to run the function against.  If the Drive
parameter is not used, the function will check all "WMI Type 3" (Logical Fixed Disks) drive letters.
The parameter will only accept, via RegEx, input that is formated as an actual drive letter C: or
D: etc.

.PARAMETER Empty

The Empty parameter is used to Remove Items from the Recycle Bin Folders, according to what is
queried.  Using the Empty parameter without the Drive parameter will Empty all the Recycle Bin
Folders on the Local or Remote Computer.

.EXAMPLE

Get-RecycleBinSize -ComputerName SERVER01

This example will return all the Recycle Bin Folders on the SERVER01 Computer.

Computer : SERVER01
Drive    : C:
User     : SERVER01\Administrator
BinSID   : S-1-5-21-3177594658-3897131987-2263270018-500
Size     : 0

.EXAMPLE

Get-RecycleBinSize -ComputerName SERVER01 -Drive D: -Empty

This example will Empty all the items in the Recycle Bin for the D: Drive.

.LINK

Windows Build Information:
http://en.wikipedia.org/wiki/Windows_NT
Win32_LogicalDisk
http://msdn.microsoft.com/en-us/library/windows/desktop/aa394173(v=vs.85).aspx
Win32_UserAccount
http://msdn.microsoft.com/en-us/library/windows/desktop/aa394507(v=vs.85).aspx
System.Security.Principal.SecurityIdentifier
http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx

.NOTES

Author: Brian Wilhite
Email:  bwilhite1@carolina.rr.com
Date:  02/24/2012
#>

[CmdletBinding()]
param(
 [Parameter(Position=0,ValueFromPipeline=$true)]
 [Alias("CN","Computer")]
 [String[]]$ComputerName="$env:COMPUTERNAME",
 [ValidatePattern(".:")]
 [String[]]$Drive,
 [Switch]$Empty
 )

Begin
 {
  #Adjusting ErrorActionPreference to stop on all errors
  $TempErrAct = $ErrorActionPreference
  $ErrorActionPreference = "Stop"
 }#End Begin Script Block
Process
 {
  Foreach ($Computer in $ComputerName)
   {
    $Computer = $Computer.ToUpper().Trim()
    Try
     {
      $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer
      Switch ($WMI_OS.BuildNumber)
       {
        {$_ -le 3790} {$RecBin = "RECYCLER"}
        {$_ -ge 6000} {$RecBin = "`$Recycle.Bin"}
       }#End Switch ($WMI_OS.BuildNumber)
      If (!$Drive)
       {
        $WMI_LDisk = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $Computer -Filter "DriveType = 3"
        Foreach ($LDisk in $WMI_LDisk)
         {
          $Disk = $LDisk.DeviceID
          $LDisk = $LDisk.DeviceID.Replace(":","$")
          $Bins = Get-ChildItem -Path \\$Computer\$LDisk\$RecBin -Force
          Foreach ($Bin in $Bins)
           {
            If ($Empty)
             {
              $Delete = $Bin.FullName + "\*"
              Remove-Item -Path $Delete -Exclude "desktop.ini" -Force -Recurse
             }#End If ($Empty)
            $Size = Get-ChildItem -Path $Bin.FullName -Exclude "desktop.ini" -Force -Recurse
            $Size = $Size | ForEach-Object {$_.Length} | Measure-Object -Sum
            
            #Attempting to Convert the Recycle Bin "Folder" Name to the Users Account.
            Try
             {
              $UserSID = New-Object System.Security.Principal.SecurityIdentifier($Bin.Name)
              $User = $UserSID.Translate([System.Security.Principal.NTAccount])
             }#End Try
            Catch
             {
              $User = $null
             }#End Catch
            If (!$User)
             {
              #Obtaining Local Account SIDs for $Bin.Name comparison.
              $WMI_UsrAcct = Get-WmiObject -Class Win32_UserAccount -ComputerName $Computer -Filter "Domain = '$Computer'"
              #Using a While Loop to search Local User Accounts for Matching $Bin.Name
              $i = 0
              While ($i -le $WMI_UsrAcct.Count)
               {
                If ($WMI_UsrAcct[$i].SID -eq $Bin.Name)
                 {
                  $User = $WMI_UsrAcct[$i].Caption
                  Break
                 }#End If ($WMI_UsrAcct[$i].SID -eq $Bin.Name)
                $i++
               }#End While ($i -le $WMI_UsrAcct.Count)
             }#End If (!$User)
            
            #Creating Output Object
            $RecInfo = New-Object PSObject -Property @{
            Computer=$Computer
            Drive=$Disk
            User=$User
            BinSID=$Bin.Name
            Size=$Size.Sum
            }
            
            #Formatting Output Object
            $RecInfo = $RecInfo | Select-Object Computer, Drive, User, BinSID, Size
            $RecInfo
           }#End Foreach ($Bin in $AllBins)
         }#End Foreach ($Drv in $Drive)
       }#End If ($Drive -eq $null)
      If ($Drive)
       {
        Foreach ($Disk in $Drive)
         {
          $MDisk = $Disk.Replace(":","$")
          $Bins = Get-ChildItem -Path \\$Computer\$MDisk\$RecBin -Force
          Foreach ($Bin in $Bins)
           {
            If ($Empty)
             {
              $Delete = $Bin.FullName + "\*"
              Remove-Item -Path $Delete -Exclude "desktop.ini" -Force -Recurse
             }#End If ($Empty)
            $Size = Get-ChildItem -Path $Bin.FullName -Exclude "desktop.ini" -Force -Recurse
            $Size = $Size | ForEach-Object {$_.Length} | Measure-Object -Sum
            
            #Attempting to Convert the Recycle Bin "Folder" Name to the Users Account.
            Try
             {
              $UserSID = New-Object System.Security.Principal.SecurityIdentifier($Bin.Name)
              $User = $UserSID.Translate([System.Security.Principal.NTAccount])
             }#End Try
            Catch
             {
              $User = $null
             }#End Catch
            If (!$User)
             {
              #Obtaining Local Account SIDs for $Bin.Name comparison.
              $WMI_UsrAcct = Get-WmiObject -Class Win32_UserAccount -ComputerName $Computer -Filter "Domain = '$Computer'"
              #Using a While Loop to search Local User Accounts for Matching $Bin.Name
              $i = 0
              While ($i -le $WMI_UsrAcct.Count)
               {
                If ($WMI_UsrAcct[$i].SID -eq $Bin.Name)
                 {
                  $User = $WMI_UsrAcct[$i].Caption
                  Break
                 }
                $i++
               }#End While ($i -le $WMI_UsrAcct.Count)
             }#End If (!$User)

            #Creating Output Object
            $RecInfo = New-Object PSObject -Property @{
            Computer=$Computer
            Drive=$Disk.ToUpper()
			User=$User
            BinSID=$Bin.Name
            Size=$Size.Sum
            }
            
            #Formatting Output Object
            $RecInfo = $RecInfo | Select-Object Computer, Drive, User, BinSID, Size
            $RecInfo
           }#End Foreach ($Bin in $AllBins)
         }#End Foreach ($Disk in $Drive)
       }#End Else
     }#End Try
    Catch
     {
      $Error[0].Exception.Message
     }#End Catch
   }#End Foreach ($Computer in $ComputerName)
 }#End Process
End
 {
  #Resetting ErrorActionPref
  $ErrorActionPreference = $TempErrAct
 }#End End
}#End Function